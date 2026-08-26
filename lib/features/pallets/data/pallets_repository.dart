import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/pallets_api.dart';
import '../../../core/api/generated/models/pallet_close_in.dart';
import '../../../core/api/generated/models/pallet_create.dart';
import '../../../core/api/generated/models/pallet_detail_out.dart';
import '../../../core/api/generated/models/pallet_out.dart';

/// How an operation on a pallet ended.
///
/// It is returned as a value and not as an exception for the same reason as in
/// the capture: the server's refusal almost always describes something whoever
/// operates can understand and correct — a box that is not sealed, one that is
/// already on another pallet — and that sentence has to reach the screen whole.
sealed class PalletOutcome<T> {
  const PalletOutcome();
}

final class PalletChanged<T> extends PalletOutcome<T> {
  const PalletChanged(this.value);

  final T value;
}

final class PalletRejected<T> extends PalletOutcome<T> {
  const PalletRejected(this.failure);

  final ApiFailure failure;
}

/// Pallet operations.
///
/// **They all require a connection**, and that is a domain rule, not a
/// limitation: a pallet is shared state that another device may be changing
/// right now. Deciding blind would produce two truths about the same load,
/// which is exactly what phase 03's boundary avoids.
class PalletsRepository {
  PalletsRepository(this._pallets);

  final PalletsApi _pallets;

  Future<List<PalletOut>> list({int limit = 100, int offset = 0}) =>
      _pallets.listPalletsV1PalletsGet(limit: limit, offset: offset);

  Future<PalletDetailOut> detail(String palletId) =>
      _pallets.getPalletV1PalletsPalletIdGet(palletId: palletId);

  /// [centerId] names where the pallet is being built, and is only ever set by
  /// a session with no centre of its own. The server takes it from the token
  /// for everybody else.
  Future<PalletOutcome<PalletOut>> create({
    String? tareWeightKg,
    String? notes,
    String? centerId,
  }) => _guard(
    () => _pallets.createPalletV1PalletsPost(
      body: PalletCreate(
        tareWeightKg: tareWeightKg,
        notes: notes,
        centerId: centerId,
      ),
    ),
  );

  /// Adds a box by its code.
  ///
  /// The contract declares the body untyped, so the key travels written by
  /// hand; it is `code`, checked against the backend's router and not assumed.
  Future<PalletOutcome<PalletDetailOut>> addBox({
    required String palletId,
    required String boxCode,
  }) => _guard(
    () => _pallets.addBoxToPalletV1PalletsPalletIdAddBoxPost(
      palletId: palletId,
      body: {'code': boxCode},
    ),
  );

  Future<PalletOutcome<PalletDetailOut>> removeBox({
    required String palletId,
    required String boxCode,
  }) => _guard(
    () => _pallets.removeBoxFromPalletV1PalletsPalletIdBoxesBoxCodeDelete(
      palletId: palletId,
      boxCode: boxCode,
    ),
  );

  /// Closes the pallet with its gross weight and its height.
  ///
  /// The server compares that weight with the sum of the boxes and publishes
  /// the difference. Nothing is computed here: the discrepancy is its own, and
  /// so is the judgement of when it matters.
  Future<PalletOutcome<PalletOut>> close({
    required String palletId,
    String? grossWeightKg,
    int? heightCm,
  }) => _guard(
    () => _pallets.closePalletV1PalletsPalletIdClosePost(
      palletId: palletId,
      body: PalletCloseIn(grossWeightKg: grossWeightKg, heightCm: heightCm),
    ),
  );

  Future<PalletOutcome<T>> _guard<T>(Future<T> Function() attempt) async {
    try {
      return PalletChanged(await attempt());
    } on Object catch (error) {
      return PalletRejected(ApiErrorMapper.fromAny(error));
    }
  }
}
