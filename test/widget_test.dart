// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quitxt_app/providers/chat_provider.dart';
import 'package:quitxt_app/providers/channel_provider.dart';
import 'package:quitxt_app/providers/system_chat_provider.dart';
import 'package:quitxt_app/providers/service_provider.dart';
import 'package:quitxt_app/providers/language_provider.dart';
import 'package:quitxt_app/theme/app_theme.dart';

// Mock AuthProvider for testing
class MockAuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get userId => 'test-user-id';

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 100));

    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> signUp(String email, String password, String username) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 100));

    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 100));

    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    return await signIn('test@example.com', 'password');
  }
}

// Test version of the app without Firebase dependencies
class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MockAuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ChannelProvider()),
        ChangeNotifierProvider(create: (_) => SystemChatProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MaterialApp(
        title: 'Quitxt Test',
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: Text('Test App'),
          ),
        ),
      ),
    );
  }
}

void main() {
  setUpAll(() {
    // Mock Firebase to prevent initialization issues
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_core'),
      (methodCall) async {
        return <String, dynamic>{'name': '[DEFAULT]'};
      },
    );

    // Mock Firebase Auth
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_auth'),
      (methodCall) async {
        return null;
      },
    );
  });

  group('App Tests', () {
    testWidgets('App smoke test', (WidgetTester tester) async {
      // Build our test app and trigger a frame.
      await tester.pumpWidget(const TestApp());

      // Verify that our app starts up without throwing.
      expect(find.text('Test App'), findsOneWidget);
      expect(find.byType(TestApp), findsOneWidget);
    });

    test('MockAuthProvider functionality', () async {
      final authProvider = MockAuthProvider();

      // Test initial state
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.isLoading, false);

      // Test sign in
      final result = await authProvider.signIn('test@example.com', 'password');
      expect(result, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.isLoading, false);

      // Test sign out
      await authProvider.signOut();
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.isLoading, false);
    });
  });
}
