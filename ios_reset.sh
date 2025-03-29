#!/bin/bash

# iOS build reset script for Flutter
# Run this when you have dependency conflicts with CocoaPods

# Print commands as they're executed
set -x

echo "===== Removing Xcode derived data ====="
rm -rf ~/Library/Developer/Xcode/DerivedData

echo "===== Removing CocoaPods cache ====="
rm -rf ~/.cocoapods/repos/*
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec
rm -rf ios/Flutter/Generated.xcconfig
rm -rf ios/Flutter/App.framework
rm -rf ios/Podfile.lock

echo "===== Updating CocoaPods ====="
pod repo update

echo "===== Getting Flutter dependencies ====="
flutter pub get

echo "===== Running pod install with repo update ====="
cd ios
pod update Firebase/Auth Firebase/Firestore --no-repo-update
pod install --repo-update
cd ..

# If still having issues, try downgrading Firebase packages
if [ $? -ne 0 ]; then
  echo "===== First attempt failed, trying with forced removal of Firebase specs ====="
  rm -rf ~/.cocoapods/repos/trunk/Specs/0/3/5/Firebase/
  pod repo update
  cd ios
  pod install --repo-update
  cd ..
fi

echo "===== iOS build reset complete ====="
echo "You can now run 'flutter run'"