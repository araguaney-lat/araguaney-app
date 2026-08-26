import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/user_out.dart';
import '../../../core/api/generated/models/user_profile_out.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/i18n/language_preference.dart';
import '../../../core/ui/record_field.dart';
import '../../session/ui/change_password_view.dart';
import '../data/account_providers.dart';
import '../data/account_repository.dart';
import 'totp_setup_view.dart';

/// Who you are and how your account is protected.
///
/// It is always looked up online. A cached profile would show a role or a
/// centre that may have changed, and here that is not a detail: it is what
/// somebody looks at to know what they can do.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const ProfileView());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(myAccountProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profileTitle)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myAccountProvider),
        child: switch (account) {
          AsyncData(:final value) => _Loaded(
            profile: value.profile,
            account: value.account,
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

class _Loaded extends ConsumerWidget {
  const _Loaded({required this.profile, required this.account});

  final UserProfileOut profile;
  final UserOut account;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: [
      RecordField(
        label: context.l10n.nameLabel,
        value: profile.fullName ?? '—',
      ),
      RecordField(label: context.l10n.usernameLabel, value: profile.username),
      RecordField(label: context.l10n.emailLabel, value: profile.email),
      if (profile.centerName case final center?)
        RecordField(label: context.l10n.centerLabel, value: center),
      if (profile.centerRole case final role?)
        RecordField(
          label: context.l10n.roleLabel,
          value: _roleLabel(context.l10n, role),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: OutlinedButton(
          onPressed: () => _rename(context, ref, profile.fullName ?? ''),
          child: Text(context.l10n.profileChangeName),
        ),
      ),
      const Divider(height: 32),
      ListTile(
        title: Text(context.l10n.passwordLabel),
        subtitle: Text(context.l10n.passwordChangeHint),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ChangePasswordView(forced: false),
          ),
        ),
      ),
      _TotpTile(enabled: account.totpEnabled),
      if (account.mustAcceptTerms) const _TermsTile(),
      const Divider(height: 32),
      const _LanguageTile(),
    ],
  );

  static String _roleLabel(AppLocalizations l10n, String role) =>
      switch (role) {
        'volunteer' => l10n.roleVolunteerLabel,
        'coordinator' => l10n.roleCoordinatorLabel,
        'national_admin' => l10n.roleNationalAdminLabel,
        _ => role,
      };

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.yourNameLabel),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: context.l10n.fullNameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(context.l10n.actionSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !context.mounted) return;

    final outcome = await ref.read(accountRepositoryProvider).rename(name);
    if (!context.mounted) return;

    if (outcome case AccountRefused(:final failure)) {
      _say(context, failure.operatorMessage(context.l10n));
      return;
    }
    ref.invalidate(myAccountProvider);
  }
}

/// Which language the application is seen in.
///
/// **Following the phone is the default case and appears first.** Nobody chose
/// this language inside the application: they chose it when setting up their
/// phone, and asking again would treat it as a decision they did not take.
///
/// Choosing by hand exists for the case that does happen: a centre device set
/// up by one person and used by another.
class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  /// What each language is called, **in that language**.
  ///
  /// It comes from the ARB and not from a constant here because a language name
  /// is not translated: «Español» is «Español» in the English list, and that is
  /// exactly the point of a picker — that somebody who reads only one finds
  /// theirs. Each language file repeats the names as they are, on purpose.
  static String _name(AppLocalizations l10n, String code) => switch (code) {
    'es' => l10n.languageNameEs,
    'en' => l10n.languageNameEn,
    _ => code,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = ref.watch(languageProvider).valueOrNull?.languageCode;

    return ListTile(
      leading: const Icon(Icons.translate),
      title: Text(context.l10n.languageLabel),
      subtitle: Text(
        chosen == null
            ? context.l10n.languageFollowsPhone
            : _name(context.l10n, chosen),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: RadioGroup<String?>(
            groupValue: chosen,
            onChanged: (value) {
              ref.read(languageProvider.notifier).choose(value);
              Navigator.of(sheetContext).pop();
            },
            child: ListView(
              shrinkWrap: true,
              children: [
                RadioListTile<String?>(
                  value: null,
                  title: Text(context.l10n.languageFollowsPhone),
                ),
                for (final locale in AppLocalizations.supportedLocales)
                  RadioListTile<String?>(
                    value: locale.languageCode,
                    title: Text(_name(context.l10n, locale.languageCode)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TotpTile extends ConsumerWidget {
  const _TotpTile({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    title: Text(context.l10n.totpChallengeTitle),
    subtitle: Text(
      enabled
          ? context.l10n.totpEnabledCaption
          : context.l10n.totpDisabledCaption,
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: () async {
      if (enabled) {
        await _disable(context, ref);
      } else {
        final done = await Navigator.of(context).push(TotpSetupView.route());
        if (done ?? false) ref.invalidate(myAccountProvider);
      }
    },
  );

  /// Removing it asks for a code, just like adding it.
  ///
  /// It is not a formality: it is what stops whoever finds an unlocked phone
  /// turning off the second barrier before walking away with the account.
  Future<void> _disable(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.totpDisableConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.totpDisableWarning),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: context.l10n.codeLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.keepAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(context.l10n.disableAction),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.isEmpty || !context.mounted) return;

    final outcome = await ref.read(accountRepositoryProvider).disableTotp(code);
    if (!context.mounted) return;

    if (outcome case AccountRefused(:final failure)) {
      _say(context, failure.operatorMessage(context.l10n));
      return;
    }
    ref.invalidate(myAccountProvider);
  }
}

/// The server asks for the terms to be accepted and **does not block** over it,
/// so neither does this: it is offered, not interposed.
class _TermsTile extends ConsumerWidget {
  const _TermsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    leading: const Icon(Icons.assignment_outlined),
    title: Text(context.l10n.pendingTermsTitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: () async {
      final outcome = await ref
          .read(accountRepositoryProvider)
          .acceptTerms('current');
      if (!context.mounted) return;
      if (outcome case AccountRefused(:final failure)) {
        _say(context, failure.operatorMessage(context.l10n));
        return;
      }
      ref.invalidate(myAccountProvider);
    },
  );
}

void _say(BuildContext context, String message) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(message)));

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(32),
    children: [Text(text, textAlign: TextAlign.center)],
  );
}
