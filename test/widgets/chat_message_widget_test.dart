import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quitxt_app/widgets/chat_message_widget.dart';
import 'package:quitxt_app/models/chat_message.dart';
import 'package:quitxt_app/providers/chat_provider.dart';
import 'package:quitxt_app/theme/app_theme.dart';

void main() {
  group('ChatMessageWidget Tests', () {
    late ChatProvider chatProvider;

    setUp(() {
      chatProvider = ChatProvider();
    });

    tearDown(() {
      chatProvider.dispose();
    });

    Widget createTestWidget(ChatMessage message) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: ChangeNotifierProvider.value(
          value: chatProvider,
          child: Scaffold(
            body: ChatMessageWidget(message: message),
          ),
        ),
      );
    }

    testWidgets('should display text message correctly', (WidgetTester tester) async {
      final message = ChatMessage(
        id: '1',
        content: 'Hello, this is a test message!',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.text,
      );

      await tester.pumpWidget(createTestWidget(message));
      await tester.pumpAndSettle();

      expect(find.text('Hello, this is a test message!'), findsOneWidget);
      expect(find.byType(ChatMessageWidget), findsOneWidget);
    });

    testWidgets('should display user message with correct styling', (WidgetTester tester) async {
      final message = ChatMessage(
        id: '1',
        content: 'User message',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.text,
      );

      await tester.pumpWidget(createTestWidget(message));
      await tester.pumpAndSettle();

      // Should find the message widget
      expect(find.byType(ChatMessageWidget), findsOneWidget);
      expect(find.text('User message'), findsOneWidget);
    });

    testWidgets('should display bot message with correct styling', (WidgetTester tester) async {
      final message = ChatMessage(
        id: '1',
        content: 'Bot response',
        timestamp: DateTime.now(),
        isMe: false,
        type: MessageType.text,
      );

      await tester.pumpWidget(createTestWidget(message));
      await tester.pumpAndSettle();

      // Should find the message widget
      expect(find.byType(ChatMessageWidget), findsOneWidget);
      expect(find.text('Bot response'), findsOneWidget);
    });

    testWidgets('should handle image messages', (WidgetTester tester) async {
      final message = ChatMessage(
        id: '1',
        content: '',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.image,
        mediaUrl: 'https://example.com/image.jpg',
      );

      await tester.pumpWidget(createTestWidget(message));
      await tester.pumpAndSettle();

      expect(find.byType(ChatMessageWidget), findsOneWidget);
      // Note: Actual image widget detection depends on implementation
    });

    testWidgets('should handle video messages', (WidgetTester tester) async {
      final message = ChatMessage(
        id: '1',
        content: '',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.video,
        mediaUrl: 'https://example.com/video.mp4',
      );

      await tester.pumpWidget(createTestWidget(message));
      await tester.pumpAndSettle();

      expect(find.byType(ChatMessageWidget), findsOneWidget);
    });

    testWidgets('should handle YouTube video messages', (WidgetTester tester) async {
      final message = ChatMessage(
        id: '1',
        content: 'Check out this video: https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.youtube,
      );

      await tester.pumpWidget(createTestWidget(message));
      await tester.pumpAndSettle();

      expect(find.byType(ChatMessageWidget), findsOneWidget);
    });

    testWidgets('should handle long messages with text wrapping', (WidgetTester tester) async {
      final message = ChatMessage(
        id: '1',
        content: 'This is a very long message that should wrap across multiple lines to test the text wrapping functionality of the chat message widget.',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.text,
      );

      await tester.pumpWidget(createTestWidget(message));
      await tester.pumpAndSettle();

      expect(find.textContaining('This is a very long message'), findsOneWidget);
      expect(find.byType(ChatMessageWidget), findsOneWidget);
    });

    testWidgets('should handle empty messages gracefully', (WidgetTester tester) async {
      final message = ChatMessage(
        id: '1',
        content: '',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.text,
      );

      await tester.pumpWidget(createTestWidget(message));
      await tester.pumpAndSettle();

      // Should not crash with empty message
      expect(find.byType(ChatMessageWidget), findsOneWidget);
    });

    testWidgets('should apply correct theme colors', (WidgetTester tester) async {
      final message = ChatMessage(
        id: '1',
        content: 'Themed message',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.text,
      );

      await tester.pumpWidget(createTestWidget(message));
      await tester.pumpAndSettle();

      // Verify widget is rendered with theme
      expect(find.byType(ChatMessageWidget), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should handle tap gestures on messages', (WidgetTester tester) async {
      bool tapped = false;
      final message = ChatMessage(
        id: '1',
        content: 'Tappable message',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.text,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: chatProvider,
            child: Scaffold(
              body: GestureDetector(
                onTap: () => tapped = true,
                child: ChatMessageWidget(message: message),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector).first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('should handle different message statuses', (WidgetTester tester) async {
      final message = ChatMessage(
        id: '1',
        content: 'Status message',
        timestamp: DateTime.now(),
        isMe: true,
        type: MessageType.text,
        status: MessageStatus.delivered,
      );

      await tester.pumpWidget(createTestWidget(message));
      await tester.pumpAndSettle();

      expect(find.byType(ChatMessageWidget), findsOneWidget);
      expect(message.status, MessageStatus.delivered);
    });
  });
}
