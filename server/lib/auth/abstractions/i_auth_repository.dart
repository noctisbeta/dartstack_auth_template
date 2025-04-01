import 'package:common/auth/login/login_request.dart';
import 'package:common/auth/login/login_response.dart';
import 'package:common/auth/register/register_request.dart';
import 'package:common/auth/register/register_response.dart';
import 'package:common/auth/tokens/refresh_jwtoken_request.dart';
import 'package:common/auth/tokens/refresh_jwtoken_response.dart';

abstract interface class IAuthRepository {
  Future<RefreshJWTokenResponse> refreshJWToken({
    required RefreshJWTokenRequest refreshTokenRequest,
    required String? ipAddress,
    required String? userAgent,
  });

  Future<LoginResponse> login({
    required LoginRequest loginRequest,
    String? ipAddress,
    String? userAgent,
  });

  Future<RegisterResponse> register({
    required RegisterRequest registerRequest,
    String? ipAddress,
    String? userAgent,
  });
}
