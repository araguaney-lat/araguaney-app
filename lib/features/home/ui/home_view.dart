import 'package:flutter/material.dart';

import '../../../core/i18n/generated/app_localizations.dart';

/// Pantalla inicial temporal mientras se construyen las features operativas.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(child: Text(l10n.homePlaceholderMessage)),
    );
  }
}
