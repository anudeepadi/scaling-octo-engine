import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/debug_config.dart';

class FirebaseUtils {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get FCM token
  static Future<String?> getFcmToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      DebugConfig.debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  // Request notification permissions
  static Future<bool> requestNotificationPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      DebugConfig.debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  // Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get user document reference
  static DocumentReference<Map<String, dynamic>> getUserDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  // Get messages collection reference
  static CollectionReference<Map<String, dynamic>> getMessagesCollection() {
    return _firestore.collection('messages');
  }

  // Get message document reference
  static DocumentReference<Map<String, dynamic>> getMessageDoc(String messageId) {
    return getMessagesCollection().doc(messageId);
  }

  // Get conversations collection reference
  static CollectionReference<Map<String, dynamic>> getConversationsCollection() {
    return _firestore.collection('conversations');
  }

  // Get conversation document reference
  static DocumentReference<Map<String, dynamic>> getConversationDoc(String conversationId) {
    return getConversationsCollection().doc(conversationId);
  }

  // Get user's conversations
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserConversations(String userId) {
    return getConversationsCollection()
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Get conversation messages
  static Stream<QuerySnapshot<Map<String, dynamic>>> getConversationMessages(String conversationId) {
    return getMessagesCollection()
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Update user's FCM token
  static Future<void> updateUserFcmToken(String userId, String? token) async {
    try {
      await getUserDoc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      DebugConfig.debugPrint('Error updating FCM token: $e');
    }
  }

  // Send a message
  static Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    required String messageType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final messageData = {
        'conversationId': conversationId,
        'senderId': senderId,
        'content': content,
        'type': messageType,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        ...?additionalData,
      };

      await getMessagesCollection().add(messageData);

      // Update conversation's last message
      await getConversationDoc(conversationId).update({
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageType': messageType,
        'lastMessageSenderId': senderId,
      });
    } catch (e) {
      DebugConfig.debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Update message status
  static Future<void> updateMessageStatus(String messageId, String status) async {
    try {
      await getMessageDoc(messageId).update({
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      DebugConfig.debugPrint('Error updating message status: $e');
    }
  }

  // Create a new conversation
  static Future<String> createConversation({
    required List<String> participants,
    String? name,
    String? lastMessage,
    String? lastMessageType,
    String? lastMessageSenderId,
  }) async {
    try {
      final conversationData = {
        'participants': participants,
        'name': name,
        'lastMessage': lastMessage,
        'lastMessageType': lastMessageType,
        'lastMessageSenderId': lastMessageSenderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await getConversationsCollection().add(conversationData);
      return docRef.id;
    } catch (e) {
      DebugConfig.debugPrint('Error creating conversation: $e');
      rethrow;
    }
  }

  // Update conversation
  static Future<void> updateConversation(
    String conversationId,
    Map<String, dynamic> data,
  ) async {
    try {
      await getConversationDoc(conversationId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      DebugConfig.debugPrint('Error updating conversation: $e');
      rethrow;
    }
  }

  // Delete conversation
  static Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete all messages in the conversation
      final messagesSnapshot = await getMessagesCollection()
          .where('conversationId', isEqualTo: conversationId)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the conversation document
      batch.delete(getConversationDoc(conversationId));

      await batch.commit();
    } catch (e) {
      DebugConfig.debugPrint('Error deleting conversation: $e');
      rethrow;
    }
  }
} 