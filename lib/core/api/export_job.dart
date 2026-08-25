import 'api_error_mapper.dart';
import 'api_failure.dart';
import 'generated/clients/exports_api.dart';
import 'generated/models/export_job_out.dart';

/// Cómo terminó pedir un documento que el servidor arma aparte.
sealed class DocumentOutcome {
  const DocumentOutcome();
}

final class DocumentReady extends DocumentOutcome {
  const DocumentReady(this.downloadUrl);

  final String downloadUrl;
}

/// El servidor sigue trabajando. No es un fallo: un manifiesto de un envío
/// grande tarda, y quien lo pidió puede volver a pedirlo.
final class DocumentStillWorking extends DocumentOutcome {
  const DocumentStillWorking();
}

final class DocumentFailed extends DocumentOutcome {
  const DocumentFailed({this.failure, this.serverError});

  /// El fallo de la llamada, cuando lo hubo.
  ///
  /// Se lleva el fallo y no una frase: redactar en la capa de datos elegiría
  /// un idioma sin saber en cuál se está mirando.
  final ApiFailure? failure;

  /// Lo que dijo el servidor cuando el trabajo terminó en error. Son sus
  /// palabras y viajan tal cual, como cualquier rechazo de regla de negocio.
  final String? serverError;
}

/// Pide un documento y espera a que el servidor lo genere.
///
/// Ninguno de estos endpoints devuelve un archivo: devuelven un trabajo, y el
/// documento se arma aparte. La espera es la misma para todos, así que vive
/// aquí y no dentro del envío — que fue donde nació, cuando era el único.
///
/// [start] es la llamada que encola el trabajo. [wait] existe para que una
/// prueba no espere de verdad.
Future<DocumentOutcome> awaitDocument({
  required Future<ExportJobOut> Function() start,
  required ExportsApi exports,
  Future<void> Function(Duration) wait = Future.delayed,
  int maxPolls = 10,
  Duration pollInterval = const Duration(seconds: 2),
}) async {
  try {
    var current = await start();

    for (var attempt = 0; attempt < maxPolls; attempt++) {
      switch (current.status) {
        case 'DONE':
          final url = current.downloadUrl;
          return url == null ? const DocumentFailed() : DocumentReady(url);
        case 'FAILED':
          return DocumentFailed(serverError: current.error);
      }

      await wait(pollInterval);
      current = await exports.getExportJobV1ExportsJobIdGet(jobId: current.id);
    }

    return const DocumentStillWorking();
  } on Object catch (error) {
    return DocumentFailed(failure: ApiErrorMapper.fromAny(error));
  }
}
