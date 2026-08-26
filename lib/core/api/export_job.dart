import 'api_error_mapper.dart';
import 'api_failure.dart';
import 'generated/clients/exports_api.dart';
import 'generated/models/export_job_out.dart';

/// How asking for a document the server builds separately ended.
sealed class DocumentOutcome {
  const DocumentOutcome();
}

final class DocumentReady extends DocumentOutcome {
  const DocumentReady(this.downloadUrl);

  final String downloadUrl;
}

/// The server is still working. It is not a failure: a manifest for a large
/// shipment takes a while, and whoever asked for it can ask again.
final class DocumentStillWorking extends DocumentOutcome {
  const DocumentStillWorking();
}

final class DocumentFailed extends DocumentOutcome {
  const DocumentFailed({this.failure, this.serverError});

  /// The call's failure, when there was one.
  ///
  /// It carries the failure and not a sentence: wording it in the data layer
  /// would pick a language without knowing which one is being read.
  final ApiFailure? failure;

  /// What the server said when the job ended in error. They are its words and
  /// they travel as they are, like any business-rule refusal.
  final String? serverError;
}

/// Asks for a document and waits for the server to generate it.
///
/// None of these endpoints returns a file: they return a job, and the document
/// is built separately. The wait is the same for all of them, so it lives here
/// and not inside the shipment — which is where it was born, when it was the
/// only one.
///
/// [start] is the call that queues the job. [wait] exists so a test does not
/// really wait.
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
