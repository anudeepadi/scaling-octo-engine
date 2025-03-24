import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_message.dart';
import 'quick_reply.dart';
import 'gemini_quick_reply.dart';
import 'link_preview.dart';

class FirebaseChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final bool isUser;
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

  FirebaseChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
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

  // Convert to local ChatMessage
  ChatMessage toChatMessage(String currentUserId) {
    return ChatMessage(
      id: id,
      content: content,
      isMe: senderId == currentUserId,
      isUser: isUser,
      timestamp: timestamp,
      type: type,
      suggestedReplies: suggestedReplies,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      fileName: fileName,
      fileSize: fileSize,
      linkPreview: linkPreview,
      status: status,
      reactions: reactions,
      parentMessageId: parentMessageId,
      threadMessageIds: threadMessageIds,
      voiceDuration: voiceDuration,
      voiceWaveform: voiceWaveform,
    );
  }

  // Create from local ChatMessage
  static FirebaseChatMessage fromChatMessage({
    required ChatMessage message,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
  }) {
    return FirebaseChatMessage(
      id: message.id,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      content: message.content,
      isUser: message.isUser,
      timestamp: message.timestamp,
      type: message.type,
      suggestedReplies: message.suggestedReplies,
      mediaUrl: message.mediaUrl,
      thumbnailUrl: message.thumbnailUrl,
      fileName: message.fileName,
      fileSize: message.fileSize,
      linkPreview: message.linkPreview,
      status: message.status,
      reactions: message.reactions,
      parentMessageId: message.parentMessageId,
      threadMessageIds: message.threadMessageIds,
      voiceDuration: message.voiceDuration,
      voiceWaveform: message.voiceWaveform,
    );
  }

  // Convert from Firestore document
  factory FirebaseChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse reactions
    List<MessageReaction> reactions = [];
    if (data['reactions'] != null) {
      final reactionsData = data['reactions'] as List<dynamic>;
      reactions = reactionsData.map((r) {
        final Map<String, dynamic> reactionMap = r as Map<String, dynamic>;
        return MessageReaction(
          emoji: reactionMap['emoji'] as String,
          userId: reactionMap['userId'] as String,
          timestamp: (reactionMap['timestamp'] as Timestamp).toDate(),
        );
      }).toList();
    }
    
    // Parse suggested replies
    List<QuickReply>? suggestedReplies;
    if (data['suggestedReplies'] != null) {
      final repliesData = data['suggestedReplies'] as List<dynamic>;
      suggestedReplies = repliesData.map((r) {
        final Map<String, dynamic> replyMap = r as Map<String, dynamic>;
        return QuickReply(
          text: replyMap['text'] as String,
          value: replyMap['value'] as String,
        );
      }).toList();
    }
    
    // Parse link preview
    LinkPreview? linkPreview;
    if (data['linkPreview'] != null) {
      final previewData = data['linkPreview'] as Map<String, dynamic>;
      linkPreview = LinkPreview(
        url: previewData['url'] as String,
        title: previewData['title'] as String,
        description: previewData['description'] as String?,
        imageUrl: previewData['imageUrl'] as String?,
      );
    }
    
    return FirebaseChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String,
      senderName: data['senderName'] as String,
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      content: data['content'] as String,
      isUser: data['isUser'] as bool? ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: MessageType.values[(data['type'] as int?) ?? 0],
      suggestedReplies: suggestedReplies,
      mediaUrl: data['mediaUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      fileName: data['fileName'] as String?,
      fileSize: data['fileSize'] as int?,
      linkPreview: linkPreview,
      status: MessageStatus.values[(data['status'] as int?) ?? 1],
      reactions: reactions,
      parentMessageId: data['parentMessageId'] as String?,
      threadMessageIds: List<String>.from(data['threadMessageIds'] as List<dynamic>? ?? []),
      voiceDuration: data['voiceDuration'] as int?,
      voiceWaveform: data['voiceWaveform'] as String?,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'content': content,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.index,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'status': status.index,
      'parentMessageId': parentMessageId,
      'threadMessageIds': threadMessageIds,
      'voiceDuration': voiceDuration,
      'voiceWaveform': voiceWaveform,
    };

    // Add link preview if available
    if (linkPreview != null) {
      data['linkPreview'] = {
        'url': linkPreview!.url,
        'title': linkPreview!.title,
        'description': linkPreview!.description,
        'imageUrl': linkPreview!.imageUrl,
      };
    }

    // Add suggested replies if available
    if (suggestedReplies != null && suggestedReplies!.isNotEmpty) {
      data['suggestedReplies'] = suggestedReplies!.map((reply) => {
        'text': reply.text,
        'value': reply.value,
      }).toList();
    }

    // Add reactions if available
    if (reactions.isNotEmpty) {
      data['reactions'] = reactions.map((reaction) => {
        'emoji': reaction.emoji,
        'userId': reaction.userId,
        'timestamp': Timestamp.fromDate(reaction.timestamp),
      }).toList();
    }

    return data;
  }
}
