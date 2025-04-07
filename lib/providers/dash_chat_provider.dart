import 'dart:async'; // Import async library
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
// Remove DashMessagingService import if only used for sending
// import '../services/dash_messaging_service.dart';
import '../utils/firebase_utils.dart';
import 'chat_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Remove FirebaseConnectionService import
// import '../services/firebase_connection_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add FirebaseAuth import
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../services/server_message_service.dart';

class DashChatProvider extends ChangeNotifier {
  // Remove DashMessagingService instance if only used for sending
  // final DashMessagingService _dashService = DashMessagingService();
  // Ensure _firestore is typed correctly
  final FirebaseFirestore _firestore;
  // Remove FirebaseConnectionService instance
  // final FirebaseConnectionService? _firebaseService;
  // Add FirebaseAuth instance
  final FirebaseAuth _auth;
  ChatProvider? _chatProvider; // Add reference to ChatProvider
  StreamSubscription? _authSubscription;
  StreamSubscription<QuerySnapshot>? _messageSubscription;
  User? _currentUser;
  ServerMessageService? _serverMessageService;

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  // Constructor for use with Firebase
  DashChatProvider()
      : _firestore = FirebaseFirestore.instance,
        _auth = FirebaseAuth.instance {
    print('DashChatProvider: Initializing...');
    // Add null check immediately after initialization
    if (_auth == null) {
      print('FATAL ERROR: DashChatProvider._auth is NULL immediately after assignment!');
      // Optionally throw an error to make it obvious
      // throw StateError('FirebaseAuth instance is null after initialization.');
    } else {
      print('DashChatProvider: _auth initialized successfully.');
    }
    _listenToAuthChanges();
  }

  // Method to link to the ChatProvider instance
  void setChatProvider(ChatProvider chatProvider) {
    _chatProvider = chatProvider;
    print('DashChatProvider: Linked with ChatProvider.');
    // If user is already logged in when linked, setup listeners immediately
    if (_currentUser != null) {
      _setupFirebaseListeners(_currentUser!);
    }
  }

  void _listenToAuthChanges() {
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      print('DashChatProvider: Auth state changed. User: ${user?.uid}');
      if (user == null) {
        // User logged out
        _currentUser = null;
        _messageSubscription?.cancel();
        _chatProvider?.clearChatHistory(); // Clear messages on logout
        notifyListeners(); // Notify if provider state depends on auth
      } else {
        // User logged in
        _currentUser = user;
        // Only setup listeners if chatProvider is linked
        if (_chatProvider != null) {
           _setupFirebaseListeners(user);
        } else {
           print('DashChatProvider: User logged in, but ChatProvider not linked yet.');
        }
        notifyListeners(); // Notify if provider state depends on auth
      }
    });
  }
        
  void _setupFirebaseListeners(User user) {
    // Cancel any previous message subscription
    _messageSubscription?.cancel();

    // <<< Clear existing messages BEFORE setting up new listener >>>
    _chatProvider?.clearChatHistory();
    print('DashChatProvider: Cleared chat history before setting up new listener.');

    final userId = user.uid;
    final collectionPath = 'messages/$userId/messages'; // Corrected path
    print('DashChatProvider: Setting up Firestore message listener for user $userId at /$collectionPath');

    _messageSubscription = _firestore
        .collection(collectionPath) // Use the corrected path variable
        .orderBy('timestamp', descending: false) // Order by timestamp
        .snapshots()
        .listen((snapshot) {
      if (_chatProvider == null) return; // Don't process if chatProvider isn't linked

      print('DashChatProvider: Received ${snapshot.docs.length} messages from Firestore (/$collectionPath).');
      final messages = snapshot.docs.map((doc) {
          final data = doc.data(); // Already Map<String, dynamic>
          
          // --- Correctly handle Firestore Timestamp --- 
          final timestampData = data['timestamp']; // Check for 'timestamp'
          DateTime timestamp;
          if (timestampData is Timestamp) {
              timestamp = timestampData.toDate(); // Convert Firestore Timestamp to DateTime
          } else {
              // Fallback or error handling if it's not a Timestamp (or null)
              print('Warning: timestamp field is not a Firestore Timestamp or is null for doc ${doc.id}.');
              timestamp = DateTime.now(); // Default to now or handle as error
          }
          // --- End of Timestamp handling --- 
          
          final messageContent = data['messageBody'] as String? ?? data['content'] as String? ?? ''; // Check both fields
          final source = data['source'] as String?;
          final senderId = data['senderId'] as String?;
          // Determine isMe based on senderId matching current user, or lack of 'server' source
          final isMe = (senderId != null && senderId == _currentUser?.uid) || (source == null && senderId == null); 

          // Extract quick replies (answers)
          List<QuickReply>? suggestedReplies;
          if (data.containsKey('answers') && data['answers'] is List) {
            final answers = List<String>.from(data['answers']);
            suggestedReplies = answers.map((text) => QuickReply(text: text, value: text)).toList();
          }
          
          // Determine type and status based on available data
          final messageType = data.containsKey('type') && data['type'] is int
                ? MessageType.values[data['type']]
                : MessageType.text;
          final messageStatus = data.containsKey('status') && data['status'] is int
                ? MessageStatus.values[data['status']]
                : (isMe ? MessageStatus.sent : MessageStatus.delivered); // Sensible defaults

          // Perform robust mapping
          return ChatMessage(
              id: doc.id, // Use Firestore doc ID
              content: messageContent,
              isMe: isMe,
              timestamp: timestamp, 
              suggestedReplies: suggestedReplies, // Include replies
              type: messageType,
              status: messageStatus,
              // Map other ChatMessage fields if corresponding data exists in Firestore
          );
      }).toList();

      // Update the linked ChatProvider
      _chatProvider!.setMessages(messages);

    }, onError: (error) {
      print('DashChatProvider: Error listening to messages (/$collectionPath): $error');
      // Optionally update ChatProvider with an error state
    });
  }

  // Initialize the server message service
  void initializeServerService(String userId, String fcmToken) {
    _serverMessageService = ServerMessageService(
      userId: userId,
      fcmToken: fcmToken,
    );
  }

  // Send a message directly to Firestore
  Future<void> sendMessage(String message) async {
    final authInstance = FirebaseAuth.instance;
    final currentUser = authInstance.currentUser; 
    if (message.trim().isEmpty || currentUser == null) {
      print('Message empty or user not logged in. Cannot send.');
      return;
    }
    final userId = currentUser.uid;
    final messageContent = message.trim();
    
    // Log the userId being used
    print('[SendMessage] Using userId: $userId');

    DocumentReference? userDocRef;
    try {
      userDocRef = _firestore.collection('messages').doc(userId);
      
      print('[SendMessage] Attempting to ensure document exists: ${userDocRef.path}');
      await userDocRef.set({'_placeholder': FieldValue.serverTimestamp()}, SetOptions(merge: true))
        .then((_) {
           print('[SendMessage] .then(): Document set/merge completed.');
        })
        .catchError((error, stackTrace) {
           print('[SendMessage] .catchError() during userDocRef.set(): $error\n$stackTrace');
           throw error;
        });
      print('[SendMessage] Post-set: Document ensured/created successfully: ${userDocRef.path}');

      // Generate a unique message ID
      final messageId = const Uuid().v4();
      
      print('[SendMessage] Attempting to add message to subcollection: ${userDocRef.collection("messages").path}');
      await userDocRef.collection('messages')
          .doc(messageId)
          .set({
            'content': messageContent,
            'senderId': userId,
            'timestamp': FieldValue.serverTimestamp(),
            'type': MessageType.text.index,
            'status': MessageStatus.sending.index,
            'eventTypeCode': 1,
          })
          .then((_) {
             print('[SendMessage] .then(): Message added successfully with ID: $messageId');
          })
          .catchError((error, stackTrace) {
             print('[SendMessage] .catchError() during collection.add(): $error\n$stackTrace');
             throw error;
          });
      print('[SendMessage] Post-add: Message added successfully to subcollection.');

      // Process the message using ServerMessageService
      if (_serverMessageService != null) {
        await _serverMessageService!.processMessage(
          messageText: messageContent,
          messageId: messageId,
          eventTypeCode: 1,
        );
      } else {
        print('Warning: ServerMessageService not initialized');
      }

    } catch (e, s) {
      if (userDocRef == null) {
         print('[SendMessage] Error initializing DocumentReference: $e\n$s');
      } else if (await userDocRef.get().then((_) => false).catchError((_) => true)) {
         print('[SendMessage] Error likely during userDocRef.set(): $e\n$s');
      } else {
         print('[SendMessage] Error likely during collection.add(): $e\n$s');
      }
      print('[SendMessage] Outer catch block details: $e\nStack trace:\n$s');
    }
  }

  // Handle quick reply selection by sending a message to Firestore
  Future<void> handleQuickReply(QuickReply reply) async {
    final authInstance = FirebaseAuth.instance;
    final currentUser = authInstance.currentUser;
    if (reply.value.isEmpty || currentUser == null) {
       print('Quick reply value empty or user not logged in. Cannot send.');
      return;
    }
    final userId = currentUser.uid;
    final replyContent = reply.value;
    
    print('[HandleQuickReply] Using userId: $userId');

    DocumentReference? userDocRef;
    try {
       userDocRef = _firestore.collection('messages').doc(userId);
       
       print('[HandleQuickReply] Attempting to ensure document exists: ${userDocRef.path}');
       await userDocRef.set({'_placeholder': FieldValue.serverTimestamp()}, SetOptions(merge: true));
       // No need for .then/.catchError here if using await
       print('[HandleQuickReply] Document set/merge completed.');

       // Generate a unique message ID for the reply
       final replyMessageId = const Uuid().v4();

       print('[HandleQuickReply] Attempting to add reply message to subcollection: ${userDocRef.collection("messages").path}'); // Use messages path
       await userDocRef.collection('messages') // Use messages path
          .doc(replyMessageId)
          .set({
            'content': replyContent, // Use 'content' for user replies
            'senderId': userId,
            'timestamp': FieldValue.serverTimestamp(), // Use 'timestamp'
            'type': MessageType.text.index,
            'status': MessageStatus.sending.index,
            'eventTypeCode': 2, // Quick reply event type
          });
       print('[HandleQuickReply] Reply message added successfully with ID: $replyMessageId');

       // Process the quick reply using ServerMessageService
       if (_serverMessageService != null) {
         await _serverMessageService!.processMessage(
           messageText: replyContent,
           messageId: replyMessageId,
           eventTypeCode: 2, // Quick reply event type
         );
       } else {
         print('Warning: ServerMessageService not initialized for quick reply processing');
       }

    } catch (e, s) {
      print('[HandleQuickReply] Error: $e\n$s');
    }
  }

  // Determine message type based on content (This seems like display logic, maybe belongs elsewhere?)
  MessageType _determineMessageType(String content) {
    // Check for YouTube links
    if (content.contains('youtube.com/') || content.contains('youtu.be/')) {
      return MessageType.youtube;
    }

    // Check for GIF links
    if (content.toLowerCase().endsWith('.gif') || content.contains('.gif?')) {
      return MessageType.gif;
    }

    // Check for image links
    if (_isImageUrl(content)) {
      return MessageType.image;
    }

    // Check for other URLs
    if (_containsUrl(content)) {
      return MessageType.linkPreview;
    }

    return MessageType.text;
  }

  // Helper to check if string is an image URL
  bool _isImageUrl(String url) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.bmp'];
    return imageExtensions.any((ext) => url.toLowerCase().contains(ext));
  }

  // Helper to check if string contains a URL
  bool _containsUrl(String text) {
    return Uri.tryParse(text)?.isAbsolute == true ||
           text.contains('http://') ||
           text.contains('https://');
  }

  @override
  void dispose() {
    print('DashChatProvider: Disposing...');
    _authSubscription?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }

  // Remove constructors for withoutFirebase if demo mode is not needed
  /*
  factory DashChatProvider.withoutFirebase() {
    print('DashChatProvider: Creating without Firebase (DEMO MODE)');
    return DashChatProvider._internal();
  }

  DashChatProvider._internal() 
      : _firestore = FirebaseFirestore.instance,
        _auth = FirebaseAuth.instance;
  */
}