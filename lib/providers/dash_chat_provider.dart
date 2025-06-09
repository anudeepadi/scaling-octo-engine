import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../services/dash_messaging_service.dart';
import '../utils/app_localizations.dart';
import '../utils/context_holder.dart';
import 'chat_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class DashChatProvider extends ChangeNotifier {
  final DashMessagingService _dashService = DashMessagingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  ChatProvider? _chatProvider;
  StreamSubscription? _authSubscription;
  StreamSubscription? _messageSubscription;
  User? _currentUser;
  String? _fcmToken;
  
  bool _isTyping = false;
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
    print('DashChatProvider: Initializing...');
    if (_auth == null) {
      print('ERROR: DashChatProvider._auth is NULL immediately after assignment!');
    } else {
      print('DashChatProvider: _auth initialized successfully.');
    }
    _listenToAuthChanges();
  }

  // Method to link to the ChatProvider instance
  void setChatProvider(ChatProvider chatProvider) {
    _chatProvider = chatProvider;
    print('DashChatProvider: Linked with ChatProvider.');
    
    // If user is already logged in when linked, setup listeners
    if (_currentUser != null) {
      _setupMessageListener();
    }
  }

  void _listenToAuthChanges() {
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      print('DashChatProvider: Auth state changed. User: ${user?.uid}');
      if (user == null) {
        // User logged out - clear all state
        clearOnLogout();
      } else {
        // User logged in
        _currentUser = user;
        if (_chatProvider != null) {
           _setupMessageListener();
        } else {
           print('DashChatProvider: User logged in, but ChatProvider not linked yet.');
        }
        notifyListeners();
      }
    });
  }
        
  void _setupMessageListener() {
    // Cancel any previous message subscription
    _messageSubscription?.cancel();

    // Clear existing messages
    _chatProvider?.clearChatHistory();
    print('DashChatProvider: Cleared chat history before setting up new listener.');

    // Subscribe to the DashMessagingService message stream
    _messageSubscription = _dashService.messageStream.listen((message) {
      if (_chatProvider == null) {
        print('DashChatProvider: ChatProvider is null, cannot add message.');
        return;
      }
      
      print('DashChatProvider: Received message from stream: ${message.id}, type: ${message.type}, content: ${message.content.substring(0, message.content.length > 30 ? 30 : message.content.length)}...');
      
      // Add message to chat provider
      // Use the appropriate method based on message type
      if (message.type == MessageType.quickReply) {
        print('DashChatProvider: Adding quick reply message with ${message.suggestedReplies?.length ?? 0} options');
        _chatProvider!.addQuickReplyMessage(message.suggestedReplies ?? []);
      } else {
        // Skip server status messages
        if (message.content.startsWith('Using server:')) {
          print('DashChatProvider: Skipping server status message');
          return;
        }
        print('DashChatProvider: Adding text message (from ${message.isMe ? "user" : "server"})');
        _chatProvider!.addTextMessage(message.content, isMe: message.isMe);
      }
      
    }, onError: (error) {
      print('DashChatProvider: Error listening to messages: $error');
    });
    
    print('DashChatProvider: Message listener set up successfully');
  }

  // Initialize the server message service
  void initializeServerService(String userId, String fcmToken) {
    print('[DashChatProvider] Initializing DashMessagingService for user $userId');
    _dashService.initialize(userId).then((_) {
      print('[DashChatProvider] DashMessagingService initialized successfully');
      // Setup message listener after successful initialization
      if (_chatProvider != null) {
        _setupMessageListener();
        print('[DashChatProvider] Message listener set up');
      } else {
        print('[DashChatProvider] Warning: ChatProvider is null, cannot set up message listener');
      }
      notifyListeners();
    }).catchError((error) {
      print('[DashChatProvider] Error initializing DashMessagingService: $error');
    });
  }

  // Clear state on logout
  void clearOnLogout() {
    print('[DashChatProvider] Clearing state on logout.');
    
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
      print('Message empty or user not logged in. Cannot send.');
      return;
    }
    
    final messageContent = message.trim();
    final userId = _currentUser!.uid;
    
    // Prevent duplicate sends (debounce)
    if (_isSendingMessage) {
      print('Already sending a message. Ignoring duplicate request.');
      return;
    }
    
    // Check for rapid duplicate messages
    if (_lastMessageSent == messageContent && _lastSendTime != null) {
      final timeSinceLastSend = DateTime.now().difference(_lastSendTime!);
      if (timeSinceLastSend.inSeconds < 2) {
        print('Duplicate message detected within 2 seconds. Ignoring: $messageContent');
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
        print('DashMessagingService not initialized. Initializing now.');
        await _dashService.initialize(_currentUser!.uid);
      }
      
      // Send message to the server via DashMessagingService
      try {
        final success = await _dashService.sendMessage(messageContent);
        if (success) {
          print('Message sent successfully to server');
        } else {
          print('Failed to send message to server - check server logs');
        }
      } catch (e) {
        print('Error sending message to server: $e');
      }
    } catch (e) {
      print('Error in DashChatProvider.sendMessage: $e');
    } finally {
      // Reset debounce flags
      _isSendingMessage = false;
    }
  }
  
  // Handle quick reply selection
  Future<void> handleQuickReply(QuickReply reply) async {
    print("[HandleQuickReply] Selected reply: text='${reply.text}', value='${reply.value}'");
    
    if (reply.value.isEmpty || _currentUser == null) {
      print('[HandleQuickReply] Reply value empty or user not logged in. Cannot send.');
      return;
    }
    
    // Prevent duplicate sends
    if (_isSendingMessage) {
      print('Already sending a message. Ignoring duplicate quick reply.');
      return;
    }
    
    _isSendingMessage = true;
    
    try {
      // Add the reply to the chat UI
      if (_chatProvider != null) {
        _chatProvider!.addTextMessage(reply.text, isMe: true);
      }
      
      // If in demo mode or testing, simulate response
      if (!_dashService.isInitialized) {
        print('DashMessagingService not initialized. Using simulation mode.');
        await _dashService.simulateServerResponse(reply.text);
        return;
      }
      
      // Send the quick reply to the server
      final success = await _dashService.sendQuickReply(reply.value, reply.text);
      if (success) {
        print('Quick reply sent successfully to server');
      } else {
        print('Failed to send quick reply to server');
        // If server send failed, simulate response in demo mode
        await _dashService.simulateServerResponse(reply.text);
      }
    } catch (e) {
      print('Error sending quick reply: $e');
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
      print('Host URL updated successfully');
    } catch (e) {
      print('Error updating host URL: $e');
      throw Exception('Failed to update host URL: $e');
    }
  }

  // Process custom JSON input
  Future<void> processCustomJsonInput(String jsonInput) async {
    if (jsonInput.trim().isEmpty || _currentUser == null) {
      print('JSON input empty or user not logged in. Cannot process.');
      return;
    }
    
    _isSendingMessage = true;
    
    try {
      print('[DashChatProvider] Processing custom JSON input');
      
      // Call the service method to process the custom JSON
      if (_dashService.isInitialized) {
        await _dashService.processCustomJsonInput(jsonInput);
      } else {
        print('DashMessagingService not initialized. Cannot process custom JSON.');
      }
    } catch (e) {
      print('Error processing custom JSON input: $e');
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
    print('DashChatProvider: Disposing...');
    _authSubscription?.cancel();
    _messageSubscription?.cancel();
    _dashService.dispose();
    super.dispose();
  }
  
  // Force a manual sync of messages from Firestore
  void forceMessageSync() {
    print('[DashChatProvider] Manually forcing message sync');
    
    if (!_dashService.isInitialized) {
      print('[DashChatProvider] Cannot force sync - DashMessagingService not initialized');
      return;
    }
    
    // Reset the last message time to force a full refresh
    _dashService.resetLastMessageTime();
  }
  
  // Force reload messages from Firestore
  void forceMessageReload() {
    print('[DashChatProvider] Forcing message reload');
    
    if (!_dashService.isInitialized) {
      print('[DashChatProvider] Cannot force reload - DashMessagingService not initialized');
      return;
    }
    
    // Clear current chat history
    _chatProvider?.clearChatHistory();
    
    // Reset the last message time and reload
    _dashService.resetLastMessageTime();
    
    // Re-setup message listener to get fresh messages
    _setupMessageListener();
  }
}