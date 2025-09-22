# QuitTxt - Flutter Health Companion App
## Comprehensive Project Documentation

### Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Project Structure](#project-structure)
4. [Key Components](#key-components)
5. [Development Setup](#development-setup)
6. [Build and Deployment](#build-and-deployment)
7. [Testing](#testing)
8. [Configuration](#configuration)
9. [Contributing](#contributing)

---

## Project Overview

**QuitTxt** is a comprehensive Flutter mobile application designed to help users quit smoking through chat-based support and messaging. The app provides a modern, health-focused experience with Firebase integration, real-time messaging, and advanced UI components.

### Key Features
- 🔐 **Firebase Authentication** - Google Sign-In and email/password
- 💬 **Real-time Chat** - Server-side integration with push notifications
- 🎨 **Modern Health-Focused UI** - Material 3 design with wellness colors
- 📱 **Cross-Platform** - iOS, Android, Web, macOS, Linux, Windows
- 🌍 **Internationalization** - English and Spanish support
- 📊 **Analytics** - Firebase Analytics integration
- 🔔 **Push Notifications** - Firebase Cloud Messaging
- 🖼️ **Media Support** - Images, videos, GIFs with picker service
- ⚡ **Performance Optimized** - Platform-specific optimizations

### Technical Specifications
- **Framework**: Flutter 3.16.0+
- **Language**: Dart 3.2.0+
- **State Management**: Provider pattern
- **Backend**: Firebase (Firestore, Auth, FCM, Analytics, Storage)
- **Platforms**: iOS, Android, Web, macOS, Linux, Windows

---

## Architecture

### Application Architecture Pattern
QuitTxt follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│                UI Layer                 │
│  ┌─────────────┐ ┌─────────────────────┐ │
│  │   Screens   │ │      Widgets        │ │
│  └─────────────┘ └─────────────────────┘ │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│            Provider Layer               │
│  ┌─────────────┐ ┌─────────────────────┐ │
│  │   State     │ │   Business Logic    │ │
│  │ Management  │ │     Providers       │ │
│  └─────────────┘ └─────────────────────┘ │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│             Service Layer               │
│  ┌─────────────┐ ┌─────────────────────┐ │
│  │  Firebase   │ │   Utility Services  │ │
│  │  Services   │ │   (Media, Analytics)│ │
│  └─────────────┘ └─────────────────────┘ │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│              Data Layer                 │
│  ┌─────────────┐ ┌─────────────────────┐ │
│  │   Models    │ │   External APIs     │ │
│  │   (DTOs)    │ │   (Firebase, HTTP)  │ │
│  └─────────────┘ └─────────────────────┘ │
└─────────────────────────────────────────┘
```

### State Management
- **Pattern**: Provider with ChangeNotifier
- **Global State**: AuthProvider, ChatProvider, UserProfileProvider
- **Local State**: StatefulWidget for UI-specific state
- **Service Coordination**: ServiceProvider for cross-service communication

### Service Architecture
- **Interface-based Design**: Abstract service contracts for testability
- **Service Manager**: Centralized service orchestration
- **Error Resilience**: Circuit breakers, retries, graceful degradation
- **Performance Monitoring**: Built-in performance tracking

---

## Project Structure

```
rcs_application/
├── lib/
│   ├── constants/           # App-wide constants
│   │   └── app_constants.dart
│   ├── firebase_options.dart # Firebase configuration
│   ├── l10n/               # Internationalization
│   │   ├── en.json         # English translations
│   │   └── es.json         # Spanish translations
│   ├── main.dart           # Application entry point
│   ├── models/             # Data models
│   │   ├── chat_message.dart
│   │   ├── link_preview.dart
│   │   ├── media_source.dart
│   │   ├── quick_reply.dart
│   │   └── user_profile.dart
│   ├── providers/          # State management
│   │   ├── auth_provider.dart
│   │   ├── channel_provider.dart
│   │   ├── chat_provider.dart
│   │   ├── dash_chat_provider.dart
│   │   ├── language_provider.dart
│   │   ├── service_provider.dart
│   │   ├── system_chat_provider.dart
│   │   └── user_profile_provider.dart
│   ├── screens/            # UI screens
│   │   ├── about_screen.dart
│   │   ├── help_screen.dart
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── profile_screen.dart
│   │   └── registration_screen.dart
│   ├── services/           # Business logic services
│   │   ├── analytics_service.dart
│   │   ├── dash_messaging_service.dart
│   │   ├── emoji_converter_service.dart
│   │   ├── firebase_connection_service.dart
│   │   ├── firebase_messaging_service.dart
│   │   ├── gif_service.dart
│   │   ├── link_preview_service.dart
│   │   ├── media_picker_service.dart
│   │   ├── notification_service.dart
│   │   ├── platform/
│   │   │   └── ios_media_picker.dart
│   │   ├── quick_reply_state_service.dart
│   │   ├── service_manager.dart
│   │   └── user_profile_service.dart
│   ├── theme/              # UI theming
│   │   └── app_theme.dart
│   ├── utils/              # Utility functions
│   │   ├── app_localizations.dart
│   │   ├── debug_config.dart
│   │   ├── env_switcher.dart
│   │   ├── ios_performance_utils.dart
│   │   ├── link_preview_debug.dart
│   │   ├── link_preview_test.dart
│   │   └── platform_utils.dart
│   └── widgets/            # Reusable UI components
│       ├── chat_message_widget.dart
│       ├── modern_chat_screen.dart
│       ├── modern_input_field.dart
│       ├── modern_message_bubble.dart
│       ├── modern_quick_reply.dart
│       └── quick_reply_widget.dart
├── assets/                 # Static assets
│   ├── gifs/              # GIF animations
│   ├── icons/             # App icons
│   ├── images/            # Image assets
│   └── logos/             # Logo variants
├── test/                  # Test files
│   ├── models/            # Model tests
│   ├── widgets/           # Widget tests
│   └── test_runner.dart   # Test configuration
├── integration_test/      # Integration tests
├── android/               # Android-specific files
├── ios/                   # iOS-specific files
├── web/                   # Web-specific files
├── macos/                 # macOS-specific files
├── linux/                # Linux-specific files
├── windows/               # Windows-specific files
├── architecture/          # Architecture documentation
├── thesis/                # Academic thesis files
├── CLAUDE.md              # Development guidelines
├── DESIGN_SYSTEM.md       # UI design system
└── pubspec.yaml           # Dependencies and configuration
```

---

## Key Components

### 1. Main Application (`lib/main.dart`)
Entry point with comprehensive initialization:
- **Firebase Setup**: Authentication, Firestore, FCM, App Check
- **Environment Management**: Multi-environment support (.env files)
- **Error Handling**: Graceful degradation with error boundary
- **Performance Optimization**: Platform-specific optimizations
- **Provider Configuration**: Multi-provider setup with dependency injection

**Key Features:**
- iOS performance optimizations via `IOSPerformanceUtils`
- Firebase retry logic with timeout handling
- Environment variable loading with fallback defaults
- Service initialization sequence with error isolation

### 2. State Management (`lib/providers/`)

#### AuthProvider (`auth_provider.dart`)
- Firebase Authentication integration
- Google Sign-In support
- User session management
- Authentication state broadcasting

#### ChatProvider (`chat_provider.dart`)
- Local chat message management
- Message rendering and display
- Media message handling (images, videos, GIFs)
- Integration with DashChatProvider

#### DashChatProvider (`dash_chat_provider.dart`)
- Server-side messaging integration
- Real-time message synchronization
- Quick reply handling
- Firebase Firestore integration

#### UserProfileProvider (`user_profile_provider.dart`)
- User profile management
- Settings persistence
- Analytics integration
- Display name synchronization

### 3. Service Layer (`lib/services/`)

#### Core Services
- **DashMessagingService**: Real-time messaging with server integration
- **FirebaseMessagingService**: Push notifications via FCM
- **FirebaseConnectionService**: Connection testing and health monitoring
- **UserProfileService**: User data persistence and management
- **AnalyticsService**: Firebase Analytics tracking

#### Utility Services
- **MediaPickerService**: Cross-platform media selection
- **GifService**: GIF management and search
- **NotificationService**: Local notification handling
- **LinkPreviewService**: URL preview generation
- **EmojiConverterService**: Emoji processing

#### Platform Services
- **IOSMediaPicker**: iOS-specific media picker implementation
- **QuickReplyStateService**: Quick reply state persistence

### 4. UI Components (`lib/widgets/`)

#### Modern Chat Components
- **ModernChatScreen**: Contemporary chat interface
- **ModernMessageBubble**: Modern message display with health-focused design
- **ModernInputField**: Enhanced text input with typing indicators
- **ModernQuickReply**: Interactive quick reply buttons

#### Traditional Components
- **ChatMessageWidget**: Flexible message display component
- **QuickReplyWidget**: Quick reply button implementation

### 5. Design System (`lib/theme/app_theme.dart`)
Comprehensive Material 3 theme with health-focused colors:
- **Primary Colors**: Modern indigo (`#6366F1`) and wellness green (`#10B981`)
- **Neutral Palette**: Warm whites and cool grays
- **Typography**: SF Pro Display with optimized letter spacing
- **Component Themes**: Cards, buttons, inputs with consistent styling

---

## Development Setup

### Prerequisites
```bash
# Install Flutter SDK (3.16.0+)
flutter --version

# Install dependencies
flutter pub get

# Verify doctor
flutter doctor
```

### Firebase Configuration
1. **Android**: Place `google-services.json` in `android/app/`
2. **iOS**: Place `GoogleService-Info.plist` in `ios/Runner/`
3. **Web**: Configure Firebase web settings
4. **Environment Variables**: Set up `.env` files for different environments

### Environment Configuration
Create environment files:
```bash
# .env (default)
SERVER_URL=http://localhost:8080
ENV=development
RECAPTCHA_SITE_KEY=your_key_here

# .env.development
SERVER_URL=https://dev-api.example.com
ENV=development

# .env.production  
SERVER_URL=https://api.example.com
ENV=production
```

### Platform-Specific Setup

#### iOS
```bash
cd ios
pod install
cd ..
```

#### Android
Ensure `android/local.properties` contains Android SDK path.

---

## Build and Deployment

### Development Commands
```bash
# Run in development mode
flutter run

# Run on specific device
flutter run -d ios
flutter run -d android

# Hot reload support
r  # Hot reload
R  # Hot restart
q  # Quit
```

### Building for Production

#### iOS
```bash
# Build iOS release
flutter build ios --release

# Archive with Xcode
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner archive
```

#### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

#### Web
```bash
flutter build web --release
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format .

# Run tests
flutter test

# Run integration tests
flutter test integration_test/
```

---

## Testing

### Test Structure
```
test/
├── basic_functionality_test.dart    # Basic app functionality
├── models/
│   └── chat_message_test.dart       # Model tests
├── widgets/
│   └── chat_message_widget_test.dart # Widget tests
├── test_config.dart                 # Test configuration
├── test_runner.dart                 # Custom test runner
└── widget_test.dart                 # Default widget test
```

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Test with coverage
flutter test --coverage

# Run specific test file
flutter test test/models/chat_message_test.dart
```

### Test Configuration
- **Mockito**: Service mocking and dependency injection
- **Integration Test**: End-to-end testing
- **Coverage**: Code coverage reporting

---

## Configuration

### Application Configuration
- **Bundle ID**: `quitxt_app` (configurable via build variants)
- **Version**: Managed in `pubspec.yaml` and platform-specific files
- **Permissions**: Location, camera, photo library, notifications

### Firebase Configuration
- **Authentication**: Google Sign-In, email/password
- **Firestore**: Real-time database for messages and user data
- **Cloud Messaging**: Push notifications with FCM tokens
- **App Check**: reCAPTCHA integration for security
- **Analytics**: User behavior tracking
- **Storage**: Media file uploads

### Environment Management
- **EnvSwitcher**: Runtime environment switching
- **SharedPreferences**: Environment persistence
- **Debug Configuration**: Development-specific settings

---

## Contributing

### Development Guidelines
1. **Follow CLAUDE.md**: Project-specific development instructions
2. **Use Design System**: Consistent UI via `DESIGN_SYSTEM.md`
3. **Code Style**: Flutter/Dart conventions with `flutter format`
4. **Testing**: Write tests for new features and bug fixes
5. **Documentation**: Update documentation for significant changes

### Git Workflow
```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes and commit
git add .
git commit -m "feat: add new feature"

# Push and create pull request
git push origin feature/new-feature
```

### Code Review Requirements
- [ ] Code follows project conventions
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] Firebase integration tested
- [ ] Cross-platform compatibility verified

### Performance Considerations
- **Bundle Size**: Monitor app size with each build
- **Firebase Usage**: Optimize Firestore queries and FCM usage  
- **Memory Management**: Proper disposal of streams and controllers
- **Platform Optimization**: iOS/Android specific optimizations

---

## Additional Resources

### Documentation Files
- `CLAUDE.md` - Development guidelines and commands
- `DESIGN_SYSTEM.md` - UI design system and components
- `architecture/` - Detailed architecture documentation
- `thesis/` - Academic research and methodology

### External Dependencies
- Firebase SDK - Backend services
- Provider - State management
- HTTP - API communication
- Image Picker - Media selection
- Flutter Localizations - Internationalization

### Support and Community
- Flutter Documentation: https://flutter.dev/docs
- Firebase Documentation: https://firebase.google.com/docs
- Material Design: https://m3.material.io/

---

*Last Updated: 2024-12-17*
*Version: 1.0.0+25*