// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'accept_terms_out.g.dart';

/// Resultado de aceptar los términos: qué versión quedó registrada.
@JsonSerializable()
class AcceptTermsOut {
  const AcceptTermsOut({
    required this.acceptedTermsVersion,
    required this.mustAcceptTerms,
  });

  factory AcceptTermsOut.fromJson(Map<String, Object?> json) =>
      _$AcceptTermsOutFromJson(json);

  @JsonKey(name: 'accepted_terms_version')
  final String acceptedTermsVersion;
  @JsonKey(name: 'must_accept_terms')
  final bool mustAcceptTerms;

  Map<String, Object?> toJson() => _$AcceptTermsOutToJson(this);
}
