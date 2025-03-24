#!/bin/bash

# Clean iOS build files and reinstall pods
echo "===== Cleaning iOS build files ====="
cd ios
rm -rf Pods
rm -rf .symlinks
rm -f Podfile.lock

echo "===== Installing pods ====="
pod install

echo "===== Done! ====="
echo "Now you can run 'flutter run' to build your app"
