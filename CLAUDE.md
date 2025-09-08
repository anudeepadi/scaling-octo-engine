# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

QuitTxT is a Flutter mobile application focused on health and wellness messaging with RCS (Rich Communication Services) capabilities. The app features modern UI design, Firebase integration, real-time messaging, multimedia support, and comprehensive authentication.

## Development Commands

### Flutter Development
- **Install dependencies**: `flutter pub get`
- **Run app (development)**: `flutter run`  
- **Run app with specific flavor**: `flutter run --flavor development`
- **Run tests**: `flutter test`
- **Analyze code**: `flutter analyze`
- **Build Android**: `flutter build appbundle --release`
- **Build iOS**: `flutter build ios --release`

### Environment Setup
- Development environment uses `.env.development` 
- Production environment uses `.env.production`
- Environment files are copied during CI/CD based on branch

### Testing & Quality
- Linting rules defined in `analysis_options.yaml`
- Uses `flutter_lints` package for code style enforcement
- CI/CD pipeline runs tests automatically on push/PR

## Architecture Overview

### State Management
The app uses **Provider pattern** with multiple specialized providers:
- `AuthProvider`: Firebase authentication, Google Sign-In
- `ChatProvider`: Core messaging functionality  
- `DashChatProvider`: Enhanced chat features with multimedia
- `ChannelProvider`: Message channels and routing
- `SystemChatProvider`: System-level messaging
- `UserProfileProvider`: User profile management
- `LanguageProvider`: Internationalization support
- `ServiceProvider`: Service layer coordination

### Key Architecture Patterns
1. **Multi-Provider Setup**: Complex dependency injection with proxy providers
2. **Service Layer**: Dedicated services for Firebase, messaging, analytics, notifications
3. **Widget Composition**: Modular, reusable widgets for UI components
4. **Platform Adaptation**: iOS/Android specific implementations
5. **Environment Management**: Branch-based environment switching

### Core Services
- **Firebase Integration**: Authentication, Firestore, Messaging, Analytics, Storage
- **Messaging Services**: RCS messaging, push notifications, emoji conversion
- **Media Services**: Image/video picker, GIF support, link previews
- **Platform Services**: iOS-specific optimizations, platform utilities

### UI Architecture
- **Design System**: Health-focused modern UI with defined color palette and typography
- **Theme Management**: Centralized in `lib/theme/app_theme.dart` with Material 3
- **Component Library**: Reusable widgets for messages, inputs, navigation
- **Responsive Design**: Adaptive layouts with platform-specific UI elements

## Project Structure

### Core Directories
```
lib/
├── main.dart                 # App entry point with provider setup
├── firebase_options.dart     # Firebase configuration
├── screens/                  # Main application screens
├── widgets/                  # Reusable UI components  
├── providers/                # State management providers
├── services/                 # Business logic and external integrations
├── models/                   # Data models and DTOs
├── theme/                    # UI theme and design system
└── utils/                    # Utilities, localizations, platform helpers
```

### Key Files
- `lib/main.dart`: Multi-provider setup, Firebase initialization, app routing
- `lib/theme/app_theme.dart`: Complete design system with health-focused colors
- `lib/screens/home_screen.dart`: Main chat interface with messaging
- `lib/screens/login_screen.dart`: Authentication with Firebase and Google Sign-In
- `lib/providers/auth_provider.dart`: Firebase authentication management
- `lib/services/firebase_messaging_service.dart`: Push notifications and messaging

## Firebase Configuration

### Services Used
- **Firebase Auth**: Email/password and Google Sign-In authentication
- **Firestore**: Real-time chat data and user profiles
- **Firebase Messaging**: Push notifications for chat messages
- **Firebase Storage**: Media file uploads and downloads
- **Firebase Analytics**: User engagement and app usage tracking
- **Firebase App Check**: App attestation and security

### Configuration Files
- `firebase_options.dart`: Auto-generated Firebase configuration
- Environment-specific Firebase projects for dev/staging/production

## CI/CD Pipeline

### Branch Strategy
- **development**: Development builds and testing
- **staging**: TestFlight (iOS) and Google Play Alpha testing
- **production**: App Store and Google Play production releases

### Automated Workflows
- **Version Bumping**: Automatic version increment on staging/production pushes
- **Multi-platform Builds**: Parallel Android and iOS builds
- **Store Deployment**: Automated deployment to app stores based on branch
- **Quality Gates**: Tests and analysis must pass before deployment

### Build Artifacts
- Android: App Bundle (`.aab`) for Google Play distribution
- iOS: IPA files for App Store and TestFlight distribution

## Development Guidelines

### Code Style
- Follow Flutter/Dart conventions with `flutter_lints`
- Use the established provider pattern for state management
- Implement platform-specific code in dedicated service classes
- Follow the design system defined in `app_theme.dart`

### Firebase Integration
- Always use existing Firebase service classes rather than direct Firebase calls
- Implement proper error handling for network operations
- Use environment-appropriate Firebase projects

### UI Development
- Follow the health-focused design system with established color palette
- Use existing widget components before creating new ones
- Implement responsive design patterns for different screen sizes
- Add proper accessibility labels and focus management

### Testing
- Write unit tests for business logic in services and providers
- Test Firebase integration with proper mocking
- Verify UI components with widget tests
- Test platform-specific functionality on both iOS and Android

## Deployment Process

### Environment Promotion
1. **Development**: Feature development and initial testing
2. **Staging**: Integration testing, TestFlight/Alpha testing  
3. **Production**: Live app store releases

### Release Management
- Version numbers auto-increment based on branch (patch/minor/major)
- Build numbers increment automatically on each deployment
- Store metadata and release notes managed through respective consoles

## Key Dependencies

### Core Flutter Packages
- `provider` (6.1.1): State management
- `firebase_core`, `firebase_auth`, `cloud_firestore`: Firebase integration  
- `http` (1.1.2): Network requests
- `shared_preferences` (2.2.2): Local storage
- `flutter_localizations`: Internationalization

### Media & UI Packages  
- `cached_network_image` (3.3.0): Optimized image loading
- `video_player`, `chewie`: Video playback
- `image_picker` (1.0.7): Camera and gallery access
- `file_picker` (9.2.3): File selection
- `flutter_linkify` (6.0.0): URL detection and linking

### Platform Integration
- `google_sign_in` (6.3.0): Google authentication
- `url_launcher` (6.2.2): External URL handling
- `firebase_messaging` (15.1.0): Push notifications
- `flutter_local_notifications` (17.2.2): Local notification display