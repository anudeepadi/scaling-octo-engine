import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../services/dash_messaging_service.dart';
import '../utils/firebase_utils.dart';
import 'chat_provider.dart';

class DashChatProvider extends ChangeNotifier {
  final DashMessagingService _dashService = DashMessagingService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isTyping = false;
  bool get isTyping => _isTyping;
  
  // Constructor to set up Firestore listener
  DashChatProvider() {
    _setupMessageListener();
  }
  
  // Set up a Firestore listener to receive messages from the Dash server
  void _setupMessageListener() async {
    final userId = await FirebaseUtils.getCurrentUserId();
    if (userId == null) return;
    
    // Listen to the user's messages collection
    _firestore
        .collection('messages')
        .doc(userId)
        .collection('chat')
        .orderBy('createdAt', descending: true)
        .limit(50)  // Limit to the most recent 50 messages
        .snapshots()
        .listen((snapshot) {
          // Only process messages that came from the server
          final serverMessages = snapshot.docs
              .where((doc) => doc.data()['source'] == 'server')
              .map((doc) => doc.data())
              .toList();
          
          // Process any new server messages
          if (serverMessages.isNotEmpty) {
            _isTyping = false;
            notifyListeners();
          }
        });
  }
  
  // Send a message to the Dash messaging server
  Future<bool> sendMessage(String message) async {
    if (message.trim().isEmpty) return false;
    
    // Set typing indicator
    _isTyping = true;
    notifyListeners();
    
    // Send to Dash Messaging server
    final String? userId = await FirebaseUtils.getCurrentUserId();
    if (userId != null) {
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
      
      return true;
    }
    
    _isTyping = false;
    notifyListeners();
    return false;
  }
  
  // Handle quick reply selection
  Future<bool> handleQuickReply(QuickReply reply) async {
    _isTyping = true;
    notifyListeners();
    
    // Send to Dash Messaging server
    final String? userId = await FirebaseUtils.getCurrentUserId();
    if (userId != null) {
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
      
      return true;
    }
    
    _isTyping = false;
    notifyListeners();
    return false;
  }
  
  // Method to forward messages to ChatProvider for display
  void forwardMessagesToChatProvider(BuildContext context) async {
    final userId = await FirebaseUtils.getCurrentUserId();
    if (userId == null) return;
    
    // Get the most recent messages
    final messagesSnapshot = await _firestore
        .collection('messages')
        .doc(userId)
        .collection('chat')
        .orderBy('createdAt', descending: false)
        .limit(20)
        .get();
    
    if (messagesSnapshot.docs.isEmpty) return;
    
    // Get the chat provider to forward messages to
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Clear existing messages
    chatProvider.clearChatHistory();
    
    // Process messages from Dash messaging
    for (final doc in messagesSnapshot.docs) {
      final data = doc.data();
      final isMe = data['source'] == 'client';
      final content = data['messageBody'] ?? '';
      final timestamp = data['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch;
      
      // Check for poll/quick replies
      if (data['isPoll'] == 'y' || data['isPoll'] == true) {
        final List<String> answers = (data['answers'] as List<dynamic>?)?.cast<String>() ?? [];
        if (answers.isNotEmpty) {
          // Convert to quick replies
          final List<QuickReply> quickReplies = answers.map((answer) => 
            QuickReply(text: answer, value: answer)
          ).toList();
          
          // Add message with quick replies
          chatProvider.addQuickReplyMessage(quickReplies, isMe: false);
          continue;
        }
      }
      
      // Process regular messages
      if (content.isNotEmpty) {
        // Check message type from content
        final MessageType type = _determineMessageType(content);
        
        // Add to chat provider
        switch (type) {
          case MessageType.youtube:
          case MessageType.gif:
          case MessageType.image:
            chatProvider.sendMedia(content, type, fromDash: true);
            break;
          case MessageType.linkPreview:
            chatProvider.addLinkPreviewMessage(content, isMe: isMe);
            break;
          default:
            chatProvider.addTextMessage(content, isMe: isMe, fromDash: true);
            break;
        }
      }
    }
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
