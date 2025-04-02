import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quick_reply.dart';

class GeminiService {
  // This would typically be stored securely or obtained from environment
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  // Simulated response to avoid actual API calls during development
  Future<String> generateResponse(String prompt) async {
    // For demo purposes, we'll return mock responses
    print('GeminiService: Generating response for: $prompt');
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Return mock responses based on prompt content
    if (prompt.toLowerCase().contains('hello') || 
        prompt.toLowerCase().contains('hi')) {
      return "Hello! How can I assist you today?";
    } else if (prompt.toLowerCase().contains('joke')) {
      return "Why don't scientists trust atoms? Because they make up everything!";
    } else if (prompt.toLowerCase().contains('weather')) {
      return "I don't have access to real-time weather data, but I'd be happy to chat about something else!";
    } else if (prompt.toLowerCase().contains('name')) {
      return "I'm Gemini, a large language model from Google AI.";
    } else {
      return "That's an interesting question. I'm a language model designed to be helpful, harmless, and honest in my responses.";
    }
    
    // Actual API implementation would look like this:
    /*
    final url = '$_baseUrl?key=$_apiKey';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{'role': 'user', 'parts': [{'text': prompt}]}],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
      }),
    );
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Failed to generate response: ${response.body}');
    }
    */
  }
  
  // Get suggested quick replies based on the conversation context
  Future<List<QuickReply>> getSuggestedReplies(String lastMessage) async {
    // For demo purposes, return predefined quick replies
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