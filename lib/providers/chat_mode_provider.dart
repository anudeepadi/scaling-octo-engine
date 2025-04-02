import 'package:flutter/foundation.dart';

enum ChatMode {
  dash,
  gemini
}

class ChatModeProvider extends ChangeNotifier {
  ChatMode _currentMode = ChatMode.dash;
  
  ChatMode get currentMode => _currentMode;
  
  bool get isDashMode => _currentMode == ChatMode.dash;
  bool get isGeminiMode => _currentMode == ChatMode.gemini;
  
  void setMode(ChatMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      notifyListeners();
    }
  }
  
  void toggleMode() {
    _currentMode = _currentMode == ChatMode.dash ? ChatMode.gemini : ChatMode.dash;
    notifyListeners();
  }
} 