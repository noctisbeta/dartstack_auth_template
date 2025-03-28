import 'package:common/abstractions/models.dart';
import 'package:common/annotations/throws.dart';
import 'package:common/exceptions/bad_map_shape_exception.dart';
import 'package:meta/meta.dart';

@immutable
final class RegisterRequest extends RequestDTO {
  const RegisterRequest({required this.username, required this.password});

  @Throws([BadMapShapeException])
  factory RegisterRequest.validatedFromMap(
    Map<String, dynamic> map,
  ) => switch (map) {
    {'username': final String username, 'password': final String password} =>
      RegisterRequest(username: username, password: password),
    _ =>
      throw const BadMapShapeException('Invalid map shape for RegisterRequest'),
  };

  final String username;
  final String password;

  @override
  Map<String, dynamic> toMap() => {'username': username, 'password': password};
  @override
  List<Object?> get props => [username, password];

  @override
  RegisterRequest copyWith({String? username, String? password}) =>
      RegisterRequest(
        username: username ?? this.username,
        password: password ?? this.password,
      );
}
