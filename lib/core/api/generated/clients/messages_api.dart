// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/attachment_out.dart';
import '../models/confirm_attachment_request.dart';
import '../models/reply_create.dart';
import '../models/thread_create.dart';
import '../models/thread_detail_out.dart';
import '../models/thread_out.dart';
import '../models/thread_reply_out.dart';
import '../models/upload_url_out.dart';
import '../models/upload_url_request.dart';

part 'messages_api.g.dart';

@RestApi()
abstract class MessagesApi {
  factory MessagesApi(Dio dio, {String? baseUrl}) = _MessagesApi;

  /// List Threads
  @GET('/v1/messages')
  Future<List<ThreadOut>> listThreadsV1MessagesGet({
    @Query('thread_type') String? threadType,
    @Query('campaign_id') String? campaignId,
  });

  /// Create Thread
  @POST('/v1/messages')
  Future<ThreadOut> createThreadV1MessagesPost({
    @Body() required ThreadCreate body,
  });

  /// Confirm Attachment
  @POST('/v1/messages/attachments/confirm')
  Future<AttachmentOut> confirmAttachmentV1MessagesAttachmentsConfirmPost({
    @Body() required ConfirmAttachmentRequest body,
  });

  /// Get Upload Url
  @POST('/v1/messages/attachments/upload-url')
  Future<UploadUrlOut> getUploadUrlV1MessagesAttachmentsUploadUrlPost({
    @Body() required UploadUrlRequest body,
  });

  /// Get Download Url
  @GET('/v1/messages/attachments/{attachment_id}/url')
  Future<void> getDownloadUrlV1MessagesAttachmentsAttachmentIdUrlGet({
    @Path('attachment_id') required String attachmentId,
  });

  /// Get Unread Count
  @GET('/v1/messages/unread-count')
  Future<void> getUnreadCountV1MessagesUnreadCountGet();

  /// Get Thread
  @GET('/v1/messages/{thread_id}')
  Future<ThreadDetailOut> getThreadV1MessagesThreadIdGet({
    @Path('thread_id') required String threadId,
  });

  /// Mark Read
  @PATCH('/v1/messages/{thread_id}/read')
  Future<void> markReadV1MessagesThreadIdReadPatch({
    @Path('thread_id') required String threadId,
  });

  /// Add Reply
  @POST('/v1/messages/{thread_id}/replies')
  Future<ThreadReplyOut> addReplyV1MessagesThreadIdRepliesPost({
    @Path('thread_id') required String threadId,
    @Body() required ReplyCreate body,
  });
}
