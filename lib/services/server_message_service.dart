import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ServerMessageService {
  final FirebaseFirestore _firestore;
  final String _userId;
  final String _fcmToken;

  ServerMessageService({
    required String userId,
    required String fcmToken,
  }) : _userId = userId,
       _fcmToken = fcmToken,
       _firestore = FirebaseFirestore.instance;

  Future<void> processMessage({
    required String messageText,
    required String messageId,
    required int eventTypeCode,
  }) async {
    try {
      final userMessagesRef = _firestore.collection('messages').doc(_userId).collection('messages');

      // Generate server response based on message content
      final response = _generateServerResponse(messageText, eventTypeCode);
      
      if (response['text'] != null) {
        final serverMessageId = const Uuid().v4();
        final serverMessagePayload = {
          'messageBody': response['text'],
          'source': 'server',
          'timestamp': FieldValue.serverTimestamp(),
        };

        // Add options if they exist
        if (response['options'] != null && response['options'].isNotEmpty) {
          serverMessagePayload['answers'] = response['options'];
          serverMessagePayload['isPoll'] = 'y';
        }

        await userMessagesRef.doc(serverMessageId).set(serverMessagePayload);
        print('Server response stored with ID: $serverMessageId');
      }
    } catch (e) {
      print('Error processing message: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _generateServerResponse(String messageText, int eventTypeCode) {
    String responseText = "I don't understand. Can you please clarify?";
    List<String> options = [];
    final lowerMsg = messageText.toLowerCase();

    if (eventTypeCode == 1) { // Regular message
      if (lowerMsg.contains('hello') || lowerMsg.contains('hi') || lowerMsg.contains('hey')) {
        responseText = "Welcome to Quitxt from the UT Health Science Center! Congrats on your decision to quit smoking! See why we think you're awesome, Tap pic below https://youtu.be/ZWsR3G0mdJo";
      } else if (lowerMsg.contains('help') || lowerMsg.contains('how')) {
        responseText = "We'll help you quit smoking with fun messages. By continuing, you agree with our terms of service. If you want to leave the program type EXIT. For more info Tap pic below https://quitxt.org";
      } else if (lowerMsg.contains('reason') || lowerMsg.contains('why')) {
        responseText = "Reason #1 to quit smoking while you're young: You'll have more time to enjoy hoverboards and flying cars. https://quitxt.org/sites/quitxt/files/gifs/PreQ6_Hoverboard.gif";
      } else if (lowerMsg.contains('smoke') || lowerMsg.contains('cigarette')) {
        responseText = "How many cigarettes do you smoke per day?";
        options = ["None, I don't smoke", "1-5", "6-10", "11-20", "More than 20"];
      } else if (lowerMsg.contains('drink') || lowerMsg.contains('alcohol')) {
        responseText = "Drinking alcohol can trigger cravings for a cigarette and makes it harder for you to quit smoking. Tap pic below https://quitxt.org/binge-drinking";
      }
    } else if (eventTypeCode == 2) { // Quick reply
      responseText = "Thanks for your response: $messageText";
    }

    return {
      'text': responseText,
      'options': options,
    };
  }
} 