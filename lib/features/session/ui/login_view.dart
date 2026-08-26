import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/session.dart';
import '../../../core/config/app_config.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/platform/open_link.dart';
import '../domain/login_failure_message.dart';
import 'app_version_footer.dart';
import 'forgot_password_view.dart';

/// Signing in. The credentials are validated by the server: all that is checked
/// here is that the fields do not arrive empty, so as not to spend a request.
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
    final failure = state is SessionAbsent && state.failure != null
        ? loginFailureMessage(context.l10n, state.failure!)
        : null;

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
                      context.l10n.appTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.loginSubtitle,
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
                      decoration: InputDecoration(
                        labelText: context.l10n.loginIdentifierLabel,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? context.l10n.loginIdentifierRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: context.l10n.passwordLabel,
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
                              ? context.l10n.showPassword
                              : context.l10n.hidePassword,
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? context.l10n.passwordRequired
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
                          : Text(context.l10n.loginSubmit),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(
                              context,
                            ).push(ForgotPasswordView.route()),
                      child: Text(context.l10n.loginForgotPassword),
                    ),
                    const _RegisterCenterLink(),
                    const SizedBox(height: 24),
                    const AppVersionFooter(),
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

/// The way out for somebody who does not have a centre yet.
///
/// The application opens on a sign-in screen and offers no registration, on
/// purpose: a centre is entered by invitation. But somebody who heard about
/// Araguaney, installed this and has no centre yet ran into a form that
/// explained nothing. This does not solve it inside the application — it takes
/// them where it is solved.
///
/// **The form is not brought here, and it is not laziness.** It sits behind the
/// browser's anti-abuse check, and rebuilding it natively would mean putting
/// that check into an embedded view, where it is worth less, with its
/// configuration inside the binary. Besides, the procedure ends in an email
/// with a link to the web, like the password recovery: closing it here would
/// require App Links and an `assetlinks.json` served from the domain, which is
/// a change in the other repository.
///
/// **The destination does follow the phone, even though the interface does
/// not.** This application's texts are in Spanish because that is the language
/// a centre is operated in; whoever taps this link does not operate one yet,
/// and the public page really does exist in both languages. Sending them to the
/// Spanish form with the phone in English would lose something in exchange for
/// nothing.
class _RegisterCenterLink extends ConsumerWidget {
  const _RegisterCenterLink();

  /// Spanish is the web's default language and goes with no prefix; English
  /// carries a prefix **and another slug**, not a translation of the same one.
  ///
  /// The base comes from `AppConfig` and is not written here: it is the same
  /// one that draws a box's QR, and a build pointing somewhere else — a fork,
  /// or the development environment — has to send people to its own web and not
  /// to this one.
  static String _formUrl(String languageCode) {
    final base = AppConfig.webBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return languageCode == 'en'
        ? '$base/en/register-center'
        : '$base/registrar-centro';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The phone's language, not the application's: `MaterialApp` pins
    // `Locale('es')`, so asking `Localizations` would always answer the same.
    final phone = View.of(context).platformDispatcher.locale;
    final url = _formUrl(phone.languageCode);

    return TextButton(
      onPressed: () async {
        // The only link in the application that opens inside. It is a public
        // page, it asks for no password, and whoever taps it stays on the
        // sign-in screen: the back button brings them here instead of leaving
        // the application in the background.
        final opened = await ref.read(openLinkProvider)(
          url,
          target: LinkTarget.inAppBrowser,
        );
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.browserOpenFailed)),
          );
        }
      },
      child: Text(context.l10n.loginRegisterCenter),
    );
  }
}

/// The tree, arriving.
///
/// **The animation exists because of a seam, not as decoration.** The system
/// splash draws this same tree while the process starts, and Flutter's first
/// frame replaces it with a form. With nothing in between, the cut shows. A
/// short entrance turns two screens into one arrival.
///
/// Three things it must not cost:
///
/// - **It does not delay the form.** Whoever arrives here lost their session,
///   sometimes mid-shift. This wraps what is drawn: the fields respond from the
///   first frame and nothing waits for the tween to finish.
/// - **It does not repeat.** A moving logo on the screen where a password is
///   typed is something to look away from.
/// - **It obeys the system's settings.** With animations turned off the final
///   state is drawn and that is that. Motion sensitivity is not a preference a
///   brand gets to override.
class _ArrivingMark extends StatefulWidget {
  const _ArrivingMark();

  /// Eighty points: `ic_mark_lg.png` measures 320 × 288, so even a 3.5× screen
  /// draws it without stretching.
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
    // Started here and not in `initState` because the decision depends on the
    // `MediaQuery`, which does not exist there yet.
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
        // It rises an eighth of its height: just enough to read as arriving,
        // not as sliding in from off screen.
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(entrance),
        child: Image.asset(
          'assets/icon/ic_mark_lg.png',
          height: _ArrivingMark._height,
          // Height decides, as in the home header: the tree is wider than it is
          // tall.
          fit: BoxFit.fitHeight,
          filterQuality: FilterQuality.medium,
          semanticLabel: context.l10n.appTitle,
        ),
      ),
    );
  }
}

/// A session error notice. It lives here because the three screens of this
/// feature share it and nobody else needs it yet.
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

/// Reusable by the other session screens.
class SessionFailureBanner extends StatelessWidget {
  const SessionFailureBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => _FailureBanner(message: message);
}
