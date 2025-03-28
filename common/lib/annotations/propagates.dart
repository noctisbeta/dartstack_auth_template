import 'package:meta/meta.dart';

@immutable
final class Propagates<T> {
  const Propagates(this.exceptions);

  final List<T> exceptions;
}
