import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'dart:async' show TimeoutException;
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
import 'utils/ios_performance_utils.dart';

// Import Flutter localizations
import 'package:flutter_localizations/flutter_localizations.dart';

// Import Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'services/firebase_connection_service.dart';
import 'services/firebase_messaging_service.dart';
import 'services/notification_service.dart';
import 'services/user_profile_service.dart';
import 'services/analytics_service.dart';
import 'services/quick_reply_state_service.dart';

// Import dotenv for environment variables
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

// Error boundary widget for graceful error handling
class AppErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? error;

  const AppErrorBoundary({super.key, required this.child, this.error});

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 64,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Quitxt',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Initializing app services...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Starting Firebase connection',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return child;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optimize performance - prevent main thread blocking
  if (Platform.isAndroid) {
    await Future.microtask(() => null);
  }

  try {
    // Apply platform-specific optimizations
    if (Platform.isIOS) {
      developer.log('Applying iOS performance optimizations', name: 'App');
      await IOSPerformanceUtils.applyOptimizations();
    }

    // Determine which .env file to load
    final prefs = await SharedPreferences.getInstance();
    final currentEnv = prefs.getString('current_env');
    String envFile = '.env';

    if (currentEnv == Environment.production.toString()) {
      envFile = '.env.production';
    } else if (currentEnv == Environment.development.toString()) {
      envFile = '.env.development';
    }

    // Try to load environment variables, but continue if files don't exist
    try {
      await dotenv.load(fileName: envFile).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          developer.log('Loading $envFile timed out, using defaults',
              name: 'App');
          throw TimeoutException('Loading $envFile timed out');
        },
      );
      developer.log('Environment variables loaded from $envFile', name: 'App');
      developer.log('Using environment: ${dotenv.env['ENV']}', name: 'App');
    } catch (e) {
      developer.log('Could not load $envFile: $e', name: 'App');
      developer.log('Continuing with default environment variables',
          name: 'App');
      // Provide default values when env files are missing
      dotenv.env['SERVER_URL'] = 'http://localhost:8080';
      dotenv.env['ENV'] = 'development';
    }

    // Print platform information for debugging
    final platformInfo = Platform.isAndroid
        ? "Android ${Platform.operatingSystemVersion}"
        : Platform.isIOS
            ? "iOS ${Platform.operatingSystemVersion}"
            : Platform.operatingSystem;
    developer.log('Running on platform: $platformInfo', name: 'App');
    developer.log('Running in emulator: ${PlatformUtils.isEmulator}',
        name: 'App');

    // Platform-specific server URL
    final originalUrl = dotenv.env['SERVER_URL'] ?? 'http://localhost:8080';
    final transformedUrl = PlatformUtils.transformLocalHostUrl(originalUrl);
    developer.log('Original server URL: $originalUrl', name: 'App');
    developer.log('Transformed server URL: $transformedUrl', name: 'App');

    // Initialize Firebase with platform-specific optimizations
    try {
      // For iOS, use a longer timeout for Firebase initialization
      final firebaseInitTimeout = Platform.isIOS
          ? const Duration(seconds: 15)
          : const Duration(seconds: 10);

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        firebaseInitTimeout,
        onTimeout: () {
          developer.log(
              'Firebase initialization timed out after ${firebaseInitTimeout.inSeconds}s',
              name: 'App');
          throw TimeoutException('Firebase initialization timed out');
        },
      );
      developer.log('Firebase initialized successfully', name: 'App');

      // Initialize Firebase App Check to fix "No AppCheckProvider installed" error
      try {
        final recaptchaSiteKey = dotenv.env['RECAPTCHA_SITE_KEY'] ??
            '6Ld_OqArAAAAAH0vSUdLv_LaiDmFl67BLpJi0Xyg';
        developer.log(
            'Using reCAPTCHA site key: ${recaptchaSiteKey.substring(0, 10)}...',
            name: 'App');

        await FirebaseAppCheck.instance.activate(
          // Use reCAPTCHA site key from environment variables
          webProvider: ReCaptchaV3Provider(recaptchaSiteKey),
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
        developer.log('Firebase App Check initialized successfully',
            name: 'App');
      } catch (appCheckError) {
        developer.log(
            'Firebase App Check initialization failed: $appCheckError',
            name: 'App');
        developer.log(
            'Continuing without App Check - this may cause authentication issues',
            name: 'App');
      }

      // Log Firebase initialization details for debugging
      if (Firebase.apps.isNotEmpty) {
        developer.log('Firebase app name: ${Firebase.app().name}', name: 'App');
        developer.log('Firebase options: ${Firebase.app().options.projectId}',
            name: 'App');
      } else {
        developer.log('WARNING: Firebase.apps is empty after initialization!',
            name: 'App');
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
        developer.log('Firebase connection test failed: $connectionError',
            name: 'App');
        developer.log('Continuing in demo mode', name: 'App');
      }

      // Initialize Quick Reply State Service
      try {
        final quickReplyStateService = QuickReplyStateService();
        await quickReplyStateService.initialize();
        developer.log('Quick Reply State Service initialized successfully',
            name: 'App');
      } catch (quickReplyError) {
        developer.log(
            'Quick Reply State Service initialization failed: $quickReplyError',
            name: 'App');
        developer.log('Continuing without quick reply state persistence',
            name: 'App');
      }
    } catch (e) {
      // If Firebase initialization fails, log it but don't crash
      developer.log('Failed to initialize Firebase or load env: $e',
          name: 'App');
      developer.log('Running in demo mode without Firebase', name: 'App');
    }
  } catch (e) {
    developer.log('Error during app initialization: $e', name: 'App');

    // Show error boundary instead of crashing
    runApp(AppErrorBoundary(
      error: 'Initializing app services...',
      child: const MyApp(),
    ));

    // Try to initialize Firebase again after a delay
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        developer.log('Firebase initialized successfully on retry',
            name: 'App');

        // Restart the app with proper initialization
        runApp(const MyApp());
      } catch (retryError) {
        developer.log('Firebase retry failed: $retryError', name: 'App');
      }
    });
    return;
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
            final userProfileProvider = previousUserProfileProvider ??
                UserProfileProvider(
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
                developer.log('Initializing User Profile for user: $userId',
                    name: 'UserProfile');
              }
            }

            return userProfileProvider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, DashChatProvider>(
          create: (_) => DashChatProvider(),
          update: (_, authProvider, previousDashChatProvider) {
            final dashChatProvider =
                previousDashChatProvider ?? DashChatProvider();

            if (authProvider.isAuthenticated &&
                !dashChatProvider.isServerServiceInitialized) {
              final userId = authProvider.currentUser?.uid;
              if (userId != null) {
                FirebaseMessaging.instance.getToken().then((token) async {
                  if (token != null) {
                    developer.log(
                        'Initializing Server Service for user: $userId with token: ${token.substring(0, 20)}...',
                        name: 'App');
                    try {
                      await dashChatProvider.initializeServerService(
                          userId, token);
                      developer.log(
                          'Server Service initialized successfully for user: $userId',
                          name: 'App');
                    } catch (initError) {
                      developer.log(
                          'Error initializing server service for user $userId: $initError',
                          name: 'App');
                    }

                    // Print token in a format easy to copy for testing
                    developer.log(
                        '==================== FCM TOKEN ====================',
                        name: 'FCM');
                    developer.log(token, name: 'FCM');
                    developer.log(
                        '==================================================',
                        name: 'FCM');
                  } else {
                    developer.log('Failed to get FCM token for user: $userId',
                        name: 'App');
                  }
                }).catchError((error) {
                  developer.log(
                      'Error getting FCM token or initializing server service for user $userId: $error',
                      name: 'App');
                });
              } else {
                developer.log(
                    'Cannot initialize Server Service: User ID is null even though authenticated.',
                    name: 'App');
              }
            } else if (!authProvider.isAuthenticated) {
              // Defer the logout clearing to avoid setState during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                dashChatProvider.clearOnLogout();
                developer.log(
                    'User logged out, cleared DashChatProvider state.',
                    name: 'App');
              });
            }

            return dashChatProvider;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          return Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return MaterialApp(
                    title: 'Quitxt Mobile',
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
                    home: authProvider.isAuthenticated
                        ? const HomeScreen()
                        : const LoginScreen(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
