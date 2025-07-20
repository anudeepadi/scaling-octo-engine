import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../utils/debug_config.dart';
import '../utils/platform_utils.dart';

class ServerMessageService {
  final FirebaseFirestore _firestore;
  final String _userId;
  final String _fcmToken;
  late String _serverUrl;

  ServerMessageService({
    required String userId,
    required String fcmToken,
  }) : _userId = userId,
       _fcmToken = fcmToken,
       _firestore = FirebaseFirestore.instance {
    // Apply platform-specific URL transformation
    _serverUrl = PlatformUtils.transformLocalHostUrl("http://localhost:8080/scheduler");
    DebugConfig.infoPrint('Using platform-specific server URL: $_serverUrl');
  }

  // Process a message both locally (Firebase) and remotely (Java server)
  Future<void> processMessage({
    required String messageText,
    required String messageId,
    required int eventTypeCode,
  }) async {
    try {
      // First store it in Firebase for local persistence
      final userMessagesRef = _firestore.collection('messages').doc(_userId).collection('chat');
      
      // Store the user message
      await userMessagesRef.doc(messageId).set({
        'messageBody': messageText,
        'source': 'client',
        'createdAt': FieldValue.serverTimestamp(),
        'isPoll': 'n',
      });
      
      // Then send to server for processing
      await _sendToJavaServer(messageText, messageId, eventTypeCode);
    } catch (e) {
      DebugConfig.debugPrint('Error processing message: $e');
      // If server fails, fall back to local mock response
      await _generateLocalResponse(messageText, eventTypeCode);
      rethrow;
    }
  }

  // Send message to Java server
  Future<void> _sendToJavaServer(String messageText, String messageId, int eventTypeCode) async {
    try {
      final endpoint = '$_serverUrl/webservice/messaging/process2/send';
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final payload = {
        'userId': _userId,
        'messageId': messageId,
        'messageText': messageText,
        'messageTime': timestamp,
        'eventTypeCode': eventTypeCode,
        'fcmToken': _fcmToken,
      };
      
      // Pretty print JSON for better readability in console
      final prettyRequestJson = const JsonEncoder.withIndent('  ').convert(payload);
      DebugConfig.debugPrint('📤 SERVER REQUEST JSON:');
      DebugConfig.debugPrint('$prettyRequestJson');
      
      DebugConfig.debugPrint('Sending message to server endpoint: $endpoint');
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));
      
      DebugConfig.debugPrint('Server response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 202) {
        DebugConfig.debugPrint('Message sent successfully to Java server');
        
        // If response has content, process it
        if (response.body.isNotEmpty) {
          try {
            final responseData = jsonDecode(response.body);
            
            // Pretty print response JSON
            final prettyResponseJson = const JsonEncoder.withIndent('  ').convert(responseData);
            DebugConfig.debugPrint('📥 SERVER RESPONSE JSON:');
            DebugConfig.debugPrint('$prettyResponseJson');
            
            if (responseData['messageBody'] != null) {
              final serverMessageId = const Uuid().v4();
              final serverMessagePayload = {
                'messageBody': responseData['messageBody'],
                'source': 'server',
                'createdAt': FieldValue.serverTimestamp(),
              };
              
              // Add options if they exist
              if (responseData['answers'] != null) {
                serverMessagePayload['answers'] = responseData['answers'];
                serverMessagePayload['isPoll'] = 'y';
              }
              
              // Store server response in Firebase
              await _firestore.collection('messages').doc(_userId).collection('chat')
                  .doc(serverMessageId).set(serverMessagePayload);
                  
              DebugConfig.debugPrint('Server response stored with ID: $serverMessageId');
            }
          } catch (e) {
            DebugConfig.debugPrint('Error processing server response: $e');
          }
        }
      } else {
        DebugConfig.debugPrint('Failed to send message to server. Status: ${response.statusCode}, Body: ${response.body}');
        // Fall back to local mock response
        await _generateLocalResponse(messageText, eventTypeCode);
      }
    } catch (e) {
      DebugConfig.debugPrint('Error sending message to Java server: $e');
      // Fall back to local mock response
      await _generateLocalResponse(messageText, eventTypeCode);
    }
  }

  // Generate and store local response when server unavailable
  Future<void> _generateLocalResponse(String messageText, int eventTypeCode) async {
    DebugConfig.debugPrint('Local fallback responses disabled - no local responses will be generated');
    DebugConfig.debugPrint('Message received but not processed: $messageText');
    return;
  }

  // Local fallback response generator
  // ignore: unused_element
  Map<String, dynamic> _generateServerResponse(String messageText, int eventTypeCode) {
    String responseText = "I don't understand the command: '$messageText'. Can you please clarify?"; // Default for commands
    List<String> options = [];
    final lowerMsg = messageText.toLowerCase().trim(); // Trim input

    if (eventTypeCode == 1) { // Regular message
      if (lowerMsg == 'hello' || lowerMsg == 'hi' || lowerMsg == 'hey') {
        responseText = "Welcome to Quitxt from the UT Health Science Center! Congrats on your decision to quit smoking! See why we think you're awesome, Tap pic below https://youtu.be/ZWsR3G0mdJo";
        options = ["Thanks!", "Tell me more", "What is Quitxt?"];
      } else if (lowerMsg == 'help' || lowerMsg == 'how') {
        responseText = "We'll help you quit smoking with fun messages. By continuing, you agree with our terms of service. If you want to leave the program type EXIT. For more info Tap pic below https://quitxt.org";
        options = ["Okay", "Terms of Service", "EXIT Program"];
      } else if (lowerMsg.contains('reason') || lowerMsg == 'why') {
          if (lowerMsg.contains('2') || lowerMsg.contains('second')) {
             responseText = "Reason #2 to quit smoking while you're young: Add a decade to your life and see the rise of fully automated smart homes; who needs to do chores when robots become a common commodity! https://quitxt.org/sites/quitxt/files/gifs/App1-Motiv2_automated_home.gif";
             options = ["Cool Robot!", "More reasons?", "Next Tip"];
          } else {
            responseText = "Reason #1 to quit smoking while you're young: You'll have more time to enjoy hoverboards and flying cars. https://quitxt.org/sites/quitxt/files/gifs/PreQ6_Hoverboard.gif";
            options = ["Sweet Hoverboard!", "Reason #2?", "Next Tip"];
          }
      } else if (lowerMsg.contains('smoke') || lowerMsg.contains('cigarette')) {
        responseText = "How many cigarettes do you smoke per day?";
        options = ["None, I don't smoke", "1-5", "6-10", "11-20", "More than 20"];
      } else if (lowerMsg.contains('drink') || lowerMsg.contains('alcohol')) {
        responseText = "Drinking alcohol can trigger cravings for a cigarette and makes it harder for you to quit smoking. Tap pic below https://quitxt.org/binge-drinking";
        options = ["Good to know", "Other triggers?", "Got it"];
      } else if (lowerMsg.contains('avengers') || lowerMsg.contains('protect') || lowerMsg == 'super') {
        responseText = "Like the Avengers protect the earth, you are protecting your lungs from respiratory diseases and cancer! Stay SUPER and quit smoking! https://quitxt.org/sites/quitxt/files/gifs/App1_Cue1_Avengers.gif";
        options = ["I am SUPER!", "Health benefits?", "Keep motivating!"];
      } else if (lowerMsg == 'test' || lowerMsg == 'ping') {
        responseText = "Pong! The local simulation is responding.";
        options = ["Ok", "Status?", "Help"];
      } else if (lowerMsg == 'exit' || lowerMsg == 'stop' || lowerMsg == 'quit') {
        responseText = "Are you sure you want to leave the Quitxt program?";
        options = ["Yes, EXIT", "No, stay", "Remind me later"];
      } else {
        // Default response for unmapped regular messages: Suggest Gemini
        responseText = "The protocol doesn't recognize '$messageText'. If you want, you can chat with Gemini, a state-of-the-art ChatGPT-style model from Google.";
        options = ["Chat with Gemini", "Help"]; // Use a distinct text for the button
      }
    } else if (eventTypeCode == 2) { // Quick reply
      // Handle specific quick replies
      if (lowerMsg == "thanks!" || lowerMsg == "okay" || lowerMsg == "got it") {
         responseText = "You're welcome! Glad I could help.";
         options = ["Next Tip", "Help", "Why quit?"];
      } else if (lowerMsg.contains("tell me more")) {
          responseText = "Quitxt uses text messages, like this one, to help you quit smoking with support and tips. You can find more info at https://quitxt.org";
          options = ["Okay", "How does it work?", "Sign me up (demo)"];
      } else if (lowerMsg.contains("what is quitxt")) {
          responseText = "Quitxt is a free smoking cessation program from UT Health Science Center using text messages. Learn more: https://quitxt.org";
          options = ["Got it", "Tell me more", "Help"];
      } else if (lowerMsg.contains("terms of service")) {
          responseText = "You can view the terms of service here: [Link to ToS]"; // Replace with actual link
          options = ["Okay", "Help"];
      } else if (lowerMsg.contains("exit program")) {
          responseText = "Are you sure you want to leave the Quitxt program?";
          options = ["Yes, EXIT", "No, stay"];
      } else if (lowerMsg.contains("reason #2?")) {
          responseText = "Reason #2 to quit smoking while you're young: Add a decade to your life and see the rise of fully automated smart homes; who needs to do chores when robots become a common commodity! https://quitxt.org/sites/quitxt/files/gifs/App1-Motiv2_automated_home.gif";
          options = ["Cool Robot!", "More reasons?", "Next Tip"];
      } else if (lowerMsg.contains("sweet hoverboard!") || lowerMsg.contains("cool robot!") || lowerMsg.contains("i am super!")) {
          responseText = "Awesome! Keep that motivation high!";
          options = ["Next Tip", "More reasons?", "Help"];
      } else if (lowerMsg.contains("health benefits")) {
          responseText = "Quitting smoking greatly reduces risks of cancer, heart disease, stroke, lung diseases, diabetes, and COPD. Your body starts healing almost immediately!";
          options = ["Wow!", "Next Tip", "More benefits?"];
      } else if (lowerMsg.contains("triggers")) {
          responseText = "Common triggers include stress, drinking coffee or alcohol, finishing a meal, or being around other smokers. Identifying yours is key!";
          options = ["Got it", "How to manage?", "Next Tip"];
      } else {
          // Default acknowledgment for unmapped quick replies
          responseText = "Thanks for the feedback: '$messageText'";
      }
    }

    return {
      'text': responseText,
      'options': options,
    };
  }
} 