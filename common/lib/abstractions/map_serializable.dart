import 'package:meta/meta.dart';

@immutable
//
// ignore: one_member_abstracts
abstract interface class MapSerializable {
  Map<String, dynamic> toMap();
}
