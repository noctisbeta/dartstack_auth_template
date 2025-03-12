import 'package:common/abstractions/models.dart';
import 'package:common/auth/login/login_error.dart';
import 'package:common/auth/user.dart';
import 'package:common/exceptions/response_exception.dart';
import 'package:meta/meta.dart';

@immutable
sealed class LoginResponse extends ResponseDTO {
  const LoginResponse();
}

@immutable
final class LoginResponseSuccess extends LoginResponse {
  const LoginResponseSuccess({required this.user});

  factory LoginResponseSuccess.validatedFromMap(Map<String, dynamic> map) =>
      switch (map) {
        {'user': final Map<String, dynamic> user} => LoginResponseSuccess(
          user: User.validatedFromMap(user),
        ),
        _ =>
          throw const BadResponseBodyException(
            'Invalid map format for RegisterResponse',
          ),
      };

  final User user;

  @override
  Map<String, dynamic> toMap() => {'user': user.toMap()};

  @override
  List<Object?> get props => [user];

  @override
  LoginResponseSuccess copyWith({User? user}) =>
      LoginResponseSuccess(user: user ?? this.user);
}

@immutable
final class LoginResponseError extends LoginResponse {
  const LoginResponseError({required this.message, required this.error});

  factory LoginResponseError.validatedFromMap(
    Map<String, dynamic> map,
  ) => switch (map) {
    {'message': final String message, 'error': final String error} =>
      LoginResponseError(message: message, error: LoginError.fromString(error)),
    _ =>
      throw const BadResponseBodyException(
        'Invalid map format for LoginResponseError',
      ),
  };

  final String message;

  final LoginError error;

  @override
  Map<String, dynamic> toMap() => {
    'message': message,
    'error': error.toString(),
  };

  @override
  List<Object?> get props => [message, error];

  @override
  LoginResponseError copyWith({String? message, LoginError? error}) =>
      LoginResponseError(
        message: message ?? this.message,
        error: error ?? this.error,
      );
}
