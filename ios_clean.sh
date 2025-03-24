#!/bin/bash

# Stop on errors
set -e

echo "===== Cleaning Flutter project ====="
cd "$(dirname "$0")"
flutter clean

echo "===== Removing iOS build artifacts ====="
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec
rm -rf ios/Flutter/ephemeral
rm -f ios/Podfile.lock

echo "===== Getting Flutter dependencies ====="
flutter pub get

echo "===== Running pod deintegrate ====="
cd ios
pod deintegrate

echo "===== Running pod install with repo update ====="
pod install --repo-update

echo "===== Done! ====="
echo "You can now try 'flutter run' again."
