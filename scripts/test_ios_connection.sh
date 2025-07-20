#!/bin/bash
# Script to test iOS connection issues with the new optimizations
# Run this script from the project root directory

echo "=== iOS Connection Test Script (With Optimizations) ==="
echo "This script will help diagnose iOS connection issues and apply optimizations"
echo

# Check if we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ This script must be run on macOS for iOS testing"
  exit 1
fi

# Check if iOS device is connected
echo "Checking for connected iOS devices..."
IOS_DEVICE=$(xcrun xctrace list devices 2>/dev/null | grep -v "Simulator" | grep -v "=" | grep "iPhone\|iPad" | head -1 | awk '{print $NF}' | tr -d '()')

if [[ -z "$IOS_DEVICE" ]]; then
  echo "No physical iOS device detected. Checking for simulators..."
  IOS_SIMULATOR=$(xcrun simctl list devices available | grep "iPhone\|iPad" | grep "Booted" | head -1 | awk -F'[()]' '{print $2}')
  
  if [[ -z "$IOS_SIMULATOR" ]]; then
    echo "❌ No running iOS simulator detected."
    echo "Available Simulators:"
    xcrun simctl list devices available | grep "iPhone\|iPad"
    echo
    echo "Please start a simulator with: xcrun simctl boot <DEVICE_ID>"
    exit 1
  else
    echo "✅ Found iOS simulator: $IOS_SIMULATOR"
    IOS_DEVICE=$IOS_SIMULATOR
  fi
else
  echo "✅ Found iOS device: $IOS_DEVICE"
fi

# Check if the optimizations files exist
if [[ ! -f "lib/utils/ios_performance_utils.dart" ]]; then
  echo "❌ iOS performance optimizations file not found!"
  echo "Please make sure you've implemented the optimizations."
  exit 1
fi

# Check if server is running
echo "Testing ngrok connection..."
NGROK_URL="https://dashmessaging-com.ngrok.io/scheduler/mobile-app"

if curl -s --head -m 5 $NGROK_URL >/dev/null; then
  echo "✅ Server is reachable at $NGROK_URL"
else
  echo "❌ Cannot reach server at $NGROK_URL"
  echo "Checking internet connection..."
  
  if curl -s --head -m 5 https://www.google.com >/dev/null; then
    echo "✅ Internet connection is working"
    echo "⚠️ Issue is specific to the ngrok server"
    echo "1. Check if ngrok tunnel is running"
    echo "2. Verify ngrok subdomain is correct"
    
    # Try HTTP version as fallback
    HTTP_URL=${NGROK_URL/https/http}
    echo "Trying HTTP fallback URL: $HTTP_URL"
    if curl -s --head -m 5 $HTTP_URL >/dev/null; then
      echo "✅ HTTP fallback URL is reachable!"
      echo "This suggests an HTTPS issue. The app will try HTTP fallback automatically."
    else
      echo "❌ HTTP fallback URL is also not reachable."
    fi
  else
    echo "❌ Internet connection appears to be down"
    echo "Please check your network settings"
  fi
fi

# Enable debug logging
echo "Enabling verbose logging..."
sed -i.bak "s/static const bool _enableDebugLogging = false;/static const bool _enableDebugLogging = true;/" lib/utils/debug_config.dart

# Run the app with optimizations
echo
echo "Would you like to run the app with iOS optimizations? (y/n)"
read -r RUN_APP

if [[ "$RUN_APP" == "y" ]]; then
  echo "Running app with iOS optimizations..."
  echo "Looking for iOS device..."
  
  # Create a temporary main file with forced optimizations
  cp lib/main.dart lib/main.dart.bak
  sed -i '' 's/if (Platform.isIOS) {/if (true) { \/\/ Force iOS optimizations/' lib/main.dart
  
  # Run the app and capture logs
  flutter run -d "$IOS_DEVICE" --verbose 2>&1 | tee ios_optimized_logs.txt
  
  # Restore original files
  mv lib/main.dart.bak lib/main.dart
  mv lib/utils/debug_config.dart.bak lib/utils/debug_config.dart
  
  echo "Logs saved to ios_optimized_logs.txt"
  echo "Analyzing logs for performance metrics..."
  
  # Extract performance metrics
  echo
  echo "=== Performance Metrics ==="
  grep "performance" ios_optimized_logs.txt
  grep "INSTANT" ios_optimized_logs.txt | wc -l | xargs echo "INSTANT operations:"
  grep "Connection test completed in" ios_optimized_logs.txt
  grep "Initial message loading" ios_optimized_logs.txt
  echo "=========================="
fi

echo
echo "=== Connection Test Complete ==="
echo "For more information, see IOS_PERFORMANCE_OPTIMIZATIONS.md" 