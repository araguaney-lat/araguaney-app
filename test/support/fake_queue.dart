import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/features/intake/data/box_code_repository.dart';
import 'package:araguaney_app/features/intake/data/capture_queue_repository.dart';
import 'package:araguaney_app/features/intake/domain/intake_draft.dart';

import 'test_database.dart';

/// Dobles de la cola y del bloque de códigos, para las pruebas de interfaz.
///
/// Existen por una limitación del entorno, no por preferencia: en un
/// `testWidgets` el reloj es falso y una escritura real a SQLite disparada
/// desde dentro del árbol de widgets no llega a completarse nunca. Lo que hace
/// la base de verdad ya está cubierto contra SQLite en memoria en las pruebas
/// de `capture_queue_test.dart` y `box_code_repository_test.dart`; aquí se mide
/// otra cosa: qué hace la pantalla.
///
/// Extienden a las clases reales en lugar de imitar una interfaz para que la
/// firma no pueda divergir en silencio.
class FakeCaptureQueue extends CaptureQueueRepository {
  FakeCaptureQueue(AppDatabase database) : super(database: database);

  /// Las capturas que la pantalla mandó a la cola, en orden.
  final enqueued = <({IntakeDraft draft, String userId})>[];

  @override
  Future<void> enqueue({
    required IntakeDraft draft,
    required String userId,
  }) async => enqueued.add((draft: draft, userId: userId));
}

class FakeBoxCodes extends BoxCodeRepository {
  FakeBoxCodes({required super.database, List<String>? pool})
    : pool = [...?pool],
      super(api: unusedBoxesApi());

  /// Códigos disponibles. Se vacía a medida que se reparten, igual que el
  /// bloque real.
  final List<String> pool;

  @override
  Future<List<String>> take(
    int count, {
    required String userId,
    String? centerId,
  }) async {
    final taken = pool.take(count).toList(growable: false);
    pool.removeRange(0, taken.length);
    return taken;
  }
}
