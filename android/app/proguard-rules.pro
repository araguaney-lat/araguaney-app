# Reglas de conservación para el build de release con R8.
#
# La regla general de este archivo: solo se conserva lo que se rompe por
# reflexión, y cada bloque dice qué se rompería. Una lista de `-keep` sin
# explicación crece hasta anular el shrinker.

# --- Flutter y sus canales de plataforma -------------------------------------
# El motor busca estas clases por nombre desde código nativo.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# El embedding referencia la API de componentes diferidos de Play Core. Esta
# aplicación no publica ningún componente diferido, así que esas clases no están
# en el classpath y R8 solo necesita que se le diga que no las espere. Sin esta
# línea el build de release falla con una lista de clases ausentes que no falta
# ninguna.
-dontwarn com.google.android.play.core.**

# --- sqlite3 (Drift) ----------------------------------------------------------
# La biblioteca nativa se resuelve por JNI; renombrarla deja la base local sin
# abrir, que en esta aplicación significa quedarse sin catálogo y sin cola.
-keep class com.tekartik.sqflite.** { *; }
-keep class org.sqlite.** { *; }

# --- flutter_secure_storage ---------------------------------------------------
# El almacén cifrado usa las clases de seguridad de AndroidX por reflexión. Sin
# esto, el refresh token deja de poder leerse tras actualizar y la sesión se
# pierde en cada arranque.
-keep class androidx.security.crypto.** { *; }
-keep class com.google.crypto.tink.** { *; }

# --- mobile_scanner -----------------------------------------------------------
# ML Kit carga sus detectores dinámicamente.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-dontwarn com.google.mlkit.**

# --- Modelos serializados -----------------------------------------------------
# El cliente generado usa json_serializable, que **no** usa reflexión: el código
# de (de)serialización se genera en Dart y R8 no lo toca. No hace falta ninguna
# regla para los modelos de la API, y añadirla por costumbre solo agrandaría el
# binario.

# --- Ruido de dependencias transitivas ---------------------------------------
# Anotaciones que no existen en tiempo de ejecución.
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
