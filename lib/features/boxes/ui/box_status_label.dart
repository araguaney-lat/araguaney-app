/// Nombre en español de un estado de caja.
///
/// Es traducción de la interfaz, no interpretación: aquí no se decide qué puede
/// hacerse con una caja según su estado. Un estado que el backend agregue
/// después se muestra tal cual en vez de desaparecer de la pantalla.
///
/// Los cuatro valores son los de `BOX_STATUSES` en el backend. La primera
/// versión de esta tabla usaba minúsculas —`open`, `sealed`— y dos estados que
/// no existen, así que **no tradujo nada nunca**: el respaldo devolvía la clave
/// cruda y la pantalla enseñaba «SEALED» a quien lee español. Se descubrió
/// mirando la aplicación contra producción, no leyendo el código.
String boxStatusLabel(String status) => switch (status) {
  'DRAFT' => 'Sin sellar',
  'SEALED' => 'Sellada',
  'SHIPPED' => 'Enviada',
  'REJECTED' => 'Rechazada',
  _ => status,
};
