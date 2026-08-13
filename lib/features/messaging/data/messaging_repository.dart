import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/messages_api.dart';
import '../../../core/api/generated/models/reply_create.dart';
import '../../../core/api/generated/models/thread_create.dart';
import '../../../core/api/generated/models/thread_detail_out.dart';
import '../../../core/api/generated/models/thread_out.dart';

/// Las dos clases de hilo que reconoce el backend.
///
/// Un hilo `PUBLIC` lo lee cualquier miembro de la campaña; uno `PRIVATE`, solo
/// sus participantes. Quién puede ver qué lo decide el servidor en cada
/// petición: aquí el tipo sirve para etiquetar y para elegir qué se crea.
abstract final class ThreadType {
  static const public = 'PUBLIC';
  static const private = 'PRIVATE';
}

String threadTypeLabel(String type) => switch (type) {
  ThreadType.public => 'De la campaña',
  ThreadType.private => 'Privado',
  _ => type,
};

sealed class MessagingOutcome<T> {
  const MessagingOutcome();
}

final class MessagingDone<T> extends MessagingOutcome<T> {
  const MessagingDone(this.value);

  final T value;
}

final class MessagingRefused<T> extends MessagingOutcome<T> {
  const MessagingRefused(this.failure);

  final ApiFailure failure;
}

/// Mensajes de la plataforma.
///
/// Se consultan en línea y no se cachean: un hilo es una conversación, y una
/// copia vieja de una conversación es peor que no tenerla — invita a responder
/// a algo que ya se contestó.
///
/// Los adjuntos no están aquí. Subirlos exige una URL prefirmada, un selector
/// de archivos y almacenamiento configurado; lo que sí llega es el texto, que
/// es lo que se lee y se contesta desde un teléfono.
class MessagingRepository {
  MessagingRepository(this._messages);

  final MessagesApi _messages;

  Future<List<ThreadOut>> threads() => _messages.listThreadsV1MessagesGet();

  Future<ThreadDetailOut> thread(String threadId) =>
      _messages.getThreadV1MessagesThreadIdGet(threadId: threadId);

  /// Mensajes privados sin leer. Es lo que pinta el contador.
  Future<int> unreadCount() async =>
      (await _messages.getUnreadCountV1MessagesUnreadCountGet()).unread;

  /// Marca el hilo como leído.
  ///
  /// Nunca lanza: abrir un hilo tiene que funcionar aunque el acuse falle, y
  /// que el contador tarde un rato más en bajar no se lo estropea a nadie.
  Future<void> markRead(String threadId) async {
    try {
      await _messages.markReadV1MessagesThreadIdReadPatch(threadId: threadId);
    } on Object {
      // Se reintenta la próxima vez que se abra.
    }
  }

  Future<MessagingOutcome<void>> reply({
    required String threadId,
    required String body,
  }) => _guard(
    () => _messages.addReplyV1MessagesThreadIdRepliesPost(
      threadId: threadId,
      body: ReplyCreate(body: body),
    ),
  );

  /// Abre un hilo de campaña.
  ///
  /// Solo `PUBLIC`: un hilo privado exige elegir destinatarios de entre quienes
  /// participan en la campaña, y esa selección es trabajo de escritorio. El
  /// servidor exige además ser miembro de la campaña, y lo sigue decidiendo él.
  Future<MessagingOutcome<ThreadOut>> openCampaignThread({
    required String campaignId,
    required String title,
    required String body,
  }) => _guard(
    () => _messages.createThreadV1MessagesPost(
      body: ThreadCreate(
        campaignId: campaignId,
        title: title,
        body: body,
        threadType: ThreadType.public,
      ),
    ),
  );

  Future<MessagingOutcome<T>> _guard<T>(Future<T> Function() attempt) async {
    try {
      return MessagingDone(await attempt());
    } on Object catch (error) {
      return MessagingRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
