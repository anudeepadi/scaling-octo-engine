import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../models/link_preview.dart';
import '../utils/firebase_utils.dart';

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
      final messageId = 'msg_${timestamp}';

      final Map<String, dynamic> payload = {
        "userId": userId,
        "messageText": messageText,
        "messageTime": timestamp,
        "messageId": messageId,
        "eventTypeCode": eventTypeCode,
        "fcmToken": fcmToken ?? await FirebaseUtils.getFCMToken(),
      };

      debugPrint('Sending message to Dash server: $payload');

      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('Message sent successfully to Dash server');
        return true;
      } else {
        debugPrint('Failed to send message to Dash server: ${response.statusCode}, ${response.body}');
        return false;
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
      final Map<String, String>? questionsAnswers = data['questionsAnswers'];
      if (questionsAnswers != null && questionsAnswers.isNotEmpty) {
        suggestedReplies = questionsAnswers.entries
            .map((entry) => QuickReply(
                  text: entry.key,
                  value: entry.value,
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
    } else if (urlMatch != null) {
      type = MessageType.linkPreview;
      mediaUrl = urlMatch.group(0);
      linkPreview = LinkPreview(
        url: mediaUrl!,
        title: 'Link Preview',
        description: 'Loading preview...',
      );
    }
    
    return ChatMessage(
      id: messageId,
      content: messageBody,
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
