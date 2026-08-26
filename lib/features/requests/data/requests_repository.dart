import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/requests_api.dart';
import '../../../core/api/generated/models/request_create.dart';
import '../../../core/api/generated/models/request_message_create.dart';
import '../../../core/api/generated/models/request_message_out.dart';
import '../../../core/api/generated/models/request_out.dart';
import '../../../core/api/generated/models/request_status_patch.dart';

/// The states of `REQUEST_STATUSES` in the backend, in the order a request
/// travels: it is opened, somebody takes it, it is resolved, it is closed.
abstract final class RequestStatus {
  static const open = 'OPEN';
  static const inProgress = 'IN_PROGRESS';
  static const resolved = 'RESOLVED';
  static const closed = 'CLOSED';

  static const all = [open, inProgress, resolved, closed];
}

/// What a category of the request matched against, and how much of it exists.
///
/// The endpoint answers an untyped list, so the shape is read by hand and in
/// one place only — it is request 4's family of problems, and this is the
/// second body in the contract that arrives without a schema.
///
/// A row that does not have the three fields is dropped rather than filled in
/// with zeros: «no stock» and «the server did not say» are different answers,
/// and only one of them is worth putting in front of somebody.
class RequestMatch {
  const RequestMatch({
    required this.category,
    required this.totalUnits,
    required this.boxCount,
  });

  static RequestMatch? tryFrom(Object? row) {
    if (row is! Map) return null;
    final category = row['category'];
    final units = row['total_units'];
    final boxes = row['box_count'];
    if (category is! String || units is! num || boxes is! num) return null;
    return RequestMatch(
      category: category,
      totalUnits: units.toInt(),
      boxCount: boxes.toInt(),
    );
  }

  final String category;
  final int totalUnits;
  final int boxCount;
}

sealed class RequestsOutcome<T> {
  const RequestsOutcome();
}

final class RequestsRead<T> extends RequestsOutcome<T> {
  const RequestsRead(this.value);

  final T value;
}

final class RequestsRefused<T> extends RequestsOutcome<T> {
  const RequestsRefused(this.failure);

  final ApiFailure failure;

  /// Whether the refusal is «not your place». Moving the status requires
  /// national administration, and the screen does not offer it to anybody else;
  /// this is the net in case the role changed while a screen was open.
  bool get isForbidden => failure is ForbiddenFailure;
}

/// The requests board: what a centre says it needs.
///
/// **Everything here is online.** A request is a conversation with whoever can
/// answer it, and a cached copy of a conversation invites replying to something
/// that was already answered — the same reason the message threads are not
/// cached either.
///
/// The server narrows the list by itself: a centre sees its own, and a national
/// administration sees them all. Nothing is filtered here.
class RequestsRepository {
  RequestsRepository(this._requests);

  final RequestsApi _requests;

  Future<RequestsOutcome<List<RequestOut>>> list({String? status}) async {
    try {
      return RequestsRead(
        await _requests.listRequestsV1RequestsGet(status: status),
      );
    } on Object catch (error) {
      return RequestsRefused(ApiErrorMapper.fromAny(error));
    }
  }

  Future<RequestsOutcome<RequestOut>> one(String id) async {
    try {
      return RequestsRead(
        await _requests.getRequestV1RequestsRequestIdGet(requestId: id),
      );
    } on Object catch (error) {
      return RequestsRefused(ApiErrorMapper.fromAny(error));
    }
  }

  /// Opens a request: a subject and a sentence.
  ///
  /// The contract asks for nothing else — no quantities, no product, no
  /// category. That is the point of the board: whoever is on the floor writes
  /// what is missing in their own words, and the matching turns it into
  /// categories afterwards.
  Future<RequestsOutcome<RequestOut>> create({
    required String title,
    required String description,
  }) async {
    try {
      return RequestsRead(
        await _requests.createRequestV1RequestsPost(
          body: RequestCreate(title: title, description: description),
        ),
      );
    } on Object catch (error) {
      return RequestsRefused(ApiErrorMapper.fromAny(error));
    }
  }

  Future<RequestsOutcome<RequestMessageOut>> reply({
    required String id,
    required String body,
  }) async {
    try {
      return RequestsRead(
        await _requests.addMessageV1RequestsRequestIdMessagesPost(
          requestId: id,
          body: RequestMessageCreate(body: body),
        ),
      );
    } on Object catch (error) {
      return RequestsRefused(ApiErrorMapper.fromAny(error));
    }
  }

  /// What the platform has of what this request is asking for.
  ///
  /// **An empty list is the normal answer and never a failure.** The server
  /// returns one when the matching is off, out of budget or the provider did
  /// not answer, and the board goes on working without the shortcut — so a
  /// failure of the call is treated the same way. Whoever wrote the request
  /// asked for something, not for a suggestion.
  Future<List<RequestMatch>> matches(String id) async {
    try {
      final rows = await _requests
          .matchRequestWithStockV1RequestsRequestIdMatchesGet(requestId: id);
      if (rows is! List) return const [];
      return [for (final row in rows) ?RequestMatch.tryFrom(row)];
    } on Object {
      return const [];
    }
  }

  /// Moves the status. **National administration only** — the backend gates
  /// this one route with `require_national_admin` while the rest of the board
  /// only asks for a session.
  Future<RequestsOutcome<RequestOut>> updateStatus({
    required String id,
    required String status,
  }) async {
    try {
      return RequestsRead(
        await _requests.updateStatusV1RequestsRequestIdStatusPatch(
          requestId: id,
          body: RequestStatusPatch(status: status),
        ),
      );
    } on Object catch (error) {
      return RequestsRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
