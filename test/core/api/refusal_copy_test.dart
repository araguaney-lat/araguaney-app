import 'package:araguaney_app/core/api/api_error_mapper.dart';
import 'package:araguaney_app/core/api/api_failure.dart';
import 'package:araguaney_app/core/api/refusal_copy.dart';
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

  group('what is read while signing in', () {
    test('wrong credentials do not claim a session expired', () {
      // El 401 cubre dos momentos: una sesion que caduco y unas credenciales
      // que no coinciden en la pantalla donde todavia no hay sesion. Decir
      // «tu sesion expiro» en el segundo describe algo que no ocurrio.
      const failure = UnauthorizedFailure(
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid credentials',
      );

      expect(
        failure.operatorMessage,
        'El correo o la contraseña no coinciden.',
      );
    });

    test('an expired session still says so', () {
      const failure = UnauthorizedFailure(
        code: 'UNAUTHORIZED',
        message: 'Not authenticated',
      );

      expect(failure.operatorMessage, contains('sesión expiró'));
    });

    test('a locked account is not described as too many requests', () {
      // Llega con 429 igual que un limite de peticiones, y son dos cosas
      // distintas: solo el codigo las separa.
      const failure = RateLimitFailure(
        code: 'ACCOUNT_LOCKED',
        message: 'Too many failed attempts.',
      );

      expect(failure.operatorMessage, contains('intentos fallidos'));
      expect(failure.isRetryable, isTrue);
    });

    test('a plain rate limit keeps its own words', () {
      const failure = RateLimitFailure(
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Too many requests',
      );

      expect(failure.operatorMessage, contains('peticiones seguidas'));
    });

    test('neither message publishes a threshold or a window', () {
      // La regla del repositorio: se publica el mecanismo, nunca el valor que
      // determina cuando salta.
      for (final code in ['INVALID_CREDENTIALS', 'ACCOUNT_LOCKED']) {
        expect(refusalCopyFor(code), isNotNull);
        expect(refusalCopyFor(code), isNot(matches(RegExp(r'\d'))));
      }
    });
  });
}
