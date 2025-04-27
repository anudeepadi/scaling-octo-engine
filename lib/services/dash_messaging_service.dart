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

class DashMessagingService {
  static final DashMessagingService _instance = DashMessagingService._internal();
  factory DashMessagingService() => _instance;
  DashMessagingService._internal();

  // Server host URL (configurable)
  String _hostUrl = "https://dashmessaging-com.ngrok.io";
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

  // Initialize the service with user ID and FCM token
  Future<void> initialize(String userId, String fcmToken) async {
    if (_isInitialized) return;
    
    _userId = userId;
    _fcmToken = fcmToken;
    _isInitialized = true;
    
    // Load host URL from shared preferences
    await _loadHostUrl();
    
    print('DashMessagingService initialized for user: $userId');
    print('Using host URL: $_hostUrl');
    print('FCM Token: $fcmToken');
    
    // Send a test message to the server to check connection
    await testConnection();
  }

  // Load host URL from shared preferences
  Future<void> _loadHostUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('hostUrl');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _hostUrl = savedUrl;
      }
    } catch (e) {
      print('Error loading host URL: $e');
    }
  }

  // Update host URL and save to shared preferences
  Future<void> updateHostUrl(String newUrl) async {
    if (newUrl.isEmpty) return;
    
    try {
      _hostUrl = newUrl;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hostUrl', newUrl);
      print('Host URL updated to: $newUrl');
      
      // Test connection with new URL
      await testConnection();
    } catch (e) {
      print('Error updating host URL: $e');
      throw Exception('Failed to update host URL: $e');
    }
  }

  // Test connection to the server
  Future<bool> testConnection() async {
    if (!_isInitialized) {
      throw Exception('DashMessagingService not initialized');
    }
    
    try {
      final endpoint = '$_hostUrl/scheduler/test-connection';
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'User-ID': _userId ?? '',
          'FCM-Token': _fcmToken ?? '',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        print('Connection test successful');
        return true;
      } else {
        print('Connection test failed. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Connection test error: $e');
      return false;
    }
  }

  // Send a message to the server
  Future<bool> sendMessage(String text, {int eventTypeCode = 1}) async {
    if (_userId == null || _fcmToken == null) {
      print('User ID or FCM token is null. Using simulation mode.');
      await simulateServerResponse(text);
      return true;
    }
    
    // Handle special test command to load sample data
    if (text.toLowerCase() == '#test' || text.toLowerCase() == '#sample') {
      print('Processing sample test data command: $text');
      await processSampleTestData();
      return true;
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final messageId = _uuid.v4();
    
    // If not initialized, use simulation
    if (!_isInitialized) {
      print('DashMessagingService not initialized. Using simulation mode for: $text');
      await simulateServerResponse(text);
      return true;
    }
    
    try {
      final endpoint = '$_hostUrl/scheduler/mobile-app';
      final payload = {
        'userId': _userId,
        'messageId': messageId,
        'messageText': text,
        'messageTime': timestamp,
        'eventTypeCode': eventTypeCode,
        'fcmToken': _fcmToken,
      };
      
      print('Sending message to server: $payload');
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 202) {
        print('Message sent successfully');
        return true;
      } else {
        print('Failed to send message. Status: ${response.statusCode}, Body: ${response.body}');
        // Fallback to simulation if server fails
        await simulateServerResponse(text);
        return false;
      }
    } catch (e) {
      print('Error sending message: $e');
      // Fallback to simulation on error
      await simulateServerResponse(text);
      return false;
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
    // Add a small delay to simulate network latency
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Determine which mock response to send based on the user message
    if (userMessage.toLowerCase().contains('hello') || userMessage.toLowerCase().contains('hi')) {
      // YouTube link message
      final youtubeMessage = ChatMessage(
        id: '0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        content: 'Welcome to Quitxt from the UT Health Science Center! Congrats on your decision to quit smoking! See why we think you\'re awesome, Tap pic below https://youtu.be/ZWsR3G0mdJo',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );
      _messageStreamController.add(youtubeMessage);
    } 
    else if (userMessage.toLowerCase().contains('deactivate')) {
      // GIF link message
      final gifMessage = ChatMessage(
        id: '1b2c3d4e-5f6a-7b8c-9d0e-1f2a3b4c5d6e',
        content: 'We\'re sorry to see you go. Here\'s a quick tip: Stay strong! https://quitxt.org/sites/quitxt/files/gifs/PreQ6_Hoverboard.gif',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );
      _messageStreamController.add(gifMessage);
    }
    else if (userMessage.toLowerCase().contains('benefit') || userMessage.contains('appeal')) {
      // Poll message with buttons
      final pollMessage = ChatMessage(
        id: '2c3d4e5f-6a7b-8c9d-0e1f-2a3b4c5d6e7f',
        content: 'Which of these benefits appeals to you the most?',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );
      _messageStreamController.add(pollMessage);
      
      // Add quick reply buttons
      await Future.delayed(const Duration(milliseconds: 200));
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
    }
    else if (userMessage.toLowerCase().contains('more') || userMessage.toLowerCase().contains('tell')) {
      // Another GIF link message
      final anotherGifMessage = ChatMessage(
        id: '3d4e5f6a-7b8c-9d0e-1f2a-3b4c5d6e7f8a',
        content: 'Reason #2 to quit smoking while you\'re young: Add a decade to your life and see the rise of fully automated smart homes; who needs to do chores when robots become a common commodity! https://quitxt.org/sites/quitxt/files/gifs/preq5_motiv2_automated_esp.gif',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );
      _messageStreamController.add(anotherGifMessage);
    }
    else {
      // Default response with all test messages in sequence
      await sendTestMessages();
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
      // First, add an acknowledgment message
      final ackMessage = ChatMessage(
        id: 'ack-${DateTime.now().millisecondsSinceEpoch}',
        content: 'Loading sample test messages...',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );
      _messageStreamController.add(ackMessage);
      
      // Allow UI to update
      await Future.delayed(const Duration(milliseconds: 500));
        
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
  
  // Dispose resources
  void dispose() {
    _messageStreamController.close();
    _isInitialized = false;
  }
}