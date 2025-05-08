# QuitTxT_App

A Flutter-based mobile application for smoking cessation support with advanced AI features.

## Features

- Modern RCS messaging interface
- Support for rich media (images, GIFs, videos)
- Link previews
- Quick replies (User-generated and Keyword-based)
- Gemini AI integration
- Thread replies
- Voice messages
- File sharing
- YouTube previews

## Branching Strategy

This project uses the following branching strategy:

-   **`development`**: Main branch for active development. New features and fixes are merged here first.
-   **`staging`**: Represents the code deployed to a staging/testing environment. Updated periodically from `development`.
-   **`production`**: Represents the stable code deployed to production. Updated periodically from `staging` after testing.
-   **Feature/Fix Branches**: Temporary branches (like `fix/build-errors`) created from `development` for specific tasks and merged back into `development` via Pull Requests.

## Deployment Process

For detailed information on the deployment process, please refer to the [DEPLOYMENT.md](DEPLOYMENT.md) guide.

### Quick Deployment Reference

1. Development changes are pushed to the `development` branch
2. When ready for testing, merge to `staging` branch to deploy to TestFlight and Google Play internal testing
3. After successful testing, merge to `production` branch to deploy to App Store and Google Play Store

### Version Management

We use a versioning script to manage app versions:

```bash
# Bump patch version (e.g., 1.0.0 -> 1.0.1)
./scripts/bump_version.sh --type patch

# Bump minor version (e.g., 1.0.0 -> 1.1.0)
./scripts/bump_version.sh --type minor

# Bump major version (e.g., 1.0.0 -> 2.0.0)
./scripts/bump_version.sh --type major

# Bump build number only (e.g., 1.0.0+1 -> 1.0.0+2)
./scripts/bump_version.sh --build
```

## Recent Updates (April 2024)

-   **Firebase Initialization**: Resolved issues preventing Firebase from initializing correctly for new users signing in, ensuring consistent behavior.
-   **Provider Refactoring**: Improved the initialization logic for `DashChatProvider` by making it dependent on `AuthProvider` using `ChangeNotifierProxyProvider` for better state management.
-   **Keyword Quick Replies**: Implemented automatic quick reply button generation for messages received from the (simulated) server based on keywords (e.g., "hello", "help", "smoke").
-   **Quick Reply Handling**: Fixed the UI logic to ensure tapping quick reply buttons correctly triggers the intended simulated server response flow (matching the behavior of sending the same text via the input box).

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
3. Configure the Gemini API key in the `lib/services/bot_service.dart` file (or relevant configuration)
4. Configure Firebase for your project (add `google-services.json` for Android and `GoogleService-Info.plist` for iOS).
5. Run the app with `flutter run`

## Requirements

- Flutter 3.0 or higher
- Dart 2.17 or higher
- A Gemini API key
- Firebase Project Setup

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request against the `development` branch.

## License

This project is licensed under the MIT License - see the LICENSE file for details.