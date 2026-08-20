import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/ui/app_bottom_bar.dart';
import '../../boxes/ui/boxes_list_view.dart';
import '../../home/ui/home_view.dart';
import '../../intake/ui/intake_form_view.dart';
import '../../messaging/data/messaging_providers.dart';
import '../../messaging/ui/threads_list_view.dart';
import '../../scanning/ui/scanner_view.dart';
import 'more_menu_sheet.dart';

/// Los cuatro destinos permanentes.
///
/// «Menú» es un destino y no un botón suelto porque el resto de la aplicación
/// vive detrás de él: si no se marca como seleccionado, quien abre transferencias
/// desde ahí se queda sin saber en qué parte de la aplicación está.
enum ShellTab { home, boxes, messages, menu }

/// La acción central de la barra.
///
/// La decide el rol y no la pantalla: quien coordina llega a verificar lo que
/// otra persona capturó, y quien es voluntariado llega a capturar. Es el mismo
/// criterio que el backend aplica a los permisos, traído al pulgar.
({IconData icon, String label}) centerActionFor({required bool coordinates}) =>
    coordinates
    ? (icon: Icons.qr_code_scanner, label: 'Escanear')
    : (icon: Icons.add_box_outlined, label: 'Capturar');

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  ShellTab _tab = ShellTab.home;

  /// Las pestañas se construyen la primera vez que se visitan y se conservan
  /// después.
  ///
  /// Un `IndexedStack` con todo dentro parece cómodo hasta que se mira la red:
  /// construye las cuatro al arrancar, y cada una pide lo suyo. Quien abre la
  /// aplicación para capturar acabaría descargando cajas y mensajes que no
  /// pidió, en la conexión de un centro de acopio, antes de poder tocar nada.
  final _visited = <ShellTab>{ShellTab.home};

  Future<void> _openMenu() async {
    // El menú no reemplaza la pantalla: se abre encima y devuelve a donde
    // estaba. Marcarlo seleccionado mientras está abierto es lo que hace que se
    // lea como «estoy en el menú» y no como que la pantalla de atrás cambió.
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
    final center = centerActionFor(coordinates: coordinates);

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
          const BottomBarItem(icon: Icons.home_outlined, label: 'Inicio'),
          const BottomBarItem(icon: Icons.inventory_2_outlined, label: 'Cajas'),
          BottomBarItem(
            icon: Icons.chat_bubble_outline,
            label: 'Mensajes',
            badge: unread,
          ),
          const BottomBarItem(icon: Icons.menu, label: 'Menú'),
        ],
      ),
    );
  }
}
