#!/bin/bash

# Script to fix Dart compilation errors
echo "===== Fixing Dart compilation errors ====="

# Clean Flutter build 
echo "Cleaning Flutter project..."
flutter clean

# Get fresh dependencies
echo "Getting dependencies..."
flutter pub get

# Run dart analyzer to catch any other issues
echo "Running Dart analyzer..."
flutter analyze

echo "===== Fix complete ====="
echo "Try running the app now with: flutter run"