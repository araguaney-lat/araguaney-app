import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/session/ui/change_password_view.dart';
import '../../features/session/ui/login_view.dart';
import '../../features/session/ui/totp_challenge_view.dart';
import '../../features/session/ui/update_required_view.dart';
import '../../features/shell/ui/app_shell.dart';
import '../api/client_version_gate.dart';
import '../api/client_version_providers.dart';
import '../auth/auth_providers.dart';
import '../auth/session.dart';
import '../ui/brand_splash.dart';
import 'push_router.dart';

/// Decide qué se ve según el estado de la sesión.
///
/// La navegación no autenticada no existe: no hay una ruta a la que llegar sin
/// sesión y luego rebotar, sino un único sitio que decide. Así no queda ninguna
/// pantalla accesible por descuido desde un enlace o un `pop`.
class SessionGate extends ConsumerWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Se interpone antes que la sesión, y solo cuando el servidor lo dijo:
    // mientras la consulta está en vuelo, o si falló, esto no vale
    // `updateRequired` y no se ve nada distinto. Nadie se queda fuera por una
    // petición que no llegó.
    // `valueOrNull` y no `value`: en un `AsyncError` el segundo **relanza**, y
    // eso convertiría un fallo de la comprobación en una pantalla de error —
    // exactamente lo que esta compuerta promete no hacer.
    if (ref.watch(clientVersionStatusProvider).valueOrNull ==
        ClientVersionStatus.updateRequired) {
      return const UpdateRequiredView();
    }

    final state = ref.watch(sessionControllerProvider);

    return switch (state) {
      SessionRestoring() => const BrandSplash(),
      SessionAbsent() => const LoginView(),
      SessionAwaitingTotp() => const TotpChallengeView(),
      // El cambio obligatorio se interpone incluso con sesión válida: el
      // servidor lo exige y saltarlo dejaría viva una clave temporal.
      SessionActive(:final session) when session.mustChangePassword =>
        const ChangePasswordView(),
      // El enrutado de avisos envuelve solo esta rama: navegar exige sesión,
      // y ni el inicio de sesión ni el cambio obligatorio de contraseña se
      // pueden saltar porque alguien tocara una notificación.
      SessionActive() => const PushRouter(child: AppShell()),
    };
  }
}
