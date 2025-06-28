# Mobile App Testing & Deployment Guide

## Overview
Two-stage testing approach:
1. **Internal Testing** - Your devices only
2. **Beta Testing** - External testers

## iOS (TestFlight) Setup

### Stage 1: Internal Testing (Your Devices)
1. **In App Store Connect:**
   - Go to your app → TestFlight tab
   - Under "Internal Testing" → Create a new group (e.g., "Development Team")
   - Add yourself and any team members (up to 100 testers)
   - Internal testers get builds immediately after processing

2. **Upload Build:**
   ```bash
   # From your project directory
   cd ios
   flutter build ios --release
   
   # Open in Xcode
   open Runner.xcworkspace
   
   # In Xcode:
   # 1. Select "Any iOS Device" as destination
   # 2. Product → Archive
   # 3. Distribute App → App Store Connect → Upload
   ```

3. **Auto-deployment for Internal Testing:**
   - Builds appear automatically for internal testers
   - No review required
   - Available within 5-10 minutes

### Stage 2: External Testing (Beta Testers)
1. **Create External Group:**
   - TestFlight → External Testing → Add Group
   - Name it (e.g., "Beta Testers")
   - Add your existing testers

2. **Submit for Review:**
   - Select build → Add to External Testing
   - Fill in "What to Test" information
   - Submit for Beta App Review (usually 24-48 hours)

3. **Auto-deployment after approval:**
   - Once approved, all builds go to external testers automatically
   - Set build expiration notifications

## Android (Play Store) Setup

### Stage 1: Internal Testing (Your Devices)
1. **In Google Play Console:**
   - Go to your app → Testing → Internal testing
   - Create new release
   - Add testers by email or create email lists

2. **Upload Build:**
   ```bash
   # Build AAB (Android App Bundle)
   flutter build appbundle --release
   
   # Or APK for direct testing
   flutter build apk --release
   ```

3. **Internal Testing Track:**
   - Upload your AAB to Internal Testing
   - Add tester emails (up to 100)
   - Share opt-in link with testers
   - Updates available within minutes

### Stage 2: Closed Testing (Beta Testers)
1. **Create Closed Testing Track:**
   - Testing → Closed testing → Create track
   - Name: "Beta Testing"
   - Add your tester list

2. **Release Process:**
   - Upload AAB to closed testing
   - No review required for closed testing
   - Available within 2-3 hours

## Automated Deployment Setup

### Using Fastlane (Recommended)

1. **Install Fastlane:**
   ```bash
   sudo gem install fastlane -NV
   # or using Homebrew
   brew install fastlane
   ```

2. **iOS Fastlane Setup:**
   Create `ios/fastlane/Fastfile`:
   ```ruby
   default_platform(:ios)

   platform :ios do
     desc "Push to TestFlight Internal"
     lane :internal do
       build_app(
         scheme: "Runner",
         export_method: "app-store"
       )
       upload_to_testflight(
         skip_waiting_for_build_processing: true,
         groups: ["Development Team"]
       )
     end

     desc "Push to TestFlight External"
     lane :beta do
       build_app(
         scheme: "Runner",
         export_method: "app-store"
       )
       upload_to_testflight(
         groups: ["Beta Testers"],
         changelog: "Bug fixes and improvements"
       )
     end
   end
   ```

3. **Android Fastlane Setup:**
   Create `android/fastlane/Fastfile`:
   ```ruby
   default_platform(:android)

   platform :android do
     desc "Deploy to Internal Testing"
     lane :internal do
       gradle(
         task: "bundle",
         build_type: "Release"
       )
       upload_to_play_store(
         track: "internal",
         aab: "../build/app/outputs/bundle/release/app-release.aab"
       )
     end

     desc "Deploy to Beta Testing"
     lane :beta do
       gradle(
         task: "bundle",
         build_type: "Release"
       )
       upload_to_play_store(
         track: "beta",
         aab: "../build/app/outputs/bundle/release/app-release.aab"
       )
     end
   end
   ```

### GitHub Actions CI/CD

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to Stores

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build iOS
        run: flutter build ios --release --no-codesign
      
      - name: Deploy to TestFlight
        run: |
          cd ios
          fastlane internal
        env:
          FASTLANE_USER: ${{ secrets.APPLE_ID }}
          FASTLANE_PASSWORD: ${{ secrets.APPLE_PASSWORD }}

  deploy-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build Android
        run: flutter build appbundle --release
      
      - name: Deploy to Play Store
        run: |
          cd android
          fastlane internal
        env:
          PLAY_STORE_JSON_KEY: ${{ secrets.PLAY_STORE_JSON }}
```

## Version & Build Management

### Version Strategy:
```yaml
# pubspec.yaml
version: 1.0.0+1  # version+buildNumber

# Internal Testing: 1.0.0+1, 1.0.0+2, etc.
# Beta Testing: 1.0.1+10, 1.0.2+20, etc.
# Production: 1.1.0+100, 1.2.0+200, etc.
```

### Auto-increment build numbers:
```bash
# Create a script: scripts/bump_version.sh
#!/bin/bash
current_version=$(grep "version:" pubspec.yaml | sed 's/version: //')
version_name=$(echo $current_version | cut -d'+' -f1)
build_number=$(echo $current_version | cut -d'+' -f2)
new_build_number=$((build_number + 1))
sed -i '' "s/version: .*/version: $version_name+$new_build_number/" pubspec.yaml
echo "Bumped to $version_name+$new_build_number"
```

## Testing Workflow

### Daily Development:
1. **Local Testing** → Push code
2. **Trigger Internal Build** → Auto-deploys to your devices
3. **Test on your devices** → Fix issues

### Weekly Beta Release:
1. **Tag release**: `git tag v1.0.1-beta`
2. **Push tag**: `git push origin v1.0.1-beta`
3. **CI/CD deploys to beta testers automatically**

### Release Checklist:
- [ ] Update version in pubspec.yaml
- [ ] Update CHANGELOG.md
- [ ] Test on internal devices
- [ ] Create git tag
- [ ] Monitor crash reports
- [ ] Gather tester feedback

## Monitoring & Feedback

### Crash Reporting:
```dart
// Add to main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Pass all uncaught errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runApp(MyApp());
}
```

### In-App Feedback:
```dart
// Add feedback button in settings
ElevatedButton(
  onPressed: () async {
    final url = Platform.isIOS 
      ? 'https://testflight.apple.com/feedback' 
      : 'mailto:support@yourapp.com';
    await launch(url);
  },
  child: Text('Send Feedback'),
)
```

## Quick Commands

```bash
# iOS Internal Testing
cd ios && fastlane internal

# iOS Beta Testing  
cd ios && fastlane beta

# Android Internal Testing
cd android && fastlane internal

# Android Beta Testing
cd android && fastlane beta

# Deploy to both platforms
./scripts/deploy_all.sh internal
```

## Important Notes

1. **iOS**: App Store Connect requires:
   - Valid provisioning profiles
   - App-specific password for CI/CD
   - Export compliance information

2. **Android**: Play Console requires:
   - Signed AAB file
   - Service account JSON for CI/CD
   - Content rating questionnaire

3. **Both Platforms**:
   - Update screenshots for major changes
   - Maintain separate release notes
   - Monitor adoption rates

This setup gives you a smooth path from development to production with proper testing stages.
