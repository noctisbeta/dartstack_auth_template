import 'package:common/annotations/propagates.dart';
import 'package:common/annotations/throws.dart';
import 'package:common/auth/login/login_error.dart';
import 'package:common/auth/login/login_request.dart';
import 'package:common/auth/login/login_response.dart';
import 'package:common/auth/register/register_error.dart';
import 'package:common/auth/register/register_request.dart';
import 'package:common/auth/register/register_response.dart';
import 'package:common/auth/tokens/jwtoken.dart';
import 'package:common/auth/tokens/refresh_error.dart';
import 'package:common/auth/tokens/refresh_jwtoken_request.dart';
import 'package:common/auth/tokens/refresh_jwtoken_response.dart';
import 'package:common/auth/tokens/refresh_token.dart';
import 'package:common/auth/tokens/refresh_token_wrapper.dart';
import 'package:common/auth/user.dart';
import 'package:server/auth/abstractions/i_auth_repository.dart';
import 'package:server/auth/hasher.dart';
import 'package:server/auth/implementations/auth_data_source.dart';
import 'package:server/auth/jwtoken_helper.dart';
import 'package:server/auth/models/refresh_token_db.dart';
import 'package:server/auth/models/user_db.dart';
import 'package:server/postgres/database_exception.dart';

final class AuthRepository implements IAuthRepository {
  AuthRepository({
    required AuthDataSource authDataSource,
    required Hasher hasher,
  }) : _authDataSource = authDataSource,
       _hasher = hasher;

  final AuthDataSource _authDataSource;

  final Hasher _hasher;

  @override
  Future<RefreshJWTokenResponse> refreshJWToken({
    required RefreshJWTokenRequest refreshTokenRequest,
    required String? ipAddress,
    required String? userAgent,
  }) async {
    @Throws([DatabaseException])
    final RefreshTokenDB refreshTokenDB = await _authDataSource.getRefreshToken(
      refreshTokenRequest.refreshToken,
    );

    // Check if token is revoked
    if (refreshTokenDB.isRevoked) {
      return const RefreshJWTokenResponseError(
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

      return const RefreshJWTokenResponseError(
        message: 'Security concern: Token already used',
        error: RefreshError.compromised,
      );
    }

    final DateTime nowUtc = DateTime.now().toUtc();

    if (refreshTokenDB.expiresAt.toUtc().isBefore(nowUtc)) {
      // Mark as expired instead of deleting
      await _authDataSource.markRefreshTokenExpired(
        refreshTokenRequest.refreshToken,
      );

      return const RefreshJWTokenResponseError(
        message: 'Refresh token expired',
        error: RefreshError.expired,
      );
    }

    final int userId = refreshTokenDB.userId;

    // Rotate the token
    final RefreshTokenDB newRefreshTokenDB = await _authDataSource
        .rotateRefreshToken(
          oldToken: refreshTokenRequest.refreshToken,
          userId: userId,
          ipAddress: ipAddress,
          userAgent: userAgent,
        );

    // Create new JWT
    final JWToken jwToken = JWTokenHelper.createWith(userID: userId);

    // Use the rotated token directly
    final refreshToken = RefreshToken.fromRefreshTokenString(
      newRefreshTokenDB.token,
    );

    return RefreshJWTokenResponseSuccess(
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
    final bool isUsernameUnique = await _authDataSource.isUniqueUsername(
      registerRequest.username,
    );

    if (!isUsernameUnique) {
      return const RegisterResponseError(
        message: 'Username already exists!',
        error: RegisterError.usernameAlreadyExists,
      );
    }

    final (
      hashedPassword: String hashedPassword,
      salt: String salt,
    ) = await _hasher.hashPassword(registerRequest.password);

    @Throws([DatabaseException])
    final UserDB userDB = await _authDataSource.register(
      registerRequest.username,
      hashedPassword,
      salt,
    );

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

    final response = RegisterResponseSuccess(user: user);

    return response;
  }

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
