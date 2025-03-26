#!/bin/bash

# Fix Firebase Messaging header files
FIREBASE_MESSAGING_PATH="$HOME/.pub-cache/hosted/pub.dev/firebase_messaging-14.7.10/ios/Classes/FLTFirebaseMessagingPlugin.h"

# Apply the patch directly
sed -i '' -e '15i\
@import FirebaseAuth;
' "$FIREBASE_MESSAGING_PATH"

echo "Firebase header files patched successfully."