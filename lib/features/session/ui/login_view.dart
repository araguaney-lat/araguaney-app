import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/session.dart';
import '../../../core/platform/open_link.dart';
import 'forgot_password_view.dart';

/// Inicio de sesión. Las credenciales las valida el servidor: aquí solo se
/// comprueba que los campos no vengan vacíos, para no gastar una petición.
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    await ref
        .read(sessionControllerProvider.notifier)
        .logIn(username: _username.text, password: _password.text);
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionControllerProvider);
    final failure = state is SessionAbsent ? state.failureMessage : null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ArrivingMark(),
                    const SizedBox(height: 16),
                    Text(
                      'Araguaney',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inicia sesión para operar tu centro de acopio.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _username,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Correo o usuario',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Escribe tu correo o usuario'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _obscurePassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Escribe tu contraseña'
                          : null,
                    ),
                    if (failure != null) ...[
                      const SizedBox(height: 16),
                      _FailureBanner(message: failure),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(
                              context,
                            ).push(ForgotPasswordView.route()),
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                    const _RegisterCenterLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La salida para quien todavía no tiene centro.
///
/// La aplicación abre en un acceso y no ofrece registro, a propósito: a un
/// centro se entra por invitación. Pero quien oyó hablar de Araguaney, instaló
/// esto y todavía no tiene centro se topaba con un formulario que no explicaba
/// nada. Esto no lo resuelve dentro de la aplicación —lo lleva a donde sí se
/// resuelve.
///
/// **El formulario no se trae aquí, y no es por pereza.** Está detrás de una
/// verificación antiabuso del navegador, y rehacerlo nativo significaría meter
/// esa verificación en una vista incrustada, donde vale menos, con su
/// configuración dentro del binario. Además el trámite termina en un correo
/// con un enlace a la web, igual que la recuperación de contraseña: cerrarlo
/// aquí exigiría App Links y un `assetlinks.json` servido desde el dominio,
/// que es un cambio del otro repositorio.
///
/// **El destino sí sigue al teléfono, aunque la interfaz no.** Los textos de
/// esta aplicación van en español porque es el idioma en que se opera un
/// centro; quien toca este enlace todavía no opera ninguno, y la página
/// pública existe de verdad en los dos idiomas. Mandarlo al formulario en
/// español teniendo el teléfono en inglés sería perder algo a cambio de nada.
class _RegisterCenterLink extends ConsumerWidget {
  const _RegisterCenterLink();

  /// El español es el idioma por defecto de la web y va sin prefijo; el inglés
  /// lleva prefijo **y otro slug**, no una traducción del mismo.
  static const _spanish = 'https://araguaney.lat/registrar-centro';
  static const _english = 'https://araguaney.lat/en/register-center';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El idioma del teléfono, no el de la aplicación: `MaterialApp` fija
    // `Locale('es')`, así que preguntarle a `Localizations` respondería
    // siempre lo mismo.
    final phone = View.of(context).platformDispatcher.locale;
    final url = phone.languageCode == 'en' ? _english : _spanish;

    return TextButton(
      onPressed: () async {
        final opened = await ref.read(openLinkProvider)(url);
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el navegador.')),
          );
        }
      },
      child: const Text('¿Tu centro aún no está registrado?'),
    );
  }
}

/// El árbol, entrando.
///
/// **La animación existe por una costura, no por adorno.** El splash del
/// sistema dibuja este mismo árbol mientras arranca el proceso, y el primer
/// fotograma de Flutter lo sustituye por un formulario. Sin nada en medio, el
/// corte se ve. Una aparición corta convierte dos pantallas en una llegada.
///
/// Tres cosas que no puede costar:
///
/// - **No retrasa el formulario.** Quien llega aquí se quedó sin sesión, y a
///   veces a mitad de un turno. Esto envuelve lo que se dibuja: los campos
///   responden desde el primer fotograma y nada espera a que el tween termine.
/// - **No se repite.** Un logotipo en movimiento en la pantalla donde se
///   escribe una contraseña es algo de lo que apartar la vista.
/// - **Obedece la configuración del sistema.** Con las animaciones desactivadas
///   se dibuja el estado final y ya. La sensibilidad al movimiento no es una
///   preferencia que una marca pueda pisar.
class _ArrivingMark extends StatefulWidget {
  const _ArrivingMark();

  /// Ochenta puntos: `ic_mark_lg.png` mide 320 × 288, así que hasta una
  /// pantalla de 3,5× lo dibuja sin estirarlo.
  static const double _height = 80;

  @override
  State<_ArrivingMark> createState() => _ArrivingMarkState();
}

class _ArrivingMarkState extends State<_ArrivingMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se arranca aquí y no en `initState` porque la decisión depende del
    // `MediaQuery`, que allí todavía no existe.
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entrance = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: entrance,
      child: SlideTransition(
        // Sube un octavo de su alto: lo justo para que se lea como que llega,
        // no como que se desliza desde fuera de la pantalla.
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(entrance),
        child: Image.asset(
          'assets/icon/ic_mark_lg.png',
          height: _ArrivingMark._height,
          // El alto manda, igual que en la cabecera del inicio: el árbol es
          // más ancho que alto.
          fit: BoxFit.fitHeight,
          filterQuality: FilterQuality.medium,
          semanticLabel: 'Araguaney',
        ),
      ),
    );
  }
}

/// Aviso de error de sesión. Vive aquí porque las tres pantallas de esta
/// feature lo comparten y no lo necesita nadie más todavía.
class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reutilizable por las otras pantallas de sesión.
class SessionFailureBanner extends StatelessWidget {
  const SessionFailureBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => _FailureBanner(message: message);
}
