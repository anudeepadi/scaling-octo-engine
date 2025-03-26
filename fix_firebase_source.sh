#!/bin/bash

# Stop on errors
set -e

echo "===== Fixing Firebase source files ====="
cd "$(dirname "$0")"

# Create a symlink to the Firebase headers if they don't exist
echo "Creating Firebase header symlinks..."
mkdir -p ios/Runner/Firebase
cd ios/Runner/Firebase

# Create header file with module import
cat > Firebase.h <<EOF
// Firebase.h module wrapper
// This is a workaround for the non-modular header issue in Flutter plugins

#ifndef Firebase_h
#define Firebase_h

@import FirebaseCore;
@import FirebaseMessaging;
@import FirebaseAuth;
@import FirebaseStorage;

#endif /* Firebase_h */
EOF

cd ../../..

# Create patch files for the Flutter plugins
echo "Creating patch for firebase_storage..."
mkdir -p patches
cat > patches/firebase_storage.patch <<EOF
--- FLTTaskStateChannelStreamHandler.h
+++ FLTTaskStateChannelStreamHandler.h
@@ -9,7 +9,7 @@
 #import <Flutter/Flutter.h>
 #endif
 
-#import <Firebase/Firebase.h>
+@import FirebaseStorage;
 
 #import <Foundation/Foundation.h>
 
EOF

echo "Creating patch for firebase_messaging..."
cat > patches/firebase_messaging.patch <<EOF
--- FLTFirebaseMessagingPlugin.h
+++ FLTFirebaseMessagingPlugin.h
@@ -9,7 +9,7 @@
 #import <Flutter/Flutter.h>
 #endif
 
-#import <Firebase/Firebase.h>
+@import FirebaseMessaging;
 #import <Foundation/Foundation.h>
 #import <UserNotifications/UserNotifications.h>
 #import <firebase_core/FLTFirebasePlugin.h>
EOF

# Apply the patches if possible
echo "Applying patches to the plugin source files (if accessible)..."
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

echo "===== Running pod deintegrate and reinstall ====="
cd ios
pod deintegrate
pod install --repo-update

# Update xcconfig to use modular headers
echo "Updating build settings to support modular headers..."
XCCONFIG_FILE="Flutter/Debug.xcconfig"
if [ -f "$XCCONFIG_FILE" ]; then
  if ! grep -q "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" "$XCCONFIG_FILE"; then
    echo "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES=YES" >> "$XCCONFIG_FILE"
  fi
fi

XCCONFIG_FILE="Flutter/Release.xcconfig"
if [ -f "$XCCONFIG_FILE" ]; then
  if ! grep -q "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" "$XCCONFIG_FILE"; then
    echo "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES=YES" >> "$XCCONFIG_FILE"
  fi
fi

echo "===== Done! ====="
echo "You can now try 'flutter run' again."