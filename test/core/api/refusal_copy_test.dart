import 'package:araguaney_app/core/api/api_error_mapper.dart';
import 'package:araguaney_app/core/api/api_failure.dart';
import 'package:araguaney_app/core/api/refusal_copy.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/l10n.dart';

void main() {
  String messageFor(
    AppLocalizations l10n,
    int status,
    String code,
    String serverMessage,
  ) => ApiErrorMapper.fromResponse(status, {
    'error': {'code': code, 'message': serverMessage, 'field': null},
  }).operatorMessage(l10n);

  group('a refusal that does not name a rule', () {
    test('a plain forbidden says nothing about the check it failed', () async {
      final l10n = await spanish();
      // The server's message describes the check, not the remedy, and it is
      // sometimes in English.
      expect(
        messageFor(
          l10n,
          403,
          'FORBIDDEN',
          'You can only invite users to your own '
              'center',
        ),
        'No tienes permiso para hacer esta operación.',
      );
    });

    test('a named refusal this version does not know stays generic', () async {
      final l10n = await spanish();
      // The contract is additive: an old binary cannot guess whether what
      // arrived is fit to be read.
      expect(
        messageFor(
          l10n,
          403,
          'BRAND_NEW_RULE',
          'Something the server explains',
        ),
        'No tienes permiso para hacer esta operación.',
      );
    });
  });

  group('a refusal the backend named', () {
    test('resolving your own review explains what to do instead', () async {
      final l10n = await spanish();
      // It is the only way out left to that person, and staying quiet about it
      // turns an explanation into a wall.
      expect(
        messageFor(
          l10n,
          403,
          'SELF_REVIEW',
          'No puedes resolver una revisión que '
              'abriste tú.',
        ),
        contains('Escala a la coordinación nacional'),
      );
    });

    test('capturing outside your campaigns says how to fix it', () async {
      final l10n = await spanish();
      expect(
        messageFor(
          l10n,
          403,
          'NOT_CAMPAIGN_MEMBER',
          'User is not assigned to this '
              'campaign',
        ),
        contains('Pide que te sumen'),
      );
    });

    test('a disabled account reads the same at 400 and at 403', () async {
      final l10n = await spanish();
      // The backend uses that code in both places; for whoever reads it, it is
      // the same fact.
      const disabled = 'Esa cuenta está desactivada.';
      expect(
        messageFor(l10n, 403, 'ACCOUNT_DISABLED', 'Account is disabled'),
        disabled,
      );
      expect(
        messageFor(
          l10n,
          400,
          'ACCOUNT_DISABLED',
          'Cannot reinvite a disabled account',
        ),
        disabled,
      );
    });
  });

  group('business rules keep speaking with the server words', () {
    test('a rule without own copy shows what the server said', () async {
      final l10n = await spanish();
      expect(
        messageFor(l10n, 422, 'EXPIRY_TOO_SOON', 'Caduca en menos de 90 días'),
        'Caduca en menos de 90 días',
      );
    });

    test('a rule answered in English is written in Spanish', () async {
      final l10n = await spanish();
      expect(
        messageFor(l10n, 400, 'EMAIL_TAKEN', 'Email already registered'),
        'Ese correo ya tiene una cuenta.',
      );
    });

    test('a stale cached product type says what to do about it', () async {
      final l10n = await spanish();
      // Answered as 400, not 404: it is a reference inside the request body,
      // not a URL resource, so it gets the same named-code treatment as the
      // rest of this group instead of the dead-end NotFoundFailure below.
      expect(
        messageFor(
          l10n,
          400,
          'PRODUCT_TYPE_NOT_FOUND',
          'No existe el tipo de producto abc-123',
        ),
        contains('Actualízalo'),
      );
    });
  });

  group('the other kinds of failure are untouched', () {
    test('technical failures stay generic even with a named code', () async {
      final l10n = await spanish();
      expect(
        messageFor(l10n, 500, 'SELF_REVIEW', 'lo que sea'),
        'El servidor tuvo un problema. Inténtalo de nuevo en un momento.',
      );
      expect(
        messageFor(l10n, 404, 'NOT_CAMPAIGN_MEMBER', 'lo que sea'),
        'No encontramos lo que buscabas.',
      );
    });
  });

  group('what is read while signing in', () {
    test('wrong credentials do not claim a session expired', () async {
      final l10n = await spanish();
      // The 401 covers two moments: a session that expired, and credentials
      // that do not match on the screen where there is no session yet. Saying
      // «your session expired» in the second describes something that did not
      // happen.
      const failure = UnauthorizedFailure(
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid credentials',
      );

      expect(
        failure.operatorMessage(l10n),
        'El correo o la contraseña no coinciden.',
      );
    });

    test('an expired session still says so', () async {
      final l10n = await spanish();
      const failure = UnauthorizedFailure(
        code: 'UNAUTHORIZED',
        message: 'Not authenticated',
      );

      expect(failure.operatorMessage(l10n), contains('sesión expiró'));
    });

    test('a locked account is not described as too many requests', () async {
      final l10n = await spanish();
      // It arrives with 429 just like a request limit, and they are two
      // different things: only the code separates them.
      const failure = RateLimitFailure(
        code: 'ACCOUNT_LOCKED',
        message: 'Too many failed attempts.',
      );

      expect(failure.operatorMessage(l10n), contains('intentos fallidos'));
      expect(failure.isRetryable, isTrue);
    });

    test('a plain rate limit keeps its own words', () async {
      final l10n = await spanish();
      const failure = RateLimitFailure(
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Too many requests',
      );

      expect(failure.operatorMessage(l10n), contains('peticiones seguidas'));
    });

    test('neither message publishes a threshold or a window', () async {
      final l10n = await spanish();
      // The repository's rule: the mechanism is published, never the value that
      // decides when it fires.
      for (final code in ['INVALID_CREDENTIALS', 'ACCOUNT_LOCKED']) {
        expect(refusalCopyFor(l10n, code), isNotNull);
        expect(refusalCopyFor(l10n, code), isNot(matches(RegExp(r'\d'))));
      }
    });
  });
}
