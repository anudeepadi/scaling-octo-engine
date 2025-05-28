# Installation Guide

This guide will help you set up your development environment for working with the QuitTxT App.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: Version 3.0 or higher
  - [Flutter Installation Guide](https://flutter.dev/docs/get-started/install)
- **Dart SDK**: Version 2.17 or higher (usually comes with Flutter)
- **Android Studio** or **Visual Studio Code** with Flutter and Dart plugins
- **Xcode** (for macOS users) for iOS development
- **Git** for version control
- **Firebase CLI** for Firebase integration

## Setting Up the Development Environment

### 1. Clone the Repository

```bash
git clone <repository-url>
cd rcs_application
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Set Up Firebase

#### For Android:

1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/)
2. Add an Android app to your Firebase project
3. Download the `google-services.json` file
4. Place the file in the `android/app` directory

#### For iOS:

1. Add an iOS app to your Firebase project
2. Download the `GoogleService-Info.plist` file
3. Place the file in the `ios/Runner` directory
4. Open the iOS project in Xcode and add the file to the Runner target

### 4. Set Up Environment Variables

1. Create the necessary `.env` files in the project root:
   - `.env` (default)
   - `.env.development`
   - `.env.production`

2. Add the required environment variables to each file:

   ```
   ENV=development
   SERVER_URL=http://your-server-url
   GEMINI_API_KEY=your-gemini-api-key
   ```

### 5. iOS Setup

1. Install CocoaPods if not already installed:
   ```bash
   sudo gem install cocoapods
   ```

2. Install iOS dependencies:
   ```bash
   cd ios
   pod install
   cd ..
   ```

### 6. Android Setup

Ensure your Android SDK is properly configured in Android Studio or with appropriate environment variables.

## Verifying Installation

To verify that everything is set up correctly:

1. Run Flutter doctor:
   ```bash
   flutter doctor
   ```

2. Start the app in debug mode:
   ```bash
   flutter run
   ```

## Troubleshooting

### Common Issues:

1. **Firebase Integration Issues**:
   - Verify that the Firebase configuration files are in the correct locations
   - Ensure that the package name/bundle ID in Firebase matches your app

2. **Environment Variables Not Loading**:
   - Verify the `.env` files are in the correct location
   - Check the format of the variables

3. **iOS Build Issues**:
   - Try running `pod update` to update CocoaPods dependencies
   - Check Xcode version compatibility

4. **Android Build Issues**:
   - Verify your Android SDK setup
   - Check Gradle version compatibility

## Next Steps

After installation, proceed to the [Configuration Guide](configuration.md) to learn how to configure the app for different environments.