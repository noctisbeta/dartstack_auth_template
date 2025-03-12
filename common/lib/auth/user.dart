import 'package:common/abstractions/models.dart';
import 'package:common/auth/tokens/jwtoken.dart';
import 'package:common/auth/tokens/refresh_token_wrapper.dart';
import 'package:common/exceptions/bad_map_shape_exception.dart';
import 'package:common/exceptions/throws.dart';
import 'package:meta/meta.dart';

@immutable
final class User extends DataModel {
  const User({
    required this.username,
    required this.token,
    required this.refreshTokenWrapper,
  });

  @Throws([BadMapShapeException])
  factory User.validatedFromMap(Map<String, dynamic> map) => switch (map) {
    {
      'username': final String username,
      'token': final JWToken token,
      'refresh_token_wrapper':
          final Map<String, dynamic> refreshTokenWrapperMap,
    } =>
      User(
        username: username,
        token: token,
        refreshTokenWrapper: RefreshTokenWrapper.validatedFromMap(
          refreshTokenWrapperMap,
        ),
      ),
    _ => throw const BadMapShapeException('Invalid map format for User'),
  };

  final String username;
  final JWToken token;
  final RefreshTokenWrapper refreshTokenWrapper;

  @override
  Map<String, dynamic> toMap() => {
    'username': username,
    'token': token,
    'refresh_token_wrapper': refreshTokenWrapper.toMap(),
  };

  @override
  List<Object?> get props => [username, token, refreshTokenWrapper];

  @override
  User copyWith({
    String? username,
    JWToken? token,
    RefreshTokenWrapper? refreshTokenWrapper,
  }) => User(
    username: username ?? this.username,
    token: token ?? this.token,
    refreshTokenWrapper: refreshTokenWrapper ?? this.refreshTokenWrapper,
  );
}
