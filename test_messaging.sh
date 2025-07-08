#!/bin/bash

# QuitTXT Messaging System Test Script
# This script helps verify that the messaging fixes are working correctly

echo "🧪 QuitTXT Messaging System Test"
echo "================================="
echo ""

# Check if Flutter is installed
echo "📱 Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

flutter --version
echo ""

# Clean and get dependencies
echo "🧹 Cleaning project and getting dependencies..."
flutter clean
flutter pub get

# Check for any obvious compilation errors
echo "🔍 Checking for compilation errors..."
flutter analyze --fatal-infos

if [ $? -ne 0 ]; then
    echo "❌ Compilation errors detected. Please fix them before proceeding."
    exit 1
fi

echo "✅ No compilation errors detected"
echo ""

# Check if required files exist
echo "📋 Checking required configuration files..."

required_files=(
    "lib/providers/dash_chat_provider.dart"
    "lib/services/dash_messaging_service.dart"
    "lib/screens/home_screen.dart"
    "lib/main.dart"
    "google-services.json"
    "GoogleService-Info.plist"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file is missing"
    fi
done

echo ""

# Check for specific fixes in the code
echo "🔧 Verifying messaging fixes..."

# Check for WidgetsBindingObserver in HomeScreen
if grep -q "WidgetsBindingObserver" lib/screens/home_screen.dart; then
    echo "✅ WidgetsBindingObserver properly implemented in HomeScreen"
else
    echo "❌ WidgetsBindingObserver missing in HomeScreen"
fi

# Check for diagnostic test methods
if grep -q "runDiagnosticTest" lib/providers/dash_chat_provider.dart; then
    echo "✅ Diagnostic test method available in DashChatProvider"
else
    echo "❌ Diagnostic test method missing in DashChatProvider"
fi

# Check for proper subscription handling
if grep -q "StreamSubscription" lib/services/dash_messaging_service.dart; then
    echo "✅ Stream subscription handling implemented"
else
    echo "❌ Stream subscription handling may be missing"
fi

# Check for reinitializeService method
if grep -q "reinitializeService" lib/providers/dash_chat_provider.dart; then
    echo "✅ Service reinitialization method available"
else
    echo "❌ Service reinitialization method missing"
fi

echo ""

# Instructions for manual testing
echo "📝 Manual Testing Instructions:"
echo "================================"
echo ""
echo "1. 🚀 Build and run the app:"
echo "   flutter run"
echo ""
echo "2. 🔐 Sign in with your test account"
echo ""
echo "3. 🧪 Run diagnostic test:"
echo "   - Tap the bug report icon (🐛) in the app bar"
echo "   - Check the diagnostic results"
echo "   - If any issues, use 'Retry Setup' button"
echo ""
echo "4. 💬 Test messaging:"
echo "   - Send a test message"
echo "   - Check if it appears in the chat"
echo "   - Verify server communication in logs"
echo ""
echo "5. 🔄 Test app lifecycle:"
echo "   - Put app in background"
echo "   - Bring it back to foreground"
echo "   - Check for message refresh"
echo ""
echo "6. 📱 Check logs for errors:"
echo "   flutter logs | grep -E 'DashChatProvider|DashMessagingService|SendMessage'"
echo ""

# Log file check
echo "📋 Recent log analysis:"
if [ -f "dash_messaging_test.log" ]; then
    echo "Found existing log file. Last 10 lines:"
    tail -n 10 dash_messaging_test.log
else
    echo "No existing log file found (this is normal for first run)"
fi

echo ""
echo "🎯 Expected Behavior After Fixes:"
echo "=================================="
echo "✅ Messages should send without duplicates"
echo "✅ No more 'type mismatch' errors"
echo "✅ Proper subscription cleanup on dispose"
echo "✅ App lifecycle events handled correctly"
echo "✅ Diagnostic test shows service connectivity"
echo "✅ Server communication works reliably"
echo ""

echo "🔧 If you still experience issues:"
echo "1. Use the diagnostic test in the app"
echo "2. Check network connectivity"
echo "3. Verify server URL configuration"
echo "4. Check Firebase project settings"
echo "5. Review Flutter logs for specific errors"
echo ""

echo "✅ Test script completed!"
echo "Run 'flutter run' to start testing the app." 