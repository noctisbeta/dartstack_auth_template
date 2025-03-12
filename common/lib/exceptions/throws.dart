import 'package:meta/meta.dart';

@immutable
final class Throws<T extends Type> {
  const Throws(this.exceptions);

  final List<T> exceptions;
}
