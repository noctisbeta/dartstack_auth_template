import 'package:common/abstractions/models.dart';
import 'package:common/auth/tokens/refresh_token.dart';
import 'package:common/exceptions/bad_map_shape_exception.dart';
import 'package:common/exceptions/throws.dart';
import 'package:meta/meta.dart';

@immutable
final class RefreshTokenRequest extends RequestDTO {
  const RefreshTokenRequest({required this.refreshToken});

  @Throws([BadMapShapeException])
  factory RefreshTokenRequest.validatedFromMap(Map<String, dynamic> map) =>
      switch (map) {
        {'refresh_token': final String refreshToken} => RefreshTokenRequest(
          refreshToken: RefreshToken.fromRefreshTokenString(refreshToken),
        ),
        _ =>
          throw const BadMapShapeException(
            'Invalid map format for RefreshTokenRequest',
          ),
      };

  final RefreshToken refreshToken;

  @override
  Map<String, dynamic> toMap() => {'refresh_token': refreshToken.value};

  @override
  List<Object?> get props => [refreshToken];

  @override
  RefreshTokenRequest copyWith({RefreshToken? refreshToken}) =>
      RefreshTokenRequest(refreshToken: refreshToken ?? this.refreshToken);
}
