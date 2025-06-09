import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../models/gemini_quick_reply.dart';
import '../models/link_preview.dart';

class FirebaseChatService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final _uuid = Uuid();
  
  FirebaseChatService() : 
    _firestore = FirebaseFirestore.instance,
    _auth = FirebaseAuth.instance,
    _storage = FirebaseStorage.instance {
    // Constructor body is empty, initialization happens in the initializer list
  }

  User? get currentUser => _auth.currentUser;
  String get userId => currentUser?.uid ?? '';

  // Get all chat messages for the current user
  Stream<List<ChatMessage>> getChatMessages() {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        // Convert Firestore Timestamp to DateTime
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        
        // Handle reactions if any
        List<MessageReaction> reactions = [];
        if (data['reactions'] != null) {
          final reactionsData = data['reactions'] as List<dynamic>;
          reactions = reactionsData.map((r) {
            return MessageReaction(
              emoji: r['emoji'] as String,
              userId: r['userId'] as String,
              timestamp: (r['timestamp'] as Timestamp).toDate(),
            );
          }).toList();
        }
        
        // Handle suggested replies if any
        List<QuickReply>? suggestedReplies;
        if (data['suggestedReplies'] != null) {
          final repliesData = data['suggestedReplies'] as List<dynamic>;
          suggestedReplies = repliesData.map((r) {
            return QuickReply(
              text: r['text'] as String,
              value: r['value'] as String,
            );
          }).toList();
        }
        
        // Handle link preview
        LinkPreview? linkPreview;
        if (data['linkPreview'] != null) {
          final previewData = data['linkPreview'] as Map<String, dynamic>;
          linkPreview = LinkPreview(
            url: previewData['url'] as String,
            title: previewData['title'] as String,
            description: previewData['description'] as String? ?? '',
            imageUrl: previewData['imageUrl'] as String?,
          );
        }
        
        // Determine message type
        final MessageType type = MessageType.values[data['type'] as int];
        
        // Create chat message from Firestore document
        return ChatMessage(
          id: doc.id,
          content: data['content'] as String,
          isMe: data['senderId'] == userId,
          timestamp: timestamp,
          type: type,
          suggestedReplies: suggestedReplies,
          mediaUrl: data['mediaUrl'] as String?,
          thumbnailUrl: data['thumbnailUrl'] as String?,
          fileName: data['fileName'] as String?,
          fileSize: data['fileSize'] as int?,
          linkPreview: linkPreview,
          status: MessageStatus.values[data['status'] as int? ?? 1],
          reactions: reactions,
          parentMessageId: data['parentMessageId'] as String?,
          threadMessageIds: List<String>.from(data['threadMessageIds'] as List<dynamic>? ?? []),
          voiceDuration: data['voiceDuration'] as int?,
          voiceWaveform: data['voiceWaveform'] as String?,
        );
      }).toList();
    });
  }

  // Save a chat message to Firestore
  Future<void> saveChatMessage(ChatMessage message) async {
    if (userId.isEmpty) return;

    final Map<String, dynamic> messageData = {
      'senderId': userId,
      'senderName': currentUser?.displayName ?? 'User',
      'senderPhotoUrl': currentUser?.photoURL,
      'content': message.content,
      'timestamp': Timestamp.fromDate(message.timestamp),
      'type': message.type.index,
      'isUser': message.isMe,
      'mediaUrl': message.mediaUrl,
      'thumbnailUrl': message.thumbnailUrl,
      'fileName': message.fileName,
      'fileSize': message.fileSize,
      'status': message.status.index,
      'parentMessageId': message.parentMessageId,
      'threadMessageIds': message.threadMessageIds,
      'voiceDuration': message.voiceDuration,
      'voiceWaveform': message.voiceWaveform,
    };

    // Add link preview if available
    if (message.linkPreview != null) {
      messageData['linkPreview'] = {
        'url': message.linkPreview!.url,
        'title': message.linkPreview!.title,
        'description': message.linkPreview!.description,
        'imageUrl': message.linkPreview!.imageUrl,
      };
    }

    // Add suggested replies if available
    if (message.suggestedReplies != null && message.suggestedReplies!.isNotEmpty) {
      if (message.type == MessageType.geminiQuickReply) {
        // Convert to regular quick replies if they are Gemini quick replies
        final geminiReplies = message.suggestedReplies as List<GeminiQuickReply>;
        messageData['suggestedReplies'] = geminiReplies.map((reply) => {
          'text': reply.text,
          'value': reply.value,
        }).toList();
      } else {
        final replies = message.suggestedReplies as List<QuickReply>;
        messageData['suggestedReplies'] = replies.map((reply) => {
          'text': reply.text,
          'value': reply.value,
        }).toList();
      }
    }

    // Add reactions if available
    if (message.reactions.isNotEmpty) {
      messageData['reactions'] = message.reactions.map((reaction) => {
        'emoji': reaction.emoji,
        'userId': reaction.userId,
        'timestamp': Timestamp.fromDate(reaction.timestamp),
      }).toList();
    }

    // Save to user's chat history
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_history')
        .doc(message.id)
        .set(messageData);
  }

  // Send a text message
  Future<ChatMessage> sendTextMessage(String content, {String? parentMessageId}) async {
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    final messageId = _uuid.v4();
    final timestamp = DateTime.now();

    final message = ChatMessage(
      id: messageId,
      content: content,
      isMe: true,
      timestamp: timestamp,
      type: MessageType.text,
      status: MessageStatus.sent,
      parentMessageId: parentMessageId,
    );

    await saveChatMessage(message);
    return message;
  }

  // Send a media message (image, video, gif)
  Future<ChatMessage> sendMediaMessage(
    String localFilePath,
    MessageType type, {
    String? thumbnailPath,
  }) async {
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    final messageId = _uuid.v4();
    final timestamp = DateTime.now();
    
    // Upload file to Firebase Storage
    final fileName = path.basename(localFilePath);
    final storagePath = 'users/$userId/media/$messageId/$fileName';
    final storageRef = _storage.ref().child(storagePath);
    
    final uploadTask = storageRef.putFile(File(localFilePath));
    final snapshot = await uploadTask.whenComplete(() {});
    final mediaUrl = await snapshot.ref.getDownloadURL();
    
    // Upload thumbnail if provided
    String? thumbnailUrl;
    if (thumbnailPath != null) {
      final thumbnailFileName = path.basename(thumbnailPath);
      final thumbnailStoragePath = 'users/$userId/media/$messageId/thumbnail_$thumbnailFileName';
      final thumbnailRef = _storage.ref().child(thumbnailStoragePath);
      
      final thumbnailTask = thumbnailRef.putFile(File(thumbnailPath));
      final thumbnailSnapshot = await thumbnailTask.whenComplete(() {});
      thumbnailUrl = await thumbnailSnapshot.ref.getDownloadURL();
    }

    final message = ChatMessage(
      id: messageId,
      content: fileName,
      isMe: true,
      timestamp: timestamp,
      type: type,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      fileName: fileName,
      fileSize: File(localFilePath).lengthSync(),
      status: MessageStatus.sent,
    );

    await saveChatMessage(message);
    return message;
  }

  // Send a file message
  Future<ChatMessage> sendFileMessage(String localFilePath) async {
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    final messageId = _uuid.v4();
    final timestamp = DateTime.now();
    final fileName = path.basename(localFilePath);
    
    // Upload file to Firebase Storage
    final storagePath = 'users/$userId/files/$messageId/$fileName';
    final storageRef = _storage.ref().child(storagePath);
    
    final uploadTask = storageRef.putFile(File(localFilePath));
    final snapshot = await uploadTask.whenComplete(() {});
    final fileUrl = await snapshot.ref.getDownloadURL();
    
    final fileSize = File(localFilePath).lengthSync();

    final message = ChatMessage(
      id: messageId,
      content: fileName,
      isMe: true,
      timestamp: timestamp,
      type: MessageType.file,
      mediaUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      status: MessageStatus.sent,
    );

    await saveChatMessage(message);
    return message;
  }

  // Add reaction to a message
  Future<void> addReaction(String messageId, String emoji) async {
    if (userId.isEmpty) return;

    final messageRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_history')
        .doc(messageId);
        
    final messageDoc = await messageRef.get();
    if (!messageDoc.exists) return;
    
    final reaction = {
      'emoji': emoji,
      'userId': userId,
      'timestamp': Timestamp.fromDate(DateTime.now()),
    };
    
    List<dynamic> reactions = [];
    if (messageDoc.data()?['reactions'] != null) {
      reactions = List<dynamic>.from(messageDoc.data()!['reactions']);
    }
    
    reactions.add(reaction);
    
    await messageRef.update({
      'reactions': reactions,
    });
  }

  // Remove reaction from a message
  Future<void> removeReaction(String messageId, String emoji) async {
    if (userId.isEmpty) return;

    final messageRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_history')
        .doc(messageId);
        
    final messageDoc = await messageRef.get();
    if (!messageDoc.exists) return;
    
    if (messageDoc.data()?['reactions'] == null) return;
    
    List<dynamic> reactions = List<dynamic>.from(messageDoc.data()!['reactions']);
    reactions.removeWhere((r) => r['emoji'] == emoji && r['userId'] == userId);
    
    await messageRef.update({
      'reactions': reactions,
    });
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    if (userId.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_history')
        .doc(messageId)
        .delete();
  }

  // Clear all chat history for the current user
  Future<void> clearChatHistory() async {
    if (userId.isEmpty) return;

    final batch = _firestore.batch();
    final messagesSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_history')
        .get();
        
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}
