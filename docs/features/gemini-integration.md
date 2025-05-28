# Gemini AI Integration

This document details how Google's Gemini AI is integrated into the QuitTxT App to provide intelligent responses and features.

## Overview

The QuitTxT App integrates with Google's Gemini AI to provide an intelligent chatbot experience. This integration enhances the user experience with AI-powered responses, context-aware suggestions, and dynamic quick replies.

## Implementation

### Integration Components

The Gemini integration consists of several components:

1. **GeminiService**: Core service that handles communication with the Gemini API
2. **GeminiChatProvider**: State management for Gemini conversations
3. **GeminiChatScreen**: UI component for displaying Gemini chat interactions
4. **GeminiQuickReplyWidget**: Enhanced quick reply UI for Gemini-generated suggestions

### Key Files

- `lib/services/gemini_service.dart`: Service for Gemini API integration
- `lib/providers/gemini_chat_provider.dart`: State management for Gemini chats
- `lib/screens/gemini_chat_screen.dart`: UI for Gemini chat
- `lib/widgets/gemini_quick_reply_widget.dart`: UI for Gemini-generated quick replies

## Features

### AI-Powered Responses

The app can generate contextually relevant responses to user messages using Gemini's advanced language model:

```dart
Future<String> generateResponse(String userMessage, List<ChatMessage> chatHistory) async {
  try {
    final response = await _geminiModel.generateContent(
      [Content.text(formatChatHistoryForGemini(userMessage, chatHistory))],
    );
    return response.text;
  } catch (e) {
    return "I'm having trouble connecting. Please try again later.";
  }
}
```

### Enhanced Quick Replies

Gemini can automatically generate contextually relevant quick reply suggestions:

- **Dynamic Generation**: Suggestions are parsed from Gemini's responses
- **Context Awareness**: Reply options based on conversation context
- **Visual Distinctiveness**: Unique styling with gradients and animations

### Implementation Details

The integration uses the following approach:

1. **API Communication**:
   - Uses the `google_generative_ai` package to communicate with Gemini
   - Handles API authentication using keys stored in environment variables

2. **Context Management**:
   - Maintains conversation history for context-aware responses
   - Limits context length to optimize API performance

3. **Response Processing**:
   - Parses Gemini responses for potential quick reply options
   - Extracts questions, choices, and suggestions from the text
   - Applies formatting to maintain consistent UI presentation

## Configuration

### API Setup

To configure Gemini API integration:

1. Obtain a Gemini API key from the Google AI Studio
2. Add the key to your environment configuration:
   ```
   GEMINI_API_KEY=your-api-key-here
   ```

3. Configure model parameters in the GeminiService:
   ```dart
   final model = GenerativeModel(
     model: 'gemini-pro',
     apiKey: _apiKey,
     generationConfig: GenerationConfig(
       temperature: 0.7,
       topK: 40,
       topP: 0.95,
       maxOutputTokens: 1024,
     ),
   );
   ```

## Usage Examples

### Sending a Message to Gemini

```dart
// In a widget or provider
final geminiService = GeminiService();
final geminiResponse = await geminiService.generateResponse(
  userMessage,
  previousMessages,
);

// Add the response to the chat
chatProvider.addMessage(
  ChatMessage(
    id: 'gemini_${DateTime.now().millisecondsSinceEpoch}',
    content: geminiResponse,
    timestamp: DateTime.now(),
    isMe: false,
    type: MessageType.text,
  ),
);
```

### Displaying Gemini Quick Replies

```dart
// In a widget
return GeminiQuickReplyWidget(
  quickReplies: geminiQuickReplies,
  onQuickReplySelected: (reply) {
    // Handle quick reply selection
    chatProvider.sendMessage(reply.text);
  },
);
```

## Best Practices

1. **Context Management**: 
   - Keep conversation history concise to avoid exceeding token limits
   - Consider implementing summarization for long conversations

2. **Error Handling**:
   - Always include fallback responses for API failures
   - Implement retry logic for temporary connection issues

3. **Rate Limiting**:
   - Respect API rate limits
   - Implement client-side throttling when necessary

4. **Privacy Considerations**:
   - Be transparent about AI usage in the app
   - Do not send sensitive user information to the API

## Related Documentation

- [Gemini API Documentation](https://ai.google.dev/docs/gemini_api)
- [Chat Screen Documentation](../screens/gemini-chat-screen.md)
- [Quick Replies Documentation](quick-replies.md)