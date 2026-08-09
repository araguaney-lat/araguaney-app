// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'audit_log_out.g.dart';

@JsonSerializable()
class AuditLogOut {
  const AuditLogOut({
    required this.action,
    required this.createdAt,
    required this.entityId,
    required this.entityType,
    required this.extra,
    required this.id,
    required this.ip,
    required this.userId,
  });

  factory AuditLogOut.fromJson(Map<String, Object?> json) =>
      _$AuditLogOutFromJson(json);

  final String action;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'entity_id')
  final String? entityId;
  @JsonKey(name: 'entity_type')
  final String entityType;
  final dynamic extra;
  final String id;
  final String? ip;
  @JsonKey(name: 'user_id')
  final String? userId;

  Map<String, Object?> toJson() => _$AuditLogOutToJson(this);
}
