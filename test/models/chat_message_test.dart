import 'package:flutter_test/flutter_test.dart';
import 'package:quitxt_app/models/chat_message.dart';
import 'package:quitxt_app/models/quick_reply.dart';

void main() {
  group('ChatMessage Model Tests', () {
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
      expect(message.timestamp, isA<DateTime>());
    });

    test('should create ChatMessage with optional fields', () {
      final timestamp = DateTime.now();
      final message = ChatMessage(
        id: '123',
        content: 'Hello World',
        timestamp: timestamp,
        isMe: true,
        type: MessageType.image,
        mediaUrl: 'https://example.com/image.jpg',
        status: MessageStatus.delivered,
        reactions: [
          MessageReaction(
            emoji: '👍',
            userId: 'user1',
            timestamp: timestamp,
          ),
        ],
      );

      expect(message.type, MessageType.image);
      expect(message.mediaUrl, 'https://example.com/image.jpg');
      expect(message.status, MessageStatus.delivered);
      expect(message.reactions.length, 1);
      expect(message.reactions.first.emoji, '👍');
    });

    test('should create ChatMessage from JSON', () {
      final json = {
        'id': '123',
        'content': 'Hello World',
        'timestamp': '2024-01-01T12:00:00.000Z',
        'isMe': true,
        'type': 'MessageType.text',
        'status': 'MessageStatus.sent',
        'eventTypeCode': 1,
      };

      final message = ChatMessage.fromJson(json);

      expect(message.id, '123');
      expect(message.content, 'Hello World');
      expect(message.isMe, true);
      expect(message.type, MessageType.text);
      expect(message.status, MessageStatus.sent);
    });

    test('should convert ChatMessage to JSON', () {
      final timestamp = DateTime.parse('2024-01-01T12:00:00.000Z');
      final message = ChatMessage(
        id: '123',
        content: 'Hello World',
        timestamp: timestamp,
        isMe: true,
        type: MessageType.text,
        status: MessageStatus.sent,
      );

      final json = message.toJson();

      expect(json['id'], '123');
      expect(json['content'], 'Hello World');
      expect(json['timestamp'], '2024-01-01T12:00:00.000Z');
      expect(json['isMe'], true);
      expect(json['type'], 'MessageType.text');
      expect(json['status'], 'MessageStatus.sent');
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

      expect(updatedMessage.id, originalMessage.id);
      expect(updatedMessage.content, 'Updated content');
      expect(updatedMessage.status, MessageStatus.delivered);
      expect(updatedMessage.timestamp, originalMessage.timestamp);
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

      final videoMessage = ChatMessage(
        id: '3',
        content: '',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.video,
        mediaUrl: 'https://example.com/video.mp4',
      );

      expect(textMessage.type, MessageType.text);
      expect(imageMessage.type, MessageType.image);
      expect(videoMessage.type, MessageType.video);
    });

    test('should handle message status changes', () {
      final message = ChatMessage(
        id: '123',
        content: 'Test message',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.text,
        status: MessageStatus.sending,
      );

      expect(message.status, MessageStatus.sending);

      final sentMessage = message.copyWith(status: MessageStatus.sent);
      expect(sentMessage.status, MessageStatus.sent);

      final deliveredMessage = message.copyWith(status: MessageStatus.delivered);
      expect(deliveredMessage.status, MessageStatus.delivered);

      final readMessage = message.copyWith(status: MessageStatus.read);
      expect(readMessage.status, MessageStatus.read);
    });

    test('should validate message content', () {
      expect(() => ChatMessage(
        id: '',
        content: 'Hello',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.text,
      ), isNot(throwsException)); // Empty ID is allowed in the current model

      final message = ChatMessage(
        id: '123',
        content: 'Hello',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.text,
      );

      expect(message.content, 'Hello');
    });

    test('should handle reactions correctly', () {
      final timestamp = DateTime.now();
      final message = ChatMessage(
        id: '123',
        content: 'Test message',
        timestamp: timestamp,
        isMe: true,
        type: MessageType.text,
        reactions: [
          MessageReaction(emoji: '👍', userId: 'user1', timestamp: timestamp),
          MessageReaction(emoji: '❤️', userId: 'user2', timestamp: timestamp),
          MessageReaction(emoji: '😊', userId: 'user3', timestamp: timestamp),
        ],
      );

      expect(message.reactions.length, 3);
      expect(message.reactions[0].emoji, '👍');
      expect(message.reactions[1].emoji, '❤️');
      expect(message.reactions[2].emoji, '😊');

      final messageWithoutReactions = ChatMessage(
        id: '124',
        content: 'Test message',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.text,
      );

      expect(messageWithoutReactions.reactions.length, 0);
    });

    test('should handle quick replies', () {
      final message = ChatMessage(
        id: '123',
        content: 'Choose an option:',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.quickReply,
        suggestedReplies: [
          QuickReply(text: 'Option 1', value: 'opt1'),
          QuickReply(text: 'Option 2', value: 'opt2'),
        ],
      );

      expect(message.type, MessageType.quickReply);
      expect(message.suggestedReplies!.length, 2);
      expect(message.suggestedReplies![0].text, 'Option 1');
      expect(message.suggestedReplies![1].text, 'Option 2');
    });

    test('should create from Firestore data', () {
      final firestoreData = {
        'messageBody': 'Hello from Firestore!',
        'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
        'source': 'client',
        'serverMessageId': 'firestore-123',
      };

      final message = ChatMessage.fromFirestore(firestoreData, 'doc-id');

      expect(message.id, 'firestore-123');
      expect(message.content, 'Hello from Firestore!');
      expect(message.isMe, true); // source is 'client'
      expect(message.type, MessageType.text);
    });

    test('should handle Firestore poll messages', () {
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
      expect(message.isMe, false); // source is 'server'
      expect(message.type, MessageType.quickReply);
      expect(message.suggestedReplies!.length, 4);
      expect(message.suggestedReplies![0].text, 'Red');
    });

    test('should handle thread messages', () {
      final message = ChatMessage(
        id: '123',
        content: 'Thread reply',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.threadReply,
        parentMessageId: 'parent-123',
        threadMessageIds: ['child-1', 'child-2'],
      );

      expect(message.parentMessageId, 'parent-123');
      expect(message.threadMessageIds.length, 2);
      expect(message.type, MessageType.threadReply);
    });

    test('should handle voice messages', () {
      final message = ChatMessage(
        id: '123',
        content: '',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.voice,
        mediaUrl: 'https://example.com/voice.m4a',
        voiceDuration: 30000, // 30 seconds
        voiceWaveform: '0.1,0.5,0.8,0.3',
      );

      expect(message.type, MessageType.voice);
      expect(message.voiceDuration, 30000);
      expect(message.voiceWaveform, '0.1,0.5,0.8,0.3');
      expect(message.mediaUrl, 'https://example.com/voice.m4a');
    });

    test('should handle file messages', () {
      final message = ChatMessage(
        id: '123',
        content: 'Document.pdf',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.file,
        mediaUrl: 'https://example.com/document.pdf',
        fileName: 'Document.pdf',
        fileSize: 1024000, // 1MB
      );

      expect(message.type, MessageType.file);
      expect(message.fileName, 'Document.pdf');
      expect(message.fileSize, 1024000);
      expect(message.mediaUrl, 'https://example.com/document.pdf');
    });
  });
}
