import 'package:common/abstractions/models.dart';
import 'package:common/annotations/throws.dart';
import 'package:common/auth/tokens/refresh_token.dart';
import 'package:common/exceptions/bad_map_shape_exception.dart';
import 'package:meta/meta.dart';

@immutable
final class RefreshJWTokenRequest extends RequestDTO {
  const RefreshJWTokenRequest({required this.refreshToken});

  @Throws([BadMapShapeException])
  factory RefreshJWTokenRequest.validatedFromMap(Map<String, dynamic> map) =>
      switch (map) {
        {'refresh_token': final String refreshToken} => RefreshJWTokenRequest(
          refreshToken: RefreshToken.fromRefreshTokenString(refreshToken),
        ),
        _ =>
          throw const BadMapShapeException(
            'Invalid map format for RefreshJWTokenRequest',
          ),
      };

  final RefreshToken refreshToken;

  @override
  Map<String, dynamic> toMap() => {'refresh_token': refreshToken};

  @override
  List<Object?> get props => [refreshToken];

  @override
  RefreshJWTokenRequest copyWith({RefreshToken? refreshToken}) =>
      RefreshJWTokenRequest(refreshToken: refreshToken ?? this.refreshToken);
}
