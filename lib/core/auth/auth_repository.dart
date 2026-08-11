import 'package:dio/dio.dart';

import '../api/api_error_mapper.dart';
import '../api/api_failure.dart';
import '../api/generated/models/token.dart';
import '../api/generated/models/user_out.dart';

/// Resultado de un intento de inicio de sesión.
sealed class LoginResult {
  const LoginResult();
}

/// Credenciales correctas y sin segundo factor: hay sesión.
class LoginSucceeded extends LoginResult {
  const LoginSucceeded(this.token);

  final Token token;
}

/// Credenciales correctas, falta el código del segundo factor.
class LoginNeedsTotp extends LoginResult {
  const LoginNeedsTotp(this.partialToken);

  final String partialToken;
}

/// Acceso a los endpoints de sesión del backend.
///
/// Casi todo pasa por el cliente generado. El inicio de sesión no puede: el
/// backend no declara `response_model` en `POST /v1/auth/login`, así que el
/// contrato publica una respuesta sin tipo y el método generado devuelve
/// `void`, descartando el token. Mientras eso se corrige aguas arriba, la
/// petición se hace aquí a mano, pero **el cuerpo se lee con el modelo
/// generado `Token`**: la forma sigue viniendo del contrato y no de una copia
/// escrita a mano que se desincronizaría. Ver `api/README.md`.
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// La segunda respuesta posible del inicio de sesión: el backend contesta
  /// 202 con un token parcial cuando la cuenta tiene segundo factor.
  static const _totpPendingStatus = 202;

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    // El endpoint usa el formulario estándar de OAuth2, no JSON.
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/login',
      data: {'username': username.trim(), 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final body = response.data;
    if (body == null) {
      throw const UnknownFailure(
        code: 'EMPTY_LOGIN_RESPONSE',
        message: 'El servidor no devolvió una sesión',
      );
    }

    if (response.statusCode == _totpPendingStatus ||
        body['requires_totp'] == true) {
      final partial = body['partial_token'] as String?;
      if (partial == null) {
        throw const UnknownFailure(
          code: 'MISSING_PARTIAL_TOKEN',
          message: 'El servidor pidió segundo factor sin entregar el token',
        );
      }
      return LoginNeedsTotp(partial);
    }

    return LoginSucceeded(Token.fromJson(body));
  }

  Future<Token> totpChallenge({
    required String partialToken,
    required String code,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/totp/challenge',
      data: {'partial_token': partialToken, 'code': code.trim()},
    );
    return Token.fromJson(response.data!);
  }

  /// Quién es la persona detrás de este token.
  ///
  /// Va con la cabecera puesta a mano y por el cliente **sin sesión**: la
  /// identidad hay que resolverla *antes* de exponer la sesión al resto de la
  /// aplicación, y el cliente con sesión saca su token de una sesión que
  /// todavía no existe. Es el dato que decide si el cache del turno anterior se
  /// borra.
  Future<UserOut> me(String accessToken) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    return UserOut.fromJson(response.data!);
  }

  /// Renueva la sesión. El backend **rota** el refresh en cada uso, así que
  /// quien llame tiene que guardar el que viene de vuelta: el anterior queda
  /// revocado y reutilizarlo delata un robo.
  Future<Token> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return Token.fromJson(response.data!);
  }

  Future<Token> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/v1/auth/me/password',
      data: {'current_password': currentPassword, 'new_password': newPassword},
    );
    return Token.fromJson(response.data!);
  }

  /// Cierra sesión en el servidor. Nunca propaga un fallo: si la red falla, la
  /// sesión local se borra igual. Dejar a alguien dentro de la aplicación
  /// porque el servidor no contestó sería el peor resultado posible.
  Future<void> logout(String? refreshToken) async {
    try {
      await _dio.post<void>(
        '/v1/auth/logout',
        data: {'refresh_token': refreshToken},
      );
    } on DioException catch (error) {
      final failure = ApiErrorMapper.fromDioException(error);
      // Se traga a propósito: el borrado local ocurre en el controlador.
      assert(() {
        // ignore: avoid_print
        print('Logout remoto falló (${failure.code}); se cierra localmente');
        return true;
      }());
    }
  }
}
