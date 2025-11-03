import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../services/link_preview_service.dart';
import '../utils/debug_config.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

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

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  final List<ChatConversation> _conversations = [];
  List<ChatConversation> get conversations => _conversations;

  String? _currentConversationId;
  String? get currentConversationId => _currentConversationId;

  final _uuid = Uuid();

  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  ChatProvider() {
    _initializeDemoConversations();
  }

  void _initializeDemoConversations() {
    final defaultConversationId = _uuid.v4();
    _conversations.add(ChatConversation(
      id: defaultConversationId,
      name: 'New Chat',
      lastMessageTime: DateTime.now(),
      messages: [],
      lastMessagePreview: null,
    ));

    _currentConversationId = defaultConversationId;
  }

  void addMessage(ChatMessage message) {
    _messages.add(message);
    _messages.sort(_messageComparator);
    _updateCurrentConversationTime();
    notifyListeners();
    _processLinksInMessage(message);
  }

  void addMessages(List<ChatMessage> newMessages) {
    _messages.addAll(newMessages);
    _messages.sort(_messageComparator);
    _updateCurrentConversationTime();
    notifyListeners();

    for (final message in newMessages) {
      _processLinksInMessage(message);
    }
  }

  void setMessages(List<ChatMessage> newMessages) {
    _messages.clear();
    _messages.addAll(newMessages);
    _messages.sort(_messageComparator);
    _updateCurrentConversationTime();
    notifyListeners();

    for (final message in newMessages) {
      _processLinksInMessage(message);
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  void addTextMessage(String content, {bool isMe = true}) {
    final message = ChatMessage(
      id: _uuid.v4(),
      content: content,
      timestamp: DateTime.now(),
      isMe: isMe,
      type: MessageType.text,
    );

    addMessage(message);
  }

  bool _containsUrl(String content) {
    final urlRegex = RegExp(
      r'https?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+',
      caseSensitive: false,
    );
    return urlRegex.hasMatch(content);
  }

  String? _extractFirstUrl(String content) {
    final urlRegex = RegExp(
      r'https?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(content);
    return match?.group(0);
  }

  bool _isYouTubeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.host.contains('youtube.com') || uri.host.contains('youtu.be');
  }

  bool _isImageUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.webp') ||
        lowerUrl.endsWith('.gif');
  }

  Future<void> _processLinksInMessage(ChatMessage message) async {
    if (!_containsUrl(message.content)) return;

    final url = _extractFirstUrl(message.content);
    if (url == null) return;

    if (_isYouTubeUrl(url) || _isImageUrl(url)) return;

    _fetchLinkPreviewAsync(message, url);
  }

  Future<void> _fetchLinkPreviewAsync(ChatMessage message, String url) async {
    try {
      final linkPreview = await LinkPreviewService.fetchLinkPreview(url);
      if (linkPreview != null) {
        final updatedMessage = message.copyWith(
          linkPreview: linkPreview,
          type: MessageType.linkPreview,
        );
        updateMessage(message.id, updatedMessage);
      }
    } catch (e) {
      DebugConfig.debugPrint('Error processing link preview: $e');
    }
  }

  void addQuickReplyMessage(String content, List<QuickReply> quickReplies,
      {bool isMe = false}) {
    final message = ChatMessage(
      id: _uuid.v4(),
      content: content,
      timestamp: DateTime.now(),
      isMe: isMe,
      type: MessageType.quickReply,
      suggestedReplies: quickReplies,
    );

    addMessage(message);
  }

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

  void updateMessage(String messageId, ChatMessage updatedMessage) {
    final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
    if (messageIndex != -1) {
      _messages[messageIndex] = updatedMessage;
      _messages.sort(_messageComparator);
      notifyListeners();
    }
  }

  int _messageComparator(ChatMessage a, ChatMessage b) {
    final timeCompare = a.timestamp.compareTo(b.timestamp);

    final timeDiffMs = (a.timestamp.millisecondsSinceEpoch -
            b.timestamp.millisecondsSinceEpoch)
        .abs();
    if (timeDiffMs > 5000) {
      return timeCompare;
    }

    if (a.isMe != b.isMe) {
      return a.isMe ? -1 : 1;
    }

    if (timeCompare != 0) {
      return timeCompare;
    }

    return a.id.compareTo(b.id);
  }

  void removeMessage(String messageId) {
    _messages.removeWhere((msg) => msg.id == messageId);
    notifyListeners();
  }

  void createNewConversation(String name) {
    final newId = _uuid.v4();
    _conversations.add(ChatConversation(
      id: newId,
      name: name,
      lastMessageTime: DateTime.now(),
      messages: [],
    ));

    _currentConversationId = newId;
    _messages.clear();
    notifyListeners();
  }

  void switchConversation(String conversationId) {
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

    _currentConversationId = conversationId;

    final selectedConversation =
        _conversations.firstWhere((conv) => conv.id == conversationId);
    _messages.clear();
    _messages.addAll(selectedConversation.messages);
    _messages.sort(_messageComparator);

    notifyListeners();
  }

  String _getMessagePreview(ChatMessage message) {
    if (message.content.isNotEmpty) {
      return message.content.length > 50
          ? '${message.content.substring(0, 50)}...'
          : message.content;
    }

    switch (message.type) {
      case MessageType.image:
        return 'Image';
      case MessageType.gif:
        return 'GIF';
      case MessageType.video:
        return 'Video';
      case MessageType.file:
        return 'File';
      case MessageType.voice:
        return 'Voice message';
      case MessageType.quickReply:
        return 'Quick reply options';
      default:
        return 'Message';
    }
  }

  void deleteConversation(String conversationId) {
    _conversations.removeWhere((conv) => conv.id == conversationId);

    if (_currentConversationId == conversationId) {
      if (_conversations.isNotEmpty) {
        switchConversation(_conversations.first.id);
      } else {
        _initializeDemoConversations();
      }
    }

    notifyListeners();
  }

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

  ChatConversation? getCurrentConversation() {
    if (_currentConversationId == null) return null;

    try {
      return _conversations
          .firstWhere((conv) => conv.id == _currentConversationId);
    } catch (e) {
      return null;
    }
  }

  void _updateCurrentConversationTime() {
    if (_currentConversationId != null && _messages.isNotEmpty) {
      final currentIndex = _conversations
          .indexWhere((conv) => conv.id == _currentConversationId);
      if (currentIndex >= 0) {
        _conversations[currentIndex] = ChatConversation(
          id: _conversations[currentIndex].id,
          name: _conversations[currentIndex].name,
          lastMessageTime: _messages.last.timestamp,
          messages: List.from(_messages),
          lastMessagePreview: _getMessagePreview(_messages.last),
        );
      }
    }
  }

  int get conversationCount => _conversations.length;
  bool get hasMessages => _messages.isNotEmpty;
  int get messageCount => _messages.length;
  ChatMessage? get latestMessage =>
      _messages.isNotEmpty ? _messages.last : null;

  void clearChatHistory() {
    clearMessages();
  }

  Future<void> sendMedia(String path, MessageType type) async {
    addMediaMessage(path, path, type);
  }

  Future<void> sendTextMessage(String content,
      {String? replyToMessageId}) async {
    addTextMessage(content, isMe: true);
  }

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

  Future<void> addReaction(String messageId, String emoji) async {
    DebugConfig.debugPrint('Adding reaction $emoji to message $messageId');
  }

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

  void debugAllMessageOrdering() {
    debugTimestampIssues();
    testChronologicalOrdering();
    verifyMessageOrder();
  }

  void testChronologicalOrdering() {
    final originalMessages = List<ChatMessage>.from(_messages);
    _messages.clear();

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

    addMessage(serverResponse2);
    addMessage(userMessage1);
    addMessage(serverResponse1);
    addMessage(userMessage2);

    verifyMessageOrder();

    _messages.clear();
    _messages.addAll(originalMessages);
    _messages.sort(_messageComparator);

    notifyListeners();
  }

  void debugTimestampIssues() {
    DebugConfig.debugPrint('Debugging timestamp issues:');

    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      final timeStr = message.timestamp.toIso8601String();
      final millis = message.timestamp.millisecondsSinceEpoch;
      final userType = message.isMe ? "USER" : "SERVER";
      final preview = message.content.isEmpty
          ? "[${message.type}]"
          : message.content.substring(
              0, message.content.length > 30 ? 30 : message.content.length);

      DebugConfig.debugPrint('$i: $userType - $timeStr ($millis) - "$preview"');

      if (i > 0) {
        final prevMessage = _messages[i - 1];
        final timeDiff =
            message.timestamp.difference(prevMessage.timestamp).inMilliseconds;

        if (timeDiff < 0) {
          DebugConfig.debugPrint('Ordering violation! Message is ${-timeDiff}ms before previous');
        } else if (timeDiff == 0) {
          if (prevMessage.isMe && !message.isMe) {
            DebugConfig.debugPrint('Correct ordering: User then Server');
          } else if (!prevMessage.isMe && message.isMe) {
            DebugConfig.debugPrint('Wrong ordering: Server then User');
          }
        }
      }
    }
  }

  void verifyMessageOrder() {
    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      final timeStr = message.timestamp.toIso8601String();
      final preview = message.content.isEmpty
          ? "[${message.type}]"
          : message.content.substring(
              0, message.content.length > 30 ? 30 : message.content.length);
      final userType = message.isMe ? "USER" : "SERVER";

      if (i > 0) {
        final prevMessage = _messages[i - 1];
        final timeDiff = message.timestamp.difference(prevMessage.timestamp);

        if (message.timestamp.isBefore(prevMessage.timestamp)) {
          DebugConfig.debugPrint('Warning: Message $i is earlier than message ${i - 1}');
        }
      }
    }
  }

  Future<void> testLinkPreview() async {
    final testUrl = 'https://www.github.com';
    try {
      final preview = await LinkPreviewService.fetchLinkPreview(testUrl);
      if (preview != null) {
        DebugConfig.debugPrint('Link preview test successful');
      }
    } catch (e) {
      DebugConfig.debugPrint('Link preview test error: $e');
    }
  }

  Future<void> reprocessAllLinkPreviews() async {
    for (final message in _messages) {
      if (_containsUrl(message.content) && message.linkPreview == null) {
        await _processLinksInMessage(message);
      }
    }
  }

  Future<void> debugLinkPreviews() async {
    final messagesWithUrls =
        _messages.where((msg) => _containsUrl(msg.content)).toList();
    DebugConfig.debugPrint('Found ${messagesWithUrls.length} messages with URLs');

    for (int i = 0; i < messagesWithUrls.length; i++) {
      final message = messagesWithUrls[i];
      final url = _extractFirstUrl(message.content);
      DebugConfig.debugPrint('Message ${i + 1}: URL: $url, Has Preview: ${message.linkPreview != null}');
    }
  }

  Future<void> addTestMessageWithLink(String testUrl) async {
    final testMessage = 'Testing link preview: $testUrl';
    addTextMessage(testMessage, isMe: true);
  }

  Future<void> processLinksForMessage(String messageId) async {
    final message = _messages.firstWhere((msg) => msg.id == messageId,
        orElse: () => throw Exception('Message not found'));
    await _processLinksInMessage(message);
  }
}
