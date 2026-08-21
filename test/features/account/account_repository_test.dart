import 'package:araguaney_app/core/api/generated/clients/auth_api.dart';
import 'package:araguaney_app/core/api/generated/models/totp_setup_out.dart';
import 'package:araguaney_app/core/api/generated/models/user_out.dart';
import 'package:araguaney_app/core/api/generated/models/user_profile_out.dart';
import 'package:araguaney_app/features/account/data/account_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';

void main() {
  AccountRepository on(FakeHttpAdapter adapter) =>
      AccountRepository(AuthApi(fakeDio(adapter)));

  test(
    'asking for a reset says the same thing whether the account exists',
    () async {
      // El servidor contesta neutro a propósito: distinguir convertiría esta
      // pantalla en una forma de averiguar quién tiene cuenta. El repositorio no
      // interpreta esa respuesta, solo la deja pasar.
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, {
          'message': 'If that email is registered, a reset link is on its way.',
        }),
      );

      final outcome = await on(
        adapter,
      ).requestPasswordReset('quien@sea.example');

      expect(outcome, isA<AccountDone<void>>());
      final body = adapter.requests.single.data as Map<String, dynamic>;
      expect(body['email'], 'quien@sea.example');
    },
  );

  test('setting up the second factor does not enable it', () async {
    // El servidor entrega un secreto y espera la prueba de que se copió bien.
    // Sin ese paso, un secreto mal escaneado dejaría a alguien fuera de su
    // propia cuenta.
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(200, {
        'secret': 'ABCDEFGH',
        'qr_uri': 'otpauth://totp/Araguaney:quien?secret=ABCDEFGH',
      }),
    );

    final outcome = await on(adapter).setUpTotp();

    expect(outcome, isA<AccountDone<TotpSetupOut>>());
    expect(adapter.requests.single.path, contains('/totp/setup'));
  });

  test('confirming returns the backup codes, which arrive once', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(200, {
        'backup_codes': ['1111-2222', '3333-4444'],
      }),
    );

    final outcome = await on(adapter).confirmTotp('123456');

    expect(
      outcome,
      isA<AccountDone<List<String>>>().having((o) => o.value, 'codes', [
        '1111-2222',
        '3333-4444',
      ]),
    );
  });

  test('a wrong code is refused with the server reason', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(422, {
        'error': {'code': 'INVALID_TOTP', 'message': 'Código incorrecto'},
      }),
    );

    final outcome = await on(adapter).confirmTotp('000000');

    expect(
      outcome,
      isA<AccountRefused<List<String>>>().having(
        (o) => o.failure.operatorMessage,
        'message',
        'Código incorrecto',
      ),
    );
  });

  test('disabling the second factor also demands a code', () async {
    // Es lo que impide que quien encuentre un teléfono desbloqueado quite la
    // segunda barrera antes de llevarse la cuenta.
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(200, {'message': 'ok'}),
    );

    await on(adapter).disableTotp('654321');

    final body = adapter.requests.single.data as Map<String, dynamic>;
    expect(body['code'], '654321');
  });

  test('the overview asks for both views of the same user', () async {
    // `/me/profile` trae el nombre del centro; `/me` es el único que dice si
    // el segundo factor está activo.
    final adapter = FakeHttpAdapter(
      (options) => FakeResponse(
        200,
        options.path.endsWith('/profile')
            ? {
                'id': 'u-1',
                'username': 'quien',
                'email': 'quien@sea.example',
                'full_name': 'Quien Sea',
                'center_id': 'c-1',
                'center_name': 'Centro Caracas',
                'center_role': 'coordinator',
                'avatar_url': null,
                'campaigns': <Object?>[],
              }
            : {
                'id': 'u-1',
                'username': 'quien',
                'email': 'quien@sea.example',
                'full_name': 'Quien Sea',
                'role': 'user',
                'is_active': true,
                'must_accept_terms': false,
                'totp_enabled': true,
                'avatar_url': null,
                'center_id': 'c-1',
                'center_role': 'coordinator',
                'country_code': null,
              },
      ),
    );

    final outcome = await on(adapter).overview();

    final done =
        outcome as AccountDone<({UserProfileOut profile, UserOut account})>;
    expect(done.value.profile.centerName, 'Centro Caracas');
    expect(done.value.account.totpEnabled, isTrue);
  });
}
