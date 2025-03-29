#!/bin/bash

# Script to fix BoringSSL-GRPC compilation issues
echo "===== Fixing BoringSSL-GRPC compilation issues ====="

# Clean derived data
echo "Cleaning Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Remove Pods directory and cache
echo "Removing Pods directory and cache..."
cd ios
rm -rf Pods
rm -rf Podfile.lock
cd ..

# Update CocoaPods repositories
echo "Updating CocoaPods repositories..."
pod repo update

# Get Flutter dependencies
echo "Getting Flutter dependencies..."
flutter clean
flutter pub get

# Install pods with updated configuration
echo "Installing pods with updated configuration..."
cd ios
pod install --repo-update
cd ..

# Set Xcode build setting
echo "Note: You may also need to manually set ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = YES in Xcode:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Select Runner from TARGETS"
echo "3. Go to Build Settings tab"
echo "4. Search for 'ALLOW_NON_MODULAR_INCLUDES'"
echo "5. Set it to YES"

echo "===== Fix complete ====="
echo "Try running the app now with: flutter run"