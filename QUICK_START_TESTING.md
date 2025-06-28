# Quick Start: Testing Deployment

## Immediate Steps for Both Platforms

### 1. iOS (TestFlight) - Today

**For YOUR devices (Internal Testing):**
1. Open [App Store Connect](https://appstoreconnect.apple.com)
2. Go to your app → TestFlight → Internal Testing
3. Create group "My Devices"
4. Add your Apple ID email
5. Build & upload:
   ```bash
   flutter build ios --release
   # Open Xcode, Archive, Upload to App Store Connect
   ```
6. Install TestFlight app on your iPhone
7. Accept invite (arrives in ~10 minutes)

**For OTHER testers (External Testing):**
1. TestFlight → External Testing → Add Group "Beta Testers"
2. Add tester emails
3. Select build → Add to group
4. Fill "What to Test" → Submit
5. Wait 24-48 hours for approval
6. Testers get email invite

### 2. Android (Play Store) - Today

**For YOUR devices (Internal Testing):**
1. Open [Google Play Console](https://play.google.com/console)
2. Select your app → Testing → Internal testing
3. Create release
4. Build & upload:
   ```bash
   flutter build appbundle --release
   # Upload the .aab file from build/app/outputs/bundle/release/
   ```
5. Add your email as tester
6. Click "Copy link" for opt-in URL
7. Open link on your Android device
8. Download from Play Store (appears in ~30 minutes)

**For OTHER testers (Closed Testing):**
1. Testing → Closed testing → Create track
2. Name: "Beta"
3. Upload same .aab file
4. Add tester emails
5. Share opt-in link
6. Available in 2-3 hours

## Simple Deployment Commands

After initial setup, use these commands:

```bash
# Increment version
./bump_version.sh

# Deploy to YOUR devices
./deploy.sh ios internal      # iOS internal
./deploy.sh android internal  # Android internal
./deploy.sh both internal     # Both platforms

# Deploy to BETA testers
./deploy.sh ios beta         # iOS external
./deploy.sh android beta     # Android closed
./deploy.sh both beta        # Both platforms
```

## Today's Checklist

- [ ] iOS: Create Internal Testing group
- [ ] iOS: Upload first build
- [ ] Android: Create Internal Testing track  
- [ ] Android: Upload first AAB
- [ ] Test on your own devices
- [ ] Setup External/Closed testing groups
- [ ] Invite beta testers

That's it! You can have testing running on both platforms within 1-2 hours.
