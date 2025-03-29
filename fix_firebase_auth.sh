#!/bin/bash

# Script to fix Firebase/Auth version issues
echo "===== Fixing Firebase/Auth version issues ====="

# Remove Podfile.lock to force regeneration
if [ -f "ios/Podfile.lock" ]; then
    echo "Removing Podfile.lock..."
    rm ios/Podfile.lock
fi

# Run pod repo update to refresh specs
echo "Updating CocoaPods specs repository..."
pod repo update

# Update the specific Firebase pods
echo "Updating Firebase pods..."
cd ios
pod update Firebase/Auth Firebase/Firestore
pod install
cd ..

echo "===== Fix complete ====="
echo "Try running the app now with: flutter run"