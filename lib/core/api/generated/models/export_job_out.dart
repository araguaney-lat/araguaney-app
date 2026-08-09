// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'export_job_out.g.dart';

@JsonSerializable()
class ExportJobOut {
  const ExportJobOut({
    required this.error,
    required this.id,
    required this.kind,
    required this.status,
    this.downloadUrl,
  });

  factory ExportJobOut.fromJson(Map<String, Object?> json) =>
      _$ExportJobOutFromJson(json);

  @JsonKey(name: 'download_url')
  final String? downloadUrl;
  final String? error;
  final String id;
  final String kind;
  final String status;

  Map<String, Object?> toJson() => _$ExportJobOutToJson(this);
}
