import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import 'dash_messaging_service.dart';
import '../utils/debug_config.dart';

class AndroidMessagingDebug {
  static final AndroidMessagingDebug _instance = AndroidMessagingDebug._internal();
  factory AndroidMessagingDebug() => _instance;
  AndroidMessagingDebug._internal();

  final DashMessagingService _dashService = DashMessagingService();
  StreamSubscription<ChatMessage>? _debugSubscription;
  
  // Debug flags
  bool _isDebugging = false;
  int _messagesReceived = 0;
  int _messagesProcessed = 0;
  
  void startDebugging(String userId) {
    if (!Platform.isAndroid) {
      DebugConfig.debugPrint('AndroidMessagingDebug: Not running on Android, skipping debug');
      return;
    }
    
    if (_isDebugging) {
      DebugConfig.debugPrint('AndroidMessagingDebug: Already debugging, stopping previous session');
      stopDebugging();
    }
    
    _isDebugging = true;
    _messagesReceived = 0;
    _messagesProcessed = 0;
    
    DebugConfig.debugPrint('🔍 AndroidMessagingDebug: Starting debug session for user: $userId');
    DebugConfig.debugPrint('🔍 Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
    
    // Test 1: Check if DashMessagingService is initialized
    _testServiceInitialization(userId);
    
    // Test 2: Check Firestore connection
    _testFirestoreConnection(userId);
    
    // Test 3: Monitor message stream
    _monitorMessageStream();
    
    // Test 4: Test stream controller directly
    _testStreamController();
  }
  
  void stopDebugging() {
    DebugConfig.debugPrint('🔍 AndroidMessagingDebug: Stopping debug session');
    DebugConfig.debugPrint('🔍 Final stats - Received: $_messagesReceived, Processed: $_messagesProcessed');
    
    _debugSubscription?.cancel();
    _debugSubscription = null;
    _isDebugging = false;
  }
  
  void _testServiceInitialization(String userId) {
    DebugConfig.debugPrint('🔍 Test 1: Service Initialization');
    DebugConfig.debugPrint('  - Service initialized: ${_dashService.isInitialized}');
    DebugConfig.debugPrint('  - Host URL: ${_dashService.hostUrl}');
    
    if (!_dashService.isInitialized) {
      DebugConfig.debugPrint('  ⚠️ Service not initialized, attempting to initialize...');
      _dashService.initialize(userId).then((_) {
        DebugConfig.debugPrint('  ✅ Service initialization completed');
      }).catchError((e) {
        DebugConfig.debugPrint('  ❌ Service initialization failed: $e');
      });
    } else {
      DebugConfig.debugPrint('  ✅ Service already initialized');
    }
  }
  
  void _testFirestoreConnection(String userId) {
    DebugConfig.debugPrint('🔍 Test 2: Firestore Connection');
    
    try {
      final chatRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(userId)
          .collection('chat')
          .limit(1);
      
      chatRef.get().then((snapshot) {
        DebugConfig.debugPrint('  ✅ Firestore connection successful');
        DebugConfig.debugPrint('  - Collection path: messages/$userId/chat');
        DebugConfig.debugPrint('  - Documents found: ${snapshot.docs.length}');
        
        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          DebugConfig.debugPrint('  - Sample document ID: ${doc.id}');
          DebugConfig.debugPrint('  - Sample document data keys: ${doc.data().keys.toList()}');
        }
      }).catchError((e) {
        DebugConfig.debugPrint('  ❌ Firestore connection failed: $e');
      });
    } catch (e) {
      DebugConfig.debugPrint('  ❌ Firestore test setup failed: $e');
    }
  }
  
  void _monitorMessageStream() {
    DebugConfig.debugPrint('🔍 Test 3: Message Stream Monitoring');
    
    try {
      _debugSubscription = _dashService.messageStream.listen(
        (message) {
          _messagesReceived++;
          DebugConfig.debugPrint('  📨 Message received (#$_messagesReceived):');
          DebugConfig.debugPrint('    - ID: ${message.id}');
          DebugConfig.debugPrint('    - Content: ${message.content.length > 50 ? message.content.substring(0, 50) + "..." : message.content}');
          DebugConfig.debugPrint('    - Is Me: ${message.isMe}');
          DebugConfig.debugPrint('    - Type: ${message.type}');
          DebugConfig.debugPrint('    - Timestamp: ${message.timestamp}');
          
          _messagesProcessed++;
        },
        onError: (error) {
          DebugConfig.debugPrint('  ❌ Message stream error: $error');
        },
        onDone: () {
          DebugConfig.debugPrint('  ⚠️ Message stream closed');
        },
      );
      
      DebugConfig.debugPrint('  ✅ Message stream listener attached');
    } catch (e) {
      DebugConfig.debugPrint('  ❌ Failed to attach message stream listener: $e');
    }
  }
  
  void _testStreamController() {
    DebugConfig.debugPrint('🔍 Test 4: Stream Controller Test');
    
    try {
      // Test if we can add a message to the stream
      final testMessage = ChatMessage(
        id: 'debug_test_${DateTime.now().millisecondsSinceEpoch}',
        content: 'Android Debug Test Message',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );
      
      // Use the service's test method
      _dashService.testStreamController();
      
      DebugConfig.debugPrint('  ✅ Stream controller test completed');
    } catch (e) {
      DebugConfig.debugPrint('  ❌ Stream controller test failed: $e');
    }
  }
  
  // Force a message sync to test if messages are in Firestore but not loading
  void forceMessageSync(String userId) {
    DebugConfig.debugPrint('🔍 Force Message Sync Test');
    
    try {
      FirebaseFirestore.instance
          .collection('messages')
          .doc(userId)
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get()
          .then((snapshot) {
        DebugConfig.debugPrint('  📊 Firestore Query Results:');
        DebugConfig.debugPrint('    - Total documents: ${snapshot.docs.length}');
        
        for (int i = 0; i < snapshot.docs.length; i++) {
          final doc = snapshot.docs[i];
          final data = doc.data();
          DebugConfig.debugPrint('    - Doc ${i + 1}:');
          DebugConfig.debugPrint('      ID: ${doc.id}');
          DebugConfig.debugPrint('      ServerMessageId: ${data['serverMessageId'] ?? 'N/A'}');
          DebugConfig.debugPrint('      MessageBody: ${(data['messageBody'] ?? '').toString().length > 30 ? (data['messageBody'] ?? '').toString().substring(0, 30) + "..." : data['messageBody'] ?? 'N/A'}');
          DebugConfig.debugPrint('      Source: ${data['source'] ?? 'N/A'}');
          DebugConfig.debugPrint('      CreatedAt: ${data['createdAt'] ?? 'N/A'}');
        }
        
        if (snapshot.docs.isEmpty) {
          DebugConfig.debugPrint('    ⚠️ No messages found in Firestore for user: $userId');
        }
      }).catchError((e) {
        DebugConfig.debugPrint('    ❌ Firestore query failed: $e');
      });
    } catch (e) {
      DebugConfig.debugPrint('  ❌ Force sync setup failed: $e');
    }
  }
  
  // Test if the issue is with the message processing logic
  void testMessageProcessing(String userId) {
    DebugConfig.debugPrint('🔍 Message Processing Test');
    
    // Create a mock Firestore document data
    final mockData = {
      'serverMessageId': 'debug_mock_${DateTime.now().millisecondsSinceEpoch}',
      'messageBody': 'Mock message for Android debug test',
      'source': 'server',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isPoll': false,
    };
    
    try {
      // Test message creation
      final message = ChatMessage(
        id: mockData['serverMessageId'] as String,
        content: mockData['messageBody'] as String,
        timestamp: DateTime.now(),
        isMe: mockData['source'] == 'client',
        type: MessageType.text,
      );
      
      DebugConfig.debugPrint('  ✅ Mock message created successfully:');
      DebugConfig.debugPrint('    - ID: ${message.id}');
      DebugConfig.debugPrint('    - Content: ${message.content}');
      DebugConfig.debugPrint('    - Is Me: ${message.isMe}');
      
      // Test adding to stream (this should trigger the message listener)
      DebugConfig.debugPrint('  🔄 Testing message addition to stream...');
      // Note: We can't directly access _safeAddToStream, but we can test the public interface
      
    } catch (e) {
      DebugConfig.debugPrint('  ❌ Message processing test failed: $e');
    }
  }
  
  // Get debug summary
  String getDebugSummary() {
    return '''
🔍 Android Messaging Debug Summary:
- Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}
- Service Initialized: ${_dashService.isInitialized}
- Messages Received: $_messagesReceived
- Messages Processed: $_messagesProcessed
- Debug Active: $_isDebugging
- Host URL: ${_dashService.hostUrl}
''';
  }
} 