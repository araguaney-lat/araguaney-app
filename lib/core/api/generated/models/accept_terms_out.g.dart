// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_terms_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcceptTermsOut _$AcceptTermsOutFromJson(Map<String, dynamic> json) =>
    AcceptTermsOut(
      acceptedTermsVersion: json['accepted_terms_version'] as String,
      mustAcceptTerms: json['must_accept_terms'] as bool,
    );

Map<String, dynamic> _$AcceptTermsOutToJson(AcceptTermsOut instance) =>
    <String, dynamic>{
      'accepted_terms_version': instance.acceptedTermsVersion,
      'must_accept_terms': instance.mustAcceptTerms,
    };
