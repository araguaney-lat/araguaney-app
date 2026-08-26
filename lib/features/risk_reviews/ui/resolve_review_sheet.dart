import 'package:flutter/material.dart';
import '../../../core/i18n/l10n_extension.dart';

import '../../../core/ui/sheet_insets.dart';
import '../data/risk_reviews_repository.dart';

/// Closing a review: what is decided and why.
///
/// Both ways out are offered at once and with the same visual weight. Hiding
/// «reject» behind one more step would make the hard decision the awkward one,
/// and whoever coordinates needs to be able to take it as fast as the easy one.
class ResolveReviewSheet extends StatefulWidget {
  const ResolveReviewSheet({super.key, required this.reason});

  /// The reason it was raised, in sight while it is being decided.
  final String reason;

  static Future<({String resolution, String? note})?> show(
    BuildContext context, {
    required String reason,
  }) => showModalBottomSheet<({String resolution, String? note})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ResolveReviewSheet(reason: reason),
  );

  @override
  State<ResolveReviewSheet> createState() => _ResolveReviewSheetState();
}

class _ResolveReviewSheetState extends State<ResolveReviewSheet> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _resolve(String resolution) {
    final note = _note.text.trim();
    Navigator.of(
      context,
    ).pop((resolution: resolution, note: note.isEmpty ? null : note));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      top: 16,
      bottom: sheetBottomInset(context),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.reviewResolveTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(widget.reason, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        TextField(
          controller: _note,
          maxLines: 3,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: context.l10n.noteOptionalLabel,
            helperText: context.l10n.reviewNoteHint,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _resolve(RiskResolution.reject),
                child: Text(context.l10n.actionReject),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _resolve(RiskResolution.approve),
                child: Text(context.l10n.actionApprove),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
