# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands
- Install dependencies: `flutter pub get`
- Run the app: `flutter run`
- Format code: `flutter format .` or `dart format .`
- Lint code: `flutter analyze`
- Run all tests: `flutter test`
- Run specific test: `flutter test test/widget_test.dart`

## Code Style Guidelines
- **Formatting**: Follow standard Dart formatting
- **Naming**: Use `camelCase` for variables/methods, `PascalCase` for classes/types
- **Imports**: Organize alphabetically, separate Flutter/package/project imports
- **Types**: Use static types whenever possible, avoid `dynamic`
- **Parameters**: Prefer named parameters with `required` for clarity
- **Error Handling**: Use try-catch with graceful fallbacks, especially for network operations
- **State Management**: Use Provider pattern with clear UI/logic separation
- **Platform Code**: Create platform-specific implementations in `lib/widgets/platform/`
- **File Structure**: Keep code organized in models, providers, screens, services, utils, widgets
- **Environment**: Use environment-specific configurations via env_switcher.dart

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md
