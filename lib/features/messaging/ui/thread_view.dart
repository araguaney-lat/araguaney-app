import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/thread_detail_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../data/messaging_providers.dart';
import '../data/messaging_repository.dart';

/// Un hilo y sus respuestas.
///
/// Abrirlo lo marca como leído. Es lo que quien lo abre espera, y lo que hace
/// que el contador de la pantalla principal signifique algo: si siguiera
/// contando lo ya leído, la gente aprendería a ignorarlo.
class ThreadView extends ConsumerStatefulWidget {
  const ThreadView({super.key, required this.threadId});

  final String threadId;

  static Route<void> route(String threadId) =>
      MaterialPageRoute<void>(builder: (_) => ThreadView(threadId: threadId));

  @override
  ConsumerState<ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends ConsumerState<ThreadView> {
  final _reply = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    if (!mounted) return;
    await ref.read(messagingRepositoryProvider).markRead(widget.threadId);
    if (mounted) ref.invalidate(unreadMessagesProvider);
  }

  Future<void> _send() async {
    final body = _reply.text.trim();
    if (body.isEmpty) return;

    setState(() => _sending = true);
    final outcome = await ref
        .read(messagingRepositoryProvider)
        .reply(threadId: widget.threadId, body: body);
    if (!mounted) return;

    setState(() => _sending = false);

    switch (outcome) {
      case MessagingDone():
        _reply.clear();
        ref.invalidate(threadProvider(widget.threadId));
      case MessagingRefused(:final failure):
        // El texto se queda en el campo: perder lo escrito por un fallo de red
        // sería la peor forma de contestar a alguien que ya escribió.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.operatorMessage(context.l10n))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(threadProvider(widget.threadId));

    return Scaffold(
      appBar: AppBar(title: Text(thread.valueOrNull?.title ?? 'Hilo')),
      body: Column(
        children: [
          Expanded(
            child: switch (thread) {
              AsyncData(:final value) => _Conversation(thread: value),
              AsyncError(:final error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    ApiErrorMapper.fromAny(error).operatorMessage(context.l10n),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
          if (thread.hasValue)
            _ReplyBar(controller: _reply, sending: _sending, onSend: _send),
        ],
      ),
    );
  }
}

class _Conversation extends StatelessWidget {
  const _Conversation({required this.thread});

  final ThreadDetailOut thread;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _Bubble(body: thread.body, at: thread.createdAt, opening: true),
      for (final reply in thread.replies)
        _Bubble(body: reply.body, at: reply.createdAt, opening: false),
      if (thread.attachments.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            '${thread.attachments.length} '
            '${thread.attachments.length == 1 ? 'adjunto' : 'adjuntos'} · '
            'se abren desde el panel web',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
    ],
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.body, required this.at, required this.opening});

  final String body;
  final DateTime at;
  final bool opening;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: opening ? scheme.secondaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body),
            const SizedBox(height: 6),
            Text(
              formatShortDate(at),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  const _ReplyBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 8,
        top: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(labelText: context.l10n.replyAction),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: sending ? null : onSend,
            icon: const Icon(Icons.send),
            tooltip: context.l10n.sendAction,
          ),
        ],
      ),
    ),
  );
}
