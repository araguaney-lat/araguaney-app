import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/request_message_out.dart';
import '../../../core/api/generated/models/request_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/category_label.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/sheet_insets.dart';
import '../../../core/ui/status_labels.dart';
import '../data/requests_providers.dart';
import '../data/requests_repository.dart';

/// A request, what the platform has of it, and the conversation about it.
///
/// The three parts answer three questions in the order they get asked: what was
/// asked for, whether anybody has it, and what has been said since.
///
/// **The matching is a shortcut and never a gate.** The server answers with an
/// empty list when it is off, out of budget or the provider did not reply, and
/// so does this screen when the call fails: the section simply is not drawn.
/// Turning that silence into an error would put a red line on a screen whose
/// whole job is to get somebody an answer.
class RequestRecordView extends ConsumerStatefulWidget {
  const RequestRecordView({super.key, required this.requestId});

  final String requestId;

  static Route<void> route(String requestId) => MaterialPageRoute<void>(
    builder: (_) => RequestRecordView(requestId: requestId),
  );

  @override
  ConsumerState<RequestRecordView> createState() => _RequestRecordViewState();
}

class _RequestRecordViewState extends ConsumerState<RequestRecordView> {
  final _reply = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _reply.text.trim();
    if (body.isEmpty || _sending) return;

    setState(() => _sending = true);
    final outcome = await ref
        .read(requestsRepositoryProvider)
        .reply(id: widget.requestId, body: body);
    if (!mounted) return;
    setState(() => _sending = false);

    switch (outcome) {
      case RequestsRead():
        // The text only leaves the field once the server has it: losing what
        // was written to a network failure is the worst way to answer somebody.
        _reply.clear();
        ref.invalidate(requestRecordProvider(widget.requestId));
        ref.invalidate(requestsBoardProvider);
      case RequestsRefused(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.operatorMessage(context.l10n))),
        );
    }
  }

  Future<void> _moveStatus(RequestOut request) async {
    final chosen = await _StatusSheet.show(context, current: request.status);
    if (chosen == null || !mounted) return;

    final outcome = await ref
        .read(requestsRepositoryProvider)
        .updateStatus(id: request.id, status: chosen);
    if (!mounted) return;

    switch (outcome) {
      case RequestsRead():
        ref.invalidate(requestRecordProvider(widget.requestId));
        ref.invalidate(requestsBoardProvider);
      case RequestsRefused(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.operatorMessage(context.l10n))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = ref.watch(requestRecordProvider(widget.requestId));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.requestRecordTitle)),
      body: switch (record) {
        AsyncData(value: RequestsRead(:final value)) => _Record(
          request: value,
          reply: _reply,
          sending: _sending,
          onSend: _send,
          onMoveStatus: () => _moveStatus(value),
        ),
        AsyncData(value: RequestsRefused(:final failure)) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              failure.operatorMessage(context.l10n),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Record extends ConsumerWidget {
  const _Record({
    required this.request,
    required this.reply,
    required this.sending,
    required this.onSend,
    required this.onMoveStatus,
  });

  final RequestOut request;
  final TextEditingController reply;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onMoveStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final canMove = ref.watch(canMoveRequestStatusProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(request.title, style: text.titleLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(
                      requestStatusLabel(context.l10n, request.status),
                    ),
                  ),
                  const Spacer(),
                  if (canMove)
                    TextButton(
                      onPressed: onMoveStatus,
                      child: Text(context.l10n.requestMoveStatusAction),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // The words of whoever wrote it, unedited: the description is
              // what the matching reads and what anybody answering replies to.
              Text(request.description, style: text.bodyLarge),
              const SizedBox(height: 8),
              RecordField(
                label: context.l10n.requestOpenedLabel,
                value: formatShortDateTime(request.createdAt),
              ),
              const SizedBox(height: 16),
              _Matches(requestId: request.id),
              const SizedBox(height: 16),
              Text(context.l10n.requestThreadHeading, style: text.titleMedium),
              const SizedBox(height: 8),
              if (request.messages.isEmpty)
                Text(context.l10n.requestThreadEmpty, style: text.bodyMedium)
              else
                for (final message in request.messages)
                  _Message(message: message),
            ],
          ),
        ),
        _ReplyBar(controller: reply, sending: sending, onSend: onSend),
      ],
    );
  }
}

/// What the platform has of what was asked for.
///
/// It is drawn only when the server answered with something. An empty answer is
/// the normal case — the matching may be off — and a section that says «no
/// matches» would read as «nobody has this», which is a much stronger claim
/// than the server made.
class _Matches extends ConsumerWidget {
  const _Matches({required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(requestMatchesProvider(requestId)).valueOrNull;
    if (matches == null || matches.isEmpty) return const SizedBox.shrink();

    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.requestMatchesHeading, style: text.titleMedium),
        const SizedBox(height: 4),
        // The stock comes from the database and is scoped by the server: a
        // coordination does not discover another centre's inventory here.
        Text(context.l10n.requestMatchesHint, style: text.bodySmall),
        const SizedBox(height: 8),
        for (final match in matches)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(categoryLabel(context.l10n, match.category)),
            trailing: Text(
              context.l10n.requestMatchStock(match.boxCount, match.totalUnits),
              style: text.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message});

  final RequestMessageOut message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formatShortDateTime(message.createdAt), style: text.bodySmall),
          const SizedBox(height: 2),
          Text(message.body, style: text.bodyMedium),
        ],
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
  Widget build(BuildContext context) => Material(
    elevation: 8,
    child: Padding(
      // A reply is typed with a thumb: without this the field ends up under the
      // keyboard on the phones this is meant for.
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: sheetBottomInset(context) + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: context.l10n.requestReplyHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          IconButton(
            onPressed: sending ? null : onSend,
            icon: const Icon(Icons.send),
            tooltip: context.l10n.requestReplyAction,
          ),
        ],
      ),
    ),
  );
}

/// Where the request goes next.
///
/// The four states are the server's `REQUEST_STATUSES` and they are chosen, not
/// typed: writing one it does not know answers `INVALID_STATUS`. Which one is
/// reasonable from which is the server's business — this offers the four and
/// lets it refuse.
class _StatusSheet extends StatelessWidget {
  const _StatusSheet({required this.current});

  final String current;

  static Future<String?> show(
    BuildContext context, {
    required String current,
  }) => showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    builder: (_) => _StatusSheet(current: current),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.l10n.requestMoveStatusTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final status in RequestStatus.all)
          ListTile(
            title: Text(requestStatusLabel(context.l10n, status)),
            trailing: status == current ? const Icon(Icons.check) : null,
            onTap: status == current
                ? null
                : () => Navigator.of(context).pop(status),
          ),
      ],
    ),
  );
}
