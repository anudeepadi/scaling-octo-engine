import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../models/gemini_quick_reply.dart';
import '../models/link_preview.dart';
import '../services/bot_service.dart';
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
  final BotService _botService = BotService();

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

    // Create some sample conversations
    _conversations.add(
      ChatConversation(
        id: _uuid.v4(),
        name: 'Trip Planning',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        messages: [],
        lastMessagePreview: 'Let me help you plan your trip.',
      )
    );

    _conversations.add(
      ChatConversation(
        id: _uuid.v4(),
        name: 'Recipe Ideas',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        messages: [],
        lastMessagePreview: 'Here are some dinner ideas.',
      )
    );

    _conversations.add(
      ChatConversation(
        id: _uuid.v4(),
        name: 'Tech Support',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 3)),
        messages: [],
        lastMessagePreview: 'Have you tried restarting your device?',
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
      case MessageType.geminiQuickReply:
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

  // Load some demo messages
  void _loadDemoMessages() {
    // Add a welcome message
    final welcomeMessage = ChatMessage(
      id: _uuid.v4(),
      content: 'Welcome to the RCS Demo App! This is running in demo mode. Feel free to send messages and try out the features.',
      isMe: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      type: MessageType.text,
      status: MessageStatus.sent,
    );

    _messages.add(welcomeMessage);

    // Add some quick replies
    final quickReplies = [
      QuickReply(text: '👋 Hello!', value: 'Hello'),
      QuickReply(text: '🤔 What can you do?', value: 'What can you do?'),
      QuickReply(text: '🔍 Tell me more', value: 'Tell me more about this app'),
    ];

    final geminiQuickReplies = quickReplies.map((qr) =>
      GeminiQuickReply.fromQuickReply(qr)
    ).toList();

    addGeminiQuickReplyMessage(geminiQuickReplies);

    notifyListeners();
  }

  // When a message is added, update conversation metadata
  void _updateCurrentConversation() {
    if (_currentConversationId != null && _messages.isNotEmpty) {
      final index = _conversations.indexWhere((conv) => conv.id == _currentConversationId);
      if (index >= 0) {
        _conversations[index] = ChatConversation(
          id: _conversations[index].id,
          name: _conversations[index].name,
          lastMessageTime: DateTime.now(),
          messages: List.from(_messages),
          lastMessagePreview: _getMessagePreview(_messages.last),
        );
      }
    }
  }

  // Clear chat history
  void clearChatHistory() {
    if (_currentConversationId != null) {
      // Only clear current conversation
      _messages.clear();

      // Update conversation in the list
      final index = _conversations.indexWhere((conv) => conv.id == _currentConversationId);
      if (index >= 0) {
        _conversations[index] = ChatConversation(
          id: _conversations[index].id,
          name: _conversations[index].name,
          lastMessageTime: DateTime.now(),
          messages: [],
          lastMessagePreview: null,
        );
      }

      notifyListeners();
    }
  }

  // Update the last message preview in the chat list
  void _updateLastMessagePreview(String text) {
    if (_currentConversationId != null) {
      final index = _conversations.indexWhere((conv) => conv.id == _currentConversationId);
      if (index >= 0) {
        _conversations[index] = ChatConversation(
          id: _conversations[index].id,
          name: _conversations[index].name,
          lastMessageTime: DateTime.now(),
          messages: _conversations[index].messages,
          lastMessagePreview: text.length > 30 ? '${text.substring(0, 27)}...' : text,
        );
      }
    }
  }

  void addTextMessage(String content, {bool isMe = true, bool fromDash = false}) {
    final messageId = _uuid.v4();
    final message = ChatMessage(
      id: messageId,
      content: content,
      isMe: isMe,
      timestamp: DateTime.now(),
      type: MessageType.text,
      status: MessageStatus.sent,
    );

    // Add to local state
    _messages.add(message);

    // Update conversation
    _updateCurrentConversation();

    notifyListeners();

    // Only generate bot response if this is from user and not from Dash service
    if (isMe && !fromDash) {
      _generateBotResponse(content);
    }
  }

  void addGifMessage(String gifUrl, {bool isMe = true}) {
    final messageId = _uuid.v4();
    final message = ChatMessage(
      id: messageId,
      content: gifUrl,
      isMe: isMe,
      timestamp: DateTime.now(),
      type: MessageType.gif,
      mediaUrl: gifUrl,
      status: MessageStatus.sent,
    );

    // Add to local state
    _messages.add(message);

    // Update conversation
    _updateCurrentConversation();

    notifyListeners();

    if (isMe) {
      _generateBotResponse('Can you react to this GIF?');
    }
  }

  void addLinkPreviewMessage(String url, {bool isMe = false}) {
    final messageId = _uuid.v4();
    
    // Create a simple link preview
    final linkPreview = LinkPreview(
      url: url,
      title: 'Link Preview',
      description: url,
    );
    
    final message = ChatMessage(
      id: messageId,
      content: url,
      isMe: isMe,
      timestamp: DateTime.now(),
      type: MessageType.linkPreview,
      linkPreview: linkPreview,
      status: MessageStatus.sent,
    );

    // Add to local state
    _messages.add(message);

    // Update conversation
    _updateCurrentConversation();

    notifyListeners();
  }

  Future<void> sendTextMessage(String content, {String? replyToMessageId}) async {
    if (content.trim().isEmpty) return;

    final messageId = _uuid.v4();
    final message = ChatMessage(
      id: messageId,
      content: content,
      isMe: true,
      timestamp: DateTime.now(),
      type: MessageType.text,
      status: MessageStatus.sending,
      parentMessageId: replyToMessageId,
    );

    // Add to local state
    _messages.add(message);

    // Update conversation
    _updateCurrentConversation();

    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _updateMessageStatus(messageId, MessageStatus.sent);

      _generateBotResponse(content);
    } catch (e) {
      _updateMessageStatus(messageId, MessageStatus.failed);
      _error = 'Failed to send message: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> sendQuickReply(String content) async {
    if (content.trim().isEmpty) return;

    final messageId = _uuid.v4();
    final message = ChatMessage(
      id: messageId,
      content: content,
      isMe: true,
      timestamp: DateTime.now(),
      type: MessageType.text,
      status: MessageStatus.sending,
    );

    // Add to local state
    _messages.add(message);

    // Update conversation
    _updateCurrentConversation();

    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _updateMessageStatus(messageId, MessageStatus.sent);

      _generateBotResponse(content);
    } catch (e) {
      _updateMessageStatus(messageId, MessageStatus.failed);
      _error = 'Failed to send message: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> sendMedia(String mediaPath, MessageType type, {bool fromDash = false}) async {
    final messageId = _uuid.v4();
    final message = ChatMessage(
      id: messageId,
      content: mediaPath,
      isMe: !fromDash,
      timestamp: DateTime.now(),
      type: type,
      mediaUrl: mediaPath,
      status: MessageStatus.sending,
    );

    // Add to local state
    _messages.add(message);

    // Update conversation
    _updateCurrentConversation();

    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      _updateMessageStatus(messageId, MessageStatus.sent);

      if (type == MessageType.image && !fromDash) {
        _generateBotResponse('Can you describe this image?');
      }
    } catch (e) {
      _updateMessageStatus(messageId, MessageStatus.failed);
      _error = 'Failed to send media: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> sendFile(String filePath, String fileName, int fileSize) async {
    final messageId = _uuid.v4();
    final message = ChatMessage(
      id: messageId,
      content: fileName,
      isMe: true,
      timestamp: DateTime.now(),
      type: MessageType.file,
      mediaUrl: filePath,
      fileName: fileName,
      fileSize: fileSize,
      status: MessageStatus.sending,
    );

    // Add to local state
    _messages.add(message);

    // Update conversation
    _updateCurrentConversation();

    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      _updateMessageStatus(messageId, MessageStatus.sent);
    } catch (e) {
      _updateMessageStatus(messageId, MessageStatus.failed);
      _error = 'Failed to send file: ${e.toString()}';
      notifyListeners();
    }
  }

  void addQuickReplyMessage(List<QuickReply> suggestedReplies, {bool isMe = false}) {
    final messageId = _uuid.v4();
    final message = ChatMessage(
      id: messageId,
      content: '',
      isMe: isMe,
      timestamp: DateTime.now(),
      type: MessageType.quickReply,
      suggestedReplies: suggestedReplies,
      status: MessageStatus.sent,
    );

    // Add to local state
    _messages.add(message);

    // Update conversation
    _updateCurrentConversation();

    notifyListeners();
  }

  void addGeminiQuickReplyMessage(List<GeminiQuickReply> suggestedReplies) {
    final messageId = _uuid.v4();
    final message = ChatMessage(
      id: messageId,
      content: '',
      isMe: false,
      timestamp: DateTime.now(),
      type: MessageType.geminiQuickReply,
      suggestedReplies: suggestedReplies,
      status: MessageStatus.sent,
    );

    // Add to local state
    _messages.add(message);

    // Update conversation
    _updateCurrentConversation();

    notifyListeners();
  }

  void addReaction(String messageId, String emoji) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final message = _messages[index];
      final reaction = MessageReaction(
        emoji: emoji,
        userId: 'current_user',
        timestamp: DateTime.now(),
      );

      final updatedReactions = List<MessageReaction>.from(message.reactions)..add(reaction);

      _messages[index] = message.copyWith(reactions: updatedReactions);

      // Update conversation
      _updateCurrentConversation();

      notifyListeners();
    }
  }

  void removeReaction(String messageId, String emoji) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final message = _messages[index];
      final userId = 'current_user';

      final updatedReactions = List<MessageReaction>.from(message.reactions)
        ..removeWhere((r) => r.emoji == emoji && r.userId == userId);

      _messages[index] = message.copyWith(reactions: updatedReactions);

      // Update conversation
      _updateCurrentConversation();

      notifyListeners();
    }
  }

  void deleteMessage(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages.removeAt(index);

      // Update conversation
      _updateCurrentConversation();

      notifyListeners();
    }
  }

  void _updateMessageStatus(String messageId, MessageStatus status) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(status: status);

      // Update conversation if the status is final
      if (status == MessageStatus.sent || status == MessageStatus.failed) {
        _updateCurrentConversation();
      }

      notifyListeners();
    }
  }

  Future<void> _generateBotResponse(String userMessage) async {
    final typingMessageId = _uuid.v4();
    final typingMessage = ChatMessage(
      id: typingMessageId,
      content: 'Typing...',
      isMe: false,
      timestamp: DateTime.now(),
      type: MessageType.text,
      status: MessageStatus.sending,
    );

    _messages.add(typingMessage);
    notifyListeners();

    final response = await _botService.generateResponse(userMessage);

    _messages.removeWhere((m) => m.id == typingMessageId);

    final messageId = _uuid.v4();
    final responseMessage = ChatMessage(
      id: messageId,
      content: response,
      isMe: false,
      timestamp: DateTime.now(),
      type: MessageType.text,
      status: MessageStatus.sent,
    );

    // Add to local state
    _messages.add(responseMessage);

    // Update conversation
    _updateCurrentConversation();

    // Always generate quick replies to test functionality
    print('Generating quick replies for response');

    // First try to get Gemini quick replies
    List<QuickReply> quickReplies = _botService.getGeminiQuickReplies(response);
    print('Generated ${quickReplies.length} quick replies');

    // If we get none, force some test ones
    if (quickReplies.isEmpty) {
      print('No quick replies generated, adding test fallbacks');
      quickReplies = [
        QuickReply(text: '👍 Test Reply 1', value: 'Test1'),
        QuickReply(text: '❓ Test Reply 2', value: 'Test2'),
        QuickReply(text: '🤔 Test Reply 3', value: 'Test3'),
      ];
    }

    // Convert to GeminiQuickReply objects and add as geminiQuickReply type message
    final geminiQuickReplies = quickReplies.map((qr) =>
      GeminiQuickReply.fromQuickReply(qr)
    ).toList();

    print('Adding ${geminiQuickReplies.length} Gemini quick replies');
    addGeminiQuickReplyMessage(geminiQuickReplies);
  }
}