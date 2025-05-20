import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../utils/app_localizations.dart';
import '../utils/context_holder.dart';
import '../utils/platform_utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DashMessagingService {
  static final DashMessagingService _instance = DashMessagingService._internal();
  factory DashMessagingService() => _instance;
  DashMessagingService._internal();

  // Server host URL - initialize with correct server URL from main.py
  String _hostUrl = "https://dashmessaging-com.ngrok.io/scheduler/mobile-app";
  String get hostUrl => _hostUrl;
  
  // User information
  String? _userId;
  String? _fcmToken;
  final _uuid = Uuid();
  
  // Stream controller for receiving messages
  final _messageStreamController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;
  
  // Flag to track initialization state
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  // Track last response message to prevent duplicates
  String? _lastResponseId;
  DateTime? _lastResponseTime;
  String? _lastMessageText;

  // Track last Firestore message time
  int _lastFirestoreMessageTime = 0;

  // Add this field to manage the Firestore subscription
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;

  // Initialize the service with user info
  Future<void> initialize(String userId) async {
    if (userId.isEmpty) {
      print('Cannot initialize DashMessagingService with empty userId');
      throw Exception('User ID cannot be empty');
    }
    
    if (_isInitialized && userId == _userId) {
      print('DashMessagingService already initialized for user: $userId');
      return;
    }
    
    print('Initializing DashMessagingService for user: $userId');
    
    _userId = userId;
    _isInitialized = true;
    
    // Load host URL explicitly first
    await _loadHostUrl();
    
    // Load FCM token
    _fcmToken = await _loadFcmToken();
    print('FCM Token: $_fcmToken');
    
    // Clear any existing message data
    _lastFirestoreMessageTime = 0;
    print('Reset _lastFirestoreMessageTime to 0 during initialization');
    
    // Load messages from Firestore on initialization
    await _loadExistingMessages();
    
    // Start real-time listening for chat messages
    startRealtimeMessageListener();
    
    print('DashMessagingService initialized for user: $userId');
    print('Using host URL: $_hostUrl');
    print('FCM Token: $_fcmToken');
    
    // Test connection to the server
    final isConnected = await testConnection();
    if (isConnected) {
      print('Successfully connected to server');
    } else {
      print('Could not connect to server, but will still attempt to send messages');
    }
  }

  // Load host URL - use the exact server URL from main.py
  Future<void> _loadHostUrl() async {
    try {
      // Always use the correct ngrok URL from main.py with full path
      _hostUrl = "https://dashmessaging-com.ngrok.io/scheduler/mobile-app";
      print('Using server URL: $_hostUrl');
      
      // Store this URL in shared preferences for future use
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('hostUrl', _hostUrl);
      } catch (e) {
        print('Error saving host URL to preferences: $e');
      }
      
      return;
    } catch (e) {
      print('Error loading host URL: $e');
    }
  }
  
  // Load existing messages from Firestore for the current user
  Future<void> _loadExistingMessages() async {
    if (_userId == null) {
      print('Cannot load messages, user ID is null');
      return;
    }
    
    try {
      print('Loading existing messages from Firestore for user: $_userId');
      print('Collection path: messages/${_userId}/chat');
      
      // Get reference to the user's chat collection in Firestore
      final chatRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(_userId)
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .limit(20); // Reduced from 50 to 20 messages initially
      
      print('Executing Firestore query for recent messages');
      final snapshot = await chatRef.get();
      
      if (snapshot.docs.isEmpty) {
        print('No existing messages found for user $_userId');
        return;
      }
      
      print('Found ${snapshot.docs.length} existing messages in Firestore');
      // Log information about documents
      for (var i = 0; i < snapshot.docs.length; i++) {
        var doc = snapshot.docs[i];
        var data = doc.data();
        print('Document $i: ID=${doc.id}, serverMessageId=${data['serverMessageId']}, createdAt=${data['createdAt']}, messageBody=${data['messageBody'] ?? '<empty>'}');
      }
      
      // Track the highest timestamp we've seen
      int highestTimestamp = 0;
      
      // Process messages in reverse to maintain chronological order
      final messages = <ChatMessage>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          
          // Skip empty messages
          if ((data['messageBody'] ?? '').toString().isEmpty) {
            print('Skipping message with empty content: ${doc.id}');
            continue;
          }
          
          // Create ChatMessage from Firestore data
          final message = ChatMessage(
            id: data['serverMessageId'] ?? doc.id,
            content: data['messageBody'] ?? '',
            timestamp: DateTime.now(), // Don't worry about exact timestamps for display
            isMe: data['source'] == 'client',
            type: MessageType.text,
          );
          
          messages.add(message);
          
          // Track the timestamp for future queries
          try {
            var createdAt = data['createdAt'];
            int timeValue = 0;
            if (createdAt != null) {
              // Handle different timestamp formats
              if (createdAt is String) {
                timeValue = int.tryParse(createdAt) ?? 0;
              } else if (createdAt is int) {
                timeValue = createdAt;
              }
              
              // Keep track of highest timestamp
              if (timeValue > highestTimestamp) {
                highestTimestamp = timeValue;
              }
            }
          } catch (e) {
            print('Error tracking timestamp: $e');
          }

          // Handle quick replies/polls
          final isPoll = data['isPoll'];
          if (isMessagePoll(isPoll) && data['answers'] != null) {
            try {
              List<String> answers = [];
              final answersData = data['answers'];
              
              if (answersData is String && answersData != 'None' && answersData.isNotEmpty) {
                // Parse comma-separated answers string
                answers = answersData.split(',').map((e) => e.trim()).toList();
              } else if (answersData is List) {
                answers = List<String>.from(answersData);
              }
              
              if (answers.isNotEmpty) {
                final quickReplies = answers.map((item) => 
                  QuickReply(text: item, value: item)
                ).toList();
                
                final quickReplyMessage = ChatMessage(
                  id: '${message.id}_replies',
                  content: '',
                  timestamp: DateTime.now().add(const Duration(milliseconds: 100)),
                  isMe: false,
                  type: MessageType.quickReply,
                  suggestedReplies: quickReplies,
                );
                
                messages.add(quickReplyMessage);
              }
            } catch (e) {
              print('Error processing quick replies: $e');
            }
          }
        } catch (e) {
          print('Error processing message: $e');
        }
      }
      
      // Update the last message time
      if (highestTimestamp > 0) {
        _lastFirestoreMessageTime = highestTimestamp;
        print('Updated _lastFirestoreMessageTime to $highestTimestamp');
      }
      
      print('Processed ${messages.length} messages from Firestore');
      
      // Add messages to the stream
      for (var message in messages) {
        _messageStreamController.add(message);
      }
      
      print('Added ${messages.length} messages to the stream');
    } catch (e) {
      print('Error loading messages from Firestore: $e');
    }
  }

  // Send a message to the server
  Future<bool> sendMessage(String text) async {
    if (_userId == null || _fcmToken == null) {
      print('User ID or FCM token is null. Will attempt to send to server anyway.');
    }

    // Prevent duplicate messages within 2 seconds
    if (_lastResponseTime != null && 
        DateTime.now().difference(_lastResponseTime!).inSeconds < 2 &&
        text.toLowerCase() == _lastMessageText?.toLowerCase()) {
      print('Preventing duplicate message: $text from user');
      return false;
    }

    _lastMessageText = text;
    _lastResponseTime = DateTime.now();

    try {
      final messageId = _uuid.v4();

      // Ensure correct server URL
      if (!_hostUrl.contains("/scheduler/mobile-app")) {
        print('Correcting server URL to include path');
        _hostUrl = "https://dashmessaging-com.ngrok.io/scheduler/mobile-app";
      }

      final endpoint = _hostUrl;
      final payload = {
        'messageId': messageId,
        'userId': _userId,
        'messageText': text,
        'fcmToken': _fcmToken,
        'messageTime': DateTime.now().millisecondsSinceEpoch,
      };

      print('Sending message to server: $payload');
      print('Using endpoint: $endpoint');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('Send message response status: ${response.statusCode}');
      print('Send message response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Message sent successfully to server');
        
        // Create user message
        final userMessage = ChatMessage(
          id: messageId,
          content: text,
          timestamp: DateTime.now(),
          isMe: true,
          type: MessageType.text,
        );

        // Add user message to stream
        _messageStreamController.add(userMessage);

        // Process server response
        try {
          final responseData = jsonDecode(response.body);
          if (responseData != null) {
            final serverMessage = ChatMessage(
              id: responseData['messageId'] ?? _uuid.v4(),
              content: responseData['message'] ?? '',
              timestamp: DateTime.now(),
              isMe: false,
              type: MessageType.text,
            );

            // Add server message to stream
            _messageStreamController.add(serverMessage);

            // Handle quick replies if present
            if (responseData['quickReplies'] != null) {
              final quickReplyMessage = ChatMessage(
                id: '${serverMessage.id}_replies',
                content: '',
                timestamp: DateTime.now().add(const Duration(milliseconds: 100)),
                isMe: false,
                type: MessageType.quickReply,
                suggestedReplies: (responseData['quickReplies'] as List)
                    .map((reply) => QuickReply(
                          text: reply['text'] ?? '',
                          value: reply['value'] ?? '',
                        ))
                    .toList(),
              );

              _messageStreamController.add(quickReplyMessage);
            }
          }
        } catch (e) {
          print('Error parsing server response: $e');
        }

        return true;
      } else {
        // If server fails, still show user message
        final userMessage = ChatMessage(
          id: messageId,
          content: text,
          timestamp: DateTime.now(),
          isMe: true,
          type: MessageType.text,
        );

        _messageStreamController.add(userMessage);
        print('Failed to send message. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending message: $e');
      print('Failed to send message to server');
      return false;
    }
  }
  
  // Start real-time listening for chat messages
  void startRealtimeMessageListener() {
    // Cancel any existing subscription
    _firestoreSubscription?.cancel();
    if (_userId == null) return;

    print('Starting real-time Firestore listener for user: [32m$_userId[0m');
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('messages')
        .doc(_userId)
        .collection('chat')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data == null) continue;
          if ((data['messageBody'] ?? '').toString().isEmpty) continue;

          final message = ChatMessage(
            id: data['serverMessageId'] ?? change.doc.id,
            content: data['messageBody'] ?? '',
            timestamp: DateTime.now(), // You can parse createdAt if needed
            isMe: data['source'] == 'client',
            type: MessageType.text,
          );
          _messageStreamController.add(message);

          // Handle quick replies/polls
          final isPoll = data['isPoll'];
          if (isMessagePoll(isPoll) && data['answers'] != null) {
            try {
              List<String> answers = [];
              final answersData = data['answers'];
              if (answersData is String && answersData != 'None' && answersData.isNotEmpty) {
                answers = answersData.split(',').map((e) => e.trim()).toList();
              } else if (answersData is List) {
                answers = List<String>.from(answersData);
              }
              if (answers.isNotEmpty) {
                final quickReplies = answers.map((item) => QuickReply(text: item, value: item)).toList();
                final quickReplyMessage = ChatMessage(
                  id: '${message.id}_replies',
                  content: '',
                  timestamp: DateTime.now().add(const Duration(milliseconds: 100)),
                  isMe: false,
                  type: MessageType.quickReply,
                  suggestedReplies: quickReplies,
                );
                _messageStreamController.add(quickReplyMessage);
              }
            } catch (e) {
              print('Error processing quick replies: $e');
            }
          }
        }
      }
    });
  }

  // Stop real-time listener
  void stopRealtimeMessageListener() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    print('Stopped real-time Firestore listener');
  }

  // Load FCM token from Firebase Messaging
  Future<String?> _loadFcmToken() async {
    try {
      // Try to use the token from main.py if we can't get a real FCM token
      // This is a fallback for testing purposes
      String defaultToken = "eLjQWERyTm2Kltsqxahvw6:APA91bFqgowOQxoeOpZuf9wMsUQczuxBBZZim_yo-r_j9H_SMKqU4HLuioUUgI028IRpUG5SObBY3Fp4HiJIkTNsLkrKPEgWEo2UWVvMa81mPIVdM0WEuV0";
      
      // Try to get the FCM token from Firebase Messaging
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      
      if (token != null && token.isNotEmpty) {
        print('Successfully retrieved FCM token from Firebase Messaging');
        return token;
      } else {
        print('Failed to get FCM token from Firebase Messaging, using default token');
        return defaultToken;
      }
    } catch (e) {
      print('Error loading FCM token: $e, using default token');
      // Return the default token from main.py
      return "eLjQWERyTm2Kltsqxahvw6:APA91bFqgowOQxoeOpZuf9wMsUQczuxBBZZim_yo-r_j9H_SMKqU4HLuioUUgI028IRpUG5SObBY3Fp4HiJIkTNsLkrKPEgWEo2UWVvMa81mPIVdM0WEuV0";
    }
  }

  // Update host URL and save to shared preferences
  Future<void> updateHostUrl(String newUrl) async {
    if (newUrl.isEmpty) return;
    
    try {
      // Check if the URL is valid
      final uri = Uri.parse(newUrl);
      if (!uri.isAbsolute) {
        throw Exception('URL must be absolute (start with http:// or https://)');
      }
      
      // Update the URL
      _hostUrl = newUrl;
      
      // Save to shared preferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hostUrl', newUrl);
      
      print('Host URL updated to: $_hostUrl');
      
      // Test if the new URL is working
      if (_userId != null) {
        try {
          final testResponse = await http.get(
            Uri.parse('$_hostUrl/info'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 5));
          
          print('Connection test response with new URL: ${testResponse.statusCode}');
        } catch (e) {
          print('Error testing new URL: $e');
          // We don't throw here since the URL might be valid but endpoint not available
        }
      }
    } catch (e) {
      print('Error updating host URL: $e');
      throw Exception('Failed to update host URL: $e');
    }
  }

  // Handle incoming push notifications
  void handlePushNotification(Map<String, dynamic> data) {
    try {
      print('Received push notification: $data');
      
      // Parse data into QuitxtServerIncomingDto format
      final recipientId = data['recipientId'] as String?;
      final serverMessageId = data['serverMessageId'] as String?;
      final messageBody = data['messageBody'] as String?;
      final timestamp = data['timestamp'] as int?;
      final isPoll = data['isPoll'] as bool? ?? false;
      final pollId = data['pollId'] as String?;
      final buttons = data['buttons'] as List<dynamic>?;
      
      // Handle missing required fields
      if (recipientId == null || serverMessageId == null || messageBody == null) {
        print('Missing required fields in push notification');
        return;
      }
      
      // Create message object
      final ChatMessage message = ChatMessage(
        id: serverMessageId,
        content: messageBody,
        timestamp: timestamp != null 
            ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000) 
            : DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );
      
      // Add the main message first
      _messageStreamController.add(message);
      
      // Add buttons as quick replies if available
      if (isPoll && buttons != null && buttons.isNotEmpty) {
        final quickReplies = <QuickReply>[];
        for (final button in buttons) {
          final title = button['title'] as String?;
          if (title != null) {
            quickReplies.add(QuickReply(text: title, value: title));
          }
        }
        
        if (quickReplies.isNotEmpty) {
          // Add a separate message with quick replies
          final quickReplyMessage = ChatMessage(
            id: '${serverMessageId}_replies',
            content: '',
            timestamp: DateTime.now(),
            isMe: false,
            type: MessageType.quickReply,
            suggestedReplies: quickReplies,
          );
          _messageStreamController.add(quickReplyMessage);
          return;
        }
      }
      
      // Fallback for older 'questionsAnswers' format
      else if (isPoll && data.containsKey('questionsAnswers')) {
        final questionsAnswers = data['questionsAnswers'] as Map<String, dynamic>?;
        if (questionsAnswers != null) {
          final quickReplies = <QuickReply>[];
          questionsAnswers.forEach((key, value) {
            quickReplies.add(QuickReply(text: value.toString(), value: key));
          });
          
          if (quickReplies.isNotEmpty) {
            // Add a separate message with quick replies
            final quickReplyMessage = ChatMessage(
              id: '${serverMessageId}_replies',
              content: '',
              timestamp: DateTime.now(),
              isMe: false,
              type: MessageType.quickReply,
              suggestedReplies: quickReplies,
            );
            _messageStreamController.add(quickReplyMessage);
          }
        }
      }
    } catch (e) {
      print('Error handling push notification: $e');
    }
  }
  
  // Mock method to simulate server response (for testing without server)
  Future<void> simulateServerResponse(String userMessage) async {
    // Skip all prebuilt responses, just log a message about server unavailability
    print('Server unavailable, but skipping all prebuilt responses as requested');
    print('Would normally send message to server: $userMessage');
    return;
    
    // All code below will not execute due to the early return above
    
    // Add a small delay to simulate network latency
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Generate a unique response ID for deduplication
    final responseId = _uuid.v4();
    
    // Add info message about server URL - removed to prevent duplicate messages
    // Server info messages are now filtered out in DashChatProvider
    
    // Determine which mock response to send based on the user message
    if (userMessage.toLowerCase().contains('hello') ||
        userMessage.toLowerCase().contains('hi') ||
        userMessage.contains('ready to quit')) {
      // Check if this is a duplicate message (same type sent in last 5 seconds)
      if (_lastResponseId != null && 
          _lastResponseTime != null && 
          DateTime.now().difference(_lastResponseTime!).inSeconds < 5 &&
          _lastResponseId!.contains('youtube-welcome')) {
        print('Preventing duplicate YouTube welcome message');
        return;
      }
      
      // Store this response with a recognizable ID pattern to prevent duplicates
      _lastResponseId = 'youtube-welcome-${DateTime.now().millisecondsSinceEpoch}';
      _lastResponseTime = DateTime.now();
      
      // YouTube link message
      final youtubeMessage = ChatMessage(
        id: _lastResponseId!,
        content: 'Welcome to Quitxt from the UT Health Science Center! Congrats on your decision to quit smoking! See why we think you\'re awesome, Tap pic below https://youtu.be/ZWsR3G0mdJo',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );
      _messageStreamController.add(youtubeMessage);
    } 
    else if (userMessage.toLowerCase().contains('#deactivate')) {
      // Check if this is a duplicate message (same type sent in last 5 seconds)
      if (_lastResponseId != null && 
          _lastResponseTime != null && 
          DateTime.now().difference(_lastResponseTime!).inSeconds < 5 &&
          _lastResponseId!.contains('deactivate-message')) {
        print('Preventing duplicate deactivate message');
        return;
      }
      
      // Store this response with a recognizable ID pattern
      _lastResponseId = 'deactivate-message-${DateTime.now().millisecondsSinceEpoch}';
      _lastResponseTime = DateTime.now();
      
      // GIF link message
      final gifMessage = ChatMessage(
        id: _lastResponseId!,
        content: 'We\'re sorry to see you go. Here\'s a quick tip: Stay strong! https://quitxt.org/sites/quitxt/files/gifs/PreQ6_Hoverboard.gif',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );
      _messageStreamController.add(gifMessage);
    }
    else if (userMessage == 'Better Health') {
      // Check if this is a duplicate message (same type sent in last 5 seconds)
      if (_lastResponseId != null && 
          _lastResponseTime != null && 
          DateTime.now().difference(_lastResponseTime!).inSeconds < 5 &&
          _lastResponseId!.contains('poll-message')) {
        print('Preventing duplicate poll message');
        return;
      }
      
      // Store this response with a recognizable ID pattern
      _lastResponseId = 'poll-message-${DateTime.now().millisecondsSinceEpoch}';
      _lastResponseTime = DateTime.now();
      
      // Poll message with buttons
      final pollMessage = ChatMessage(
        id: _lastResponseId!,
        content: 'Which of these benefits appeals to you the most?',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );
      _messageStreamController.add(pollMessage);
      
      // Add quick reply buttons
      await Future.delayed(const Duration(milliseconds: 200));
      final quickReplyMessage = ChatMessage(
        id: '${_lastResponseId!}_replies',
        content: '',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.quickReply,
        suggestedReplies: [
          QuickReply(text: 'Better Health', value: 'Better Health'),
          QuickReply(text: 'Save Money', value: 'Save Money'),
          QuickReply(text: 'More Energy', value: 'More Energy'),
        ],
      );
      _messageStreamController.add(quickReplyMessage);
    }
    else if (userMessage == 'Tell me more') {
      // Check if this is a duplicate message (same type sent in last 5 seconds)
      if (_lastResponseId != null && 
          _lastResponseTime != null && 
          DateTime.now().difference(_lastResponseTime!).inSeconds < 5 &&
          _lastResponseId!.contains('gif-message')) {
        print('Preventing duplicate GIF message');
        return;
      }
      
      // Store this response with a recognizable ID pattern
      _lastResponseId = 'gif-message-${DateTime.now().millisecondsSinceEpoch}';
      _lastResponseTime = DateTime.now();
      
      // Another GIF link message
      final anotherGifMessage = ChatMessage(
        id: _lastResponseId!,
        content: 'Reason #2 to quit smoking while you\'re young: Add a decade to your life and see the rise of fully automated smart homes; who needs to do chores when robots become a common commodity! https://quitxt.org/sites/quitxt/files/gifs/preq5_motiv2_automated_esp.gif',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );
      _messageStreamController.add(anotherGifMessage);
    }
    else {
      // Check if this is a duplicate default message (same ID generated in last 5 seconds)
      if (_lastResponseId != null && 
          _lastResponseTime != null && 
          DateTime.now().difference(_lastResponseTime!).inSeconds < 5 &&
          _lastResponseId!.contains('default-message')) {
        print('Preventing duplicate default message');
        return;
      }
      
      // Store this response with a recognizable ID pattern
      _lastResponseId = 'default-message-${DateTime.now().millisecondsSinceEpoch}';
      _lastResponseTime = DateTime.now();
      
      // For any other message, show a default response asking for more specific input
      final defaultMessage = ChatMessage(
        id: _lastResponseId!,
        content: 'I\'m not sure how to respond to that. Try one of these options:',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );
      _messageStreamController.add(defaultMessage);
      
      // Add quick reply buttons for standard options
      await Future.delayed(const Duration(milliseconds: 200));
      final quickReplyMessage = ChatMessage(
        id: '${_lastResponseId!}_replies',
        content: '',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.quickReply,
        suggestedReplies: [
          QuickReply(text: 'Hello, I\'m ready to quit!', value: 'Hello, I\'m ready to quit!'),
          QuickReply(text: '#deactivate', value: '#deactivate'),
          QuickReply(text: 'Tell me more', value: 'Tell me more'),
        ],
      );
      _messageStreamController.add(quickReplyMessage);
    }
  }
  
  // Send all test messages in sequence (useful for testing)
  Future<void> sendTestMessages() async {
    print("Sending test messages sequence...");
    // Message 1: YouTube video
    final youtubeMessage = ChatMessage(
      id: '0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
      content: 'Welcome to Quitxt from the UT Health Science Center! Congrats on your decision to quit smoking! See why we think you\'re awesome, Tap pic below https://youtu.be/ZWsR3G0mdJo',
      timestamp: DateTime.now(),
      isMe: false,
      type: MessageType.text,
    );
    _messageStreamController.add(youtubeMessage);
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Message 2: GIF link
    final gifMessage = ChatMessage(
      id: '1b2c3d4e-5f6a-7b8c-9d0e-1f2a3b4c5d6e',
      content: 'We\'re sorry to see you go. Here\'s a quick tip: Stay strong! https://quitxt.org/sites/quitxt/files/gifs/PreQ6_Hoverboard.gif',
      timestamp: DateTime.now(),
      isMe: false,
      type: MessageType.text,
    );
    _messageStreamController.add(gifMessage);
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Message 3: Poll with buttons
    final pollMessage = ChatMessage(
      id: '2c3d4e5f-6a7b-8c9d-0e1f-2a3b4c5d6e7f',
      content: 'Which of these benefits appeals to you the most?',
      timestamp: DateTime.now(),
      isMe: false,
      type: MessageType.text,
    );
    _messageStreamController.add(pollMessage);
    
    await Future.delayed(const Duration(milliseconds: 500));
    final quickReplyMessage = ChatMessage(
      id: '2c3d4e5f-6a7b-8c9d-0e1f-2a3b4c5d6e7f_replies',
      content: '',
      timestamp: DateTime.now(),
      isMe: false,
      type: MessageType.quickReply,
      suggestedReplies: [
        QuickReply(text: 'Better Health', value: 'Better Health'),
        QuickReply(text: 'Save Money', value: 'Save Money'),
        QuickReply(text: 'More Energy', value: 'More Energy'),
      ],
    );
    _messageStreamController.add(quickReplyMessage);
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Message 4: Another GIF link
    final anotherGifMessage = ChatMessage(
      id: '3d4e5f6a-7b8c-9d0e-1f2a-3b4c5d6e7f8a',
      content: 'Reason #2 to quit smoking while you\'re young: Add a decade to your life and see the rise of fully automated smart homes; who needs to do chores when robots become a common commodity! https://quitxt.org/sites/quitxt/files/gifs/preq5_motiv2_automated_esp.gif',
      timestamp: DateTime.now(),
      isMe: false,
      type: MessageType.text,
    );
    _messageStreamController.add(anotherGifMessage);
  }
  
  // Process sample test data
  Future<void> processSampleTestData() async {
    print("Processing sample test data...");
    
    try {
      // Just send all test messages
      await sendTestMessages();
      
      print("Sample test data processing completed.");
    } catch (e) {
      print("Error in processSampleTestData: $e");
      // As a fallback, try sending test messages directly
      try {
        await sendTestMessages();
      } catch (e2) {
        print("Error in fallback test messages: $e2");
      }
    }
  }
  
  // Process server responses
  Future<void> processServerResponses() async {
    try {
      print("Processing predefined server responses...");
      
      // List of predefined example responses showing different types of messages
      final responses = [
        {
          "serverMessageId": "example-1",
          "messageBody": "Welcome to Quitxt from the UT Health Science Center! Congrats on your decision to quit smoking!",
          "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
          "isPoll": false
        },
        {
          "serverMessageId": "example-2",
          "messageBody": "Welcome to Quitxt from the UT Health Science Center! Congrats on your decision to quit smoking! See why we think you're awesome, Tap pic below https://youtu.be/ZWsR3G0mdJo",
          "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
          "isPoll": false
        },
        {
          "serverMessageId": "example-3",
          "messageBody": "How many cigarettes do you smoke per day?",
          "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
          "isPoll": true,
          "questionsAnswers": {
            "Less than 5": "Less than 5",
            "5-10": "5-10",
            "11-20": "11-20",
            "More than 20": "More than 20"
          }
        },
        {
          "serverMessageId": "example-4",
          "messageBody": "Reason #1 to quit smoking while you're young: You'll have more time to enjoy hoverboards and flying cars. https://quitxt.org/sites/quitxt/files/gifs/PreQ6_Hoverboard.gif",
          "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
          "isPoll": false
        },
        {
          "serverMessageId": "example-5",
          "messageBody": "¡Bienvenido a Quitxt del UT Health Science Center! ¡Felicitaciones por su decisión de dejar de fumar!",
          "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
          "isPoll": false
        },
        {
          "serverMessageId": "example-6",
          "messageBody": "¿Cuántos cigarrillos fumas por día?",
          "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
          "isPoll": true,
          "questionsAnswers": {
            "Menos de 5": "Menos de 5",
            "5-10": "5-10",
            "11-20": "11-20", 
            "Más de 20": "Más de 20"
          }
        }
      ];
      
      // Process each response with a delay between them
      for (final response in responses) {
        // Wait for a moment to simulate real conversation flow
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Convert response to JSON and process it
        final jsonResponse = jsonEncode(response);
        final message = await processServerResponseJson(jsonResponse);
        
        // Add the message to the stream
        _messageStreamController.add(message);
        
        // If the message is a poll, add quick replies as a separate message
        if (response["isPoll"] == true && message.suggestedReplies?.isNotEmpty == true) {
          await Future.delayed(const Duration(milliseconds: 300));
          
          // Create a dedicated message for quick replies
          final quickReplyMessage = ChatMessage(
            id: "${message.id}_replies",
            content: "",
            timestamp: DateTime.now(),
            isMe: false,
            type: MessageType.quickReply,
            suggestedReplies: message.suggestedReplies,
          );
          
          _messageStreamController.add(quickReplyMessage);
        }
      }
      
      print("Finished processing predefined server responses");
    } catch (e) {
      print("Error in processServerResponses: $e");
    }
  }
  
  // Send a quick reply to the server
  Future<bool> sendQuickReply(String value, String text) async {
    return sendMessage(text);
  }
  
  // Process predefined server responses from JSON input
  Future<void> processPredefinedResponses(Map<String, dynamic> jsonInput) async {
    try {
      final List<dynamic> serverResponses = jsonInput['serverResponses'];
      if (serverResponses.isEmpty) {
        print('No server responses found in the input JSON');
        return;
      }

      // Add a small delay between messages for natural flow
      for (var i = 0; i < serverResponses.length; i++) {
        final response = serverResponses[i];
        await Future.delayed(Duration(milliseconds: 800));
        
        final messageId = response['serverMessageId'] ?? _uuid.v4();
        final messageBody = response['messageBody'] ?? '';
        final isPoll = response['isPoll'] ?? false;
        Map<String, dynamic>? questionsAnswers = response['questionsAnswers'];
        
        if (isPoll && questionsAnswers != null) {
          // Create quick replies for poll questions
          final List<QuickReply> quickReplies = [];
          questionsAnswers.forEach((text, value) {
            quickReplies.add(QuickReply(text: text, value: value));
          });
          
          // Add poll message with quick replies
          final message = ChatMessage(
            id: messageId,
            content: messageBody,
            timestamp: DateTime.now(),
            isMe: false,
            type: MessageType.quickReply,
            suggestedReplies: quickReplies,
          );
          
          _messageStreamController.add(message);
        } else {
          // Add regular text message
          final message = ChatMessage(
            id: messageId,
            content: messageBody,
            timestamp: DateTime.now(),
            isMe: false,
            type: MessageType.text,
          );
          
          _messageStreamController.add(message);
        }
      }
    } catch (e) {
      print('Error processing predefined responses: $e');
    }
  }
  
  // Process responses from custom JSON input
  Future<bool> processCustomJsonInput(String jsonInput) async {
    try {
      print('Processing custom JSON input');
      final Map<String, dynamic> data = jsonDecode(jsonInput);
      await processPredefinedResponses(data);
      return true;
    } catch (e) {
      print('Error processing custom JSON input: $e');
      return false;
    }
  }
  
  // Process interactive responses for specific user inputs
  Future<bool> processInteractiveResponses(String userInput) async {
    // Return false to bypass all prebuilt responses and always use the server
    print('Bypassing prebuilt responses for: $userInput');
    return false;
  }
  
  // Dispose resources
  void dispose() {
    _messageStreamController.close();
    _isInitialized = false;
  }

  // Reset the last message time to force a full refresh
  void resetLastMessageTime() {
    _lastFirestoreMessageTime = 0;
    print('Reset _lastFirestoreMessageTime to 0');
  }

  /// Takes a raw JSON text message from the server and processes it into a ChatMessage.
  /// This handles processing of response messages received from the server.
  /// 
  /// [serverResponseJson] should be a JSON string containing the server response data.
  /// 
  /// Returns a ChatMessage object ready to be added to the chat stream.
  Future<ChatMessage> processServerResponseJson(String serverResponseJson) async {
    try {
      // Parse the JSON string
      final Map<String, dynamic> responseData = jsonDecode(serverResponseJson);
      
      // Extract required fields
      final String messageId = responseData['serverMessageId'] ?? _uuid.v4();
      final String messageBody = responseData['messageBody'] ?? '';
      final bool isPoll = responseData['isPoll'] ?? false;
      final timestamp = responseData['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch((responseData['timestamp'] as int) * 1000)
          : DateTime.now();
      
      // Create the main message
      ChatMessage message = ChatMessage(
        id: messageId,
        content: messageBody,
        timestamp: timestamp,
        isMe: false,
        type: MessageType.text,
      );
      
      // If it's a poll message, add quick replies
      if (isPoll && responseData.containsKey('questionsAnswers')) {
        final questionsAnswers = responseData['questionsAnswers'] as Map<String, dynamic>?;
        if (questionsAnswers != null && questionsAnswers.isNotEmpty) {
          final List<QuickReply> quickReplies = [];
          questionsAnswers.forEach((key, value) {
            quickReplies.add(QuickReply(text: key, value: value.toString()));
          });
          
          // Create a new message with quick replies using copyWith
          message = message.copyWith(
            suggestedReplies: quickReplies
          );
        }
      }
      
      return message;
    } catch (e) {
      print('Error processing server response JSON: $e');
      // In case of error, return a fallback message
      return ChatMessage(
        id: _uuid.v4(),
        content: 'Error processing server response: $e',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );
    }
  }

  // Test connection to the server using the exact URL
  Future<bool> testConnection() async {
    if (!_isInitialized) {
      print('DashMessagingService not initialized, cannot test connection');
      return false;
    }
    
    // Double check that we're using the correct URL
    if (!_hostUrl.contains("/scheduler/mobile-app")) {
      print('Correcting server URL to include path for connection test');
      _hostUrl = "https://dashmessaging-com.ngrok.io/scheduler/mobile-app";
    }
    
    try {
      print('Testing connection to server: $_hostUrl');
      
      // Try to connect to the server
      final response = await http.get(
        Uri.parse(_hostUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      print('Server connection test response: ${response.statusCode}');
      
      // Any response means we can reach the server
      return response.statusCode >= 200;
    } catch (e) {
      print('Error testing connection to server: $e');
      return false;
    }
  }
  
  // Helper method to determine if a message is a poll/has quick replies
  bool isMessagePoll(dynamic isPollValue) {
    if (isPollValue == null) return false;
    
    // Convert various formats to a boolean
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
}