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
    final username = userProfileProvider.displayName ?? user?.displayName ?? user?.email ?? 'User';
    final signInMethod = user?.providerData.first.providerId ?? 'GOOGLE_SIGN_IN';
    
    // Format last access time
    final lastAccessTime = DateTime.now().subtract(const Duration(days: 3, hours: 12, minutes: 30));
    final lastAccessString = '${lastAccessTime.year}-${lastAccessTime.month.toString().padLeft(2, '0')}-${lastAccessTime.day.toString().padLeft(2, '0')} ${lastAccessTime.hour.toString().padLeft(2, '0')}:${lastAccessTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QuiTXT Mobile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppTheme.quitxtTeal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User information displayed as plain text
              _buildInfoText(localizations.translate('user'), username),
              _buildInfoText(localizations.translate('last_access_time'), lastAccessString),
              _buildInfoText(localizations.translate('sign_in_method'), signInMethod),
              _buildInfoText(localizations.translate('user_id'), userId),
              
              const SizedBox(height: 32),
              
              // Language selector
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.translate('language'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                          const SizedBox(width: 16),
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
                ),
              ),
              
              const Spacer(),
              
              // Sign out button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    authProvider.signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(localizations.translate('sign_out')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.green,
            ),
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.quitxtTeal : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          language,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}