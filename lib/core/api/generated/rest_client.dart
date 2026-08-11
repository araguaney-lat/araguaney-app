// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/boxes_api.dart';
import 'clients/pallets_api.dart';
import 'clients/auth_api.dart';
import 'clients/campaigns_api.dart';
import 'clients/catalog_api.dart';
import 'clients/center_applications_api.dart';
import 'clients/centers_api.dart';
import 'clients/users_api.dart';
import 'clients/client_api.dart';
import 'clients/donations_api.dart';
import 'clients/dashboard_api.dart';
import 'clients/email_failures_api.dart';
import 'clients/exports_api.dart';
import 'clients/incidents_api.dart';
import 'clients/intakes_api.dart';
import 'clients/messages_api.dart';
import 'clients/product_types_api.dart';
import 'clients/reports_api.dart';
import 'clients/requests_api.dart';
import 'clients/risk_reviews_api.dart';
import 'clients/shipments_api.dart';
import 'clients/studio_api.dart';
import 'clients/transfers_api.dart';

/// Acopio API `v0.1.0`
class RestClient {
  RestClient(Dio dio, {String? baseUrl}) : _dio = dio, _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.1.0';

  BoxesApi? _boxes;
  PalletsApi? _pallets;
  AuthApi? _auth;
  CampaignsApi? _campaigns;
  CatalogApi? _catalog;
  CenterApplicationsApi? _centerApplications;
  CentersApi? _centers;
  UsersApi? _users;
  ClientApi? _client;
  DonationsApi? _donations;
  DashboardApi? _dashboard;
  EmailFailuresApi? _emailFailures;
  ExportsApi? _exports;
  IncidentsApi? _incidents;
  IntakesApi? _intakes;
  MessagesApi? _messages;
  ProductTypesApi? _productTypes;
  ReportsApi? _reports;
  RequestsApi? _requests;
  RiskReviewsApi? _riskReviews;
  ShipmentsApi? _shipments;
  StudioApi? _studio;
  TransfersApi? _transfers;

  BoxesApi get boxes => _boxes ??= BoxesApi(_dio, baseUrl: _baseUrl);

  PalletsApi get pallets => _pallets ??= PalletsApi(_dio, baseUrl: _baseUrl);

  AuthApi get auth => _auth ??= AuthApi(_dio, baseUrl: _baseUrl);

  CampaignsApi get campaigns =>
      _campaigns ??= CampaignsApi(_dio, baseUrl: _baseUrl);

  CatalogApi get catalog => _catalog ??= CatalogApi(_dio, baseUrl: _baseUrl);

  CenterApplicationsApi get centerApplications =>
      _centerApplications ??= CenterApplicationsApi(_dio, baseUrl: _baseUrl);

  CentersApi get centers => _centers ??= CentersApi(_dio, baseUrl: _baseUrl);

  UsersApi get users => _users ??= UsersApi(_dio, baseUrl: _baseUrl);

  ClientApi get client => _client ??= ClientApi(_dio, baseUrl: _baseUrl);

  DonationsApi get donations =>
      _donations ??= DonationsApi(_dio, baseUrl: _baseUrl);

  DashboardApi get dashboard =>
      _dashboard ??= DashboardApi(_dio, baseUrl: _baseUrl);

  EmailFailuresApi get emailFailures =>
      _emailFailures ??= EmailFailuresApi(_dio, baseUrl: _baseUrl);

  ExportsApi get exports => _exports ??= ExportsApi(_dio, baseUrl: _baseUrl);

  IncidentsApi get incidents =>
      _incidents ??= IncidentsApi(_dio, baseUrl: _baseUrl);

  IntakesApi get intakes => _intakes ??= IntakesApi(_dio, baseUrl: _baseUrl);

  MessagesApi get messages =>
      _messages ??= MessagesApi(_dio, baseUrl: _baseUrl);

  ProductTypesApi get productTypes =>
      _productTypes ??= ProductTypesApi(_dio, baseUrl: _baseUrl);

  ReportsApi get reports => _reports ??= ReportsApi(_dio, baseUrl: _baseUrl);

  RequestsApi get requests =>
      _requests ??= RequestsApi(_dio, baseUrl: _baseUrl);

  RiskReviewsApi get riskReviews =>
      _riskReviews ??= RiskReviewsApi(_dio, baseUrl: _baseUrl);

  ShipmentsApi get shipments =>
      _shipments ??= ShipmentsApi(_dio, baseUrl: _baseUrl);

  StudioApi get studio => _studio ??= StudioApi(_dio, baseUrl: _baseUrl);

  TransfersApi get transfers =>
      _transfers ??= TransfersApi(_dio, baseUrl: _baseUrl);
}
