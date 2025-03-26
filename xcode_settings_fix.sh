#!/bin/bash

# This script updates the Xcode project settings to fix the Firebase modular header issues

echo "===== Fixing Xcode project settings for Firebase ====="

# Navigate to the project directory
cd "$(dirname "$0")"

# Fix the source files
echo "1. Patching Firebase plugin source files..."
STORAGE_HEADER="$HOME/.pub-cache/hosted/pub.dev/firebase_storage-11.6.5/ios/Classes/FLTTaskStateChannelStreamHandler.h"
MESSAGING_HEADER="$HOME/.pub-cache/hosted/pub.dev/firebase_messaging-14.7.10/ios/Classes/FLTFirebaseMessagingPlugin.h"

if [ -f "$STORAGE_HEADER" ] && [ -w "$STORAGE_HEADER" ]; then
  echo "Patching $STORAGE_HEADER"
  sed -i '' 's/#import <Firebase\/Firebase.h>/@import FirebaseCore; @import FirebaseStorage;/' "$STORAGE_HEADER"
fi

if [ -f "$MESSAGING_HEADER" ] && [ -w "$MESSAGING_HEADER" ]; then
  echo "Patching $MESSAGING_HEADER"
  sed -i '' 's/#import <Firebase\/Firebase.h>/@import FirebaseCore; @import FirebaseMessaging;/' "$MESSAGING_HEADER"
fi

# Create Podfile with modular imports settings
echo "2. Creating fixed Podfile with modular imports..."
cat > ios/Podfile.alt <<EOL
# Uncomment this line to define a global platform for your project
platform :ios, '12.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        # Fix modular header issues
        config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
        config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
        config.build_settings['DEFINES_MODULE'] = 'YES'
        config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'NO'
      end
    end
  end

  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Specifically fix BoringSSL-GRPC -G compiler flag issue
    if target.name == 'BoringSSL-GRPC'
      target.source_build_phase.files.each do |file|
        if file.settings && file.settings['COMPILER_FLAGS']
          flags = file.settings['COMPILER_FLAGS'].split
          flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
          file.settings['COMPILER_FLAGS'] = flags.join(' ')
        end
      end
    end
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      
      # Fix modular header issues
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
      
      # Other compatibility fixes
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
      config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
      config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
    end
  end
end
EOL

# Save the original Podfile
cp ios/Podfile ios/Podfile.orig
cp ios/Podfile.alt ios/Podfile

# Clean the project
echo "3. Cleaning the project..."
flutter clean

# Manually clean up iOS specific files
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec
rm -rf ios/Flutter/ephemeral
rm -f ios/Podfile.lock

# Add special setting to Flutter configs
echo "4. Updating Flutter configuration files..."
echo "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES=YES" >> ios/Flutter/Debug.xcconfig
echo "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER=NO" >> ios/Flutter/Debug.xcconfig
echo "DEFINES_MODULE=YES" >> ios/Flutter/Debug.xcconfig

echo "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES=YES" >> ios/Flutter/Release.xcconfig
echo "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER=NO" >> ios/Flutter/Release.xcconfig
echo "DEFINES_MODULE=YES" >> ios/Flutter/Release.xcconfig

# Get Flutter dependencies
echo "5. Getting Flutter dependencies..."
flutter pub get

# Run the deep clean script for iOS
echo "6. Running deep clean for iOS..."
(cd ios && pod deintegrate)
(cd ios && pod install --repo-update)

echo "===== Done! ====="
echo "The Xcode project settings have been fixed. Try running 'flutter run' again."
echo ""
echo "If you still encounter issues, try opening the project in Xcode and manually setting:"
echo "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = YES"
echo "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = NO"
echo "for all build targets."