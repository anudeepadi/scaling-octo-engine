#!/bin/bash

# Script to clean Xcode cache thoroughly

echo "===== Cleaning Xcode cache ====="

# Stop Xcode if it's running
echo "Closing Xcode if open..."
killall Xcode || true
sleep 2

# Clean DerivedData
echo "Removing Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Clean Module Cache
echo "Removing Module Cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/

# Clean SDK Stat Caches
echo "Removing SDK Stat Caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/

# Clean iOS Device Support
echo "Cleaning iOS Device Support..."
rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/*

# Clean Xcode archives
echo "Cleaning Xcode archives..."
rm -rf ~/Library/Developer/Xcode/Archives/*

echo "===== Cleaning Flutter and iOS project artifacts ====="

# Clean Flutter
echo "Running Flutter clean..."
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

# Reinstall pods
echo "Reinstalling pods..."
pod deintegrate
pod install

echo "===== Done! ====="
echo "Try running 'flutter run' again"
