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
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'theme/ios_theme.dart';

// Import Firebase only if we're going to use it
// import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Skip Firebase initialization for now to avoid conflicts
  print('Running in demo mode without Firebase');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => BotChatProvider()),
        ChangeNotifierProvider(create: (_) => ChannelProvider()),
        ChangeNotifierProvider(create: (_) => SystemChatProvider()),
        // Create DashChatProvider without Firebase for now
        ChangeNotifierProvider(create: (_) {
          try {
            return DashChatProvider.withoutFirebase();
          } catch (e) {
            print('Error initializing DashChatProvider: $e');
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