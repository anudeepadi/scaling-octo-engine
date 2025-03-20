import 'package:flutter/material.dart';
import '../models/quick_reply.dart';

/// Utility class to parse Gemini responses and generate dynamic quick reply suggestions
class GeminiResponseParser {
  // Common keywords to identify potential follow-up questions
  static const List<String> _questionIndicators = [
    'would you like',
    'do you want',
    'are you interested',
    'shall we',
    'should i',
    'can i help',
    'need more',
    'want to know',
    'interested in',
    '?',
  ];

  // Keywords that indicate choices/options in the response
  static const List<String> _optionIndicators = [
    'option',
    'options',
    'choice',
    'choices',
    'alternative',
    'alternatives',
    ' or ',
    'example',
    'examples',
    'such as',
  ];

  // Emoji map for common topic areas to make quick replies more engaging
  static const Map<String, String> _topicToEmoji = {
    'weather': '☀️',
    'rain': '☔',
    'snow': '❄️',
    'temperature': '🌡️',
    'music': '🎵',
    'song': '🎵',
    'food': '🍽️',
    'recipe': '🍳',
    'restaurant': '🍽️',
    'movie': '🎬',
    'film': '🎬',
    'book': '📚',
    'news': '📰',
    'sport': '🏆',
    'game': '🎮',
    'travel': '✈️',
    'vacation': '🏖️',
    'health': '🏥',
    'fitness': '💪',
    'tech': '📱',
    'phone': '📱',
    'computer': '💻',
    'joke': '😄',
    'funny': '😂',
    'help': '❓',
    'question': '❓',
    'more': '➕',
    'info': 'ℹ️',
    'time': '⏰',
    'date': '📅',
    'money': '💰',
    'finance': '💵',
    'image': '🖼️',
    'photo': '📷',
    'video': '📹',
    'location': '📍',
    'direction': '🧭',
    'yes': '👍',
    'no': '👎',
    'thanks': '🙏',
    'price': '💲',
    'cost': '💲',
  };

  /// Extracts potential quick replies from a Gemini response
  /// Returns a list of QuickReply objects
  static List<QuickReply> extractQuickReplies(String response, {int maxReplies = 6}) {
    if (response.isEmpty) {
      return [];
    }

    final Set<QuickReply> potentialReplies = {};
    final List<String> sentences = _splitIntoSentences(response);

    // First pass: extract questions and choices from the response
    for (final sentence in sentences) {
      if (_containsQuestionIndicator(sentence)) {
        final replies = _extractRepliesFromQuestion(sentence);
        potentialReplies.addAll(replies);
      } else if (_containsOptionIndicator(sentence)) {
        final replies = _extractRepliesFromOptions(sentence);
        potentialReplies.addAll(replies);
      }
    }

    // Second pass: extract key topics if we don't have enough replies
    if (potentialReplies.length < 2) {
      final topics = _extractKeyTopics(response);
      for (final topic in topics) {
        final topicReply = _createTopicReply(topic);
        if (topicReply != null) {
          potentialReplies.add(topicReply);
        }
      }
    }

    // Add generic follow-up replies if we still don't have enough
    if (potentialReplies.length < 2) {
      potentialReplies.addAll(_getGenericFollowUps());
    }

    // Return a list of unique replies, limited to maxReplies
    final List<QuickReply> finalReplies = potentialReplies.toList();
    finalReplies.sort((a, b) => a.text.length.compareTo(b.text.length));
    
    return finalReplies.take(maxReplies).toList();
  }

  /// Splits a response text into sentences
  static List<String> _splitIntoSentences(String text) {
    // Basic sentence splitting logic
    final RegExp sentenceRegex = RegExp(r'[.!?]+');
    final List<String> sentences = text.split(sentenceRegex)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    
    return sentences;
  }

  /// Checks if a sentence contains a question indicator
  static bool _containsQuestionIndicator(String sentence) {
    final lowerSentence = sentence.toLowerCase();
    return _questionIndicators.any((indicator) => lowerSentence.contains(indicator));
  }

  /// Checks if a sentence contains an option indicator
  static bool _containsOptionIndicator(String sentence) {
    final lowerSentence = sentence.toLowerCase();
    return _optionIndicators.any((indicator) => lowerSentence.contains(indicator));
  }

  /// Extracts reply suggestions from a question
  static Set<QuickReply> _extractRepliesFromQuestion(String question) {
    final Set<QuickReply> replies = {};
    final lowerQuestion = question.toLowerCase();
    
    // Yes/No pattern
    if (lowerQuestion.contains('would you like') || 
        lowerQuestion.contains('do you want') ||
        lowerQuestion.contains('are you interested')) {
      replies.add(QuickReply(text: '👍 Yes', value: 'Yes'));
      replies.add(QuickReply(text: '👎 No', value: 'No'));
      
      // Try to extract the subject of the question
      final String subject = _extractSubject(question);
      if (subject.isNotEmpty) {
        replies.add(QuickReply(
          text: 'Tell me more about $subject',
          value: 'Tell me more about $subject',
          icon: Icons.info_outline,
        ));
      }
    }
    
    // More information pattern
    if (lowerQuestion.contains('more information') || 
        lowerQuestion.contains('more details') ||
        lowerQuestion.contains('learn more')) {
      replies.add(QuickReply(
        text: 'ℹ️ More information',
        value: 'I want more information',
      ));
    }
    
    return replies;
  }

  /// Extracts the subject from a question
  static String _extractSubject(String question) {
    final lowerQuestion = question.toLowerCase();
    
    for (final indicator in ['about', 'regarding', 'on', 'for']) {
      if (lowerQuestion.contains(indicator)) {
        final parts = lowerQuestion.split(indicator);
        if (parts.length > 1) {
          // Extract up to the next punctuation or end of string
          final subject = parts[1].split(RegExp(r'[,.!?;:]'))[0].trim();
          if (subject.isNotEmpty && subject.length < 20) {
            return subject;
          }
        }
      }
    }
    
    return '';
  }

  /// Extracts reply suggestions from options in a sentence
  static Set<QuickReply> _extractRepliesFromOptions(String sentence) {
    final Set<QuickReply> replies = {};
    
    // Check for "or" pattern: "Would you like X or Y?"
    if (sentence.toLowerCase().contains(' or ')) {
      final parts = sentence.split(RegExp(r'\s+or\s+', caseSensitive: false));
      if (parts.length >= 2) {
        // Extract the options
        String option1 = _cleanOption(parts[0]);
        String option2 = _cleanOption(parts[1]);
        
        if (option1.isNotEmpty && option1.length < 25) {
          final emoji = _findEmojiForText(option1);
          replies.add(QuickReply(
            text: emoji.isNotEmpty ? '$emoji $option1' : option1,
            value: option1,
          ));
        }
        
        if (option2.isNotEmpty && option2.length < 25) {
          final emoji = _findEmojiForText(option2);
          replies.add(QuickReply(
            text: emoji.isNotEmpty ? '$emoji $option2' : option2,
            value: option2,
          ));
        }
      }
    }
    
    // Check for list of options: "such as X, Y, and Z"
    final listPatterns = [
      RegExp(r'such as ([^,.!?;:]+)'),
      RegExp(r'like ([^,.!?;:]+)'),
      RegExp(r'examples? include ([^,.!?;:]+)'),
    ];
    
    for (final pattern in listPatterns) {
      final match = pattern.firstMatch(sentence);
      if (match != null && match.groupCount >= 1) {
        final String optionsText = match.group(1) ?? '';
        final List<String> options = optionsText.split(RegExp(r',\s+|\s+and\s+'));
        
        for (final option in options) {
          final cleanOption = _cleanOption(option);
          if (cleanOption.isNotEmpty && cleanOption.length < 25) {
            final emoji = _findEmojiForText(cleanOption);
            replies.add(QuickReply(
              text: emoji.isNotEmpty ? '$emoji $cleanOption' : cleanOption,
              value: cleanOption,
            ));
          }
        }
      }
    }
    
    return replies;
  }

  /// Cleans an extracted option
  static String _cleanOption(String option) {
    // Remove leading/trailing punctuation and whitespace
    var cleaned = option.trim();
    // Remove leading punctuation
    if (cleaned.isNotEmpty && ".,!?;:'\"[]".contains(cleaned[0])) {
      cleaned = cleaned.substring(1);
    }
    // Remove trailing punctuation
    if (cleaned.isNotEmpty && ".,!?;:'\"[]".contains(cleaned[cleaned.length - 1])) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    
    // Remove leading helping verbs or prepositions
    const List<String> leadingWords = [
      'would', 'do', 'does', 'are', 'is', 'the', 'a', 'an', 'some', 'any',
      'to', 'for', 'with', 'by', 'about', 'like'
    ];
    
    for (final word in leadingWords) {
      if (cleaned.toLowerCase().startsWith('$word ')) {
        cleaned = cleaned.substring(word.length + 1);
      }
    }
    
    return cleaned.trim();
  }

  /// Extracts key topics from the response
  static List<String> _extractKeyTopics(String response) {
    final List<String> topics = [];
    final lowerResponse = response.toLowerCase();
    
    for (final topic in _topicToEmoji.keys) {
      if (lowerResponse.contains(topic)) {
        topics.add(topic);
      }
    }
    
    return topics;
  }

  /// Creates a quick reply from a topic
  static QuickReply? _createTopicReply(String topic) {
    final emoji = _topicToEmoji[topic] ?? '';
    
    switch (topic) {
      case 'weather':
        return QuickReply(
          text: '$emoji Weather forecast', 
          value: 'What\'s the weather forecast?',
        );
      case 'rain':
        return QuickReply(
          text: '$emoji Rain chances', 
          value: 'Will it rain today?',
        );
      case 'snow':
        return QuickReply(
          text: '$emoji Snow forecast', 
          value: 'Will it snow today?',
        );
      case 'temperature':
        return QuickReply(
          text: '$emoji Temperature', 
          value: 'What\'s the temperature?',
        );
      case 'music':
      case 'song':
        return QuickReply(
          text: '$emoji Song recommendations', 
          value: 'Recommend some songs',
        );
      case 'food':
      case 'recipe':
        return QuickReply(
          text: '$emoji Food recipes', 
          value: 'Food recipe suggestions',
        );
      case 'restaurant':
        return QuickReply(
          text: '$emoji Restaurant suggestions', 
          value: 'Suggest some restaurants',
        );
      case 'movie':
      case 'film':
        return QuickReply(
          text: '$emoji Movie recommendations', 
          value: 'Recommend a movie',
        );
      case 'book':
        return QuickReply(
          text: '$emoji Book recommendations', 
          value: 'Recommend a book',
        );
      case 'news':
        return QuickReply(
          text: '$emoji Latest news', 
          value: 'Tell me the latest news',
        );
      case 'sport':
        return QuickReply(
          text: '$emoji Sports updates', 
          value: 'Sports updates',
        );
      case 'game':
        return QuickReply(
          text: '$emoji Game recommendations', 
          value: 'Recommend a game',
        );
      case 'travel':
      case 'vacation':
        return QuickReply(
          text: '$emoji Travel ideas', 
          value: 'Travel destination ideas',
        );
      case 'health':
      case 'fitness':
        return QuickReply(
          text: '$emoji Health tips', 
          value: 'Give me some health tips',
        );
      case 'tech':
      case 'phone':
      case 'computer':
        return QuickReply(
          text: '$emoji Tech news', 
          value: 'Latest technology news',
        );
      case 'joke':
      case 'funny':
        return QuickReply(
          text: '$emoji Tell a joke', 
          value: 'Tell me a joke',
        );
      case 'help':
      case 'question':
        return QuickReply(
          text: '$emoji Help', 
          value: 'I need help',
        );
      default:
        if (emoji.isNotEmpty) {
          return QuickReply(
            text: '$emoji ${topic.substring(0, 1).toUpperCase()}${topic.substring(1)}',
            value: 'Tell me about $topic',
          );
        }
        return null;
    }
  }

  /// Find the appropriate emoji for a text
  static String _findEmojiForText(String text) {
    final lowerText = text.toLowerCase();
    
    for (final entry in _topicToEmoji.entries) {
      if (lowerText.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return '';
  }

  /// Get generic follow-up replies for when specific ones can't be generated
  static List<QuickReply> _getGenericFollowUps() {
    return [
      QuickReply(
        text: '👍 Thanks',
        value: 'Thank you for the information',
      ),
      QuickReply(
        text: '🔍 Examples',
        value: 'Can you give me some examples?',
      ),
      QuickReply(
        text: '❓ Tell me more',
        value: 'Can you tell me more about that?',
      ),
      QuickReply(
        text: '💡 Other options',
        value: 'What other options are there?',
      ),
      QuickReply(
        text: '🆕 Start a new topic',
        value: 'Let\'s talk about something else',
      ),
    ];
  }
}