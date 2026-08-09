// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/risk_review_out.dart';
import '../models/risk_review_resolve_in.dart';

part 'risk_reviews_api.g.dart';

@RestApi()
abstract class RiskReviewsApi {
  factory RiskReviewsApi(Dio dio, {String? baseUrl}) = _RiskReviewsApi;

  /// List Risk Reviews
  @GET('/v1/risk-reviews')
  Future<List<RiskReviewOut>> listRiskReviewsV1RiskReviewsGet();

  /// Resolve Risk Review
  @POST('/v1/risk-reviews/{review_id}/resolve')
  Future<RiskReviewOut> resolveRiskReviewV1RiskReviewsReviewIdResolvePost({
    @Path('review_id') required String reviewId,
    @Body() required RiskReviewResolveIn body,
  });
}
