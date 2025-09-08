import '../services/link_preview_service.dart';
import '../utils/debug_config.dart';

class LinkPreviewTest {
  static Future<void> testQuitxtUrls() async {
    final testUrls = [
      'https://quitxt.org/nicotine-replacement',
      'https://quitxt.org/reasons',
      'http://quitxt.org/instead-of-smoking',
      'http://quitxt.org/getting-active',
      'https://quitxt.org/support',
      'http://quitxt.org/talk-yourself-out-of-smoking',
    ];

    DebugConfig.debugPrint(
        '🔍 LinkPreviewTest: Testing ${testUrls.length} Quitxt URLs...');

    for (int i = 0; i < testUrls.length; i++) {
      final url = testUrls[i];
      DebugConfig.debugPrint('');
      DebugConfig.debugPrint(
          '📎 Testing URL ${i + 1}/${testUrls.length}: $url');

      try {
        final preview = await LinkPreviewService.fetchLinkPreview(url);

        if (preview != null) {
          DebugConfig.debugPrint('✅ SUCCESS: Preview fetched');
          DebugConfig.debugPrint('   Title: ${preview.title}');
          DebugConfig.debugPrint('   Description: ${preview.description}');
          DebugConfig.debugPrint('   Image: ${preview.imageUrl ?? 'None'}');
          DebugConfig.debugPrint('   Site: ${preview.siteName ?? 'None'}');
        } else {
          DebugConfig.debugPrint('❌ FAILED: No preview returned');
        }
      } catch (e) {
        DebugConfig.debugPrint('💥 ERROR: $e');
      }

      // Add small delay between requests
      await Future.delayed(const Duration(milliseconds: 500));
    }

    DebugConfig.debugPrint('');
    DebugConfig.debugPrint('🏁 LinkPreviewTest: Completed testing all URLs');
    DebugConfig.debugPrint('Cache size: ${LinkPreviewService.getCacheSize()}');
  }

  static Future<void> testBasicUrls() async {
    final testUrls = [
      'https://www.google.com',
      'https://www.github.com',
      'https://flutter.dev',
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // This should be skipped
    ];

    DebugConfig.debugPrint(
        '🔍 LinkPreviewTest: Testing ${testUrls.length} basic URLs...');

    for (int i = 0; i < testUrls.length; i++) {
      final url = testUrls[i];
      DebugConfig.debugPrint('');
      DebugConfig.debugPrint(
          '📎 Testing URL ${i + 1}/${testUrls.length}: $url');

      try {
        final preview = await LinkPreviewService.fetchLinkPreview(url);

        if (preview != null) {
          DebugConfig.debugPrint('✅ SUCCESS: Preview fetched');
          DebugConfig.debugPrint('   Title: ${preview.title}');
          DebugConfig.debugPrint('   Description: ${preview.description}');
          DebugConfig.debugPrint('   Image: ${preview.imageUrl ?? 'None'}');
          DebugConfig.debugPrint('   Site: ${preview.siteName ?? 'None'}');
        } else {
          DebugConfig.debugPrint('❌ FAILED: No preview returned');
        }
      } catch (e) {
        DebugConfig.debugPrint('💥 ERROR: $e');
      }

      // Add small delay between requests
      await Future.delayed(const Duration(milliseconds: 500));
    }

    DebugConfig.debugPrint('');
    DebugConfig.debugPrint('🏁 LinkPreviewTest: Completed testing all URLs');
  }
}
