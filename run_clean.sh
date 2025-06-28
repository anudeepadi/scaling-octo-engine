#!/bin/bash

# QuiTXT Clean Run Script
# This script runs the app with minimal debug output to show only clean message history

echo "🚀 Starting QuiTXT with clean message history..."
echo "📱 Debug logging disabled for clean UI experience"
echo ""

# Run Flutter app on iOS simulator
flutter run --release 2>&1 | grep -E "(flutter:|Welcome|Message:|Error|Warning)" | grep -v -E "(DashChatProvider|ChatProvider|Firestore|FCM|Performance|Debug|print)"

# Alternative: Run with custom filtering
# flutter run 2>&1 | awk '!/DashChatProvider|ChatProvider|Firestore|FCM|Performance|Debug/ {print}' 