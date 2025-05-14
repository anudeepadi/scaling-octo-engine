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

  // Initialize the service with user info
  Future<void> initialize(String userId) async {
    if (_isInitialized && userId == _userId) {
      print('DashMessagingService already initialized for user: $userId');
      return;
    }
    
    _userId = userId;
    _isInitialized = true;
    
    // Load host URL explicitly first
    await _loadHostUrl();
    
    // Load FCM token
    _fcmToken = await _loadFcmToken();
    print('FCM Token: $_fcmToken');
    
    // Load messages from Firestore on initialization
    await _loadExistingMessages();
    
    // Start polling for new messages
    startMessagePolling();
    
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
      
      // Get reference to the user's chat collection in Firestore
      final chatRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(_userId)
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .limit(50); // Load the last 50 messages
      
      final snapshot = await chatRef.get();
      
      if (snapshot.docs.isEmpty) {
        print('No existing messages found for user $_userId');
        return;
      }
      
      print('Found ${snapshot.docs.length} existing messages');
      
      // Process messages in reverse to maintain chronological order
      final messages = snapshot.docs.reversed.map((doc) {
        final data = doc.data();
        
        // Create ChatMessage from Firestore data
        String content = data['messageBody'] ?? '';
        bool isFromUser = (data['source'] == 'client');
        String messageId = data['serverMessageId'] ?? doc.id;
        
        // Parse timestamp
        DateTime timestamp;
        try {
          String createdAt = data['createdAt'] ?? '';
          if (createdAt.isNotEmpty) {
            // Convert string timestamp to int if needed
            int timeValue = int.tryParse(createdAt) ?? 0;
            // Convert milliseconds to DateTime
            timestamp = DateTime.fromMillisecondsSinceEpoch(timeValue);
          } else {
            timestamp = DateTime.now();
          }
        } catch (e) {
          print('Error parsing timestamp: $e');
          timestamp = DateTime.now();
        }
        
        // Create message object
        return ChatMessage(
          id: messageId,
          content: content,
          timestamp: timestamp,
          isMe: isFromUser,
          type: MessageType.text,
        );
      }).toList();
      
      // Add messages to the stream
      for (var message in messages) {
        _messageStreamController.add(message);
      }
      
      print('Loaded ${messages.length} messages from Firestore');
    } catch (e) {
      print('Error loading messages from Firestore: $e');
    }
  }

  // Send a message to the server - using exact format from main.py
  Future<bool> sendMessage(String text, {int eventTypeCode = 1}) async {
    if (_userId == null || _fcmToken == null) {
      print('User ID or FCM token is null. Will attempt to send to server anyway.');
      return false;
    }
    
    // Early deduplication check - prevent rapid duplicate sends of the same message
    if (_lastResponseTime != null && 
        DateTime.now().difference(_lastResponseTime!).inSeconds < 2 &&
        text.toLowerCase() == _lastMessageText?.toLowerCase()) {
      print('Preventing duplicate message: $text from user');
      return true; // Return success to avoid error handling in the UI
    }
    
    // Store this message text to prevent duplicates
    _lastMessageText = text;
    _lastResponseTime = DateTime.now();
    
    try {
      final messageId = _uuid.v4();
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000; // Convert to seconds
      
      // Double check that we're using the correct URL
      if (!_hostUrl.contains("/scheduler/mobile-app")) {
        print('Correcting server URL to include path');
        _hostUrl = "https://dashmessaging-com.ngrok.io/scheduler/mobile-app";
      }
      
      // Use the exact endpoint from main.py
      final endpoint = _hostUrl;
      
      // Create payload using exact structure from main.py
      final payload = {
        'userId': _userId,
        'messageId': messageId,
        'messageText': text,
        'messageTime': timestamp,
        'eventTypeCode': eventTypeCode,
        'fcmToken': _fcmToken,
      };
      
      print('Sending message to server: $payload');
      print('Using endpoint: $endpoint');
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));
      
      print('Send message response status: ${response.statusCode}');
      print('Send message response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 202) {
        print('Message sent successfully to server');
        
        // Parse the server response if any
        if (response.body.isNotEmpty) {
          try {
            final responseData = jsonDecode(response.body);
            
            // Add the user's message to the local chat
            final userMessage = ChatMessage(
              id: messageId,
              content: text,
              timestamp: DateTime.now(),
              isMe: true,
              type: MessageType.text,
            );
            _messageStreamController.add(userMessage);
            
            // Handle response data - check if there's a message to display
            if (responseData['messageBody'] != null) {
              final serverMessage = ChatMessage(
                id: responseData['messageId'] ?? _uuid.v4(),
                content: responseData['messageBody'],
                timestamp: DateTime.now(),
                isMe: false,
                type: MessageType.text,
              );
              _messageStreamController.add(serverMessage);
              
              // Add quick replies if available
              if (responseData['isPoll'] == true && responseData['answers'] != null) {
                final answers = responseData['answers'] as List;
                if (answers.isNotEmpty) {
                  final quickReplies = answers.map((item) => 
                    QuickReply(text: item.toString(), value: item.toString())
                  ).toList();
                  
                  final quickReplyMessage = ChatMessage(
                    id: '${serverMessage.id}_replies',
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
            print('Error parsing server response: $e');
          }
        } else {
          // If server doesn't send an immediate response, just add the user message
          final userMessage = ChatMessage(
            id: messageId,
            content: text,
            timestamp: DateTime.now(),
            isMe: true,
            type: MessageType.text,
          );
          _messageStreamController.add(userMessage);
        }
        
        return true;
      } else {
        print('Failed to send message. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending message: $e');
      print('Failed to send message to server');
      return false;
    }
  }
  
  // Periodically check for new messages in Firestore
  void startMessagePolling() {
    if (_userId == null) {
      print('Cannot start message polling, user ID is null');
      return;
    }
    
    // Cancel any existing timer
    _messagePollingTimer?.cancel();
    
    // Create a new timer that checks for messages every 30 seconds
    _messagePollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForNewMessages();
    });
    
    print('Started message polling for user: $_userId');
  }
  
  // Stop message polling
  void stopMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = null;
    print('Stopped message polling');
  }
  
  // Check for new messages in Firestore
  Future<void> _checkForNewMessages() async {
    if (_userId == null) {
      print('Cannot check for messages, user ID is null');
      return;
    }
    
    try {
      // Get the timestamp of the last message we processed
      final lastMessageTime = _lastFirestoreMessageTime ?? 0;
      
      print('Checking for new messages since: $lastMessageTime');
      
      // Query Firestore for new messages
      final chatRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(_userId)
          .collection('chat')
          .where('createdAt', isGreaterThan: lastMessageTime.toString())
          .orderBy('createdAt')
          .limit(20);
      
      final snapshot = await chatRef.get();
      
      if (snapshot.docs.isEmpty) {
        print('No new messages found');
        return;
      }
      
      print('Found ${snapshot.docs.length} new messages');
      
      // Process the new messages
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Skip messages from the client (user) as we already have those
        if (data['source'] == 'client') {
          continue;
        }
        
        // Create ChatMessage from Firestore data
        String content = data['messageBody'] ?? '';
        String messageId = data['serverMessageId'] ?? doc.id;
        
        // Parse timestamp
        DateTime timestamp;
        try {
          String createdAt = data['createdAt'] ?? '';
          if (createdAt.isNotEmpty) {
            // Convert string timestamp to int if needed
            int timeValue = int.tryParse(createdAt) ?? 0;
            
            // Update the last message time
            if (timeValue > _lastFirestoreMessageTime!) {
              _lastFirestoreMessageTime = timeValue;
            }
            
            // Convert milliseconds to DateTime
            timestamp = DateTime.fromMillisecondsSinceEpoch(timeValue);
          } else {
            timestamp = DateTime.now();
          }
        } catch (e) {
          print('Error parsing timestamp: $e');
          timestamp = DateTime.now();
        }
        
        // Create message object
        final message = ChatMessage(
          id: messageId,
          content: content,
          timestamp: timestamp,
          isMe: false,
          type: MessageType.text,
        );
        
        // Add to the stream
        _messageStreamController.add(message);
        
        // Check for quick replies
        if (data['isPoll'] == 'y' && data['answers'] != null) {
          try {
            List<String> answers = [];
            if (data['answers'] is String && data['answers'] != 'None') {
              // Parse comma-separated answers string
              answers = data['answers'].split(',').map((e) => e.trim()).toList();
            } else if (data['answers'] is List) {
              answers = List<String>.from(data['answers']);
            }
            
            if (answers.isNotEmpty) {
              final quickReplies = answers.map((item) => 
                QuickReply(text: item, value: item)
              ).toList();
              
              final quickReplyMessage = ChatMessage(
                id: '${message.id}_replies',
                content: '',
                timestamp: timestamp.add(const Duration(milliseconds: 100)),
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
      
      print('Processed ${snapshot.docs.length} new messages');
    } catch (e) {
      print('Error checking for new messages: $e');
    }
  }
  
  // Variable to track the last Firestore message timestamp
  int? _lastFirestoreMessageTime = 0;
  
  // Timer for polling messages
  Timer? _messagePollingTimer;

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
  
  // Send a quick reply to the server
  Future<bool> sendQuickReply(String value, String text) async {
    return sendMessage(text, eventTypeCode: 2);
  }
  
  // Process sample test data in the format provided
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
    
    // The code below is kept but not executed due to the early return above
    /*
    // Normalize user input by converting to lowercase and trimming
    final normalizedInput = userInput.toLowerCase().trim();
    
    try {
      // Basic greeting responses in English
      if (normalizedInput == "hello" || normalizedInput == "hi") {
        // Remove the first response and only send the YouTube link response
        final youtubeResponse = {
          "recipientId": "pUuutN05eoVeWhsKyXBiwRoFW9u1",
          "serverMessageId": "8f0e1d2c-3b4a-5d6e-7f8g-9h0i1j2k3l4m",
          "messageBody": "Welcome to Quitxt from the UT Health Science Center! Congrats on your decision to quit smoking! See why we think you're awesome, Tap pic below https://youtu.be/ZWsR3G0mdJo",
          "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
          "isPoll": false,
          "pollId": null,
          "fcmToken": "e-D8y5f8RoOcRgQl4AV18K:APA91bEdH6CwssC17yIKENOuLiW5eOxnE5CaOxqiOkKXdL4ZgnbOAk9s1_EX0w0E4G0c_zn5QD8X7W0-BHGooS2RyBcfHFYl8hfNEwYVcNIEConIJTyeJnhAnxlhD3OwayB6S_yeZXST",
          "questionsAnswers": null
        };
        
        await _sendServerResponse(youtubeResponse);
        return true;
      }
      
      // Rest of the method...
    } catch (e) {
      print('Error processing interactive response: $e');
    }
    
    // If we reach here, no interactive response matched
    return false;
    */
  }
  
  // Helper to send a server response based on a response object
  Future<void> _sendServerResponse(Map<String, dynamic> response) async {
    try {
      final messageBody = response['messageBody'] as String;
      final isPoll = response['isPoll'] as bool? ?? false;
      final serverMessageId = response['serverMessageId'] as String;
      Map<String, dynamic>? questionsAnswers = response['questionsAnswers'];
      
      if (isPoll && questionsAnswers != null) {
        // Create quick replies for poll questions
        final List<QuickReply> quickReplies = [];
        questionsAnswers.forEach((text, value) {
          quickReplies.add(QuickReply(text: text, value: value));
        });
        
        // Add message with poll question
        final message = ChatMessage(
          id: serverMessageId,
          content: messageBody,
          timestamp: DateTime.now(),
          isMe: false,
          type: MessageType.text,
        );
        
        _messageStreamController.add(message);
        
        // Add quick reply options after a short delay
        await Future.delayed(const Duration(milliseconds: 300));
        final quickReplyMessage = ChatMessage(
          id: '${serverMessageId}_replies',
          content: '',
          timestamp: DateTime.now(),
          isMe: false,
          type: MessageType.quickReply,
          suggestedReplies: quickReplies,
        );
        
        _messageStreamController.add(quickReplyMessage);
      } else {
        // Add regular text message
        final message = ChatMessage(
          id: serverMessageId,
          content: messageBody,
          timestamp: DateTime.now(),
          isMe: false,
          type: MessageType.text,
        );
        
        _messageStreamController.add(message);
      }
    } catch (e) {
      print('Error sending server response: $e');
    }
  }
  
  // Dispose resources
  void dispose() {
    _messageStreamController.close();
    _isInitialized = false;
  }

  // Process a complete demo conversation with predefined user messages and server responses
  Future<void> processDemoConversation() async {
    try {
      print('Starting demo conversation sequence...');
      
      final interactionPairs = [
        {"userMessage": "Hello", "serverResponse": "Welcome to Quitxt from the UT Health Science Center! Congrats on your decision to quit smoking!"},
        {"userMessage": "Hi", "serverResponse": "Welcome to Quitxt from the UT Health Science Center! Congrats on your decision to quit smoking! See why we think you're awesome, Tap pic below https://youtu.be/ZWsR3G0mdJo"},
        {"userMessage": "Hola", "serverResponse": "¡Bienvenido a Quitxt del UT Health Science Center! ¡Felicitaciones por su decisión de dejar de fumar!"},
        {"userMessage": "I want to quit smoking", "serverResponse": "How many cigarettes do you smoke per day?", "isPoll": true, "options": {
          "Less than 5": "Less than 5",
          "5-10": "5-10",
          "11-20": "11-20",
          "More than 20": "More than 20"
        }},
        {"userMessage": "5-10", "serverResponse": "Reason #1 to quit smoking while you're young: You'll have more time to enjoy hoverboards and flying cars. https://quitxt.org/sites/quitxt/files/gifs/PreQ6_Hoverboard.gif"},
        {"userMessage": "That's cool!", "serverResponse": "Drinking alcohol can trigger cravings for a cigarette and makes it harder for you to quit smoking. Tap pic below https://quitxt.org/binge-drinking"},
        {"userMessage": "Thanks for the info", "serverResponse": "Like the Avengers protect the earth, you are protecting your lungs from respiratory diseases and cancer! Stay SUPER and quit smoking! https://quitxt.org/sites/quitxt/files/gifs/App1_Cue1_Avengers.gif"},
        {"userMessage": "That's motivation!", "serverResponse": "Reason #2 to quit smoking while you're young: Add a decade to your life and see the rise of fully automated smart homes; who needs to do chores when robots become a common commodity! https://quitxt.org/sites/quitxt/files/gifs/App1-Motiv2_automated_home.gif"},
        {"userMessage": "Me gustaría recibir mensajes en español", "serverResponse": "Beber alcohol puede provocar los deseos de fumar y te hace más difícil dejar el cigarrillo. Clic el pic abajo https://quitxt.org/spanish/consumo-intensivo-de-alcohol"},
        {"userMessage": "Gracias", "serverResponse": "Como los Avengers protegen el planeta, ¡tú estás protegiendo tus pulmones de enfermedades respiratorias y de cáncer! ¡Sigue SUPER y deja de fumar!"},
        {"userMessage": "Muy inspirador", "serverResponse": "Razón #2 para dejar de fumar siendo joven: ¡ganarás 10 años de vida y verás el aumento de las casas inteligentes; ¡quién necesita limpiar la casa cuando los robots lo harán por ti! https://quitxt.org/sites/quitxt/files/gifs/preq5_motiv2_automated_esp.gif"},
        {"userMessage": "Buena razón", "serverResponse": "¿Cuántos cigarrillos fumas por día?", "isPoll": true, "options": {
          "Menos de 5": "Menos de 5",
          "5-10": "5-10",
          "11-20": "11-20",
          "Más de 20": "Más de 20"
        }},
        {"userMessage": "5-10", "serverResponse": "¡Gracias por la información! Estamos aquí para ayudarte a reducir y eventualmente dejar de fumar por completo."},
        {"userMessage": "#deactivate", "serverResponse": "Hemos desactivado tu cuenta. Si deseas volver a usar nuestros servicios en el futuro, simplemente envía un mensaje y estaremos aquí para ayudarte."},
        {"userMessage": "EXIT", "serverResponse": "You have been unsubscribed from the QuiTXT program. If you would like to rejoin in the future, simply text back to this number."},
        {"userMessage": "SALIR", "serverResponse": "Has sido dado de baja del programa QuiTXT. Si deseas volver a unirte en el futuro, simplemente envía un mensaje a este número."}
      ];
      
      for (final pair in interactionPairs) {
        // Add user message
        final userMsg = ChatMessage(
          id: _uuid.v4(),
          content: pair["userMessage"] as String,
          timestamp: DateTime.now(),
          isMe: true,
          type: MessageType.text,
        );
        _messageStreamController.add(userMsg);
        
        // Wait a moment
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Add server response
        final bool isPoll = pair["isPoll"] as bool? ?? false;
        if (isPoll) {
          // Create text message
          final serverMsg = ChatMessage(
            id: _uuid.v4(),
            content: pair["serverResponse"] as String,
            timestamp: DateTime.now(),
            isMe: false,
            type: MessageType.text,
          );
          _messageStreamController.add(serverMsg);
          
          // Wait a short time
          await Future.delayed(const Duration(milliseconds: 300));
          
          // Create poll options
          final options = pair["options"] as Map<String, dynamic>;
          final List<QuickReply> quickReplies = [];
          options.forEach((text, value) {
            quickReplies.add(QuickReply(text: text, value: value.toString()));
          });
          
          // Add poll message
          final pollMsg = ChatMessage(
            id: "${_uuid.v4()}_poll",
            content: "",
            timestamp: DateTime.now(),
            isMe: false,
            type: MessageType.quickReply,
            suggestedReplies: quickReplies,
          );
          _messageStreamController.add(pollMsg);
          
        } else {
          // Just add the text message
          final serverMsg = ChatMessage(
            id: _uuid.v4(),
            content: pair["serverResponse"] as String,
            timestamp: DateTime.now(),
            isMe: false,
            type: MessageType.text,
          );
          _messageStreamController.add(serverMsg);
        }
        
        // Wait between message pairs
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      
      print('Demo conversation complete');
    } catch (e) {
      print('Error in demo conversation: $e');
    }
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

  /// Processes predefined server responses to demonstrate various message formats.
  /// 
  /// This method sends a series of example server messages to show different types
  /// of content that can be received from the server, including:
  ///
  /// - Plain text messages
  /// - Messages with URLs
  /// - Poll messages with multiple choice options
  /// - Responses in both English and Spanish
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
}