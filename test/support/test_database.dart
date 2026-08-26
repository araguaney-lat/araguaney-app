import 'package:araguaney_app/core/api/generated/clients/boxes_api.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';

/// A real in-memory database.
///
/// What touches Drift is tested against real SQLite and not against a double:
/// half the errors of this layer live in the transactions and in the table's
/// constraints, and a double obeys them by definition.
AppDatabase openTestDatabase() => AppDatabase(NativeDatabase.memory());

/// A boxes client no double ever gets to use. It exists because the real
/// repositories require it in their constructor and the doubles inherit from
/// them.
BoxesApi unusedBoxesApi() => BoxesApi(Dio());
