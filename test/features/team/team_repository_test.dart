import 'package:araguaney_app/core/api/api_failure.dart';
import 'package:araguaney_app/core/api/generated/clients/campaigns_api.dart';
import 'package:araguaney_app/core/api/generated/clients/users_api.dart';
import 'package:araguaney_app/features/team/data/team_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';
import '../../support/l10n.dart';

void main() {
  TeamRepository repositoryOn(FakeHttpAdapter adapter) {
    final dio = fakeDio(adapter);
    return TeamRepository(campaigns: CampaignsApi(dio), users: UsersApi(dio));
  }

  TeamRepository refusing(int status, String code, String message) =>
      repositoryOn(
        FakeHttpAdapter(
          (_) => FakeResponse(status, {
            'error': {'code': code, 'message': message},
          }),
        ),
      );

  group('campaign membership', () {
    test('adding somebody sends the identifier the server expects', () async {
      final adapter = FakeHttpAdapter((_) => FakeResponse(201, {'ok': true}));

      final outcome = await repositoryOn(
        adapter,
      ).addMember(campaignId: 'campaign-1', userId: 'user-7');

      expect(outcome, isA<TeamChanged>());
      expect(adapter.requests.single.path, contains('/campaigns/campaign-1/'));
      expect(adapter.requests.single.data, {'user_id': 'user-7'});
    });

    test('removing somebody asks the server to remove them', () async {
      final adapter = FakeHttpAdapter((_) => const FakeResponse(204, null));

      final outcome = await repositoryOn(
        adapter,
      ).removeMember(campaignId: 'campaign-1', userId: 'user-7');

      expect(outcome, isA<TeamChanged>());
      expect(adapter.requests.single.method, 'DELETE');
    });

    test('the general campaign refuses in words that explain why', () async {
      // El servidor contesta en inglés y quien opera lee en español; el porqué
      // importa más que el código.
      final outcome = await refusing(
        422,
        'PROTECTED_CAMPAIGN',
        'Cannot remove members from the general campaign',
      ).removeMember(campaignId: 'campaign-1', userId: 'user-7');

      expect(
        (outcome as TeamRefused).reason.operatorMessage(await spanish()),
        contains('campaña general'),
      );
    });

    test(
      'a business refusal nobody translated shows the server words',
      () async {
        final outcome = await refusing(
          422,
          'SOMETHING_NEW',
          'Esta campaña está cerrada',
        ).addMember(campaignId: 'campaign-1', userId: 'user-7');

        expect(
          (outcome as TeamRefused).reason.operatorMessage(await spanish()),
          'Esta campaña está cerrada',
        );
      },
    );

    test('a permission refusal stays generic', () async {
      // La política de la fase 02: solo las reglas de negocio hablan con las
      // palabras del servidor.
      final outcome = await refusing(
        403,
        'FORBIDDEN',
        'You can only assign users from your own center',
      ).addMember(campaignId: 'campaign-1', userId: 'user-7');

      final refused = outcome as TeamRefused;
      expect(refused.failure, isA<ForbiddenFailure>());
      expect(
        refused.reason.operatorMessage(await spanish()),
        'No tienes permiso para hacer esta operación.',
      );
    });
  });

  group('the center team', () {
    test('the directory comes back as the server sent it', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, [
          userJson(username: 'ana'),
          userJson(id: 'user-2', username: 'beto', centerRole: 'coordinator'),
        ]),
      );

      final people = await repositoryOn(adapter).centerUsers('center-1');

      expect(people.map((person) => person.username), ['ana', 'beto']);
    });

    test('inviting says the invitation went out by email', () async {
      // La contraseña la genera el servidor y viaja por correo: si no se dice,
      // quien invita se queda esperando una clave que nunca verá.
      final adapter = FakeHttpAdapter((_) => FakeResponse(201, userJson()));

      final outcome = await repositoryOn(adapter).invite(
        centerId: 'center-1',
        email: 'ana@centro.test',
        username: 'ana',
        fullName: 'Ana Pérez',
        centerRole: 'volunteer',
      );

      expect((outcome as TeamChanged).notice, contains('correo'));
      expect(adapter.requests.single.data, {
        'email': 'ana@centro.test',
        'username': 'ana',
        'full_name': 'Ana Pérez',
        'center_role': 'volunteer',
        'country_code': null,
      });
    });

    test('a taken email is explained, not echoed in English', () async {
      final outcome =
          await refusing(400, 'EMAIL_TAKEN', 'Email already registered').invite(
            centerId: 'center-1',
            email: 'ana@centro.test',
            username: 'ana',
            centerRole: 'volunteer',
          );

      expect(
        (outcome as TeamRefused).reason.operatorMessage(await spanish()),
        contains('ya tiene una cuenta'),
      );
    });

    test('resending an access says a new one went out', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, {'message': 'ok'}),
      );

      final outcome = await repositoryOn(
        adapter,
      ).reinvite(centerId: 'center-1', userId: 'user-1');

      expect((outcome as TeamChanged).notice, contains('acceso nuevo'));
    });

    test('no signal is a failure with its own words', () async {
      final outcome = await repositoryOn(
        OfflineHttpAdapter(),
      ).reinvite(centerId: 'center-1', userId: 'user-1');

      expect(
        (outcome as TeamRefused).reason.operatorMessage(await spanish()),
        contains('No hay conexión'),
      );
    });
  });

  group('reading a role', () {
    test('the three roles read in Spanish', () {
      expect(centerRoleLabel('volunteer'), 'Voluntariado');
      expect(centerRoleLabel('coordinator'), 'Coordinación');
      expect(centerRoleLabel('national_admin'), 'Administración nacional');
    });

    test('a role this version does not know still reads', () {
      expect(centerRoleLabel('auditor'), 'auditor');
      expect(centerRoleLabel(null), 'Sin rol');
    });
  });
}
