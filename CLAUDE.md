# CLAUDE.md - Flutter RCS Application Guide

## Commands
- **Run app**: `flutter run`
- **Clean project**: `./ios_clean.sh` (iOS issues) or `flutter clean`
- **Install dependencies**: `flutter pub get`
- **Analyze code**: `flutter analyze`
- **Run tests**: `flutter test`
- **Run single test**: `flutter test test/my_test.dart`
- **Format code**: `dart format lib/`

## Code Style Guidelines
- **Imports**: Group imports: 1) Dart, 2) Flutter, 3) External packages, 4) Project imports
- **Naming**: camelCase for variables/methods, PascalCase for classes, snake_case for files
- **Types**: Use strong typing, prefer final/const, include nullability (`?` or `required`)
- **Models**: Implement copyWith(), fromJson/toJson for data classes
- **Error handling**: Use try/catch blocks, prefer nullable returns over exceptions
- **Formatting**: 2-space indentation, 80-character line limit
- **State management**: Use Provider pattern with ChangeNotifier
- **Platform specifics**: Use platform/ directory for platform-specific implementations
- **Comments**: Focus on WHY over WHAT, document non-obvious code