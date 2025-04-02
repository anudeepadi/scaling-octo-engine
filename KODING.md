## RCS Application Koding Guidelines

This document outlines coding conventions and useful commands for the RCS Application codebase.

**Build, Lint, and Test Commands:**

*   **Run the app:** `flutter run`
*   **Install dependencies:** `flutter pub get`
*   **Analyze code (lint):** `flutter analyze`
*   **Run tests:** `flutter test`
*   **Run a specific test file:** `flutter test test/widget_test.dart` (replace with desired test file)

**Code Style and Conventions:**

*   **Formatting:** Follow standard Dart formatting (`dart format .`).
*   **Naming:** Use `camelCase` for variables and functions, `PascalCase` for classes and types.
*   **Imports:** Organize imports alphabetically. Use relative paths for imports within the `lib` directory. Avoid unused imports.
*   **Types:** Use static types whenever possible. Avoid `dynamic` unless necessary.
*   **Error Handling:** Use `try-catch` blocks for potential exceptions, especially for network requests and file operations. Log errors appropriately. Print statements are acceptable for debugging during development but should be removed or replaced with proper logging before merging.
*   **State Management:** Primarily uses the `provider` package. Ensure providers are scoped correctly.
*   **UI:** Adhere to platform-specific conventions (Material Design for Android, Cupertino for iOS) where applicable, using `Platform.isIOS` checks.
*   **Firebase:** Ensure Firebase services are initialized correctly and handle potential initialization errors gracefully.
*   **Dependencies:** Keep dependencies up-to-date. Run `flutter pub outdated` to check for outdated packages.

**Codebase Structure:**

*   `lib/`: Contains the main Dart application code.
    *   `main.dart`: Entry point of the application.
    *   `models/`: Data models.
    *   `providers/`: State management providers (`ChangeNotifier`).
    *   `screens/`: UI screens/pages.
    *   `services/`: Business logic, API interactions, and utility services.
    *   `theme/`: Application themes (light/dark, platform-specific).
    *   `utils/`: Utility functions and helpers.
    *   `widgets/`: Reusable UI components.
*   `test/`: Contains unit and widget tests.
*   `assets/`: Static assets like images and icons.
*   `ios/` & `android/`: Platform-specific code and configuration.
