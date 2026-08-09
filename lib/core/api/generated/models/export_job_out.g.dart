// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_job_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExportJobOut _$ExportJobOutFromJson(Map<String, dynamic> json) => ExportJobOut(
  error: json['error'] as String?,
  id: json['id'] as String,
  kind: json['kind'] as String,
  status: json['status'] as String,
  downloadUrl: json['download_url'] as String?,
);

Map<String, dynamic> _$ExportJobOutToJson(ExportJobOut instance) =>
    <String, dynamic>{
      'download_url': instance.downloadUrl,
      'error': instance.error,
      'id': instance.id,
      'kind': instance.kind,
      'status': instance.status,
    };
