import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../models/gemini_quick_reply.dart';
import '../services/bot_service.dart';
import '../services/firebase_chat_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:math' as math;

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;
  final _uuid = Uuid();
  final BotService _botService = BotService();
  final FirebaseChatService _firebaseChatService = FirebaseChatService();
  
  StreamSubscription? _chatSubscription;
  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;
  String? _error;
  String? get error => _error;

  ChatProvider() {
    _loadChatHistory();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }

  // Load chat history from Firebase
  Future<void> _loadChatHistory() async {
    _isLoadingHistory = true;
    _error = null;
    notifyListeners();

    try {
      // Cancel existing subscription if any
      await _chatSubscription?.cancel();
      
      // Subscribe to chat history stream
      _chatSubscription = _firebaseChatService.getChatMessages().listen(
        (chatMessages) {
          // Replace current messages with loaded history
          _messages.clear();
          _messages.addAll(chatMessages);
          _isLoadingHistory = false;
          notifyListeners();
        },
        onError: (e) {
          _isLoadingHistory = false;
          _error = 'Failed to load chat history: ${e.toString()}';
          notifyListeners();
        }
      );
    } catch (e) {
      _isLoadingHistory = false;
      _error = 'Failed to load chat history: ${e.toString()}';
      notifyListeners();
    }
  }

  // Reload chat history (useful after login/logout)
  void refreshChatHistory() {
    _loadChatHistory();
  }

  // Clear all chat history
  Future<void> clearChatHistory() async {
    try {
      await _firebaseChatService.clearChatHistory();
      _messages.clear();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear chat history: ${e.toString()}';
      notifyListeners();
    }
  }

  void addTextMessage(String content, {bool isMe = true}) {
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
    notifyListeners();
    
    // Save to Firebase if authenticated
    if (_firebaseChatService.userId.isNotEmpty) {
      _firebaseChatService.saveChatMessage(message);
    }

    if (isMe) {
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
    notifyListeners();
    
    // Save to Firebase if authenticated
    if (_firebaseChatService.userId.isNotEmpty) {
      _firebaseChatService.saveChatMessage(message);
    }

    if (isMe) {
      _generateBotResponse('Can you react to this GIF?');
    }
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
    notifyListeners();

    try {
      // Save to Firebase if authenticated
      if (_firebaseChatService.userId.isNotEmpty) {
        await _firebaseChatService.saveChatMessage(message);
      }
      
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
    notifyListeners();

    try {
      // Save to Firebase if authenticated
      if (_firebaseChatService.userId.isNotEmpty) {
        await _firebaseChatService.saveChatMessage(message);
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      _updateMessageStatus(messageId, MessageStatus.sent);
      
      _generateBotResponse(content);
    } catch (e) {
      _updateMessageStatus(messageId, MessageStatus.failed);
      _error = 'Failed to send message: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> sendMedia(String mediaPath, MessageType type) async {
    final messageId = _uuid.v4();
    final message = ChatMessage(
      id: messageId,
      content: mediaPath,
      isMe: true,
      timestamp: DateTime.now(),
      type: type,
      mediaUrl: mediaPath,
      status: MessageStatus.sending,
    );

    // Add to local state
    _messages.add(message);
    notifyListeners();

    try {
      // Try to upload and save to Firebase if authenticated
      if (_firebaseChatService.userId.isNotEmpty) {
        // For non-local files (e.g. from web), just save the message without uploading
        if (mediaPath.startsWith('http')) {
          await _firebaseChatService.saveChatMessage(message);
        } else {
          // For local files, upload to Firebase Storage
          await _firebaseChatService.sendMediaMessage(mediaPath, type);
        }
      }
      
      await Future.delayed(const Duration(seconds: 1));
      _updateMessageStatus(messageId, MessageStatus.sent);

      if (type == MessageType.image) {
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
    notifyListeners();

    try {
      // Try to upload and save to Firebase if authenticated
      if (_firebaseChatService.userId.isNotEmpty) {
        // For non-local files (e.g. from web), just save the message without uploading
        if (filePath.startsWith('http')) {
          await _firebaseChatService.saveChatMessage(message);
        } else {
          // For local files, upload to Firebase Storage
          await _firebaseChatService.sendFileMessage(filePath);
        }
      }
      
      await Future.delayed(const Duration(seconds: 1));
      _updateMessageStatus(messageId, MessageStatus.sent);
    } catch (e) {
      _updateMessageStatus(messageId, MessageStatus.failed);
      _error = 'Failed to send file: ${e.toString()}';
      notifyListeners();
    }
  }

  void addQuickReplyMessage(List<QuickReply> suggestedReplies) {
    final messageId = _uuid.v4();
    final message = ChatMessage(
      id: messageId,
      content: '',
      isMe: false,
      timestamp: DateTime.now(),
      type: MessageType.quickReply,
      suggestedReplies: suggestedReplies,
      status: MessageStatus.sent,
    );
    
    // Add to local state
    _messages.add(message);
    notifyListeners();
    
    // Save to Firebase if authenticated
    if (_firebaseChatService.userId.isNotEmpty) {
      _firebaseChatService.saveChatMessage(message);
    }
  }
  
  void addGeminiQuickReplyMessage(List<GeminiQuickReply> suggestedReplies) {
    final messageId = _uuid.v4();
    final message = ChatMessage(
      id: messageId,
      content: '',
      isMe: false,
      timestamp: DateTime.now(),
      type: MessageType.geminiQuickReply, // Use the new message type
      suggestedReplies: suggestedReplies,
      status: MessageStatus.sent,
    );
    
    // Add to local state
    _messages.add(message);
    notifyListeners();
    
    // Save to Firebase if authenticated
    if (_firebaseChatService.userId.isNotEmpty) {
      _firebaseChatService.saveChatMessage(message);
    }
  }

  void addReaction(String messageId, String emoji) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final message = _messages[index];
      final reaction = MessageReaction(
        emoji: emoji,
        userId: _firebaseChatService.userId.isNotEmpty ? _firebaseChatService.userId : 'current_user',
        timestamp: DateTime.now(),
      );

      final updatedReactions = List<MessageReaction>.from(message.reactions)..add(reaction);
      
      _messages[index] = message.copyWith(reactions: updatedReactions);
      notifyListeners();
      
      // Save to Firebase if authenticated
      if (_firebaseChatService.userId.isNotEmpty) {
        _firebaseChatService.addReaction(messageId, emoji);
      }
    }
  }

  void removeReaction(String messageId, String emoji) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final message = _messages[index];
      final userId = _firebaseChatService.userId.isNotEmpty ? _firebaseChatService.userId : 'current_user';
      
      final updatedReactions = List<MessageReaction>.from(message.reactions)
        ..removeWhere((r) => r.emoji == emoji && r.userId == userId);
      
      _messages[index] = message.copyWith(reactions: updatedReactions);
      notifyListeners();
      
      // Update in Firebase if authenticated
      if (_firebaseChatService.userId.isNotEmpty) {
        _firebaseChatService.removeReaction(messageId, emoji);
      }
    }
  }

  void deleteMessage(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages.removeAt(index);
      notifyListeners();
      
      // Delete from Firebase if authenticated
      if (_firebaseChatService.userId.isNotEmpty) {
        _firebaseChatService.deleteMessage(messageId);
      }
    }
  }

  void _updateMessageStatus(String messageId, MessageStatus status) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(status: status);
      notifyListeners();
      
      // Update in Firebase if authenticated
      if (_firebaseChatService.userId.isNotEmpty) {
        _firebaseChatService.saveChatMessage(_messages[index]);
      }
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
    
    // Save to Firebase if authenticated
    if (_firebaseChatService.userId.isNotEmpty) {
      _firebaseChatService.saveChatMessage(responseMessage);
    }
    
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
    
    notifyListeners();
  }
}