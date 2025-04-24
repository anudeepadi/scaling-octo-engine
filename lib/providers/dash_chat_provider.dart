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
  bool _isServerServiceInitialized = false; // Add this field

  bool _isTyping = false;
  bool get isTyping => _isTyping;
  bool get isServerServiceInitialized => _isServerServiceInitialized; // Add this getter

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
        // _messageSubscription?.cancel(); // Moved cancellation to clearOnLogout
        // _chatProvider?.clearChatHistory(); // Moved clearing to clearOnLogout (via proxy provider call)
        // clearOnLogout(); // Let the proxy provider call this
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
          print('\n[QuickReplyDebug] Processing doc ID: ${doc.id}'); // Log Doc ID
          final data = doc.data(); 
          
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
          print('[QuickReplyDebug] isMe: $isMe (senderId: $senderId, source: $source)'); // Log isMe calculation
          print('[QuickReplyDebug] Message Content: "$messageContent"'); // Log Content

          List<QuickReply>? suggestedReplies;
          List<String>? answersFromData;
          // Extract existing quick replies (answers) first
          if (data.containsKey('answers') && data['answers'] is List) {
            answersFromData = List<String>.from(data['answers']);
            print("[QuickReplyDebug] Found 'answers' field: $answersFromData"); // Use double quotes
            if (answersFromData.isNotEmpty) { 
               suggestedReplies = answersFromData.map((text) => QuickReply(text: text, value: text)).toList();
               print("[QuickReplyDebug] Created suggestedReplies from 'answers' field: ${suggestedReplies?.length ?? 0} replies"); // Use double quotes
            }
          } else {
             print("[QuickReplyDebug] 'answers' field not found or not a List."); // Use double quotes
          }

          // ---- Add keyword-based quick replies if message is from server and no 'answers' were provided ----
          final shouldCheckKeywords = !isMe && (suggestedReplies == null || suggestedReplies.isEmpty);
          print('[QuickReplyDebug] Should check keywords? $shouldCheckKeywords (!isMe: ${!isMe}, repliesEmpty: ${(suggestedReplies == null || suggestedReplies.isEmpty)}) ');
          if (shouldCheckKeywords) {
            final messageContentLower = messageContent.toLowerCase();
            final List<Map<String, List<String>>> keywordGroups = [
              {'keywords': ['hello', 'hi'], 'replies': ['hello', 'hi']},
              {'keywords': ['how', 'help'], 'replies': ['how', 'help']},
              {'keywords': ['why', 'reason'], 'replies': ['why', 'reason']},
              {'keywords': ['smoke', 'cigarette'], 'replies': ['smoke', 'cigarette']},
              {'keywords': ['drink', 'alcohol'], 'replies': ['drink', 'alcohol']},
            ];

            bool keywordMatchFound = false; // Flag to track if any keyword matched
            for (var group in keywordGroups) {
              bool matchFoundInGroup = group['keywords']!.any((keyword) => messageContentLower.contains(keyword));
              if (matchFoundInGroup) {
                 print('[QuickReplyDebug] Keyword match found in group: ${group['keywords']}'); // Log which group matched
                 suggestedReplies = group['replies']!
                    .map((replyText) => QuickReply(text: replyText, value: replyText))
                    .toList();
                 keywordMatchFound = true;
                 break; 
              }
            }
            if (!keywordMatchFound) {
                 print('[QuickReplyDebug] No keyword match found in message content.');
            }
          } else if (!isMe) {
             print("[QuickReplyDebug] Not checking keywords because replies already exist from 'answers' field."); // Use double quotes
          }
          // ---- End of keyword-based quick replies ----
          
          print('[QuickReplyDebug] Final suggestedReplies count: ${suggestedReplies?.length ?? 0}'); // Log final reply count

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
              suggestedReplies: suggestedReplies, // Include replies (either from 'answers' or keywords)
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
    print('[DashChatProvider] Initializing ServerMessageService for user $userId'); // Added log
    _serverMessageService = ServerMessageService(
      userId: userId,
      fcmToken: fcmToken,
    );
    _isServerServiceInitialized = true; // Set flag
    print('[DashChatProvider] ServerMessageService Initialized. Flag set: $_isServerServiceInitialized'); // Added log
    notifyListeners(); // Notify potentially interested listeners
  }

  // Add the clearOnLogout method
  void clearOnLogout() {
    print('[DashChatProvider] Clearing state on logout.');
    _messageSubscription?.cancel();
    _messageSubscription = null; // Ensure it's null after cancelling
    _serverMessageService = null; // Clear the service instance
    _isServerServiceInitialized = false; // Reset the flag
    // Note: _chatProvider?.clearChatHistory() is likely handled by ChatProvider itself
    // listening to AuthProvider or called separately. Avoid duplicate clears.
    print('[DashChatProvider] State cleared. Subscription cancelled: ${_messageSubscription == null}, Service cleared: ${_serverMessageService == null}, Flag reset: $_isServerServiceInitialized');
    notifyListeners(); // Notify listeners about the state change
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
    print("[HandleQuickReply] Method called with reply: text='${reply.text}', value='${reply.value}'"); // Log entry and reply
    
    final authInstance = FirebaseAuth.instance;
    final currentUser = authInstance.currentUser;
    if (reply.value.isEmpty || currentUser == null) {
       print('[HandleQuickReply] Error: Reply value empty or user not logged in. Cannot send.');
      return;
    }
    final userId = currentUser.uid;
    final replyContent = reply.value;
    
    print('[HandleQuickReply] Using userId: $userId, Reply Content: "$replyContent"');

    DocumentReference? userDocRef;
    final replyMessageId = const Uuid().v4(); // Generate ID early for logging
    print('[HandleQuickReply] Generated Reply Message ID: $replyMessageId');

    try {
       userDocRef = _firestore.collection('messages').doc(userId);
       final messageSubcollectionPath = userDocRef.collection("messages").path;
       print('[HandleQuickReply] User doc path: ${userDocRef.path}');
       print('[HandleQuickReply] Message subcollection path: $messageSubcollectionPath');

       // --- Firestore Write --- 
       print('[HandleQuickReply] Attempting to add reply message to Firestore...');
       await userDocRef.collection('messages') 
          .doc(replyMessageId)
          .set({
            'content': replyContent, // Use 'content' for user replies
            'senderId': userId,
            'timestamp': FieldValue.serverTimestamp(), // Use 'timestamp'
            'type': MessageType.text.index,
            'status': MessageStatus.sending.index,
            'eventTypeCode': 2, // <-- Ensure this is 2 for quick replies
          });
       print('[HandleQuickReply] Successfully added reply message to Firestore (ID: $replyMessageId).');

       // --- Server Processing --- 
       if (_serverMessageService != null) {
         print('[HandleQuickReply] Attempting to process reply message via ServerMessageService...');
         await _serverMessageService!.processMessage(
           messageText: replyContent,
           messageId: replyMessageId,
           eventTypeCode: 2, // <-- Ensure this is 2 for quick replies
         );
         print('[HandleQuickReply] Successfully processed reply message via ServerMessageService.');
       } else {
         print('[HandleQuickReply] Warning: ServerMessageService not initialized, cannot process quick reply.');
       }

       print('[HandleQuickReply] Method completed successfully.');

    } catch (e, s) {
      print('[HandleQuickReply] !!! ERROR occurred !!!');
      print('[HandleQuickReply] Error details: $e');
      print('[HandleQuickReply] Stack trace:\n$s');
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