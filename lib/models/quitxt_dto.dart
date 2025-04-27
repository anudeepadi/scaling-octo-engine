import 'dart:collection';

/// Represents a message sent from the mobile app to the server
class IncomingMobileMessageDto {
  final String userId;
  final String messageId;
  final String messageText;
  final int messageTime; // Epoch time in seconds
  final int eventTypeCode; // 1=text, 2=quick-reply
  final String fcmToken;

  IncomingMobileMessageDto({
    required this.userId,
    required this.messageId,
    required this.messageText,
    required this.messageTime,
    required this.eventTypeCode,
    required this.fcmToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'messageId': messageId,
      'messageText': messageText,
      'messageTime': messageTime,
      'eventTypeCode': eventTypeCode,
      'fcmToken': fcmToken,
    };
  }
}

/// Represents a message sent from the server to the mobile app
class QuitxtServerIncomingDto {
  final String recipientId;
  final String serverMessageId;
  final String messageBody;
  final int timestamp; // Epoch time in seconds
  final bool isPoll;
  final String? pollId;
  final String? fcmToken;
  final LinkedHashMap<String, String>? questionsAnswers; // Preserves order

  QuitxtServerIncomingDto({
    required this.recipientId,
    required this.serverMessageId,
    required this.messageBody,
    required this.timestamp,
    this.isPoll = false,
    this.pollId,
    this.fcmToken,
    this.questionsAnswers,
  });

  factory QuitxtServerIncomingDto.fromJson(Map<String, dynamic> json) {
    LinkedHashMap<String, String>? questionsAnswersMap;
    
    if (json.containsKey('questionsAnswers') && json['questionsAnswers'] != null) {
      questionsAnswersMap = LinkedHashMap<String, String>();
      final Map<String, dynamic> jsonAnswers = json['questionsAnswers'];
      
      jsonAnswers.forEach((key, value) {
        questionsAnswersMap![key] = value.toString();
      });
    }

    return QuitxtServerIncomingDto(
      recipientId: json['recipientId'],
      serverMessageId: json['serverMessageId'],
      messageBody: json['messageBody'],
      timestamp: json['timestamp'],
      isPoll: json['isPoll'] ?? false,
      pollId: json['pollId'],
      fcmToken: json['fcmToken'],
      questionsAnswers: questionsAnswersMap,
    );
  }
}