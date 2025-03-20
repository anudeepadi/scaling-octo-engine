import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../services/bot_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;
  final _uuid = Uuid();
  final BotService _botService = BotService();

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
    _messages.add(message);
    notifyListeners();

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
    _messages.add(message);
    notifyListeners();

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

    _messages.add(message);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    _updateMessageStatus(messageId, MessageStatus.sent);
    
    _generateBotResponse(content);
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

    _messages.add(message);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    _updateMessageStatus(messageId, MessageStatus.sent);
    
    _generateBotResponse(content);
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

    _messages.add(message);
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    _updateMessageStatus(messageId, MessageStatus.sent);

    if (type == MessageType.image) {
      _generateBotResponse('Can you describe this image?');
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

    _messages.add(message);
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    _updateMessageStatus(messageId, MessageStatus.sent);
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
    _messages.add(message);
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
      notifyListeners();
    }
  }

  void _updateMessageStatus(String messageId, MessageStatus status) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(status: status);
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
    
    _messages.add(responseMessage);
    
    final quickReplies = BotService.getQuickReplies(response)
        .map((qr) => QuickReply(
              text: qr['text']!,
              value: qr['value']!,
            ))
        .toList();
        
    if (quickReplies.isNotEmpty) {
      addQuickReplyMessage(quickReplies);
    }
    
    notifyListeners();
  }
}