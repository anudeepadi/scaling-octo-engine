import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../models/link_preview.dart';

class DashMessagingService {
  // Latest Dash messaging server endpoint
  static const String _baseUrl = 'https://dashmessaging-com.ngrok.io/scheduler/mobile-app';
  static const String _messagesEndpoint = '$_baseUrl/messages'; // Add messages endpoint

  // Send a message to the Dash messaging server
  Future<bool> sendMessage({
    required String userId,
    required String messageText,
    String? fcmToken,
    int eventTypeCode = 1,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'messageText': messageText,
          'messageTime': timestamp,
          'messageId': messageId,
          'eventTypeCode': eventTypeCode,
          'fcmToken': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        print('Message sent successfully to Dash server.');
        return true;
      } else {
        print('Failed to send message. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Get messages from the server
  Future<List<ChatMessage>> getMessages({String? userId}) async {
    try {
      final queryParams = userId != null ? {'userId': userId} : null;
      final uri = Uri.parse(_messagesEndpoint).replace(queryParameters: queryParams);
      
      print('Fetching messages from: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Received ${data.length} messages from server');
        
        return data.map((messageData) {
          if (messageData is Map<String, dynamic>) {
            return processServerMessage(messageData);
          } else {
            print('Invalid message format: $messageData');
            return null;
          }
        }).whereType<ChatMessage>().toList();
      } else {
        print('Failed to fetch messages. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  // Process the received message from server to determine its type
  ChatMessage processServerMessage(Map<String, dynamic> data) {
    final String messageId = data['serverMessageId'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final String messageBody = data['messageBody'] ?? '';
    final int timestamp = data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
    final bool isUserMessage = data['isUserMessage'] ?? false;
    
    // Extract quick replies if this is a poll
    List<QuickReply>? suggestedReplies;
    if (data['isPoll'] == true || data['isPoll'] == 'y') {
      if (data['questionsAnswers'] != null) {
        Map<String, String> questionsAnswers;
        
        // Handle different formats of questionsAnswers
        if (data['questionsAnswers'] is Map) {
          questionsAnswers = Map<String, String>.from(data['questionsAnswers']);
        } else if (data['questionsAnswers'] is List) {
          // Convert list to map with same values for key and value
          final List<dynamic> answers = data['questionsAnswers'];
          questionsAnswers = {
            for (var answer in answers) answer.toString(): answer.toString()
          };
        } else {
          questionsAnswers = {};
        }
        
        if (questionsAnswers.isNotEmpty) {
          suggestedReplies = questionsAnswers.entries
              .map((entry) => QuickReply(
                    text: entry.key,
                    value: entry.value,
                  ))
              .toList();
        }
      }
      
      // If no questionsAnswers but there are answers as a list
      if (suggestedReplies == null && data['answers'] != null && data['answers'] is List) {
        final List<dynamic> answers = data['answers'];
        suggestedReplies = answers
            .map((answer) => QuickReply(
                  text: answer.toString(),
                  value: answer.toString(),
                ))
            .toList();
      }
    }

    // Determine message type
    MessageType type = MessageType.text;
    String? mediaUrl;
    
    // Check for YouTube URLs
    final youtubeRegex = RegExp(r'(https?:\/\/)?(www\.)?(youtube\.com|youtu\.?be)\/[^\s]+');
    final youtubeMatch = youtubeRegex.firstMatch(messageBody);
    
    // Check for GIF URLs
    final gifRegex = RegExp(r'https?:\/\/[^\s]+\.gif');
    final gifMatch = gifRegex.firstMatch(messageBody);
    
    // Check for image URLs
    final imageRegex = RegExp(r'https?:\/\/[^\s]+\.(jpg|jpeg|png|webp)');
    final imageMatch = imageRegex.firstMatch(messageBody);
    
    // Check for other URLs
    final urlRegex = RegExp(r'https?:\/\/[^\s]+');
    final urlMatch = urlRegex.firstMatch(messageBody);

    LinkPreview? linkPreview;
    
    if (youtubeMatch != null) {
      type = MessageType.youtube;
      mediaUrl = youtubeMatch.group(0);
    } else if (gifMatch != null) {
      type = MessageType.gif;
      mediaUrl = gifMatch.group(0);
    } else if (imageMatch != null) {
      type = MessageType.image;
      mediaUrl = imageMatch.group(0);
    } else if (urlMatch != null) {
      type = MessageType.linkPreview;
      mediaUrl = urlMatch.group(0);
      linkPreview = LinkPreview(
        url: mediaUrl!,
        title: 'Link Preview',
        description: 'Loading preview...',
      );
    }
    
    // Create a clean text content by removing the media URL if present
    String cleanContent = messageBody;
    if (mediaUrl != null) {
      cleanContent = messageBody.replaceAll(mediaUrl, '').trim();
    }
    
    return ChatMessage(
      id: messageId,
      content: cleanContent.isEmpty ? mediaUrl ?? '' : cleanContent,
      isMe: isUserMessage,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      type: type,
      suggestedReplies: suggestedReplies,
      mediaUrl: mediaUrl,
      linkPreview: linkPreview,
      status: MessageStatus.delivered,
    );
  }
}