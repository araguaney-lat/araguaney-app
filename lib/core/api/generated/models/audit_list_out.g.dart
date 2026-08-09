// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditListOut _$AuditListOutFromJson(Map<String, dynamic> json) => AuditListOut(
  items: (json['items'] as List<dynamic>)
      .map((e) => AuditLogOut.fromJson(e as Map<String, dynamic>))
      .toList(),
  limit: (json['limit'] as num).toInt(),
  offset: (json['offset'] as num).toInt(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$AuditListOutToJson(AuditListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
      'limit': instance.limit,
      'offset': instance.offset,
      'total': instance.total,
    };
