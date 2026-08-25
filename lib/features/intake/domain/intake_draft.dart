import '../../../core/api/generated/models/donor_input.dart';
import '../../../core/api/generated/models/intake_create.dart';
import 'box_draft_input.dart';

/// Tipos de donante que reconoce el contrato.
abstract final class DonorType {
  static const natural = 'fisica';
  static const legal = 'moral';
}

/// Una captura en construcción.
///
/// Es inmutable: cada cambio del formulario produce una captura nueva. Importa
/// más de lo habitual aquí, porque [captureId] tiene que sobrevivir intacto a
/// todas esas ediciones y a todos los reintentos.
class IntakeDraft {
  const IntakeDraft({
    required this.captureId,
    this.centerId,
    this.campaignId,
    this.donor,
    this.donorTermsAccepted = false,
    this.donanteLibre,
    this.donationId,
    this.notes,
    this.anonymousExceptionReason,
    this.boxes = const [],
  });

  /// Llave de idempotencia, **generada antes del primer intento** y jamás
  /// regenerada. Reintentar una captura es el caso normal, no la excepción: el
  /// servidor devuelve la que ya registró en vez de duplicarla.
  final String captureId;

  /// Where this capture is being registered, when the session has to say so.
  ///
  /// It is fixed **when the capture starts** and never resolved again — not
  /// when the queue drains, not on a retry. A national administrator can change
  /// working centre while captures are still waiting for signal, and resolving
  /// this at send time would move donations that were already registered
  /// somewhere else, days after the boxes were physically put down.
  ///
  /// Null for everybody else: the server writes to the centre in their token
  /// and ignores this field, so sending it would only suggest otherwise.
  final String? centerId;

  final String? campaignId;
  final DonorInput? donor;
  final bool donorTermsAccepted;

  /// Nombre suelto del donante, para la operación que todavía no identifica.
  final String? donanteLibre;

  /// Donación pre-registrada de la que salió esta captura, cuando se llegó
  /// escaneando un código `DN-`.
  final String? donationId;

  final String? notes;

  /// Motivo por el que la donación queda anónima cuando el servidor pide
  /// identificar. Lo escribe quien captura; el servidor lo deja en revisión.
  final String? anonymousExceptionReason;

  final List<BoxDraftInput> boxes;

  /// Sin cajas no hay captura: es el único campo que el contrato exige.
  bool get isSubmittable => boxes.isNotEmpty;

  IntakeDraft copyWith({
    String? campaignId,
    DonorInput? donor,
    bool? donorTermsAccepted,
    String? donanteLibre,
    String? donationId,
    String? notes,
    String? anonymousExceptionReason,
    List<BoxDraftInput>? boxes,
  }) => IntakeDraft(
    captureId: captureId,
    centerId: centerId,
    campaignId: campaignId ?? this.campaignId,
    donor: donor ?? this.donor,
    donorTermsAccepted: donorTermsAccepted ?? this.donorTermsAccepted,
    donanteLibre: donanteLibre ?? this.donanteLibre,
    donationId: donationId ?? this.donationId,
    notes: notes ?? this.notes,
    anonymousExceptionReason:
        anonymousExceptionReason ?? this.anonymousExceptionReason,
    boxes: boxes ?? this.boxes,
  );

  /// Quita al donante identificado. Va aparte de [copyWith] porque poner un
  /// campo en nulo con un parámetro opcional es indistinguible de no tocarlo.
  IntakeDraft withoutDonor() => IntakeDraft(
    captureId: captureId,
    centerId: centerId,
    campaignId: campaignId,
    donorTermsAccepted: false,
    donanteLibre: donanteLibre,
    donationId: donationId,
    notes: notes,
    anonymousExceptionReason: anonymousExceptionReason,
    boxes: boxes,
  );

  IntakeDraft addBox(BoxDraftInput box) => copyWith(boxes: [...boxes, box]);

  IntakeDraft replaceBox(int index, BoxDraftInput box) => copyWith(
    boxes: [...boxes.sublist(0, index), box, ...boxes.sublist(index + 1)],
  );

  IntakeDraft removeBox(int index) => copyWith(
    boxes: [...boxes.sublist(0, index), ...boxes.sublist(index + 1)],
  );

  IntakeCreate toRequest() => IntakeCreate(
    captureId: captureId,
    centerId: centerId,
    campaignId: campaignId,
    donor: donor,
    donorTermsAccepted: donorTermsAccepted,
    donanteLibre: _trimmedOrNull(donanteLibre),
    donationId: donationId,
    notes: _trimmedOrNull(notes),
    anonymousExceptionReason: _trimmedOrNull(anonymousExceptionReason),
    boxes: boxes.map((box) => box.toRequest()).toList(growable: false),
  );

  static String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
