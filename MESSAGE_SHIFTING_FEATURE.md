# Dynamic Message Shifting Feature

## Overview

The Dynamic Message Shifting feature automatically reorders conversation messages to improve the natural flow of the chat interface. Specifically, it shifts user messages to appear one position earlier relative to server messages, creating a more intuitive conversation sequence.

## How It Works

### Before Message Shifting:
```
1. Server: "Welcome to QuitTXT!"
2. Server: "Pop quiz before we start, just 1 easy question!"
3. Server: "About how many cigarettes do you smoke on an average day?" [1-9, 10-19, 20 or more]
4. User: "1-9" (user's button selection)
5. Server: "If you smoke a pack of cigarettes a day or more..."
```

### After Message Shifting:
```
1. Server: "Welcome to QuitTXT!"
2. Server: "Pop quiz before we start, just 1 easy question!"
3. User: "1-9" (appears before the question it responds to)
4. Server: "About how many cigarettes do you smoke on an average day?" [1-9, 10-19, 20 or more]
5. Server: "If you smoke a pack of cigarettes a day or more..."
```

## Implementation Details

### Automatic Shifting Logic

The feature works by:

1. **Identifying Message Pairs**: When a server message is followed by a user message, they form a conversation pair
2. **Reordering Pairs**: Within each pair, the user message is moved to appear first
3. **Preserving Context**: All other message ordering remains intact
4. **Dynamic Application**: Shifting happens automatically when messages are added or loaded

### Key Methods

#### In `ChatProvider`:

- `_applyMessageShifting()`: Core logic that reorders messages
- `applyMessageShifting()`: Manual trigger for testing
- `setMessageShifting(bool enabled)`: Enable/disable the feature
- `isMessageShiftingEnabled`: Check current state

#### In `DashChatProvider`:

- `testMessageShifting()`: Test the shifting functionality
- `toggleMessageShifting()`: Toggle feature on/off

## Usage

### Automatic Operation

The feature is **DISABLED by default** (as per user request to preserve chronological order) but can be enabled manually. When enabled, it works automatically:

- When new messages are added via `addMessage()`
- When messages are loaded via `setMessages()`
- When text messages are added via `addTextMessage()`
- When quick reply messages are added

### Manual Control

You can control the feature programmatically:

```dart
// Get the chat provider
final chatProvider = context.read<ChatProvider>();

// Check if shifting is enabled
bool isEnabled = chatProvider.isMessageShiftingEnabled;

// Enable/disable shifting
chatProvider.setMessageShifting(true);  // Enable
chatProvider.setMessageShifting(false); // Disable

// Manually apply shifting to current messages
chatProvider.applyMessageShifting();
```

### UI Controls

Debug buttons are available in the messaging screen:

1. **Swap Vert Button** (↕️): Test message shifting functionality
2. **Toggle Button**: Enable/disable message shifting
3. **Console Output**: Check logs for shifting results

## Testing

### Via UI Buttons

1. **Open the messaging screen**
2. **Tap the swap vertical button** (↕️) to test shifting
3. **Tap the toggle button** to enable/disable the feature
4. **Check console logs** for detailed results

### Via Console

Look for these log messages:
```
[DashChatProvider] 🔄 Testing message shifting functionality...
[DashChatProvider] Current message shifting enabled: true
[DashChatProvider] Current message count: 5
Applied message shifting: 5 -> 5 messages
[DashChatProvider] ✅ Message shifting test completed
```

### Expected Results

- **User messages appear earlier**: User responses show up before the questions they answer
- **Natural conversation flow**: The chat reads more like a natural conversation
- **Preserved context**: All other messages maintain their relative positions

## Configuration

### Enable/Disable

```dart
// In ChatProvider constructor or initialization
_messageShiftingEnabled = false; // Default: DISABLED (preserves chronological order)

// Runtime toggle
chatProvider.setMessageShifting(true);  // Enable shifting
chatProvider.setMessageShifting(false); // Disable (back to chronological)
```

### Debug Logging

The feature includes debug logging:
```dart
DebugConfig.debugPrint('Applied message shifting: ${originalMessages.length} -> ${reorderedMessages.length} messages');
```

## Benefits

1. **Better UX**: Conversations flow more naturally
2. **Improved Readability**: User responses appear in logical sequence
3. **Dynamic**: Works automatically without manual intervention
4. **Configurable**: Can be enabled/disabled as needed
5. **Non-destructive**: Original message data is preserved

## Use Cases

- **Quiz Interactions**: User answers appear before questions
- **Button Responses**: User selections show up in logical order
- **Chat Flow**: Overall conversation becomes more readable
- **Testing**: Easy to verify message ordering in development

## Notes

- The feature preserves all original message data and timestamps
- Only the display order is changed, not the underlying data
- Works with all message types (text, quick replies, etc.)
- Performance impact is minimal as it only processes message pairs
- Compatible with existing message loading and display logic 