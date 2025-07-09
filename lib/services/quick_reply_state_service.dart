import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QuickReplyStateService {
  static final QuickReplyStateService _instance = QuickReplyStateService._internal();
  factory QuickReplyStateService() => _instance;
  QuickReplyStateService._internal();

  // Track selected quick replies by message ID
  final Map<String, String> _selectedReplies = {};
  
  // Key for SharedPreferences storage
  static const String _storageKey = 'selected_quick_replies';

  /// Initialize the service by loading saved state
  Future<void> initialize() async {
    await _loadSavedState();
  }

  /// Check if a message has any quick reply selected
  bool hasSelectedReply(String messageId) {
    return _selectedReplies.containsKey(messageId);
  }

  /// Get the selected reply value for a message
  String? getSelectedReply(String messageId) {
    return _selectedReplies[messageId];
  }

  /// Select a quick reply for a message (this will disable all other options in the same set)
  Future<void> selectQuickReply(String messageId, String selectedValue) async {
    _selectedReplies[messageId] = selectedValue;
    await _saveState();
  }

  /// Check if a specific quick reply option is selected for a message
  bool isQuickReplySelected(String messageId, String replyValue) {
    return _selectedReplies[messageId] == replyValue;
  }

  /// Check if any quick reply is selected for a message (meaning all others should be disabled)
  bool isMessageSetDisabled(String messageId) {
    return _selectedReplies.containsKey(messageId);
  }

  /// Check if a specific option should be disabled (any other option selected in the same set)
  bool isOptionDisabled(String messageId, String replyValue) {
    final selectedValue = _selectedReplies[messageId];
    return selectedValue != null && selectedValue != replyValue;
  }

  /// Clear selection for a message (for testing purposes)
  Future<void> clearMessageSelection(String messageId) async {
    _selectedReplies.remove(messageId);
    await _saveState();
  }

  /// Clear all selections (for testing purposes)
  Future<void> clearAllSelections() async {
    _selectedReplies.clear();
    await _saveState();
  }

  /// Load saved state from SharedPreferences
  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_storageKey);
      
      if (savedData != null) {
        final Map<String, dynamic> decodedData = jsonDecode(savedData);
        _selectedReplies.clear();
        decodedData.forEach((key, value) {
          _selectedReplies[key] = value.toString();
        });
      }
    } catch (e) {
      // If there's an error loading, start with empty state
      _selectedReplies.clear();
    }
  }

  /// Save current state to SharedPreferences
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedData = jsonEncode(_selectedReplies);
      await prefs.setString(_storageKey, encodedData);
    } catch (e) {
      // Handle save error silently for now
    }
  }
} 