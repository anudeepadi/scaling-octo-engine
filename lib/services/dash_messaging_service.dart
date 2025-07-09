import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../utils/debug_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DashMessagingService {
  static final DashMessagingService _instance = DashMessagingService._internal();
  factory DashMessagingService() => _instance;
  DashMessagingService._internal() {
    // Enable Firestore offline persistence for better performance
    _enableFirestorePersistence();
  }
  
  // Enable Firestore offline persistence
  void _enableFirestorePersistence() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // INSTANT OPTIMIZATION: Configure Firestore for maximum performance
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        host: null, // Use default host for best performance
        sslEnabled: true,
      );
      
      // Enable network for real-time updates
      await firestore.enableNetwork();
      
      // Warm up the connection
      firestore.collection('messages').doc('_warmup').get().catchError((_) => null);
      
      DebugConfig.debugPrint('⚡ Firestore optimized for instant performance');
    } catch (e) {
      DebugConfig.debugPrint('Error enabling Firestore persistence: $e');
    }
  }

  // Server host URL - initialize with correct server URL from main.py
  String _hostUrl = "https://dashmessaging-com.ngrok.io/scheduler/mobile-app";
  String get hostUrl => _hostUrl;
  
  // User information
  String? _userId;
  String? _fcmToken;
  final _uuid = Uuid();
  
  // Stream controller for receiving messages
  StreamController<ChatMessage> _messageStreamController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;
  
  // Flag to track initialization state
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  // Add flag to track if stream is closed
  bool _isStreamClosed = false;
  
  // Track last response message to prevent duplicates
  DateTime? _lastResponseTime;
  String? _lastMessageText;

  // Track last Firestore message time
  int _lastFirestoreMessageTime = 0;
  int _lowestLoadedTimestamp = 0; // Track lowest timestamp for pagination

  // Add this field to manage the Firestore subscription
  StreamSubscription? _firestoreSubscription;

  // Add cache management
  final Map<String, ChatMessage> _messageCache = {};
  
  // Add performance monitoring
  final Stopwatch _performanceStopwatch = Stopwatch();
  
  // Debug flag for message alignment logging
  static const bool _debugMessageAlignment = true; // Set to false in production
  
  void _startPerformanceTimer(String operation) {
    _performanceStopwatch.reset();
    _performanceStopwatch.start();
    DebugConfig.performancePrint('Starting performance timer for: $operation');
  }
  
  void _stopPerformanceTimer(String operation) {
    _performanceStopwatch.stop();
    final elapsedMs = _performanceStopwatch.elapsedMilliseconds;
    DebugConfig.performancePrint('$operation completed in ${elapsedMs}ms');
  }
  
  void _addToCache(ChatMessage message) {
    _messageCache[message.id] = message;
  }
  
  // ignore: unused_element
  bool _isMessageCached(String messageId) {
    return _messageCache.containsKey(messageId);
  }
  
  void clearCache() {
    _messageCache.clear();
    DebugConfig.debugPrint('Message cache cleared');
  }

  // Initialize the service with user info
  Future<void> initialize(String userId) async {
    if (_isInitialized && _userId == userId) {
      DebugConfig.debugPrint('DashMessagingService already initialized for user: $userId');
      return;
    }
    
    DebugConfig.infoPrint('⚡ INSTANT initializing DashMessagingService for user: $userId');
    _userId = userId;
    
    // Clear cache when switching users
    if (_messageCache.isNotEmpty) {
      clearCache();
    }
    
    // Reinitialize stream controller if it's closed
    _reinitializeStreamController();
    
    // Stop any existing listeners
    stopRealtimeMessageListener();
    
    // Reset timestamp tracking
    DebugConfig.debugPrint('Reset timestamps during initialization');
    _lastFirestoreMessageTime = 0;
    _lowestLoadedTimestamp = 0;
    
    try {
      // INSTANT OPTIMIZATION: Start listener FIRST for immediate updates
      startRealtimeMessageListener();
      
      // Then load existing messages and FCM token in parallel
      final futures = <Future>[];
      
      futures.add(loadExistingMessages());
      futures.add(_loadFcmTokenInBackground());
      
      // Non-critical background tasks
      Future.delayed(Duration.zero, () => _testConnectionInBackground());
      
      // Wait only for critical tasks
      await Future.wait(futures);
      
      _isInitialized = true;
      DebugConfig.infoPrint('⚡ DashMessagingService initialized instantly');
    } catch (e) {
      DebugConfig.errorPrint('Error during initialization: $e');
      _isInitialized = false;
      rethrow;
    }
  }
  
  // Load FCM token in background without blocking initialization
  Future<void> _loadFcmTokenInBackground() async {
    try {
      _fcmToken = await _loadFcmToken().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          DebugConfig.debugPrint('FCM token loading timed out, using default');
          return "eLjQWERyTm2Kltsqxahvw6:APA91bFqgowOQxoeOpZuf9wMsUQczuxBBZZim_yo-r_j9H_SMKqU4HLuioUUgI028IRpUG5SObBY3Fp4HiJIkTNsLkrKPEgWEo2UWVvMa81mPIVdM0WEuV0";
        },
      );
      DebugConfig.debugPrint('FCM Token: $_fcmToken');
    } catch (e) {
      DebugConfig.debugPrint('Error loading FCM token in background: $e');
      // Use default token
      _fcmToken = "eLjQWERyTm2Kltsqxahvw6:APA91bFqgowOQxoeOpZuf9wMsUQczuxBBZZim_yo-r_j9H_SMKqU4HLuioUUgI028IRpUG5SObBY3Fp4HiJIkTNsLkrKPEgWEo2UWVvMa81mPIVdM0WEuV0";
    }
  }

  // Background connection test that doesn't block initialization
  Future<void> _testConnectionInBackground() async {
    try {
      final hostUrl = _hostUrl;
      DebugConfig.debugPrint('Using host URL: $hostUrl');
      DebugConfig.debugPrint('FCM Token: $_fcmToken');
      DebugConfig.debugPrint('Testing connection to server: $hostUrl');
      
      final response = await http.get(
        Uri.parse(hostUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      DebugConfig.debugPrint('Server connection test response: ${response.statusCode}');
      if (response.statusCode == 200) {
        DebugConfig.debugPrint('Successfully connected to server');
      } else {
        DebugConfig.debugPrint('Server responded with status: ${response.statusCode}');
        DebugConfig.debugPrint('Response body: ${response.body}');
      }
    } catch (e) {
      DebugConfig.debugPrint('Background server connection test failed: $e');
      // Check if it's a network connectivity issue
      if (e.toString().contains('Failed host lookup') || e.toString().contains('Network is unreachable')) {
        DebugConfig.debugPrint('❌ Network connectivity issue detected. Please check internet connection.');
      } else if (e.toString().contains('timeout')) {
        DebugConfig.debugPrint('❌ Server timeout - the server may be down or slow to respond.');
      } else {
        DebugConfig.debugPrint('❌ Unexpected connection error: $e');
      }
      // Don't throw - this is just a background test
    }
  }

  // Load host URL - use the exact server URL from main.py
  // ignore: unused_element
  Future<void> _loadHostUrl() async {
    try {
      // Always use the correct ngrok URL from main.py with full path
      _hostUrl = "https://dashmessaging-com.ngrok.io/scheduler/mobile-app";
      DebugConfig.debugPrint('Using server URL: $_hostUrl');
      
      // Store this URL in shared preferences for future use
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('hostUrl', _hostUrl);
      } catch (e) {
        DebugConfig.debugPrint('Error saving host URL to preferences: $e');
      }
      
      return;
    } catch (e) {
      DebugConfig.debugPrint('Error loading host URL: $e');
    }
  }
  
  // Load existing messages from Firestore
  Future<void> loadExistingMessages() async {
    _startPerformanceTimer('Initial message loading');
    
    if (_userId == null) {
      DebugConfig.debugPrint('Cannot load messages, user ID is null');
      return;
    }
    
    try {
      DebugConfig.debugPrint('⚡ INSTANT loading messages for user: $_userId');
      
      // CHRONOLOGICAL LOADING: Load messages in chronological order  
      final chatRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(_userId)
          .collection('chat')
          .orderBy('createdAt', descending: false)
          .limitToLast(30); // Load last 30 messages in chronological order
      
      // Try cache first for INSTANT display
      Future<QuerySnapshot>? cacheQuery;
      Future<QuerySnapshot>? serverQuery;
      
      // Start both queries in parallel
      cacheQuery = chatRef.get(const GetOptions(source: Source.cache));
      serverQuery = chatRef.get(const GetOptions(source: Source.server));
      
      // Process cache results INSTANTLY if available
      bool cacheProcessed = false;
      try {
        final cacheSnapshot = await cacheQuery.timeout(
          const Duration(milliseconds: 100), // Ultra-fast timeout
          onTimeout: () => throw TimeoutException('Cache timeout'),
        );
        
        if (cacheSnapshot.docs.isNotEmpty) {
          DebugConfig.debugPrint('⚡ INSTANT cache hit: ${cacheSnapshot.docs.length} messages');
          _processSnapshotInstant(cacheSnapshot);
          cacheProcessed = true;
        }
      } catch (e) {
        DebugConfig.debugPrint('Cache miss or timeout - loading from server');
      }
      
      // Always process server results for updates
      try {
        final serverSnapshot = await serverQuery;
        DebugConfig.debugPrint('Server loaded: ${serverSnapshot.docs.length} messages');
        
        // Only process if cache wasn't successful or if there are new messages
        if (!cacheProcessed || serverSnapshot.docs.length > _messageCache.length) {
          _processSnapshotInstant(serverSnapshot);
        }
      } catch (e) {
        DebugConfig.debugPrint('Server load error: $e');
        if (!cacheProcessed) {
          _stopPerformanceTimer('Initial message loading (error)');
          return;
        }
      }
      
      _stopPerformanceTimer('Initial message loading (instant)');
    } catch (e) {
      DebugConfig.debugPrint('Error loading existing messages: $e');
      _stopPerformanceTimer('Initial message loading (error)');
    }
  }
  
  // Process snapshot with proper chronological ordering
  void _processSnapshotInstant(QuerySnapshot snapshot) {
    if (snapshot.docs.isEmpty) return;
    
    final processedIds = <String>{};
    final messages = <ChatMessage>[];
    int lowestTimestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Process documents (already in chronological order due to limitToLast)
    for (var doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        final messageId = data['serverMessageId'] ?? doc.id;
        
        // Skip if already processed
        if (processedIds.contains(messageId) || _messageCache.containsKey(messageId)) {
          continue;
        }
        processedIds.add(messageId);
        
        // Extract content
        final content = data['messageBody']?.toString() ?? '';
        if (content.isEmpty) continue;
        
        // Fast timestamp extraction
        final timestamp = _extractTimestampFast(data);
        lowestTimestamp = timestamp.millisecondsSinceEpoch < lowestTimestamp 
            ? timestamp.millisecondsSinceEpoch 
            : lowestTimestamp;
        
        // Quick user check - prioritize source field for reliability
        final source = data['source']?.toString() ?? '';
        final senderId = data['senderId'] ?? data['userId'] ?? '';
        // FIXED: Prioritize source field since it's more reliable than senderId comparison
        final isMe = source == 'client' || (source.isEmpty && senderId == _userId);
        
        // DEBUG: Log message alignment for troubleshooting
        if (_debugMessageAlignment && content.isNotEmpty) {
          DebugConfig.debugPrint('📍 INITIAL Message alignment check: "${content.substring(0, content.length > 30 ? 30 : content.length)}..." -> isMe: $isMe (source: "$source", senderId: "$senderId", _userId: "$_userId")');
        }
        
        // Debug: Print full message data for messages that might have quick replies
        if (content.toLowerCase().contains('cigarette') || content.toLowerCase().contains('ready') || content.toLowerCase().contains('quiz')) {
          DebugConfig.debugPrint('🔍 POTENTIAL QUICK REPLY MESSAGE:');
          DebugConfig.debugPrint('🔍 Content: $content');
          DebugConfig.debugPrint('🔍 Full data keys: ${data.keys.toList()}');
          DebugConfig.debugPrint('🔍 Full data: $data');
        }

        // Enhanced poll detection - check ALL possible quick reply fields (same as unified logic)
        final isPoll = data['isPoll'];
        final questionsAnswers = data['questionsAnswers'] as Map<String, dynamic>?;
        final answers = data['answers'];
        final buttons = data['buttons'] as List<dynamic>?;
        final suggestedReplies = data['suggestedReplies'] as List<dynamic>?;
        
        // Comprehensive logging for debugging (same as unified logic)
        if (content.toLowerCase().contains('cigarette') || content.toLowerCase().contains('ready') || 
            content.toLowerCase().contains('quiz') || content.toLowerCase().contains('smoke')) {
          DebugConfig.debugPrint('🔍 INITIAL: Analyzing potential poll message:');
          DebugConfig.debugPrint('🔍 Content: $content');
          DebugConfig.debugPrint('🔍 isPoll: $isPoll');
          DebugConfig.debugPrint('🔍 questionsAnswers: $questionsAnswers');
          DebugConfig.debugPrint('🔍 answers: $answers');
          DebugConfig.debugPrint('🔍 buttons: $buttons');
          DebugConfig.debugPrint('🔍 suggestedReplies: $suggestedReplies');
          DebugConfig.debugPrint('🔍 All keys: ${data.keys.toList()}');
        }
        
        final hasQuickReplyData = isMessagePoll(isPoll) || 
                                 questionsAnswers != null || 
                                 answers != null || 
                                 buttons != null || 
                                 suggestedReplies != null;
        
        if (hasQuickReplyData) {
          // Create a single message with content AND quick replies
          List<QuickReply> quickReplies = [];
          
          // Process quick replies from ALL possible sources (same as unified logic)
          
          // 1. questionsAnswers (Map format)
          if (questionsAnswers != null && questionsAnswers.isNotEmpty) {
            for (final entry in questionsAnswers.entries) {
              quickReplies.add(QuickReply(text: entry.key, value: entry.value.toString()));
            }
            DebugConfig.debugPrint('🔧 INITIAL: Added ${questionsAnswers.length} quick replies from questionsAnswers');
          }
          
          // 2. answers (List or String format)
          else if (answers is List && answers.isNotEmpty) {
            for (var a in answers.take(4)) {
              quickReplies.add(QuickReply(text: a.toString(), value: a.toString()));
            }
            DebugConfig.debugPrint('🔧 INITIAL: Added ${answers.length} quick replies from answers (List)');
          } 
          else if (answers is String && answers != 'None' && answers.isNotEmpty) {
            final answerList = answers.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).take(4).toList();
            for (final a in answerList) {
              quickReplies.add(QuickReply(text: a, value: a));
            }
            DebugConfig.debugPrint('🔧 INITIAL: Added ${answerList.length} quick replies from answers (String)');
          }
          
          // 3. buttons (from push notifications)
          else if (buttons != null && buttons.isNotEmpty) {
            for (var button in buttons.take(4)) {
              final title = button['title']?.toString() ?? button.toString();
              if (title.isNotEmpty) {
                quickReplies.add(QuickReply(text: title, value: title));
              }
            }
            DebugConfig.debugPrint('🔧 INITIAL: Added ${buttons.length} quick replies from buttons');
          }
          
          // 4. suggestedReplies (already processed)
          else if (suggestedReplies != null && suggestedReplies.isNotEmpty) {
            for (var reply in suggestedReplies.take(4)) {
              final text = reply['text']?.toString() ?? reply.toString();
              final value = reply['value']?.toString() ?? text;
              if (text.isNotEmpty) {
                quickReplies.add(QuickReply(text: text, value: value));
              }
            }
            DebugConfig.debugPrint('🔧 INITIAL: Added ${suggestedReplies.length} quick replies from suggestedReplies');
          }
          
          // 5. Check for legacy field names that might exist
          final oldAnswers = data['options'] ?? data['choices'] ?? data['replies'];
          if (quickReplies.isEmpty && oldAnswers != null) {
            if (oldAnswers is List) {
                          for (var option in oldAnswers.take(4)) {
              quickReplies.add(QuickReply(text: option.toString(), value: option.toString()));
            }
            DebugConfig.debugPrint('🔧 INITIAL: Added ${oldAnswers.length} quick replies from legacy options/choices/replies');
            }
          }
          
          if (quickReplies.isNotEmpty) {
            // Create a single message with both content and quick replies
            final message = ChatMessage(
              id: messageId,
              content: content, // Include the poll question content
              timestamp: timestamp,
              isMe: isMe,
              type: MessageType.quickReply, // Mark as quick reply type
              suggestedReplies: quickReplies,
            );
            
            _messageCache[messageId] = message;
            messages.add(message);
            DebugConfig.debugPrint('🔧 ✅ INITIAL: Created single poll message with content and ${quickReplies.length} options: ${quickReplies.map((r) => r.text).join(", ")}');
          } else {
            DebugConfig.debugPrint('🔧 ⚠️ INITIAL: Poll detected but no valid quick replies created for: $content');
            // Fallback to regular text message if no quick replies could be created
            final message = ChatMessage(
              id: messageId,
              content: content,
              timestamp: timestamp,
              isMe: isMe,
              type: MessageType.text,
            );
            
            _messageCache[messageId] = message;
            messages.add(message);
          }
        } else {
          // Create regular text message
          final message = ChatMessage(
            id: messageId,
            content: content,
            timestamp: timestamp,
            isMe: isMe,
            type: MessageType.text,
          );
          
          _messageCache[messageId] = message;
          messages.add(message);
        }
        
      } catch (e) {
        DebugConfig.debugPrint('Error processing doc: $e');
      }
    }
    
    // Sort messages by timestamp to ensure perfect chronological order
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Add messages to stream in chronological order
    for (var message in messages) {
      _safeAddToStream(message);
    }
    
    _lowestLoadedTimestamp = lowestTimestamp;
    DebugConfig.debugPrint('⚡ Processed ${processedIds.length} messages in chronological order');
  }
  
  // Helper method to extract timestamp from Firestore data
  // ignore: unused_element
  DateTime _extractTimestamp(Map<String, dynamic> data) {
    try {
      final createdAt = data['createdAt'];
      if (createdAt is Timestamp) {
        return createdAt.toDate();
      } else if (createdAt is int) {
        return DateTime.fromMillisecondsSinceEpoch(createdAt);
      } else if (createdAt is String) {
        return DateTime.parse(createdAt);
      }
    } catch (e) {
      DebugConfig.debugPrint('Error parsing timestamp: $e');
    }
    return DateTime.now();
  }
  
  // Helper method to determine message type
  // ignore: unused_element
  MessageType _determineMessageType(Map<String, dynamic> data) {
    final isPoll = data['isPoll'] ?? false;
    final hasQuickReplies = data['questionsAnswers'] != null;
    
    if (isPoll || hasQuickReplies) {
      return MessageType.quickReply;
    }
    return MessageType.text;
  }
  
  // Helper method to extract quick replies from message data
  // ignore: unused_element
  List<QuickReply>? _extractQuickReplies(Map<String, dynamic> data) {
    try {
      final questionsAnswers = data['questionsAnswers'] as Map<String, dynamic>?;
      if (questionsAnswers != null && questionsAnswers.isNotEmpty) {
        return questionsAnswers.entries
            .map((entry) => QuickReply(
                  text: entry.key,
                  value: entry.value.toString(),
                ))
            .toList();
      }
    } catch (e) {
      DebugConfig.debugPrint('Error extracting quick replies: $e');
    }
    return null;
  }

  // Send a message to the server
  Future<bool> sendMessage(String text, {int eventTypeCode = 1}) async {
    if (text.trim().isEmpty) {
      DebugConfig.debugPrint('Cannot send empty message');
      return false;
    }
    
    // Prevent rapid duplicate messages (debouncing)
    final now = DateTime.now();
    if (_lastMessageText == text && _lastResponseTime != null) {
      final timeSinceLastSend = now.difference(_lastResponseTime!);
      if (timeSinceLastSend.inSeconds < 3) {
        DebugConfig.debugPrint('Preventing duplicate message within 3 seconds: $text');
        return false;
      }
    }
    
    // Generate unique message ID and track timing
    final messageId = _uuid.v4();
    final requestStartTime = now.millisecondsSinceEpoch ~/ 1000; // Convert to seconds for server
    
    // Update tracking variables
    _lastMessageText = text;
    _lastResponseTime = now;
    
    // REMOVED: Don't add user message to stream immediately to prevent timestamp conflicts
    // User messages will appear when they come back through Firebase real-time listener
    // with proper server timestamps ensuring correct chronological ordering
    
    // CONVERSATION HISTORY: Store user message in Firebase for complete conversation history
    await _storeUserMessageInFirebase(messageId, text, now, eventTypeCode);
    
    DebugConfig.debugPrint('🕐 User message stored in Firebase, will appear through real-time listener with correct server timestamp');
    
    DebugConfig.debugPrint('Sending message to server: {messageId: $messageId, userId: $_userId, messageText: $text, eventTypeCode: $eventTypeCode}');
    
    try {
      final requestBody = jsonEncode({
        'messageId': messageId,
        'userId': _userId,
        'messageText': text,
        'fcmToken': _fcmToken,
        'messageTime': requestStartTime,
        'eventTypeCode': eventTypeCode,
      });
      
      DebugConfig.debugPrint('Using endpoint: $_hostUrl');
      DebugConfig.debugPrint('Request body: $requestBody');
      
      // Send to server with optimized timeout
      final response = await http.post(
        Uri.parse(_hostUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'QuitTXT-Mobile/1.0',
        },
        body: requestBody,
      ).timeout(
        const Duration(seconds: 8), // Reduced from 10 to 8 seconds
        onTimeout: () {
          DebugConfig.debugPrint('⚠️ Server request timeout for message: $text');
          // Don't throw - let Firebase handle the response
          return http.Response('', 408); // Request timeout
        },
      );
      
      DebugConfig.debugPrint('Send message response status: ${response.statusCode}');
      DebugConfig.debugPrint('Send message response body: ${response.body}');
      
      if (response.statusCode == 200) {
        DebugConfig.debugPrint('Message sent successfully to server');
        // Server will send response via Firebase, no need to process here
        return true;
      } else if (response.statusCode == 408) {
        // Timeout - message might still be delivered via Firebase
        DebugConfig.debugPrint('Server timeout, but message may still be delivered');
        return true;
      } else {
        DebugConfig.debugPrint('Failed to send message. Status: ${response.statusCode}');
        DebugConfig.debugPrint('Response body: ${response.body}');
        // Remove the message from stream if server rejected it
        // Note: In a real app, you might want to show an error state instead
        return false;
      }
    } catch (e) {
      DebugConfig.debugPrint('Error sending message to server: $e');
      // Message already shown in UI, server might still process it
      return true; // Return true to avoid confusing the user
    }
  }
  
  // Start real-time message listener
  void startRealtimeMessageListener() {
    if (_userId == null) {
      DebugConfig.debugPrint('Cannot start realtime listener, user ID is null');
      return;
    }
    
    // Stop any existing listener
    stopRealtimeMessageListener();
    
    _startPerformanceTimer('Realtime listener setup');
    
    try {
      DebugConfig.debugPrint('Setting up INSTANT realtime listener for user: $_userId');
      
      // CHRONOLOGICAL ORDERING: Get messages in ascending order for proper chronological display
      final chatRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(_userId)
          .collection('chat')
          .orderBy('createdAt', descending: false)
          .limitToLast(100); // Get last 100 messages in chronological order
      
      // Enable network synchronization for instant updates
      FirebaseFirestore.instance.enableNetwork();
      
      _firestoreSubscription = chatRef.snapshots(
        includeMetadataChanges: true  // Include metadata for instant local writes
      ).listen(
        (snapshot) {
          // Process changes and ensure chronological ordering
          final docChanges = snapshot.docChanges;
          if (docChanges.isEmpty) return;
          
          DebugConfig.debugPrint('⚡ INSTANT update: ${docChanges.length} changes');
          
          // Collect new messages and sort them chronologically
          final newMessages = <ChatMessage>[];
          
          for (var change in docChanges) {
            // Process all change types for instant updates
            if (change.type == DocumentChangeType.added || 
                (change.type == DocumentChangeType.modified && !change.doc.metadata.hasPendingWrites)) {
              
              final doc = change.doc;
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) continue;
              
              final messageId = data['serverMessageId'] ?? doc.id;
              
              // Ultra-fast cache check
              if (_messageCache.containsKey(messageId)) continue;
              
              // Extract core data immediately
              final messageBody = data['messageBody']?.toString() ?? '';
              if (messageBody.isEmpty) continue;
              
              // Debug: Print full message data for messages that might have quick replies
              if (messageBody.toLowerCase().contains('cigarette') || messageBody.toLowerCase().contains('ready') || messageBody.toLowerCase().contains('quiz')) {
                DebugConfig.debugPrint('🔍 REALTIME POTENTIAL QUICK REPLY MESSAGE:');
                DebugConfig.debugPrint('🔍 Content: $messageBody');
                DebugConfig.debugPrint('🔍 Full data keys: ${data.keys.toList()}');
                DebugConfig.debugPrint('🔍 Full data: $data');
              }
              
              // Instant timestamp - use now if not available
              final messageTimestamp = _extractTimestampFast(data);
              
                      // Quick user check - prioritize source field for reliability
        final source = data['source']?.toString() ?? '';
        final senderId = data['senderId'] ?? data['userId'] ?? '';
        // FIXED: Prioritize source field since it's more reliable than senderId comparison
        final isMe = source == 'client' || (source.isEmpty && senderId == _userId);
        
        // DEBUG: Log message alignment for troubleshooting
        if (_debugMessageAlignment && messageBody.isNotEmpty) {
          DebugConfig.debugPrint('📍 REALTIME Message alignment check: "${messageBody.substring(0, messageBody.length > 30 ? 30 : messageBody.length)}..." -> isMe: $isMe (source: "$source", senderId: "$senderId", _userId: "$_userId")');
        }
              
              // Enhanced poll detection - check ALL possible quick reply fields (same as unified logic)
              final isPoll = data['isPoll'];
              final questionsAnswers = data['questionsAnswers'] as Map<String, dynamic>?;
              final answers = data['answers'];
              final buttons = data['buttons'] as List<dynamic>?;
              final suggestedReplies = data['suggestedReplies'] as List<dynamic>?;
              
              // Comprehensive logging for debugging (same as unified logic)
              if (messageBody.toLowerCase().contains('cigarette') || messageBody.toLowerCase().contains('ready') || 
                  messageBody.toLowerCase().contains('quiz') || messageBody.toLowerCase().contains('smoke')) {
                DebugConfig.debugPrint('🔍 REALTIME: Analyzing potential poll message:');
                DebugConfig.debugPrint('🔍 Content: $messageBody');
                DebugConfig.debugPrint('🔍 isPoll: $isPoll');
                DebugConfig.debugPrint('🔍 questionsAnswers: $questionsAnswers');
                DebugConfig.debugPrint('🔍 answers: $answers');
                DebugConfig.debugPrint('🔍 buttons: $buttons');
                DebugConfig.debugPrint('🔍 suggestedReplies: $suggestedReplies');
                DebugConfig.debugPrint('🔍 All keys: ${data.keys.toList()}');
              }
              
              final hasQuickReplyData = isMessagePoll(isPoll) || 
                                       questionsAnswers != null || 
                                       answers != null || 
                                       buttons != null || 
                                       suggestedReplies != null;
              
              if (hasQuickReplyData) {
                // Create a single message with content AND quick replies
                List<QuickReply> quickReplies = [];
                
                // Process quick replies from ALL possible sources (same as unified logic)
                
                // 1. questionsAnswers (Map format)
                if (questionsAnswers != null && questionsAnswers.isNotEmpty) {
                  for (final entry in questionsAnswers.entries) {
                    quickReplies.add(QuickReply(text: entry.key, value: entry.value.toString()));
                  }
                  DebugConfig.debugPrint('🔧 REALTIME: Added ${questionsAnswers.length} quick replies from questionsAnswers');
                }
                
                // 2. answers (List or String format)
                else if (answers is List && answers.isNotEmpty) {
                  for (var a in answers.take(4)) {
                    quickReplies.add(QuickReply(text: a.toString(), value: a.toString()));
                  }
                  DebugConfig.debugPrint('🔧 REALTIME: Added ${answers.length} quick replies from answers (List)');
                } 
                else if (answers is String && answers != 'None' && answers.isNotEmpty) {
                  final answerList = answers.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).take(4).toList();
                  for (final a in answerList) {
                    quickReplies.add(QuickReply(text: a, value: a));
                  }
                  DebugConfig.debugPrint('🔧 REALTIME: Added ${answerList.length} quick replies from answers (String)');
                }
                
                // 3. buttons (from push notifications)
                else if (buttons != null && buttons.isNotEmpty) {
                  for (var button in buttons.take(4)) {
                    final title = button['title']?.toString() ?? button.toString();
                    if (title.isNotEmpty) {
                      quickReplies.add(QuickReply(text: title, value: title));
                    }
                  }
                  DebugConfig.debugPrint('🔧 REALTIME: Added ${buttons.length} quick replies from buttons');
                }
                
                // 4. suggestedReplies (already processed)
                else if (suggestedReplies != null && suggestedReplies.isNotEmpty) {
                  for (var reply in suggestedReplies.take(4)) {
                    final text = reply['text']?.toString() ?? reply.toString();
                    final value = reply['value']?.toString() ?? text;
                    if (text.isNotEmpty) {
                      quickReplies.add(QuickReply(text: text, value: value));
                    }
                  }
                  DebugConfig.debugPrint('🔧 REALTIME: Added ${suggestedReplies.length} quick replies from suggestedReplies');
                }
                
                // 5. Check for legacy field names that might exist
                final oldAnswers = data['options'] ?? data['choices'] ?? data['replies'];
                if (quickReplies.isEmpty && oldAnswers != null) {
                  if (oldAnswers is List) {
                    for (var option in oldAnswers.take(4)) {
                      quickReplies.add(QuickReply(text: option.toString(), value: option.toString()));
                    }
                    DebugConfig.debugPrint('🔧 REALTIME: Added ${oldAnswers.length} quick replies from legacy options/choices/replies');
                  }
                }
                
                if (quickReplies.isNotEmpty) {
                  // Create a single message with both content and quick replies
                  final message = ChatMessage(
                    id: messageId,
                    content: messageBody, // Include the poll question content
                    timestamp: messageTimestamp,
                    isMe: isMe,
                    type: MessageType.quickReply, // Mark as quick reply type
                    suggestedReplies: quickReplies,
                  );
                  
                  _messageCache[messageId] = message;
                  newMessages.add(message);
                  DebugConfig.debugPrint('🔧 ✅ REALTIME: Created single poll message with content and ${quickReplies.length} options: ${quickReplies.map((r) => r.text).join(", ")}');
                } else {
                  DebugConfig.debugPrint('🔧 ⚠️ REALTIME: Poll detected but no valid quick replies created for: $messageBody');
                  // Fallback to regular text message if no quick replies could be created
                  final message = ChatMessage(
                    id: messageId,
                    content: messageBody,
                    timestamp: messageTimestamp,
                    isMe: isMe,
                    type: MessageType.text,
                  );
                  
                  _messageCache[messageId] = message;
                  newMessages.add(message);
                }
              } else {
                // Create regular text message
                final message = ChatMessage(
                  id: messageId,
                  content: messageBody,
                  timestamp: messageTimestamp,
                  isMe: isMe,
                  type: MessageType.text,
                );
                
                _messageCache[messageId] = message;
                newMessages.add(message);
              }
            }
          }
          
          // Sort messages by timestamp (chronological order)
          newMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          // Add messages to stream in chronological order
          for (var message in newMessages) {
            _safeAddToStream(message);
          }
        },
        onError: (error) {
          DebugConfig.debugPrint('Realtime listener error: $error');
          // Instant retry with exponential backoff
          Future.delayed(const Duration(seconds: 1), () {
            if (_userId != null) startRealtimeMessageListener();
          });
        },
      );
      
      _stopPerformanceTimer('Realtime listener setup');
      DebugConfig.debugPrint('⚡ INSTANT realtime listener active');
    } catch (e) {
      DebugConfig.debugPrint('Error setting up instant listener: $e');
      _stopPerformanceTimer('Realtime listener setup (error)');
    }
  }
  
  // Ultra-fast timestamp extraction
  // ignore: unused_element
  DateTime _extractTimestampFast(Map<String, dynamic> data) {
    try {
      // Try primary timestamp field (server timestamp)
      final createdAt = data['createdAt'];
      if (createdAt is Timestamp) {
        return createdAt.toDate();
      }
      
      // Try backup fields for older messages
      if (createdAt is int) {
        // Handle both seconds and milliseconds
        if (createdAt > 9999999999) {
          return DateTime.fromMillisecondsSinceEpoch(createdAt);
        } else {
          return DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
        }
      }
      
      // Try client timestamp as fallback
      final clientTimestamp = data['clientTimestamp'];
      if (clientTimestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(clientTimestamp);
      }
      
    } catch (_) {}
    return DateTime.now(); // Instant fallback
  }
  
  // Create quick reply message without directly adding to stream
  // ignore: unused_element
  ChatMessage? _createQuickReplyMessage(Map<String, dynamic> data, String messageId, DateTime messageTimestamp) {
    try {
      final isPoll = data['isPoll'];
      final questionsAnswers = data['questionsAnswers'] as Map<String, dynamic>?;
      final answers = data['answers'];
      
      DebugConfig.debugPrint('🔧 Creating quick reply for message $messageId: isPoll=$isPoll, questionsAnswers=$questionsAnswers, answers=$answers');
      DebugConfig.debugPrint('🔧 All fields in message data: ${data.keys.toList()}');
      
      // Check if this message has quick reply data
      final hasQuickReplyData = isMessagePoll(isPoll) || questionsAnswers != null || answers != null;
      if (!hasQuickReplyData) {
        DebugConfig.debugPrint('🔧 No quick reply data found for message $messageId');
        return null;
      }
      
      final quickReplyId = '${messageId}_qr';
      if (_messageCache.containsKey(quickReplyId)) return null;
      
      List<QuickReply> quickReplies = [];
      
      // Fast processing - handle both questionsAnswers and answers formats
      if (questionsAnswers != null && questionsAnswers.isNotEmpty) {
        for (final entry in questionsAnswers.entries) {
          quickReplies.add(QuickReply(text: entry.key, value: entry.value.toString()));
        }
        DebugConfig.debugPrint('🔧 Added ${questionsAnswers.length} quick replies from questionsAnswers');
      } else if (answers != null) {
        if (answers is List) {
          for (var a in answers.take(4)) {
            quickReplies.add(QuickReply(text: a.toString(), value: a.toString()));
          }
          DebugConfig.debugPrint('🔧 Added ${answers.length} quick replies from answers (List)');
        } else if (answers is String && answers != 'None' && answers.isNotEmpty) {
          final answerList = answers.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).take(4).toList();
          for (final a in answerList) {
            quickReplies.add(QuickReply(text: a, value: a));
          }
          DebugConfig.debugPrint('🔧 Added ${answerList.length} quick replies from answers (String)');
        }
      }
      
      if (quickReplies.isNotEmpty) {
        DebugConfig.debugPrint('🔧 ✅ Created quick reply message with ${quickReplies.length} options: ${quickReplies.map((r) => r.text).join(", ")}');
        return ChatMessage(
          id: quickReplyId,
          content: '',
          timestamp: messageTimestamp.add(const Duration(milliseconds: 1)),
          isMe: false,
          type: MessageType.quickReply,
          suggestedReplies: quickReplies,
        );
      }
      
      DebugConfig.debugPrint('🔧 ❌ No quick replies created for message $messageId');
      return null;
    } catch (e) {
      DebugConfig.debugPrint('Quick reply processing error: $e');
      return null;
    }
  }

  // Stop real-time listener
  void stopRealtimeMessageListener() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    DebugConfig.debugPrint('Stopped real-time Firestore listener');
  }

  // Load FCM token from Firebase Messaging
  Future<String?> _loadFcmToken() async {
    try {
      // Try to use the token from main.py if we can't get a real FCM token
      // This is a fallback for testing purposes
      String defaultToken = "eLjQWERyTm2Kltsqxahvw6:APA91bFqgowOQxoeOpZuf9wMsUQczuxBBZZim_yo-r_j9H_SMKqU4HLuioUUgI028IRpUG5SObBY3Fp4HiJIkTNsLkrKPEgWEo2UWVvMa81mPIVdM0WEuV0";
      
      // Try to get the FCM token from Firebase Messaging
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      
      if (token != null && token.isNotEmpty) {
        DebugConfig.debugPrint('Successfully retrieved FCM token from Firebase Messaging');
        return token;
      } else {
        DebugConfig.debugPrint('Failed to get FCM token from Firebase Messaging, using default token');
        return defaultToken;
      }
    } catch (e) {
      DebugConfig.debugPrint('Error loading FCM token: $e, using default token');
      // Return the default token from main.py
      return "eLjQWERyTm2Kltsqxahvw6:APA91bFqgowOQxoeOpZuf9wMsUQczuxBBZZim_yo-r_j9H_SMKqU4HLuioUUgI028IRpUG5SObBY3Fp4HiJIkTNsLkrKPEgWEo2UWVvMa81mPIVdM0WEuV0";
    }
  }

  // Update host URL and save to shared preferences
  Future<void> updateHostUrl(String newUrl) async {
    if (newUrl.isEmpty) return;
    
    try {
      // Check if the URL is valid
      final uri = Uri.parse(newUrl);
      if (!uri.isAbsolute) {
        throw Exception('URL must be absolute (start with http:// or https://)');
      }
      
      // Update the URL
      _hostUrl = newUrl;
      
      // Save to shared preferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hostUrl', newUrl);
      
      DebugConfig.debugPrint('Host URL updated to: $_hostUrl');
      
      // Test if the new URL is working
      if (_userId != null) {
        try {
          final testResponse = await http.get(
            Uri.parse('$_hostUrl/info'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 5));
          
          DebugConfig.debugPrint('Connection test response with new URL: ${testResponse.statusCode}');
        } catch (e) {
          DebugConfig.debugPrint('Error testing new URL: $e');
          // We don't throw here since the URL might be valid but endpoint not available
        }
      }
    } catch (e) {
      DebugConfig.debugPrint('Error updating host URL: $e');
      throw Exception('Failed to update host URL: $e');
    }
  }

  // Handle incoming push notifications
  void handlePushNotification(Map<String, dynamic> data) {
    try {
      DebugConfig.debugPrint('Received push notification: $data');
      
      // Parse data into QuitxtServerIncomingDto format
      final recipientId = data['recipientId'] as String?;
      final serverMessageId = data['serverMessageId'] as String?;
      final messageBody = data['messageBody'] as String?;
      final timestamp = data['timestamp'] as int?;
      final isPoll = data['isPoll'] as bool? ?? false;
      final buttons = data['buttons'] as List<dynamic>?;
      
      // Handle missing required fields
      if (recipientId == null || serverMessageId == null || messageBody == null) {
        DebugConfig.debugPrint('Missing required fields in push notification');
        return;
      }
      
      // Create message object
      final ChatMessage message = ChatMessage(
        id: serverMessageId,
        content: messageBody,
        timestamp: timestamp != null 
            ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000) 
            : DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );
      
      // Add the main message first
      _safeAddToStream(message);
      
      // Add buttons as quick replies if available
      if (isPoll && buttons != null && buttons.isNotEmpty) {
        final quickReplies = <QuickReply>[];
        for (final button in buttons) {
          final title = button['title'] as String?;
          if (title != null) {
            quickReplies.add(QuickReply(text: title, value: title));
          }
        }
        
        if (quickReplies.isNotEmpty) {
          // Add a separate message with quick replies
          final quickReplyMessage = ChatMessage(
            id: '${serverMessageId}_replies',
            content: '',
            timestamp: DateTime.now(),
            isMe: false,
            type: MessageType.quickReply,
            suggestedReplies: quickReplies,
          );
          _safeAddToStream(quickReplyMessage);
          return;
        }
      }
      
      // Fallback for older 'questionsAnswers' format
      else if (isPoll && data.containsKey('questionsAnswers')) {
        final questionsAnswers = data['questionsAnswers'] as Map<String, dynamic>?;
        if (questionsAnswers != null) {
          final quickReplies = <QuickReply>[];
          for (final entry in questionsAnswers.entries) {
            quickReplies.add(QuickReply(text: entry.value.toString(), value: entry.key));
          }
          
          if (quickReplies.isNotEmpty) {
            // Add a separate message with quick replies
            final quickReplyMessage = ChatMessage(
              id: '${serverMessageId}_replies',
              content: '',
              timestamp: DateTime.now(),
              isMe: false,
              type: MessageType.quickReply,
              suggestedReplies: quickReplies,
            );
            _safeAddToStream(quickReplyMessage);
          }
        }
      }
    } catch (e) {
      DebugConfig.debugPrint('Error handling push notification: $e');
    }
  }
  
  // Mock method to simulate server response (for testing without server)
  Future<void> simulateServerResponse(String userMessage) async {
    // Skip all mock responses to keep chat completely clean
    DebugConfig.debugPrint('Mock server responses disabled - no responses will be generated');
    DebugConfig.debugPrint('Message received but not processed: $userMessage');
    return;
  }
  
  // Send all test messages in sequence (useful for testing)
  Future<void> sendTestMessages() async {
    DebugConfig.debugPrint("Test messages disabled - no test messages will be sent");
    return;
  }
  
  // Process sample test data
  Future<void> processSampleTestData() async {
    DebugConfig.debugPrint("Sample test data processing disabled - no sample messages will be sent");
    return;
  }
  
  // Process server responses
  Future<void> processServerResponses() async {
    DebugConfig.debugPrint("Predefined server responses disabled - no predefined messages will be sent");
    return;
  }
  
  // Send a quick reply to the server
  Future<bool> sendQuickReply(String value, String text) async {
    DebugConfig.debugPrint('Sending quick reply: value="$value", text="$text"');
    return sendMessage(text, eventTypeCode: 2);
  }
  
  // Process predefined server responses from JSON input
  Future<void> processPredefinedResponses(Map<String, dynamic> jsonInput) async {
    try {
      final List<dynamic> serverResponses = jsonInput['serverResponses'];
      if (serverResponses.isEmpty) {
        DebugConfig.debugPrint('No server responses found in the input JSON');
        return;
      }

      // Add a small delay between messages for natural flow
      for (var i = 0; i < serverResponses.length; i++) {
        final response = serverResponses[i];
        await Future.delayed(Duration(milliseconds: 800));
        
        final messageId = response['serverMessageId'] ?? _uuid.v4();
        final messageBody = response['messageBody'] ?? '';
        final isPoll = response['isPoll'] ?? false;
        Map<String, dynamic>? questionsAnswers = response['questionsAnswers'];
        
        if (isPoll && questionsAnswers != null) {
          // Create quick replies for poll questions
          final List<QuickReply> quickReplies = [];
          for (final entry in questionsAnswers.entries) {
            quickReplies.add(QuickReply(text: entry.key, value: entry.value));
          }
          
          // Add poll message with quick replies
          final message = ChatMessage(
            id: messageId,
            content: messageBody,
            timestamp: DateTime.now(),
            isMe: false,
            type: MessageType.quickReply,
            suggestedReplies: quickReplies,
          );
          
          _safeAddToStream(message);
        } else {
          // Add regular text message
          final message = ChatMessage(
            id: messageId,
            content: messageBody,
            timestamp: DateTime.now(),
            isMe: false,
            type: MessageType.text,
          );
          
          _safeAddToStream(message);
        }
      }
    } catch (e) {
      DebugConfig.debugPrint('Error processing predefined responses: $e');
    }
  }
  
  // Process responses from custom JSON input
  Future<bool> processCustomJsonInput(String jsonInput) async {
    try {
      DebugConfig.debugPrint('Processing custom JSON input');
      final Map<String, dynamic> data = jsonDecode(jsonInput);
      await processPredefinedResponses(data);
      return true;
    } catch (e) {
      DebugConfig.debugPrint('Error processing custom JSON input: $e');
      return false;
    }
  }
  
  // Process interactive responses for specific user inputs
  Future<bool> processInteractiveResponses(String userInput) async {
    // Return false to bypass all prebuilt responses and always use the server
    DebugConfig.debugPrint('Bypassing prebuilt responses for: $userInput');
    return false;
  }
  
  // Dispose resources
  void dispose() {
    _isStreamClosed = true;
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    if (!_messageStreamController.isClosed) {
      _messageStreamController.close();
    }
    _isInitialized = false;
  }

  // Reinitialize stream controller if it's closed
  void _reinitializeStreamController() {
    if (_isStreamClosed || _messageStreamController.isClosed) {
      _messageStreamController = StreamController<ChatMessage>.broadcast();
      _isStreamClosed = false;
      DebugConfig.debugPrint('Stream controller reinitialized');
    }
  }

  // Reset the last message time to force a full refresh
  void resetLastMessageTime() {
    _lastFirestoreMessageTime = 0;
    DebugConfig.debugPrint('Reset _lastFirestoreMessageTime to 0');
  }

  /// Takes a raw JSON text message from the server and processes it into a ChatMessage.
  /// This handles processing of response messages received from the server.
  /// 
  /// [serverResponseJson] should be a JSON string containing the server response data.
  /// 
  /// Returns a ChatMessage object ready to be added to the chat stream.
  Future<ChatMessage> processServerResponseJson(String serverResponseJson) async {
    try {
      // Parse the JSON string
      final Map<String, dynamic> responseData = jsonDecode(serverResponseJson);
      
      // Extract required fields
      final String messageId = responseData['serverMessageId'] ?? _uuid.v4();
      final String messageBody = responseData['messageBody'] ?? '';
      final bool isPoll = responseData['isPoll'] ?? false;
      final timestamp = responseData['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch((responseData['timestamp'] as int) * 1000)
          : DateTime.now();
      
      // Create the main message
      ChatMessage message = ChatMessage(
        id: messageId,
        content: messageBody,
        timestamp: timestamp,
        isMe: false,
        type: MessageType.text,
      );
      
      // If it's a poll message, add quick replies
      if (isPoll && responseData.containsKey('questionsAnswers')) {
        final questionsAnswers = responseData['questionsAnswers'] as Map<String, dynamic>?;
        if (questionsAnswers != null && questionsAnswers.isNotEmpty) {
          final List<QuickReply> quickReplies = [];
          for (final entry in questionsAnswers.entries) {
            quickReplies.add(QuickReply(text: entry.key, value: entry.value.toString()));
          }
          
          // Create a new message with quick replies using copyWith
          message = message.copyWith(
            suggestedReplies: quickReplies
          );
        }
      }
      
      return message;
    } catch (e) {
      DebugConfig.debugPrint('Error processing server response JSON: $e');
      // In case of error, return a fallback message
      return ChatMessage(
        id: _uuid.v4(),
        content: 'Error processing server response: $e',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );
    }
  }

  // Test connection to the server using the exact URL
  Future<bool> testConnection() async {
    if (!_isInitialized) {
      DebugConfig.debugPrint('DashMessagingService not initialized, cannot test connection');
      return false;
    }
    
    // Double check that we're using the correct URL
    if (!_hostUrl.contains("/scheduler/mobile-app")) {
      DebugConfig.debugPrint('Correcting server URL to include path for connection test');
      _hostUrl = "https://dashmessaging-com.ngrok.io/scheduler/mobile-app";
    }
    
    try {
      DebugConfig.debugPrint('Testing connection to server: $_hostUrl');
      
      // Try to connect to the server
      final response = await http.get(
        Uri.parse(_hostUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      DebugConfig.debugPrint('Server connection test response: ${response.statusCode}');
      
      // Any response means we can reach the server
      return response.statusCode >= 200;
    } catch (e) {
      DebugConfig.debugPrint('Error testing connection to server: $e');
      return false;
    }
  }
  
  // Helper method to determine if a message is a poll/has quick replies
  bool isMessagePoll(dynamic isPollValue) {
    if (isPollValue == null) return false;
    
    // Convert various formats to a boolean
    if (isPollValue is bool) {
      return isPollValue;
    } else if (isPollValue is String) {
      return isPollValue.toLowerCase() == 'y' || 
             isPollValue.toLowerCase() == 'yes' || 
             isPollValue.toLowerCase() == 'true';
    } else if (isPollValue is int) {
      return isPollValue > 0;
    }
    
    return false;
  }

  // Load older messages for pagination
  Future<List<ChatMessage>> loadOlderMessages({int limit = 10}) async {
    _startPerformanceTimer('Loading older messages (pagination)');
    
    if (_userId == null) {
      DebugConfig.debugPrint('Cannot load older messages, user ID is null');
      _stopPerformanceTimer('Loading older messages (pagination - no user)');
      return [];
    }
    
    try {
      DebugConfig.debugPrint('Loading $limit older messages from Firestore for user: $_userId');
      
      // Get reference to the user's chat collection
      var query = FirebaseFirestore.instance
          .collection('messages')
          .doc(_userId)
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      // Add pagination using the lowest timestamp we've seen
      if (_lowestLoadedTimestamp > 0) {
        query = query.where('createdAt', isLessThan: _lowestLoadedTimestamp);
        DebugConfig.debugPrint('Loading messages older than timestamp: $_lowestLoadedTimestamp');
      }
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        DebugConfig.debugPrint('No older messages found');
        _stopPerformanceTimer('Loading older messages (pagination - no messages)');
        return [];
      }
      
      DebugConfig.debugPrint('Found ${snapshot.docs.length} older messages');
      
      final messages = <ChatMessage>[];
      final processedMessageIds = <String>{};
      
      for (var doc in snapshot.docs.reversed) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          final messageId = data['serverMessageId'] ?? doc.id;
          
          // Skip if already processed or cached
          if (processedMessageIds.contains(messageId) || _messageCache.containsKey(messageId)) {
            continue;
          }
          processedMessageIds.add(messageId);
          
          // Skip empty messages
          if ((data['messageBody'] ?? '').toString().isEmpty) {
            continue;
          }
          
          // Update lowest timestamp for next pagination
          try {
            var createdAt = data['createdAt'];
            if (createdAt != null) {
              int timeValue = 0;
              if (createdAt is String) {
                timeValue = int.tryParse(createdAt) ?? 0;
              } else if (createdAt is int) {
                timeValue = createdAt;
              }
              
              if (timeValue > 0 && (_lowestLoadedTimestamp == 0 || timeValue < _lowestLoadedTimestamp)) {
                _lowestLoadedTimestamp = timeValue;
              }
            }
          } catch (e) {
            DebugConfig.debugPrint('Error updating pagination timestamp: $e');
          }
          
          // Use unified processing logic for historical messages
          final timestamp = _extractTimestampFast(data);
          final isMe = (data['source']?.toString() ?? '') == 'client';
          
          final message = _processUnifiedMessage(data, messageId, timestamp, isMe);
          if (message != null) {
            _addToCache(message);
            messages.add(message);
          }
        } catch (e) {
          DebugConfig.debugPrint('Error processing older message: $e');
        }
      }
      
      DebugConfig.debugPrint('Processed ${messages.length} older messages');
      _stopPerformanceTimer('Loading older messages (pagination)');
      return messages;
    } catch (e) {
      DebugConfig.debugPrint('Error loading older messages: $e');
      _stopPerformanceTimer('Loading older messages (pagination - error)');
      return [];
    }
  }

  // Load more messages on demand (for pagination or when user scrolls up)
  Future<void> loadMoreMessages({int additionalCount = 10}) async {
    _startPerformanceTimer('Loading additional messages');
    
    if (_userId == null) {
      DebugConfig.debugPrint('Cannot load more messages, user ID is null');
      return;
    }
    
    try {
      DebugConfig.debugPrint('Loading $additionalCount additional messages from Firestore');
      
      // Query for older messages using pagination
      var query = FirebaseFirestore.instance
          .collection('messages')
          .doc(_userId)
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .limit(additionalCount);
      
      // Skip the messages we already have
      if (_lastFirestoreMessageTime > 0) {
        query = query.where('createdAt', isLessThan: _lastFirestoreMessageTime);
      }
      
      final snapshot = await query.get().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          DebugConfig.debugPrint('Additional messages query timeout');
          throw TimeoutException('Additional messages query timeout', const Duration(seconds: 3));
        },
      );
      
      if (snapshot.docs.isEmpty) {
        DebugConfig.debugPrint('No additional messages found');
        _stopPerformanceTimer('Loading additional messages (no messages)');
        return;
      }
      
      DebugConfig.debugPrint('Found ${snapshot.docs.length} additional messages');
      
      // Process additional messages efficiently
      final messages = <ChatMessage>[];
      int oldestTimestamp = _lastFirestoreMessageTime;
      
      for (var doc in snapshot.docs.reversed) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          final messageId = data['serverMessageId'] ?? doc.id;
          
          // Skip if already cached
          if (_messageCache.containsKey(messageId)) {
            continue;
          }
          
          final messageBody = (data['messageBody'] ?? '').toString();
          if (messageBody.isEmpty) {
            continue;
          }
          
          // Track oldest timestamp
          try {
            var createdAt = data['createdAt'];
            if (createdAt != null) {
              int timeValue = 0;
              if (createdAt is String) {
                timeValue = int.tryParse(createdAt) ?? 0;
              } else if (createdAt is int) {
                timeValue = createdAt;
              }
              
              if (timeValue > 0 && (oldestTimestamp == 0 || timeValue < oldestTimestamp)) {
                oldestTimestamp = timeValue;
              }
            }
          } catch (e) {
            // Continue silently
          }
          
          // Use unified processing logic for additional messages
          final timestamp = _extractTimestampFast(data);
          final isMe = (data['source']?.toString() ?? '') == 'client';
          
          final message = _processUnifiedMessage(data, messageId, timestamp, isMe);
          if (message != null) {
            _addToCache(message);
            messages.add(message);
          }
        } catch (e) {
          // Continue silently
        }
      }
      
      // Add messages to stream
      for (var message in messages) {
        _safeAddToStream(message);
      }
      
      DebugConfig.debugPrint('Added ${messages.length} additional messages to stream');
      _stopPerformanceTimer('Loading additional messages');
    } catch (e) {
      DebugConfig.debugPrint('Error loading additional messages: $e');
      _stopPerformanceTimer('Loading additional messages (error)');
    }
  }

  // Helper method to safely add messages to stream
  void _safeAddToStream(ChatMessage message) {
    if (!_isStreamClosed && !_messageStreamController.isClosed) {
      try {
        _messageStreamController.add(message);
      } catch (e) {
        DebugConfig.debugPrint('Error adding message to stream: $e');
      }
    } else {
      DebugConfig.debugPrint('Stream is closed, cannot add message: ${message.id}');
    }
  }

  // Test stream controller functionality
  void testStreamController() {
    DebugConfig.debugPrint('Testing stream controller...');
    DebugConfig.debugPrint('Stream controller closed: ${_messageStreamController.isClosed}');
    DebugConfig.debugPrint('Stream has listener: ${_messageStreamController.hasListener}');
    DebugConfig.debugPrint('Is stream closed flag: $_isStreamClosed');
    DebugConfig.debugPrint('Service initialized: $_isInitialized');
    DebugConfig.debugPrint('User ID: $_userId');
    
    // Test adding a message to the stream
    try {
      final testMessage = ChatMessage(
        id: 'test-${DateTime.now().millisecondsSinceEpoch}',
        content: 'Stream controller test message',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );
      _safeAddToStream(testMessage);
      DebugConfig.debugPrint('Successfully added test message to stream');
    } catch (e) {
      DebugConfig.debugPrint('Error testing stream controller: $e');
    }
  }

  // Helper method for ultra-fast message processing
  Future<ChatMessage?> _processMessageDocOptimized(QueryDocumentSnapshot doc, Set<String> processedMessageIds) async {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;
      
      final messageId = data['serverMessageId'] ?? doc.id;
      
      // Skip if already processed
      if (processedMessageIds.contains(messageId)) {
        return null;
      }
      processedMessageIds.add(messageId);
      
      final messageBody = (data['messageBody']?.toString() ?? '');
      // Skip empty messages
      if (messageBody.isEmpty) {
        return null;
      }
      
      // Create minimal ChatMessage for ultra-fast processing
      final messageTimestamp = _extractTimestampFast(data);
      return ChatMessage(
        id: messageId,
        content: messageBody,
        timestamp: messageTimestamp,
        isMe: (data['source']?.toString() ?? '') == 'client',
        type: MessageType.text,
      );
    } catch (e) {
      return null;
    }
  }

  // Background loading of additional messages for better UX
  // ignore: unused_element
  void _scheduleBackgroundMessageLoad() {
    if (_userId == null) return;
    
    // Schedule background loading after a short delay
    Timer(const Duration(milliseconds: 300), () {
      _loadAdditionalMessagesInBackground();
    });
  }

  // Load more messages in background without blocking UI
  Future<void> _loadAdditionalMessagesInBackground() async {
    if (_userId == null) return;
    
    try {
      DebugConfig.debugPrint('Loading additional messages in background...');
      
      // Load additional messages in chronological order
      final chatRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(_userId!)
          .collection('chat')
          .orderBy('createdAt', descending: false)
          .limit(18)  // Load 18 additional messages
          .startAfter([_lastFirestoreMessageTime]);
      
      QuerySnapshot<Map<String, dynamic>>? snapshot;
      try {
        snapshot = await chatRef.get().timeout(
          const Duration(seconds: 3),
        );
      } catch (e) {
        DebugConfig.debugPrint('Background loading timeout or error - continuing with current messages: $e');
        return;
      }
      
      if (snapshot.docs.isNotEmpty) {
        final additionalMessages = <ChatMessage>[];
        final processedIds = <String>{};
        
        // Process in chronological order (already sorted)
        for (var doc in snapshot.docs) {
          final message = await _processMessageDocOptimized(doc, processedIds);
          if (message != null && !_messageCache.containsKey(message.id)) {
            additionalMessages.add(message);
            _addToCache(message);
          }
        }
        
        // Sort by timestamp to ensure perfect chronological order
        additionalMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        // Add background messages in chronological order with subtle delays
        for (int i = 0; i < additionalMessages.length; i++) {
          await Future.delayed(const Duration(milliseconds: 50));
          _safeAddToStream(additionalMessages[i]);
        }
        
        DebugConfig.debugPrint('Background loaded ${additionalMessages.length} additional messages in chronological order');
      }
    } catch (e) {
      DebugConfig.debugPrint('Background message loading failed: $e');
    }
  }

  // Store user message in Firebase for conversation history
  Future<void> _storeUserMessageInFirebase(String messageId, String messageText, DateTime timestamp, int eventTypeCode) async {
    if (_userId == null) {
      DebugConfig.debugPrint('Cannot store user message: user ID is null');
      return;
    }

    try {
      // Get reference to user's chat collection
      final userMessagesRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(_userId!)
          .collection('chat');
      
      // Create user message document with same structure as server messages
      // Use server timestamp as the primary ordering field for consistency
      final userMessageData = {
        'messageBody': messageText,
        'source': 'client', // Indicates this is from the user
        'senderId': _userId,
        'serverMessageId': messageId,
        'createdAt': FieldValue.serverTimestamp(), // Use server timestamp for consistent ordering
        'clientTimestamp': timestamp.millisecondsSinceEpoch, // Keep client time for reference
        'isPoll': 'n',
        'eventTypeCode': eventTypeCode,
      };
      
      // Store the user message in Firebase
      await userMessagesRef.doc(messageId).set(userMessageData);
      
             DebugConfig.debugPrint('✓ User message stored in Firebase: $messageId');
     } catch (e) {
       DebugConfig.debugPrint('Error storing user message in Firebase: $e');
       // Don't throw the error - this shouldn't prevent sending the message
     }
   }

  // Get conversation history from Firebase (for debugging/verification)
  Future<List<Map<String, dynamic>>> getConversationHistory({int limit = 20}) async {
    if (_userId == null) {
      DebugConfig.debugPrint('Cannot get conversation history: user ID is null');
      return [];
    }

    try {
      final userMessagesRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(_userId!)
          .collection('chat')
          .orderBy('createdAt', descending: false)
          .limitToLast(limit);
      
      final snapshot = await userMessagesRef.get();
      
      final history = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) { // Already in chronological order
        final data = doc.data();
        
        // Extract timestamp properly using the same logic as the app
        final timestamp = _extractTimestampFast(data);
        final timeString = timestamp.toString();
        
        history.add({
          'id': data['serverMessageId'] ?? doc.id,
          'message': data['messageBody'] ?? '',
          'source': data['source'] ?? 'unknown',
          'timestamp': timeString,
          'isUserMessage': (data['source'] ?? '') == 'client',
        });
      }
      
             DebugConfig.debugPrint('📜 Conversation History ($_userId):');
      for (var i = 0; i < history.length; i++) {
        final msg = history[i];
        final prefix = msg['isUserMessage'] ? '👤 User:' : '🤖 Server:';
        DebugConfig.debugPrint('  ${i + 1}. $prefix ${msg['message']} [${msg['timestamp']}]');
      }
      
      return history;
    } catch (e) {
      DebugConfig.debugPrint('Error getting conversation history: $e');
      return [];
    }
  }

  // Verify message ordering and fix if needed
  Future<void> verifyMessageOrdering() async {
    if (_userId == null) {
      DebugConfig.debugPrint('Cannot verify message ordering: user ID is null');
      return;
    }

    try {
      DebugConfig.debugPrint('🔍 Verifying message ordering for user: $_userId');
      
      final userMessagesRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(_userId!)
          .collection('chat')
          .orderBy('createdAt', descending: false) // Get in chronological order
          .limit(20);
      
      final snapshot = await userMessagesRef.get();
      
      if (snapshot.docs.isEmpty) {
        DebugConfig.debugPrint('✅ No messages to verify ordering');
        return;
      }
      
      DebugConfig.debugPrint('📋 Message ordering verification (chronological):');
      DateTime? lastTimestamp;
      bool orderingIssues = false;
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        final timestamp = _extractTimestampFast(data);
        final source = data['source'] ?? 'unknown';
        final messageBody = data['messageBody'] ?? '';
        
        if (lastTimestamp != null && timestamp.isBefore(lastTimestamp)) {
          DebugConfig.debugPrint('⚠️  Ordering issue at message ${i + 1}');
          orderingIssues = true;
        }
        
        final timeStr = timestamp.toString().substring(11, 19); // HH:MM:SS
        final prefix = source == 'client' ? '👤' : '🤖';
        DebugConfig.debugPrint('  ${i + 1}. $prefix [$timeStr] ${messageBody.substring(0, messageBody.length > 30 ? 30 : messageBody.length)}${messageBody.length > 30 ? '...' : ''}');
        
        lastTimestamp = timestamp;
      }
      
      if (orderingIssues) {
        DebugConfig.debugPrint('⚠️  Ordering issues detected. Consider clearing and resyncing messages.');
      } else {
        DebugConfig.debugPrint('✅ Message ordering is correct');
      }
      
    } catch (e) {
      DebugConfig.debugPrint('Error verifying message ordering: $e');
    }
  }

  // Force reload all messages (clear cache and reload)
  Future<void> forceReloadMessages() async {
    DebugConfig.debugPrint('🔄 Force reloading all messages...');
    
    // Clear the cache to remove old format messages
    clearCache();
    
    // Reset timestamps
    _lastFirestoreMessageTime = 0;
    _lowestLoadedTimestamp = 0;
    
    // Stop existing listener
    stopRealtimeMessageListener();
    
    // Reload messages with new logic
    await loadExistingMessages();
    
    // Restart listener
    startRealtimeMessageListener();
    
    DebugConfig.debugPrint('🔄 ✅ Force reload completed');
  }

  // Debug method to test message alignment fix
  Future<void> debugMessageAlignment() async {
    if (_userId == null) {
      DebugConfig.debugPrint('❌ Cannot debug message alignment: user ID is null');
      return;
    }

    try {
      DebugConfig.debugPrint('🔍 DEBUG: Testing message alignment fix for user: $_userId');
      
      final userMessagesRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(_userId!)
          .collection('chat')
          .orderBy('createdAt', descending: false)
          .limit(10);
      
      final snapshot = await userMessagesRef.get();
      
      if (snapshot.docs.isEmpty) {
        DebugConfig.debugPrint('✅ No messages found to test alignment');
        return;
      }
      
      DebugConfig.debugPrint('📋 Message alignment test results:');
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        
        // Use the same logic as the fixed code
        final source = data['source']?.toString() ?? '';
        final senderId = data['senderId'] ?? data['userId'] ?? '';
        final isMe = source == 'client' || (source.isEmpty && senderId == _userId);
        final messageBody = data['messageBody'] ?? '';
        
        final alignmentStatus = isMe ? '👤 USER (RIGHT)' : '🤖 SERVER (LEFT)';
        final sourceInfo = source.isNotEmpty ? source : 'no source';
        
        DebugConfig.debugPrint('  ${i + 1}. $alignmentStatus - "$messageBody" (source: $sourceInfo)');
      }
      
      DebugConfig.debugPrint('✅ Message alignment test completed');
    } catch (e) {
      DebugConfig.debugPrint('❌ Error testing message alignment: $e');
    }
  }

  // Helper method to process any message with unified logic
  ChatMessage? _processUnifiedMessage(Map<String, dynamic> data, String messageId, DateTime timestamp, bool isMe) {
    final content = data['messageBody']?.toString() ?? '';
    if (content.isEmpty) return null;
    
    // Enhanced poll detection - check ALL possible quick reply fields
    final isPoll = data['isPoll'];
    final questionsAnswers = data['questionsAnswers'] as Map<String, dynamic>?;
    final answers = data['answers'];
    final buttons = data['buttons'] as List<dynamic>?;
    final suggestedReplies = data['suggestedReplies'] as List<dynamic>?;
    
    // Comprehensive logging for debugging
    if (content.toLowerCase().contains('cigarette') || content.toLowerCase().contains('ready') || 
        content.toLowerCase().contains('quiz') || content.toLowerCase().contains('smoke')) {
      DebugConfig.debugPrint('🔍 UNIFIED: Analyzing potential poll message:');
      DebugConfig.debugPrint('🔍 Content: $content');
      DebugConfig.debugPrint('🔍 isPoll: $isPoll');
      DebugConfig.debugPrint('🔍 questionsAnswers: $questionsAnswers');
      DebugConfig.debugPrint('🔍 answers: $answers');
      DebugConfig.debugPrint('🔍 buttons: $buttons');
      DebugConfig.debugPrint('🔍 suggestedReplies: $suggestedReplies');
      DebugConfig.debugPrint('🔍 All keys: ${data.keys.toList()}');
    }
    
    // Enhanced quick reply detection - check ALL possible sources
    final hasQuickReplyData = isMessagePoll(isPoll) || 
                             questionsAnswers != null || 
                             answers != null || 
                             buttons != null || 
                             suggestedReplies != null;
    
    if (hasQuickReplyData) {
      List<QuickReply> quickReplies = [];
      
      // Process quick replies from ALL possible sources
      
      // 1. questionsAnswers (Map format)
      if (questionsAnswers != null && questionsAnswers.isNotEmpty) {
        for (final entry in questionsAnswers.entries) {
          quickReplies.add(QuickReply(text: entry.key, value: entry.value.toString()));
        }
        DebugConfig.debugPrint('🔧 UNIFIED: Added ${questionsAnswers.length} quick replies from questionsAnswers');
      }
      
      // 2. answers (List or String format)
      else if (answers is List && answers.isNotEmpty) {
        for (var a in answers.take(4)) {
          quickReplies.add(QuickReply(text: a.toString(), value: a.toString()));
        }
        DebugConfig.debugPrint('🔧 UNIFIED: Added ${answers.length} quick replies from answers (List)');
      } 
      else if (answers is String && answers != 'None' && answers.isNotEmpty) {
        final answerList = answers.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).take(4).toList();
        for (final a in answerList) {
          quickReplies.add(QuickReply(text: a, value: a));
        }
        DebugConfig.debugPrint('🔧 UNIFIED: Added ${answerList.length} quick replies from answers (String)');
      }
      
      // 3. buttons (from push notifications)
      else if (buttons != null && buttons.isNotEmpty) {
        for (var button in buttons.take(4)) {
          final title = button['title']?.toString() ?? button.toString();
          if (title.isNotEmpty) {
            quickReplies.add(QuickReply(text: title, value: title));
          }
        }
        DebugConfig.debugPrint('🔧 UNIFIED: Added ${buttons.length} quick replies from buttons');
      }
      
      // 4. suggestedReplies (already processed)
      else if (suggestedReplies != null && suggestedReplies.isNotEmpty) {
        for (var reply in suggestedReplies.take(4)) {
          final text = reply['text']?.toString() ?? reply.toString();
          final value = reply['value']?.toString() ?? text;
          if (text.isNotEmpty) {
            quickReplies.add(QuickReply(text: text, value: value));
          }
        }
        DebugConfig.debugPrint('🔧 UNIFIED: Added ${suggestedReplies.length} quick replies from suggestedReplies');
      }
      
      // 5. Check for legacy field names that might exist
      final oldAnswers = data['options'] ?? data['choices'] ?? data['replies'];
      if (quickReplies.isEmpty && oldAnswers != null) {
        if (oldAnswers is List) {
          for (var option in oldAnswers.take(4)) {
            quickReplies.add(QuickReply(text: option.toString(), value: option.toString()));
          }
          DebugConfig.debugPrint('🔧 UNIFIED: Added ${oldAnswers.length} quick replies from legacy options/choices/replies');
        }
      }
      
      if (quickReplies.isNotEmpty) {
        DebugConfig.debugPrint('🔧 ✅ UNIFIED: Created single poll message with content and ${quickReplies.length} options: ${quickReplies.map((r) => r.text).join(", ")}');
        return ChatMessage(
          id: messageId,
          content: content, // Include the poll question content
          timestamp: timestamp,
          isMe: isMe,
          type: MessageType.quickReply, // Mark as quick reply type
          suggestedReplies: quickReplies,
        );
      } else {
        DebugConfig.debugPrint('🔧 ⚠️ UNIFIED: Poll detected but no valid quick replies created for: $content');
      }
    }
    
    // Create regular text message
    return ChatMessage(
      id: messageId,
      content: content,
      timestamp: timestamp,
      isMe: isMe,
      type: MessageType.text,
    );
      }


}