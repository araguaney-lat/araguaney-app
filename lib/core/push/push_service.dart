import 'push_destination.dart';

/// What the person using the phone has decided about receiving notices.
enum PushPermission {
  /// Granted: notices are shown.
  granted,

  /// Denied. The application does not ask again; it is changed in the system
  /// settings.
  denied,

  /// Nobody has been asked yet.
  notDetermined,

  /// There is nobody to ask: this build does not deliver notices. That is the
  /// `foss` flavour's case.
  unavailable,
}

/// The only door Firebase comes through.
///
/// Everything the application needs from notices fits in these few members, and
/// none of them mentions FCM. That is why it exists: the `foss` flavour builds
/// with [NoopPushService] and not one proprietary dependency, and the rest of
/// the code cannot tell one flavour from the other.
abstract interface class PushService {
  /// Starts the service. Idempotent: calling it twice does not duplicate
  /// subscriptions.
  Future<void> start();

  /// This device's address, or null when there is not one yet — no permission,
  /// no Google services, or the `foss` flavour.
  Future<String?> currentToken();

  /// New addresses. FCM rotates the token on its own, and every rotation
  /// leaves the previous one dead: whoever listens has to register the new
  /// one.
  Stream<String> get onTokenRotated;

  /// Notices somebody tapped, already interpreted.
  Stream<PushDestination> get onOpened;

  /// What has already been decided, without asking anything.
  Future<PushPermission> permission();

  /// Asks the system for the permission. Returns what was decided.
  Future<PushPermission> requestPermission();
}

/// The implementation that does nothing.
///
/// It is the `foss` flavour's, and also that of any build without Firebase
/// configured. It is not a placeholder: it is the correct behaviour when there
/// is nowhere to deliver notices, and the rest of the application works the
/// same.
class NoopPushService implements PushService {
  const NoopPushService();

  @override
  Future<void> start() async {}

  @override
  Future<String?> currentToken() async => null;

  @override
  Stream<String> get onTokenRotated => const Stream.empty();

  @override
  Stream<PushDestination> get onOpened => const Stream.empty();

  /// There is no permission to ask for because there are no notices to
  /// deliver. Saying «denied» would suggest somebody denied it.
  @override
  Future<PushPermission> permission() async => PushPermission.unavailable;

  @override
  Future<PushPermission> requestPermission() async =>
      PushPermission.unavailable;
}
