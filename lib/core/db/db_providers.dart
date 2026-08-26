import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

/// Empties the read model.
///
/// It is exposed as a function rather than the whole database so `core/auth`
/// can clear the cache when the person changes without knowing about Drift. The
/// session decides *when* it is cleared; the database knows *what* is.
typedef ReadModelReset = Future<void> Function();

final readModelResetProvider = Provider<ReadModelReset>(
  (ref) =>
      () => ref.read(appDatabaseProvider).clearReadModel(),
);
