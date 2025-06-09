# ChatMessage Model

The `ChatMessage` class is the core data model representing messages in the QuitTxT App. It supports various message types and contains all necessary metadata for rendering messages in the UI.

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique identifier for the message |
| `content` | `String` | The text content of the message |
| `timestamp` | `DateTime` | When the message was sent |
| `isMe` | `bool` | Whether the message was sent by the current user |
| `type` | `MessageType` | Type of message (text, image, video, etc.) |
| `suggestedReplies` | `List<QuickReply>?` | Optional quick reply buttons |
| `quickReplies` | `List<QuickReply>?` | Optional quick reply buttons (variant) |
| `mediaUrl` | `String?` | URL to attached media (if applicable) |
| `thumbnailUrl` | `String?` | URL to media thumbnail (if applicable) |
| `fileName` | `String?` | Name of attached file (if applicable) |
| `fileSize` | `int?` | Size of attached file in bytes (if applicable) |
| `linkPreview` | `LinkPreview?` | Preview data for links in message |
| `status` | `MessageStatus` | Delivery status of the message |
| `reactions` | `List<MessageReaction>` | User reactions to the message |
| `parentMessageId` | `String?` | ID of parent message (for thread replies) |
| `threadMessageIds` | `List<String>` | IDs of replies to this message |
| `voiceDuration` | `int?` | Duration of voice message in milliseconds |
| `voiceWaveform` | `String?` | Waveform data for voice message visualization |
| `eventTypeCode` | `int` | Code indicating special event types (default: 1) |

## Enums

### MessageType

```dart
enum MessageType {
  text,
  image,
  gif,
  video,
  youtube,
  file,
  linkPreview,
  quickReply,
  suggestion,
  voice,
  threadReply,
}
```

### MessageStatus

```dart
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  error,
  failed,
}
```

## Constructor

```dart
ChatMessage({
  required this.id,
  required this.content,
  required this.timestamp,
  required this.isMe,
  required this.type,
  this.suggestedReplies,
  this.quickReplies,
  this.mediaUrl,
  this.thumbnailUrl,
  this.fileName,
  this.fileSize,
  this.linkPreview,
  this.status = MessageStatus.sent,
  this.reactions = const [],
  this.parentMessageId,
  this.threadMessageIds = const [],
  this.voiceDuration,
  this.voiceWaveform,
  this.eventTypeCode = 1,
});
```

## Factory Constructors

### fromFirestore

Creates a `ChatMessage` from a Firestore document:

```dart
factory ChatMessage.fromFirestore(Map<String, dynamic> data, String documentId)
```

### fromJson

Creates a `ChatMessage` from a JSON object:

```dart
factory ChatMessage.fromJson(Map<String, dynamic> json)
```

## Methods

### toJson

Converts the message to a JSON object for serialization:

```dart
Map<String, dynamic> toJson()
```

### copyWith

Creates a copy of the message with optional property changes:

```dart
ChatMessage copyWith({...})
```

## Usage Examples

### Creating a new text message

```dart
final message = ChatMessage(
  id: 'msg_123',
  content: 'Hello, world!',
  timestamp: DateTime.now(),
  isMe: true,
  type: MessageType.text,
  status: MessageStatus.sending,
);
```

### Creating a message with quick replies

```dart
final message = ChatMessage(
  id: 'msg_456',
  content: 'How are you feeling today?',
  timestamp: DateTime.now(),
  isMe: false,
  type: MessageType.quickReply,
  suggestedReplies: [
    QuickReply(text: 'Good', value: 'good'),
    QuickReply(text: 'Not so good', value: 'bad'),
    QuickReply(text: 'Neutral', value: 'neutral'),
  ],
);
```

### Updating a message status

```dart
final updatedMessage = message.copyWith(
  status: MessageStatus.delivered,
);
```

## Related Models

- [QuickReply](quick-reply.md): Used for message reply options
- [LinkPreview](link-preview.md): Used for URL previews in messages
- [MessageReaction](message-reaction.md): Used for emoji reactions