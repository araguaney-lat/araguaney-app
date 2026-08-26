import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/app_bottom_bar.dart';
import '../../boxes/ui/boxes_list_view.dart';
import '../../home/ui/home_view.dart';
import '../../intake/ui/intake_form_view.dart';
import '../../messaging/data/messaging_providers.dart';
import '../../messaging/ui/threads_list_view.dart';
import '../../scanning/ui/scanner_view.dart';
import 'more_menu_sheet.dart';

/// The four permanent destinations.
///
/// «Menú» is a destination and not a loose button because the rest of the
/// application lives behind it: if it is not marked as selected, whoever opens
/// transfers from there is left not knowing where in the application they are.
enum ShellTab { home, boxes, messages, menu }

/// The bar's central action.
///
/// The role decides it, not the screen: whoever coordinates comes to verify
/// what somebody else captured, and whoever volunteers comes to capture. It is
/// the same criterion the backend applies to permissions, brought to the thumb.
({IconData icon, String label}) centerActionFor(
  AppLocalizations l10n, {
  required bool coordinates,
}) => coordinates
    ? (icon: Icons.qr_code_scanner, label: l10n.navScan)
    : (icon: Icons.add_box_outlined, label: l10n.navCapture);

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  ShellTab _tab = ShellTab.home;

  /// The tabs are built the first time they are visited and kept afterwards.
  ///
  /// An `IndexedStack` with everything inside looks convenient until you look
  /// at the network: it builds all four at launch, and each one asks for its
  /// own. Whoever opens the application to capture would end up downloading
  /// boxes and messages they did not ask for, on a collection centre's
  /// connection, before being able to touch anything.
  final _visited = <ShellTab>{ShellTab.home};

  Future<void> _openMenu() async {
    // The menu does not replace the screen: it opens on top and returns to
    // where you were. Marking it selected while it is open is what makes it
    // read as «I am in the menu» and not as though the screen behind changed.
    setState(() => _tab = ShellTab.menu);
    await MoreMenuSheet.show(context);
    if (mounted) setState(() => _tab = ShellTab.home);
  }

  void _select(int index) {
    final tab = ShellTab.values[index];
    if (tab == ShellTab.menu) {
      _openMenu();
      return;
    }
    setState(() {
      _tab = tab;
      _visited.add(tab);
    });
  }

  @override
  Widget build(BuildContext context) {
    final coordinates = ref.watch(isCenterCoordinatorProvider);
    final unread = ref.watch(unreadMessagesProvider).valueOrNull ?? 0;
    final center = centerActionFor(context.l10n, coordinates: coordinates);

    return Scaffold(
      body: IndexedStack(
        index: _tab == ShellTab.menu ? ShellTab.home.index : _tab.index,
        children: [
          const HomeView(),
          if (_visited.contains(ShellTab.boxes))
            const BoxesListView()
          else
            const SizedBox.shrink(),
          if (_visited.contains(ShellTab.messages))
            const ThreadsListView()
          else
            const SizedBox.shrink(),
          const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: _tab.index,
        onSelected: _select,
        centerIcon: center.icon,
        centerTooltip: center.label,
        onCenterPressed: () => Navigator.of(
          context,
        ).push(coordinates ? ScannerView.route() : IntakeFormView.route()),
        items: [
          BottomBarItem(icon: Icons.home_outlined, label: context.l10n.navHome),
          BottomBarItem(
            icon: Icons.inventory_2_outlined,
            label: context.l10n.boxesTitle,
          ),
          BottomBarItem(
            icon: Icons.chat_bubble_outline,
            label: context.l10n.messagesTitle,
            badge: unread,
          ),
          BottomBarItem(icon: Icons.menu, label: context.l10n.navMenu),
        ],
      ),
    );
  }
}
