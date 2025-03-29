#!/bin/bash

# Script to run the app and handle common issues

echo "====== RCS Application Launch Script ======"

# Check if pod is installed
if ! command -v pod &> /dev/null; then
    echo "CocoaPods is not installed. Please install it with: sudo gem install cocoapods"
    exit 1
fi

# First attempt to run the app
echo "Attempting to run the app..."
OUTPUT=$(flutter run 2>&1)
EXIT_CODE=$?

# If it fails, analyze the error
if [ $EXIT_CODE -ne 0 ]; then
    echo "Initial run failed. Checking for specific issues..."
    echo "$OUTPUT" | tail -20  # Show last 20 lines of output for debugging
    
    # Check for compiler flag issue
    if grep -q "unsupported option '-G'" <<< "$OUTPUT"; then
        echo "Detected compiler flag issue. Running fix_compiler_flags.sh..."
        bash fix_compiler_flags.sh
        
        echo "Attempting to run the app again after fixing compiler flags..."
        flutter run
        exit $?
    fi
    
    # Check for CocoaPods issues
    if grep -q "could not find compatible versions" <<< "$OUTPUT" || grep -q "pod repo update" <<< "$OUTPUT"; then
        echo "Found CocoaPods compatibility issues. Attempting to fix..."
        
        # Check if Podfile.lock exists
        if [ -f "ios/Podfile.lock" ]; then
            echo "Found Podfile.lock, removing it to force regeneration..."
            rm ios/Podfile.lock
        fi
        
        echo "Running pod repo update..."
        cd ios && pod repo update && cd ..
        
        echo "Running pod install with repo update..."
        cd ios && pod install --repo-update && cd ..
        
        echo "Attempting to run the app again after CocoaPods update..."
        flutter run
        
        # If it still fails, suggest using the iOS reset script
        if [ $? -ne 0 ]; then
            echo "=============================================="
            echo "App still fails to run. Try the iOS reset script:"
            echo "bash ios_reset.sh"
            echo "=============================================="
            exit 1
        fi
        
        exit 0
    fi
    
    # If we got here, it's a different issue
    echo "=============================================="
    echo "App failed to run with an unrecognized issue."
    echo "Try the full reset scripts:"
    echo "bash ios_reset.sh"
    echo "or:"
    echo "bash fix_compiler_flags.sh"
    echo "=============================================="
    exit 1
fi