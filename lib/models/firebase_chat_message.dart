import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_message.dart';

class FirebaseChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final List<String> reactions;
  final MessageStatus status;

  FirebaseChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    required this.timestamp,
    required this.type,
    this.mediaUrl,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.reactions = const [],
    this.status = MessageStatus.sent,
  });

  // Convert to local ChatMessage
  ChatMessage toChatMessage() {
    final isMe = false; // This will be set properly by the UI

    // Convert reactions to MessageReaction objects
    final messageReactions = reactions.map((emoji) {
      return MessageReaction(
        emoji: emoji,
        userId: senderId,
        timestamp: timestamp,
      );
    }).toList();

    return ChatMessage(
      id: id,
      content: content,
      isMe: isMe,
      timestamp: timestamp,
      type: type,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      fileName: fileName,
      fileSize: fileSize,
      reactions: messageReactions,
      status: status,
    );
  }

  // Create from local ChatMessage
  static FirebaseChatMessage fromChatMessage({
    required ChatMessage message,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
  }) {
    // Convert MessageReaction objects to emoji strings
    final reactionEmojis = message.reactions.map((reaction) => reaction.emoji).toList();

    return FirebaseChatMessage(
      id: message.id,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      content: message.content,
      timestamp: message.timestamp,
      type: message.type,
      mediaUrl: message.mediaUrl,
      thumbnailUrl: message.thumbnailUrl,
      fileName: message.fileName,
      fileSize: message.fileSize,
      reactions: reactionEmojis,
      status: message.status,
    );
  }

  // Convert from Firestore document
  factory FirebaseChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FirebaseChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      senderPhotoUrl: data['senderPhotoUrl'],
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: MessageType.values[data['type'] ?? 0],
      mediaUrl: data['mediaUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      reactions: List<String>.from(data['reactions'] ?? []),
      status: MessageStatus.values[data['status'] ?? 1],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.index,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'reactions': reactions,
      'status': status.index,
    };
  }
}
