# iOS Build Fix Guide

This guide addresses the issue with the iOS build error: `unsupported option '-G' for target 'x86_64-apple-ios10.0-simulator'`.

## Fixes Applied

1. **Updated Podfile Configuration:**
   - Uncommented and set iOS platform version to 12.0
   - Added specific handling for the `-G` compiler flag error
   - Enhanced post_install hooks with Xcode 14+ compatibility settings

2. **Updated Minimum iOS Version:**
   - Ensured all configuration files use iOS 12.0 as the minimum version

## How to Apply the Fix

1. **Manual Cleanup Method:**
   Run the following commands in order:

   ```bash
   # Clean Flutter project
   flutter clean

   # Remove iOS build artifacts
   cd ios
   rm -rf Pods
   rm -rf .symlinks
   rm -rf Flutter/Flutter.framework
   rm -rf Flutter/Flutter.podspec
   rm -f Podfile.lock

   # Reinstall pods
   pod deintegrate
   pod install --repo-update
   cd ..

   # Get Flutter dependencies
   flutter pub get

   # Run the app
   flutter run
   ```

2. **Using the Provided Script:**
   We've created a script to automate the cleanup process:

   ```bash
   # Make the script executable if needed
   chmod +x ios_clean.sh

   # Run the script
   ./ios_clean.sh
   ```

## Troubleshooting

If you still encounter issues after applying these fixes:

1. **Check Xcode Version:**
   - Ensure you're using a compatible Xcode version (Xcode 13.0+ recommended)

2. **CocoaPods Version:**
   - Update CocoaPods to the latest version:
     ```bash
     sudo gem install cocoapods
     ```

3. **Flutter Version:**
   - Consider updating Flutter:
     ```bash
     flutter upgrade
     ```

4. **Try Running on Android:**
   - To verify that the app itself is working correctly:
     ```bash
     flutter run -d android
     ```

## Additional Notes

- This fix addresses compatibility between older Flutter Firebase plugins and newer iOS/Xcode versions
- The issue was specifically related to the compiler flag `-G` which is no longer supported in newer build environments
- The iOS deployment target has been updated to 12.0 throughout the project