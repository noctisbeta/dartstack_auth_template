import 'package:common/abstractions/models.dart';
import 'package:common/annotations/throws.dart';
import 'package:meta/meta.dart';
import 'package:server/postgres/database_exception.dart';

@immutable
final class RefreshTokenDB extends DataModel {
  const RefreshTokenDB({
    required this.id,
    required this.userId,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    this.ipAddress,
    this.userAgent,
    this.isUsed = false,
    this.usedAt,
    this.previousToken,
    this.isRevoked = false,
    this.revokedAt,
    this.revokeReason,
  });

  @Throws([DBEbadSchema])
  factory RefreshTokenDB.validatedFromMap(Map<String, dynamic> map) =>
      switch (map) {
        {
          'id': final int id,
          'user_id': final int userId,
          'token': final String token,
          'created_at': final DateTime createdAt,
          'expires_at': final DateTime expiresAt,
          'is_used': final bool isUsed,
          'used_at': final DateTime? usedAt,
          'previous_token': final String? previousToken,
          'user_agent': final String? userAgent,
          'ip_address': final String? ipAddress,
          'is_revoked': final bool isRevoked,
          'revoked_at': final DateTime? revokedAt,
          'revoke_reason': final String? revokeReason,
        } =>
          RefreshTokenDB(
            id: id,
            userId: userId,
            token: token,
            createdAt: createdAt,
            expiresAt: expiresAt,
            ipAddress: ipAddress,
            userAgent: userAgent,
            isUsed: isUsed,
            usedAt: usedAt,
            previousToken: previousToken,
            isRevoked: isRevoked,
            revokedAt: revokedAt,
            revokeReason: revokeReason,
          ),
        _ => throw DBEbadSchema('Invalid shape for RefreshTokenDB. Got $map'),
      };

  final int id;
  final int userId;
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime? usedAt;
  final String? previousToken;
  final String? userAgent;
  final String? ipAddress;
  final bool isRevoked;
  final DateTime? revokedAt;
  final String? revokeReason;

  @override
  List<Object?> get props => [
    id,
    userId,
    token,
    createdAt,
    expiresAt,
    ipAddress,
    userAgent,
    isUsed,
    usedAt,
    previousToken,
    isRevoked,
    revokedAt,
    revokeReason,
  ];

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'token': token,
    'created_at': createdAt.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
    'ip_address': ipAddress,
    'user_agent': userAgent,
    'is_used': isUsed,
    'used_at': usedAt?.toIso8601String(),
    'previous_token': previousToken,
    'is_revoked': isRevoked,
    'revoked_at': revokedAt?.toIso8601String(),
    'revoke_reason': revokeReason,
  };

  @override
  RefreshTokenDB copyWith({
    int? id,
    int? userId,
    String? token,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? Function()? ipAddressFn,
    String? Function()? userAgentFn,
    bool? isUsed,
    DateTime? Function()? usedAtFn,
    String? Function()? previousTokenFn,
    bool? isRevoked,
    DateTime? Function()? revokedAtFn,
    String? Function()? revokeReasonFn,
  }) => RefreshTokenDB(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    token: token ?? this.token,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
    ipAddress: ipAddressFn?.call() ?? ipAddress,
    userAgent: userAgentFn?.call() ?? userAgent,
    isUsed: isUsed ?? this.isUsed,
    usedAt: usedAtFn?.call() ?? usedAt,
    previousToken: previousTokenFn?.call() ?? previousToken,
    isRevoked: isRevoked ?? this.isRevoked,
    revokedAt: revokedAtFn?.call() ?? revokedAt,
    revokeReason: revokeReasonFn?.call() ?? revokeReason,
  );
}
