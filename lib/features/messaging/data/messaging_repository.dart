import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/messages_api.dart';
import '../../../core/api/generated/models/reply_create.dart';
import '../../../core/api/generated/models/thread_create.dart';
import '../../../core/api/generated/models/thread_detail_out.dart';
import '../../../core/api/generated/models/thread_out.dart';
import '../../../core/i18n/generated/app_localizations.dart';

/// The two kinds of thread the backend recognises.
///
/// A `PUBLIC` thread is read by any member of the campaign; a `PRIVATE` one,
/// only by its participants. Who can see what is decided by the server on every
/// request: here the type serves to label and to choose what gets created.
abstract final class ThreadType {
  static const public = 'PUBLIC';
  static const private = 'PRIVATE';
}

String threadTypeLabel(AppLocalizations l10n, String type) => switch (type) {
  ThreadType.public => l10n.threadTypeCampaign,
  ThreadType.private => l10n.threadTypePrivate,
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

/// The platform's messages.
///
/// They are looked up online and not cached: a thread is a conversation, and an
/// old copy of a conversation is worse than not having it — it invites replying
/// to something already answered.
///
/// Attachments are not here. Uploading them requires a presigned URL, a file
/// picker and configured storage; what does arrive is the text, which is what
/// gets read and answered from a phone.
class MessagingRepository {
  MessagingRepository(this._messages);

  final MessagesApi _messages;

  Future<List<ThreadOut>> threads() => _messages.listThreadsV1MessagesGet();

  Future<ThreadDetailOut> thread(String threadId) =>
      _messages.getThreadV1MessagesThreadIdGet(threadId: threadId);

  /// Unread private messages. It is what paints the counter.
  Future<int> unreadCount() async =>
      (await _messages.getUnreadCountV1MessagesUnreadCountGet()).unread;

  /// Marks the thread as read.
  ///
  /// It never throws: opening a thread has to work even if the acknowledgement
  /// fails, and the counter taking a while longer to go down spoils nothing for
  /// anybody.
  Future<void> markRead(String threadId) async {
    try {
      await _messages.markReadV1MessagesThreadIdReadPatch(threadId: threadId);
    } on Object {
      // It is retried the next time it is opened.
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

  /// Opens a campaign thread.
  ///
  /// `PUBLIC` only: a private thread requires choosing recipients from among
  /// those taking part in the campaign, and that selection is desk work. The
  /// server also requires membership of the campaign, and it goes on deciding
  /// that.
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
