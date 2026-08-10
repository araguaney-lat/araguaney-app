import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

/// Vacía el modelo de lectura.
///
/// Se expone como función y no como la base entera para que `core/auth` pueda
/// borrar el cache al cambiar de persona sin conocer Drift. La sesión decide
/// *cuándo* se borra; la base sabe *qué* se borra.
typedef ReadModelReset = Future<void> Function();

final readModelResetProvider = Provider<ReadModelReset>(
  (ref) =>
      () => ref.read(appDatabaseProvider).clearReadModel(),
);
