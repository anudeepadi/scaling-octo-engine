# QuitTxT_App Deployment Guide

This document outlines the deployment process for the QuitTxT_App using a three-branch strategy for continuous integration and delivery.

## Branch Structure

The repository maintains three primary branches:

- **development**: Main development branch where all new features and fixes are integrated
- **staging**: Testing environment for validating changes before production
- **production**: Live production environment that is deployed to app stores

## Deployment Workflow

1. **Development Phase**
   - All feature branches should be created from and merged back into the `development` branch
   - When code is pushed to `development`, the CI pipeline runs tests but does not deploy to any environment
   - Example: `git checkout -b feature/new-chat-feature development`

2. **Staging Phase**
   - When ready to test a release candidate, merge `development` into `staging`:
     ```
     git checkout staging
     git pull
     git merge development
     git push
     ```
   - This triggers the CI/CD pipeline to:
     - Build Android app and deploy to Google Play Store's internal testing track
     - Build iOS app and deploy to TestFlight
     - A Slack notification will be sent to the team

3. **Production Phase**
   - After successful testing in staging, merge `staging` into `production`:
     ```
     git checkout production
     git pull
     git merge staging
     git push
     ```
   - This triggers the CI/CD pipeline to:
     - Build Android app and deploy to Google Play Store's production track
     - Build iOS app and deploy to App Store
     - A Slack notification will be sent to the team

## Required Secrets for CI/CD

The GitHub workflow requires these secrets to be configured in your repository:

### Repository Access
- `QUITXT_REPO_TOKEN`: A GitHub Personal Access Token (PAT) with limited scope to just this repository. This prevents the workflow from requesting access to unrelated repositories.

### Android Deployment
- `PLAYSTORE_SERVICE_ACCOUNT_JSON`: JSON key file for Google Play Console API access

### iOS Deployment
- `IOS_DISTRIBUTION_P12_BASE64`: Base64-encoded P12 certificate for iOS distribution
- `IOS_DISTRIBUTION_P12_PASSWORD`: Password for the P12 certificate
- `KEYCHAIN_PASSWORD`: Password for the macOS keychain
- `IOS_PROVISIONING_PROFILE_BASE64`: Base64-encoded provisioning profile
- `APPLE_TEAM_ID`: Your Apple Developer Team ID
- `APPSTORE_ISSUER_ID`: App Store Connect API Issuer ID
- `APPSTORE_API_KEY_ID`: App Store Connect API Key ID
- `APPSTORE_API_PRIVATE_KEY`: App Store Connect API Private Key

### Notifications
- `SLACK_WEBHOOK`: Webhook URL for Slack notifications

## Setting Up App Store Deployment

1. **First-time App Store Setup**
   - Register your app's bundle identifier in App Store Connect
   - Create an App Record with necessary metadata
   - Configure App Store listing, screenshots, and app information

2. **TestFlight Setup**
   - Configure TestFlight external testers or beta test groups
   - Add test information for TestFlight review

3. **Production Release**
   - After App Store review approval, you can release the app manually from App Store Connect
   - Alternatively, configure the app for automatic release after approval

## Setting Up Google Play Store Deployment

1. **First-time Play Store Setup**
   - Register your app in Google Play Console
   - Configure store listing, screenshots, and app information
   - Complete content rating questionnaire

2. **Internal Testing Setup**
   - Create a closed testing track
   - Add testers via email or Google Groups

3. **Production Release**
   - After internal testing, promote the release to production
   - Configure phased rollout if desired (%)

## Versioning

- Update the `version` in `pubspec.yaml` when preparing a new release
- Follow semantic versioning: `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- Increment the build number for each release to ensure proper tracking

## Environment Configuration

- The workflow automatically uses the appropriate `.env` file based on the branch:
  - `.env.development` for development and staging
  - `.env.production` for production

## Troubleshooting

If deployment fails:

1. Check the GitHub Actions logs for detailed error information
2. Verify that all secrets are correctly configured
3. Ensure your app meets Apple's and Google's guidelines
4. Test the build locally before pushing to staging or production 