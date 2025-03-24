#!/bin/bash

# Full rebuild script for iOS with alternative Podfile

echo "===== Starting full iOS rebuild process ====="

# Stop Xcode and related processes
echo "Closing Xcode and related processes..."
killall Xcode || true
killall "Xcode Helper" || true
killall "xcodebuild" || true
killall "iOS Simulator" || true
killall "Simulator" || true
sleep 2

# Remove Xcode caches
echo "Removing Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode
mkdir -p ~/Library/Developer/Xcode/DerivedData

# Clean Flutter
echo "Cleaning Flutter project..."
flutter clean

# Clean iOS specific files
echo "Cleaning iOS build files..."
cd ios
rm -rf Pods
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec
rm -rf .xcodebuild
rm -rf build
rm -f Podfile.lock

# Backup original Podfile and use alternative
echo "Using alternative Podfile..."
if [ ! -f "Podfile.original" ]; then
  cp Podfile Podfile.original
fi

cp Podfile.nobuild Podfile

# Update CocoaPods repositories
echo "Updating CocoaPods repositories..."
pod repo update

# Install pods with specific settings
echo "Installing pods with alternative settings..."
export LANG=en_US.UTF-8
export CLANG_STATCACHE_DISABLE=YES
export CLANG_ENABLE_COMPILE_CACHE=NO

# Try using arch command for Intel compilation (can help with M1/M2 Macs)
echo "Installing pods with architecture-specific settings..."
arch -x86_64 pod install || pod install

# Go back to project root
cd ..

echo "===== Done! ====="
echo "Try running the app with: flutter run"
echo ""
echo "If it still fails, open in Xcode and try building there:"
echo "open ios/Runner.xcworkspace"
echo ""
echo "To restore the original Podfile:"
echo "cd ios && cp Podfile.original Podfile && cd .."
