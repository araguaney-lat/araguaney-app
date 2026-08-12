import 'package:araguaney_app/core/api/generated/clients/boxes_api.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';

/// Base real en memoria.
///
/// Lo que toca Drift se prueba contra SQLite de verdad y no contra un doble:
/// la mitad de los errores de esta capa viven en las transacciones y en las
/// restricciones de la tabla, y un doble las obedece por definición.
AppDatabase openTestDatabase() => AppDatabase(NativeDatabase.memory());

/// Cliente de cajas que ningún doble llega a usar. Existe porque los
/// repositorios reales lo exigen en su constructor y los dobles heredan de
/// ellos.
BoxesApi unusedBoxesApi() => BoxesApi(Dio());
