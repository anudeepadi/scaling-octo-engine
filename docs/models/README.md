# Models Documentation

This section documents the data models used throughout the QuitTxT App.

## Contents

- [ChatMessage](chat-message.md): The core message model
- [QuickReply](quick-reply.md): Quick reply buttons model
- [LinkPreview](link-preview.md): Link preview data model
- [MediaSource](media-source.md): Media source data model

## Overview

Models in the QuitTxT App represent the data structures used throughout the application. They provide type safety, serialization/deserialization capabilities, and business logic related to the data they represent.

The app's models are designed to:
- Support conversion to/from JSON for API communication
- Support conversion to/from Firestore documents
- Provide immutable data structures with copyWith pattern for updates
- Include validation logic where necessary

## Core Models

### ChatMessage

The primary data model representing a message in the chat interface. It supports various message types, including text, image, video, and quick replies.

[View ChatMessage Documentation](chat-message.md)

### QuickReply

Represents a quick reply button that can be attached to messages, allowing users to respond with predefined options.

[View QuickReply Documentation](quick-reply.md)

### LinkPreview

Contains metadata for generating previews of links shared in messages.

[View LinkPreview Documentation](link-preview.md)

### MediaSource

Represents different sources of media (camera, gallery, etc.) for attachments.

[View MediaSource Documentation](media-source.md)

## Model Relationships

- **ChatMessage** can contain:
  - QuickReply objects (as suggestedReplies)
  - LinkPreview objects (for URL previews)
  - References to media files

- **MediaSource** is used by services that handle media selection and uploading

## Working with Models

When working with models in the app:

1. Always use factory constructors for creating models from external data sources
2. Use the copyWith pattern for updating models rather than modifying properties directly
3. Leverage the provided serialization methods for API communication and storage

For more detailed information on each model, please refer to the individual documentation pages.