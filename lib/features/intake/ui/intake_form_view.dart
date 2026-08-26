import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/campaign_out.dart';
import '../../../core/center/center_providers.dart';
import '../../../core/connectivity/connectivity_controller.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/confirm_button.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/working_center_banner.dart';
import '../data/intake_providers.dart';
import '../data/intake_repository.dart';
import '../domain/box_draft_input.dart';
import '../domain/intake_draft.dart';
import 'anonymous_exception_dialog.dart';
import 'box_draft_sheet.dart';
import 'campaign_sheet.dart';
import 'donor_sheet.dart';
import 'intake_queued_view.dart';
import 'intake_submitted_view.dart';

/// Capturing a donation, on a single screen.
///
/// All the state lives here: nothing is lost by going back, and reviewing
/// before sending means looking down the page. The idempotency key was
/// generated when it opened and does not change, so resending after a refusal
/// never duplicates inventory.
class IntakeFormView extends ConsumerStatefulWidget {
  const IntakeFormView({super.key, this.donationId});

  /// The pre-registered donation this capture came from, when it was reached
  /// by scanning a `DN-` code.
  final String? donationId;

  static Route<void> route({String? donationId}) => MaterialPageRoute<void>(
    builder: (_) => IntakeFormView(donationId: donationId),
  );

  @override
  ConsumerState<IntakeFormView> createState() => _IntakeFormViewState();
}

class _IntakeFormViewState extends ConsumerState<IntakeFormView> {
  final _notes = TextEditingController();
  final _donanteLibre = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.donationId case final donationId?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(intakeDraftControllerProvider.notifier)
              .prefillFromDonation(donationId);
        }
      });
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    _donanteLibre.dispose();
    super.dispose();
  }

  IntakeDraftController get _controller =>
      ref.read(intakeDraftControllerProvider.notifier);

  Future<void> _addBox() async {
    final box = await BoxDraftSheet.show(context);
    if (box != null) _controller.addBox(box);
  }

  Future<void> _pickCampaign(List<CampaignOut> campaigns) async {
    final chosen = await CampaignSheet.show(
      context,
      campaigns: campaigns,
      selected: ref.read(intakeDraftControllerProvider).campaignId,
    );
    if (chosen != null) _controller.setCampaign(chosen.id);
  }

  Future<void> _editBox(int index, BoxDraftInput current) async {
    final box = await BoxDraftSheet.show(context, initial: current);
    if (box != null) _controller.replaceBox(index, box);
  }

  Future<bool> _identifyDonor() async {
    final draft = ref.read(intakeDraftControllerProvider);
    final result = await DonorSheet.show(
      context,
      initial: draft.donor,
      termsAccepted: draft.donorTermsAccepted,
    );
    if (result == null) return false;

    _controller.setDonor(result.donor, termsAccepted: result.termsAccepted);
    return true;
  }

  Future<void> _submit() async {
    _controller
      ..setNotes(_notes.text)
      ..setDonanteLibre(_donanteLibre.text);

    final userId = ref.read(currentUserIdProvider);
    final offline =
        ref.read(connectivityControllerProvider) == ConnectivityStatus.offline;

    // With no signal it is not attempted and failed: it is queued. It is the
    // only write that depends solely on what the person has in front of them,
    // and that is why it is the only one that can wait on the device.
    if (offline && userId != null) {
      await _enqueue(userId);
      return;
    }

    var result = await _send();

    // The server may ask for the donor to be identified. It is not a field
    // error: it is a question for the counter, and the answer is resent with
    // the same capture key.
    if (result is IntakeNeedsDonor && mounted) {
      final resolved = await _resolveDonorRequest(result);
      result = resolved ?? result;
    }

    if (!mounted) return;

    switch (result) {
      case IntakeAccepted(:final intake):
        await Navigator.of(
          context,
        ).pushReplacement(IntakeSubmittedView.route(intake));
      // A refusal is shown with the server's reason. That the question about
      // the donor reaches this far means it went unresolved, and that is also
      // an answer whoever captures has to read.
      case IntakeNeedsDonor(:final failure):
        _showFailure(failure.operatorMessage(context.l10n));
      // The network went down mid-submission. Losing what was captured would
      // be the worst possible outcome, so the capture moves to the queue with
      // its same key: when the signal returns it will be sent once, not twice.
      case IntakeRejected(:final failure)
          when failure.isRetryable && userId != null:
        await _enqueue(userId);
      case IntakeRejected(:final failure):
        _showFailure(failure.operatorMessage(context.l10n));
    }
  }

  /// Stores the capture to be sent when the signal comes back, assigning it
  /// first whatever reserved codes are needed to be able to label now.
  Future<void> _enqueue(String userId) async {
    setState(() => _submitting = true);

    final draft = ref.read(intakeDraftControllerProvider);
    final withoutCode = draft.boxes.where((box) => box.code == null).length;
    if (withoutCode > 0) {
      final codes = await ref
          .read(boxCodeRepositoryProvider)
          .take(
            withoutCode,
            userId: userId,
            centerId: ref.read(writeCenterIdProvider),
          );
      _controller.assignCodes(codes);
    }

    await _controller.enqueue(userId);
    if (!mounted) return;

    setState(() => _submitting = false);
    await Navigator.of(context).pushReplacement(
      IntakeQueuedView.route(ref.read(intakeDraftControllerProvider)),
    );
  }

  /// Sends and marks the screen busy only while the request is in flight.
  /// Waiting for somebody to answer a dialog is not sending, and leaving the
  /// spinner turning meanwhile would say otherwise.
  Future<IntakeSubmission> _send() async {
    setState(() => _submitting = true);
    final result = await _controller.submit();
    if (mounted) setState(() => _submitting = false);
    return result;
  }

  Future<IntakeSubmission?> _resolveDonorRequest(IntakeNeedsDonor asked) async {
    final decision = await AnonymousExceptionDialog.show(
      context,
      serverMessage: asked.failure.operatorMessage(context.l10n),
    );
    if (decision == null || !mounted) return null;

    switch (decision.outcome) {
      case DonorRequestOutcome.identify:
        if (!await _identifyDonor()) return null;
      case DonorRequestOutcome.exception:
        _controller.setExceptionReason(decision.reason);
    }

    return _send();
  }

  void _showFailure(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(intakeDraftControllerProvider);
    final campaigns = ref.watch(myCampaignsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _CampaignHeader(
          label: _campaignLabel(
            context.l10n,
            campaigns.valueOrNull,
            draft.campaignId,
          ),
          onTap: () => _pickCampaign(campaigns.valueOrNull ?? const []),
        ),
      ),
      body: Column(
        children: [
          const WorkingCenterBanner(),
          Expanded(
            child: AbsorbPointer(
              absorbing: _submitting,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_submitting) const LinearProgressIndicator(),
                  if (draft.donationId != null) const _DonationNotice(),
                  _DonorSection(
                    draft: draft,
                    onIdentify: _identifyDonor,
                    onClear: _controller.clearDonor,
                    donanteLibre: _donanteLibre,
                  ),
                  const SizedBox(height: 16),
                  _BoxesCard(
                    boxes: draft.boxes,
                    onEdit: _editBox,
                    onRemove: _controller.removeBox,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notes,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: context.l10n.notesOptionalLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Both actions live at the bottom and do not go away with the scroll:
      // adding a box is what repeats most, and registering is what closes.
      // Hunting for them upwards, with a box in your hands, was the worst place
      // for either.
      bottomNavigationBar: _ActionBar(
        onAdd: _submitting ? null : _addBox,
        onSubmit: draft.isSubmittable && !_submitting ? _submit : null,
      ),
    );
  }

  /// The active campaign's name. Until the list arrives an identifier cannot be
  /// resolved to a name, and saying «general» without knowing would be stating
  /// something false on the very line that gives the context.
  static String _campaignLabel(
    AppLocalizations l10n,
    List<CampaignOut>? campaigns,
    String? id,
  ) {
    if (id == null) return l10n.generalCampaign;
    if (campaigns == null) return l10n.campaignPlaceholder;
    for (final campaign in campaigns) {
      if (campaign.id == id) return campaign.name;
    }
    return l10n.generalCampaign;
  }
}

/// The screen's title with the campaign below it, tappable to change it.
class _CampaignHeader extends StatelessWidget {
  const _CampaignHeader({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.intakeFormTitle),
        InkWell(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              const Icon(Icons.expand_more, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

/// A fixed bar with the two actions: blue leads to another screen, gold
/// closes.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onAdd, required this.onSubmit});

  final VoidCallback? onAdd;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.bar,
        border: Border(top: BorderSide(color: palette.barBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          // A bottom bar does not rise with the keyboard by itself, and here
          // people type with a thumb while holding a box.
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onAdd,
                  child: Text(context.l10n.boxAddAction),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ConfirmButton(
                  label: context.l10n.registerAction,
                  onPressed: onSubmit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonationNotice extends StatelessWidget {
  const _DonationNotice();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        context.l10n.captureLinkedToDonation,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ),
  );
}

class _DonorSection extends StatelessWidget {
  const _DonorSection({
    required this.draft,
    required this.onIdentify,
    required this.onClear,
    required this.donanteLibre,
  });

  final IntakeDraft draft;
  final Future<bool> Function() onIdentify;
  final VoidCallback onClear;
  final TextEditingController donanteLibre;

  @override
  Widget build(BuildContext context) {
    if (draft.donor case final donor?) {
      return Card(
        child: Column(
          children: [
            RecordField(
              label: donor.donorType == DonorType.legal ? 'Empresa' : 'Persona',
              value: donor.legalName ?? '${donor.firstName} ${donor.lastName}',
            ),
            OverflowBar(
              children: [
                TextButton(
                  onPressed: onClear,
                  child: Text(context.l10n.removeAction),
                ),
                TextButton(
                  onPressed: () => onIdentify(),
                  child: Text(context.l10n.centerEditAction),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: donanteLibre,
          decoration: InputDecoration(
            labelText: context.l10n.donorOptionalLabel,
            helperText: context.l10n.freeNameHint,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => onIdentify(),
          icon: const Icon(Icons.person_add_alt),
          label: Text(context.l10n.identifyDonorTitle),
        ),
      ],
    );
  }
}

/// What the intake carries so far, with its count.
///
/// The number goes in the header because it is what gets checked before
/// registering: whoever received six packages counts six lines, and a card that
/// only lists them forces them to be counted by eye.
class _BoxesCard extends StatelessWidget {
  const _BoxesCard({
    required this.boxes,
    required this.onEdit,
    required this.onRemove,
  });

  final List<BoxDraftInput> boxes;
  final void Function(int index, BoxDraftInput box) onEdit;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.boxesInIntake(boxes.length),
              style: theme.textTheme.titleMedium,
            ),
            if (boxes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
                child: Text(
                  context.l10n.captureNeedsBoxes,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            for (final (index, box) in boxes.indexed)
              _BoxRow(
                box: box,
                onEdit: () => onEdit(index, box),
                onRemove: () => onRemove(index),
              ),
          ],
        ),
      ),
    );
  }
}

class _BoxRow extends StatelessWidget {
  const _BoxRow({
    required this.box,
    required this.onEdit,
    required this.onRemove,
  });

  final BoxDraftInput box;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(box.productType.displayName),
    subtitle: Text(
      [
        // The code only exists when it was reserved to label without signal.
        // It comes first on the line because it is what is written on the
        // cardboard the person has in front of them.
        ?box.code,
        '${box.quantity} ${box.unit}',
        if (box.batch case final batch?) context.l10n.batchOf(batch),
        if (box.expiryDate case final expiry?)
          context.l10n.expiresOn(formatShortDate(expiry)),
      ].join(' · '),
    ),
    onTap: onEdit,
    trailing: IconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: context.l10n.boxRemoveTitle,
      onPressed: onRemove,
    ),
  );
}
