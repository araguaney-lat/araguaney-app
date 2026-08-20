import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dio_client.dart';
import 'auth_interceptor.dart';
import 'auth_repository.dart';
import 'session.dart';
import 'session_controller.dart';
import 'token_storage.dart';

/// Versión instalada de la aplicación. Se sobrescribe al arrancar con el valor
/// real del paquete; existe como provider para que las pruebas no necesiten
/// canales de plataforma.
final appVersionProvider = Provider<String>(
  (ref) => throw UnimplementedError('appVersionProvider debe sobrescribirse'),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

/// Cliente sin sesión, para los endpoints de autenticación y para reintentar.
///
/// Está separado del cliente con sesión a propósito: si la renovación viajara
/// por el mismo cliente que lleva el interceptor, un 401 durante la renovación
/// dispararía otra renovación.
final authDioProvider = Provider<Dio>(
  (ref) => DioClient.create(appVersion: ref.watch(appVersionProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(authDioProvider)),
);

/// Si quien tiene la sesión coordina un centro.
///
/// El backend exige ese rol en las escrituras que tocan estado compartido
/// —tarimas, incidencias— y **sigue siendo quien decide**: esto solo evita
/// ofrecer un botón que va a responder 403. Vive en `core` porque ya son dos
/// features las que lo preguntan, y dos copias de la misma condición terminan
/// divergiendo.
final isCenterCoordinatorProvider = Provider<bool>((ref) {
  final state = ref.watch(sessionControllerProvider);
  if (state is! SessionActive) return false;
  return const {
    'coordinator',
    'national_admin',
  }.contains(state.session.centerRole);
});

/// El centro de quien tiene la sesión.
///
/// Decide si una transferencia sale o llega y de qué directorio se habla, así
/// que ya son dos features las que lo preguntan. Es nulo en una administración
/// nacional, que no pertenece a ningún centro.
final myCenterIdProvider = Provider<String?>((ref) {
  final state = ref.watch(sessionControllerProvider);
  return state is SessionActive ? state.session.centerId : null;
});

/// Si quien tiene la sesión es administración nacional.
///
/// Cambia lo que significan los agregados —su centro o todos— y qué se puede
/// escribir. Vive en `core` porque ya son dos features las que lo preguntan.
final isNationalAdminProvider = Provider<bool>((ref) {
  final state = ref.watch(sessionControllerProvider);
  return state is SessionActive && state.session.centerRole == 'national_admin';
});

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

/// Cliente con sesión: el que usa el resto de la aplicación.
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
