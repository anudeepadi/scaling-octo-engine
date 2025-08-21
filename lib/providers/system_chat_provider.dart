import 'package:flutter/material.dart';
import '../models/quick_reply.dart';
import '../models/chat_message.dart';
import '../models/link_preview.dart';
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
    
    // Check for links and fetch preview asynchronously
    _processLinksInMessage(message);
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
    
    try {
      final linkPreview = await LinkPreviewService.fetchLinkPreview(url);
      if (linkPreview != null) {
        // Update the message with link preview
        final updatedMessage = message.copyWith(
          linkPreview: linkPreview,
          type: MessageType.linkPreview,
        );
        updateMessage(message.id, updatedMessage);
      }
    } catch (e) {
      DebugConfig.debugPrint('SystemChatProvider: Error processing link preview: $e');
    }
  }
  
  // Update message by ID
  void updateMessage(String messageId, ChatMessage updatedMessage) {
    final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
    if (messageIndex != -1) {
      _messages[messageIndex] = updatedMessage;
      notifyListeners();
      DebugConfig.debugPrint('SystemChatProvider: Updated message $messageId with link preview');
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
        // Implement export functionality
        break;
      case '/theme':
        // Implement theme switching
        break;
    }
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}