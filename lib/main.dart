import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'providers/chat_provider.dart';
import 'providers/bot_chat_provider.dart';
import 'providers/channel_provider.dart';
import 'providers/system_chat_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dash_chat_provider.dart';
import 'providers/service_provider.dart';
import 'providers/chat_mode_provider.dart';
import 'providers/gemini_chat_provider.dart';
import 'services/bot_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'theme/ios_theme.dart';
import 'screens/main_screen.dart';

// Import Firebase
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_connection_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
    
    // Test Firebase connection - but don't block app startup if it fails
    try {
      final firebaseConnectionService = FirebaseConnectionService();
      await firebaseConnectionService.testConnection();
    } catch (connectionError) {
      print('Firebase connection test failed: $connectionError');
      print('Continuing in demo mode');
    }
  } catch (e) {
    // If Firebase initialization fails, log it but don't crash
    print('Failed to initialize Firebase: $e');
    print('Running in demo mode without Firebase');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => BotChatProvider()),
        ChangeNotifierProvider(create: (_) => ChannelProvider()),
        ChangeNotifierProvider(create: (_) => SystemChatProvider()),
        ChangeNotifierProvider(create: (_) => ChatModeProvider()),
        ChangeNotifierProvider(create: (_) => GeminiChatProvider()),
        Provider(create: (_) => BotService()),
        // Create DashChatProvider with Firebase if available
        ChangeNotifierProvider(create: (_) {
          try {
            // Try to use the Firebase-enabled constructor first
            return DashChatProvider();
          } catch (e) {
            print('Error initializing DashChatProvider with Firebase: $e');
            print('Falling back to demo mode without Firebase');
            return DashChatProvider.withoutFirebase();
          }
        }),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final app = Platform.isIOS
              ? MaterialApp(
                  title: 'RCS Demo App',
                  debugShowCheckedModeBanner: false,
                  theme: IosTheme.lightTheme,
                  darkTheme: IosTheme.darkTheme,
                  themeMode: ThemeMode.system,
                  home: authProvider.isAuthenticated ? const HomeScreen() : const LoginScreen(),
                )
              : MaterialApp(
                  title: 'RCS Demo App',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: ThemeMode.system,
                  home: authProvider.isAuthenticated ? const HomeScreen() : const LoginScreen(),
                );
          return app;
        },
      ),
    );
  }
}