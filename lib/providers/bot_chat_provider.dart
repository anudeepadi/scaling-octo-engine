import 'package:flutter/material.dart';
import '../models/quick_reply.dart';
import '../utils/debug_config.dart';

class BotChatProvider extends ChangeNotifier {
  List<QuickReply> getSuggestedReplies() {
    return [
      QuickReply(
        text: 'Help',
        value: '/help',
        icon: Icons.help_outline,
      ),
      QuickReply(
        text: 'Settings',
        value: '/settings',
        icon: Icons.settings,
      ),
      QuickReply(
        text: 'About',
        value: '/about',
        icon: Icons.info_outline,
      ),
    ];
  }

  void handleQuickReply(String value) {
    // Handle quick reply selection
    DebugConfig.debugPrint('Quick reply selected: $value');
    notifyListeners();
  }
}