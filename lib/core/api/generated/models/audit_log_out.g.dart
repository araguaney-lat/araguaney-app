// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditLogOut _$AuditLogOutFromJson(Map<String, dynamic> json) => AuditLogOut(
  action: json['action'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  entityId: json['entity_id'] as String?,
  entityType: json['entity_type'] as String,
  extra: json['extra'],
  id: json['id'] as String,
  ip: json['ip'] as String?,
  userId: json['user_id'] as String?,
);

Map<String, dynamic> _$AuditLogOutToJson(AuditLogOut instance) =>
    <String, dynamic>{
      'action': instance.action,
      'created_at': instance.createdAt.toIso8601String(),
      'entity_id': instance.entityId,
      'entity_type': instance.entityType,
      'extra': instance.extra,
      'id': instance.id,
      'ip': instance.ip,
      'user_id': instance.userId,
    };
