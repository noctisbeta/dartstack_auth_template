import 'package:common/auth/login/login_error.dart';
import 'package:common/auth/login/login_request.dart';
import 'package:common/auth/login/login_response.dart';
import 'package:common/auth/register/register_error.dart';
import 'package:common/auth/register/register_request.dart';
import 'package:common/auth/register/register_response.dart';
import 'package:common/auth/tokens/jwtoken.dart';
import 'package:common/auth/tokens/refresh_error.dart';
import 'package:common/auth/tokens/refresh_token.dart';
import 'package:common/auth/tokens/refresh_token_request.dart';
import 'package:common/auth/tokens/refresh_token_response.dart';
import 'package:common/auth/tokens/refresh_token_wrapper.dart';
import 'package:common/auth/user.dart';
import 'package:common/exceptions/propagates.dart';
import 'package:common/exceptions/throws.dart';
import 'package:server/auth/abstractions/i_auth_repository.dart';
import 'package:server/auth/auth_data_source.dart';
import 'package:server/auth/hasher.dart';
import 'package:server/auth/jwtoken_helper.dart';
import 'package:server/auth/refresh_token_db.dart';
import 'package:server/auth/user_db.dart';
import 'package:server/postgres/exceptions/database_exception.dart';

final class AuthRepository implements IAuthRepository {
  AuthRepository({
    required AuthDataSource authDataSource,
    required Hasher hasher,
  }) : _authDataSource = authDataSource,
       _hasher = hasher;

  final AuthDataSource _authDataSource;

  final Hasher _hasher;

  @override
  Future<RefreshTokenResponse> refreshToken(
    RefreshTokenRequest refreshTokenRequest,
  ) async {
    final RefreshTokenDB refreshTokenDB = await _authDataSource.getRefreshToken(
      refreshTokenRequest.refreshToken,
    );

    // Check if token is revoked
    if (refreshTokenDB.isRevoked) {
      return const RefreshTokenResponseError(
        message: 'Token has been revoked',
        error: RefreshError.revoked,
      );
    }

    // Check if this token has already been used
    if (refreshTokenDB.isUsed) {
      // This might indicate token theft! Revoke all tokens for this user
      await _authDataSource.revokeAllUserTokens(
        refreshTokenDB.userId,
        reason: 'Potential token compromise',
      );

      return const RefreshTokenResponseError(
        message: 'Security concern: Token already used',
        error: RefreshError.compromised,
      );
    }

    final DateTime nowUtc = DateTime.now().toUtc();

    if (refreshTokenDB.expiresAt.toUtc().isBefore(nowUtc)) {
      await _authDataSource.deleteRefreshToken(
        refreshTokenRequest.refreshToken,
      );

      return const RefreshTokenResponseError(
        message: 'Refresh token expired',
        error: RefreshError.expired,
      );
    }

    final int userId = refreshTokenDB.userId;

    // Rotate the token
    final RefreshTokenDB newRefreshTokenDB = await _authDataSource
        .rotateRefreshToken(refreshTokenRequest.refreshToken, userId);

    // Create new JWT
    final JWToken jwToken = JWTokenHelper.createWith(userID: userId);

    // Use the rotated token directly
    final refreshToken = RefreshToken.fromRefreshTokenString(
      newRefreshTokenDB.token,
    );

    return RefreshTokenResponseSuccess(
      refreshTokenWrapper: RefreshTokenWrapper(
        refreshToken: refreshToken,
        refreshTokenExpiresAt: newRefreshTokenDB.expiresAt,
      ),
      jwToken: jwToken,
    );
  }

  @override
  @Propagates([DatabaseException])
  Future<LoginResponse> login({
    required LoginRequest loginRequest,
    String? ipAddress,
    String? userAgent,
  }) async {
    @Throws([DatabaseException])
    final UserDB userDB = await _authDataSource.login(loginRequest.username);

    final bool isValid = await _hasher.verifyPassword(
      loginRequest.password,
      userDB.hashedPassword,
      userDB.salt,
    );

    if (!isValid) {
      return const LoginResponseError(
        message: 'Invalid password!',
        error: LoginError.wrongPassword,
      );
    }

    final (
      JWToken token,
      RefreshTokenWrapper refreshTokenWrapper,
    ) = await _getTokensFromUserId(
      userId: userDB.id,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    final user = User(
      username: userDB.username,
      token: token,
      refreshTokenWrapper: refreshTokenWrapper,
    );

    final response = LoginResponseSuccess(user: user);

    return response;
  }

  @override
  @Propagates([DatabaseException])
  Future<RegisterResponse> register({
    required RegisterRequest registerRequest,
    String? ipAddress,
    String? userAgent,
  }) async {
    final bool isUsernameUnique = await _isUniqueUsername(
      registerRequest.username,
    );

    if (!isUsernameUnique) {
      return const RegisterResponseError(
        message: 'Username already exists!',
        error: RegisterError.usernameAlreadyExists,
      );
    }

    final ({String hashedPassword, String salt}) hashResult = await _hasher
        .hashPassword(registerRequest.password);

    @Throws([DatabaseException])
    final UserDB userDB = await _authDataSource.register(
      registerRequest.username,
      hashResult.hashedPassword,
      hashResult.salt,
    );

    final (
      JWToken token,
      RefreshTokenWrapper refreshTokenWrapper,
    ) = await _getTokensFromUserId(userId: userDB.id);

    final user = User(
      username: userDB.username,
      token: token,
      refreshTokenWrapper: refreshTokenWrapper,
    );

    final response = RegisterResponseSuccess(user: user);

    return response;
  }

  Future<bool> _isUniqueUsername(String username) =>
      _authDataSource.isUniqueUsername(username);

  Future<(JWToken, RefreshTokenWrapper)> _getTokensFromUserId({
    required int userId,
    String? ipAddress,
    String? userAgent,
  }) async {
    final JWToken jwToken = JWTokenHelper.createWith(userID: userId);

    final RefreshTokenDB refreshTokenDB = await _authDataSource
        .storeRefreshToken(
          userId: userId,
          ipAddress: ipAddress,
          userAgent: userAgent,
        );

    final refreshToken = RefreshToken.fromRefreshTokenString(
      refreshTokenDB.token,
    );

    return (
      jwToken,
      RefreshTokenWrapper(
        refreshToken: refreshToken,
        refreshTokenExpiresAt: refreshTokenDB.expiresAt,
      ),
    );
  }
}
