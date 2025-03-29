#!/bin/bash

# Script to fix compiler flag issues with iOS build
echo "===== Fixing iOS compiler flag issues ====="

# Remove derived data to force full rebuild
echo "Removing Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean Flutter build
echo "Cleaning Flutter build..."
flutter clean

# Remove Pods to force recreation
echo "Removing Pods directory..."
rm -rf ios/Pods
rm -rf ios/Podfile.lock

# Get fresh dependencies
echo "Getting dependencies..."
flutter pub get

# Run pod installation with new flags
echo "Installing pods with fixed compiler flags..."
cd ios
pod install --repo-update
cd ..

echo "===== Fix complete ====="
echo "Try running the app now with: flutter run"