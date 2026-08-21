import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/auth_api.dart';
import '../../../core/api/generated/models/accept_terms_request.dart';
import '../../../core/api/generated/models/forgot_password_request.dart';
import '../../../core/api/generated/models/totp_confirm_in.dart';
import '../../../core/api/generated/models/totp_setup_out.dart';
import '../../../core/api/generated/models/user_out.dart';
import '../../../core/api/generated/models/user_profile_out.dart';
import '../../../core/api/generated/models/user_update.dart';

/// Cómo terminó una operación de la cuenta.
sealed class AccountOutcome<T> {
  const AccountOutcome();
}

final class AccountDone<T> extends AccountOutcome<T> {
  const AccountDone(this.value);

  final T value;
}

final class AccountRefused<T> extends AccountOutcome<T> {
  const AccountRefused(this.failure);

  final ApiFailure failure;
}

/// La cuenta de quien usa la aplicación: quién es, su contraseña y su segundo
/// factor.
///
/// Nada de esto se cachea. Son operaciones que exigen señal por naturaleza —no
/// se cambia una contraseña sin servidor— y guardar un perfil viejo solo serviría
/// para enseñar un rol que dejó de ser cierto.
class AccountRepository {
  const AccountRepository(this._auth);

  final AuthApi _auth;

  /// Quién es y cómo está protegida su cuenta.
  ///
  /// Son dos peticiones porque son dos vistas distintas del mismo usuario:
  /// `/me/profile` trae el nombre del centro y las campañas, y `/me` es el
  /// único que dice si el segundo factor está activo.
  Future<AccountOutcome<({UserProfileOut profile, UserOut account})>>
  overview() => _run(() async {
    final results = await Future.wait([
      _auth.getMyProfileV1AuthMeProfileGet(),
      _auth.getMeV1AuthMeGet(),
    ]);
    return (
      profile: results[0] as UserProfileOut,
      account: results[1] as UserOut,
    );
  });

  Future<AccountOutcome<void>> rename(String fullName) => _run(
    () => _auth.updateMeV1AuthMePatch(body: UserUpdate(fullName: fullName)),
  );

  Future<AccountOutcome<void>> acceptTerms(String version) => _run(
    () => _auth.acceptTermsV1AuthMeAcceptTermsPost(
      body: AcceptTermsRequest(version: version),
    ),
  );

  /// Empieza a activar el segundo factor. Devuelve el secreto y su `otpauth:`,
  /// que es lo que se dibuja como QR para la aplicación de códigos.
  ///
  /// No queda activado hasta [confirmTotp]: el servidor exige demostrar que el
  /// código se genera bien antes de exigirlo al entrar. Sin ese paso, un error
  /// al copiar el secreto dejaría a la persona fuera de su propia cuenta.
  Future<AccountOutcome<TotpSetupOut>> setUpTotp() =>
      _run(() => _auth.totpSetupV1AuthTotpSetupPost());

  /// Confirma el segundo factor. Devuelve los códigos de respaldo, y es la
  /// **única** vez que el servidor los entrega.
  Future<AccountOutcome<List<String>>> confirmTotp(String code) => _run(
    () async => (await _auth.totpConfirmV1AuthTotpConfirmPost(
      body: TotpConfirmIn(code: code),
    )).backupCodes,
  );

  Future<AccountOutcome<void>> disableTotp(String code) => _run(
    () =>
        _auth.totpDisableV1AuthTotpDisablePost(body: TotpConfirmIn(code: code)),
  );

  /// Pide el correo de recuperación.
  ///
  /// El servidor contesta lo mismo exista o no la cuenta, a propósito: decir
  /// «ese correo no está registrado» convierte esta pantalla en una forma de
  /// averiguar quién tiene cuenta. La interfaz repite esa respuesta neutra y no
  /// intenta ser más útil de lo que el servidor quiere ser.
  Future<AccountOutcome<void>> requestPasswordReset(String email) => _run(
    () => _auth.forgotPasswordV1AuthForgotPasswordPost(
      body: ForgotPasswordRequest(email: email),
    ),
  );

  Future<AccountOutcome<T>> _run<T>(Future<T> Function() call) async {
    try {
      return AccountDone(await call());
    } on Object catch (error) {
      return AccountRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
