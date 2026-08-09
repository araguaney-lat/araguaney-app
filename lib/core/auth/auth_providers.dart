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
