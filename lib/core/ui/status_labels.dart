import '../i18n/generated/app_localizations.dart';

/// Las tablas de estados, traducidas a la salida.
///
/// **Las claves son las del servidor y no se tocan**: `CLOSED` viaja como
/// `CLOSED` y solo cambia lo que se dibuja. Eso es lo que permite que la
/// aplicación hable tres idiomas sin que el contrato sepa nada de ninguno.
///
/// Cada objeto tiene su vocabulario aunque comparta palabras. Una tarima
/// «CLOSED» y un envío «CLOSED» se dicen distinto en español —«cerrada» y
/// «cerrado»— y en portugués también; en inglés coinciden, que es justo por qué
/// una sola tabla habría parecido correcta hasta la primera traducción.
///
/// Todas reciben [AppLocalizations] en vez de leerlo de un contexto global: un
/// valor global tiene un idioma y esta aplicación tiene tres, y quien dibuja ya
/// tiene el contexto a mano.
///
/// Un estado desconocido devuelve su clave. Es feo a propósito: el contrato es
/// aditivo y un binario viejo puede recibir un estado que no conoce; enseñarlo
/// crudo dice «esto es nuevo» en vez de inventar una traducción.
String boxStatusLabel(AppLocalizations l10n, String status) => switch (status) {
  'DRAFT' => l10n.boxStatusDraft,
  'SEALED' => l10n.boxStatusSealed,
  'SHIPPED' => l10n.boxStatusShipped,
  'REJECTED' => l10n.boxStatusRejected,
  _ => status,
};

String palletStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'OPEN' => l10n.palletStatusOpen,
      'CLOSED' => l10n.palletStatusClosed,
      'SHIPPED' => l10n.palletStatusShipped,
      _ => status,
    };

String shipmentStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'OPEN' => l10n.shipmentStatusOpen,
      'CLOSED' => l10n.shipmentStatusClosed,
      'SHIPPED' => l10n.shipmentStatusShipped,
      'DELIVERED' => l10n.shipmentStatusDelivered,
      'RECONCILED' => l10n.shipmentStatusReconciled,
      _ => status,
    };

String transferStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'REQUESTED' => l10n.transferStatusRequested,
      'APPROVED' => l10n.transferStatusApproved,
      'IN_TRANSIT' => l10n.transferStatusInTransit,
      'RECEIVED' => l10n.transferStatusReceived,
      'REJECTED' => l10n.transferStatusRejected,
      _ => status,
    };

String reviewStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'PENDING' => l10n.reviewStatusPending,
      'APPROVED' => l10n.reviewStatusApproved,
      'REJECTED' => l10n.reviewStatusRejected,
      _ => status,
    };

/// El ciclo de una donación pre-registrada: se registra por correo, se
/// confirma, y se recibe cuando alguien la captura en un centro.
String donationStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'PENDING_EMAIL' => l10n.donationStatusPendingEmail,
      'REGISTERED' => l10n.donationStatusRegistered,
      'RECEIVED' => l10n.donationStatusReceived,
      'CANCELLED' => l10n.donationStatusCancelled,
      'EXPIRED' => l10n.donationStatusExpired,
      _ => status,
    };

/// Cómo llegó una caja de un envío.
///
/// Cuatro estados de `RECEPTION_OUTCOMES`. Tabla propia y no compartida con la
/// de las donaciones aunque tres palabras coincidan: son objetos distintos, y
/// «retenida en aduana» solo existe aquí.
String receptionOutcomeLabel(AppLocalizations l10n, String outcome) =>
    switch (outcome) {
      'RECEIVED' => l10n.receptionOutcomeReceived,
      'MISSING' => l10n.receptionOutcomeMissing,
      'DAMAGED' => l10n.receptionOutcomeDamaged,
      'RETAINED_CUSTOMS' => l10n.receptionOutcomeRetained,
      _ => outcome,
    };

/// Cómo terminó una línea de una donación al recibirla.
///
/// Tres estados del backend, y solo dos se mandan: lo que no viaja marcado el
/// servidor lo da por recibido. Tabla propia y no compartida con las cajas
/// porque son objetos distintos y solo coinciden en español.
String receptionResultLabel(AppLocalizations l10n, String result) =>
    switch (result) {
      'RECEIVED' => l10n.receptionReceived,
      'MISSING' => l10n.receptionMissing,
      'REJECTED' => l10n.receptionRejected,
      _ => result,
    };

String incidentStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'OPEN' => l10n.incidentStatusOpen,
      'RESOLVED' => l10n.incidentStatusResolved,
      _ => status,
    };
