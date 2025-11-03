import 'package:flutter/material.dart';
import '../models/quick_reply.dart';
import '../models/chat_message.dart';
import '../services/link_preview_service.dart';
import '../utils/debug_config.dart';
import 'package:uuid/uuid.dart';

class SystemChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;
  final _uuid = Uuid();

  void addUserMessage(String content) {
    final message = ChatMessage(
      id: _uuid.v4(),
      content: content,
      isMe: true,
      timestamp: DateTime.now(),
      type: MessageType.text,
      status: MessageStatus.sent,
    );
    _messages.add(message);
    notifyListeners();

    _processLinksInMessage(message);
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

  void updateMessage(String messageId, ChatMessage updatedMessage) {
    final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
    if (messageIndex != -1) {
      _messages[messageIndex] = updatedMessage;
      notifyListeners();
    }
  }

  void addGifMessage(String gifUrl) {
    final message = ChatMessage(
      id: _uuid.v4(),
      content: gifUrl,
      isMe: true,
      timestamp: DateTime.now(),
      type: MessageType.gif,
      mediaUrl: gifUrl,
      status: MessageStatus.sent,
    );
    _messages.add(message);
    notifyListeners();
  }

  List<QuickReply> getSystemCommands() {
    return [
      QuickReply(
        text: 'Clear Chat',
        value: '/clear',
        icon: Icons.clear_all,
      ),
      QuickReply(
        text: 'Export Chat',
        value: '/export',
        icon: Icons.download,
      ),
      QuickReply(
        text: 'Theme',
        value: '/theme',
        icon: Icons.palette,
      ),
    ];
  }

  void handleSystemCommand(String command) {
    switch (command) {
      case '/clear':
        _messages.clear();
        break;
      case '/export':
        break;
      case '/theme':
        break;
    }
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}
