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

// Chat provider with proper message ordering (chronological)
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
    DebugConfig.debugPrint('ChatProvider: Initializing with chronological message ordering');
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

    // Start with empty conversation (no demo messages)
    print('ChatProvider: Starting with empty conversation to preserve user message order');
  }

  // Add a message to the current conversation in chronological order
  void addMessage(ChatMessage message) {
    _messages.add(message);
    
    // Always sort by timestamp to maintain chronological order
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    _updateCurrentConversationTime();
    notifyListeners();
    
    print('ChatProvider: Added message "${message.content.isEmpty ? "[${message.type}]" : message.content.substring(0, message.content.length > 30 ? 30 : message.content.length)}" - Total: ${_messages.length}');
  }

  // Add multiple messages while preserving chronological order
  void addMessages(List<ChatMessage> newMessages) {
    _messages.addAll(newMessages);
    
    // Sort all messages by timestamp to ensure chronological order
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    _updateCurrentConversationTime();
    notifyListeners();
    
    print('ChatProvider: Added ${newMessages.length} messages in chronological order - Total: ${_messages.length}');
  }

  // Set messages (replaces current messages, maintaining chronological order)
  void setMessages(List<ChatMessage> newMessages) {
    _messages.clear();
    _messages.addAll(newMessages);
    
    // Sort by timestamp to ensure chronological order
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    _updateCurrentConversationTime();
    notifyListeners();
    
    print('ChatProvider: Set ${newMessages.length} messages in chronological order');
  }

  // Clear all messages
  void clearMessages() {
    _messages.clear();
    notifyListeners();
    print('ChatProvider: Cleared all messages');
  }

  // Send a text message (creates user message with current timestamp)
  void addTextMessage(String content, {bool isMe = true}) {
    final message = ChatMessage(
      id: _uuid.v4(),
      content: content,
      timestamp: DateTime.now(), // Use current timestamp for proper ordering
      isMe: isMe,
      type: MessageType.text,
    );
    
    addMessage(message);
  }

  // Send a quick reply message (creates user message with current timestamp)
  void addQuickReplyMessage(String content, List<QuickReply> quickReplies, {bool isMe = false}) {
    final message = ChatMessage(
      id: _uuid.v4(),
      content: content,
      timestamp: DateTime.now(), // Use current timestamp for proper ordering
      isMe: isMe,
      type: MessageType.quickReply,
      suggestedReplies: quickReplies,
    );
    
    addMessage(message);
  }

  // Add media message
  void addMediaMessage(String content, String path, MessageType type) {
    final message = ChatMessage(
      id: _uuid.v4(),
      content: content,
      timestamp: DateTime.now(),
      isMe: true,
      type: type,
      mediaUrl: path,
    );
    
    addMessage(message);
  }

  // Update message by ID (useful for updating status)
  void updateMessage(String messageId, ChatMessage updatedMessage) {
    final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
    if (messageIndex != -1) {
      _messages[messageIndex] = updatedMessage;
      
      // Re-sort to maintain chronological order after update
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      notifyListeners();
      print('ChatProvider: Updated message $messageId and re-sorted chronologically');
    }
  }

  // Remove message by ID
  void removeMessage(String messageId) {
    _messages.removeWhere((msg) => msg.id == messageId);
    notifyListeners();
    print('ChatProvider: Removed message $messageId');
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

    // Load messages for the selected conversation (already in chronological order)
    final selectedConversation = _conversations.firstWhere((conv) => conv.id == conversationId);
    _messages.clear();
    _messages.addAll(selectedConversation.messages);

    print('ChatProvider: Switched conversation - loaded ${_messages.length} messages in chronological order');

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
          lastMessageTime: _messages.last.timestamp, // Use last message timestamp
          messages: List.from(_messages),
          lastMessagePreview: _getMessagePreview(_messages.last),
        );
      }
    }
  }

  // Get conversation count
  int get conversationCount => _conversations.length;

  // Check if has messages
  bool get hasMessages => _messages.isNotEmpty;

  // Get message count
  int get messageCount => _messages.length;

  // Get latest message
  ChatMessage? get latestMessage => _messages.isNotEmpty ? _messages.last : null;

  // Clear chat history (alias for clearMessages)
  void clearChatHistory() {
    clearMessages();
  }

  // Send media message (for compatibility)
  Future<void> sendMedia(String path, MessageType type) async {
    addMediaMessage(path, path, type);
  }

  // Send text message (for compatibility)
  Future<void> sendTextMessage(String content, {String? replyToMessageId}) async {
    addTextMessage(content, isMe: true);
  }

  // Send file message (for compatibility)
  Future<void> sendFile(String path, String filename, int size) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      content: filename,
      timestamp: DateTime.now(),
      isMe: true,
      type: MessageType.file,
      mediaUrl: path,
    );
    addMessage(message);
  }

  // Add reaction to message (for compatibility)
  Future<void> addReaction(String messageId, String emoji) async {
    print('ChatProvider: Adding reaction $emoji to message $messageId');
    // In a real implementation, you would add reactions to the message
    // For now, just print for debugging
  }

  // Add GIF message (for compatibility)
  void addGifMessage(String gifPath) {
    final message = ChatMessage(
      id: _uuid.v4(),
      content: gifPath,
      timestamp: DateTime.now(),
      isMe: true,
      type: MessageType.gif,
      mediaUrl: gifPath,
    );
    addMessage(message);
  }

  // Debug method to verify message ordering
  void verifyMessageOrder() {
    print('ChatProvider: Verifying message order (should be chronological):');
    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      final timeStr = message.timestamp.toIso8601String();
      final preview = message.content.isEmpty ? "[${message.type}]" : message.content.substring(0, message.content.length > 30 ? 30 : message.content.length);
      print('  $i: $timeStr - "$preview" (isMe: ${message.isMe})');
      
      if (i > 0) {
        final prevMessage = _messages[i - 1];
        if (message.timestamp.isBefore(prevMessage.timestamp)) {
          print('  ⚠️ WARNING: Message $i is earlier than message ${i-1} - ordering violated!');
        }
      }
    }
    print('ChatProvider: ✅ Message order verification completed');
  }
}