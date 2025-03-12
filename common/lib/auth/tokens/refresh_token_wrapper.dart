import 'package:common/abstractions/models.dart';
import 'package:common/auth/tokens/refresh_token.dart';
import 'package:common/exceptions/bad_map_shape_exception.dart';
import 'package:common/exceptions/throws.dart';
import 'package:meta/meta.dart';

@immutable
final class RefreshTokenWrapper extends DataModel {
  const RefreshTokenWrapper({
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
  });

  @Throws([BadMapShapeException])
  factory RefreshTokenWrapper.validatedFromMap(Map<String, dynamic> map) =>
      switch (map) {
        {
          'refresh_token': final String refreshToken,
          'refresh_token_expires_at': final String refreshTokenExpiresAt,
        } =>
          RefreshTokenWrapper(
            refreshToken: RefreshToken.fromRefreshTokenString(refreshToken),
            refreshTokenExpiresAt: DateTime.parse(refreshTokenExpiresAt),
          ),
        _ =>
          throw const BadMapShapeException(
            'Invalid map format for RefreshTokenWrapper',
          ),
      };

  final RefreshToken refreshToken;
  final DateTime refreshTokenExpiresAt;

  @override
  List<Object?> get props => [refreshToken, refreshTokenExpiresAt];

  @override
  Map<String, dynamic> toMap() => {
    'refresh_token': refreshToken.value,
    'refresh_token_expires_at': refreshTokenExpiresAt.toIso8601String(),
  };

  @override
  RefreshTokenWrapper copyWith({
    RefreshToken? refreshToken,
    DateTime? refreshTokenExpiresAt,
  }) => RefreshTokenWrapper(
    refreshToken: refreshToken ?? this.refreshToken,
    refreshTokenExpiresAt: refreshTokenExpiresAt ?? this.refreshTokenExpiresAt,
  );
}
