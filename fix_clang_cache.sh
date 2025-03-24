#!/bin/bash

# Script to fix ClangStatCache issues

echo "===== Fixing ClangStatCache issues ====="

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
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
rm -rf ~/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex
mkdir -p ~/Library/Developer/Xcode/DerivedData

# Set permissions on DerivedData
echo "Setting permissions on DerivedData directory..."
chmod -R 755 ~/Library/Developer/Xcode/DerivedData

# Reset iOS simulators
echo "Resetting iOS Simulators..."
xcrun simctl shutdown all
xcrun simctl erase all

# Remove project specific build files
echo "Cleaning project build files..."
cd "$(dirname "$0")"
rm -rf ios/build
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf build

# Run Flutter clean
echo "Running Flutter clean..."
flutter clean

# Set up project again
echo "Setting up project again..."
flutter pub get

# Fix iOS build
echo "Reinstalling pods with specific settings..."
cd ios
rm -f Podfile.lock
export LANG=en_US.UTF-8

# Try using arch command for Intel compilation (can help with M1/M2 Macs)
echo "Installing pods with architecture-specific settings..."
arch -x86_64 pod install || pod install

# Go back to project root
cd ..

echo "===== Done! ====="
echo "Try running the app with:"
echo "flutter run --verbose"
echo ""
echo "If it still fails, try opening the workspace in Xcode and building there:"
echo "open ios/Runner.xcworkspace"
