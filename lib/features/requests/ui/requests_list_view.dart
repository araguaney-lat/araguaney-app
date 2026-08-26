import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/request_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/relative_time.dart';
import '../../../core/ui/status_labels.dart';
import '../data/requests_providers.dart';
import '../data/requests_repository.dart';
import 'new_request_sheet.dart';
import 'request_record_view.dart';

/// The board: what centres have said they need.
///
/// **The one thing a phone is better at than the panel is the writing.** The
/// contract asks for a subject and a sentence, so the person who knows what is
/// missing can open a request while standing in front of the empty shelf,
/// instead of remembering it later at a desk.
///
/// Open ones first and the oldest at the top of that half, by the same argument
/// as the incidents: a request that nobody has answered in a week is exactly
/// the one being forgotten. What comes after — in progress, resolved, closed —
/// is history, and it goes newest first.
///
/// Everybody with a session can read the board and write on it; the server
/// narrows the list to their own centre and shows a national administration all
/// of them. Only moving the status is gated, and only that is hidden by role.
class RequestsListView extends ConsumerStatefulWidget {
  const RequestsListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const RequestsListView());

  @override
  ConsumerState<RequestsListView> createState() => _RequestsListViewState();
}

class _RequestsListViewState extends ConsumerState<RequestsListView> {
  bool _creating = false;

  Future<void> _create() async {
    final written = await NewRequestSheet.show(context);
    if (written == null || !mounted) return;

    setState(() => _creating = true);
    final outcome = await ref
        .read(requestsRepositoryProvider)
        .create(title: written.title, description: written.description);
    if (!mounted) return;
    setState(() => _creating = false);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    switch (outcome) {
      case RequestsRead(:final value):
        ref.invalidate(requestsBoardProvider);
        messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.requestCreated)),
        );
        // Straight into the record: the matching runs on what was just
        // written, and the answer to «does anybody have this?» is the reason
        // for writing it.
        await navigator.push(RequestRecordView.route(value.id));
      case RequestsRefused(:final failure):
        messenger.showSnackBar(
          SnackBar(content: Text(failure.operatorMessage(context.l10n))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(requestsBoardProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.requestsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creating ? null : _create,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.requestNewAction),
      ),
      body: switch (board) {
        AsyncData(value: RequestsRead(:final value)) when value.isEmpty =>
          _Message(context.l10n.requestsEmpty),
        AsyncData(value: RequestsRead(:final value)) => _Board(requests: value),
        AsyncData(value: RequestsRefused(:final failure)) => _Message(
          failure.operatorMessage(context.l10n),
        ),
        AsyncError(:final error) => _Message('$error'),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Board extends ConsumerWidget {
  const _Board({required this.requests});

  final List<RequestOut> requests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = requests.where((r) => r.status == RequestStatus.open).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final rest = requests.where((r) => r.status != RequestStatus.open).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(requestsBoardProvider),
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              open.isEmpty
                  ? context.l10n.nothingAwaitsDecision
                  : context.l10n.requestsOpenCount(open.length),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          for (final request in open) _RequestCard(request: request),
          if (rest.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(context.l10n.requestsAnsweredHeading),
            ),
            for (final request in rest) _RequestCard(request: request),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final RequestOut request;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: InkWell(
        onTap: () =>
            Navigator.of(context).push(RequestRecordView.route(request.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(request.title, style: text.titleMedium)),
                  Text(
                    describeAge(
                      context.l10n,
                      request.createdAt,
                      DateTime.now(),
                    ),
                    style: text.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.description,
                style: text.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Chip(
                    label: Text(
                      requestStatusLabel(context.l10n, request.status),
                    ),
                  ),
                  const Spacer(),
                  // The thread is what says whether anybody answered, and it is
                  // the first thing whoever wrote the request comes looking
                  // for. A request with no replies says nothing rather than
                  // «0», which reads as a figure instead of as a silence.
                  if (request.messages.isNotEmpty)
                    Text(
                      context.l10n.requestReplyCount(request.messages.length),
                      style: text.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
