#!/bin/bash

# Test script for message alignment fix verification

echo "🔧 Message Alignment Fix Test Script"
echo "====================================="
echo ""

echo "📱 Step 1: Building and running the app..."
echo "Run this command to start the app:"
echo "flutter run"
echo ""

echo "🧪 Step 2: Test the alignment fix and message shifting"
echo "1. Open the app and sign in"
echo "2. Navigate to the messaging screen"
echo "3. Look at your message history - user messages should be on the RIGHT"
echo "4. Tap the alignment test button (horizontal align icon) in the action bar"
echo "5. Tap the message shifting test button (swap vertical icon) to test shifting"
echo "6. Tap the toggle button to enable/disable message shifting"
echo "7. Check the console logs for test results"
echo ""

echo "🔍 Step 3: Look for these log messages:"
echo "- '📍 Message alignment check: ... -> isMe: true (source: \"client\", ...)' for user messages"
echo "- '📍 Message alignment check: ... -> isMe: false (source: \"server\", ...)' for server messages"
echo "- '📋 Message alignment test results:' followed by alignment status for each message"
echo "- '🔄 Testing message shifting functionality...' for shifting tests"
echo "- 'Applied message shifting: X -> Y messages' when shifting is applied"
echo ""

echo "✅ Expected Results:"
echo "- User messages: isMe: true → RIGHT side alignment"
echo "- Server messages: isMe: false → LEFT side alignment"
echo "- Message shifting: DISABLED by default (preserves chronological order)"
echo "- When shifting enabled: User responses appear BEFORE the questions they answer"
echo "- Natural conversation flow maintained in chronological order"
echo ""

echo "📝 Notes:"
echo "- Debug logging is enabled in the code for testing"
echo "- Set _debugMessageAlignment = false in production"
echo "- The fix prioritizes the 'source' field over 'senderId' comparison"
echo "- Message shifting is DISABLED by default to preserve chronological order"
echo "- Use the toggle button in the UI to enable shifting if needed"
echo ""

echo "🐛 If issues persist:"
echo "1. Check console logs for error messages"
echo "2. Verify Firebase data has 'source' field set to 'client' for user messages"
echo "3. Try the force reload button to refresh message cache"
echo "" 