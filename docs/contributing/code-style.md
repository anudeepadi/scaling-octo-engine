# Code Style Guidelines

This document outlines the coding standards and style guidelines for the QuitTxT App project.

## Dart Style Guide

The QuitTxT App follows the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style) and [Flutter style guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo). Here are the key points:

### Formatting

- Use the standard Dart formatter:
  ```bash
  dart format .
  ```
- Line length should be a maximum of 80 characters
- Use 2 spaces for indentation, not tabs
- No trailing whitespace
- End files with a newline

### Naming Conventions

- **Classes, enums, typedefs, and extensions**: Use `PascalCase`
  ```dart
  class ChatMessage { ... }
  enum MessageType { ... }
  ```

- **Variables, constants, parameters, and function names**: Use `camelCase`
  ```dart
  final chatMessage = ChatMessage(...);
  void sendMessage(String content) { ... }
  ```

- **Private identifiers**: Start with underscore
  ```dart
  final _privateVariable = 'private';
  void _privateMethod() { ... }
  ```

- **Files and directories**: Use `snake_case`
  ```
  chat_message.dart
  quick_reply_widget.dart
  ```

### Imports

Organize imports in the following order, with a blank line between each group:

1. Dart/Flutter imports
2. Package imports
3. Local imports

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../services/bot_service.dart';
```

### Types

- Use static types whenever possible
- Avoid using `dynamic` unless absolutely necessary
- Use `final` for variables that don't change after initialization
- Use `const` for compile-time constants
- Use `var` only when the type is obvious from the initialization

```dart
// Good
final String message = 'Hello';
final chatMessage = ChatMessage(...);

// Avoid
var message = 'Hello';
dynamic result = someFunction();
```

### Comments

- Use `///` for documentation comments
- Document all public APIs
- Keep comments concise and focused on why, not what
- Update comments when code changes

```dart
/// A widget that displays a chat message.
///
/// This widget handles different message types and formats
/// the message accordingly.
class ChatMessageWidget extends StatelessWidget {
  // ...
}
```

## Flutter-Specific Guidelines

### Widget Structure

- Split complex widgets into smaller, reusable components
- Use named constructors or factory methods for widget variations
- Prefer composition over inheritance for widget reuse

### State Management

- Use Provider pattern for state management
- Follow the separation of concerns principle:
  - Models for data structures
  - Providers for state management
  - Services for business logic
  - Widgets for UI

### Platform-Specific Code

- Place platform-specific implementations in:
  - `lib/widgets/platform/` for UI components
  - `lib/services/platform/` for services

- Use platform checks to adapt behavior:
  ```dart
  if (Platform.isIOS) {
    // iOS-specific code
  } else {
    // Android or other platform code
  }
  ```

## Project Structure

Maintain the following project structure:

```
lib/
  ├── main.dart             # App entry point
  ├── models/               # Data models
  ├── providers/            # State management
  ├── screens/              # Full-page UI
  ├── services/             # Business logic
  │   └── platform/         # Platform-specific services
  ├── theme/                # App theming
  ├── utils/                # Utility functions
  └── widgets/              # Reusable UI components
      └── platform/         # Platform-specific widgets
```

## Error Handling

- Use try-catch blocks for potential exceptions
- Provide meaningful error messages
- Implement graceful fallbacks for error cases
- Log errors appropriately

```dart
try {
  final response = await apiService.fetchData();
  return response;
} catch (e) {
  debugPrint('Error fetching data: $e');
  return fallbackData;
}
```

## Testing

- Write testable code with clear separation of concerns
- Keep UI logic separate from business logic
- Use dependency injection to make components testable

## Code Reviews

During code reviews, we look for:

1. Adherence to the style guidelines
2. Proper error handling
3. Code readability and maintainability
4. Performance considerations
5. Proper test coverage
6. Documentation where necessary

## Linting

The project uses `flutter_lints` for static code analysis. Ensure your code passes the linter:

```bash
flutter analyze
```

Resolve any issues before submitting a pull request.

## Conclusion

Following these guidelines ensures a consistent codebase that is easy to read, maintain, and extend. When in doubt, prioritize readability and maintainability over cleverness or brevity.