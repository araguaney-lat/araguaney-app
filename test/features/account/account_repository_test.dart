import 'package:araguaney_app/core/api/generated/clients/auth_api.dart';
import 'package:araguaney_app/core/api/generated/models/totp_setup_out.dart';
import 'package:araguaney_app/core/api/generated/models/user_out.dart';
import 'package:araguaney_app/core/api/generated/models/user_profile_out.dart';
import 'package:araguaney_app/features/account/data/account_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/l10n.dart';

void main() async {
  AccountRepository on(FakeHttpAdapter adapter) =>
      AccountRepository(AuthApi(fakeDio(adapter)));

  test(
    'asking for a reset says the same thing whether the account exists',
    () async {
      // The server answers neutrally on purpose: telling them apart would turn
      // this screen into a way of finding out who has an account. The
      // repository does not interpret that answer, it only lets it through.
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
    // The server hands over a secret and waits for proof that it was copied
    // correctly. Without that step, a badly scanned secret would leave somebody
    // out of their own account.
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
    final l10n = await spanish();

    expect(
      outcome,
      isA<AccountRefused<List<String>>>().having(
        (o) => o.failure.operatorMessage(l10n),
        'message',
        'Código incorrecto',
      ),
    );
  });

  test('disabling the second factor also demands a code', () async {
    // It is what stops whoever finds an unlocked phone removing the second
    // barrier before walking away with the account.
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(200, {'message': 'ok'}),
    );

    await on(adapter).disableTotp('654321');

    final body = adapter.requests.single.data as Map<String, dynamic>;
    expect(body['code'], '654321');
  });

  test('the overview asks for both views of the same user', () async {
    // `/me/profile` brings the centre's name; `/me` is the only one that says
    // whether the second factor is on.
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
