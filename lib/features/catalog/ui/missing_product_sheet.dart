import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/barcode_prefill.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/sheet_insets.dart';
import '../../messaging/data/messaging_providers.dart';
import '../../messaging/data/messaging_repository.dart';
import '../../messaging/ui/new_thread_sheet.dart';
import '../../messaging/ui/thread_view.dart';
import '../data/catalog_providers.dart';
import 'product_form_view.dart';

/// What is done when the catalogue does not have what somebody is holding.
///
/// Until now, nothing: the scanner said «no está» and the road ended there, at
/// the exact spot where the person does know which product it is. The two ways
/// out depend on the role, because that is how the server splits them:
///
/// - **National administration** creates it, which is all
///   `require_national_admin` allows.
/// - **Whoever captures asks for it.** They are not offered a form that was
///   going to answer 403; they are offered to say what they have in front of
///   them, and the campaign thread takes it to whoever can add it.
///
/// The vehicle is a campaign thread because it already exists and reaches the
/// right people. Nothing is needed from the backend for this: if one day there
/// is a tray of catalogue proposals, this sheet is the only thing that changes.
class MissingProductSheet extends ConsumerWidget {
  const MissingProductSheet({super.key, required this.gtin, this.prefill});

  /// The code that was read. It is the figure nobody is going to type correctly
  /// from memory.
  final String gtin;

  /// What Open Food Facts knew about the package, when it knew anything.
  final BarcodePrefill? prefill;

  static Future<void> show(
    BuildContext context, {
    required String gtin,
    BarcodePrefill? prefill,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => MissingProductSheet(gtin: gtin, prefill: prefill),
  );

  Future<void> _ask(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final draft = await NewThreadSheet.show(
      context,
      initialTitle: l10n.missingProductThreadTitle,
      initialBody: prefill == null
          ? l10n.missingProductThreadBody(gtin)
          : l10n.missingProductThreadBodyNamed(gtin, prefill!.displayName),
    );
    if (draft == null || !context.mounted) return;

    final outcome = await ref
        .read(messagingRepositoryProvider)
        .openCampaignThread(
          campaignId: draft.campaignId,
          title: draft.title,
          body: draft.body,
        );
    if (!context.mounted) return;

    Navigator.of(context).pop();
    switch (outcome) {
      case MessagingDone(:final value):
        await Navigator.of(context).push(ThreadView.route(value.id));
      case MessagingRefused(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.operatorMessage(context.l10n))),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCreate = ref.watch(canEditCatalogProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: sheetBottomInset(context, base: 20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.missingProductTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            prefill == null
                ? context.l10n.missingProductUnknown(gtin)
                : context.l10n.missingProductDescribed(
                    gtin,
                    prefill!.displayName,
                  ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (canCreate)
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await Navigator.of(
                  context,
                ).push(ProductFormView.route(prefill: prefill));
              },
              icon: const Icon(Icons.add),
              label: Text(context.l10n.productCreateAction),
            )
          else
            FilledButton.icon(
              onPressed: () => _ask(context, ref),
              icon: const Icon(Icons.forum_outlined),
              label: Text(context.l10n.missingProductAskAction),
            ),
          const SizedBox(height: 8),
          Text(
            canCreate
                ? context.l10n.missingProductCreateHint
                : context.l10n.missingProductAskHint,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
