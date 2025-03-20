# RCS Application

A Flutter-based RCS (Rich Communication Services) messaging application with advanced AI features.

## Features

- Modern RCS messaging interface
- Support for rich media (images, GIFs, videos)
- Link previews
- Quick replies
- Gemini AI integration
- Thread replies
- Voice messages
- File sharing
- YouTube previews

## Enhanced Gemini Quick Replies

This feature provides an improved UI for AI-generated quick reply suggestions:

- **Visual Distinctiveness**: Gemini quick replies have a unique visual style with gradients and animations.
- **Dynamic Generation**: Suggestions are intelligently parsed from Gemini's responses.
- **Context Awareness**: Relevant quick reply buttons based on conversation context.
- **Responsive UI**: Properly handles various screen sizes and orientations.

### Implementation Details

The feature analyzes Gemini responses to extract potential quick reply suggestions through:
- Identifying questions within responses
- Extracting choices and options from the text
- Recognizing key topics in the conversation
- Providing appropriate emoji suggestions

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure the Gemini API key in the `bot_service.dart` file
4. Run the app with `flutter run`

## Requirements

- Flutter 3.0 or higher
- Dart 2.17 or higher
- A Gemini API key

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.