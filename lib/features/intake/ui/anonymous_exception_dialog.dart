import 'package:flutter/material.dart';
import '../../../core/i18n/l10n_extension.dart';

/// What is done when the server asks for the donor to be identified.
enum DonorRequestOutcome {
  /// The donor is going to be registered.
  identify,

  /// The donor did not want to identify themselves; the reason is recorded.
  exception,
}

/// The server asked for identification before accepting this capture.
///
/// It does not block: the backend accepts the anonymous capture with a written
/// reason and leaves the review open for coordination. Stopping whoever
/// captures here would move the cost onto the operation mid-shift and recover
/// nothing — by the time anybody reviewed it, the person would be long gone.
class AnonymousExceptionDialog extends StatefulWidget {
  const AnonymousExceptionDialog({super.key, required this.serverMessage});

  final String serverMessage;

  static Future<({DonorRequestOutcome outcome, String? reason})?> show(
    BuildContext context, {
    required String serverMessage,
  }) => showDialog<({DonorRequestOutcome outcome, String? reason})>(
    context: context,
    builder: (_) => AnonymousExceptionDialog(serverMessage: serverMessage),
  );

  @override
  State<AnonymousExceptionDialog> createState() =>
      _AnonymousExceptionDialogState();
}

class _AnonymousExceptionDialogState extends State<AnonymousExceptionDialog> {
  final _reason = TextEditingController();
  bool _writingReason = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.donorRequiredTitle),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The server's text is shown as it is: it describes a business rule
        // that whoever captures can understand and resolve.
        Text(widget.serverMessage),
        if (_writingReason) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _reason,
            autofocus: true,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: context.l10n.reasonLabel,
              helperText: context.l10n.anonymousReasonLabel,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    ),
    actions: _writingReason
        ? [
            TextButton(
              onPressed: () => setState(() => _writingReason = false),
              child: Text(context.l10n.backAction),
            ),
            FilledButton(
              onPressed: _reason.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop((
                      outcome: DonorRequestOutcome.exception,
                      reason: _reason.text.trim(),
                    )),
              child: Text(context.l10n.registerWithoutDonor),
            ),
          ]
        : [
            TextButton(
              onPressed: () => setState(() => _writingReason = true),
              child: Text(context.l10n.donorDeclinedOption),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pop((outcome: DonorRequestOutcome.identify, reason: null)),
              child: Text(context.l10n.identifyAction),
            ),
          ],
  );
}
