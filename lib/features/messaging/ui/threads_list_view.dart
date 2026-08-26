import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/thread_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../data/messaging_providers.dart';
import '../data/messaging_repository.dart';
import 'new_thread_sheet.dart';
import 'thread_view.dart';

/// The threads this person can read.
class ThreadsListView extends ConsumerWidget {
  const ThreadsListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const ThreadsListView());

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final draft = await NewThreadSheet.show(context);
    if (draft == null || !context.mounted) return;

    final outcome = await ref
        .read(messagingRepositoryProvider)
        .openCampaignThread(
          campaignId: draft.campaignId,
          title: draft.title,
          body: draft.body,
        );
    if (!context.mounted) return;

    switch (outcome) {
      case MessagingDone(:final value):
        ref.invalidate(threadsProvider);
        await Navigator.of(context).push(ThreadView.route(value.id));
      case MessagingRefused(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.operatorMessage(context.l10n))),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(threadsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.messagesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context, ref),
        icon: const Icon(Icons.edit_outlined),
        label: Text(context.l10n.threadNewAction),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(threadsProvider)
            ..invalidate(unreadMessagesProvider);
        },
        child: switch (threads) {
          AsyncData(:final value) when value.isEmpty => _Message(
            context.l10n.threadsEmpty,
          ),
          AsyncData(:final value) => ListView.separated(
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _ThreadTile(thread: value[index]),
          ),
          AsyncError(:final error) => _Message(
            ApiErrorMapper.fromAny(error).operatorMessage(context.l10n),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread});

  final ThreadOut thread;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(
      thread.threadType == ThreadType.private
          ? Icons.lock_outline
          : Icons.campaign_outlined,
    ),
    title: Text(thread.title),
    subtitle: Text(
      '${threadTypeLabel(context.l10n, thread.threadType)} · '
      '${formatShortDate(thread.updatedAt)}',
    ),
    onTap: () => Navigator.of(context).push(ThreadView.route(thread.id)),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
}
