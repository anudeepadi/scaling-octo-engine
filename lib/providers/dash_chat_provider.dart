import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../services/dash_messaging_service.dart';
import '../utils/firebase_utils.dart';
import 'chat_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_connection_service.dart';

class DashChatProvider extends ChangeNotifier {
  final DashMessagingService _dashService = DashMessagingService();
  final dynamic _firestore; // Will be FirebaseFirestore when available
  final FirebaseConnectionService? _firebaseService;

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  // Constructor for use with Firebase
  DashChatProvider() 
      : _firestore = FirebaseFirestore.instance,
        _firebaseService = FirebaseConnectionService() {
    print('DashChatProvider: Creating with Firebase enabled');
    _setupFirebaseListeners();
  }

  // Constructor for creating without Firebase
  factory DashChatProvider.withoutFirebase() {
    print('DashChatProvider: Creating without Firebase');
    return DashChatProvider._internal();
  }

  // Internal constructor
  DashChatProvider._internal() 
      : _firestore = null,
        _firebaseService = null;
        
  // Setup Firebase message listeners
  void _setupFirebaseListeners() {
    try {
      if (_firestore != null) {
        print('Setting up Firebase message listeners');
        // This would set up Firestore listeners in a real implementation
      }
    } catch (e) {
      print('Error setting up Firebase listeners: $e');
    }
  }

  // Send a message to the Dash messaging server
  Future<bool> sendMessage(String message) async {
    if (message.trim().isEmpty) return false;

    // Set typing indicator
    _isTyping = true;
    notifyListeners();

    try {
      // Generate a user ID - in real implementation this would come from Firebase Auth
      final String userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      
      // If Firebase is available, use the Firebase service
      if (_firebaseService != null) {
        print('Sending message via Firebase: $message');
        final success = await _firebaseService!.sendDashMessage(
          userId: userId,
          messageText: message,
          eventTypeCode: 1, // Regular text message
        );
        
        _isTyping = false;
        notifyListeners();
        return success;
      } else {
        // Fall back to the regular dash service
        final success = await _dashService.sendMessage(
          userId: userId,
          messageText: message,
          eventTypeCode: 1, // Regular text message
        );

        _isTyping = false;
        notifyListeners();
        return success;
      }
    } catch (e) {
      print('Error sending message: $e');
      _isTyping = false;
      notifyListeners();
      return false;
    }
  }

  // Handle quick reply selection
  Future<bool> handleQuickReply(QuickReply reply) async {
    _isTyping = true;
    notifyListeners();

    try {
      // Generate a user ID - in real implementation this would come from Firebase Auth
      final String userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      
      // If Firebase is available, use the Firebase service
      if (_firebaseService != null) {
        print('Sending quick reply via Firebase: ${reply.value}');
        final success = await _firebaseService!.sendDashMessage(
          userId: userId,
          messageText: reply.value,
          eventTypeCode: 2, // Quick reply
        );
        
        _isTyping = false;
        notifyListeners();
        return success;
      } else {
        // Fall back to the regular dash service
        final success = await _dashService.sendMessage(
          userId: userId,
          messageText: reply.value,
          eventTypeCode: 2, // Quick reply
        );

        _isTyping = false;
        notifyListeners();
        return success;
      }
    } catch (e) {
      print('Error handling quick reply: $e');
      _isTyping = false;
      notifyListeners();
      return false;
    }
  }

  // Method to forward messages to ChatProvider for display
  void forwardMessagesToChatProvider(BuildContext context) {
    // In demo mode, just create sample messages
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Clear existing messages
    chatProvider.clearChatHistory();

    // Create test messages
    chatProvider.addTextMessage('Welcome to Dash Messaging! 👋', isMe: false);

    // Add message with quick replies
    final List<QuickReply> quickReplies = [
      QuickReply(text: '👋 Hello!', value: 'Hello!'),
      QuickReply(text: '🤔 What can you do?', value: 'What can you do?'),
      QuickReply(text: '🔍 Tell me more', value: 'Tell me more about this app'),
    ];

    chatProvider.addQuickReplyMessage(quickReplies);
  }

  // Determine message type based on content
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
}