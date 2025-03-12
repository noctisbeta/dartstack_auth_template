import 'package:common/abstractions/models.dart';
import 'package:common/exceptions/throws.dart';
import 'package:meta/meta.dart';
import 'package:server/postgres/exceptions/database_exception.dart';

@immutable
final class UserDB extends DataModel {
  const UserDB({
    required this.id,
    required this.username,
    required this.hashedPassword,
    required this.salt,
    required this.createdAt,
    required this.updatedAt,
  });

  @Throws([DBEbadSchema])
  factory UserDB.validatedFromMap(Map<String, dynamic> map) => switch (map) {
    {
      'id': final int id,
      'username': final String username,
      'hashed_password': final String hashedPassword,
      'salt': final String salt,
      'created_at': final DateTime createdAt,
      'updated_at': final DateTime updatedAt,
    } =>
      UserDB(
        id: id,
        username: username,
        hashedPassword: hashedPassword,
        salt: salt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    _ => throw const DBEbadSchema('Invalid shape for UserDB.'),
  };

  final int id;
  final String username;
  final String hashedPassword;
  final String salt;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    username,
    hashedPassword,
    salt,
    createdAt,
    updatedAt,
  ];

  @override
  bool get stringify => true;

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'hashed_password': hashedPassword,
    'salt': salt,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  @override
  UserDB copyWith({
    int? id,
    String? username,
    String? hashedPassword,
    String? salt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserDB(
    id: id ?? this.id,
    username: username ?? this.username,
    hashedPassword: hashedPassword ?? this.hashedPassword,
    salt: salt ?? this.salt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
