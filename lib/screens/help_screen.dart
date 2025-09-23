import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dash_chat_provider.dart';
import '../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          'Help & Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroCard(context),
            const SizedBox(height: 24),
            _buildKeywordSection(
              context,
              'Crisis Support',
              Icons.emergency,
              AppTheme.errorRed,
              [
                {'keyword': 'helpnow', 'label': 'Help Now', 'description': 'Immediate crisis support'},
                {'keyword': 'crisis', 'label': 'Crisis Help', 'description': 'Crisis intervention resources'},
                {'keyword': 'ayudaahora', 'label': 'Ayuda Ahora', 'description': 'Ayuda inmediata en crisis'},
              ],
            ),
            const SizedBox(height: 20),
            _buildKeywordSection(
              context,
              'Cravings & Urges',
              Icons.psychology,
              AppTheme.primaryBlue,
              [
                {'keyword': 'crave', 'label': 'Craving', 'description': 'Managing cravings and urges'},
                {'keyword': 'urge', 'label': 'Urge', 'description': 'Dealing with sudden urges'},
                {'keyword': 'antojo', 'label': 'Antojo', 'description': 'Manejo de antojos'},
              ],
            ),
            const SizedBox(height: 20),
            _buildKeywordSection(
              context,
              'Emotional Support',
              Icons.favorite,
              AppTheme.wellnessGreen,
              [
                {'keyword': 'badmood', 'label': 'Bad Mood', 'description': 'Mood management strategies'},
                {'keyword': 'stress', 'label': 'Stress', 'description': 'Stress relief techniques'},
                {'keyword': 'estres', 'label': 'Estrés', 'description': 'Técnicas para el estrés'},
                {'keyword': 'malhumor', 'label': 'Mal Humor', 'description': 'Manejo del mal humor'},
              ],
            ),
            const SizedBox(height: 20),
            _buildKeywordSection(
              context,
              'Recovery & Setbacks',
              Icons.trending_up,
              AppTheme.warningOrange,
              [
                {'keyword': 'slip', 'label': 'Slip', 'description': 'Dealing with setbacks'},
                {'keyword': 'relapse', 'label': 'Relapse', 'description': 'Relapse prevention support'},
                {'keyword': 'recaida', 'label': 'Recaída', 'description': 'Apoyo para recaídas'},
              ],
            ),
            const SizedBox(height: 20),
            _buildKeywordSection(
              context,
              'Substance-Specific',
              Icons.block,
              AppTheme.textSecondary,
              [
                {'keyword': 'alcohol', 'label': 'Alcohol', 'description': 'Alcohol-related support'},
                {'keyword': 'smokers', 'label': 'Smoking', 'description': 'Smoking cessation help'},
                {'keyword': 'fumadores', 'label': 'Fumadores', 'description': 'Ayuda para dejar de fumar'},
              ],
            ),
            const SizedBox(height: 20),
            _buildKeywordSection(
              context,
              'Motivation & Goals',
              Icons.star,
              AppTheme.accentPurple,
              [
                {'keyword': 'motivation', 'label': 'Motivation', 'description': 'Stay motivated in recovery'},
                {'keyword': 'goals', 'label': 'Goals', 'description': 'Set and track recovery goals'},
                {'keyword': 'motivacion', 'label': 'Motivación', 'description': 'Mantener la motivación'},
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.glassmorphismGradient,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderLight.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowSubtle,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowSubtle,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/logos/avatar high rez.jpg',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Quick Help Keywords',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap any keyword below to instantly send it to your health coach for personalized support and guidance.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordSection(
    BuildContext context,
    String title,
    IconData icon,
    Color accentColor,
    List<Map<String, String>> keywords,
  ) {
    // Separate English and Spanish keywords
    final englishKeywords = <Map<String, String>>[];
    final spanishKeywords = <Map<String, String>>[];
    
    for (final keyword in keywords) {
      final label = keyword['label']!;
      // Check if the label contains Spanish characters or is a common Spanish word
      if (_isSpanishKeyword(label)) {
        spanishKeywords.add(keyword);
      } else {
        englishKeywords.add(keyword);
      }
    }

    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // English keywords
          if (englishKeywords.isNotEmpty) ...[
            _buildLanguageLabel('English', accentColor),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: englishKeywords.map((keywordData) {
                return _buildKeywordChip(
                  context,
                  keywordData['keyword']!,
                  keywordData['label']!,
                  keywordData['description']!,
                  accentColor,
                );
              }).toList(),
            ),
          ],
          // Separator between English and Spanish
          if (englishKeywords.isNotEmpty && spanishKeywords.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    accentColor.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Spanish keywords
          if (spanishKeywords.isNotEmpty) ...[
            _buildLanguageLabel('Español', accentColor),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: spanishKeywords.map((keywordData) {
                return _buildKeywordChip(
                  context,
                  keywordData['keyword']!,
                  keywordData['label']!,
                  keywordData['description']!,
                  accentColor,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  bool _isSpanishKeyword(String label) {
    // List of Spanish keywords and characters to identify Spanish language
    final spanishIndicators = [
      'Ayuda', 'Ahora', 'Antojo', 'Estrés', 'Mal Humor', 'Recaída', 
      'Fumadores', 'Motivación', 'é', 'ñ', 'ó', 'í', 'á', 'ú'
    ];
    
    return spanishIndicators.any((indicator) => label.contains(indicator));
  }

  Widget _buildLanguageLabel(String language, Color accentColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 12,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          language,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: accentColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildKeywordChip(
    BuildContext context,
    String keyword,
    String label,
    String description,
    Color accentColor,
  ) {
    return GestureDetector(
      onTap: () => _sendKeywordToChat(context, keyword),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textTertiary,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _sendKeywordToChat(BuildContext context, String keyword) {
    final dashChatProvider = Provider.of<DashChatProvider>(context, listen: false);

    // Send the keyword as a message
    dashChatProvider.sendMessage(keyword);

    // Navigate back to the home screen (chat)
    Navigator.of(context).pop();

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent "$keyword" to your health coach'),
        backgroundColor: AppTheme.wellnessGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
