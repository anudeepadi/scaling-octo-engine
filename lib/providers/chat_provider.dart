import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../services/link_preview_service.dart';
import '../utils/debug_config.dart';
import '../utils/link_preview_test.dart';
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

  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  ChatProvider() {
    DebugConfig.debugPrint(
        'ChatProvider: Initializing with chronological message ordering');
    _initializeDemoConversations();
  }

  // Initialize with demo conversations
  void _initializeDemoConversations() {
    // Create a default conversation
    final defaultConversationId = _uuid.v4();
    _conversations.add(ChatConversation(
      id: defaultConversationId,
      name: 'New Chat',
      lastMessageTime: DateTime.now(),
      messages: [],
      lastMessagePreview: null,
    ));

    // Set current conversation
    _currentConversationId = defaultConversationId;

    // Start with empty conversation (no demo messages)
    DebugConfig.debugPrint(
        'ChatProvider: Starting with empty conversation to preserve user message order');
  }

  // Add a message to the current conversation in chronological order
  void addMessage(ChatMessage message) {
    _messages.add(message);

    // Always sort by timestamp to maintain chronological order
    _messages.sort(_messageComparator);

    _updateCurrentConversationTime();
    notifyListeners();

    // Check for links and fetch preview asynchronously for ALL messages
    _processLinksInMessage(message);

    DebugConfig.debugPrint(
        'ChatProvider: Added message "${message.content.isEmpty ? "[${message.type}]" : message.content.substring(0, message.content.length > 30 ? 30 : message.content.length)}" - Total: ${_messages.length}');
  }

  // Add multiple messages while preserving chronological order
  void addMessages(List<ChatMessage> newMessages) {
    _messages.addAll(newMessages);

    // Sort all messages by timestamp to ensure chronological order
    _messages.sort(_messageComparator);

    _updateCurrentConversationTime();
    notifyListeners();

    // Process link previews for new messages asynchronously
    for (final message in newMessages) {
      _processLinksInMessage(message);
    }

    DebugConfig.debugPrint(
        'ChatProvider: Added ${newMessages.length} messages in chronological order - Total: ${_messages.length}');
  }

  // Set messages (replaces current messages, maintaining chronological order)
  void setMessages(List<ChatMessage> newMessages) {
    _messages.clear();
    _messages.addAll(newMessages);

    // Sort by timestamp to ensure chronological order
    _messages.sort(_messageComparator);

    _updateCurrentConversationTime();
    notifyListeners();

    // Process link previews for new messages asynchronously
    for (final message in newMessages) {
      _processLinksInMessage(message);
    }

    DebugConfig.debugPrint(
        'ChatProvider: Set ${newMessages.length} messages in chronological order');
  }

  // Clear all messages
  void clearMessages() {
    _messages.clear();
    notifyListeners();
    DebugConfig.debugPrint('ChatProvider: Cleared all messages');
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
    // Note: Link processing is now handled in addMessage()
  }

  // Helper method to detect URLs in message content
  bool _containsUrl(String content) {
    final urlRegex = RegExp(
      r'https?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+',
      caseSensitive: false,
    );
    return urlRegex.hasMatch(content);
  }

  // Helper method to extract first URL from content
  String? _extractFirstUrl(String content) {
    final urlRegex = RegExp(
      r'https?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(content);
    return match?.group(0);
  }

  // Helper method to check if URL is YouTube
  bool _isYouTubeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.host.contains('youtube.com') || uri.host.contains('youtu.be');
  }

  // Helper method to check if URL points to an image
  bool _isImageUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.webp') ||
        lowerUrl.endsWith('.gif');
  }

  // Process links in message and fetch previews
  Future<void> _processLinksInMessage(ChatMessage message) async {
    if (!_containsUrl(message.content)) return;

    final url = _extractFirstUrl(message.content);
    if (url == null) return;

    // Skip YouTube URLs and image URLs as they're handled differently
    if (_isYouTubeUrl(url) || _isImageUrl(url)) return;

    DebugConfig.debugPrint('ChatProvider: Processing link preview for: $url');

    // Process link preview asynchronously without blocking the UI
    _fetchLinkPreviewAsync(message, url);
  }

  // Async method to fetch link preview without blocking
  Future<void> _fetchLinkPreviewAsync(ChatMessage message, String url) async {
    try {
      final linkPreview = await LinkPreviewService.fetchLinkPreview(url);
      if (linkPreview != null) {
        DebugConfig.debugPrint(
            'ChatProvider: Got link preview for $url - Title: ${linkPreview.title}');

        // Update the message with link preview
        final updatedMessage = message.copyWith(
          linkPreview: linkPreview,
          type: MessageType.linkPreview,
        );
        updateMessage(message.id, updatedMessage);
      }
    } catch (e) {
      DebugConfig.debugPrint(
          'ChatProvider: Error processing link preview for $url: $e');
    }
  }

  // Send a quick reply message (creates user message with current timestamp)
  void addQuickReplyMessage(String content, List<QuickReply> quickReplies,
      {bool isMe = false}) {
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
      _messages.sort(_messageComparator);

      notifyListeners();
      DebugConfig.debugPrint(
          'ChatProvider: Updated message $messageId and re-sorted chronologically');
    }
  }

  /// Comparator that sorts by timestamp ascending, ensuring chronological order.
  /// When timestamps are equal or very close (within 5 seconds), user messages appear before
  /// server responses to maintain natural conversational flow.
  int _messageComparator(ChatMessage a, ChatMessage b) {
    final timeCompare = a.timestamp.compareTo(b.timestamp);

    // If timestamps are significantly different (more than 5 seconds), use strict chronological order
    final timeDiffMs = (a.timestamp.millisecondsSinceEpoch -
            b.timestamp.millisecondsSinceEpoch)
        .abs();
    if (timeDiffMs > 5000) {
      return timeCompare;
    }

    // For timestamps that are the same or very close (within 5 seconds),
    // ensure conversational flow: user message → server response
    if (a.isMe != b.isMe) {
      // If one is user and one is server, user message comes first regardless of exact timestamp
      return a.isMe
          ? -1
          : 1; // User messages (-1) come before server messages (1)
    }

    // If both are same type (both user or both server), use timestamp
    if (timeCompare != 0) {
      return timeCompare;
    }

    // Final fallback on id to avoid reordering equal items unpredictably
    return a.id.compareTo(b.id);
  }

  // Remove message by ID
  void removeMessage(String messageId) {
    _messages.removeWhere((msg) => msg.id == messageId);
    notifyListeners();
    DebugConfig.debugPrint('ChatProvider: Removed message $messageId');
  }

  // Create a new conversation
  void createNewConversation(String name) {
    final newId = _uuid.v4();
    _conversations.add(ChatConversation(
      id: newId,
      name: name,
      lastMessageTime: DateTime.now(),
      messages: [],
    ));

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
      final currentIndex = _conversations
          .indexWhere((conv) => conv.id == _currentConversationId);
      if (currentIndex >= 0) {
        _conversations[currentIndex] = ChatConversation(
          id: _conversations[currentIndex].id,
          name: _conversations[currentIndex].name,
          lastMessageTime: _conversations[currentIndex].lastMessageTime,
          messages: List.from(_messages),
          lastMessagePreview:
              _messages.isNotEmpty ? _getMessagePreview(_messages.last) : null,
        );
      }
    }

    // Set new current conversation
    _currentConversationId = conversationId;

    // Load messages for the selected conversation and ensure chronological order
    final selectedConversation =
        _conversations.firstWhere((conv) => conv.id == conversationId);
    _messages.clear();
    _messages.addAll(selectedConversation.messages);

    // Sort to ensure chronological order (messages might have been stored unsorted)
    _messages.sort(_messageComparator);

    DebugConfig.debugPrint(
        'ChatProvider: Switched conversation - loaded ${_messages.length} messages in chronological order');

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
    final index =
        _conversations.indexWhere((conv) => conv.id == conversationId);
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
      return _conversations
          .firstWhere((conv) => conv.id == _currentConversationId);
    } catch (e) {
      return null;
    }
  }

  // Update current conversation's last message time
  void _updateCurrentConversationTime() {
    if (_currentConversationId != null && _messages.isNotEmpty) {
      final currentIndex = _conversations
          .indexWhere((conv) => conv.id == _currentConversationId);
      if (currentIndex >= 0) {
        _conversations[currentIndex] = ChatConversation(
          id: _conversations[currentIndex].id,
          name: _conversations[currentIndex].name,
          lastMessageTime:
              _messages.last.timestamp, // Use last message timestamp
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
  ChatMessage? get latestMessage =>
      _messages.isNotEmpty ? _messages.last : null;

  // Clear chat history (alias for clearMessages)
  void clearChatHistory() {
    clearMessages();
  }

  // Send media message (for compatibility)
  Future<void> sendMedia(String path, MessageType type) async {
    addMediaMessage(path, path, type);
  }

  // Send text message (for compatibility)
  Future<void> sendTextMessage(String content,
      {String? replyToMessageId}) async {
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
    DebugConfig.debugPrint(
        'ChatProvider: Adding reaction $emoji to message $messageId');
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

  // Debug all message ordering issues (comprehensive test)
  void debugAllMessageOrdering() {
    DebugConfig.debugPrint('🔍 COMPREHENSIVE MESSAGE ORDERING DEBUG');
    DebugConfig.debugPrint('=======================================');

    debugTimestampIssues();
    DebugConfig.debugPrint('');
    testChronologicalOrdering();
    DebugConfig.debugPrint('');
    verifyMessageOrder();

    DebugConfig.debugPrint('🔍 COMPREHENSIVE DEBUG COMPLETED');
  }

  // Test chronological ordering with sample messages
  void testChronologicalOrdering() {
    DebugConfig.debugPrint('ChatProvider: Testing chronological ordering...');

    // Clear existing messages for test
    final originalMessages = List<ChatMessage>.from(_messages);
    _messages.clear();

    // Create test messages with specific timestamps
    final baseTime = DateTime.now().subtract(const Duration(minutes: 5));

    final userMessage1 = ChatMessage(
      id: 'test-user-1',
      content: 'Hello, I need help',
      timestamp: baseTime,
      isMe: true,
      type: MessageType.text,
    );

    final serverResponse1 = ChatMessage(
      id: 'test-server-1',
      content: 'Hi! How can I assist you?',
      timestamp: baseTime.add(const Duration(seconds: 1)),
      isMe: false,
      type: MessageType.text,
    );

    final userMessage2 = ChatMessage(
      id: 'test-user-2',
      content: 'I have a question',
      timestamp: baseTime.add(const Duration(seconds: 2)),
      isMe: true,
      type: MessageType.text,
    );

    final serverResponse2 = ChatMessage(
      id: 'test-server-2',
      content: 'What would you like to know?',
      timestamp: baseTime.add(const Duration(seconds: 3)),
      isMe: false,
      type: MessageType.text,
    );

    // Add messages in random order
    addMessage(serverResponse2);
    addMessage(userMessage1);
    addMessage(serverResponse1);
    addMessage(userMessage2);

    DebugConfig.debugPrint('ChatProvider: Added test messages in random order');
    verifyMessageOrder();

    // Restore original messages
    _messages.clear();
    _messages.addAll(originalMessages);
    _messages.sort(_messageComparator);

    DebugConfig.debugPrint('ChatProvider: Test completed, messages restored');
    notifyListeners();
  }

  // Debug specific timestamp and ordering issues
  void debugTimestampIssues() {
    DebugConfig.debugPrint('🐛 DEBUGGING TIMESTAMP ISSUES:');
    DebugConfig.debugPrint('===============================');

    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      final timeStr = message.timestamp.toIso8601String();
      final millis = message.timestamp.millisecondsSinceEpoch;
      final userType = message.isMe ? "USER" : "SERVER";
      final preview = message.content.isEmpty
          ? "[${message.type}]"
          : message.content.substring(
              0, message.content.length > 30 ? 30 : message.content.length);

      DebugConfig.debugPrint(
          '  $i: $userType - $timeStr ($millis) - "$preview"');

      if (i > 0) {
        final prevMessage = _messages[i - 1];
        final timeDiff =
            message.timestamp.difference(prevMessage.timestamp).inMilliseconds;

        if (timeDiff < 0) {
          DebugConfig.debugPrint(
              '    ⚠️  ORDERING VIOLATION! This message is ${-timeDiff}ms BEFORE previous message');
        } else if (timeDiff == 0) {
          if (prevMessage.isMe && !message.isMe) {
            DebugConfig.debugPrint(
                '    ✅ Correct same-timestamp ordering: User → Server');
          } else if (!prevMessage.isMe && message.isMe) {
            DebugConfig.debugPrint(
                '    ❌ WRONG same-timestamp ordering: Server → User (should be User → Server)');
          } else {
            DebugConfig.debugPrint('    ⚠️  Same timestamp, same sender type');
          }
        } else {
          DebugConfig.debugPrint(
              '    ✓ Correct chronological order (+${timeDiff}ms)');
        }
      }
    }
    DebugConfig.debugPrint('🐛 TIMESTAMP DEBUG COMPLETED');
  }

  // Debug method to verify message ordering
  void verifyMessageOrder() {
    DebugConfig.debugPrint(
        'ChatProvider: Verifying message order (should be chronological):');
    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      final timeStr = message.timestamp.toIso8601String();
      final preview = message.content.isEmpty
          ? "[${message.type}]"
          : message.content.substring(
              0, message.content.length > 30 ? 30 : message.content.length);
      final userType = message.isMe ? "USER" : "SERVER";
      DebugConfig.debugPrint('  $i: $timeStr - "$preview" ($userType)');

      if (i > 0) {
        final prevMessage = _messages[i - 1];
        final timeDiff = message.timestamp.difference(prevMessage.timestamp);

        if (message.timestamp.isBefore(prevMessage.timestamp)) {
          DebugConfig.debugPrint(
              '  ⚠️ WARNING: Message $i is earlier than message ${i - 1} - ordering violated!');
        } else if (timeDiff.inMilliseconds == 0) {
          // Same timestamp - check if user message comes before server message
          if (prevMessage.isMe && !message.isMe) {
            DebugConfig.debugPrint(
                '  ✅ Correct: User message followed by server response (same timestamp)');
          } else if (!prevMessage.isMe && message.isMe) {
            DebugConfig.debugPrint(
                '  ⚠️ Potential issue: Server message followed by user message (same timestamp)');
          }
        }
      }
    }
    DebugConfig.debugPrint(
        'ChatProvider: ✅ Message order verification completed (${_messages.length} messages)');
  }

  // Test link preview functionality
  Future<void> testLinkPreview() async {
    final testUrl = 'https://www.github.com';
    DebugConfig.debugPrint('ChatProvider: Testing link preview for $testUrl');

    try {
      final preview = await LinkPreviewService.fetchLinkPreview(testUrl);
      if (preview != null) {
        DebugConfig.debugPrint('ChatProvider: ✅ Link preview test successful');
        DebugConfig.debugPrint('  Title: ${preview.title}');
        DebugConfig.debugPrint('  Description: ${preview.description}');
        DebugConfig.debugPrint('  Image: ${preview.imageUrl}');
        DebugConfig.debugPrint('  Site: ${preview.siteName}');
      } else {
        DebugConfig.debugPrint(
            'ChatProvider: ❌ Link preview test failed - no preview returned');
      }
    } catch (e) {
      DebugConfig.debugPrint('ChatProvider: ❌ Link preview test error: $e');
    }
  }

  // Force process link previews for all existing messages (useful for debugging)
  Future<void> reprocessAllLinkPreviews() async {
    DebugConfig.debugPrint(
        'ChatProvider: Reprocessing link previews for ${_messages.length} messages');

    for (final message in _messages) {
      if (_containsUrl(message.content) && message.linkPreview == null) {
        DebugConfig.debugPrint(
            'ChatProvider: Processing links in message: "${message.content}"');
        await _processLinksInMessage(message);
      }
    }

    DebugConfig.debugPrint('ChatProvider: Finished reprocessing link previews');
  }

  // Comprehensive debug method for link preview issues
  Future<void> debugLinkPreviews() async {
    DebugConfig.debugPrint('');
    DebugConfig.debugPrint('🔍=================================');
    DebugConfig.debugPrint('🔍 LINK PREVIEW DEBUG REPORT');
    DebugConfig.debugPrint('🔍=================================');

    // 1. Check messages with URLs
    final messagesWithUrls =
        _messages.where((msg) => _containsUrl(msg.content)).toList();
    DebugConfig.debugPrint(
        '📊 Found ${messagesWithUrls.length} messages with URLs out of ${_messages.length} total messages');

    for (int i = 0; i < messagesWithUrls.length; i++) {
      final message = messagesWithUrls[i];
      final url = _extractFirstUrl(message.content);
      DebugConfig.debugPrint('');
      DebugConfig.debugPrint(
          '📎 Message ${i + 1}: "${message.content.length > 50 ? '${message.content.substring(0, 50)}...' : message.content}"');
      DebugConfig.debugPrint('   URL: $url');
      DebugConfig.debugPrint('   Type: ${message.type}');
      DebugConfig.debugPrint('   Has Preview: ${message.linkPreview != null}');
      if (message.linkPreview != null) {
        DebugConfig.debugPrint(
            '   Preview Title: ${message.linkPreview!.title}');
      }
    }

    // 2. Test LinkPreviewService with Quitxt URLs
    DebugConfig.debugPrint('');
    DebugConfig.debugPrint('🧪 Testing LinkPreviewService...');
    await LinkPreviewTest.testQuitxtUrls();

    // 3. Test basic URLs
    DebugConfig.debugPrint('');
    DebugConfig.debugPrint('🧪 Testing basic URLs...');
    await LinkPreviewTest.testBasicUrls();

    DebugConfig.debugPrint('');
    DebugConfig.debugPrint('🔍=================================');
    DebugConfig.debugPrint('🔍 END LINK PREVIEW DEBUG REPORT');
    DebugConfig.debugPrint('🔍=================================');
  }

  // Create a test message with link to verify functionality
  Future<void> addTestMessageWithLink(String testUrl) async {
    final testMessage = 'Testing link preview: $testUrl';
    DebugConfig.debugPrint(
        'ChatProvider: Adding test message with URL: $testUrl');
    addTextMessage(testMessage, isMe: true);
  }

  // Helper method to manually trigger link processing for a specific message
  Future<void> processLinksForMessage(String messageId) async {
    final message = _messages.firstWhere((msg) => msg.id == messageId,
        orElse: () => throw Exception('Message not found'));
    DebugConfig.debugPrint(
        'ChatProvider: Manually processing links for message: $messageId');
    await _processLinksInMessage(message);
  }
}
