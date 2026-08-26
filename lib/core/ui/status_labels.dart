import '../i18n/generated/app_localizations.dart';

/// The status tables, translated on the way out.
///
/// **The keys are the server's and are never touched**: `CLOSED` travels as
/// `CLOSED` and only what is drawn changes. That is what lets the application
/// speak more than one language without the contract knowing about any of
/// them.
///
/// Each object has its own vocabulary even where the words repeat. A pallet
/// that is «CLOSED» and a shipment that is «CLOSED» are said differently in
/// Spanish — «cerrada» and «cerrado» — and in Portuguese too; in English they
/// coincide, which is exactly why one shared table would have looked right up
/// until the first translation.
///
/// They all take [AppLocalizations] rather than reading a global: a global has
/// one language and this application has more, and whoever is drawing already
/// has the context to hand.
///
/// An unknown status returns its key. That is ugly on purpose: the contract is
/// additive and an old binary can receive a status it does not know; showing it
/// raw says «this is new» instead of inventing a translation.
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

/// The life of an announced donation: it is registered by email, confirmed,
/// and received when somebody captures it at a centre.
String donationStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'PENDING_EMAIL' => l10n.donationStatusPendingEmail,
      'REGISTERED' => l10n.donationStatusRegistered,
      'RECEIVED' => l10n.donationStatusReceived,
      'CANCELLED' => l10n.donationStatusCancelled,
      'EXPIRED' => l10n.donationStatusExpired,
      _ => status,
    };

/// How a box from a shipment arrived.
///
/// The four states of `RECEPTION_OUTCOMES`. Its own table rather than the
/// donations' one even though three words coincide: they are different objects,
/// and «held at customs» only exists here.
String receptionOutcomeLabel(AppLocalizations l10n, String outcome) =>
    switch (outcome) {
      'RECEIVED' => l10n.receptionOutcomeReceived,
      'MISSING' => l10n.receptionOutcomeMissing,
      'DAMAGED' => l10n.receptionOutcomeDamaged,
      'RETAINED_CUSTOMS' => l10n.receptionOutcomeRetained,
      _ => outcome,
    };

/// How a line of a donation ended up when it was received.
///
/// Three backend states, and only two are ever sent: whatever does not travel
/// marked, the server counts as received. Its own table rather than the boxes'
/// one because they are different objects and only coincide in Spanish.
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

String requestStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'OPEN' => l10n.requestStatusOpen,
      'IN_PROGRESS' => l10n.requestStatusInProgress,
      'RESOLVED' => l10n.requestStatusResolved,
      'CLOSED' => l10n.requestStatusClosed,
      _ => status,
    };
