# Deployment Documentation

This section provides detailed information on deploying the QuitTxT App to various environments and app stores.

## Contents

- [CI/CD Pipeline](ci-cd-pipeline.md): Continuous integration and deployment setup
- [iOS Deployment](ios-deployment.md): Deploying to the App Store
- [Android Deployment](android-deployment.md): Deploying to the Google Play Store

## Deployment Strategy

The QuitTxT App follows a three-branch strategy for deployment:

1. **Development Branch** (`development`):
   - Main branch for active development
   - All feature branches and fixes are merged here first
   - Does not automatically deploy to any environment

2. **Staging Branch** (`staging`):
   - Represents the code deployed to testing environments
   - When `development` is merged to `staging`, the CI/CD pipeline:
     - Builds the iOS app and deploys to TestFlight
     - Builds the Android app and deploys to Google Play internal testing

3. **Production Branch** (`production`):
   - Represents the stable code deployed to production
   - When `staging` is merged to `production`, the CI/CD pipeline:
     - Builds the iOS app and deploys to the App Store
     - Builds the Android app and deploys to the Google Play Store

## CI/CD Pipeline

The CI/CD pipeline is implemented using GitHub Actions, which automates the build and deployment process. Key features include:

- Automated testing
- Environment-specific builds
- Code signing and packaging
- App store uploads
- Notification systems

[Learn more about the CI/CD Pipeline](ci-cd-pipeline.md)

## iOS Deployment

The iOS deployment process includes:

- Code signing with appropriate certificates and provisioning profiles
- Building the app with Xcode
- Packaging for TestFlight and App Store
- App Store submission and review process

[Learn more about iOS Deployment](ios-deployment.md)

## Android Deployment

The Android deployment process includes:

- Code signing with keystore
- Building the app with Gradle
- Packaging for Google Play
- Internal testing and production releases

[Learn more about Android Deployment](android-deployment.md)

## Version Management

The app uses semantic versioning (`MAJOR.MINOR.PATCH+BUILD_NUMBER`):

- **MAJOR**: Incompatible API changes
- **MINOR**: Backwards-compatible functionality additions
- **PATCH**: Backwards-compatible bug fixes
- **BUILD_NUMBER**: Incremental build identifier

A version bumping script is provided to manage versions:

```bash
# Bump patch version (e.g., 1.0.0 -> 1.0.1)
./scripts/bump_version.sh --type patch

# Bump minor version (e.g., 1.0.0 -> 1.1.0)
./scripts/bump_version.sh --type minor

# Bump major version (e.g., 1.0.0 -> 2.0.0)
./scripts/bump_version.sh --type major

# Bump build number only (e.g., 1.0.0+1 -> 1.0.0+2)
./scripts/bump_version.sh --build
```

## Environment Configuration

The app uses environment-specific configuration files:

- `.env.development`: Used for development builds
- `.env.production`: Used for production builds

The CI/CD pipeline automatically selects the appropriate configuration based on the target environment.

For more detailed information on deployment, please refer to the individual documentation pages.