import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quitxt_app/models/chat_message.dart';
import 'package:quitxt_app/models/quick_reply.dart';
import 'package:quitxt_app/services/emoji_converter_service.dart';
import 'package:quitxt_app/theme/app_theme.dart';

void main() {
  group('Basic Functionality Tests', () {
    group('ChatMessage Model', () {
      test('should create ChatMessage with required fields', () {
        final message = ChatMessage(
          id: '123',
          content: 'Hello World',
          timestamp: DateTime.now(),
          isMe: true,
          type: MessageType.text,
        );

        expect(message.id, '123');
        expect(message.content, 'Hello World');
        expect(message.isMe, true);
        expect(message.type, MessageType.text);
      });

      test('should create copy with updated fields', () {
        final originalMessage = ChatMessage(
          id: '123',
          content: 'Original content',
          timestamp: DateTime.now(),
          isMe: true,
          type: MessageType.text,
          status: MessageStatus.sent,
        );

        final updatedMessage = originalMessage.copyWith(
          content: 'Updated content',
          status: MessageStatus.delivered,
        );

        expect(updatedMessage.content, 'Updated content');
        expect(updatedMessage.status, MessageStatus.delivered);
        expect(updatedMessage.id, originalMessage.id);
      });

      test('should handle different message types', () {
        final textMessage = ChatMessage(
          id: '1',
          content: 'Text message',
          timestamp: DateTime.now(),
          isMe: true,
          type: MessageType.text,
        );

        final imageMessage = ChatMessage(
          id: '2',
          content: '',
          timestamp: DateTime.now(),
          isMe: true,
          type: MessageType.image,
          mediaUrl: 'https://example.com/image.jpg',
        );

        expect(textMessage.type, MessageType.text);
        expect(imageMessage.type, MessageType.image);
        expect(imageMessage.mediaUrl, 'https://example.com/image.jpg');
      });
    });

    group('QuickReply Model', () {
      test('should create QuickReply with text and value', () {
        final quickReply = QuickReply(text: 'Yes', value: 'yes');

        expect(quickReply.text, 'Yes');
        expect(quickReply.value, 'yes');
      });

      test('should handle QuickReply serialization', () {
        final quickReply = QuickReply(text: 'Option 1', value: 'opt1');
        final json = quickReply.toJson();
        final fromJson = QuickReply.fromJson(json);

        expect(fromJson.text, quickReply.text);
        expect(fromJson.value, quickReply.value);
      });
    });

    group('EmojiConverterService', () {
      test('should convert text emoticons to emojis', () {
        final result1 = EmojiConverterService.convertTextToEmoji(':)');
        final result2 = EmojiConverterService.convertTextToEmoji(':(');

        expect(result1, contains('😊'));
        expect(result2, contains('😢'));
      });

      test('should handle empty input', () {
        expect(EmojiConverterService.convertTextToEmoji(''), '');
      });

      test('should not modify regular text', () {
        const input = 'Hello world!';
        final result = EmojiConverterService.convertTextToEmoji(input);
        expect(result, input);
      });
    });

    group('App Theme', () {
      test('should provide light theme', () {
        final theme = AppTheme.lightTheme;

        expect(theme, isNotNull);
        expect(theme.brightness, Brightness.light);
      });

      test('should have consistent color palette', () {
        expect(AppTheme.primaryBlue, isA<Color>());
        expect(AppTheme.wellnessGreen, isA<Color>());
        expect(AppTheme.textPrimary, isA<Color>());
        expect(AppTheme.backgroundPrimary, isA<Color>());
      });

      test('should provide gradient colors', () {
        expect(AppTheme.primaryGradient, isNotEmpty);
        expect(AppTheme.wellnessGradient, isNotEmpty);
        expect(AppTheme.primaryGradient.length, 2);
        expect(AppTheme.wellnessGradient.length, 2);
      });
    });

    group('Message Enums', () {
      test('should have all message types', () {
        expect(MessageType.values, contains(MessageType.text));
        expect(MessageType.values, contains(MessageType.image));
        expect(MessageType.values, contains(MessageType.video));
        expect(MessageType.values, contains(MessageType.youtube));
        expect(MessageType.values, contains(MessageType.quickReply));
      });

      test('should have all message statuses', () {
        expect(MessageStatus.values, contains(MessageStatus.sending));
        expect(MessageStatus.values, contains(MessageStatus.sent));
        expect(MessageStatus.values, contains(MessageStatus.delivered));
        expect(MessageStatus.values, contains(MessageStatus.read));
        expect(MessageStatus.values, contains(MessageStatus.error));
      });
    });

    group('Message Reactions', () {
      test('should create MessageReaction correctly', () {
        final timestamp = DateTime.now();
        final reaction = MessageReaction(
          emoji: '👍',
          userId: 'user123',
          timestamp: timestamp,
        );

        expect(reaction.emoji, '👍');
        expect(reaction.userId, 'user123');
        expect(reaction.timestamp, timestamp);
      });
    });

    group('Firestore Integration', () {
      test('should parse poll messages from Firestore', () {
        final firestoreData = {
          'messageBody': 'What is your favorite color?',
          'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
          'source': 'server',
          'serverMessageId': 'poll-123',
          'isPoll': 'yes',
          'answers': 'Red,Blue,Green,Yellow',
        };

        final message = ChatMessage.fromFirestore(firestoreData, 'doc-id');

        expect(message.id, 'poll-123');
        expect(message.content, 'What is your favorite color?');
        expect(message.isMe, false);
        expect(message.type, MessageType.quickReply);
        expect(message.suggestedReplies!.length, 4);
        expect(message.suggestedReplies![0].text, 'Red');
      });

      test('should handle regular messages from Firestore', () {
        final firestoreData = {
          'messageBody': 'Hello from Firestore!',
          'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
          'source': 'client',
          'serverMessageId': 'msg-456',
        };

        final message = ChatMessage.fromFirestore(firestoreData, 'doc-id');

        expect(message.id, 'msg-456');
        expect(message.content, 'Hello from Firestore!');
        expect(message.isMe, true);
        expect(message.type, MessageType.text);
      });
    });

    group('Utility Functions', () {
      test('isMessagePoll should detect poll values correctly', () {
        expect(isMessagePoll(true), true);
        expect(isMessagePoll('yes'), true);
        expect(isMessagePoll('Y'), true);
        expect(isMessagePoll('true'), true);
        expect(isMessagePoll(1), true);
        expect(isMessagePoll(false), false);
        expect(isMessagePoll('no'), false);
        expect(isMessagePoll(0), false);
        expect(isMessagePoll(null), false);
      });
    });
  });
}
