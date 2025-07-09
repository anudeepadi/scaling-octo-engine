import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quick_reply.dart';
import '../utils/debug_config.dart';

class GeminiService {
  // IMPORTANT: Replace with your new, valid API key securely!
  // DO NOT COMMIT THIS KEY TO VERSION CONTROL
  static const String _apiKey = 'AIzaSyCODVjQ7aIyDAcHXXW3XBiB9quiPwznocs'; 
  // static const String _baseUrl_OLD = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  static const String _modelName = 'gemini-1.5-flash'; // Use the confirmed working model
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent';
  
  // Actual API call implementation
  Future<String> generateResponse(String prompt) async {
    DebugConfig.debugPrint('[GeminiService] Generating response for: "$prompt"');

    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
       DebugConfig.debugPrint('[GeminiService] ERROR: API Key is placeholder!');
       return "ERROR: API Key not set in GeminiService."; // Return error if key missing
    }

    final url = Uri.parse('$_baseUrl?key=$_apiKey');
    final requestBody = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt.trim()}
          ]
        }
      ],
      // Optional: Add generationConfig if needed
      // "generationConfig": { ... } 
    });

    DebugConfig.debugPrint("[GeminiService] Calling API: $url");
    // DebugConfig.debugPrint("[GeminiService] Request Body: $requestBody"); // Optional: Log body if needed

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      DebugConfig.debugPrint("[GeminiService] API Response Status: ${response.statusCode}");
      // DebugConfig.debugPrint("[GeminiService] API Response Body: ${response.body}"); // Optional: Log full body if needed

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        final candidates = decodedResponse['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
           final content = candidates[0]['content'] as Map<String, dynamic>?;
           if (content != null) {
              final parts = content['parts'] as List<dynamic>?;
              if (parts != null && parts.isNotEmpty) {
                 final text = parts[0]['text'] as String?;
                 if (text != null) {
                    DebugConfig.debugPrint('[GeminiService] Extracted text: "${text.substring(0, (text.length > 50 ? 50 : text.length))}..."');
                    return text; // Success
                 } 
              }
           }
        }
        // Handle blocked response or missing data
        final promptFeedback = decodedResponse['promptFeedback'] as Map<String, dynamic>?;
         if (promptFeedback != null && promptFeedback['blockReason'] != null) {
            final reason = promptFeedback['blockReason'];
            DebugConfig.debugPrint('[GeminiService] Response blocked: $reason');
            return "Response blocked due to: $reason"; // Return info about blocking
         } else {
           DebugConfig.debugPrint('[GeminiService] Error: Could not extract valid candidate text from response.');
           throw Exception('Could not extract valid candidate text from API response.');
         }
      } else {
        DebugConfig.debugPrint('[GeminiService] API Error ${response.statusCode}: ${response.body}');
        throw Exception('API Error: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      DebugConfig.debugPrint('[GeminiService] Error during API call: $e');
      // Consider returning a user-friendly error message instead of rethrowing
      return "Error communicating with Gemini: $e"; 
      // throw Exception('Failed to generate response: $e'); // Or rethrow if caller handles it
    }
  }

  // Get suggested quick replies based on the conversation context
  // TODO: Implement actual API call for suggested replies if needed, or keep mock?
  Future<List<QuickReply>> getSuggestedReplies(String lastMessage) async {
    // For demo purposes, return predefined quick replies
    DebugConfig.debugPrint('[GeminiService] Generating mock suggested replies for: "$lastMessage"');
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (lastMessage.toLowerCase().contains('hello') || 
        lastMessage.toLowerCase().contains('hi')) {
      return [
        QuickReply(text: 'How are you?', value: 'How are you?'),
        QuickReply(text: 'What can you do?', value: 'What can you do?'),
        QuickReply(text: 'Tell me a joke', value: 'Tell me a joke'),
      ];
    } else if (lastMessage.toLowerCase().contains('joke')) {
      return [
        QuickReply(text: 'Another joke please', value: 'Tell me another joke'),
        QuickReply(text: 'That was funny!', value: 'That was funny!'),
        QuickReply(text: 'Tell me about yourself', value: 'Tell me about yourself'),
      ];
    } else {
      return [
        QuickReply(text: 'Tell me more', value: 'Tell me more'),
        QuickReply(text: 'Interesting!', value: 'That\'s interesting!'),
        QuickReply(text: 'Change topic', value: 'Let\'s talk about something else'),
      ];
    }
  }
} 