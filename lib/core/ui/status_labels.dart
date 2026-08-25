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

/// `SHIPMENT_STATUSES` en el backend.
///
/// «Abierto» y «cerrado» hablan de si admite tarimas, no de si terminó: un
/// envío cerrado todavía no salió. Por eso «despachado» y «entregado» son
/// estados distintos, y «conciliado» es el final de verdad, cuando lo recibido
/// se cuadró con lo enviado.
String shipmentStatusLabel(String status) => switch (status) {
  'OPEN' => 'Abierto',
  'CLOSED' => 'Cerrado',
  'SHIPPED' => 'Despachado',
  'DELIVERED' => 'Entregado',
  'RECONCILED' => 'Conciliado',
  _ => status,
};

/// `TRANSFER_STATUSES` en el backend. Vivía dentro de la función de
/// transferencias, que es exactamente cómo las otras cuatro acabaron
/// enseñando la clave del servidor en las pantallas que no la importaban.
String transferStatusLabel(String status) => switch (status) {
  'REQUESTED' => 'Solicitada',
  'APPROVED' => 'Aprobada',
  'IN_TRANSIT' => 'En tránsito',
  'RECEIVED' => 'Recibida',
  'REJECTED' => 'Rechazada',
  _ => status,
};

/// El estado de una revisión de riesgo. `PENDING` es el que espera una
/// decisión; los otros dos ya la llevan.
String reviewStatusLabel(String status) => switch (status) {
  'PENDING' => 'Pendiente',
  'APPROVED' => 'Aprobada',
  'REJECTED' => 'Rechazada',
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

/// El estado de una incidencia. Solo dos: la abrió alguien, o alguien la
/// cerró. Vive aquí y no en la feature por la misma razón que las seis de
/// arriba —una tabla escondida en una pantalla deja a las otras enseñando el
/// idioma del backend— y esta ya se lee desde dos: la lista y la ficha de un
/// envío.
String incidentStatusLabel(String status) => switch (status) {
  'OPEN' => 'Abierta',
  'RESOLVED' => 'Resuelta',
  _ => status,
};
