package org.araguaney.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

/**
 * El canal se crea aquí, en el arranque, y no en el código Dart.
 *
 * Un aviso que llega sin canal declarado cae en el de reserva de Firebase, con
 * importancia normal: se queda en el cajón, en silencio, y quien opera se entera
 * cuando desliza la barra. Los avisos de esta aplicación —una revisión que
 * bloquea una captura, un envío que llegó— existen para interrumpir, así que el
 * canal es de importancia alta y aparece como banner.
 *
 * Declararlo también le da a quien lo recibe un interruptor propio en los
 * ajustes del sistema: puede silenciar estos avisos sin silenciar la
 * aplicación entera.
 */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        // Los canales existen desde Android 8. Por debajo, la importancia la
        // decide cada aviso y no hay nada que declarar.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            OPERATIONS_CHANNEL_ID,
            "Avisos del centro",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description =
                "Revisiones abiertas sobre capturas de este centro y envíos " +
                    "que llegaron a su destino."
        }

        getSystemService(NotificationManager::class.java)
            ?.createNotificationChannel(channel)
    }

    private companion object {
        /** Tiene que coincidir con el `meta-data` del manifiesto. */
        const val OPERATIONS_CHANNEL_ID = "araguaney_operaciones"
    }
}
