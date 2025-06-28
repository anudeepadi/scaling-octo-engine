#!/bin/bash

# Quick Setup Script for Testing Deployment

echo "🚀 RCS App Testing Setup"
echo "======================="

# Function to setup iOS
setup_ios() {
    echo "📱 Setting up iOS TestFlight..."
    
    # Check if fastlane is installed
    if ! command -v fastlane &> /dev/null; then
        echo "Installing fastlane..."
        sudo gem install fastlane -NV
    fi
    
    # Create fastlane directory
    mkdir -p ios/fastlane
    
    # Initialize fastlane for iOS
    cd ios
    fastlane init
    cd ..
    
    echo "✅ iOS setup complete!"
}

# Function to setup Android
setup_android() {
    echo "🤖 Setting up Android Play Store..."
    
    # Create fastlane directory
    mkdir -p android/fastlane
    
    # Initialize fastlane for Android
    cd android
    fastlane init
    cd ..
    
    echo "✅ Android setup complete!"
}

# Function to create deployment scripts
create_scripts() {
    echo "📝 Creating deployment scripts..."
    
    # Create deploy script
    cat > deploy.sh << 'EOF'
#!/bin/bash

# Deploy script
PLATFORM=$1
STAGE=$2

if [ "$PLATFORM" == "ios" ]; then
    echo "🍎 Deploying to iOS $STAGE..."
    cd ios
    fastlane $STAGE
    cd ..
elif [ "$PLATFORM" == "android" ]; then
    echo "🤖 Deploying to Android $STAGE..."
    cd android
    fastlane $STAGE
    cd ..
elif [ "$PLATFORM" == "both" ]; then
    echo "📱 Deploying to both platforms $STAGE..."
    cd ios
    fastlane $STAGE
    cd ..
    cd android
    fastlane $STAGE
    cd ..
else
    echo "Usage: ./deploy.sh [ios|android|both] [internal|beta]"
fi
EOF
    
    chmod +x deploy.sh
    
    # Create version bump script
    cat > bump_version.sh << 'EOF'
#!/bin/bash

# Get current version
current_version=$(grep "version:" pubspec.yaml | sed 's/version: //')
version_name=$(echo $current_version | cut -d'+' -f1)
build_number=$(echo $current_version | cut -d'+' -f2)

# Increment build number
new_build_number=$((build_number + 1))

# Update pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/version: .*/version: $version_name+$new_build_number/" pubspec.yaml
else
    # Linux
    sed -i "s/version: .*/version: $version_name+$new_build_number/" pubspec.yaml
fi

echo "✅ Version bumped to $version_name+$new_build_number"
EOF
    
    chmod +x bump_version.sh
    
    echo "✅ Scripts created!"
}

# Main menu
echo ""
echo "What would you like to setup?"
echo "1) iOS TestFlight"
echo "2) Android Play Store"
echo "3) Both platforms"
echo "4) Just create deployment scripts"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        setup_ios
        create_scripts
        ;;
    2)
        setup_android
        create_scripts
        ;;
    3)
        setup_ios
        setup_android
        create_scripts
        ;;
    4)
        create_scripts
        ;;
    *)
        echo "Invalid choice!"
        exit 1
        ;;
esac

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure your Apple/Google credentials"
echo "2. Run: ./bump_version.sh (to increment build number)"
echo "3. Run: ./deploy.sh ios internal (for iOS internal testing)"
echo "4. Run: ./deploy.sh android internal (for Android internal testing)"
echo "5. Run: ./deploy.sh both beta (for beta testing on both platforms)"
