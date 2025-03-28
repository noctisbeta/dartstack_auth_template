import 'package:client/dio_wrapper/dio_wrapper.dart';
import 'package:common/auth/tokens/jwtoken.dart';
import 'package:common/auth/tokens/refresh_jwtoken_request.dart';
import 'package:common/auth/tokens/refresh_jwtoken_response.dart';
import 'package:common/auth/tokens/refresh_token.dart';
import 'package:common/auth/tokens/refresh_token_wrapper.dart';
import 'package:common/logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class JwtInterceptor extends InterceptorsWrapper {
  JwtInterceptor({
    required FlutterSecureStorage secureStorage,
    required this.dioWrapper,
  }) : _storage = secureStorage;

  final DioWrapper dioWrapper;
  final FlutterSecureStorage _storage;

  Future<JWToken?> _refreshToken(
    RequestOptions options,
    ErrorInterceptorHandler handler,
  ) async {
    final String? refreshTokenString = await _storage.read(
      key: 'refresh_token',
    );
    final String? refreshTokenExpiresAtString = await _storage.read(
      key: 'refresh_token_expires_at',
    );

    switch ((refreshTokenString, refreshTokenExpiresAtString)) {
      case (null, null):
        throw Exception(
          'Refresh token and refres token expires at not found in '
          'secure storage.',
        );
      case (null, String()):
        throw Exception('Refresh token not found');
      case (String(), null):
        throw Exception('Refresh token expires at not found');
    }

    final RefreshToken refreshToken = RefreshToken.fromRefreshTokenString(
      refreshTokenString!,
    );

    final DateTime refreshTokenExpiresAt = DateTime.parse(
      refreshTokenExpiresAtString!,
    );

    if (DateTime.now().isAfter(refreshTokenExpiresAt)) {
      handler.resolve(
        Response(
          requestOptions: options,
          data: 'Refresh Token is expired',
          statusCode: 401,
        ),
      );
    }

    final RefreshJWTokenRequest refreshTokenRequest = RefreshJWTokenRequest(
      refreshToken: refreshToken,
    );

    try {
      final Response response = await dioWrapper.post(
        '/auth/refresh',
        data: refreshTokenRequest.toMap(),
      );

      final RefreshJWTokenResponseSuccess refreshTokenResponse =
          RefreshJWTokenResponseSuccess.validatedFromMap(
            response.data as Map<String, dynamic>,
          );
      RefreshJWTokenResponseSuccess.validatedFromMap(
        response.data as Map<String, dynamic>,
      );

      final RefreshTokenWrapper refreshTokenWrapper =
          refreshTokenResponse.refreshTokenWrapper;

      final RefreshToken newRefreshToken = refreshTokenWrapper.refreshToken;
      final DateTime newRefreshTokenExpiresAt =
          refreshTokenWrapper.refreshTokenExpiresAt;
      final JWToken newJwToken = refreshTokenResponse.jwToken;

      await _storage.write(key: 'refresh_token', value: newRefreshToken.value);
      await _storage.write(
        key: 'refresh_token_expires_at',
        value: newRefreshTokenExpiresAt.toIso8601String(),
      );
      await _storage.write(key: 'jw_token', value: newJwToken.value);

      return newJwToken;
    } on DioException catch (e) {
      LOG.e('Failed to refresh token: $e');

      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'refresh_token_expires_at');
      await _storage.delete(key: 'jw_token');

      return null;
    }
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? jwTokenString = await _storage.read(key: 'jw_token');

    if (jwTokenString == null) {
      throw Exception('Token not found in storage in JwtInterceptor');
    }

    final JWToken token = JWToken.fromJwtString(jwTokenString);

    options.headers['Authorization'] = 'Bearer $token';

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final JWToken? newToken = await _refreshToken(
          err.requestOptions,
          handler,
        );

        if (newToken == null) {
          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: 'Token refresh failed',
            ),
          );
        }

        final RequestOptions requestOptions = err.requestOptions;

        requestOptions.headers['Authorization'] = 'Bearer $newToken';

        final Response response = await dioWrapper.request(
          requestOptions.path,
          options: Options(
            method: requestOptions.method,
            headers: requestOptions.headers,
          ),
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
        );
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: 'Token refresh failed $e',
          ),
        );
      }
    }
    return handler.next(err);
  }
}
