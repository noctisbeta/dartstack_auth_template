import 'dart:io';

import 'package:common/auth/login/login_request.dart';
import 'package:common/auth/login/login_response.dart';
import 'package:common/auth/register/register_error.dart';
import 'package:common/auth/register/register_request.dart';
import 'package:common/auth/register/register_response.dart';
import 'package:common/auth/tokens/refresh_token_request.dart';
import 'package:common/auth/tokens/refresh_token_response.dart';
import 'package:common/exceptions/request_exception.dart';
import 'package:common/exceptions/throws.dart';
import 'package:server/auth/abstractions/i_auth_handler.dart';
import 'package:server/auth/abstractions/i_auth_repository.dart';
import 'package:server/postgres/exceptions/database_exception.dart';
import 'package:server/util/json_response.dart';
import 'package:server/util/request_extension.dart';
import 'package:shelf/shelf.dart';

final class AuthHandler implements IAuthHandler {
  AuthHandler({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  final IAuthRepository _authRepository;

  @override
  Future<Response> refreshToken(Request request) async {
    try {
      final bool isValidContentType = request.validateContentType(
        ContentType.json.mimeType,
      );

      if (!isValidContentType) {
        return Response(
          HttpStatus.badRequest,
          body: 'Invalid request! Content-Type must be ${ContentType.json}',
        );
      }

      @Throws([FormatException])
      final Map<String, dynamic> json = await request.json();

      final refreshTokenRequest = RefreshTokenRequest.validatedFromMap(json);

      final RefreshTokenResponse refreshTokenResponse = await _authRepository
          .refreshToken(refreshTokenRequest);

      switch (refreshTokenResponse) {
        case RefreshTokenResponseSuccess():
          return JsonResponse(body: refreshTokenResponse.toMap());
        case RefreshTokenResponseError():
          return JsonResponse(
            statusCode: HttpStatus.unauthorized,
            body: refreshTokenResponse.toMap(),
          );
      }
    } on Exception catch (e) {
      return Response(
        HttpStatus.internalServerError,
        body: 'Failed to refresh token: $e',
      );
    }
  }

  @override
  Future<Response> login(Request request) async {
    try {
      final bool isValidContentType = request.validateContentType(
        ContentType.json.mimeType,
      );

      if (!isValidContentType) {
        return Response(
          HttpStatus.badRequest,
          body: 'Invalid request! Content-Type must be ${ContentType.json}',
        );
      }

      @Throws([FormatException])
      final Map<String, dynamic> json = await request.json();

      @Throws([BadRequestBodyException])
      final loginRequest = LoginRequest.validatedFromMap(json);

      // Get client information
      final String? userAgent = request.headers['user-agent'];
      final String? ipAddress = _getClientIp(request);

      @Throws([DatabaseException])
      final LoginResponse loginResponse = await _authRepository.login(
        loginRequest: loginRequest,
        userAgent: userAgent,
        ipAddress: ipAddress,
      );

      switch (loginResponse) {
        case LoginResponseSuccess():
          return JsonResponse(body: loginResponse.toMap());
        case LoginResponseError():
          return JsonResponse(
            statusCode: HttpStatus.unauthorized,
            body: loginResponse.toMap(),
          );
      }
    } on BadRequestContentTypeException catch (e) {
      return Response(HttpStatus.badRequest, body: 'Invalid request! $e');
    } on FormatException catch (e) {
      return Response(HttpStatus.badRequest, body: 'Invalid request! $e');
    } on BadRequestBodyException catch (e) {
      return Response(HttpStatus.badRequest, body: 'Invalid request! $e');
    } on DatabaseException catch (e) {
      switch (e) {
        case DBEuniqueViolation():
        case DBEunknown():
        case DBEbadCertificate():
        case DBEbadSchema():
        case DBEemptyResult():
          return Response(HttpStatus.notFound, body: 'User does not exist! $e');
      }
    }
  }

  String? _getClientIp(Request request) {
    // Try X-Forwarded-For header first (for clients behind proxy)
    final String? forwardedFor = request.headers['x-forwarded-for'];
    if (forwardedFor != null && forwardedFor.isNotEmpty) {
      return forwardedFor.split(',').first.trim();
    }

    // Fall back to direct connection info if available
    return (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)
        ?.remoteAddress
        .address;
  }

  @override
  Future<Response> register(Request request) async {
    try {
      final bool isValidContentType = request.validateContentType(
        ContentType.json.mimeType,
      );

      if (!isValidContentType) {
        return Response(
          HttpStatus.badRequest,
          body: 'Invalid request! Content-Type must be ${ContentType.json}',
        );
      }

      @Throws([FormatException])
      final Map<String, dynamic> json = await request.json();

      @Throws([BadRequestBodyException])
      final registerRequest = RegisterRequest.validatedFromMap(json);

      // Get client information
      final String? userAgent = request.headers['user-agent'];
      final String? ipAddress = _getClientIp(request);

      @Throws([DatabaseException])
      final RegisterResponse registerResponse = await _authRepository.register(
        registerRequest: registerRequest,

        userAgent: userAgent,
        ipAddress: ipAddress,
      );

      switch (registerResponse) {
        case RegisterResponseSuccess():
          return JsonResponse(
            statusCode: HttpStatus.created,
            body: registerResponse.toMap(),
          );
        case RegisterResponseError(:final error):
          switch (error) {
            case RegisterError.usernameAlreadyExists:
              return JsonResponse(
                statusCode: HttpStatus.conflict,
                body: registerResponse.toMap(),
              );
            case RegisterError.unknownRegisterError:
              return JsonResponse(
                statusCode: HttpStatus.internalServerError,
                body: registerResponse.toMap(),
              );
          }
      }
    } on DatabaseException catch (e) {
      switch (e) {
        case DBEuniqueViolation():
        case DBEunknown():
        case DBEbadCertificate():
        case DBEbadSchema():
        case DBEemptyResult():
      }

      return Response(
        HttpStatus.internalServerError,
        body: 'An error occurred! $e',
      );
    }
  }
}
