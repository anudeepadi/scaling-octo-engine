import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/chat_provider.dart';
import 'providers/channel_provider.dart';
import 'providers/system_chat_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dash_chat_provider.dart';
import 'providers/service_provider.dart';
import 'providers/language_provider.dart';
import 'providers/user_profile_provider.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

// Theme and localization
import 'theme/app_theme.dart';
import 'utils/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Services (simplified for demo)
import 'services/user_profile_service.dart';
import 'services/analytics_service.dart';

/// QuitTxt - Demo Version for Thesis Exploration
///
/// This is a simplified version with production connections removed.
/// Firebase and backend API integrations have been stubbed for demonstration purposes.
///
/// Key Features:
/// - Provider-based state management
/// - Multi-screen navigation
/// - Internationalization support (English/Spanish)
/// - Clean architecture with separation of concerns
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const QuitTxtApp());
}

/// Main application widget with provider configuration
class QuitTxtApp extends StatelessWidget {
  const QuitTxtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Authentication state
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),

        // Chat messaging state
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),

        // Channel management
        ChangeNotifierProvider(
          create: (_) => ChannelProvider(),
        ),

        // System messages
        ChangeNotifierProvider(
          create: (_) => SystemChatProvider(),
        ),

        // Service layer coordination
        ChangeNotifierProvider(
          create: (_) => ServiceProvider(),
        ),

        // Internationalization
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
        ),

        // User profile management - depends on auth state
        ChangeNotifierProxyProvider<AuthProvider, UserProfileProvider>(
          create: (_) => UserProfileProvider(
            userProfileService: UserProfileService(),
            analyticsService: AnalyticsService(),
          ),
          update: (context, authProvider, previousProfileProvider) {
            final profileProvider = previousProfileProvider ??
                UserProfileProvider(
                  userProfileService: UserProfileService(),
                  analyticsService: AnalyticsService(),
                );

            // Initialize profile when user authenticates
            if (authProvider.isAuthenticated) {
              final userId = authProvider.currentUser?.uid;
              if (userId != null) {
                profileProvider.initializeProfile(userId);

                // Sync display name from auth
                final displayName = authProvider.currentUser?.displayName;
                if (displayName != null && displayName.isNotEmpty) {
                  profileProvider.updateDisplayName(displayName);
                }
              }
            }

            return profileProvider;
          },
        ),

        // Server chat integration - depends on auth state
        ChangeNotifierProxyProvider<AuthProvider, DashChatProvider>(
          create: (_) => DashChatProvider(),
          update: (context, authProvider, previousDashProvider) {
            final dashProvider = previousDashProvider ?? DashChatProvider();

            if (authProvider.isAuthenticated &&
                !dashProvider.isServerServiceInitialized) {
              final userId = authProvider.currentUser?.uid;
              if (userId != null) {
                // Initialize server service (stubbed in demo mode)
                dashProvider.initializeServerService(userId, 'demo-token');
              }
            } else if (!authProvider.isAuthenticated) {
              // Clear state on logout
              WidgetsBinding.instance.addPostFrameCallback((_) {
                dashProvider.clearOnLogout();
              });
            }

            return dashProvider;
          },
        ),
      ],
      child: const AppContent(),
    );
  }
}

/// App content with localization and routing
class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return MaterialApp(
              title: 'QuitTxt - Demo Version',
              debugShowCheckedModeBanner: false,

              // Theme configuration
              theme: AppTheme.lightTheme,
              themeMode: ThemeMode.light,

              // Internationalization setup
              locale: languageProvider.currentLocale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              // Routing based on auth state
              home: authProvider.isAuthenticated
                  ? const HomeScreen()
                  : const LoginScreen(),
            );
          },
        );
      },
    );
  }
}
