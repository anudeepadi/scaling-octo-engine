# Firebase Integration

This document provides detailed information about the Firebase integration in the RCS Application.

## Firebase Services Used

The application integrates with the following Firebase services:

1. **Firebase Authentication**
2. **Firestore Database**
3. **Firebase Storage**
4. **Firebase Cloud Messaging**

## Setup and Configuration

### Prerequisites

- Firebase account
- Firebase project created
- Flutter project set up

### Installation

1. Add Firebase dependencies to `pubspec.yaml`:
   ```yaml
   dependencies:
     firebase_core: ^x.x.x
     firebase_auth: ^x.x.x
     cloud_firestore: ^x.x.x
     firebase_storage: ^x.x.x
     firebase_messaging: ^x.x.x
   ```

2. Download and add configuration files:
   - For Android: `google-services.json` in `android/app/`
   - For iOS: `GoogleService-Info.plist` in `ios/Runner/`

3. Initialize Firebase in `main.dart`:
   ```dart
   await Firebase.initializeApp();
   ```

## Firebase Authentication

The application uses Firebase Authentication for user management:

- Implementation in `lib/providers/auth_provider.dart`
- Supports email/password authentication
- Supports Google Sign-In
- Handles user sessions and persistence

### Code Examples

```dart
// Sign in with email and password
Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
  return await _auth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
}

// Sign in with Google
Future<UserCredential> signInWithGoogle() async {
  final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  return await _auth.signInWithCredential(credential);
}
```

## Firestore Database

The application uses Firestore for storing chat data:

- Implementation in `lib/services/firebase_chat_service.dart`
- Collection structure:
  - `users`: User profiles and settings
  - `chats`: Chat conversations
  - `messages`: Chat messages

### Code Examples

```dart
// Get messages for a chat
Stream<List<ChatMessage>> getMessages(String chatId) {
  return _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return ChatMessage.fromJson(doc.data());
    }).toList();
  });
}

// Send a message
Future<void> sendMessage(ChatMessage message, String chatId) async {
  await _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .add(message.toJson());
}
```

## Firebase Storage

The application uses Firebase Storage for media files:

- Implementation in related services
- Used for storing images, videos, and other media
- Security rules to control access

### Code Examples

```dart
// Upload an image
Future<String> uploadImage(File file, String path) async {
  final ref = _storage.ref().child(path);
  final uploadTask = ref.putFile(file);
  final snapshot = await uploadTask.whenComplete(() => null);
  return await snapshot.ref.getDownloadURL();
}

// Download an image
Future<File> downloadImage(String url, String localPath) async {
  final ref = _storage.refFromURL(url);
  final bytes = await ref.getData();
  final file = File(localPath);
  await file.writeAsBytes(bytes!);
  return file;
}
```

## Firebase Cloud Messaging

The application uses Firebase Cloud Messaging for push notifications:

- Implementation in `lib/services/firebase_messaging_service.dart`
- Handles foreground and background messages
- Notification configuration for both platforms

### Code Examples

```dart
// Initialize messaging
Future<void> initializeMessaging() async {
  final messaging = FirebaseMessaging.instance;
  
  // Request permission
  NotificationSettings settings = await messaging.requestPermission();
  
  // Get token
  String? token = await messaging.getToken();
  
  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Handle foreground message
  });
  
  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}
```

## Security Considerations

- Implement proper security rules for Firestore and Storage
- Validate user permissions in the application code
- Secure API keys and credentials

## Testing Firebase Integration

- Use Firebase Emulator Suite for local testing
- Write integration tests for Firebase services
- Test authentication flows thoroughly

## Troubleshooting

Common issues and their solutions:

1. **Authentication failures**: Check credentials and network connectivity
2. **Firestore permission errors**: Review security rules
3. **Storage upload failures**: Check file size and format
4. **Push notification issues**: Verify device token registration

For more detailed information, refer to the official Firebase documentation.