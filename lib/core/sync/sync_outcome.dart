import '../api/api_failure.dart';

/// Resultado de refrescar un recurso cacheado.
///
/// Un refresco **nunca lanza** hacia la interfaz. La pantalla ya tiene datos
/// que mostrar; lo que necesita saber es si siguen siendo los últimos y, si no,
/// por qué. Devolverlo como valor obliga a decidirlo en cada sitio en vez de
/// dejar que una excepción se lleve la pantalla por delante.
sealed class SyncOutcome {
  const SyncOutcome();
}

final class SyncSucceeded extends SyncOutcome {
  const SyncSucceeded({required this.at, required this.itemCount});

  final DateTime at;
  final int itemCount;
}

final class SyncFailed extends SyncOutcome {
  const SyncFailed(this.failure);

  final ApiFailure failure;

  /// Si el fallo fue de red. Lo usa el estado de conexión: un rechazo del
  /// servidor prueba que el servidor está ahí, y no debe marcarse sin señal.
  bool get isNetworkFailure => failure is NetworkFailure;
}
