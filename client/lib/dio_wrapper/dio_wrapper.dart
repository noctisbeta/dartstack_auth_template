import 'package:client/dio_wrapper/jwt_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

@immutable
final class DioWrapper {
  DioWrapper()
    : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://localhost:8080/api/v1',
            validateStatus:
                (status) => status != null && status >= 200 && status < 300,
          ),
        )
        ..interceptors.addAll([
          LogInterceptor(requestBody: true, responseBody: true),
          InterceptorsWrapper(onError: (e, handler) => handler.next(e)),
        ]);

  void addAuthInterceptor(FlutterSecureStorage storage) {
    removeAuthInterceptor();

    _dio.interceptors.add(
      JwtInterceptor(secureStorage: storage, dioWrapper: DioWrapper()),
    );
  }

  void removeAuthInterceptor() {
    _dio.interceptors.removeWhere(
      (interceptor) => interceptor is JwtInterceptor,
    );
  }

  final Dio _dio;

  Future<Response> request(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final Response response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return response;
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final Response response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );

      return response;
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Response> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final Response response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return response;
    } on DioException catch (_) {
      rethrow;
    }
  }
}
