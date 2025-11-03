import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../services/dash_messaging_service.dart';
import '../services/firebase_messaging_service.dart';
import '../utils/debug_config.dart';
import 'chat_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashChatProvider extends ChangeNotifier {
  final DashMessagingService _dashService = DashMessagingService();
  final FirebaseMessagingService _firebaseMessagingService = FirebaseMessagingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ChatProvider? _chatProvider;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<ChatMessage>? _messageSubscription;
  User? _currentUser;
  String? _fcmToken;

  final bool _isTyping = false;
  bool get isTyping => _isTyping;
  bool get isServerServiceInitialized => _dashService.isInitialized;

  bool _isSendingMessage = false;
  bool get isSendingMessage => _isSendingMessage;
  String? _lastMessageSent;
  DateTime? _lastSendTime;

  List<ChatMessage> get messages => _chatProvider?.messages ?? [];
  bool get isLoading => _chatProvider?.isLoading ?? false;

  DashChatProvider() {
    _listenToAuthChanges();
  }

  void setChatProvider(ChatProvider chatProvider) {
    _chatProvider = chatProvider;
    _removeExistingEmojiTestMessages();

    if (_currentUser != null) {
      _setupMessageListener();
    }
  }

  Future<void> clearAllMessages() async {
    if (_currentUser == null) return;

    try {
      if (_chatProvider != null) {
        _chatProvider!.clearMessages();
      }

      _dashService.clearCache();
      await _dashService.clearAllMessagesInFirebase();
      notifyListeners();
    } catch (e) {
      DebugConfig.debugPrint('Error clearing messages: $e');
    }
  }

  void _listenToAuthChanges() {
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        clearOnLogout();
      } else {
        _currentUser = user;
        if (_chatProvider != null) {
          _setupMessageListener();
        }
        notifyListeners();
      }
    });
  }

  void _setupMessageListener() {
    _messageSubscription?.cancel();

    _messageSubscription = _dashService.messageStream.listen((message) {
      if (_chatProvider == null) return;

      if (message.content.startsWith('Using server:')) return;

      _chatProvider!.addMessage(message);
      notifyListeners();
    }, onError: (error) {
      DebugConfig.debugPrint('Error listening to messages: $error');
    });
  }

  Future<void> initializeServerService(String userId, String fcmToken) async {
    try {
      await _dashService.initialize(userId, fcmToken);

      if (_chatProvider != null) {
        _setupMessageListener();

        Future.delayed(const Duration(milliseconds: 500), () {
          forceMessageReload();
        });
      }
      notifyListeners();
    } catch (error) {
      DebugConfig.debugPrint('Error initializing DashMessagingService: $error');
      rethrow;
    }
  }

  void clearOnLogout() {
    _messageSubscription?.cancel();
    _messageSubscription = null;

    if (_chatProvider != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _chatProvider?.clearChatHistory();
      });
    }

    _dashService.dispose();

    _isSendingMessage = false;
    _lastMessageSent = null;
    _lastSendTime = null;
    _currentUser = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || _currentUser == null) return;

    final messageContent = message.trim();

    if (_isSendingMessage) return;

    if (_lastMessageSent == messageContent && _lastSendTime != null) {
      final timeSinceLastSend = DateTime.now().difference(_lastSendTime!);
      if (timeSinceLastSend.inSeconds < 2) return;
    }

    _isSendingMessage = true;
    _lastMessageSent = messageContent;
    _lastSendTime = DateTime.now();

    try {
      if (!_dashService.isInitialized && _currentUser != null) {
        await _dashService.initialize(_currentUser!.uid, await _firebaseMessagingService.getFcmToken());
      }

      try {
        await _dashService.sendMessage(messageContent);
      } catch (e) {
        DebugConfig.debugPrint('Error sending message: $e');
      }
    } catch (e) {
      DebugConfig.debugPrint('Error in sendMessage: $e');
    } finally {
      _isSendingMessage = false;
    }
  }

  Future<void> handleQuickReply(QuickReply reply) async {
    if (reply.value.isEmpty || _currentUser == null) return;

    if (_isSendingMessage) return;

    _isSendingMessage = true;

    try {
      if (!_dashService.isInitialized) {
        if (_chatProvider != null) {
          _chatProvider!.addTextMessage(reply.text, isMe: true);
          notifyListeners();
        }
        await _dashService.simulateServerResponse(reply.text);
        return;
      }

      await _dashService.sendQuickReply(reply.value, reply.text);
    } catch (e) {
      DebugConfig.debugPrint('Error sending quick reply: $e');
      await _dashService.simulateServerResponse(reply.text);
    } finally {
      _isSendingMessage = false;
    }
  }

  Future<void> updateHostUrl(String newUrl) async {
    try {
      await _dashService.updateHostUrl(newUrl);
    } catch (e) {
      DebugConfig.debugPrint('Error updating host URL: $e');
      throw Exception('Failed to update host URL: $e');
    }
  }

  Future<void> updateServerUrl(String newUrl) async {
    return updateHostUrl(newUrl);
  }

  Future<void> processCustomJsonInput(String jsonInput) async {
    if (jsonInput.trim().isEmpty || _currentUser == null) return;

    _isSendingMessage = true;

    try {
      if (_dashService.isInitialized) {
        await _dashService.processCustomJsonInput(jsonInput);
      }
    } catch (e) {
      DebugConfig.debugPrint('Error processing custom JSON: $e');
    } finally {
      _isSendingMessage = false;
    }
  }

  String getAndroidDebugInfo() {
    final buffer = StringBuffer();
    buffer.writeln('User ID: ${_currentUser?.uid ?? "null"}');
    buffer.writeln('FCM Token: ${_fcmToken ?? "null"}');
    buffer.writeln('Service Initialized: ${_dashService.isInitialized}');
    buffer.writeln('Is Sending: $_isSendingMessage');
    buffer.writeln('Messages Count: ${messages.length}');
    buffer.writeln('Auth State: ${_currentUser != null ? "logged in" : "logged out"}');
    buffer.writeln('Last Message: $_lastMessageSent');
    buffer.writeln('Last Send Time: $_lastSendTime');
    return buffer.toString();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _messageSubscription?.cancel();
    _dashService.dispose();
    super.dispose();
  }

  void forceMessageSync() {
    if (!_dashService.isInitialized) return;
    _dashService.resetLastMessageTime();
  }

  Future<void> forceMessageReload() async {
    if (!_dashService.isInitialized) return;

    _chatProvider?.clearChatHistory();
    notifyListeners();

    try {
      await _dashService.forceReloadMessages();
    } catch (e) {
      DebugConfig.debugPrint('Error during force reload: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getConversationHistory({int limit = 20}) async {
    if (!_dashService.isInitialized) return [];

    try {
      return await _dashService.getConversationHistory(limit: limit);
    } catch (e) {
      DebugConfig.debugPrint('Error getting conversation history: $e');
      return [];
    }
  }

  Future<void> verifyMessageOrdering() async {
    if (!_dashService.isInitialized) return;

    try {
      await _dashService.verifyMessageOrdering();
    } catch (e) {
      DebugConfig.debugPrint('Error verifying message ordering: $e');
    }
  }

  Future<void> debugMessageAlignment() async {
    if (!_dashService.isInitialized) return;

    try {
      await _dashService.debugMessageAlignment();
    } catch (e) {
      DebugConfig.debugPrint('Error debugging message alignment: $e');
    }
  }

  void debugMessageOrdering() {
    if (_chatProvider == null) return;

    _chatProvider!.verifyMessageOrder();
  }

  Future<void> testChronologicalOrdering() async {
    if (!_dashService.isInitialized) return;

    try {
      _chatProvider?.clearChatHistory();
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));
      await _dashService.loadExistingMessages();
      await _dashService.verifyMessageOrdering();
    } catch (e) {
      DebugConfig.debugPrint('Error testing chronological ordering: $e');
    }
  }

  Future<void> refreshMessages() async {
    if (!_dashService.isInitialized) return;

    try {
      await _dashService.loadExistingMessages();
    } catch (e) {
      DebugConfig.debugPrint('Error refreshing messages: $e');
    }
  }

  void _removeExistingEmojiTestMessages() {
    if (_chatProvider == null) return;

    final emojiTestMessages = _chatProvider!.messages
        .where((msg) => msg.id.startsWith('emoji_test_'))
        .toList();

    if (emojiTestMessages.isNotEmpty) {
      for (final msg in emojiTestMessages) {
        _chatProvider!.removeMessage(msg.id);
      }
    }
  }

  Future<void> testMessageShifting() async {
    if (!_dashService.isInitialized) return;

    try {
      if (_chatProvider != null && _chatProvider!.messages.length > 1) {
        final originalMessages = List<ChatMessage>.from(_chatProvider!.messages);

        _chatProvider!.clearChatHistory();
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 500));
        await _dashService.loadExistingMessages();
      }
    } catch (e) {
      DebugConfig.debugPrint('Error testing message shifting: $e');
    }
  }

  bool _messageShiftingEnabled = true;
  bool get messageShiftingEnabled => _messageShiftingEnabled;

  void toggleMessageShifting() {
    _messageShiftingEnabled = !_messageShiftingEnabled;
    notifyListeners();
  }

  void debugComprehensiveMessageOrdering() {
    if (_chatProvider == null) return;
    _chatProvider!.debugAllMessageOrdering();
  }
}
