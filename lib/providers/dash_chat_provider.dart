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
  StreamSubscription? _messageSubscription;
  User? _currentUser;

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
    print('DashChatProvider: Setting up Firestore message listener for user ${user.uid} at /messages/${user.uid}/chat');

    // Use the correct collection path and order field
    final messageStream = _firestore
        .collection('messages')
        .doc(user.uid)
        .collection('chat')
        // .orderBy('createdAt', descending: false) // <<< Temporarily remove ordering
        .snapshots();

    _messageSubscription = messageStream.listen((snapshot) {
      if (_chatProvider == null) return; // Don't process if chatProvider isn't linked

      print('DashChatProvider: Received ${snapshot.docs.length} messages from Firestore (/chat path).');
      final messages = snapshot.docs.map((doc) {
          final data = doc.data(); // Already Map<String, dynamic>
          
          // Map fields from the /chat structure
          final createdAtMillis = data['createdAt'] as int?; // Expecting int milliseconds
          final timestamp = createdAtMillis != null
              ? DateTime.fromMillisecondsSinceEpoch(createdAtMillis)
              : DateTime.now(); // Provide default if createdAt is missing/null
          
          final messageContent = data['messageBody'] as String? ?? ''; // Use messageBody
          final source = data['source'] as String?;
          final isMe = source != 'server'; // Assume not from 'server' means it's from the user
          
          // Default type and status for now, adjust if needed
          final messageType = MessageType.text;
          final messageStatus = MessageStatus.delivered; // Since it's read from DB

          // Perform robust mapping
          return ChatMessage(
              id: doc.id, // Use Firestore doc ID
              content: messageContent,
              isMe: isMe,
              timestamp: timestamp, 
              type: messageType,
              status: messageStatus,
              // Map other ChatMessage fields if corresponding data exists in Firestore
              // e.g., quickReplies from 'answers' if isPoll == 'y' ?
          );
      }).toList();

      // Update the linked ChatProvider
      _chatProvider!.setMessages(messages);

    }, onError: (error) {
      print('DashChatProvider: Error listening to messages (/chat path): $error');
      // Optionally update ChatProvider with an error state
    });
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
           // Re-throw or handle as needed, for now just logging
           throw error; // Re-throw to be caught by outer catch block if needed
        });
      print('[SendMessage] Post-set: Document ensured/created successfully: ${userDocRef.path}'); // Keep this log

      print('[SendMessage] Attempting to add message to subcollection: ${userDocRef.collection("chat").path}');
      await userDocRef.collection('chat')
          .add({
            'messageBody': messageContent,
            'source': 'user',
            'createdAt': FieldValue.serverTimestamp(),
          })
          .then((docRef) {
             print('[SendMessage] .then(): Message added successfully with ID: ${docRef.id}');
          })
          .catchError((error, stackTrace) {
             print('[SendMessage] .catchError() during collection.add(): $error\n$stackTrace');
             throw error; // Re-throw
          });
      print('[SendMessage] Post-add: Message added successfully to subcollection.'); // Keep this log

    } catch (e, s) { // Outer catch block remains
      // Check if userDocRef was assigned to distinguish errors
      if (userDocRef == null) {
         print('[SendMessage] Error initializing DocumentReference: $e\n$s');
      } else if (await userDocRef.get().then((_) => false).catchError((_) => true)) {
         // Crude check: If getting the doc errors out *after* the set attempt, the set likely failed
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
    
    // Log the userId being used
    print('[HandleQuickReply] Using userId: $userId');

    DocumentReference? userDocRef;
    try {
       userDocRef = _firestore.collection('messages').doc(userId);
       
       print('[HandleQuickReply] Attempting to ensure document exists: ${userDocRef.path}');
       await userDocRef.set({'_placeholder': FieldValue.serverTimestamp()}, SetOptions(merge: true))
          .then((_) {
             print('[HandleQuickReply] .then(): Document set/merge completed.');
          })
          .catchError((error, stackTrace) {
             print('[HandleQuickReply] .catchError() during userDocRef.set(): $error\n$stackTrace');
             throw error; // Re-throw
          });
       print('[HandleQuickReply] Post-set: Document ensured/created successfully: ${userDocRef.path}'); // Keep

       print('[HandleQuickReply] Attempting to add quick reply to subcollection: ${userDocRef.collection("chat").path}');
       await userDocRef.collection('chat')
           .add({
             'messageBody': replyContent,
             'source': 'user',
             'createdAt': FieldValue.serverTimestamp(),
           })
           .then((docRef) {
             print('[HandleQuickReply] .then(): Quick reply added successfully with ID: ${docRef.id}');
           })
           .catchError((error, stackTrace) {
             print('[HandleQuickReply] .catchError() during collection.add(): $error\n$stackTrace');
             throw error; // Re-throw
           });
       print('[HandleQuickReply] Post-add: Quick reply added successfully to subcollection.'); // Keep

    } catch (e, s) { // Outer catch block remains
      // Check if userDocRef was assigned to distinguish errors
      if (userDocRef == null) {
         print('[HandleQuickReply] Error initializing DocumentReference: $e\n$s');
      } else if (await userDocRef.get().then((_) => false).catchError((_) => true)) {
         print('[HandleQuickReply] Error likely during userDocRef.set(): $e\n$s');
      } else {
         print('[HandleQuickReply] Error likely during collection.add(): $e\n$s');
      }
      print('[HandleQuickReply] Outer catch block details: $e\nStack trace:\n$s');
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