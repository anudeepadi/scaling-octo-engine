#!/bin/bash

# Deep clean script for iOS build issues
# This script performs a thorough cleanup of all Flutter and iOS build artifacts
# and rebuilds the iOS project with fixed configuration

set -e
cd "$(dirname "$0")"

echo "===== Performing deep clean ====="

# Kill Xcode if it's running to avoid file lock issues
echo "Closing Xcode if open..."
killall Xcode || true
sleep 2

# Stop CocoaPods processes if any
echo "Stopping CocoaPods processes..."
killall ruby || true
sleep 1

# 1. Flutter clean
echo "Running flutter clean..."
flutter clean

# 2. Remove Dart package cache
echo "Removing package cache..."
rm -rf ~/.pub-cache/

# 3. Clean iOS directory thoroughly
echo "Deep cleaning iOS directory..."
cd ios
rm -rf Pods
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec
rm -rf Flutter/ephemeral
rm -f Podfile.lock
rm -rf .xcodebuild
rm -rf build
rm -rf DerivedData
cd ..

# 4. Clear CocoaPods cache
echo "Cleaning CocoaPods cache..."
rm -rf ~/Library/Caches/CocoaPods
pod cache clean --all || true

# 5. Flutter pub get
echo "Getting Flutter dependencies..."
flutter pub get

# 6. Patch Podfile.lock if it exists
if [ -f "ios/Podfile.lock" ]; then
  echo "Patching Podfile.lock to remove -G flags..."
  perl -i.bak -pe 's/-G\S*\s?//g' ios/Podfile.lock
fi

# 7. Run pod installation with special options
echo "Installing pods with special options..."
cd ios
export LANG=en_US.UTF-8
export COCOAPODS_DISABLE_STATS=true
pod deintegrate

# Use pod-install with specific compiler flags for this platform
export OTHER_CFLAGS=""
pod install --verbose

# 8. Patch xcconfig files to remove -G flags
echo "Scanning for problematic compiler flags in xcconfig files..."
find . -name "*.xcconfig" -exec perl -i.bak -pe 's/-G\S*\s?//g' {} \;
find . -name "*.xcconfig.bak" -delete

# 9. Fix project.pbxproj file
if [ -f "Pods/Pods.xcodeproj/project.pbxproj" ]; then
  echo "Fixing project.pbxproj file..."
  perl -i.bak -pe 's/-G\S*\s?//g' "Pods/Pods.xcodeproj/project.pbxproj"
  rm -f "Pods/Pods.xcodeproj/project.pbxproj.bak"
fi

cd ..

echo "===== Deep clean complete ====="
echo "Now run 'flutter run' to build the app."
echo "If the build still fails, try:"
echo "  - Running on a different iOS simulator version"
echo "  - Updating CocoaPods with 'sudo gem install cocoapods'"
echo "  - Or try running the app on an Android device for now"
