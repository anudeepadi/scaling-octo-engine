import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';

class BotService {
  static const String _apiKey = 'AIzaSyCODVjQ7aIyDAcHXXW3XBiB9quiPwznocs';
  late final GenerativeModel? _model;
  late final ChatSession? _chat;
  bool _useAPIMode = true;  // Set to true to use Gemini API

  BotService() {
    try {
      if (_useAPIMode) {
        // Initialize with the gemini-1.5-flash model
        _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: _apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topP: 0.9,
            topK: 16,
            maxOutputTokens: 1024,
          ),
        );
        _chat = _model?.startChat();
        print('Initialized Gemini 1.5 Flash model successfully');
      } else {
        _model = null;
        _chat = null;
        print('Using fallback mode for bot responses');
      }
    } catch (e) {
      print('Error initializing Gemini model: $e');
      _model = null;
      _chat = null;
    }
  }

  Future<String> generateResponse(String text) async {
    // If not using API mode or model is null, use fallback responses
    if (!_useAPIMode || _model == null) {
      return _getFallbackResponse(text);
    }
    
    try {
      print('Sending request to Gemini 1.5 Flash: $text');
      
      // Create content parts with the user's text
      final content = [Content.text(text)];
      
      // Generate a response using the model
      final response = await _model!.generateContent(content);
      
      // Get the text from the response
      final responseText = response.text;
      
      // Check if the response is valid
      if (responseText == null || responseText.isEmpty) {
        print('Empty response from Gemini 1.5 Flash, using fallback');
        return _getFallbackResponse(text);
      }
      
      print('Received response from Gemini 1.5 Flash: ${responseText.substring(0, responseText.length > 50 ? 50 : responseText.length)}...');
      return responseText;
    } catch (e) {
      print('Error generating response from Gemini 1.5 Flash: $e');
      return _getFallbackResponse(text);
    }
  }
  
  String _getFallbackResponse(String text) {
    // Simple pattern matching for common messages
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('hello') || lowerText.contains('hi')) {
      return 'Hello! How can I help you today?';
    } else if (lowerText.contains('how are you')) {
      return 'I\'m doing well, thank you for asking! How can I assist you?';
    } else if (lowerText.contains('help')) {
      return 'I can help you with information, answer questions, or just chat! Try asking me about the weather, news, or sending a GIF.';
    } else if (lowerText.contains('joke')) {
      return 'Why don\'t scientists trust atoms? Because they make up everything! 😄';
    } else if (lowerText.contains('thank')) {
      return 'You\'re welcome! It\'s my pleasure to help. Let me know if you need anything else.';
    } else if (lowerText.contains('gif')) {
      return 'That\'s a cool GIF! You can send more GIFs by tapping the GIF button in the message bar.';
    } else if (lowerText.contains('weather')) {
      return 'The weather today is sunny with a high of 72°F (22°C). Would you like more detailed information?';
    } else if (lowerText.contains('name')) {
      return 'I\'m an RCS messaging assistant here to help you with your queries. What can I help you with today?';
    } else if (lowerText.contains('time') || lowerText.contains('date')) {
      final now = DateTime.now();
      return 'The current time is ${now.hour}:${now.minute.toString().padLeft(2, '0')} on ${now.day}/${now.month}/${now.year}.';
    } else if (lowerText.contains('news')) {
      return 'Today\'s top headlines: "New climate agreement reached at global summit", "Tech company announces breakthrough in AI", and "Scientists discover potential new treatment for cancer".';
    } else if (lowerText.contains('music') || lowerText.contains('song')) {
      return 'Some popular songs right now include "Flowers" by Miley Cyrus, "Kill Bill" by SZA, and "Anti-Hero" by Taylor Swift. What kind of music do you enjoy?';
    } else {
      return 'That\'s interesting! I\'d love to hear more about that. Feel free to ask me anything or share your thoughts.';
    }
  }

  static List<String> getSuggestedResponses() {
    return [
      'Tell me a joke',
      'What can you help me with?',
      'How are you?',
      'What\'s the weather like?',
      'Show me something funny',
      'Tell me an interesting fact',
    ];
  }

  static List<Map<String, String>> getQuickReplies(String lastMessage) {
    // Context-aware quick replies based on the last message content
    final lowerMessage = lastMessage.toLowerCase();
    
    if (lowerMessage.contains('weather')) {
      return [
        {'text': '☀️ Forecast', 'value': 'Show me the weather forecast'},
        {'text': '☔ Rain?', 'value': 'Will it rain today?'},
        {'text': '🌡️ Temperature', 'value': 'What will the temperature be tomorrow?'},
      ];
    }
    
    if (lowerMessage.contains('joke')) {
      return [
        {'text': '🤣 Another!', 'value': 'Tell me another joke'},
        {'text': '😄 Funny', 'value': 'That was funny! Tell me another one'},
        {'text': '🎭 Riddle', 'value': 'Tell me a riddle instead'},
      ];
    }
    
    if (lowerMessage.contains('song') || lowerMessage.contains('music')) {
      return [
        {'text': '🎵 Pop', 'value': 'Tell me about pop music'},
        {'text': '🎸 Rock', 'value': 'I like rock music'},
        {'text': '🎹 Classical', 'value': 'I enjoy classical music'},
      ];
    }
    
    if (lowerMessage.contains('news')) {
      return [
        {'text': '📰 More', 'value': 'Tell me more news'},
        {'text': '📱 Tech', 'value': 'Any technology news?'},
        {'text': '🌍 World', 'value': 'What\'s happening around the world?'},
      ];
    }

    // Default quick replies for other contexts
    return [
      {'text': '👍 Thanks', 'value': 'Thank you for the information!'},
      {'text': '❓ More', 'value': 'Can you tell me more about that?'},
      {'text': '💬 Help', 'value': 'What else can you help me with?'},
    ];
  }
}