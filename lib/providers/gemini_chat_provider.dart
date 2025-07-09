import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../services/gemini_service.dart';
import 'package:uuid/uuid.dart';
import '../utils/debug_config.dart';

class GeminiChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  final GeminiService _geminiService = GeminiService();
  final _uuid = Uuid();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  GeminiChatProvider() {
    _initializeChat();
  }

  void _initializeChat() {
    // Add welcome message
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        content: 'Hello! I\'m Gemini, a large language model from Google AI. How can I help you today?',
        type: MessageType.text,
        isMe: false,
        timestamp: DateTime.now(),
      ),
    );
    
    // Add initial quick replies
    _addQuickReplies([
      QuickReply(text: '👋 Hello', value: 'Hello'),
      QuickReply(text: '🤔 What can you do?', value: 'What can you do?'),
      QuickReply(text: '😄 Tell me a joke', value: 'Tell me a joke'),
    ]);
    
    notifyListeners();
  }

  // Clear chat history
  void clearChatHistory() {
    _messages.clear();
    _initializeChat();
    notifyListeners();
  }

  // Add a user message and generate a response
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    final userMessageId = _uuid.v4();
    DebugConfig.debugPrint('[GeminiProvider.sendMessage] START - User message: "$message" (ID: $userMessageId)');
    DebugConfig.debugPrint('[GeminiProvider.sendMessage] Messages BEFORE user add: ${_messages.length}');

    // Add user message
    _messages.add(
      ChatMessage(
        id: userMessageId, // Use generated ID
        content: message,
        type: MessageType.text,
        isMe: true,
        timestamp: DateTime.now(),
      ),
    );
    DebugConfig.debugPrint('[GeminiProvider.sendMessage] Messages AFTER user add: ${_messages.length}');
    notifyListeners();
    DebugConfig.debugPrint('[GeminiProvider.sendMessage] Notified after user add.');

    // Show loading indicator
    _isLoading = true;
    notifyListeners();
    DebugConfig.debugPrint('[GeminiProvider.sendMessage] Notified for loading start.');

    String geminiResponseContent = '';
    String geminiMessageId = '';
    try {
      // Generate response from Gemini
      DebugConfig.debugPrint('[GeminiProvider.sendMessage] Calling GeminiService...');
      final response = await _geminiService.generateResponse(message);
      geminiResponseContent = response; // Store response content
      geminiMessageId = _uuid.v4(); // Generate ID for Gemini message
      DebugConfig.debugPrint('[GeminiProvider.sendMessage] Gemini response received: "$geminiResponseContent" (ID: $geminiMessageId)');
      DebugConfig.debugPrint('[GeminiProvider.sendMessage] Messages BEFORE Gemini add: ${_messages.length}');

      // Add Gemini response
      _messages.add(
        ChatMessage(
          id: geminiMessageId, // Use generated ID
          content: response,
          type: MessageType.text,
          isMe: false,
          timestamp: DateTime.now(),
        ),
      );
      DebugConfig.debugPrint('[GeminiProvider.sendMessage] Messages AFTER Gemini add: ${_messages.length}');

      // Get suggested replies (using the mock service for now)
      DebugConfig.debugPrint('[GeminiProvider.sendMessage] Calling getSuggestedReplies...');
      final replies = await _geminiService.getSuggestedReplies(response); 
      if (replies.isNotEmpty) {
         _addQuickReplies(replies);
         DebugConfig.debugPrint('[GeminiProvider.sendMessage] Quick replies added. Count: ${replies.length}');
      } else {
         DebugConfig.debugPrint('[GeminiProvider.sendMessage] No quick replies generated.');
      }
      // DebugConfig.debugPrint('[GeminiProvider.sendMessage] Quick replies added.'); // Optional log for replies

      _error = null;
    } catch (e) {
      _error = 'Failed to generate response: $e';
      DebugConfig.debugPrint('[GeminiProvider.sendMessage] ERROR: $_error');
    } finally {
      _isLoading = false;
      DebugConfig.debugPrint('[GeminiProvider.sendMessage] FINALLY block - Loading false.');
      notifyListeners();
      DebugConfig.debugPrint('[GeminiProvider.sendMessage] Notified in finally block. Final message count: ${_messages.length}');
    }
  }

  // Add quick replies as a separate message
  void _addQuickReplies(List<QuickReply> replies) {
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        content: '',
        type: MessageType.quickReply,
        isMe: false,
        timestamp: DateTime.now(),
        suggestedReplies: replies,
      ),
    );
  }

  // Add a GIF message
  void addGifMessage(String gifPath) {
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        content: gifPath,
        type: MessageType.gif,
        isMe: true,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
    
    // After sending a GIF, generate a response
    _respondToMedia();
  }

  // Generate a response to media content
  Future<void> _respondToMedia() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Add a response to the media
      _messages.add(
        ChatMessage(
          id: _uuid.v4(),
          content: "That's a nice media content! Is there anything specific you'd like to discuss?",
          type: MessageType.text,
          isMe: false,
          timestamp: DateTime.now(),
        ),
      );

      // Add quick replies
      _addQuickReplies([
        QuickReply(text: '👍 Thanks!', value: 'Thanks!'),
        QuickReply(text: '🤔 Tell me more about it', value: 'Tell me more about it'),
        QuickReply(text: '🔄 Change topic', value: 'Let\'s talk about something else'),
      ]);

      _error = null;
    } catch (e) {
      _error = 'Failed to generate response: $e';
      DebugConfig.debugPrint(_error ?? 'Unknown error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 