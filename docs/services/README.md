# Services Documentation

This section documents the service layer of the QuitTxT App, which handles business logic, external API communication, and other non-UI functionalities.

## Contents

- [Bot Service](bot-service.md): Handles interactions with Gemini AI
- [Dash Messaging Service](dash-messaging-service.md): Manages RCS messaging
- [Firebase Services](firebase-services.md): Firebase integration
- [Media Services](media-services.md): Media handling services

## Overview

Services in the QuitTxT App follow the separation of concerns principle by encapsulating business logic away from the UI components. They are responsible for:

- API communication
- Data processing and transformation
- Business rule implementation
- Firebase integration
- Media handling
- Local storage management

## Core Services

### Bot Service / Gemini Service

Responsible for communicating with the Gemini AI API to generate responses, handle AI-based quick replies, and provide intelligent suggestions.

[View Bot Service Documentation](bot-service.md)

### Dash Messaging Service

Handles RCS messaging features, including sending/receiving messages, managing conversations, and implementing message delivery status tracking.

[View Dash Messaging Service Documentation](dash-messaging-service.md)

### Firebase Services

A collection of services that integrate with Firebase for authentication, database access, storage, and messaging.

[View Firebase Services Documentation](firebase-services.md)

### Media Services

Services for handling media content, including picking images/videos from the gallery, capturing media from the camera, and processing media for sending.

[View Media Services Documentation](media-services.md)

## Service Architecture

The service layer is designed with the following principles:

1. **Dependency Injection**: Services are instantiated and provided to the rest of the app through the Provider pattern
2. **Interface Segregation**: Services have focused responsibilities rather than being monolithic
3. **Testability**: Services are designed to be easily mockable for unit testing
4. **Error Handling**: Services implement proper error handling and propagation

## Service Manager

The `ServiceManager` class serves as a facade for accessing various services in the app. It:

- Manages the lifecycle of services
- Provides a centralized access point for service instances
- Handles dependencies between services

## Platform-Specific Implementations

Some services, particularly those that interact with device capabilities, have platform-specific implementations:

- iOS-specific media picker service
- Android-specific implementations

For more detailed information on each service, please refer to the individual documentation pages.