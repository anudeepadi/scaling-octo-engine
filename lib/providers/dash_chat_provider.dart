import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../services/dash_messaging_service.dart';
import '../utils/debug_config.dart';
import 'chat_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashChatProvider extends ChangeNotifier {
  final DashMessagingService _dashService = DashMessagingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  ChatProvider? _chatProvider;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<ChatMessage>? _messageSubscription;
  User? _currentUser;
  String? _fcmToken;
  
  final bool _isTyping = false;
  bool get isTyping => _isTyping;
  bool get isServerServiceInitialized => _dashService.isInitialized;
  
  // Add debounce variables to prevent double sends
  bool _isSendingMessage = false;
  bool get isSendingMessage => _isSendingMessage;
  String? _lastMessageSent;
  DateTime? _lastSendTime;
  
  // Delegate messages to ChatProvider
  List<ChatMessage> get messages => _chatProvider?.messages ?? [];
  
  // Delegate isLoading to ChatProvider
  bool get isLoading => _chatProvider?.isLoading ?? false;

  // Constructor
  DashChatProvider() {
    DebugConfig.debugPrint('DashChatProvider: Initializing...');
    _listenToAuthChanges();
  }

  // Method to link to the ChatProvider instance
  void setChatProvider(ChatProvider chatProvider) {
    _chatProvider = chatProvider;
    DebugConfig.debugPrint('DashChatProvider: Linked with ChatProvider.');
    
    // If user is already logged in when linked, setup listeners
    if (_currentUser != null) {
      _setupMessageListener();
    }
  }

  void _listenToAuthChanges() {
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      DebugConfig.debugPrint('DashChatProvider: Auth state changed. User: ${user?.uid}');
      if (user == null) {
        // User logged out - clear all state
        clearOnLogout();
      } else {
        // User logged in
        _currentUser = user;
        if (_chatProvider != null) {
          _setupMessageListener();
        } else {
          DebugConfig.debugPrint('DashChatProvider: User logged in, but ChatProvider not linked yet.');
        }
        notifyListeners();
      }
    });
  }
        
  void _setupMessageListener() {
    // Cancel any previous message subscription
    _messageSubscription?.cancel();

    DebugConfig.debugPrint('DashChatProvider: Setting up message listener (keeping existing messages).');

    // Subscribe to the DashMessagingService message stream
    _messageSubscription = _dashService.messageStream.listen((message) {
      if (_chatProvider == null) {
        DebugConfig.debugPrint('DashChatProvider: ChatProvider is null, cannot add message.');
        return;
      }
      
      DebugConfig.messagingPrint('DashChatProvider: Received message from stream: ${message.id}, type: ${message.type}, content: ${message.content.substring(0, message.content.length > 30 ? 30 : message.content.length)}...');
      
      // Skip server status messages
      if (message.content.startsWith('Using server:')) {
        DebugConfig.debugPrint('DashChatProvider: Skipping server status message');
        return;
      }
      
      // FIXED: Add the complete message directly instead of recreating it
      // This preserves all the original message data including suggestedReplies
      if (message.type == MessageType.quickReply) {
        DebugConfig.debugPrint('DashChatProvider: Adding quick reply message with ${message.suggestedReplies?.length ?? 0} options directly');
      } else {
        DebugConfig.debugPrint('DashChatProvider: Adding text message (from ${message.isMe ? "user" : "server"}) directly');
      }
      
      // Add the complete message to the ChatProvider using the public method
      _chatProvider!.addMessage(message);
      
      // CRITICAL FIX: Notify DashChatProvider listeners so UI updates
      DebugConfig.debugPrint('DashChatProvider: Notifying listeners after message added');
      notifyListeners();
      
    }, onError: (error) {
      DebugConfig.debugPrint('DashChatProvider: Error listening to messages: $error');
    });
    
    DebugConfig.debugPrint('DashChatProvider: Message listener set up successfully');
  }

  // Initialize the server message service
  Future<void> initializeServerService(String userId, String fcmToken) async {
    DebugConfig.debugPrint('[DashChatProvider] Initializing DashMessagingService for user $userId');
    try {
      await _dashService.initialize(userId);
      DebugConfig.debugPrint('[DashChatProvider] DashMessagingService initialized successfully');
      
      // Setup message listener after successful initialization
      if (_chatProvider != null) {
        _setupMessageListener();
        DebugConfig.debugPrint('[DashChatProvider] Message listener set up');
        
        // Force reload all messages to ensure they use the new unified format
        Future.delayed(const Duration(milliseconds: 500), () {
          forceMessageReload();
        });
      } else {
        DebugConfig.debugPrint('[DashChatProvider] Warning: ChatProvider is null, cannot set up message listener');
      }
      notifyListeners();
    } catch (error) {
      DebugConfig.debugPrint('[DashChatProvider] Error initializing DashMessagingService: $error');
      rethrow; // Re-throw to let the caller handle the error
    }
  }

  // Clear state on logout
  void clearOnLogout() {
    DebugConfig.debugPrint('[DashChatProvider] Clearing state on logout.');
    
    // Cancel subscriptions
    _messageSubscription?.cancel();
    _messageSubscription = null;
    
    // Clear chat history from ChatProvider - defer to avoid setState during build
    if (_chatProvider != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _chatProvider?.clearChatHistory();
      });
    }
    
    // Dispose the messaging service
    _dashService.dispose();
    
    // Reset debounce flags
    _isSendingMessage = false;
    _lastMessageSent = null;
    _lastSendTime = null;
    
    // Clear current user
    _currentUser = null;
    
    // Defer notifyListeners to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Send a message 
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || _currentUser == null) {
      DebugConfig.debugPrint('Message empty or user not logged in. Cannot send.');
      return;
    }
    
    final messageContent = message.trim();
    
    // Prevent duplicate sends (debounce)
    if (_isSendingMessage) {
      DebugConfig.debugPrint('Already sending a message. Ignoring duplicate request.');
      return;
    }
    
    // Check for rapid duplicate messages
    if (_lastMessageSent == messageContent && _lastSendTime != null) {
      final timeSinceLastSend = DateTime.now().difference(_lastSendTime!);
      if (timeSinceLastSend.inSeconds < 2) {
        DebugConfig.debugPrint('Duplicate message detected within 2 seconds. Ignoring: $messageContent');
        return;
      }
    }
    
    // Set debounce flags
    _isSendingMessage = true;
    _lastMessageSent = messageContent;
    _lastSendTime = DateTime.now();
    
    try {
      // If the messaging service is not initialized, initialize it now
      if (!_dashService.isInitialized && _currentUser != null) {
        DebugConfig.debugPrint('DashMessagingService not initialized. Initializing now.');
        await _dashService.initialize(_currentUser!.uid);
      }
      
      // Send message to the server via DashMessagingService
      try {
        final success = await _dashService.sendMessage(messageContent);
        if (success) {
          DebugConfig.debugPrint('Message sent successfully to server');
        } else {
          DebugConfig.debugPrint('Failed to send message to server - check server logs');
        }
      } catch (e) {
        DebugConfig.debugPrint('Error sending message to server: $e');
      }
    } catch (e) {
      DebugConfig.debugPrint('Error in DashChatProvider.sendMessage: $e');
    } finally {
      // Reset debounce flags
      _isSendingMessage = false;
    }
  }
  
  // Handle quick reply selection
  Future<void> handleQuickReply(QuickReply reply) async {
    DebugConfig.debugPrint("[HandleQuickReply] Selected reply: text='${reply.text}', value='${reply.value}'");
    
    if (reply.value.isEmpty || _currentUser == null) {
      DebugConfig.debugPrint('[HandleQuickReply] Reply value empty or user not logged in. Cannot send.');
      return;
    }
    
    // Prevent duplicate sends
    if (_isSendingMessage) {
      DebugConfig.debugPrint('Already sending a message. Ignoring duplicate quick reply.');
      return;
    }
    
    _isSendingMessage = true;
    
    try {
      // REMOVED: Don't add the reply to chat UI here - let DashMessagingService handle it
      // This prevents duplicate messages and ensures proper chronological ordering
      
      // If in demo mode or testing, simulate response
      if (!_dashService.isInitialized) {
        DebugConfig.debugPrint('DashMessagingService not initialized. Using simulation mode.');
        // Add user message only in demo mode when service isn't handling it
        if (_chatProvider != null) {
          _chatProvider!.addTextMessage(reply.text, isMe: true);
          notifyListeners();
        }
        await _dashService.simulateServerResponse(reply.text);
        return;
      }
      
      // Send the quick reply to the server
      // DashMessagingService.sendQuickReply() will handle adding the user message to the stream
      // with proper timestamps and chronological ordering
      final success = await _dashService.sendQuickReply(reply.value, reply.text);
      if (success) {
        DebugConfig.debugPrint('Quick reply sent successfully to server');
      } else {
        DebugConfig.debugPrint('Failed to send quick reply to server');
        // If server send failed, simulate response in demo mode
        await _dashService.simulateServerResponse(reply.text);
      }
    } catch (e) {
      DebugConfig.debugPrint('Error sending quick reply: $e');
      // On error, use simulation as fallback
      await _dashService.simulateServerResponse(reply.text);
    } finally {
      _isSendingMessage = false;
    }
  }

  // Method to update the host URL
  Future<void> updateHostUrl(String newUrl) async {
    try {
      await _dashService.updateHostUrl(newUrl);
      DebugConfig.debugPrint('Host URL updated successfully');
    } catch (e) {
      DebugConfig.debugPrint('Error updating host URL: $e');
      throw Exception('Failed to update host URL: $e');
    }
  }

  // Alias method for updateHostUrl to match screen calls
  Future<void> updateServerUrl(String newUrl) async {
    return updateHostUrl(newUrl);
  }

  // Process custom JSON input
  Future<void> processCustomJsonInput(String jsonInput) async {
    if (jsonInput.trim().isEmpty || _currentUser == null) {
      DebugConfig.debugPrint('JSON input empty or user not logged in. Cannot process.');
      return;
    }
    
    _isSendingMessage = true;
    
    try {
      DebugConfig.debugPrint('[DashChatProvider] Processing custom JSON input');
      
      // Call the service method to process the custom JSON
      if (_dashService.isInitialized) {
        await _dashService.processCustomJsonInput(jsonInput);
      } else {
        DebugConfig.debugPrint('DashMessagingService not initialized. Cannot process custom JSON.');
      }
    } catch (e) {
      DebugConfig.debugPrint('Error processing custom JSON input: $e');
    } finally {
      _isSendingMessage = false;
    }
  }

  // Get Android debug info
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
    DebugConfig.debugPrint('DashChatProvider: Disposing...');
    _authSubscription?.cancel();
    _messageSubscription?.cancel();
    _dashService.dispose();
    super.dispose();
  }
  
  // Force a manual sync of messages from Firestore
  void forceMessageSync() {
    DebugConfig.debugPrint('[DashChatProvider] Manually forcing message sync');
    
    if (!_dashService.isInitialized) {
      DebugConfig.debugPrint('[DashChatProvider] Cannot force sync - DashMessagingService not initialized');
      return;
    }
    
    // Reset the last message time to force a full refresh
    _dashService.resetLastMessageTime();
  }
  
  // Force reload messages from Firestore
  Future<void> forceMessageReload() async {
    DebugConfig.debugPrint('[DashChatProvider] Forcing message reload with cache clear');
    
    if (!_dashService.isInitialized) {
      DebugConfig.debugPrint('[DashChatProvider] Cannot force reload - DashMessagingService not initialized');
      return;
    }
    
    // Clear current chat history
    _chatProvider?.clearChatHistory();
    
    // Notify listeners after clearing chat
    notifyListeners();
    
    try {
      // Use the new unified force reload method
      await _dashService.forceReloadMessages();
      DebugConfig.debugPrint('[DashChatProvider] ✅ Force reload completed successfully');
    } catch (e) {
      DebugConfig.debugPrint('[DashChatProvider] Error during force reload: $e');
    }
  }

  // Get conversation history from Firebase (for debugging/verification)
  Future<List<Map<String, dynamic>>> getConversationHistory({int limit = 20}) async {
    if (!_dashService.isInitialized) {
      DebugConfig.debugPrint('[DashChatProvider] Service not initialized, cannot get conversation history');
      return [];
    }
    
    try {
      return await _dashService.getConversationHistory(limit: limit);
    } catch (e) {
      DebugConfig.debugPrint('[DashChatProvider] Error getting conversation history: $e');
      return [];
    }
  }

  // Verify message ordering (for debugging)
  Future<void> verifyMessageOrdering() async {
    if (!_dashService.isInitialized) {
      DebugConfig.debugPrint('[DashChatProvider] Service not initialized, cannot verify message ordering');
      return;
    }
    
    try {
      await _dashService.verifyMessageOrdering();
    } catch (e) {
      DebugConfig.debugPrint('[DashChatProvider] Error verifying message ordering: $e');
    }
  }

  // Debug message alignment fix
  Future<void> debugMessageAlignment() async {
    if (!_dashService.isInitialized) {
      DebugConfig.debugPrint('[DashChatProvider] Service not initialized, cannot debug alignment');
      return;
    }
    
    try {
      await _dashService.debugMessageAlignment();
    } catch (e) {
      DebugConfig.debugPrint('[DashChatProvider] Error debugging message alignment: $e');
    }
  }

  // Debug chronological message ordering
  void debugMessageOrdering() {
    if (_chatProvider == null) {
      DebugConfig.debugPrint('[DashChatProvider] ChatProvider not available, cannot debug message ordering');
      return;
    }
    
    DebugConfig.debugPrint('[DashChatProvider] 🔍 Debugging message ordering (chronological by timestamp)...');
    DebugConfig.debugPrint('[DashChatProvider] Total messages: ${_chatProvider!.messages.length}');
    
    // Verify chronological order is maintained
    _chatProvider!.verifyMessageOrder();
    DebugConfig.debugPrint('[DashChatProvider] ✅ Message ordering debug completed');
  }

  // Test chronological ordering by clearing and reloading
  Future<void> testChronologicalOrdering() async {
    if (!_dashService.isInitialized) {
      DebugConfig.debugPrint('[DashChatProvider] Service not initialized, cannot test ordering');
      return;
    }
    
    try {
      DebugConfig.debugPrint('[DashChatProvider] 🧪 Testing chronological ordering...');
      
      // Clear current messages
      _chatProvider?.clearChatHistory();
      notifyListeners();
      
      // Wait a moment for UI to update
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Reload messages
      await _dashService.loadExistingMessages();
      
      // Verify ordering
      await _dashService.verifyMessageOrdering();
      
      DebugConfig.debugPrint('[DashChatProvider] ✅ Chronological ordering test completed');
    } catch (e) {
      DebugConfig.debugPrint('[DashChatProvider] Error testing chronological ordering: $e');
    }
  }
  
  // Refresh messages from server (called when app resumes)
  Future<void> refreshMessages() async {
    if (!_dashService.isInitialized) {
      DebugConfig.debugPrint('[DashChatProvider] Service not initialized, cannot refresh messages');
      return;
    }
    
    try {
      DebugConfig.debugPrint('[DashChatProvider] 🔄 Refreshing messages from server...');
      await _dashService.loadExistingMessages();
      DebugConfig.debugPrint('[DashChatProvider] ✅ Messages refreshed successfully');
    } catch (e) {
      DebugConfig.debugPrint('[DashChatProvider] ❌ Error refreshing messages: $e');
    }
  }

  // Test message shifting functionality
  Future<void> testMessageShifting() async {
    if (!_dashService.isInitialized) {
      DebugConfig.debugPrint('[DashChatProvider] Service not initialized, cannot test message shifting');
      return;
    }
    
    try {
      DebugConfig.debugPrint('[DashChatProvider] 🧪 Testing message shifting functionality...');
      
      // Simulate message shifting by reordering some messages temporarily
      if (_chatProvider != null && _chatProvider!.messages.length > 1) {
        final originalMessages = List<ChatMessage>.from(_chatProvider!.messages);
        DebugConfig.debugPrint('[DashChatProvider] Original message count: ${originalMessages.length}');
        
        // Test by clearing and reloading to see if order is maintained
        _chatProvider!.clearChatHistory();
        notifyListeners();
        
        // Wait a moment
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Reload from service
        await _dashService.loadExistingMessages();
        
        DebugConfig.debugPrint('[DashChatProvider] Message shifting test completed');
        DebugConfig.debugPrint('[DashChatProvider] Message count after reload: ${_chatProvider!.messages.length}');
      } else {
        DebugConfig.debugPrint('[DashChatProvider] Not enough messages to test shifting (need at least 2)');
      }
    } catch (e) {
      DebugConfig.debugPrint('[DashChatProvider] Error testing message shifting: $e');
    }
  }

  // Message shifting toggle state
  bool _messageShiftingEnabled = true;
  bool get messageShiftingEnabled => _messageShiftingEnabled;

  // Toggle message shifting functionality on/off
  void toggleMessageShifting() {
    _messageShiftingEnabled = !_messageShiftingEnabled;
    DebugConfig.debugPrint('[DashChatProvider] Message shifting ${_messageShiftingEnabled ? "enabled" : "disabled"}');
    
    if (_messageShiftingEnabled) {
      DebugConfig.debugPrint('[DashChatProvider] ✅ Message shifting is now ENABLED - messages will be ordered chronologically');
    } else {
      DebugConfig.debugPrint('[DashChatProvider] ⚠️ Message shifting is now DISABLED - messages will maintain original order');
    }
    
    // Notify listeners to update UI if needed
    notifyListeners();
  }


}