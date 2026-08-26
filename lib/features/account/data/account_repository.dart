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

/// How an account operation ended.
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

/// The account of whoever uses the application: who they are, their password
/// and their second factor.
///
/// None of this is cached. They are operations that require signal by nature —
/// a password is not changed without a server — and storing an old profile
/// would only serve to show a role that stopped being true.
class AccountRepository {
  const AccountRepository(this._auth);

  final AuthApi _auth;

  /// Who they are and how their account is protected.
  ///
  /// They are two requests because they are two different views of the same
  /// user: `/me/profile` brings the centre's name and the campaigns, and `/me`
  /// is the only one that says whether the second factor is on.
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

  /// Starts turning the second factor on. It returns the secret and its
  /// `otpauth:`, which is what gets drawn as a QR for the code application.
  ///
  /// It is not on until [confirmTotp]: the server requires proof that the code
  /// is generated correctly before requiring it on the way in. Without that
  /// step, a mistake copying the secret would leave the person out of their own
  /// account.
  Future<AccountOutcome<TotpSetupOut>> setUpTotp() =>
      _run(() => _auth.totpSetupV1AuthTotpSetupPost());

  /// Confirms the second factor. It returns the backup codes, and it is the
  /// **only** time the server hands them over.
  Future<AccountOutcome<List<String>>> confirmTotp(String code) => _run(
    () async => (await _auth.totpConfirmV1AuthTotpConfirmPost(
      body: TotpConfirmIn(code: code),
    )).backupCodes,
  );

  Future<AccountOutcome<void>> disableTotp(String code) => _run(
    () =>
        _auth.totpDisableV1AuthTotpDisablePost(body: TotpConfirmIn(code: code)),
  );

  /// Asks for the recovery email.
  ///
  /// The server answers the same whether or not the account exists, on purpose:
  /// saying «that address is not registered» turns this screen into a way of
  /// finding out who has an account. The interface repeats that neutral answer
  /// and does not try to be more helpful than the server wants to be.
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
