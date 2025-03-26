#!/bin/bash

# Stop on errors
set -e

echo "===== Comprehensive iOS build fix for Firebase modular headers ====="
cd "$(dirname "$0")"

# 1. Fix Podfile
echo "1. Creating fixed Podfile..."
cat > ios/Podfile <<EOL
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
    
    # Apply fixes to all targets
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      
      # Disable checking for non-modular includes in framework modules for all targets
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      
      # Disable warnings for quoted include in framework header
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
      
      # Define all targets as modules
      config.build_settings['DEFINES_MODULE'] = 'YES'
      
      # These settings fix some Xcode 14+ issues
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
      config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
      config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
      
      # Allow frameworks in app extension (Firebase needs this)
      config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'NO'
    end
  end
end
EOL

# 2. Patch the Firebase header files
echo "2. Patching Firebase plugin header files..."
STORAGE_HEADER="$HOME/.pub-cache/hosted/pub.dev/firebase_storage-11.6.5/ios/Classes/FLTTaskStateChannelStreamHandler.h"
MESSAGING_HEADER="$HOME/.pub-cache/hosted/pub.dev/firebase_messaging-14.7.10/ios/Classes/FLTFirebaseMessagingPlugin.h"

if [ -f "$STORAGE_HEADER" ] && [ -w "$STORAGE_HEADER" ]; then
  echo "Patching $STORAGE_HEADER"
  sed -i '' 's/#import <Firebase\/Firebase.h>/@import FirebaseStorage;/' "$STORAGE_HEADER"
fi

if [ -f "$MESSAGING_HEADER" ] && [ -w "$MESSAGING_HEADER" ]; then
  echo "Patching $MESSAGING_HEADER"
  sed -i '' 's/#import <Firebase\/Firebase.h>/@import FirebaseMessaging;/' "$MESSAGING_HEADER"
fi

# 3. Update Flutter config files
echo "3. Updating Flutter configuration files..."

# Update Debug.xcconfig
XCCONFIG_FILE="ios/Flutter/Debug.xcconfig"
if [ -f "$XCCONFIG_FILE" ]; then
  if ! grep -q "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" "$XCCONFIG_FILE"; then
    echo "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES=YES" >> "$XCCONFIG_FILE"
    echo "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER=NO" >> "$XCCONFIG_FILE"
  fi
fi

# Update Release.xcconfig
XCCONFIG_FILE="ios/Flutter/Release.xcconfig"
if [ -f "$XCCONFIG_FILE" ]; then
  if ! grep -q "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" "$XCCONFIG_FILE"; then
    echo "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES=YES" >> "$XCCONFIG_FILE"
    echo "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER=NO" >> "$XCCONFIG_FILE"
  fi
fi

# 4. Clean the project thoroughly
echo "4. Performing complete cleanup..."
flutter clean

rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec
rm -rf ios/Flutter/ephemeral
rm -f ios/Podfile.lock

flutter pub get

# 5. Reinstall pods
echo "5. Reinstalling pods with fixed configuration..."
cd ios
pod deintegrate
pod install --repo-update

echo "===== Done! ====="
echo "You can now try 'flutter run' again."