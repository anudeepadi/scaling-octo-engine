import 'package:flutter/material.dart';
import 'quick_reply.dart';
import 'gemini_quick_reply.dart';
import 'link_preview.dart';

enum MessageType {
  text,
  image,
  gif,
  video,
  youtube,
  file,
  linkPreview,
  quickReply,
  geminiQuickReply, // New type for Gemini-generated quick replies
  suggestion,
  voice,
  threadReply,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class MessageReaction {
  final String emoji;
  final String userId;
  final DateTime timestamp;

  MessageReaction({
    required this.emoji,
    required this.userId,
    required this.timestamp,
  });
}

class ChatMessage {
  final String id;
  final String content;
  final bool isMe;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final List<QuickReply>? suggestedReplies;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final LinkPreview? linkPreview;
  final MessageStatus status;
  final List<MessageReaction> reactions;
  final String? parentMessageId;
  final List<String> threadMessageIds;
  final int? voiceDuration;
  final String? voiceWaveform;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isMe,
    required this.timestamp,
    required this.type,
    this.isUser = false,
    this.suggestedReplies,
    this.mediaUrl,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.linkPreview,
    this.status = MessageStatus.sent,
    this.reactions = const [],
    this.parentMessageId,
    this.threadMessageIds = const [],
    this.voiceDuration,
    this.voiceWaveform,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isMe,
    bool? isUser,
    DateTime? timestamp,
    MessageType? type,
    List<QuickReply>? suggestedReplies,
    String? mediaUrl,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    LinkPreview? linkPreview,
    MessageStatus? status,
    List<MessageReaction>? reactions,
    String? parentMessageId,
    List<String>? threadMessageIds,
    int? voiceDuration,
    String? voiceWaveform,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isMe: isMe ?? this.isMe,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      suggestedReplies: suggestedReplies ?? this.suggestedReplies,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      linkPreview: linkPreview ?? this.linkPreview,
      status: status ?? this.status,
      reactions: reactions ?? this.reactions,
      parentMessageId: parentMessageId ?? this.parentMessageId,
      threadMessageIds: threadMessageIds ?? this.threadMessageIds,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      voiceWaveform: voiceWaveform ?? this.voiceWaveform,
    );
  }
}