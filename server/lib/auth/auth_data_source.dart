import 'dart:convert';
import 'dart:math';

import 'package:common/auth/tokens/refresh_token.dart';
import 'package:common/exceptions/propagates.dart';
import 'package:common/exceptions/throws.dart';
import 'package:common/logger/logger.dart';
import 'package:postgres/postgres.dart';
import 'package:server/auth/refresh_token_db.dart';
import 'package:server/auth/user_db.dart';
import 'package:server/postgres/exceptions/database_exception.dart';
import 'package:server/postgres/implementations/postgres_service.dart';

final class AuthDataSource {
  AuthDataSource({required PostgresService postgresService})
    : _db = postgresService;

  final PostgresService _db;

  Future<void> deleteRefreshToken(RefreshToken token) async {
    @Throws([DatabaseException])
    final Result _ = await _db.execute(
      Sql.named('DELETE FROM refresh_tokens WHERE token = @token;'),
      parameters: {'token': token},
    );
  }

  Future<RefreshTokenDB> getRefreshToken(RefreshToken token) async {
    @Throws([DatabaseException])
    final Result res = await _db.execute(
      Sql.named('SELECT * FROM refresh_tokens WHERE token = @token;'),
      parameters: {'token': token},
    );

    if (res.isEmpty) {
      throw const DBEemptyResult('No refresh token found with that token.');
    }

    final Map<String, dynamic> resCol = res.first.toColumnMap();

    @Throws([DBEbadSchema])
    final refreshTokenDB = RefreshTokenDB.validatedFromMap(resCol);

    return refreshTokenDB;
  }

  RefreshToken _generateRefreshToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return RefreshToken.fromRefreshTokenString(base64Url.encode(bytes));
  }

  Future<RefreshTokenDB> storeRefreshToken({
    required int userId,
    required String? userAgent,
    required String? ipAddress,
  }) async {
    final RefreshToken refreshToken = _generateRefreshToken();

    final DateTime expiresAt = DateTime.now().toUtc().add(
      RefreshToken.expirationDuration,
    );

    @Throws([DatabaseException])
    final Result res = await _db.execute(
      Sql.named('''
      INSERT INTO refresh_tokens (
        user_id, 
        token, 
        expires_at, 
        user_agent,
        ip_address
      )
      VALUES (@user_id, @token, @expires_at, @user_agent, @ip_address)
      RETURNING *;
      '''),
      parameters: {
        'user_id': userId,
        'token': refreshToken,
        'expires_at': expiresAt,
        'user_agent': userAgent,
        'ip_address': ipAddress,
      },
    );

    if (res.isEmpty) {
      throw const DBEemptyResult(
        'Failed to insert refresh token into database.',
      );
    }

    final Map<String, dynamic> resCol = res.first.toColumnMap();

    @Throws([DBEbadSchema])
    final refreshTokenDB = RefreshTokenDB.validatedFromMap(resCol);

    return refreshTokenDB;
  }

  @Throws([DBEemptyResult, DBEbadSchema])
  @Propagates([DatabaseException])
  Future<UserDB> login(String username) async {
    @Throws([DatabaseException])
    final Result res = await _db.execute(
      Sql.named('SELECT * FROM users WHERE username = @username;'),
      parameters: {'username': username},
    );

    if (res.isEmpty) {
      throw const DBEemptyResult('No user found with that username.');
    }

    final Map<String, dynamic> resCol = res.first.toColumnMap();

    @Throws([DBEbadSchema])
    final userDB = UserDB.validatedFromMap(resCol);

    return userDB;
  }

  @Throws([DBEemptyResult, DBEbadSchema])
  @Propagates([DatabaseException])
  Future<UserDB> register(
    String username,
    String hashedPassword,
    String salt,
  ) async {
    @Throws([DatabaseException])
    final Result res = await _db.execute(
      Sql.named('''
        INSERT INTO users (username, hashed_password, salt)
        VALUES (@username, @hashedPassword, @salt) RETURNING *;
      '''),
      parameters: {
        'username': username,
        'hashedPassword': hashedPassword,
        'salt': salt,
      },
    );

    if (res.isEmpty) {
      throw const DBEemptyResult('Failed to insert user into database.');
    }

    final Map<String, dynamic> resCol = res.first.toColumnMap();

    @Throws([DBEbadSchema])
    final userDB = UserDB.validatedFromMap(resCol);

    return userDB;
  }

  @Propagates([DatabaseException])
  Future<bool> isUniqueUsername(String username) async {
    @Throws([DatabaseException])
    final Result res = await _db.execute(
      Sql.named('SELECT 1 FROM users WHERE username = @username;'),
      parameters: {'username': username},
    );

    return res.isEmpty;
  }

  /// Rotates a refresh token by invalidating the old one and creating a new one
  /// This maintains an audit trail and enhances security
  Future<RefreshTokenDB> rotateRefreshToken(
    RefreshToken oldToken,
    int userId, {
    String? ipAddress,
    String? userAgent,
  }) async {
    // Get the old token data with its client context
    final RefreshTokenDB oldTokenData = await getRefreshToken(oldToken);

    // Use transaction to ensure atomicity
    return _db.runTx((connection) async {
      // Mark old token as used (don't delete it)
      await connection.execute(
        Sql.named(
          'UPDATE refresh_tokens SET is_used = TRUE WHERE token = @token',
        ),
        parameters: {'token': oldToken},
      );

      // Create new token with same client context as the old one
      final RefreshToken newToken = _generateRefreshToken();

      final Result res = await connection.execute(
        Sql.named('''
        INSERT INTO refresh_tokens (
          user_id, token, expires_at, previous_token, ip_address, user_agent
        )
        VALUES (
          @user_id, @token, @expires_at, @previous_token, 
          COALESCE(@ip_address, @old_ip_address), 
          COALESCE(@user_agent, @old_user_agent)
        )
        RETURNING *;
        '''),
        parameters: {
          'user_id': userId,
          'token': newToken,
          'expires_at': DateTime.now().toUtc().add(
            RefreshToken.expirationDuration,
          ),
          'previous_token': oldToken,
          'ip_address': ipAddress,
          'old_ip_address': oldTokenData.ipAddress,
          'user_agent': userAgent,
          'old_user_agent': oldTokenData.userAgent,
        },
      );

      // Return the new token
      return RefreshTokenDB.validatedFromMap(res.first.toColumnMap());
    });
  }

  /// Revokes all refresh tokens for a specific user
  /// This is a security measure typically used when token theft is suspected
  /// [userId] The ID of the user whose tokens should be revoked
  /// [reason] Optional reason for the revocation (useful for audit logs)
  Future<void> revokeAllUserTokens(int userId, {String? reason}) async {
    final DateTime revokedAt = DateTime.now().toUtc();

    @Throws([DatabaseException])
    final Result result = await _db.execute(
      Sql.named('''
      UPDATE refresh_tokens
      SET 
        is_revoked = TRUE,
        revoked_at = @revoked_at,
        revoked_reason = @reason
      WHERE 
        user_id = @user_id AND
        is_revoked = FALSE
      '''),
      parameters: {
        'user_id': userId,
        'revoked_at': revokedAt,
        'reason': reason ?? 'Security measure - bulk revocation',
      },
    );

    LOG.w(
      'Revoked ${result.affectedRows} tokens for user $userId. Reason: $reason',
    );
  }
}
