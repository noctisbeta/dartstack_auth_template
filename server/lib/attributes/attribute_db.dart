import 'package:common/abstractions/models.dart';
import 'package:common/exceptions/throws.dart';
import 'package:meta/meta.dart';
import 'package:server/postgres/exceptions/database_exception.dart';

@immutable
final class AttributeDB extends DataModel {
  const AttributeDB({
    required this.id,
    required this.entityId,
    required this.name,
    required this.dataType,
    required this.isPrimaryKey,
    required this.isForeignKey,
    required this.isNullable,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.referencedEntityId,
  });

  @Throws([DBEbadSchema])
  factory AttributeDB.validatedFromMap(Map<String, dynamic> map) =>
      switch (map) {
        {
          'id': final int id,
          'entity_id': final String entityId,
          'name': final String name,
          'data_type': final String dataType,
          'is_primary_key': final bool isPrimaryKey,
          'is_foreign_key': final bool isForeignKey,
          'is_nullable': final bool isNullable,
          'order': final int order,
          'created_at': final DateTime createdAt,
          'updated_at': final DateTime updatedAt,
        } =>
          AttributeDB(
            id: id,
            entityId: entityId,
            name: name,
            dataType: dataType,
            isPrimaryKey: isPrimaryKey,
            isForeignKey: isForeignKey,
            isNullable: isNullable,
            referencedEntityId: map['referenced_entity_id'] as String?,
            order: order,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        _ => throw const DBEbadSchema('Invalid shape for AttributeDB.'),
      };

  final int id;
  final String entityId;
  final String name;
  final String dataType;
  final bool isPrimaryKey;
  final bool isForeignKey;
  final bool isNullable;
  final String? referencedEntityId;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    entityId,
    name,
    dataType,
    isPrimaryKey,
    isForeignKey,
    isNullable,
    referencedEntityId,
    order,
    createdAt,
    updatedAt,
  ];

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'entity_id': entityId,
    'name': name,
    'data_type': dataType,
    'is_primary_key': isPrimaryKey,
    'is_foreign_key': isForeignKey,
    'is_nullable': isNullable,
    'referenced_entity_id': referencedEntityId,
    'order': order,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  @override
  AttributeDB copyWith({
    int? id,
    String? entityId,
    String? name,
    String? dataType,
    bool? isPrimaryKey,
    bool? isForeignKey,
    bool? isNullable,
    String? Function()? referencedEntityIdFn,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AttributeDB(
    id: id ?? this.id,
    entityId: entityId ?? this.entityId,
    name: name ?? this.name,
    dataType: dataType ?? this.dataType,
    isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
    isForeignKey: isForeignKey ?? this.isForeignKey,
    isNullable: isNullable ?? this.isNullable,
    referencedEntityId: referencedEntityIdFn?.call() ?? referencedEntityId,
    order: order ?? this.order,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
