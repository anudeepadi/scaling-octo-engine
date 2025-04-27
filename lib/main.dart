import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'providers/channel_provider.dart';
import 'providers/system_chat_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dash_chat_provider.dart';
import 'providers/service_provider.dart';
import 'providers/language_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'utils/app_localizations.dart';

// Import Flutter localizations
import 'package:flutter_localizations/flutter_localizations.dart';

// Import Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/firebase_connection_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
    
    // Request FCM token
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $fcmToken');
    
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
        ChangeNotifierProvider(create: (_) => ChannelProvider()),
        ChangeNotifierProvider(create: (_) => SystemChatProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),

        ChangeNotifierProxyProvider<AuthProvider, DashChatProvider>(
          create: (_) => DashChatProvider(),
          update: (_, authProvider, previousDashChatProvider) {
            final dashChatProvider = previousDashChatProvider ?? DashChatProvider();

            if (authProvider.isAuthenticated && !dashChatProvider.isServerServiceInitialized) {
              final userId = authProvider.currentUser?.uid;
              if (userId != null) {
                FirebaseMessaging.instance.getToken().then((token) {
                  if (token != null) {
                    print('Attempting to initialize Server Service for user: $userId with token: $token');
                    dashChatProvider.initializeServerService(userId, token);
                  } else {
                     print('Failed to get FCM token for user: $userId');
                  }
                }).catchError((error) {
                   print('Error getting FCM token or initializing server service for user $userId: $error');
                });
              } else {
                 print('Cannot initialize Server Service: User ID is null even though authenticated.');
              }
            } else if (!authProvider.isAuthenticated) {
               dashChatProvider.clearOnLogout();
               print('User logged out, cleared DashChatProvider state.');
            }

            return dashChatProvider;
          },
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return MaterialApp(
                title: 'QuitTXT Mobile',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                themeMode: ThemeMode.light,
                locale: languageProvider.currentLocale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: authProvider.isAuthenticated ? const HomeScreen() : const LoginScreen(),
              );
            },
          );
        },
      ),
    );
  }
}