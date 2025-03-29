#!/bin/bash
# Clean Xcode caches and build artifacts

echo "Cleaning Flutter project..."
flutter clean

echo "Removing Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo "Removing Xcode module cache..."
rm -rf ~/Library/Developer/Xcode/ModuleCache.noindex/*

echo "Removing Xcode SDK stat cache..."
rm -rf ~/Library/Developer/Xcode/SDKStatCaches.noindex/*

echo "Cleaning iOS project..."
cd ios
rm -f Podfile.lock
rm -rf Pods
rm -rf .symlinks

echo "Reinstalling pods..."
pod deintegrate
pod setup
pod install --repo-update

echo "Cleaning complete!"
cd ..
