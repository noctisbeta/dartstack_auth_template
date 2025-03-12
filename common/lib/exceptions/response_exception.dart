import 'package:meta/meta.dart';

@immutable
sealed class ResponseException implements Exception {
  const ResponseException(this.message);
  final String message;

  @override
  String toString() => 'ResponseException: $message';
}

@immutable
final class BadResponseBodyException extends ResponseException {
  const BadResponseBodyException(super.message);

  @override
  String toString() => 'BadResponseBodyException: $message';
}
