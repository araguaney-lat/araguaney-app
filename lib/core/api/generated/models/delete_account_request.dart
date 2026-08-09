// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'delete_account_request.g.dart';

/// Password confirmation for self-service account deletion (ARCO cancellation).
@JsonSerializable()
class DeleteAccountRequest {
  const DeleteAccountRequest({required this.password});

  factory DeleteAccountRequest.fromJson(Map<String, Object?> json) =>
      _$DeleteAccountRequestFromJson(json);

  final String password;

  Map<String, Object?> toJson() => _$DeleteAccountRequestToJson(this);
}
