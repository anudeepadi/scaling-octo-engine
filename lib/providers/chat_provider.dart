import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../utils/debug_config.dart';
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
    DebugConfig.debugPrint('ChatProvider: Initializing in demo mode');
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

    // Skip loading demo messages - keep conversations empty
    print('Conversation switched - keeping empty without demo messages');

    notifyListeners();
  }

  // Get message preview text for sidebar
  String _getMessagePreview(ChatMessage message) {
    if (message.content.isNotEmpty) {
      return message.content.length > 50 
          ? '${message.content.substring(0, 50)}...'
          : message.content;
    }
    
    // Handle special message types
    switch (message.type) {
      case MessageType.image:
        return '📷 Image';
      case MessageType.gif:
        return '🎬 GIF';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.file:
        return '📎 File';
      case MessageType.voice:
        return '🎤 Voice message';
      case MessageType.quickReply:
        return '💬 Quick reply options';
      default:
        return 'Message';
    }
  }

  // Delete a conversation
  void deleteConversation(String conversationId) {
    _conversations.removeWhere((conv) => conv.id == conversationId);
    
    // If the deleted conversation was current, switch to another one
    if (_currentConversationId == conversationId) {
      if (_conversations.isNotEmpty) {
        switchConversation(_conversations.first.id);
      } else {
        // Create a new default conversation
        _initializeDemoConversations();
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

  // Get current conversation
  ChatConversation? getCurrentConversation() {
    if (_currentConversationId == null) return null;
    
    try {
      return _conversations.firstWhere((conv) => conv.id == _currentConversationId);
    } catch (e) {
      return null;
    }
  }

  // Update current conversation's last message time
  void _updateCurrentConversationTime() {
    if (_currentConversationId != null && _messages.isNotEmpty) {
      final currentIndex = _conversations.indexWhere((conv) => conv.id == _currentConversationId);
      if (currentIndex >= 0) {
        _conversations[currentIndex] = ChatConversation(
          id: _conversations[currentIndex].id,
          name: _conversations[currentIndex].name,
          lastMessageTime: _messages.last.timestamp,
          messages: _conversations[currentIndex].messages,
          lastMessagePreview: _getMessagePreview(_messages.last),
        );
      }
    }
  }

  // Set messages directly (called by DashChatProvider)
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

  // Add a complete message directly (preserves all original data)
  void addMessage(ChatMessage message) {
    // Check for duplicate messages to prevent displaying multiple instances of the same message
    if (_messages.isNotEmpty) {
      final lastMessage = _messages.last;
      // If the last message has the same ID, skip it
      if (lastMessage.id == message.id) {
        DebugConfig.debugPrint('Preventing duplicate message with same ID: ${message.id}');
        return;
      }
      
      // If the last message has the same content, is from the same user, and was sent within 2 seconds
      if (lastMessage.content == message.content && 
          lastMessage.isMe == message.isMe &&
          DateTime.now().difference(lastMessage.timestamp).inSeconds < 2) {
        DebugConfig.debugPrint('Preventing duplicate message: ${message.content} from ${message.isMe ? "user" : "server"}');
        return; // Skip adding this duplicate message
      }
    }
    
    _messages.add(message);
    notifyListeners();
  }

  // Message shifting feature - DISABLED by default as per user request
  bool _messageShiftingEnabled = false; // CHANGED: Disabled by default
  bool get isMessageShiftingEnabled => _messageShiftingEnabled;
  
  void setMessageShifting(bool enabled) {
    _messageShiftingEnabled = enabled;
    if (enabled) {
      _applyMessageShifting();
      notifyListeners();
    } else {
      // When disabled, we don't need to do anything - messages remain in natural order
      notifyListeners();
    }
  }

  // Dynamic message shifting: Move user messages one position up relative to server messages
  // NOTE: This feature is now disabled by default to preserve natural message order
  void _applyMessageShifting() {
    if (!_messageShiftingEnabled || _messages.length < 2) return; // Need at least 2 messages to shift
    
    final originalMessages = List<ChatMessage>.from(_messages);
    final reorderedMessages = <ChatMessage>[];
    
    // Group messages into conversation pairs (server message + potential user response)
    for (int i = 0; i < originalMessages.length; i++) {
      final currentMessage = originalMessages[i];
      
      // If this is a server message, check if there's a user response after it
      if (!currentMessage.isMe && i + 1 < originalMessages.length) {
        final nextMessage = originalMessages[i + 1];
        
        // If the next message is from user, shift it to appear first
        if (nextMessage.isMe) {
          reorderedMessages.add(nextMessage); // Add user message first
          reorderedMessages.add(currentMessage); // Then add server message
          i++; // Skip the next message since we already processed it
          continue;
        }
      }
      
      // For all other cases, add the message as-is
      reorderedMessages.add(currentMessage);
    }
    
    // Update the messages list with reordered messages
    _messages.clear();
    _messages.addAll(reorderedMessages);
    
    DebugConfig.debugPrint('Applied message shifting: ${originalMessages.length} -> ${reorderedMessages.length} messages');
  }

  // Manual method to apply message shifting (useful for testing/debugging)
  void applyMessageShifting() {
    _applyMessageShifting();
    notifyListeners();
  }

  // Clear chat history
  void clearChatHistory() {
    _messages.clear();
    notifyListeners();
  }

  // Add a text message - FIXED: Preserve chronological order
  void addTextMessage(String text, {bool isMe = false}) {
    // Check for duplicate messages to prevent displaying multiple instances of the same message
    if (_messages.isNotEmpty) {
      final lastMessage = _messages.last;
      // If the last message has the same content, is from the same user, and was sent within 2 seconds
      if (lastMessage.content == text && 
          lastMessage.isMe == isMe &&
          DateTime.now().difference(lastMessage.timestamp).inSeconds < 2) {
        DebugConfig.debugPrint('Preventing duplicate message: $text from ${isMe ? "user" : "server"}');
        return; // Skip adding this duplicate message
      }
      
      // Also check if any message in the last 5 messages has the exact same content and sender
      final recentMessages = _messages.length > 5 ? _messages.sublist(_messages.length - 5) : _messages;
      for (final message in recentMessages) {
        if (message.content == text && 
            message.isMe == isMe &&
            DateTime.now().difference(message.timestamp).inSeconds < 5) {
          DebugConfig.debugPrint('Preventing recent duplicate message: $text from ${isMe ? "user" : "server"}');
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
    
    // REMOVED: Message shifting to preserve natural order as requested
    notifyListeners();
  }

  // Add a quick reply message - FIXED: Preserve chronological order
  void addQuickReplyMessage(List<QuickReply> replies) {
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
    
    // REMOVED: Message shifting to preserve natural order as requested
    notifyListeners();
  }

  // Add a media message
  Future<void> sendMedia(String path, MessageType type) async {
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        content: path,
        type: type,
        isMe: true,
        timestamp: DateTime.now(),
        mediaUrl: path,
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

  // Send a text message (for compatibility with firebase_chat_service calls)
  Future<void> sendTextMessage(String content, {String? replyToMessageId}) async {
    addTextMessage(content, isMe: true);
  }

  // Send a file message (for compatibility with firebase_chat_service calls)
  Future<void> sendFile(String path, String filename, int size) async {
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        content: filename,
        type: MessageType.file,
        isMe: true,
        timestamp: DateTime.now(),
        mediaUrl: path,
      ),
    );
    notifyListeners();
  }

  // Add reaction to a message (for compatibility with firebase_chat_service calls)
  Future<void> addReaction(String messageId, String emoji) async {
    // Find the message and add the reaction
    final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
    if (messageIndex >= 0) {
      // In a real implementation, you would add reactions to the message
      // For now, just print for debugging
      print('Adding reaction $emoji to message $messageId');
    }
  }

  // Load demo messages
  void _loadDemoMessages() {
    // Skip loading demo messages to start with a completely clean chat
    print('Skipping demo message loading - starting with empty chat');
    // No demo messages will be added, chat starts completely clean
  }
}