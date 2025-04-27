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
  
  bool _isTyping = false;
  bool get isTyping => _isTyping;
  bool get isServerServiceInitialized => _dashService.isInitialized;

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
        // User logged out
        _currentUser = null;
        notifyListeners();
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
      if (_chatProvider == null) return;
      
      // Add message to chat provider
      // Use the appropriate method based on message type
      if (message.type == MessageType.quickReply) {
        _chatProvider!.addQuickReplyMessage(message.suggestedReplies ?? []);
      } else {
        _chatProvider!.addTextMessage(message.content, isMe: message.isMe);
      }
      
    }, onError: (error) {
      print('DashChatProvider: Error listening to messages: $error');
    });
  }

  // Initialize the server message service
  void initializeServerService(String userId, String fcmToken) {
    print('[DashChatProvider] Initializing DashMessagingService for user $userId');
    _dashService.initialize(userId, fcmToken).then((_) {
      // Setup message listener after successful initialization
      if (_chatProvider != null) {
        _setupMessageListener();
      }
      notifyListeners();
    }).catchError((error) {
      print('[DashChatProvider] Error initializing DashMessagingService: $error');
    });
  }

  // Clear state on logout
  void clearOnLogout() {
    print('[DashChatProvider] Clearing state on logout.');
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _dashService.dispose();
    notifyListeners();
  }

  // Send a message 
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || _currentUser == null) {
      print('Message empty or user not logged in. Cannot send.');
      return;
    }
    
    final messageContent = message.trim();
    final userId = _currentUser!.uid;
    
    try {
      // Special command to load sample test data
      if (messageContent.toLowerCase() == '#test' || messageContent.toLowerCase() == '#sample') {
        print('[DashChatProvider] Detected test command. Processing test data...');
        // Add message to local chat UI first
        if (_chatProvider != null) {
          _chatProvider!.addTextMessage(messageContent, isMe: true);
          
          final context = ContextHolder.currentContext;
          final localizations = context != null 
              ? AppLocalizations.of(context) 
              : null;
          
          final loadingMessage = localizations?.translate('loading_sample') ?? 'Loading sample test messages...';
          _chatProvider!.addTextMessage(loadingMessage, isMe: false);
        }
        
        // Process sample test data via direct method call (no server)
        await _dashService.processSampleTestData();
        return;
      }
      
      // Important: ChatProvider adds the message to UI automatically in HomeScreen's _handleSubmitted,
      // so we don't need to add it again here to avoid duplication
      
      // If in demo mode or testing, simulate response
      if (!_dashService.isInitialized) {
        print('DashMessagingService not initialized. Using simulation mode.');
        await _dashService.simulateServerResponse(messageContent);
        return;
      }
      
      // Send message to the server via DashMessagingService
      try {
        final success = await _dashService.sendMessage(messageContent);
        if (success) {
          print('Message sent successfully to server');
        } else {
          print('Failed to send message to server');
          // If server send failed, simulate response in demo mode
          await _dashService.simulateServerResponse(messageContent);
        }
      } catch (e) {
        print('Error sending message to server: $e');
        // On error, use simulation as fallback
        await _dashService.simulateServerResponse(messageContent);
      }
    } catch (e) {
      print('Error in DashChatProvider.sendMessage: $e');
      // On error, use simulation as fallback
      await _dashService.simulateServerResponse(messageContent);
    }
  }

  // Handle quick reply selection
  Future<void> handleQuickReply(QuickReply reply) async {
    print("[HandleQuickReply] Selected reply: text='${reply.text}', value='${reply.value}'");
    
    if (reply.value.isEmpty || _currentUser == null) {
      print('[HandleQuickReply] Reply value empty or user not logged in. Cannot send.');
      return;
    }
    
    try {
      // Add the reply to the chat UI
      if (_chatProvider != null) {
        _chatProvider!.addTextMessage(reply.text, isMe: true);
      }
      
      // Process the quick reply response directly through simulation
      // This ensures consistent behavior for the demo scenarios
      await _dashService.simulateServerResponse(reply.value);
      
      // If server is initialized and we're not in demo mode, also send to server
      if (_dashService.isInitialized) {
        final success = await _dashService.sendQuickReply(reply.value, reply.text);
        if (success) {
          print('Quick reply sent successfully to server');
        } else {
          print('Failed to send quick reply to server');
        }
      }
    } catch (e) {
      print('Error handling quick reply: $e');
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

  @override
  void dispose() {
    print('DashChatProvider: Disposing...');
    _authSubscription?.cancel();
    _messageSubscription?.cancel();
    _dashService.dispose();
    super.dispose();
  }
}