import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final userProfileProvider = Provider.of<UserProfileProvider>(context);
    final localizations = AppLocalizations.of(context);
    final user = authProvider.currentUser;

    // Get data from user profile and auth info
    final userId = user?.uid ?? 'pUuutN05eoYeWshsKyXBwrRoFW9u1';
    final username = userProfileProvider.displayName ??
        user?.displayName ??
        user?.email ??
        'User';
    final signInMethod =
        user?.providerData.first.providerId ?? 'GOOGLE_SIGN_IN';

    // Format last access time
    final lastAccessTime = DateTime.now()
        .subtract(const Duration(days: 3, hours: 12, minutes: 30));
    final lastAccessString =
        '${lastAccessTime.year}-${lastAccessTime.month.toString().padLeft(2, '0')}-${lastAccessTime.day.toString().padLeft(2, '0')} ${lastAccessTime.hour.toString().padLeft(2, '0')}:${lastAccessTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          'Quitxt Mobile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.quitxtTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header section
              _buildProfileHeader(username),

              const SizedBox(height: 24),

              // Account information card
              _buildAccountInfoCard(
                localizations,
                username,
                lastAccessString,
                signInMethod,
                userId,
              ),

              const SizedBox(height: 24),

              // Language preferences card
              _buildLanguageCard(context, localizations, languageProvider),

              const SizedBox(height: 32),

              // Sign out button
              _buildSignOutButton(context, authProvider, localizations),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String username) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowSubtle,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.quitxtTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              Icons.person,
              size: 32,
              color: AppTheme.quitxtTeal,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Active user',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(
    AppLocalizations localizations,
    String username,
    String lastAccessString,
    String signInMethod,
    String userId,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderLight,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowSubtle,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
              localizations.translate('last_access_time'), lastAccessString),
          const SizedBox(height: 12),
          _buildInfoRow(
              localizations.translate('sign_in_method'), signInMethod),
          const SizedBox(height: 12),
          _buildInfoRow(localizations.translate('user_id'), userId),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    AppLocalizations localizations,
    LanguageProvider languageProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderLight,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowSubtle,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('language'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLanguageOption(
                  context,
                  'English',
                  languageProvider.currentLocale.languageCode == 'en',
                  () {
                    languageProvider.setLanguage('en');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLanguageOption(
                  context,
                  'Español',
                  languageProvider.currentLocale.languageCode == 'es',
                  () {
                    languageProvider.setLanguage('es');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String language,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppTheme.quitxtTeal : AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.quitxtTeal : AppTheme.borderLight,
            width: 1,
          ),
        ),
        child: Text(
          language,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(
    BuildContext context,
    AuthProvider authProvider,
    AppLocalizations localizations,
  ) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          authProvider.signOut();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          localizations.translate('sign_out'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
