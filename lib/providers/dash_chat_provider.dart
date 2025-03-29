import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../services/dash_messaging_service.dart';
import '../utils/firebase_utils.dart';
import 'chat_provider.dart';

class DashChatProvider extends ChangeNotifier {
  final DashMessagingService _dashService = DashMessagingService();
  final dynamic _firestore; // Changed to dynamic to avoid Firebase imports if not needed
  
  bool _isTyping = false;
  bool get isTyping => _isTyping;
  
  // Constructor for use with Firebase
  // This won't be called in demo mode
  DashChatProvider() : _firestore = null {
    print('DashChatProvider: Creating with Firebase disabled');
  }
  
  // Constructor for creating without Firebase
  factory DashChatProvider.withoutFirebase() {
    print('DashChatProvider: Creating without Firebase');
    return DashChatProvider._internal();
  }
  
  // Internal constructor
  DashChatProvider._internal() : _firestore = null;
  
  // Send a message to the Dash messaging server
  Future<bool> sendMessage(String message) async {
    if (message.trim().isEmpty) return false;
    
    // Set typing indicator
    _isTyping = true;
    notifyListeners();
    
    // In demo mode, just simulate a response
    try {
      // Generate a simple user ID
      final String userId = 'demo_user_${DateTime.now().millisecondsSinceEpoch}';
      
      final success = await _dashService.sendMessage(
        userId: userId,
        messageText: message,
        eventTypeCode: 1, // Regular text message
      );
      
      if (!success) {
        _isTyping = false;
        notifyListeners();
        return false;
      }
      
      _isTyping = false;
      notifyListeners();
      return true;
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
    
    // In demo mode, just simulate a response
    try {
      // Generate a simple user ID
      final String userId = 'demo_user_${DateTime.now().millisecondsSinceEpoch}';
      
      final success = await _dashService.sendMessage(
        userId: userId,
        messageText: reply.value,
        eventTypeCode: 2, // Quick reply
      );
      
      if (!success) {
        _isTyping = false;
        notifyListeners();
        return false;
      }
      
      _isTyping = false;
      notifyListeners();
      return true;
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
    chatProvider.addTextMessage('Welcome to Quitxt! 👋', isMe: false);
    
    // Add message with quick replies
    final List<QuickReply> quickReplies = [
      QuickReply(text: '👋 Hello!', value: 'Hello!'),
      QuickReply(text: '🤔 What can you do?', value: 'What can you do?'),
      QuickReply(text: '🔍 Tell me more', value: 'Tell me more about this app'),
    ];
    
    chatProvider.addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'How can I help you today?',
        isMe: false,
        timestamp: DateTime.now(),
        type: MessageType.geminiQuickReply,
        suggestedReplies: quickReplies,
        status: MessageStatus.delivered,
      )
    );
    
    print('Adding test Gemini quick replies');
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