# Firebase Setup and Troubleshooting

This guide will help you set up Firebase correctly with this application and resolve common issues.

## Firebase Version Compatibility

The app uses the following Firebase package versions to ensure compatibility:

```yaml
firebase_core: ^2.24.2
firebase_auth: ^4.15.3
cloud_firestore: ^4.13.6
firebase_messaging: ^14.7.10
firebase_storage: ^11.5.6
```

## Running the App

The simplest way to run the app is using the provided script:

```bash
bash run_app.sh
```

This script will:
1. Attempt to run the app normally
2. If it fails with CocoaPods issues, fix common problems automatically
3. Try running again

## Fixing CocoaPods Issues

If you encounter CocoaPods dependency conflicts, especially with Firebase, use the iOS reset script:

```bash
bash ios_reset.sh
```

This script will:
1. Clean the Flutter build
2. Remove CocoaPods cache
3. Update CocoaPods repos
4. Reinstall dependencies
5. Perform a clean pod install

## Manual Steps for iOS Firebase Issues

If scripts don't resolve the issue, try these manual steps:

1. Remove Podfile.lock:
   ```bash
   rm ios/Podfile.lock
   ```

2. Update CocoaPods repositories:
   ```bash
   pod repo update
   ```

3. Clean the Flutter project:
   ```bash
   flutter clean
   ```

4. Get dependencies:
   ```bash
   flutter pub get
   ```

5. Reinstall pods with repo update:
   ```bash
   cd ios && pod install --repo-update
   ```

## Common Errors and Solutions

### "CocoaPods could not find compatible versions for pod Firebase/Firestore" or "Firebase/Auth"

This occurs due to a version mismatch between what's in your Podfile.lock and what's required by the updated packages.

Solution:
1. Edit ios/Podfile to explicitly specify the Firebase versions:
   ```ruby
   pod 'Firebase/Firestore', '10.25.0'
   pod 'Firebase/Auth', '10.25.0'
   ```

2. Run the fix script:
   ```bash
   bash fix_firebase_auth.sh
   ```

3. Or manually delete Podfile.lock and reinstall pods:
   ```bash
   rm ios/Podfile.lock
   cd ios && pod update Firebase/Auth Firebase/Firestore
   cd ios && pod install
   ```

### "Unsupported option '-G' for target 'x86_64-apple-ios12.0-simulator'"

This error occurs due to incompatible compiler flags in one of the CocoaPods dependencies.

Solution:
1. Run the compiler flags fix script:
   ```bash
   bash fix_compiler_flags.sh
   ```

2. Or manually fix by:
   - Clean Xcode derived data:
     ```bash
     rm -rf ~/Library/Developer/Xcode/DerivedData
     ```
   - Remove pods and reinstall:
     ```bash
     rm -rf ios/Pods ios/Podfile.lock
     cd ios && pod install --repo-update
     ```

The fix works by modifying the Podfile to remove problematic compiler flags during pod installation.

## Firebase Authentication

The app is configured to work with Firebase Authentication. To use it:

1. Ensure your Firebase project has Authentication enabled with your desired sign-in methods
2. Make sure your `GoogleService-Info.plist` (iOS) and `google-services.json` (Android) files are correctly installed
3. Test authentication using the `FirebaseConnectionService.testConnection()` method

## Dash Messaging Integration

The app integrates with Dash Messaging service using Firebase Cloud Messaging (FCM). Key components:

- `FirebaseMessagingService` - Manages FCM tokens and notifications
- `FirebaseConnectionService` - Tests connection with Firebase services
- `DashChatProvider` - Handles communication with the Dash messaging server

## Running Without Firebase

The app is designed to fall back to demo mode if Firebase is not available or fails to initialize. In this mode:

- All Firebase-dependent features will use local mock data
- The app will still function, but without real-time messaging capabilities
- Chat history won't be synchronized across devices