import 'dart:io';

import 'package:client/dio_wrapper/dio_wrapper.dart';
import 'package:common/auth/login/login_error.dart';
import 'package:common/auth/login/login_request.dart';
import 'package:common/auth/login/login_response.dart';
import 'package:common/auth/register/register_error.dart';
import 'package:common/auth/register/register_request.dart';
import 'package:common/auth/register/register_response.dart';
import 'package:common/auth/tokens/jwtoken.dart';
import 'package:common/auth/tokens/refresh_jwtoken_request.dart';
import 'package:common/auth/tokens/refresh_jwtoken_response.dart';
import 'package:common/auth/tokens/refresh_token.dart';
import 'package:common/auth/tokens/refresh_token_wrapper.dart';
import 'package:common/auth/user.dart';
import 'package:common/logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

@immutable
final class AuthRepository {
  const AuthRepository({
    required DioWrapper dio,
    required FlutterSecureStorage storage,
  }) : _dio = dio,
       _storage = storage;

  final DioWrapper _dio;

  final FlutterSecureStorage _storage;

  Future<void> _saveUsername(String username) async {
    await _storage.write(key: 'username', value: username);
  }

  Future<String?> _getUsername() => _storage.read(key: 'username');

  Future<void> _saveJWToken(JWToken token) async {
    await _storage.write(key: 'jw_token', value: token.value);
  }

  Future<JWToken?> _getJWToken() async {
    final String? tokenString = await _storage.read(key: 'jw_token');

    if (tokenString == null) {
      return null;
    }

    return JWToken.fromJwtString(tokenString);
  }

  Future<void> _saveRefreshToken(
    RefreshToken refreshToken,
    DateTime refreshTokenExpiresAt,
  ) async {
    await _storage.write(key: 'refresh_token', value: refreshToken.value);

    await _storage.write(
      key: 'refresh_token_expires_at',
      value: refreshTokenExpiresAt.toIso8601String(),
    );
  }

  Future<JWToken?> refreshJWToken() async {
    final String? refreshTokenString = await _storage.read(
      key: 'refresh_token',
    );

    if (refreshTokenString == null) {
      throw Exception('Refresh token not found in secure storage');
    }

    try {
      final RefreshToken refreshToken = RefreshToken.fromRefreshTokenString(
        refreshTokenString,
      );

      final RefreshJWTokenRequest refreshTokenRequest = RefreshJWTokenRequest(
        refreshToken: refreshToken,
      );

      final Response response = await _dio.post(
        '/auth/refresh',
        data: refreshTokenRequest.toMap(),
      );

      final RefreshJWTokenResponseSuccess refreshTokenResponseSuccess =
          RefreshJWTokenResponseSuccess.validatedFromMap(response.data);

      final RefreshTokenWrapper refreshTokenWrapper =
          refreshTokenResponseSuccess.refreshTokenWrapper;

      final RefreshToken newRefreshToken = refreshTokenWrapper.refreshToken;
      final DateTime newRefreshTokenExpiresAt =
          refreshTokenWrapper.refreshTokenExpiresAt;
      final JWToken newJwToken = refreshTokenResponseSuccess.jwToken;

      await _storage.write(key: 'refresh_token', value: newRefreshToken.value);

      await _storage.write(
        key: 'refresh_token_expires_at',
        value: newRefreshTokenExpiresAt.toIso8601String(),
      );

      await _saveJWToken(newJwToken);

      return newJwToken;
    } on DioException catch (e) {
      LOG.e(
        'Error refreshing token. \n ${e.response?.statusCode} '
        '\n ${e.response?.data}',
      );
      return null;
    }
  }

  Future<User> getUser() async {
    final String? username = await _getUsername();
    final JWToken? token = await _getJWToken();

    if (username == null || token == null) {
      throw Exception('Username or token not found in secure storage');
    }

    final String? refreshTokenString = await _storage.read(
      key: 'refresh_token',
    );

    if (refreshTokenString == null) {
      throw Exception('Refresh token not found in secure storage');
    }

    final RefreshToken refreshToken = RefreshToken.fromRefreshTokenString(
      refreshTokenString,
    );

    final String? refreshTokenExpiresAtString = await _storage.read(
      key: 'refresh_token_expires_at',
    );

    if (refreshTokenExpiresAtString == null) {
      throw Exception('Refresh token expires at not found in secure storage');
    }

    final DateTime refreshTokenExpiresAt = DateTime.parse(
      refreshTokenExpiresAtString,
    );

    final RefreshTokenWrapper refreshTokenWrapper = RefreshTokenWrapper(
      refreshToken: refreshToken,
      refreshTokenExpiresAt: refreshTokenExpiresAt,
    );

    return User(
      username: username,
      token: token,
      refreshTokenWrapper: refreshTokenWrapper,
    );
  }

  Future<bool> isAuthenticated() async {
    final JWToken? token = await _getJWToken();

    if (token == null) {
      return false;
    }

    final bool isValid = token.isValid();

    switch (isValid) {
      case false:
        final JWToken? newJwToken = await refreshJWToken();
        return newJwToken != null;
      case true:
        return true;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jw_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'refresh_token_expires_at');
  }

  Future<LoginResponse> login(LoginRequest loginRequest) async {
    try {
      final Response response = await _dio.post(
        '/auth/login',
        data: loginRequest.toMap(),
      );

      final LoginResponseSuccess loginResponse =
          LoginResponseSuccess.validatedFromMap(response.data);

      await _saveUsername(loginRequest.username);

      await _saveJWToken(loginResponse.user.token);

      await _saveRefreshToken(
        loginResponse.user.refreshTokenWrapper.refreshToken,
        loginResponse.user.refreshTokenWrapper.refreshTokenExpiresAt,
      );

      return loginResponse;
    } on DioException catch (e) {
      LOG.e('Error logging in user: $e');
      switch (e.response?.statusCode) {
        case HttpStatus.unauthorized:
          LOG.w('Unauthorized login attempt');
          return LoginResponseError.validatedFromMap(e.response?.data);

        case HttpStatus.notFound:
          LOG.e('User not found');
          return const LoginResponseError(
            message: 'User not found',
            error: LoginError.userNotFound,
          );

        default:
          LOG.e('Unknown Error logging in user: $e');
          return const LoginResponseError(
            message: 'Error logging i user',
            error: LoginError.unknownLoginError,
          );
      }
    }
  }

  Future<RegisterResponse> register(RegisterRequest registerRequest) async {
    try {
      final Response response = await _dio.post(
        '/auth/register',
        data: registerRequest.toMap(),
      );

      final RegisterResponseSuccess registerResponse =
          RegisterResponseSuccess.validatedFromMap(response.data);

      await _saveUsername(registerRequest.username);
      await _saveJWToken(registerResponse.user.token);
      await _saveRefreshToken(
        registerResponse.user.refreshTokenWrapper.refreshToken,
        registerResponse.user.refreshTokenWrapper.refreshTokenExpiresAt,
      );

      return registerResponse;
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case HttpStatus.conflict:
          return RegisterResponseError.validatedFromMap(e.response?.data);

        default:
          LOG.e('Unknown Error registering user: $e');
          return const RegisterResponseError(
            message: 'Error registering user',
            error: RegisterError.unknownRegisterError,
          );
      }
    }
  }

  Future<({DateTime jwtExpiresAt, DateTime refreshExpiresAt})?>
  getTokenExpirations() async {
    try {
      final String? jwtString = await _storage.read(key: 'jw_token');
      final String? refreshExp = await _storage.read(
        key: 'refresh_token_expires_at',
      );

      if (jwtString == null || refreshExp == null) {
        return null;
      }

      final JWToken jwt = JWToken.fromJwtString(jwtString);

      final DateTime jwtExpiresAt = jwt.getExpiration();
      final DateTime refreshExpiresAt = DateTime.parse(refreshExp);

      return (jwtExpiresAt: jwtExpiresAt, refreshExpiresAt: refreshExpiresAt);
    } on Exception catch (e) {
      LOG.e('Error getting token info: $e');
      return null;
    }
  }
}
