/// Nombre en español de un estado de caja.
///
/// Es traducción de la interfaz, no interpretación: aquí no se decide qué puede
/// hacerse con una caja según su estado. Un estado que el backend agregue
/// después se muestra tal cual en vez de desaparecer de la pantalla.
String boxStatusLabel(String status) => switch (status) {
  'open' => 'Abierta',
  'sealed' => 'Sellada',
  'palletized' => 'En tarima',
  'shipped' => 'Enviada',
  'received' => 'Recibida',
  'rejected' => 'Rechazada',
  _ => status,
};
