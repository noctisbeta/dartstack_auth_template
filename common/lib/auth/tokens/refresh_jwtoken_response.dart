import 'package:common/abstractions/models.dart';
import 'package:common/annotations/throws.dart';
import 'package:common/auth/tokens/jwtoken.dart';
import 'package:common/auth/tokens/refresh_error.dart';
import 'package:common/auth/tokens/refresh_token_wrapper.dart';
import 'package:common/exceptions/bad_map_shape_exception.dart';
import 'package:meta/meta.dart';

@immutable
sealed class RefreshJWTokenResponse extends ResponseDTO {
  const RefreshJWTokenResponse();
}

@immutable
final class RefreshJWTokenResponseSuccess extends RefreshJWTokenResponse {
  const RefreshJWTokenResponseSuccess({
    required this.refreshTokenWrapper,
    required this.jwToken,
  });

  @Throws([BadMapShapeException])
  factory RefreshJWTokenResponseSuccess.validatedFromMap(
    Map<String, dynamic> map,
  ) => switch (map) {
    {
      'refresh_token_wrapper': final Map<String, dynamic> refreshTokenWrapper,
      'jw_token': final String jwTokenString,
    } =>
      RefreshJWTokenResponseSuccess(
        refreshTokenWrapper: RefreshTokenWrapper.validatedFromMap(
          refreshTokenWrapper,
        ),
        jwToken: JWToken.fromJwtString(jwTokenString),
      ),
    _ =>
      throw const BadMapShapeException(
        'Invalid map format for RefreshJWTokenResponseSuccess',
      ),
  };
  final RefreshTokenWrapper refreshTokenWrapper;
  final JWToken jwToken;

  @override
  List<Object?> get props => [refreshTokenWrapper, jwToken];

  @override
  Map<String, dynamic> toMap() => {
    'refresh_token_wrapper': refreshTokenWrapper.toMap(),
    'jw_token': jwToken.toString(),
  };

  @override
  RefreshJWTokenResponseSuccess copyWith({
    RefreshTokenWrapper? refreshTokenWrapper,
    JWToken? jwToken,
  }) => RefreshJWTokenResponseSuccess(
    refreshTokenWrapper: refreshTokenWrapper ?? this.refreshTokenWrapper,
    jwToken: jwToken ?? this.jwToken,
  );
}

@immutable
final class RefreshJWTokenResponseError extends RefreshJWTokenResponse {
  const RefreshJWTokenResponseError({
    required this.message,
    required this.error,
  });

  @Throws([BadMapShapeException])
  factory RefreshJWTokenResponseError.validatedFromMap(
    Map<String, dynamic> map,
  ) => switch (map) {
    {'message': final String message, 'error': final String error} =>
      RefreshJWTokenResponseError(
        message: message,
        error: RefreshError.fromString(error),
      ),
    _ =>
      throw const BadMapShapeException(
        'Invalid map format for RefreshJWTokenResponseError',
      ),
  };

  final String message;
  final RefreshError error;

  @override
  List<Object?> get props => [message, error];

  @override
  Map<String, dynamic> toMap() => {
    'message': message,
    'error': error.toString(),
  };

  @override
  RefreshJWTokenResponseError copyWith({
    String? message,
    RefreshError? error,
  }) => RefreshJWTokenResponseError(
    message: message ?? this.message,
    error: error ?? this.error,
  );
}
