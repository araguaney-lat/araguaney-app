/// Los estados del dominio, en español.
///
/// Las tres tablas viven juntas y en `core` a propósito. La de categorías vivía
/// dentro de una pantalla, así que la única que la importaba traducía y todas
/// las demás enseñaban la clave del servidor; la de cajas empezó con valores
/// inventados y no tradujo nada durante ocho fases. El patrón es el mismo y ya
/// se pagó dos veces: **una tabla de traducción escondida en una pantalla deja
/// a las otras enseñando el idioma del backend.**
///
/// Todas son traducción de interfaz, no interpretación: aquí no se decide qué
/// puede hacerse con una caja, una tarima o una donación según su estado. Y
/// todas devuelven la clave cruda cuando no la conocen, para que un estado que
/// el backend agregue después aparezca en pantalla en vez de desaparecer de
/// ella.
library;

/// `BOX_STATUSES` en el backend.
String boxStatusLabel(String status) => switch (status) {
  'DRAFT' => 'Sin sellar',
  'SEALED' => 'Sellada',
  'SHIPPED' => 'Enviada',
  'REJECTED' => 'Rechazada',
  _ => status,
};

/// `PALLET_STATUSES` en el backend.
///
/// «Abierta» y no «en construcción»: una tarima abierta admite cajas, que es lo
/// único que cambia para quien la tiene delante.
String palletStatusLabel(String status) => switch (status) {
  'OPEN' => 'Abierta',
  'CLOSED' => 'Cerrada',
  'SHIPPED' => 'Enviada',
  _ => status,
};

/// El ciclo de una donación pre-registrada: se registra por correo, se
/// confirma, y se recibe cuando alguien la captura en un centro.
String donationStatusLabel(String status) => switch (status) {
  'PENDING_EMAIL' => 'Sin confirmar',
  'REGISTERED' => 'Registrada',
  'RECEIVED' => 'Recibida',
  'CANCELLED' => 'Cancelada',
  'EXPIRED' => 'Caducada',
  _ => status,
};
