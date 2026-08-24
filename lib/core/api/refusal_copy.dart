/// Copia propia para rechazos que el backend nombra con un código.
///
/// Existe por dos motivos distintos que dan el mismo resultado:
///
/// 1. **Un rechazo con nombre describe una regla que la persona puede
///    resolver.** El backend usa `FORBIDDEN` como código genérico para «no te
///    toca», y códigos propios —`SELF_REVIEW`, `NOT_CAMPAIGN_MEMBER`— cuando el
///    motivo es una regla concreta. El código es la señal: si el servidor se
///    tomó el trabajo de nombrarla, hay algo que hacer con esa información.
/// 2. **Varios de esos mensajes están en inglés** y quien opera lee en español.
///
/// Es copia de presentación para códigos nombrados, no una segunda copia de la
/// regla: aquí no se decide nada, solo se dice. Un código que no esté en esta
/// tabla no se inventa —ver `ApiFailure.operatorMessage` para qué se muestra
/// entonces— y la tabla no debería crecer mucho: si lo hace, lo correcto es que
/// los mensajes vengan del backend en español, que es la petición 6 de
/// `docs/backend-requests.md`.
const _refusalCopy = {
  // Permisos con nombre propio (403).
  'SELF_REVIEW':
      'No puedes resolver una revisión que abriste tú. Escala a la '
      'coordinación nacional.',
  'NOT_CAMPAIGN_MEMBER':
      'No participas en esa campaña. Pide que te sumen para poder capturar '
      'en ella.',
  'ACCOUNT_DISABLED': 'Esa cuenta está desactivada.',
  'EMAIL_NOT_VERIFIED': 'Tienes que verificar tu correo antes de operar.',

  // Lo que se lee al iniciar sesión (401, 429).
  //
  // Sin la primera, escribir mal una contraseña respondía «Tu sesión expiró»
  // en la pantalla donde todavía no hay sesión ninguna. La segunda no arregla
  // un fallo sino una imprecisión: una cuenta bloqueada por intentos fallidos
  // caía en el texto de límite de peticiones, que describe otra cosa.
  //
  // Ninguna de las dos dice cuántos intentos ni cuántos minutos: ese es un
  // parámetro de un control del servidor y no se publica desde aquí. El
  // servidor sí manda el tiempo restante en su propio mensaje, y quien lo
  // necesite lo tiene ahí.
  'INVALID_CREDENTIALS': 'El correo o la contraseña no coinciden.',
  'ACCOUNT_LOCKED':
      'Demasiados intentos fallidos. Espera un momento antes de volver a '
      'intentarlo.',

  // Reglas de negocio que el servidor contesta en inglés (400, 409, 422).
  'EMAIL_TAKEN': 'Ese correo ya tiene una cuenta.',
  'USERNAME_TAKEN': 'Ese nombre de usuario ya está tomado.',
  'INVALID_ROLE': 'El rol tiene que ser coordinación o voluntariado.',
  'PROTECTED_CAMPAIGN':
      'De la campaña general no se puede sacar a nadie: es donde entra todo '
      'lo que no pertenece a otra campaña.',
};

/// La copia propia para [code], si esta versión la conoce.
String? refusalCopyFor(String code) => _refusalCopy[code];
