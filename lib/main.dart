import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'providers/channel_provider.dart';
import 'providers/system_chat_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dash_chat_provider.dart';
import 'providers/service_provider.dart';
import 'providers/language_provider.dart';
import 'providers/user_profile_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'utils/app_localizations.dart';
import 'utils/env_switcher.dart';
import 'utils/platform_utils.dart';

// Import Flutter localizations
import 'package:flutter_localizations/flutter_localizations.dart';

// Import Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'services/firebase_connection_service.dart';
import 'services/firebase_messaging_service.dart';
import 'services/notification_service.dart';
import 'services/user_profile_service.dart';
import 'services/analytics_service.dart';

// Import dotenv for environment variables
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Determine which .env file to load
    final prefs = await SharedPreferences.getInstance();
    final currentEnv = prefs.getString('current_env');
    String envFile = '.env';
    
    if (currentEnv == Environment.production.toString()) {
      envFile = '.env.production';
    } else if (currentEnv == Environment.development.toString()) {
      envFile = '.env.development';
    }
    
    // Load environment variables
    await dotenv.load(fileName: envFile);
    developer.log('Environment variables loaded from $envFile', name: 'App');
    developer.log('Using environment: ${dotenv.env['ENV']}', name: 'App');
    
    // Print platform information for debugging
    final platformInfo = Platform.isAndroid 
        ? "Android ${Platform.operatingSystemVersion}"
        : Platform.isIOS 
        ? "iOS ${Platform.operatingSystemVersion}" 
        : Platform.operatingSystem;
    developer.log('Running on platform: $platformInfo', name: 'App');
    developer.log('Running in emulator: ${PlatformUtils.isEmulator}', name: 'App');
    
    // Platform-specific server URL
    final originalUrl = dotenv.env['SERVER_URL'] ?? 'http://localhost:8080';
    final transformedUrl = PlatformUtils.transformLocalHostUrl(originalUrl);
    developer.log('Original server URL: $originalUrl', name: 'App');
    developer.log('Transformed server URL: $transformedUrl', name: 'App');
    
    // Initialize Firebase
    try {
      await Firebase.initializeApp();
      developer.log('Firebase initialized successfully', name: 'App');
      
      // Initialize Firebase App Check to fix "No AppCheckProvider installed" error
      try {
        await FirebaseAppCheck.instance.activate(
          // For development, use debug provider
          // For production, switch to device check (iOS) or play integrity (Android)
          webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
        developer.log('Firebase App Check initialized successfully', name: 'App');
      } catch (appCheckError) {
        developer.log('Firebase App Check initialization failed: $appCheckError', name: 'App');
        developer.log('Continuing without App Check - this may cause authentication issues', name: 'App');
      }
      
      // Log Firebase initialization details for debugging
      if (Firebase.apps.isNotEmpty) {
        developer.log('Firebase app name: ${Firebase.app().name}', name: 'App');
        developer.log('Firebase options: ${Firebase.app().options.projectId}', name: 'App');
      } else {
        developer.log('WARNING: Firebase.apps is empty after initialization!', name: 'App');
      }
      
      // Initialize Notification Service first
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      // Initialize Firebase Messaging Service
      final firebaseMessagingService = FirebaseMessagingService();
      await firebaseMessagingService.setupMessaging();
      
      // Request and log FCM token
      final fcmToken = await firebaseMessagingService.getFcmToken();
      developer.log('FCM Token: $fcmToken', name: 'FCM');
      
      // Test Firebase connection - but don't block app startup if it fails
      try {
        final firebaseConnectionService = FirebaseConnectionService();
        await firebaseConnectionService.testConnection();
      } catch (connectionError) {
        developer.log('Firebase connection test failed: $connectionError', name: 'App');
        developer.log('Continuing in demo mode', name: 'App');
      }
    } catch (e) {
      // If Firebase initialization fails, log it but don't crash
      developer.log('Failed to initialize Firebase or load env: $e', name: 'App');
      developer.log('Running in demo mode without Firebase', name: 'App');
    }
  } catch (e) {
    developer.log('Error during app initialization: $e', name: 'App');
  }

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
        ChangeNotifierProvider(create: (_) => ChannelProvider()),
        ChangeNotifierProvider(create: (_) => SystemChatProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),

        ChangeNotifierProxyProvider<AuthProvider, UserProfileProvider>(
          create: (_) => UserProfileProvider(
            userProfileService: UserProfileService(),
            analyticsService: AnalyticsService(),
          ),
          update: (_, authProvider, previousUserProfileProvider) {
            final userProfileProvider = previousUserProfileProvider ?? UserProfileProvider(
              userProfileService: UserProfileService(),
              analyticsService: AnalyticsService(),
            );

            if (authProvider.isAuthenticated) {
              final userId = authProvider.currentUser?.uid;
              if (userId != null) {
                // Initialize user profile when user is authenticated
                userProfileProvider.initializeProfile(userId).then((_) {
                  // Sync display name from Firebase Auth
                  final displayName = authProvider.currentUser?.displayName;
                  if (displayName != null && displayName.isNotEmpty) {
                    userProfileProvider.updateDisplayName(displayName);
                  }
                });
                developer.log('Initializing User Profile for user: $userId', name: 'UserProfile');
              }
            }

            return userProfileProvider;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, DashChatProvider>(
          create: (_) => DashChatProvider(),
          update: (_, authProvider, previousDashChatProvider) {
            final dashChatProvider = previousDashChatProvider ?? DashChatProvider();

            if (authProvider.isAuthenticated && !dashChatProvider.isServerServiceInitialized) {
              final userId = authProvider.currentUser?.uid;
              if (userId != null) {
                FirebaseMessaging.instance.getToken().then((token) async {
                  if (token != null) {
                    developer.log('Initializing Server Service for user: $userId with token: ${token.substring(0, 20)}...', name: 'App');
                    try {
                      await dashChatProvider.initializeServerService(userId, token);
                      developer.log('Server Service initialized successfully for user: $userId', name: 'App');
                    } catch (initError) {
                      developer.log('Error initializing server service for user $userId: $initError', name: 'App');
                    }
                    
                    // Print token in a format easy to copy for testing
                    developer.log('==================== FCM TOKEN ====================', name: 'FCM');
                    developer.log(token, name: 'FCM');
                    developer.log('==================================================', name: 'FCM');
                  } else {
                     developer.log('Failed to get FCM token for user: $userId', name: 'App');
                  }
                }).catchError((error) {
                   developer.log('Error getting FCM token or initializing server service for user $userId: $error', name: 'App');
                });
              } else {
                 developer.log('Cannot initialize Server Service: User ID is null even though authenticated.', name: 'App');
              }
            } else if (!authProvider.isAuthenticated) {
               // Defer the logout clearing to avoid setState during build
               WidgetsBinding.instance.addPostFrameCallback((_) {
                 dashChatProvider.clearOnLogout();
                 developer.log('User logged out, cleared DashChatProvider state.', name: 'App');
               });
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