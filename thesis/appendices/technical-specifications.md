# Appendix E: Technical Specifications and Implementation Details

## E.1 System Architecture Specifications

### E.1.1 Technology Stack Components

**Frontend Framework**
- Framework: Flutter 3.19.0
- Programming Language: Dart 3.3.0
- Minimum SDK: Flutter 3.0.0
- Target Platforms: iOS 12.0+, Android API 21+

**Backend Services**
- Primary Backend: Google Firebase
- Authentication: Firebase Authentication v4.15.0
- Database: Cloud Firestore v4.13.0
- Messaging: Firebase Cloud Messaging v14.7.0
- Analytics: Firebase Analytics v10.7.0
- Storage: Firebase Storage v11.5.0

**State Management**
- Pattern: Provider Pattern
- Library: provider v6.1.1
- Architecture: MVVM (Model-View-ViewModel)

**Development Dependencies**
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0
  firebase_messaging: ^14.7.0
  firebase_analytics: ^10.7.0
  firebase_storage: ^11.5.0
  provider: ^6.1.1
  google_sign_in: ^6.1.5
  http: ^1.1.0
  shared_preferences: ^2.2.2
  flutter_local_notifications: ^16.1.0
  image_picker: ^1.0.4
  file_picker: ^6.1.1
  cached_network_image: ^3.3.0
  video_player: ^2.8.1
  flutter_linkify: ^6.0.0
  intl: ^0.19.0
  flutter_localizations:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.7
  flutter_launcher_icons: ^0.13.1
```

### E.1.2 Firebase Configuration

**Project Configuration**
- Project ID: quitxt-mobile-app
- Region: us-central1
- Firestore Mode: Native
- Authentication Providers: Google, Email/Password
- Storage Bucket: quitxt-mobile-app.appspot.com

**Security Rules - Firestore**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User profiles can only be read/written by the authenticated user
    match /userProfiles/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Chat messages require authenticated user
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
    
    // Channels require authenticated user and proper membership
    match /channels/{channelId} {
      allow read: if request.auth != null && 
        request.auth.uid in resource.data.members;
      allow write: if request.auth != null && 
        request.auth.uid in resource.data.members;
    }
  }
}
```

**Security Rules - Storage**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /user-media/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
    
    match /shared-media/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.token.email_verified == true;
    }
  }
}
```

## E.2 Data Models and Schema Definitions

### E.2.1 Core Data Models

**User Profile Model**
```dart
class UserProfile {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final Map<String, dynamic> preferences;
  final List<String> channels;
  final bool isOnline;
  final String? fcmToken;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    required this.lastActiveAt,
    required this.preferences,
    required this.channels,
    required this.isOnline,
    this.fcmToken,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      displayName: map['displayName'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastActiveAt: DateTime.fromMillisecondsSinceEpoch(map['lastActiveAt']),
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      channels: List<String>.from(map['channels'] ?? []),
      isOnline: map['isOnline'] ?? false,
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastActiveAt': lastActiveAt.millisecondsSinceEpoch,
      'preferences': preferences,
      'channels': channels,
      'isOnline': isOnline,
      'fcmToken': fcmToken,
    };
  }
}
```

**Chat Message Model**
```dart
class ChatMessage {
  final String id;
  final String senderId;
  final String? senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final String? channelId;
  final Map<String, dynamic>? metadata;
  final List<String>? attachments;
  final String? replyToMessageId;
  final MessageStatus status;

  ChatMessage({
    required this.id,
    required this.senderId,
    this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    this.channelId,
    this.metadata,
    this.attachments,
    this.replyToMessageId,
    required this.status,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      senderId: map['senderId'],
      senderName: map['senderName'],
      content: map['content'],
      type: MessageType.values[map['type']],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      channelId: map['channelId'],
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata']) 
          : null,
      attachments: map['attachments'] != null 
          ? List<String>.from(map['attachments']) 
          : null,
      replyToMessageId: map['replyToMessageId'],
      status: MessageStatus.values[map['status']],
    );
  }
}

enum MessageType { text, image, video, audio, file, system }
enum MessageStatus { sending, sent, delivered, read, failed }
```

### E.2.2 Database Schema

**Firestore Collections Structure**
```
quitxt-mobile-app (project)
├── userProfiles/
│   └── {userId}/
│       ├── id: string
│       ├── displayName: string
│       ├── email: string
│       ├── photoUrl: string?
│       ├── createdAt: timestamp
│       ├── lastActiveAt: timestamp
│       ├── preferences: map
│       ├── channels: array<string>
│       ├── isOnline: boolean
│       └── fcmToken: string?
├── messages/
│   └── {messageId}/
│       ├── id: string
│       ├── senderId: string
│       ├── senderName: string?
│       ├── content: string
│       ├── type: number
│       ├── timestamp: timestamp
│       ├── channelId: string?
│       ├── metadata: map?
│       ├── attachments: array<string>?
│       ├── replyToMessageId: string?
│       └── status: number
├── channels/
│   └── {channelId}/
│       ├── id: string
│       ├── name: string
│       ├── description: string?
│       ├── members: array<string>
│       ├── createdAt: timestamp
│       ├── lastMessageAt: timestamp?
│       ├── isPrivate: boolean
│       └── metadata: map?
└── analytics/
    └── {eventId}/
        ├── userId: string
        ├── eventType: string
        ├── timestamp: timestamp
        ├── sessionId: string
        └── properties: map
```

## E.3 API Specifications

### E.3.1 Authentication API

**Google Sign-In Flow**
```dart
class AuthService {
  static const List<String> scopes = [
    'email',
    'profile',
  ];

  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        scopes: scopes,
      ).signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled by user');
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException._fromFirebaseAuthException(e);
    }
  }
}
```

**Authentication State Management**
```dart
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAuthenticated => _currentUser != null;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      _errorMessage = null;
      notifyListeners();
    });
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
    } catch (e) {
      _errorMessage = 'Failed to sign out: $e';
      notifyListeners();
    }
  }
}
```

### E.3.2 Messaging API

**Message Service Interface**
```dart
abstract class MessagingService {
  bool get isInitialized;
  Stream<ChatMessage> get messageStream;
  
  Future<void> initialize(String userId, String? fcmToken);
  Future<String> sendMessage(String content, {
    MessageType type = MessageType.text,
    String? channelId,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
    String? replyToMessageId,
  });
  Future<void> markMessageAsRead(String messageId);
  Future<List<ChatMessage>> getMessageHistory({
    String? channelId,
    int limit = 50,
    DateTime? before,
  });
}
```

**Firebase Messaging Implementation**
```dart
class FirebaseMessagingServiceImpl implements MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<ChatMessage> _messageController = 
      StreamController<ChatMessage>.broadcast();
  
  bool _isInitialized = false;
  String? _userId;
  StreamSubscription<QuerySnapshot>? _messageSubscription;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Stream<ChatMessage> get messageStream => _messageController.stream;

  @override
  Future<void> initialize(String userId, String? fcmToken) async {
    _userId = userId;
    
    // Update FCM token
    if (fcmToken != null) {
      await _firestore
          .collection('userProfiles')
          .doc(userId)
          .update({'fcmToken': fcmToken});
    }

    // Listen for new messages
    _messageSubscription = _firestore
        .collection('messages')
        .where('recipients', arrayContains: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final message = ChatMessage.fromMap(change.doc.data()!);
          _messageController.add(message);
        }
      }
    });

    _isInitialized = true;
  }

  @override
  Future<String> sendMessage(String content, {
    MessageType type = MessageType.text,
    String? channelId,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
    String? replyToMessageId,
  }) async {
    if (!_isInitialized || _userId == null) {
      throw Exception('Service not initialized');
    }

    final messageId = _firestore.collection('messages').doc().id;
    final message = ChatMessage(
      id: messageId,
      senderId: _userId!,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      channelId: channelId,
      metadata: metadata,
      attachments: attachments,
      replyToMessageId: replyToMessageId,
      status: MessageStatus.sending,
    );

    await _firestore
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());

    return messageId;
  }
}
```

## E.4 Security Implementation Details

### E.4.1 Encryption Specifications

**Data Encryption at Rest**
- Firestore: AES-256 encryption (Google Cloud default)
- Local Storage: Platform-specific secure storage
  - iOS: Keychain Services with kSecAttrAccessibleWhenUnlockedThisDeviceOnly
  - Android: EncryptedSharedPreferences with AES-256-GCM

**Data Encryption in Transit**
- TLS 1.3 for all network communications
- Certificate pinning for Firebase endpoints
- HTTP Strict Transport Security (HSTS) enabled

**Implementation Example**
```dart
class SecureStorageService {
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptionCipher: EncryptionCipher.aes_gcm_256,
    keyCipher: KeyCipher.rsa_oaep_sha256,
    storageCipher: StorageCipher.aes_gcm,
    enableKeyGeneration: true,
  );

  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
    synchronizable: false,
    requiresAuthentication: true,
  );

  static final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  static Future<void> storeSecureData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> getSecureData(String key) async {
    return await _storage.read(key: key);
  }
}
```

### E.4.2 Access Control Implementation

**Role-Based Access Control**
```dart
enum UserRole { patient, provider, admin, system }

class AccessControlService {
  static bool canReadMessage(User user, ChatMessage message) {
    return message.senderId == user.uid ||
           message.recipients?.contains(user.uid) == true ||
           _hasAdminRole(user);
  }

  static bool canSendMessage(User user, String? channelId) {
    if (channelId == null) return true; // Direct messages allowed
    
    return _isChannelMember(user.uid, channelId) ||
           _hasProviderRole(user);
  }

  static bool _hasAdminRole(User user) {
    return user.customClaims?['role'] == UserRole.admin.toString();
  }

  static bool _hasProviderRole(User user) {
    final role = user.customClaims?['role'];
    return role == UserRole.provider.toString() ||
           role == UserRole.admin.toString();
  }
}
```

### E.4.3 Audit Logging Implementation

**Audit Event Schema**
```dart
class AuditEvent {
  final String id;
  final String userId;
  final String eventType;
  final DateTime timestamp;
  final String? resourceId;
  final Map<String, dynamic> details;
  final String ipAddress;
  final String userAgent;

  AuditEvent({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.timestamp,
    this.resourceId,
    required this.details,
    required this.ipAddress,
    required this.userAgent,
  });
}
```

**Audit Service Implementation**
```dart
class AuditService {
  static const List<String> auditedEvents = [
    'user_login',
    'user_logout',
    'message_sent',
    'message_read',
    'profile_updated',
    'data_exported',
    'password_changed',
  ];

  static Future<void> logEvent(String eventType, {
    String? resourceId,
    Map<String, dynamic>? details,
  }) async {
    if (!auditedEvents.contains(eventType)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final event = AuditEvent(
      id: FirebaseFirestore.instance.collection('audit').doc().id,
      userId: user.uid,
      eventType: eventType,
      timestamp: DateTime.now(),
      resourceId: resourceId,
      details: details ?? {},
      ipAddress: await _getClientIP(),
      userAgent: await _getUserAgent(),
    );

    await FirebaseFirestore.instance
        .collection('audit')
        .doc(event.id)
        .set(event.toMap());
  }
}
```

## E.5 Performance Monitoring and Analytics

### E.5.1 Performance Metrics Collection

**Client-Side Performance Monitoring**
```dart
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  
  static void startOperation(String operationName) {
    _startTimes[operationName] = DateTime.now();
  }
  
  static void endOperation(String operationName) {
    final startTime = _startTimes[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _logPerformanceMetric(operationName, duration);
      _startTimes.remove(operationName);
    }
  }
  
  static void _logPerformanceMetric(String operation, Duration duration) {
    FirebaseAnalytics.instance.logEvent(
      name: 'performance_metric',
      parameters: {
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}
```

### E.5.2 Custom Analytics Events

**Healthcare-Specific Analytics**
```dart
class HealthAnalytics {
  static Future<void> logMessageSent({
    required MessageType messageType,
    String? channelId,
    bool hasAttachments = false,
  }) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'health_message_sent',
      parameters: {
        'message_type': messageType.toString(),
        'channel_id': channelId ?? 'direct',
        'has_attachments': hasAttachments,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> logUserEngagement({
    required Duration sessionDuration,
    required int messagesRead,
    required int messagesReplied,
  }) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'health_engagement',
      parameters: {
        'session_duration_seconds': sessionDuration.inSeconds,
        'messages_read': messagesRead,
        'messages_replied': messagesReplied,
        'engagement_ratio': messagesReplied / messagesRead,
      },
    );
  }
}
```

## E.6 Testing Specifications

### E.6.1 Unit Test Framework

**Authentication Provider Tests**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  group('AuthProvider', () {
    late AuthProvider authProvider;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      authProvider = AuthProvider(auth: mockFirebaseAuth);
    });

    test('should update authentication state when user signs in', () async {
      // Arrange
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockFirebaseAuth.signInWithCredential(any))
          .thenAnswer((_) async => MockUserCredential(mockUser));

      // Act
      await authProvider.signInWithGoogle();

      // Assert
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.currentUser?.uid, 'test-user-id');
    });

    test('should handle authentication errors gracefully', () async {
      // Arrange
      when(mockFirebaseAuth.signInWithCredential(any))
          .thenThrow(FirebaseAuthException(code: 'user-disabled'));

      // Act & Assert
      expect(
        () => authProvider.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
```

### E.6.2 Integration Test Configuration

**End-to-End Test Setup**
```dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quitxt_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('QuitTxt Integration Tests', () {
    testWidgets('complete user journey: login, send message, logout', 
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Login flow
      await tester.tap(find.byKey(Key('google_sign_in_button')));
      await tester.pumpAndSettle();

      // Verify home screen appears
      expect(find.byKey(Key('home_screen')), findsOneWidget);

      // Send a message
      await tester.enterText(
        find.byKey(Key('message_input')), 
        'Test message'
      );
      await tester.tap(find.byKey(Key('send_button')));
      await tester.pumpAndSettle();

      // Verify message appears
      expect(find.text('Test message'), findsOneWidget);

      // Logout
      await tester.tap(find.byKey(Key('profile_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('logout_button')));
      await tester.pumpAndSettle();

      // Verify return to login screen
      expect(find.byKey(Key('login_screen')), findsOneWidget);
    });
  });
}
```

## E.7 Deployment Configuration

### E.7.1 iOS Deployment

**Info.plist Configuration**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>QuitTxt</string>
    <key>CFBundleIdentifier</key>
    <string>com.quitxt.app</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    
    <!-- Camera permissions for media messaging -->
    <key>NSCameraUsageDescription</key>
    <string>QuitTxt needs camera access to share photos in your health conversations.</string>
    
    <!-- Photo library permissions -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>QuitTxt needs photo library access to share images in your health conversations.</string>
    
    <!-- Microphone permissions for audio messages -->
    <key>NSMicrophoneUsageDescription</key>
    <string>QuitTxt needs microphone access to record audio messages for your health support.</string>
    
    <!-- Background processing for notifications -->
    <key>UIBackgroundModes</key>
    <array>
        <string>background-processing</string>
        <string>remote-notification</string>
    </array>
    
    <!-- App Transport Security -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>firebaseapp.com</key>
            <dict>
                <key>NSIncludesSubdomains</key>
                <true/>
                <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
                <false/>
                <key>NSTemporaryExceptionMinimumTLSVersion</key>
                <string>TLSv1.2</string>
            </dict>
        </dict>
    </dict>
</dict>
</plist>
```

### E.7.2 Android Deployment

**AndroidManifest.xml Configuration**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.quitxt.app">

    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

    <!-- Firebase Cloud Messaging -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />

    <application
        android:label="QuitTxt"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="false"
        android:usesCleartextTraffic="false"
        android:networkSecurityConfig="@xml/network_security_config">

        <!-- Main Activity -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
                
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <!-- Firebase Cloud Messaging -->
        <service
            android:name=".FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>

        <!-- Don't delete the meta-data below -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
            
        <!-- Google Services -->
        <meta-data
            android:name="com.google.android.gms.version"
            android:value="@integer/google_play_services_version" />
    </application>
</manifest>
```

**Network Security Configuration**
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">firebaseapp.com</domain>
        <domain includeSubdomains="true">googleapis.com</domain>
        <domain includeSubdomains="true">google.com</domain>
        <pin-set expiration="2025-12-31">
            <pin digest="SHA-256">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=</pin>
            <pin digest="SHA-256">BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=</pin>
        </pin-set>
    </domain-config>
</network-security-config>
```

## E.8 Monitoring and Observability

### E.8.1 Application Performance Monitoring

**Firebase Performance Configuration**
```dart
class PerformanceService {
  static Future<void> initialize() async {
    FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
    
    // Custom traces for critical user journeys
    await _setupCustomTraces();
    
    // HTTP request monitoring
    await _setupNetworkMonitoring();
  }

  static Future<void> _setupCustomTraces() async {
    // Authentication flow trace
    final authTrace = FirebasePerformance.instance.newTrace('auth_flow');
    await authTrace.start();
    
    // Message sending trace
    final messageTrace = FirebasePerformance.instance.newTrace('send_message');
    await messageTrace.start();
  }

  static Future<void> _setupNetworkMonitoring() async {
    final httpClient = HttpClientWithPerformance();
    // Configure HTTP monitoring
  }
}
```

### E.8.2 Error Reporting and Crashlytics

**Crashlytics Integration**
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class ErrorReportingService {
  static Future<void> initialize() async {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    
    // Set custom keys for debugging
    await FirebaseCrashlytics.instance.setCustomKey('environment', 'production');
    await FirebaseCrashlytics.instance.setCustomKey('app_version', '1.0.0');
    
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FirebaseCrashlytics.instance.recordFlutterError(details);
    };
  }

  static void reportError(dynamic error, StackTrace stackTrace, {
    Map<String, dynamic>? context,
  }) {
    if (context != null) {
      context.forEach((key, value) {
        FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
      });
    }
    
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}
```

---

*This technical appendix provides comprehensive implementation details supporting the academic analysis presented in Chapter 4. The specifications demonstrate the complexity and sophistication required for healthcare-compliant mobile messaging applications while maintaining academic rigor appropriate for Master's thesis documentation.*