import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_message.dart';
import '../models/firebase_chat_message.dart';

class FirebaseUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static String get userId => _auth.currentUser?.uid ?? '';
  static User? get currentUser => _auth.currentUser;

  // Create a Firestore document reference for a user's profile
  static DocumentReference getUserDocRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  // Create a Firestore collection reference for a user's chat history
  static CollectionReference getChatHistoryCollectionRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('chat_history');
  }

  // Create a storage reference for user media
  static Reference getUserMediaStorageRef(String uid, String mediaId) {
    return _storage.ref().child('users/$uid/media/$mediaId');
  }

  // Create a storage reference for user profile images
  static Reference getUserProfileImageStorageRef(String uid, String fileName) {
    return _storage.ref().child('users/$uid/profile/$fileName');
  }

  // Check if user is authenticated
  static bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  // Get current user display name
  static String getCurrentUserDisplayName() {
    return _auth.currentUser?.displayName ?? 'User';
  }

  // Get current user photo URL
  static String? getCurrentUserPhotoUrl() {
    return _auth.currentUser?.photoURL;
  }

  // Update last activity timestamp for current user
  static Future<void> updateUserLastActive() async {
    if (_auth.currentUser == null) return;
    
    try {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user last active: $e');
    }
  }

  // Get timestamp for server time
  static Timestamp getServerTimestamp() {
    return Timestamp.now();
  }

  // Convert ChatMessage to FirebaseChatMessage
  static FirebaseChatMessage chatMessageToFirebaseMessage(ChatMessage message) {
    return FirebaseChatMessage.fromChatMessage(
      message: message,
      senderId: userId,
      senderName: getCurrentUserDisplayName(),
      senderPhotoUrl: getCurrentUserPhotoUrl(),
    );
  }

  // Convert FirebaseChatMessage to ChatMessage
  static ChatMessage firebaseMessageToChatMessage(FirebaseChatMessage message) {
    return message.toChatMessage(userId);
  }

  // Delete all files in a user's storage directory
  static Future<void> deleteUserStorageFiles(String uid, String subPath) async {
    try {
      final ref = _storage.ref().child('users/$uid/$subPath');
      final ListResult result = await ref.listAll();
      
      for (final item in result.items) {
        await item.delete();
      }
      
      for (final prefix in result.prefixes) {
        final ListResult subResult = await prefix.listAll();
        for (final item in subResult.items) {
          await item.delete();
        }
      }
    } catch (e) {
      print('Error deleting user storage files: $e');
    }
  }
}