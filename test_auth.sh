#!/bin/bash

echo "🔍 Android Authentication Troubleshooting Script"
echo "==============================================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Run this script from the Flutter project root directory"
    exit 1
fi

echo "📱 Checking Android setup..."

# Check if Android SDK is available
if ! command -v adb &> /dev/null; then
    echo "⚠️  Warning: ADB not found in PATH"
else
    echo "✅ ADB found"
    
    # List connected devices
    echo "📱 Connected devices:"
    adb devices
fi

echo ""
echo "🧹 Cleaning project..."
flutter clean
flutter pub get

echo ""
echo "🔥 Checking Firebase configuration..."

# Check if google-services.json exists
if [ -f "android/app/google-services.json" ]; then
    echo "✅ google-services.json found"
    
    # Extract project info
    PROJECT_ID=$(grep '"project_id"' android/app/google-services.json | cut -d'"' -f4)
    echo "📋 Project ID: $PROJECT_ID"
else
    echo "❌ google-services.json not found in android/app/"
    echo "   Download it from Firebase Console and place it in android/app/"
fi

# Check if GoogleService-Info.plist exists for iOS
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "✅ GoogleService-Info.plist found"
else
    echo "⚠️  GoogleService-Info.plist not found in ios/Runner/"
fi

echo ""
echo "🌐 Testing network connectivity..."

# Test basic connectivity
if curl -s --connect-timeout 5 https://www.google.com > /dev/null; then
    echo "✅ Internet connection working"
else
    echo "❌ No internet connection"
    exit 1
fi

# Test Firebase endpoints
FIREBASE_ENDPOINTS=(
    "https://firebase.googleapis.com"
    "https://identitytoolkit.googleapis.com" 
    "https://securetoken.googleapis.com"
)

for endpoint in "${FIREBASE_ENDPOINTS[@]}"; do
    if curl -s --connect-timeout 5 "$endpoint" > /dev/null; then
        echo "✅ $endpoint - reachable"
    else
        echo "❌ $endpoint - unreachable"
    fi
done

echo ""
echo "🔧 Building and testing..."

# Build for Android
echo "Building Android APK..."
if flutter build apk --debug; then
    echo "✅ Android build successful"
else
    echo "❌ Android build failed"
    exit 1
fi

echo ""
echo "🚀 Ready to test!"
echo ""
echo "Next steps:"
echo "1. Connect your Android device via USB"
echo "2. Enable USB debugging on your device"
echo "3. Run: flutter run -d android"
echo "4. Test authentication in the app"
echo "5. Check logs with: flutter logs"
echo ""
echo "If using emulator:"
echo "1. Ensure emulator has Google Play Services"
echo "2. Use emulator with API 28+ and Google Play"
echo "3. Consider testing on a real device for best results" 