import 'package:araguaney_app/core/api/api_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String messageFor(int status, String code, String serverMessage) =>
      ApiErrorMapper.fromResponse(status, {
        'error': {'code': code, 'message': serverMessage, 'field': null},
      }).operatorMessage;

  group('a refusal that does not name a rule', () {
    test('a plain forbidden says nothing about the check it failed', () {
      // El mensaje del servidor describe la comprobación, no el remedio, y a
      // veces está en inglés.
      expect(
        messageFor(
          403,
          'FORBIDDEN',
          'You can only invite users to your own '
              'center',
        ),
        'No tienes permiso para hacer esta operación.',
      );
    });

    test('a named refusal this version does not know stays generic', () {
      // El contrato es aditivo: un binario viejo no puede adivinar si lo que
      // llegó es apto para leerse.
      expect(
        messageFor(403, 'BRAND_NEW_RULE', 'Something the server explains'),
        'No tienes permiso para hacer esta operación.',
      );
    });
  });

  group('a refusal the backend named', () {
    test('resolving your own review explains what to do instead', () {
      // Es la única salida que le queda a esa persona, y callarla convierte
      // una explicación en un muro.
      expect(
        messageFor(
          403,
          'SELF_REVIEW',
          'No puedes resolver una revisión que '
              'abriste tú.',
        ),
        contains('Escala a la coordinación nacional'),
      );
    });

    test('capturing outside your campaigns says how to fix it', () {
      expect(
        messageFor(
          403,
          'NOT_CAMPAIGN_MEMBER',
          'User is not assigned to this '
              'campaign',
        ),
        contains('Pide que te sumen'),
      );
    });

    test('a disabled account reads the same at 400 and at 403', () {
      // El backend usa ese código en los dos sitios; para quien lo lee es el
      // mismo hecho.
      const disabled = 'Esa cuenta está desactivada.';
      expect(
        messageFor(403, 'ACCOUNT_DISABLED', 'Account is disabled'),
        disabled,
      );
      expect(
        messageFor(
          400,
          'ACCOUNT_DISABLED',
          'Cannot reinvite a disabled account',
        ),
        disabled,
      );
    });
  });

  group('business rules keep speaking with the server words', () {
    test('a rule without own copy shows what the server said', () {
      expect(
        messageFor(422, 'EXPIRY_TOO_SOON', 'Caduca en menos de 90 días'),
        'Caduca en menos de 90 días',
      );
    });

    test('a rule answered in English is written in Spanish', () {
      expect(
        messageFor(400, 'EMAIL_TAKEN', 'Email already registered'),
        'Ese correo ya tiene una cuenta.',
      );
    });
  });

  group('the other kinds of failure are untouched', () {
    test('technical failures stay generic even with a named code', () {
      expect(
        messageFor(500, 'SELF_REVIEW', 'lo que sea'),
        'El servidor tuvo un problema. Inténtalo de nuevo en un momento.',
      );
      expect(
        messageFor(404, 'NOT_CAMPAIGN_MEMBER', 'lo que sea'),
        'No encontramos lo que buscabas.',
      );
    });
  });
}
