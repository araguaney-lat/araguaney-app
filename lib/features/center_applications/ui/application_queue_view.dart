import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/center_application_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/relative_time.dart';
import '../../centers/data/centers_providers.dart';
import '../../centers/ui/center_record_view.dart';
import '../data/center_applications_providers.dart';
import '../data/center_applications_repository.dart';
import 'reject_application_sheet.dart';

/// The queue of centre applications.
///
/// **It is the other end of the sign-in screen's link.** The application sends
/// whoever has no centre off to apply on the web; this is where somebody
/// answers. A queue whose entire purpose is not to jam is exactly what is worth
/// having on a phone: what it costs for it to sit still is a centre that cannot
/// start operating.
///
/// It only brings what is waiting for review, oldest to newest. Deciding one
/// takes it out of here, so this is a queue and not a history.
class ApplicationQueueView extends ConsumerStatefulWidget {
  const ApplicationQueueView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const ApplicationQueueView());

  @override
  ConsumerState<ApplicationQueueView> createState() =>
      _ApplicationQueueViewState();
}

class _ApplicationQueueViewState extends ConsumerState<ApplicationQueueView> {
  String? _deciding;

  Future<void> _approve(CenterApplicationOut application) async {
    // Taken before opening the dialog: after waiting for it, this context may
    // have stopped being mounted.
    final l10n = context.l10n;
    // Approving does three irreversible things from here, so all three are
    // named before doing them. A confirmation that only says «are you sure?»
    // informs nobody of anything.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.l10n.applicationApproveConfirmTitle(application.centerName),
        ),
        content: Text(
          context.l10n.applicationApproveExplanation(
            application.contactName,
            application.contactEmail,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.actionApprove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _decide(
      application.id,
      () => ref
          .read(centerApplicationsRepositoryProvider)
          .approve(application.id),
      done: l10n.applicationApproved(application.centerName),
      // Approving creates a centre, and `created_center_id` comes in the
      // answer. Offering it closes the real next step: whoever has just
      // approved usually wants to look at — or correct — what was just
      // created, with the application still in their head.
      onCreated: (resolved) {
        final id = resolved.createdCenterId;
        if (id == null) return null;
        return (
          label: context.l10n.applicationViewCenter,
          route: CenterRecordView.route(id),
        );
      },
    );
  }

  Future<void> _reject(CenterApplicationOut application) async {
    final l10n = context.l10n;
    final reason = await RejectApplicationSheet.show(
      context,
      centerName: application.centerName,
    );
    if (reason == null) return;

    await _decide(
      application.id,
      () => ref
          .read(centerApplicationsRepositoryProvider)
          .reject(application.id, reason),
      done: l10n.applicationRejected(application.contactName),
    );
  }

  Future<void> _decide(
    String id,
    Future<ApplicationsOutcome<CenterApplicationOut>> Function() run, {
    required String done,
    ({String label, Route<void> route})? Function(CenterApplicationOut)?
    onCreated,
  }) async {
    setState(() => _deciding = id);
    final outcome = await run();
    if (!mounted) return;
    setState(() => _deciding = null);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    switch (outcome) {
      case ApplicationsRead(:final value):
        ref.invalidate(applicationQueueProvider);
        // The new centre too: the list of centres has to have it.
        ref.invalidate(centersProvider);
        final next = onCreated?.call(value);
        messenger.showSnackBar(
          SnackBar(
            content: Text(done),
            action: next == null
                ? null
                : SnackBarAction(
                    label: next.label,
                    onPressed: () => navigator.push(next.route),
                  ),
          ),
        );
      case ApplicationsRefused(:final failure):
        messenger.showSnackBar(
          SnackBar(content: Text(failure.operatorMessage(context.l10n))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(applicationQueueProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.applicationsTitle)),
      body: switch (queue) {
        AsyncData(value: ApplicationsRead(:final value)) when value.isEmpty =>
          _Message(context.l10n.applicationsEmpty),
        AsyncData(value: ApplicationsRead(:final value)) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(applicationQueueProvider),
          child: ListView(
            children: [
              _Header(pending: value.length),
              for (final application in value)
                _ApplicationCard(
                  application: application,
                  busy: _deciding == application.id,
                  onApprove: () => _approve(application),
                  onReject: () => _reject(application),
                ),
            ],
          ),
        ),
        AsyncData(
          value: ApplicationsRefused(:final isForbidden, :final failure),
        ) =>
          _Message(
            isForbidden
                ? context.l10n.applicationsForbidden
                : failure.operatorMessage(context.l10n),
          ),
        AsyncError(:final error) => _Message('$error'),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.pending});

  final int pending;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      context.l10n.applicationsPendingCount(pending),
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final CenterApplicationOut application;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final place = [
      application.stateName,
      application.countryCode,
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(application.centerName, style: text.titleMedium),
                ),
                Text(
                  describeAge(
                    context.l10n,
                    application.createdAt,
                    DateTime.now(),
                  ),
                  style: text.bodySmall,
                ),
              ],
            ),
            if (place.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(place, style: text.bodyMedium),
              ),
            const SizedBox(height: 12),
            // Everything the decision needs, on the card. Forcing a record to
            // be opened to know who backs a centre turns a queue of three into
            // three navigations.
            RecordField(
              label: context.l10n.contactLabel,
              value: '${application.contactName} · ${application.contactEmail}',
            ),
            if (application.contactPhone case final phone?
                when phone.isNotEmpty)
              RecordField(label: context.l10n.phoneLabel, value: phone),
            if (application.address case final address? when address.isNotEmpty)
              RecordField(label: context.l10n.addressLabel, value: address),
            if (application.backingOrg case final org? when org.isNotEmpty)
              RecordField(label: context.l10n.backingOrgLabel, value: org),
            if (application.socialUrl case final social? when social.isNotEmpty)
              RecordField(label: context.l10n.socialLabel, value: social),
            if (application.message case final message?
                when message.isNotEmpty) ...[
              const SizedBox(height: 8),
              // In quotes and unedited: they are the words of whoever applied.
              Text(context.l10n.quoted(message), style: text.bodyMedium),
            ],
            const SizedBox(height: 16),
            if (busy)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      child: Text(context.l10n.actionApprove),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      child: Text(context.l10n.actionReject),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
    child: Text(text, textAlign: TextAlign.center),
  );
}
