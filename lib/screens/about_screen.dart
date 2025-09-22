import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/debug_config.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  
  // Helper to launch URL
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        DebugConfig.debugPrint('Could not launch $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $url')),
          );
        }
      }
    } catch (e) {
      DebugConfig.debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Quitxt'),
        backgroundColor: AppTheme.quitxtTeal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/logos/avatar high rez.jpg',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.quitxtTeal,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'Q',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quitxt',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.quitxtTeal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your Personal Quit Coach',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Main Description
            const Text(
              'About the Quitxt Program',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.quitxtTeal,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Smoking and vaping are tough opponents.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 12),
            
            const Text(
              "That's why you are invited to join Quitxt, a free bilingual texting service that turns your smartphone into a personal coach to help you quit smoking/vaping!",
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Quitxt sends interactive and entertaining texts over 4 months of service with links to online support, and music and videos developed by UT Health San Antonio researchers, with an additional 2 months of support to help you stay free from smoking/vaping.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Texts focus on motivation to quit, setting a quit date, finding things to do instead of smoking/vaping, handling stress, coping, and more.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // How to Join Section
            const Text(
              'How to Join',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.quitxtTeal,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Simple chat instruction
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.quitxtTeal, AppTheme.quitxtPurple],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.quitxtTeal.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Ready to Start Your Journey?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Simply text "iquit0" in the chat to begin your personalized quit journey.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Effectiveness Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.quitxtTeal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.quitxtTeal.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.quitxtTeal.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.science,
                    color: AppTheme.quitxtTeal,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: '"Text-message applications have scientifically proven to roughly ',
                        ),
                        TextSpan(
                          text: 'double one\'s odds of quitting smoking/vaping',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.quitxtTeal),
                        ),
                        TextSpan(
                          text: ', which can help you ',
                        ),
                        TextSpan(
                          text: 'live 10 years longer and healthier, and save \$50,000',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.quitxtTeal),
                        ),
                        TextSpan(
                          text: '," said Dr. Amelie G. Ramirez, study leader and director of the Institute for Health Promotion Research at UT Health San Antonio. "We developed Quitxt specifically for young adults to help them quit for good."',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Target Audience
            const Text(
              'Who Can Join',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.quitxtTeal,
              ),
            ),
            
            const SizedBox(height: 12),
            
            const Text(
              'Quitxt is now enrolling English- and Spanish-speaking individuals who are trying to quit smoking and/or vaping. The program is primarily designed for young adults ages 18-29, but everyone who wants to quit is welcomed to enroll. If you would like to enroll and are 18 and older, text the number above.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Research Information
            const Text(
              'Research & Development',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.quitxtTeal,
              ),
            ),
            
            const SizedBox(height: 12),
            
            const Text(
              'The service for text messaging was created by the Institute for Health Promotion Research (IHPR) at UT Health San Antonio and developed by the Software Communications and Navigation Systems (SCNS) Laboratory at the University of Texas at San Antonio, for a study funded by the Cancer Prevention and Research Institute of Texas. The service is supported by a grant from the Cancer Prevention and Research Institute of Texas.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Website Link
            Center(
              child: GestureDetector(
                onTap: () => _launchURL('https://quitxt.org/'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.quitxtTeal, width: 2),
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.quitxtTeal.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.language,
                        color: AppTheme.quitxtTeal,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Visit quitxt.org',
                        style: TextStyle(
                          color: AppTheme.quitxtTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Footer
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.quitxtTeal, AppTheme.quitxtPurple],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.quitxtTeal.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Start Your Quit Journey Today!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '© 2024 UT Health San Antonio',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}