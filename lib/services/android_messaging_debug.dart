import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import 'dash_messaging_service.dart';

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
      print('AndroidMessagingDebug: Not running on Android, skipping debug');
      return;
    }
    
    if (_isDebugging) {
      print('AndroidMessagingDebug: Already debugging, stopping previous session');
      stopDebugging();
    }
    
    _isDebugging = true;
    _messagesReceived = 0;
    _messagesProcessed = 0;
    
    print('🔍 AndroidMessagingDebug: Starting debug session for user: $userId');
    print('🔍 Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
    
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
    print('🔍 AndroidMessagingDebug: Stopping debug session');
    print('🔍 Final stats - Received: $_messagesReceived, Processed: $_messagesProcessed');
    
    _debugSubscription?.cancel();
    _debugSubscription = null;
    _isDebugging = false;
  }
  
  void _testServiceInitialization(String userId) {
    print('🔍 Test 1: Service Initialization');
    print('  - Service initialized: ${_dashService.isInitialized}');
    print('  - Host URL: ${_dashService.hostUrl}');
    
    if (!_dashService.isInitialized) {
      print('  ⚠️ Service not initialized, attempting to initialize...');
      _dashService.initialize(userId).then((_) {
        print('  ✅ Service initialization completed');
      }).catchError((e) {
        print('  ❌ Service initialization failed: $e');
      });
    } else {
      print('  ✅ Service already initialized');
    }
  }
  
  void _testFirestoreConnection(String userId) {
    print('🔍 Test 2: Firestore Connection');
    
    try {
      final chatRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(userId)
          .collection('chat')
          .limit(1);
      
      chatRef.get().then((snapshot) {
        print('  ✅ Firestore connection successful');
        print('  - Collection path: messages/$userId/chat');
        print('  - Documents found: ${snapshot.docs.length}');
        
        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          print('  - Sample document ID: ${doc.id}');
          print('  - Sample document data keys: ${doc.data().keys.toList()}');
        }
      }).catchError((e) {
        print('  ❌ Firestore connection failed: $e');
      });
    } catch (e) {
      print('  ❌ Firestore test setup failed: $e');
    }
  }
  
  void _monitorMessageStream() {
    print('🔍 Test 3: Message Stream Monitoring');
    
    try {
      _debugSubscription = _dashService.messageStream.listen(
        (message) {
          _messagesReceived++;
          print('  📨 Message received (#$_messagesReceived):');
          print('    - ID: ${message.id}');
          print('    - Content: ${message.content.length > 50 ? message.content.substring(0, 50) + "..." : message.content}');
          print('    - Is Me: ${message.isMe}');
          print('    - Type: ${message.type}');
          print('    - Timestamp: ${message.timestamp}');
          
          _messagesProcessed++;
        },
        onError: (error) {
          print('  ❌ Message stream error: $error');
        },
        onDone: () {
          print('  ⚠️ Message stream closed');
        },
      );
      
      print('  ✅ Message stream listener attached');
    } catch (e) {
      print('  ❌ Failed to attach message stream listener: $e');
    }
  }
  
  void _testStreamController() {
    print('🔍 Test 4: Stream Controller Test');
    
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
      
      print('  ✅ Stream controller test completed');
    } catch (e) {
      print('  ❌ Stream controller test failed: $e');
    }
  }
  
  // Force a message sync to test if messages are in Firestore but not loading
  void forceMessageSync(String userId) {
    print('🔍 Force Message Sync Test');
    
    try {
      FirebaseFirestore.instance
          .collection('messages')
          .doc(userId)
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get()
          .then((snapshot) {
        print('  📊 Firestore Query Results:');
        print('    - Total documents: ${snapshot.docs.length}');
        
        for (int i = 0; i < snapshot.docs.length; i++) {
          final doc = snapshot.docs[i];
          final data = doc.data();
          print('    - Doc ${i + 1}:');
          print('      ID: ${doc.id}');
          print('      ServerMessageId: ${data['serverMessageId'] ?? 'N/A'}');
          print('      MessageBody: ${(data['messageBody'] ?? '').toString().length > 30 ? (data['messageBody'] ?? '').toString().substring(0, 30) + "..." : data['messageBody'] ?? 'N/A'}');
          print('      Source: ${data['source'] ?? 'N/A'}');
          print('      CreatedAt: ${data['createdAt'] ?? 'N/A'}');
        }
        
        if (snapshot.docs.isEmpty) {
          print('    ⚠️ No messages found in Firestore for user: $userId');
        }
      }).catchError((e) {
        print('    ❌ Firestore query failed: $e');
      });
    } catch (e) {
      print('  ❌ Force sync setup failed: $e');
    }
  }
  
  // Test if the issue is with the message processing logic
  void testMessageProcessing(String userId) {
    print('🔍 Message Processing Test');
    
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
      
      print('  ✅ Mock message created successfully:');
      print('    - ID: ${message.id}');
      print('    - Content: ${message.content}');
      print('    - Is Me: ${message.isMe}');
      
      // Test adding to stream (this should trigger the message listener)
      print('  🔄 Testing message addition to stream...');
      // Note: We can't directly access _safeAddToStream, but we can test the public interface
      
    } catch (e) {
      print('  ❌ Message processing test failed: $e');
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