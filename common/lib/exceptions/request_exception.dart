import 'package:meta/meta.dart';

@immutable
sealed class RequestException implements Exception {
  const RequestException(this.message);
  final String message;

  @override
  String toString() => 'RequestException: $message';
}

@immutable
final class BadRequestBodyException extends RequestException {
  const BadRequestBodyException(super.message);

  @override
  String toString() => 'BadRequestBodyException: $message';
}

@immutable
final class BadRequestContentTypeException extends RequestException {
  const BadRequestContentTypeException(super.message);

  @override
  String toString() => 'BadContentTypeException: $message';
}
