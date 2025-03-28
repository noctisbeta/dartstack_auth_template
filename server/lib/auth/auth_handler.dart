import 'dart:io';

import 'package:common/annotations/throws.dart';
import 'package:common/auth/login/login_request.dart';
import 'package:common/auth/login/login_response.dart';
import 'package:common/auth/register/register_error.dart';
import 'package:common/auth/register/register_request.dart';
import 'package:common/auth/register/register_response.dart';
import 'package:common/auth/tokens/refresh_jwtoken_request.dart';
import 'package:common/auth/tokens/refresh_jwtoken_response.dart';
import 'package:common/exceptions/request_exception.dart';
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
  Future<Response> refreshJWToken(Request request) async {
    try {
      @Throws([FormatException])
      final Map<String, dynamic> json = await request.json();

      final refreshTokenRequest = RefreshJWTokenRequest.validatedFromMap(json);

      final RefreshJWTokenResponse refreshTokenResponse = await _authRepository
          .refreshJWToken(refreshTokenRequest);

      switch (refreshTokenResponse) {
        case RefreshJWTokenResponseSuccess():
          return JsonResponse(body: refreshTokenResponse.toMap());
        case RefreshJWTokenResponseError():
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
      @Throws([FormatException])
      final Map<String, dynamic> json = await request.json();

      @Throws([BadRequestBodyException])
      final loginRequest = LoginRequest.validatedFromMap(json);

      final (
        ipAddr: String? ipAddr,
        userAgent: String? userAgent,
      ) = _getClientInformation(request);

      @Throws([DatabaseException])
      final LoginResponse loginResponse = await _authRepository.login(
        loginRequest: loginRequest,
        userAgent: userAgent,
        ipAddress: ipAddr,
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

  @override
  Future<Response> register(Request request) async {
    try {
      @Throws([FormatException])
      final Map<String, dynamic> json = await request.json();

      @Throws([BadRequestBodyException])
      final registerRequest = RegisterRequest.validatedFromMap(json);

      final (
        ipAddr: String? ipAddr,
        userAgent: String? userAgent,
      ) = _getClientInformation(request);

      @Throws([DatabaseException])
      final RegisterResponse registerResponse = await _authRepository.register(
        registerRequest: registerRequest,
        userAgent: userAgent,
        ipAddress: ipAddr,
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
    } on FormatException catch (e) {
      return Response(
        HttpStatus.badRequest,
        body: 'Invalid request! Bad JSON. $e',
      );
    } on BadRequestBodyException catch (e) {
      return Response(
        HttpStatus.badRequest,
        body: 'Invalid request! Bad request body. $e',
      );
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

  ({String? ipAddr, String? userAgent}) _getClientInformation(Request request) {
    final String? userAgent = request.headers[HttpHeaders.userAgentHeader];

    // Try X-Forwarded-For header first (for clients behind proxy)
    final String? forwardedFor = request.headers['x-forwarded-for'];
    if (forwardedFor != null && forwardedFor.isNotEmpty) {
      final String ipAddr = forwardedFor.split(',').first.trim();
      return (ipAddr: ipAddr, userAgent: userAgent);
    }

    // Fall back to direct connection info if available
    final String? ipAddr =
        (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)
            ?.remoteAddress
            .address;

    return (ipAddr: ipAddr, userAgent: userAgent);
  }
}
