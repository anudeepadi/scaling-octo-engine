# Quick Deployment Guide

## 🚀 How to Deploy New Versions

Your project is already set up with automated deployments! Here's how to use it:

### For Testing (TestFlight + Google Play Alpha)

```bash
# 1. Merge your changes to staging branch
git checkout staging
git pull
git merge development  # or merge your feature branch
git push

# ✅ This automatically:
# - Increments build number
# - Deploys to TestFlight (iOS)
# - Deploys to Google Play Alpha Testing (Android)
# - Sends Slack notification
```

### For Production (App Store + Google Play Production)

```bash
# 1. Merge staging to production
git checkout production
git pull
git merge staging
git push

# ✅ This automatically:
# - Increments version number (patch by default)
# - Increments build number
# - Deploys to App Store (iOS)
# - Deploys to Google Play Production (Android)
# - Sends Slack notification
```

## 🎯 Branch Strategy

- **`development`** → Development work, runs tests only
- **`staging`** → **Testing deployments** (TestFlight + Alpha Testing)
- **`production`** → **Production deployments** (App Store + Google Play)

## 📱 Testing Access

### TestFlight (iOS)
- Builds appear in TestFlight automatically after staging deployment
- Add testers via App Store Connect → TestFlight → External Groups

### Google Play Alpha Testing (Android)
- Set up closed alpha testing in Google Play Console
- Add testers via Play Console → Testing → Closed testing → Alpha

## 🔧 Required Setup (One-time)

Add these secrets to your GitHub repository settings:

### Android Secrets
- `PLAYSTORE_SERVICE_ACCOUNT_JSON`

### iOS Secrets  
- `IOS_DISTRIBUTION_P12_BASE64`
- `IOS_DISTRIBUTION_P12_PASSWORD`
- `KEYCHAIN_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `APPLE_TEAM_ID`
- `APPSTORE_ISSUER_ID`
- `APPSTORE_API_KEY_ID`
- `APPSTORE_API_PRIVATE_KEY`

### Optional
- `SLACK_WEBHOOK` (for notifications)

## 🏃 Manual Deployment

You can also trigger deployments manually:

1. Go to GitHub Actions in your repository
2. Select "Flutter CI/CD Pipeline"
3. Click "Run workflow"
4. Choose environment and version increment type

## 📊 Version Management

- **Staging**: Only increments build number (e.g., 1.0.0+1 → 1.0.0+2)
- **Production**: Increments version + build number (e.g., 1.0.0+2 → 1.0.1+3)

## ⚡ Quick Commands

```bash
# Deploy to testing
git checkout staging && git pull && git merge development && git push

# Deploy to production  
git checkout production && git pull && git merge staging && git push
```

That's it! Your deployments are now automated. 🎉 