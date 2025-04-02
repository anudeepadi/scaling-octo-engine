# RCS Application Summary

## Overview

This Flutter application provides a Rich Communication Services (RCS) messaging experience enhanced with AI features. It aims to deliver a modern chat interface supporting various media types and intelligent interactions.

## Core Features

*   **RCS Messaging:** Implements core chat functionalities like sending/receiving text messages.
*   **Rich Media Support:** Handles images, GIFs (via local assets and potentially external sources), and videos within chat messages. Includes media pickers (camera/gallery) and previews.
*   **YouTube Previews:** Automatically detects and displays previews for YouTube links shared in messages.
*   **Link Previews:** (Potentially, based on `LinkPreviewService`) Generates previews for general URLs.
*   **Quick Replies:** Supports standard quick reply buttons.
*   **Gemini AI Integration:**
    *   Integrates with Google's Gemini API (`google_generative_ai` package) for AI-powered interactions, likely including bot responses and suggestions.
    *   Features enhanced UI for Gemini-generated quick replies (visual distinction, dynamic generation).
*   **Dash Messaging Service:** Integrates with a secondary messaging service ("Dash"), potentially using Firebase for backend features like real-time messaging and storage. Users can toggle between Gemini and Dash services.
*   **Authentication:** Includes a login screen and uses `firebase_auth` for user authentication.
*   **Multi-Conversation Management:** Allows users to create, rename, switch between, and delete multiple chat conversations. Chat history appears to be managed locally or potentially synced via Firebase depending on the active service.
*   **Platform Adaptation:** Provides distinct UI experiences for iOS (Cupertino) and Android (Material Design).
*   **State Management:** Uses the `provider` package for managing application state across various components (Auth, Chat, Services, etc.).

## Architecture

*   **Language:** Dart with Flutter framework.
*   **UI:** Built with Flutter widgets, adapting to iOS and Android styles.
*   **State Management:** `provider` package.
*   **Backend/Services:**
    *   **Gemini:** Direct API calls via `google_generative_ai`.
    *   **Dash:** Utilizes Firebase services (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`, `firebase_storage`).
    *   Potentially uses WebSockets (`web_socket_channel`) for real-time communication, possibly for the Dash service or other features.
*   **Key Packages:**
    *   `http`: For general network requests.
    *   `provider`: State management.
    *   `google_generative_ai`: Gemini integration.
    *   Firebase suite (`firebase_core`, `auth`, `firestore`, etc.): Backend for Dash service.
    *   `file_picker`, `path_provider`: File system access.
    *   `video_player`, `chewie`: Video playback.
    *   `youtube_player_flutter`: YouTube playback.
    *   `flutter_lints`: Code analysis.

## Key Components

*   **`main.dart`:** App entry point, initializes Firebase (if available), sets up providers, and defines the root `MyApp` widget.
*   **`providers/`:** Contains `ChangeNotifier` classes for managing state (e.g., `AuthProvider`, `ChatProvider`, `DashChatProvider`, `ServiceProvider`).
*   **`screens/`:** Defines the main UI screens (`HomeScreen`, `LoginScreen`, `ProfileScreen`). `HomeScreen` is the primary chat interface.
*   **`services/`:** Encapsulates business logic and external interactions:
    *   `BotService`/`GeminiService`: Interacts with the Gemini API.
    *   `DashMessagingService`/`FirebaseChatService`: Handles communication with the Dash/Firebase backend.
    *   `ServiceProvider`/`ServiceManager`: Manages the toggling between Gemini and Dash services.
    *   `MediaPickerService`, `GifService`, `VideoService`: Handle media selection, loading, and processing.
*   **`widgets/`:** Contains reusable UI components like chat bubbles (`ChatMessageWidget`), message input fields (`IosMessageInput`, standard input), media previews, and quick reply widgets.
*   **`models/`:** Defines data structures for messages (`ChatMessage`), quick replies (`QuickReply`, `GeminiQuickReply`), etc.

## Setup & Running

1.  Ensure Flutter SDK is installed.
2.  Configure Firebase for both iOS and Android platforms (place `GoogleService-Info.plist` and `google-services.json`).
3.  Set up a Gemini API key (likely configured within `BotService` or a similar file).
4.  Run `flutter pub get` to install dependencies.
5.  Run `flutter run` to launch the app on a connected device or simulator.

This summary provides a high-level overview based on the available code structure and dependencies.
