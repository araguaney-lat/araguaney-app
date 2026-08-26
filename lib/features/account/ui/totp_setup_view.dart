import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/api/generated/models/totp_setup_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../data/account_providers.dart';
import '../data/account_repository.dart';

/// Turning two-step verification on.
///
/// Three moments, and the order matters: the server hands over a secret,
/// requires a code generated with it, and only then requires it on the way in.
/// That middle step exists so a badly copied secret does not leave anybody out
/// of their own account.
class TotpSetupView extends ConsumerStatefulWidget {
  const TotpSetupView({super.key});

  static Route<bool> route() =>
      MaterialPageRoute<bool>(builder: (_) => const TotpSetupView());

  @override
  ConsumerState<TotpSetupView> createState() => _TotpSetupViewState();
}

class _TotpSetupViewState extends ConsumerState<TotpSetupView> {
  final _code = TextEditingController();
  TotpSetupOut? _setup;
  List<String>? _backupCodes;
  bool _busy = false;
  String? _failure;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    final outcome = await ref.read(accountRepositoryProvider).setUpTotp();
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (outcome) {
        case AccountDone(:final value):
          _setup = value;
        case AccountRefused(:final failure):
          _failure = failure.operatorMessage(context.l10n);
      }
    });
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    final outcome = await ref
        .read(accountRepositoryProvider)
        .confirmTotp(_code.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (outcome) {
        case AccountDone(:final value):
          _backupCodes = value;
        case AccountRefused(:final failure):
          _failure = failure.operatorMessage(context.l10n);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.totpChallengeTitle),
      // With the codes on screen there is no back arrow: they are the only copy
      // and leaving by accident loses them.
      automaticallyImplyLeading: _backupCodes == null,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: switch (_backupCodes) {
          final codes? => _BackupCodes(codes: codes),
          _ => _setupBody(context),
        },
      ),
    ),
  );

  Widget _setupBody(BuildContext context) {
    final theme = Theme.of(context);
    if (_setup case final setup?) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.totpSetupInstruction,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: QrImageView(data: setup.qrUri, size: 220),
            ),
          ),
          const SizedBox(height: 16),
          // The secret written out, for somebody who cannot scan because the
          // code application is on this very phone.
          _CopyRow(
            label: context.l10n.totpSecretManualHint,
            value: setup.secret,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: context.l10n.sixDigitCodeLabel,
            ),
            onSubmitted: (_) => _confirm(),
          ),
          if (_failure case final message?) ...[
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _confirm,
            child: Text(context.l10n.totpEnableAction),
          ),
        ],
      );
    }

    if (_failure case final message?) {
      return Column(
        children: [
          Text(message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _start,
            child: Text(context.l10n.actionRetry),
          ),
        ],
      );
    }

    return const Center(child: CircularProgressIndicator());
  }
}

/// The backup codes, which the server hands over **once only**.
///
/// If they are lost and the phone with the code application is lost too, there
/// is no way in without somebody in administration resetting the account. That
/// is why this screen does not close by itself, has no back arrow, and asks for
/// an explicit confirmation that they were saved.
class _BackupCodes extends StatefulWidget {
  const _BackupCodes({required this.codes});

  final List<String> codes;

  @override
  State<_BackupCodes> createState() => _BackupCodesState();
}

class _BackupCodesState extends State<_BackupCodes> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.totpAlreadyEnabled,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.backupCodesWarning,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              widget.codes.join('\n'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: widget.codes.join('\n')),
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(context.l10n.backupCodesCopied)),
                );
            }
          },
          icon: const Icon(Icons.copy_all_outlined),
          label: Text(context.l10n.copyAction),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _saved,
          onChanged: (value) => setState(() => _saved = value ?? false),
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.backupCodesAcknowledge),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _saved ? () => Navigator.of(context).pop(true) : null,
          child: Text(context.l10n.actionFinish),
        ),
      ],
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            SelectableText(value),
          ],
        ),
      ),
      IconButton(
        tooltip: context.l10n.copyAction,
        icon: const Icon(Icons.copy_outlined),
        onPressed: () => Clipboard.setData(ClipboardData(text: value)),
      ),
    ],
  );
}
