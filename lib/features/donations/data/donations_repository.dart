import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/donations_api.dart';
import '../../../core/api/generated/models/donation_item_input.dart';
import '../../../core/api/generated/models/donation_out.dart';
import '../../../core/api/generated/models/product_type_out.dart';
import '../../../core/api/generated/models/receive_in.dart';

/// The states the server leaves a donation line in when it is received.
///
/// They are the three of `_RECEPTION_STATES`. **Only the exceptions are sent**:
/// what does not travel marked, the server takes as received, and that split is
/// its own, not a convenience of this screen.
abstract final class ReceptionResult {
  static const received = 'RECEIVED';
  static const missing = 'MISSING';
  static const rejected = 'REJECTED';
}

/// A donation's states, exactly as the backend publishes them.
abstract final class DonationStatus {
  static const pendingEmail = 'PENDING_EMAIL';
  static const registered = 'REGISTERED';
  static const received = 'RECEIVED';
  static const expired = 'EXPIRED';
  static const cancelled = 'CANCELLED';
}

sealed class DonationsOutcome<T> {
  const DonationsOutcome();
}

final class DonationsRead<T> extends DonationsOutcome<T> {
  const DonationsRead(this.value);

  final T value;
}

final class DonationsRefused<T> extends DonationsOutcome<T> {
  const DonationsRefused(this.failure);

  final ApiFailure failure;
}

/// Pre-registered donations: the ones somebody announced from the web and
/// brings to the centre.
///
/// Reading is cached by the screen that asks for it; **receiving requires
/// signal**. It is a write over shared state, like sealing or dispatching: two
/// people receiving the same donation from two phones would produce two truths
/// about the same boxes.
class DonationsRepository {
  DonationsRepository(this._donations);

  final DonationsApi _donations;

  /// [incoming] separates the two questions somebody asks in a centre: what is
  /// on its way, and what has already been received.
  Future<DonationsOutcome<List<DonationOut>>> list({required bool incoming}) =>
      _guard(() => _donations.listDonationsV1DonationsGet(incoming: incoming));

  /// The record by its printed code, which is what arrives from a scan.
  Future<DonationsOutcome<DonationOut>> byCode(String code) =>
      _guard(() => _donations.getDonationV1DonationsCodeGet(code: code));

  /// Records the reception.
  ///
  /// [results] carries **only** the lines that did not arrive complete;
  /// [extras], what came unannounced. [centerId] is set only by a national
  /// administration, which has no centre of its own: for everybody else the
  /// server takes it from the token and ignores whatever is sent.
  Future<DonationsOutcome<DonationOut>> receive({
    required String code,
    Map<String, String> results = const {},
    List<DonationItemInput> extras = const [],
    String? centerId,
  }) => _guard(
    () => _donations.receiveDonationV1DonationsCodeReceivePost(
      code: code,
      body: ReceiveIn(results: results, extras: extras, centerId: centerId),
    ),
  );

  /// Up to three catalogue products for a line the donor wrote by hand.
  ///
  /// The server returns an empty list if the capability is off or does not
  /// answer. That is **not a failure**: receiving by hand never depends on this
  /// answering, and the screen behaves just as it would with no matches.
  Future<DonationsOutcome<List<ProductTypeOut>>> suggestions({
    required String code,
    required String text,
  }) => _guard(
    () => _donations.suggestCatalogMatchesV1DonationsCodeSuggestionsGet(
      code: code,
      text: text,
    ),
  );

  /// A photo's signed link. It expires, so it is asked for when the photo is
  /// looked at and it is not stored.
  Future<DonationsOutcome<String>> photoUrl({
    required String code,
    required String photoId,
  }) => _guard(() async {
    final signed = await _donations
        .centerPhotoUrlV1DonationsCodePhotosPhotoIdUrlGet(
          code: code,
          photoId: photoId,
        );
    return signed.url;
  });

  /// Asks the server to read a photo's label.
  ///
  /// What it returns are **suggestions**, and the contract says so by wrapping
  /// them in `suggested`. An empty dictionary is the normal answer when the
  /// capability is off: people type as always.
  Future<DonationsOutcome<Map<String, String>>> readLabel({
    required String code,
    required String photoId,
  }) => _guard(() async {
    final response = await _donations
        .readLabelV1DonationsCodePhotosPhotoIdReadLabelPost(
          code: code,
          photoId: photoId,
        );
    final suggested = (response as Map?)?['suggested'];
    if (suggested is! Map) return const <String, String>{};
    return {
      for (final entry in suggested.entries)
        if (entry.value != null) '${entry.key}': '${entry.value}',
    };
  });

  Future<DonationsOutcome<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return DonationsRead(await call());
    } on Object catch (error) {
      return DonationsRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
