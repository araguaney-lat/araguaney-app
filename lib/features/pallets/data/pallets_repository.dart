import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/pallets_api.dart';
import '../../../core/api/generated/models/pallet_close_in.dart';
import '../../../core/api/generated/models/pallet_create.dart';
import '../../../core/api/generated/models/pallet_detail_out.dart';
import '../../../core/api/generated/models/pallet_out.dart';

/// Cómo terminó una operación sobre una tarima.
///
/// Se devuelve como valor y no como excepción por la misma razón que en la
/// captura: el rechazo del servidor casi siempre describe algo que quien opera
/// puede entender y corregir —una caja que no está sellada, una que ya está en
/// otra tarima—, y esa frase tiene que llegar entera a la pantalla.
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

/// Operaciones de tarima.
///
/// **Todas exigen conexión**, y eso es una regla de dominio, no una limitación:
/// una tarima es estado compartido que otro dispositivo puede estar cambiando
/// ahora mismo. Decidir a ciegas produciría dos verdades sobre el mismo bulto,
/// que es exactamente lo que la frontera de la fase 03 evita.
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

  /// Agrega una caja por su código.
  ///
  /// El contrato declara el cuerpo sin tipar, así que la llave viaja escrita a
  /// mano; es `code`, verificado contra el router del backend y no supuesto.
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

  /// Cierra la tarima con su peso bruto y su altura.
  ///
  /// El servidor compara ese peso con la suma de las cajas y publica la
  /// diferencia. Aquí no se calcula nada: la discrepancia es suya, igual que el
  /// criterio de cuándo importa.
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
