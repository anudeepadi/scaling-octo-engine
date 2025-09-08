import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../utils/debug_config.dart';

class LinkPreviewDebugWidget extends StatelessWidget {
  const LinkPreviewDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.withValues(alpha: 0.2),
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Link Preview Debug Panel',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _debugLinkPreviews(context),
                child: const Text('Debug Link Previews'),
              ),
              ElevatedButton(
                onPressed: () => _reprocessAllLinks(context),
                child: const Text('Reprocess All Links'),
              ),
              ElevatedButton(
                onPressed: () => _testQuitxtLink(context),
                child: const Text('Test Quitxt Link'),
              ),
              ElevatedButton(
                onPressed: () => _testGithubLink(context),
                child: const Text('Test GitHub Link'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _debugLinkPreviews(BuildContext context) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    DebugConfig.debugPrint('🔍 Starting comprehensive link preview debug...');
    await chatProvider.debugLinkPreviews();
    DebugConfig.debugPrint('🔍 Debug completed - check console for results');
  }

  Future<void> _reprocessAllLinks(BuildContext context) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    DebugConfig.debugPrint('🔄 Reprocessing all link previews...');
    await chatProvider.reprocessAllLinkPreviews();
    DebugConfig.debugPrint('🔄 Reprocessing completed');
  }

  Future<void> _testQuitxtLink(BuildContext context) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    DebugConfig.debugPrint('🧪 Adding test message with Quitxt link...');
    await chatProvider.addTestMessageWithLink('https://quitxt.org/reasons');
  }

  Future<void> _testGithubLink(BuildContext context) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    DebugConfig.debugPrint('🧪 Adding test message with GitHub link...');
    await chatProvider
        .addTestMessageWithLink('https://github.com/flutter/flutter');
  }
}

// Helper function to add debug buttons to any screen temporarily
Widget addDebugButtonsToScreen(Widget originalChild) {
  return Column(
    children: [
      const LinkPreviewDebugWidget(),
      Expanded(child: originalChild),
    ],
  );
}

// Helper function to debug link previews from anywhere in the app
Future<void> debugLinkPreviewsGlobally(BuildContext context) async {
  final chatProvider = Provider.of<ChatProvider>(context, listen: false);

  DebugConfig.debugPrint('');
  DebugConfig.debugPrint('🚀=================================');
  DebugConfig.debugPrint('🚀 GLOBAL LINK PREVIEW DEBUG');
  DebugConfig.debugPrint('🚀=================================');

  // 1. Check current message count
  DebugConfig.debugPrint(
      '📊 Current message count: ${chatProvider.messages.length}');

  // 2. Count messages with URLs
  final messagesWithUrls = chatProvider.messages
      .where((msg) => RegExp(r'https?://').hasMatch(msg.content))
      .toList();
  DebugConfig.debugPrint('📊 Messages with URLs: ${messagesWithUrls.length}');

  // 3. Count messages with previews
  final messagesWithPreviews =
      chatProvider.messages.where((msg) => msg.linkPreview != null).toList();
  DebugConfig.debugPrint(
      '📊 Messages with previews: ${messagesWithPreviews.length}');

  // 4. List some examples
  DebugConfig.debugPrint('');
  DebugConfig.debugPrint('📋 Sample messages with URLs:');
  for (int i = 0; i < messagesWithUrls.length && i < 5; i++) {
    final msg = messagesWithUrls[i];
    final urlMatch = RegExp(r'https?://[^\s]+').firstMatch(msg.content);
    final url = urlMatch?.group(0) ?? 'No URL found';
    DebugConfig.debugPrint(
        '  ${i + 1}. ${msg.content.substring(0, msg.content.length > 50 ? 50 : msg.content.length)}...');
    DebugConfig.debugPrint('     URL: $url');
    DebugConfig.debugPrint('     Has Preview: ${msg.linkPreview != null}');
    DebugConfig.debugPrint('     Type: ${msg.type}');
  }

  // 5. Run comprehensive debug
  await chatProvider.debugLinkPreviews();

  DebugConfig.debugPrint('🚀=================================');
  DebugConfig.debugPrint('🚀 END GLOBAL DEBUG');
  DebugConfig.debugPrint('🚀=================================');
}
