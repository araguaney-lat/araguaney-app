// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'accept_terms_request.g.dart';

@JsonSerializable()
class AcceptTermsRequest {
  const AcceptTermsRequest({required this.version});

  factory AcceptTermsRequest.fromJson(Map<String, Object?> json) =>
      _$AcceptTermsRequestFromJson(json);

  final String version;

  Map<String, Object?> toJson() => _$AcceptTermsRequestToJson(this);
}
