import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dio_client.dart';
import 'auth_interceptor.dart';
import 'auth_repository.dart';
import 'session.dart';
import 'session_controller.dart';
import 'token_storage.dart';

/// The installed version of the application. It is overridden at start-up with
/// the package's real value; it exists as a provider so tests do not need
/// platform channels.
final appVersionProvider = Provider<String>(
  (ref) => throw UnimplementedError('appVersionProvider must be overridden'),
);

/// The build number (the `+3` of `1.0.0+3`).
///
/// Separate from the version because the name repeats across releases and this
/// is what identifies a binary. It does not travel in the user agent; it is
/// shown at the foot of the sign-in screen so that asking «which version do you
/// have» does not cost a conversation.
final appBuildNumberProvider = Provider<String>((ref) => '');

/// The package identifier, for opening its page in the store.
final appPackageNameProvider = Provider<String>(
  (ref) =>
      throw UnimplementedError('appPackageNameProvider must be overridden'),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

/// The client without a session, for the authentication endpoints and for
/// retrying.
///
/// It is deliberately separate from the client with a session: if the renewal
/// travelled through the same client that carries the interceptor, a 401 during
/// a renewal would fire another renewal.
final authDioProvider = Provider<Dio>(
  (ref) => DioClient.create(appVersion: ref.watch(appVersionProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(authDioProvider)),
);

/// Whether whoever has the session coordinates a centre.
///
/// The backend requires that role for the writes that touch shared state —
/// pallets, incidents — and **it is still the one that decides**: this only
/// avoids offering a button that will answer 403. It lives in `core` because
/// two features already ask, and two copies of the same condition end up
/// diverging.
final isCenterCoordinatorProvider = Provider<bool>((ref) {
  final state = ref.watch(sessionControllerProvider);
  if (state is! SessionActive) return false;
  return const {
    'coordinator',
    'national_admin',
  }.contains(state.session.centerRole);
});

/// Who has the session open.
///
/// It is the key to everything the device keeps per person: the capture queue,
/// the reserved codes and the working centre. It lives in `core` because a
/// shared device divides all three by the same criterion.
final sessionUserIdProvider = Provider<String?>((ref) {
  final state = ref.watch(sessionControllerProvider);
  return state is SessionActive ? state.session.userId : null;
});

/// The centre of whoever has the session.
///
/// It decides whether a transfer is leaving or arriving, and which directory is
/// being talked about, so two features already ask. It is null for a national
/// administration, which belongs to no centre.
final myCenterIdProvider = Provider<String?>((ref) {
  final state = ref.watch(sessionControllerProvider);
  return state is SessionActive ? state.session.centerId : null;
});

/// Whether whoever has the session is national administration.
///
/// It changes what the aggregates mean — their centre, or all of them — and
/// what can be written. It lives in `core` because two features already ask.
final isNationalAdminProvider = Provider<bool>((ref) {
  final state = ref.watch(sessionControllerProvider);
  return state is SessionActive && state.session.centerRole == 'national_admin';
});

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

/// The client with a session: the one the rest of the application uses.
final apiDioProvider = Provider<Dio>((ref) {
  final controller = ref.read(sessionControllerProvider.notifier);
  return DioClient.create(
    appVersion: ref.watch(appVersionProvider),
    interceptors: [
      AuthInterceptor(
        readAccessToken: () => controller.accessToken,
        refreshSession: controller.renew,
        onSessionExpired: controller.expire,
        retryClient: ref.watch(authDioProvider),
      ),
    ],
  );
});
