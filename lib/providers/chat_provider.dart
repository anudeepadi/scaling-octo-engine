import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../models/link_preview.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

// Simple class to represent a chat conversation
class ChatConversation {
  final String id;
  final String name;
  final DateTime lastMessageTime;
  final List<ChatMessage> messages;
  final String? lastMessagePreview;

  ChatConversation({
    required this.id,
    required this.name,
    required this.lastMessageTime,
    required this.messages,
    this.lastMessagePreview,
  });
}

// Simple demo chat provider with no Firebase dependencies
class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  // Add list of chat conversations
  final List<ChatConversation> _conversations = [];
  List<ChatConversation> get conversations => _conversations;

  // Current active conversation ID
  String? _currentConversationId;
  String? get currentConversationId => _currentConversationId;

  final _uuid = Uuid();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  ChatProvider() {
    print('ChatProvider: Initializing in demo mode');
    _initializeDemoConversations();
  }

  // Initialize with demo conversations
  void _initializeDemoConversations() {
    // Create a default conversation
    final defaultConversationId = _uuid.v4();
    _conversations.add(
      ChatConversation(
        id: defaultConversationId,
        name: 'New Chat',
        lastMessageTime: DateTime.now(),
        messages: [],
        lastMessagePreview: null,
      )
    );

    // Set current conversation
    _currentConversationId = defaultConversationId;

    // Load demo messages for the current conversation
    _loadDemoMessages();
  }

  // Create a new conversation
  void createNewConversation(String name) {
    final newId = _uuid.v4();
    _conversations.add(
      ChatConversation(
        id: newId,
        name: name,
        lastMessageTime: DateTime.now(),
        messages: [],
      )
    );

    // Set as current conversation
    _currentConversationId = newId;

    // Clear messages for the new conversation
    _messages.clear();

    notifyListeners();
  }

  // Switch to a different conversation
  void switchConversation(String conversationId) {
    // Save current messages to the current conversation
    if (_currentConversationId != null) {
      final currentIndex = _conversations.indexWhere((conv) => conv.id == _currentConversationId);
      if (currentIndex >= 0) {
        _conversations[currentIndex] = ChatConversation(
          id: _conversations[currentIndex].id,
          name: _conversations[currentIndex].name,
          lastMessageTime: _conversations[currentIndex].lastMessageTime,
          messages: List.from(_messages),
          lastMessagePreview: _messages.isNotEmpty ? _getMessagePreview(_messages.last) : null,
        );
      }
    }

    // Set new current conversation
    _currentConversationId = conversationId;

    // Load messages for the selected conversation
    final selectedConversation = _conversations.firstWhere((conv) => conv.id == conversationId);
    _messages.clear();
    _messages.addAll(selectedConversation.messages);

    // If conversation is empty, add welcome message
    if (_messages.isEmpty) {
      _loadDemoMessages();
    }

    notifyListeners();
  }

  // Get message preview text for sidebar
  String _getMessagePreview(ChatMessage message) {
    switch (message.type) {
      case MessageType.text:
        return message.content.length > 30
          ? '${message.content.substring(0, 27)}...'
          : message.content;
      case MessageType.image:
        return '📷 Image';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.gif:
        return '🎭 GIF';
      case MessageType.file:
        return '📄 File';
      case MessageType.youtube:
        return '📺 YouTube';
      case MessageType.quickReply:
        return '💬 Quick Replies';
      case MessageType.linkPreview:
        return '🔗 Link';
      default:
        return 'Message';
    }
  }

  // Delete a conversation
  void deleteConversation(String conversationId) {
    // Remove the conversation
    _conversations.removeWhere((conv) => conv.id == conversationId);

    // If we deleted the current conversation, switch to another one
    if (_currentConversationId == conversationId) {
      if (_conversations.isNotEmpty) {
        _currentConversationId = _conversations.first.id;
        _messages.clear();
        _messages.addAll(_conversations.first.messages);
      } else {
        // If no conversations left, create a new one
        createNewConversation('New Chat');
      }
    }

    notifyListeners();
  }

  // Rename a conversation
  void renameConversation(String conversationId, String newName) {
    final index = _conversations.indexWhere((conv) => conv.id == conversationId);
    if (index >= 0) {
      _conversations[index] = ChatConversation(
        id: _conversations[index].id,
        name: newName,
        lastMessageTime: _conversations[index].lastMessageTime,
        messages: _conversations[index].messages,
        lastMessagePreview: _conversations[index].lastMessagePreview,
      );
      notifyListeners();
    }
  }

  // Add a method to set the entire list of messages
  void setMessages(List<ChatMessage> messages) {
    _messages.clear();
    _messages.addAll(messages);
    // Ensure the last message preview is updated if needed
    if (_currentConversationId != null) {
      final currentIndex = _conversations.indexWhere((conv) => conv.id == _currentConversationId);
      if (currentIndex >= 0) {
        _conversations[currentIndex] = ChatConversation(
          id: _conversations[currentIndex].id,
          name: _conversations[currentIndex].name,
          lastMessageTime: _messages.isNotEmpty ? _messages.last.timestamp : _conversations[currentIndex].lastMessageTime,
          messages: List.from(_messages), // Ensure conversation has the new messages
          lastMessagePreview: _messages.isNotEmpty ? _getMessagePreview(_messages.last) : null,
        );
      }
    }
    notifyListeners();
  }

  // Clear chat history
  void clearChatHistory() {
    _messages.clear();
    notifyListeners();
  }

  // Add a text message
  void addTextMessage(String text, {bool isMe = false}) {
    // Check for duplicate messages to prevent displaying multiple instances of the same message
    if (_messages.isNotEmpty) {
      final lastMessage = _messages.last;
      // If the last message has the same content, is from the same user, and was sent within 2 seconds
      if (lastMessage.content == text && 
          lastMessage.isMe == isMe &&
          DateTime.now().difference(lastMessage.timestamp).inSeconds < 2) {
        print('Preventing duplicate message: $text from ${isMe ? "user" : "server"}');
        return; // Skip adding this duplicate message
      }
      
      // Also check if any message in the last 5 messages has the exact same content and sender
      final recentMessages = _messages.length > 5 ? _messages.sublist(_messages.length - 5) : _messages;
      for (final message in recentMessages) {
        if (message.content == text && 
            message.isMe == isMe &&
            DateTime.now().difference(message.timestamp).inSeconds < 5) {
          print('Preventing recent duplicate message: $text from ${isMe ? "user" : "server"}');
          return; // Skip adding this duplicate message
        }
      }
    }
    
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        content: text,
        type: MessageType.text,
        isMe: isMe,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  // Add a quick reply message
  void addQuickReplyMessage(List<QuickReply> replies) {
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        content: '',
        type: MessageType.quickReply,
        isMe: false,
        timestamp: DateTime.now(),
        quickReplies: replies,
      ),
    );
    notifyListeners();
  }

  // Add a media message
  void sendMedia(String path, MessageType type) {
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        content: path,
        type: type,
        isMe: true,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
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
  }

  // Load demo messages
  void _loadDemoMessages() {
    // Add welcome message
    addTextMessage('Welcome to Dash Messaging! 👋', isMe: false);
    
    // Add some quick replies
    addQuickReplyMessage([
      QuickReply(text: '👋 Hello!', value: 'Hello!'),
      QuickReply(text: '🤔 What can you do?', value: 'What can you do?'),
      QuickReply(text: '🔍 Tell me more', value: 'Tell me more'),
    ]);
  }
}