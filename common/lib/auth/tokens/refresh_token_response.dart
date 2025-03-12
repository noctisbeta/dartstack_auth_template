import 'package:common/abstractions/models.dart';
import 'package:common/auth/tokens/jwtoken.dart';
import 'package:common/auth/tokens/refresh_error.dart';
import 'package:common/auth/tokens/refresh_token_wrapper.dart';
import 'package:common/exceptions/bad_map_shape_exception.dart';
import 'package:common/exceptions/throws.dart';
import 'package:meta/meta.dart';

@immutable
sealed class RefreshTokenResponse extends ResponseDTO {
  const RefreshTokenResponse();
}

@immutable
final class RefreshTokenResponseSuccess extends RefreshTokenResponse {
  const RefreshTokenResponseSuccess({
    required this.refreshTokenWrapper,
    required this.jwToken,
  });

  @Throws([BadMapShapeException])
  factory RefreshTokenResponseSuccess.validatedFromMap(
    Map<String, dynamic> map,
  ) => switch (map) {
    {
      'refresh_token_wrapper': final Map<String, dynamic> refreshTokenWrapper,
      'jw_token': final String jwTokenString,
    } =>
      RefreshTokenResponseSuccess(
        refreshTokenWrapper: RefreshTokenWrapper.validatedFromMap(
          refreshTokenWrapper,
        ),
        jwToken: JWToken.fromJwtString(jwTokenString),
      ),
    _ =>
      throw const BadMapShapeException(
        'Invalid map format for RefreshTokenResponseSuccess',
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
  RefreshTokenResponseSuccess copyWith({
    RefreshTokenWrapper? refreshTokenWrapper,
    JWToken? jwToken,
  }) => RefreshTokenResponseSuccess(
    refreshTokenWrapper: refreshTokenWrapper ?? this.refreshTokenWrapper,
    jwToken: jwToken ?? this.jwToken,
  );
}

@immutable
final class RefreshTokenResponseError extends RefreshTokenResponse {
  const RefreshTokenResponseError({required this.message, required this.error});

  @Throws([BadMapShapeException])
  factory RefreshTokenResponseError.validatedFromMap(
    Map<String, dynamic> map,
  ) => switch (map) {
    {'message': final String message, 'error': final String error} =>
      RefreshTokenResponseError(
        message: message,
        error: RefreshError.fromString(error),
      ),
    _ =>
      throw const BadMapShapeException(
        'Invalid map format for RefreshTokenResponseError',
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
  RefreshTokenResponseError copyWith({String? message, RefreshError? error}) =>
      RefreshTokenResponseError(
        message: message ?? this.message,
        error: error ?? this.error,
      );
}
