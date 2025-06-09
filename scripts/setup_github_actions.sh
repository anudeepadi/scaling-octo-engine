#!/bin/bash

# This script helps set up your GitHub Actions environment for deploying QuitTxT_App

echo "QuitTxT_App GitHub Actions Setup Guide"
echo "======================================"
echo
echo "This script provides instructions for setting up the required secrets for GitHub Actions."
echo

# Create a personal access token
echo "1. Create a GitHub Personal Access Token:"
echo "   a. Go to GitHub > Settings > Developer settings > Personal access tokens > Tokens (classic)"
echo "   b. Click 'Generate new token' (classic)"
echo "   c. Name it 'QuitTxT_App Deployment'"
echo "   d. Set expiration as needed"
echo "   e. Select only these scopes:"
echo "      - repo (Full control of private repositories)"
echo "      - workflow (Update GitHub Action workflows)"
echo "   f. Generate token and copy it"
echo
echo "2. Add the token as a repository secret:"
echo "   a. Go to your repository Settings > Secrets and variables > Actions"
echo "   b. Click 'New repository secret'"
echo "   c. Name: QUITXT_REPO_TOKEN"
echo "   d. Value: [Paste your token]"
echo

# Android deployment
echo "3. Set up Google Play Store deployment secrets:"
echo "   a. Create a Google Play Console Service Account"
echo "   b. Download the JSON key file"
echo "   c. Add it as a secret named 'PLAYSTORE_SERVICE_ACCOUNT_JSON'"
echo

# iOS deployment
echo "4. Set up Apple App Store deployment secrets:"
echo "   a. Create a p12 certificate for distribution"
echo "      - Base64 encode it: cat certificate.p12 | base64 | pbcopy"
echo "      - Add as secret: IOS_DISTRIBUTION_P12_BASE64"
echo "   b. Add the p12 password as secret: IOS_DISTRIBUTION_P12_PASSWORD"
echo "   c. Set a keychain password secret: KEYCHAIN_PASSWORD"
echo "   d. Export provisioning profile and add it:"
echo "      - Base64 encode it: cat profile.mobileprovision | base64 | pbcopy"
echo "      - Add as secret: IOS_PROVISIONING_PROFILE_BASE64"
echo "   e. Add your Apple Team ID as secret: APPLE_TEAM_ID"
echo "   f. Set up App Store Connect API access:"
echo "      - Add issuer ID as secret: APPSTORE_ISSUER_ID"
echo "      - Add API key ID as secret: APPSTORE_API_KEY_ID"
echo "      - Add API private key as secret: APPSTORE_API_PRIVATE_KEY"
echo

# Notifications
echo "5. Set up Slack notifications (optional):"
echo "   a. Create a Slack webhook"
echo "   b. Add it as secret: SLACK_WEBHOOK"
echo

echo "After setting up all these secrets, your GitHub Actions workflow will work without"
echo "requesting access to unrelated repositories."
echo
echo "See DEPLOYMENT.md for more details on the deployment process." 