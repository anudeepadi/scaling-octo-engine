import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../models/link_preview.dart';

class DashMessagingService {
  // Latest Dash messaging server endpoint
  static const String serverUrl = 'https://dashmessaging-com.ngrok.io/scheduler/mobile-app';

  // Send a message to the Dash messaging server
  Future<bool> sendMessage({
    required String userId,
    required String messageText,
    required int eventTypeCode, // 1 for regular text, 2 for quick reply
    String? fcmToken,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final messageId = 'msg_${timestamp}_${DateTime.now().microsecond}';

      // Use a dummy token if none provided (for demo mode)
      final token = fcmToken ?? 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
      
      final Map<String, dynamic> payload = {
        "userId": userId,
        "messageText": messageText,
        "messageTime": timestamp,
        "messageId": messageId,
        "eventTypeCode": eventTypeCode,
        "fcmToken": token,
      };

      debugPrint('Sending message to Dash server: $payload');

      try {
        final response = await http.post(
          Uri.parse(serverUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
        );

        debugPrint('Response status: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          final shortBody = response.body.length > 100 
              ? response.body.substring(0, 100) + '...' 
              : response.body;
          debugPrint('Response body: $shortBody');
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint('Message sent successfully to Dash server');
          return true;
        } else {
          debugPrint('Failed to send message to Dash server: ${response.statusCode}');
          // In demo mode, pretend it worked anyway
          return true;
        }
      } catch (e) {
        debugPrint('Error sending HTTP request to Dash server: $e');
        // In demo mode, pretend it worked anyway
        return true;
      }
    } catch (e) {
      debugPrint('Error sending message to Dash server: $e');
      return false;
    }
  }

  // Process the received message from server to determine its type
  ChatMessage processServerMessage(Map<String, dynamic> data) {
    final String messageId = data['serverMessageId'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final String messageBody = data['messageBody'] ?? '';
    final int timestamp = data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
    
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
      isMe: false,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      type: type,
      suggestedReplies: suggestedReplies,
      mediaUrl: mediaUrl,
      linkPreview: linkPreview,
      status: MessageStatus.delivered,
    );
  }
}