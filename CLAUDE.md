# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **QuitTxt** - a Flutter mobile application that helps users quit smoking through chat-based support and messaging. The app connects to a chat server and provides Firebase-based authentication, messaging, and analytics.

**Current Setup**: The project is configured for the "old_ui" branch with classic bundle ID (`quitxt_app` instead of `quitxt_classic`).

## Development Commands

### Core Flutter Commands
```bash
# Run the app in development mode
flutter run

# Run on specific device
flutter run -d ios
flutter run -d android

# Build for production
flutter build ios
flutter build android
flutter build apk

# Clean and get dependencies
flutter clean
flutter pub get

# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Run integration tests
flutter test integration_test/

# Format code
flutter format .
```

### Build and Deployment
```bash
# iOS build and archive (requires Xcode)
flutter build ios --release
cd ios && xcodebuild -workspace Runner.xcworkspace -scheme Runner archive

# Android release build
flutter build apk --release
flutter build appbundle --release
```

### Firebase and Environment Setup
```bash
# The app supports multiple environments via .env files:
# .env (default)
# .env.development
# .env.production

# Environment variables needed:
# SERVER_URL=http://localhost:8080
# ENV=development|production
# RECAPTCHA_SITE_KEY=your_key_here
```

## Architecture

### State Management
- **Provider pattern** with `ChangeNotifierProvider` for global state
- **Key Providers**:
  - `AuthProvider` - Firebase authentication state
  - `ChatProvider` - Chat messaging and history
  - `DashChatProvider` - Server-side chat service integration
  - `ChannelProvider` - Chat channel management
  - `UserProfileProvider` - User profile and settings
  - `LanguageProvider` - Internationalization
  - `ServiceProvider` - Service layer coordination

### Service Layer Architecture
Located in `lib/services/`, these handle external integrations:
- `FirebaseConnectionService` - Firebase connectivity testing
- `FirebaseMessagingService` - Push notifications via FCM
- `AnalyticsService` - Firebase Analytics tracking
- `UserProfileService` - User data management
- `MediaPickerService` - Image/video picker with platform-specific implementations
- `NotificationService` - Local notification handling
- `QuickReplyStateService` - Quick reply state persistence

### Screen Structure
- `LoginScreen` - Authentication with Google Sign-In
- `HomeScreen` - Main chat interface
- `ProfileScreen` - User settings and profile
- `RegistrationScreen` - User registration flow
- `AboutScreen` - App information

### Platform-Specific Considerations
- **iOS**: Uses `IOSPerformanceUtils` for optimization
- **Android**: Platform-specific URL transformations for localhost
- **Web**: Basic support with Firebase web configuration

## Firebase Configuration

The app uses comprehensive Firebase integration:
- **Authentication**: Google Sign-In and email/password
- **Firestore**: Chat history and user data storage
- **Cloud Messaging**: Push notifications with FCM tokens
- **App Check**: Security validation with reCAPTCHA
- **Analytics**: User behavior tracking
- **Storage**: Media file uploads

**Important**: Firebase initialization includes retry logic and graceful degradation to "demo mode" if initialization fails.

## Development Guidelines

### Error Handling
- Uses `AppErrorBoundary` widget for graceful error handling
- Comprehensive logging with `dart:developer`
- Firebase failures are non-blocking - app continues in demo mode

### Performance Optimizations
- iOS-specific performance optimizations in main()
- Lazy loading of services
- Timeout handling for all async operations
- Platform-specific initialization delays

### Testing
- Unit tests: `flutter test`
- Integration tests: `flutter test integration_test/`
- Widget tests included in `test/` directory
- Mock services available via `mockito` package

### Internationalization
- Supports English and Spanish (en.json, es.json)
- Uses `AppLocalizations` with `flutter_localizations`
- Locale-aware formatting with `intl` package

## Common Issues and Solutions

### Firebase Connection Issues
- App includes automatic retry logic
- Check environment variables are properly loaded
- Verify Firebase configuration files are present:
  - `ios/Runner/GoogleService-Info.plist`
  - `android/app/google-services.json`

### iOS Build Issues
- Run `cd ios && pod install` after dependency changes
- May need to run `flutter clean` before iOS builds
- Check Xcode signing configuration

### Environment Switching
- Use `EnvSwitcher` utility to change environments
- Restart app after environment changes
- Environment persisted in SharedPreferences

## BMAD-METHOD Framework Integration

This project can be enhanced with the BMAD-METHOD framework for specialized AI agent teams.

### Initial BMAD Setup

```bash
# Install BMAD in your QuitTxT project root
cd /path/to/quittxt
npx bmad-method install
```

### Team Configuration

Create `bmad-config.json` in project root:

```json
{
  "project": {
    "name": "QuitTxT",
    "type": "flutter-mobile-app",
    "domain": "health-wellness-messaging",
    "version": "1.0.0"
  },
  "teams": {
    "ui_team": {
      "agents": ["ui-designer", "flutter-developer", "accessibility-specialist"],
      "focus": "health-focused-design-system",
      "artifacts": ["design-system", "flutter-widgets", "theme-config"]
    },
    "testing_team": {
      "agents": ["qa-engineer", "test-automation", "performance-tester"],
      "focus": "flutter-testing-firebase-integration",
      "artifacts": ["test-suites", "coverage-reports", "performance-metrics"]
    },
    "scrum_team": {
      "agents": ["scrum-master", "product-owner", "technical-lead"],
      "focus": "health-app-development-cycle",
      "artifacts": ["sprint-planning", "user-stories", "release-notes"]
    },
    "features_team": {
      "agents": ["feature-analyst", "flutter-architect", "firebase-specialist"],
      "focus": "rcs-messaging-health-features",
      "artifacts": ["feature-specs", "technical-design", "integration-guides"]
    },
    "thesis_team": {
      "agents": ["thesis-writer", "research-analyst", "academic-reviewer"],
      "focus": "mobile-health-app-research",
      "artifacts": ["thesis-chapters", "research-data", "academic-papers"]
    },
    "version_control_team": {
      "agents": ["git-specialist", "devops-engineer", "release-manager"],
      "focus": "code-versioning-deployment",
      "artifacts": ["git-workflows", "release-branches", "deployment-configs"]
    }
  }
}
```

### BMAD Development Commands

```bash
# Start development session with specific team
npx bmad-method start-sprint

# UI Team workflow
npx bmad-method dev --agent ui-designer --story "implement-dark-theme"

# Testing Team workflow  
npx bmad-method dev --agent qa-engineer --story "fix-firebase-test-timeout"

# Feature Team workflow
npx bmad-method dev --agent flutter-architect --story "enhance-rcs-messaging"

# Thesis writing workflow
npx bmad-method dev --agent thesis-writer --story "literature-review-chapter"

# Git workflow integration
npx bmad-method git-branch --story "implement-dark-theme" --team ui_team
```

### Specialized Agent Focus Areas

**UI Team Agent**:
- Health-focused Material 3 design system
- Flutter widget development following accessibility standards
- Performance optimization for animations
- Dark theme implementation for health apps

**Testing Team Agent**:
- Flutter test infrastructure (unit, widget, integration)
- Firebase service mocking and testing
- Performance benchmarking for messaging features
- Test coverage improvement (target: 80%+)

**Thesis Team Agent**:
- Academic research on mobile health applications
- Research data extraction from development artifacts
- Technical documentation for academic submission
- Literature review on RCS messaging and health communication

**Git Specialist Agent**:
- Branch strategy management (main/develop/feature branches)
- Release workflow automation
- Commit message standardization
- CI/CD pipeline optimization

### Quality Gates Integration

Create `.bmad/quality-gates.yaml`:

```yaml
quality_gates:
  pre_commit:
    - flutter analyze
    - flutter test --no-sound-null-safety
    - dart format --set-exit-if-changed .
    - thesis_spell_check
    
  pre_merge:
    - flutter test --coverage
    - flutter build appbundle --release
    - security_audit
    - thesis_chapter_review
    
  pre_release:
    - performance_benchmarks
    - accessibility_audit
    - health_app_compliance_check
    - thesis_data_validation
```

### Recommended Expansion Packs

Add to `package.json`:

```json
{
  "dependencies": {
    "@bmad-method/flutter-pack": "latest",
    "@bmad-method/health-wellness-pack": "latest", 
    "@bmad-method/firebase-pack": "latest",
    "@bmad-method/mobile-testing-pack": "latest"
  }
}
```

## Key Dependencies
- `firebase_core`, `firebase_auth`, `cloud_firestore` - Firebase integration
- `provider` - State management
- `http` - API communication
- `google_sign_in` - Authentication
- `flutter_local_notifications` - Push notifications
- `image_picker`, `file_picker` - Media handling
- `video_player`, `chewie` - Video playback
- `cached_network_image` - Image caching
- `flutter_linkify` - URL detection
- `youtube_player_flutter` - YouTube video embedding