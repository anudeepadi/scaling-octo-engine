import 'quick_reply.dart';
import 'link_preview.dart';
import '../utils/debug_config.dart';

enum MessageType {
  text,
  image,
  gif,
  video,
  youtube,
  file,
  linkPreview,
  quickReply,
  geminiQuickReply,
  suggestion,
  voice,
  threadReply,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  error,
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

bool isMessagePoll(dynamic isPollValue) {
  if (isPollValue == null) return false;
  if (isPollValue is bool) {
    return isPollValue;
  } else if (isPollValue is String) {
    return isPollValue.toLowerCase() == 'y' ||
           isPollValue.toLowerCase() == 'yes' ||
           isPollValue.toLowerCase() == 'true';
  } else if (isPollValue is int) {
    return isPollValue > 0;
  }
  return false;
}

class ChatMessage {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final MessageType type;
  final List<QuickReply>? suggestedReplies;
  final List<QuickReply>? quickReplies;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final LinkPreview? linkPreview;
  MessageStatus status;
  final List<MessageReaction> reactions;
  final String? parentMessageId;
  final List<String> threadMessageIds;
  final int? voiceDuration;
  final String? voiceWaveform;
  final int eventTypeCode;

  ChatMessage({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.isMe,
    required this.type,
    this.suggestedReplies,
    this.quickReplies,
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
    this.eventTypeCode = 1,
  });

  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String documentId) {
    // Parse createdAt timestamp
    DateTime timestamp;
    try {
      var createdAt = data['createdAt'];
      if (createdAt != null) {
        if (createdAt is String) {
          int timeValue = int.tryParse(createdAt) ?? 0;
          timestamp = DateTime.fromMillisecondsSinceEpoch(timeValue);
        } else if (createdAt is int) {
          timestamp = DateTime.fromMillisecondsSinceEpoch(createdAt);
        } else {
          timestamp = DateTime.now();
        }
      } else {
        timestamp = DateTime.now();
      }
    } catch (e) {
      DebugConfig.debugPrint('Error parsing timestamp: $e');
      timestamp = DateTime.now();
    }
    
    // Get message content
    String content = data['messageBody'] ?? '';
    
    // Determine if message is from the user
    bool isMe = data['source'] == 'client';
    
    // Get message ID
    String messageId = data['serverMessageId'] ?? documentId;
    
    // Check for quick replies
    List<QuickReply>? suggestedReplies;
    final isPoll = data['isPoll'];
    final answers = data['answers'];
    
    if (isMessagePoll(isPoll) && answers != null) {
      suggestedReplies = [];
      
      if (answers is String && answers != 'None' && answers.isNotEmpty) {
        // Parse comma-separated answers string
        final answerList = answers.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        suggestedReplies = answerList.map((item) => QuickReply(text: item, value: item)).toList();
      } else if (answers is List) {
        suggestedReplies = List<String>.from(answers)
            .map((item) => QuickReply(text: item, value: item))
            .toList();
      }
    }
    
    // Determine message type
    MessageType type = MessageType.text;
    if (suggestedReplies != null && suggestedReplies.isNotEmpty) {
      type = MessageType.quickReply;
    }
    
    return ChatMessage(
      id: messageId,
      content: content,
      timestamp: timestamp,
      isMe: isMe,
      type: type,
      suggestedReplies: suggestedReplies,
      status: MessageStatus.sent,
    );
  }
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isMe: json['isMe'] as bool,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => MessageStatus.sending,
      ),
      mediaUrl: json['mediaUrl'] as String?,
      linkPreview: json['linkPreview'] != null
          ? LinkPreview.fromJson(json['linkPreview'] as Map<String, dynamic>)
          : null,
      suggestedReplies: (json['suggestedReplies'] as List<dynamic>?)
          ?.map((e) => QuickReply.fromJson(e as Map<String, dynamic>))
          .toList(),
      eventTypeCode: json['eventTypeCode'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isMe': isMe,
      'type': type.toString(),
      'status': status.toString(),
      'mediaUrl': mediaUrl,
      'linkPreview': linkPreview?.toJson(),
      'suggestedReplies': suggestedReplies?.map((e) => e.toJson()).toList(),
      'eventTypeCode': eventTypeCode,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    DateTime? timestamp,
    bool? isMe,
    MessageType? type,
    List<QuickReply>? suggestedReplies,
    List<QuickReply>? quickReplies,
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
    int? eventTypeCode,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      type: type ?? this.type,
      suggestedReplies: suggestedReplies ?? this.suggestedReplies,
      quickReplies: quickReplies ?? this.quickReplies,
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
      eventTypeCode: eventTypeCode ?? this.eventTypeCode,
    );
  }
}