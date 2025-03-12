import 'package:common/abstractions/models.dart';
import 'package:common/auth/register/register_error.dart';
import 'package:common/auth/user.dart';
import 'package:common/exceptions/response_exception.dart';
import 'package:common/exceptions/throws.dart';
import 'package:meta/meta.dart';

@immutable
sealed class RegisterResponse extends ResponseDTO {
  const RegisterResponse();
}

@immutable
final class RegisterResponseSuccess extends RegisterResponse {
  const RegisterResponseSuccess({required this.user});

  @Throws([BadResponseBodyException])
  factory RegisterResponseSuccess.validatedFromMap(Map<String, dynamic> map) =>
      switch (map) {
        {'user': final Map<String, dynamic> user} => RegisterResponseSuccess(
          user: User.validatedFromMap(user),
        ),
        _ =>
          throw const BadResponseBodyException(
            'Invalid map format for RegisterResponseSuccess',
          ),
      };

  final User user;

  @override
  Map<String, dynamic> toMap() => {'user': user.toMap()};

  @override
  List<Object?> get props => [user];

  @override
  RegisterResponseSuccess copyWith({User? user}) =>
      RegisterResponseSuccess(user: user ?? this.user);
}

@immutable
final class RegisterResponseError extends RegisterResponse {
  const RegisterResponseError({required this.message, required this.error});

  factory RegisterResponseError.validatedFromMap(Map<String, dynamic> map) =>
      switch (map) {
        {'message': final String message, 'error': final String error} =>
          RegisterResponseError(
            message: message,
            error: RegisterError.fromString(error),
          ),
        _ =>
          throw const BadResponseBodyException(
            'Invalid map format for RegisterResponseError',
          ),
      };

  final String message;

  final RegisterError error;

  @override
  Map<String, dynamic> toMap() => {
    'message': message,
    'error': error.toString(),
  };

  @override
  List<Object?> get props => [message, error];

  @override
  RegisterResponseError copyWith({String? message, RegisterError? error}) =>
      RegisterResponseError(
        message: message ?? this.message,
        error: error ?? this.error,
      );
}
