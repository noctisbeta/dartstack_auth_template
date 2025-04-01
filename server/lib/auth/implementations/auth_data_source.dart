import 'dart:convert';
import 'dart:math';

import 'package:common/annotations/propagates.dart';
import 'package:common/annotations/throws.dart';
import 'package:common/auth/tokens/refresh_token.dart';
import 'package:common/logger/logger.dart';
import 'package:postgres/postgres.dart';
import 'package:server/auth/abstractions/i_auth_data_source.dart';
import 'package:server/auth/models/refresh_token_db.dart';
import 'package:server/auth/models/user_db.dart';
import 'package:server/postgres/database_exception.dart';
import 'package:server/postgres/i_postgres_service.dart';

final class AuthDataSource implements IAuthDataSource {
  AuthDataSource({required IPostgresService postgresService})
    : _ps = postgresService;

  final IPostgresService _ps;

  @override
  @Propagates([DatabaseException])
  Future<RefreshTokenDB> getRefreshToken(RefreshToken token) async {
    @Throws([DatabaseException])
    final RefreshTokenDB refreshTokenDB = await _ps.executeAndMap(
      query: Sql.named('SELECT * FROM refresh_tokens WHERE token = @token;'),
      parameters: {'token': token},
      mapper: RefreshTokenDB.validatedFromMap,
      emptyResultMessage: 'No refresh token found with that token.',
    );

    return refreshTokenDB;
  }

  @Propagates([DatabaseException])
  Future<void> markRefreshTokenExpired(RefreshToken token) async {
    await _ps.execute(
      Sql.named('''
      UPDATE refresh_tokens 
      SET is_used = true, 
          is_revoked = true, 
          revocation_reason = 'Token expired'
      WHERE token = @token;
    '''),
      parameters: {'token': token},
    );
  }

  RefreshToken _generateRefreshToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return RefreshToken.fromRefreshTokenString(base64Url.encode(bytes));
  }

  @override
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
    final RefreshTokenDB refreshTokenDB = await _ps.executeAndMap(
      query: Sql.named('''
        INSERT INTO refresh_tokens (
          user_id, token, expires_at, user_agent, ip_address
        )
        VALUES (
          @user_id, @token, @expires_at, @user_agent, @ip_address
        )
        RETURNING *;
      '''),
      parameters: {
        'user_id': userId,
        'token': refreshToken,
        'expires_at': expiresAt,
        'user_agent': userAgent,
        'ip_address': ipAddress,
      },
      mapper: RefreshTokenDB.validatedFromMap,
      emptyResultMessage: 'Failed to insert refresh token into database.',
    );

    return refreshTokenDB;
  }

  @override
  @Propagates([DatabaseException])
  Future<UserDB> login(String username) async {
    @Throws([DatabaseException])
    final UserDB userDB = await _ps.executeAndMap(
      query: Sql.named('''
        SELECT * FROM users WHERE username = @username;
      '''),
      parameters: {'username': username},
      mapper: UserDB.validatedFromMap,
      emptyResultMessage: 'No user found with that username.',
    );

    return userDB;
  }

  @override
  @Propagates([DatabaseException])
  Future<UserDB> register(
    String username,
    String hashedPassword,
    String salt,
  ) async {
    @Throws([DatabaseException])
    final UserDB userDB = await _ps.executeAndMap(
      query: Sql.named('''
        INSERT INTO users (username, hashed_password, salt)
        VALUES (@username, @hashedPassword, @salt) RETURNING *;
      '''),
      parameters: {
        'username': username,
        'hashedPassword': hashedPassword,
        'salt': salt,
      },
      mapper: UserDB.validatedFromMap,
      emptyResultMessage: 'Failed to insert user into database.',
    );

    return userDB;
  }

  @override
  @Propagates([DatabaseException])
  Future<bool> isUniqueUsername(String username) async {
    @Throws([DatabaseException])
    final Result res = await _ps.execute(
      Sql.named('SELECT 1 FROM users WHERE username = @username;'),
      parameters: {'username': username},
    );

    return res.isEmpty;
  }

  /// Rotates a refresh token by invalidating the old one and creating a new one
  /// This maintains an audit trail and enhances security
  @Propagates([DatabaseException])
  @override
  Future<RefreshTokenDB> rotateRefreshToken({
    required RefreshToken oldToken,
    required int userId,
    String? ipAddress,
    String? userAgent,
  }) async {
    // Get the old token data with its client context
    @Throws([DatabaseException])
    final RefreshTokenDB oldTokenData = await getRefreshToken(oldToken);

    // Use transaction to ensure atomicity
    return _ps.runTx((connection) async {
      // Mark old token as used (don't delete it)
      await connection.execute(
        Sql.named(
          'UPDATE refresh_tokens SET is_used = TRUE WHERE token = @old_token',
        ),
        parameters: {'old_token': oldToken},
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
  @override
  @Throws([DatabaseException])
  Future<void> revokeAllUserTokens(int userId, {String? reason}) async {
    final DateTime revokedAt = DateTime.now().toUtc();

    @Throws([DatabaseException])
    final Result result = await _ps.execute(
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
