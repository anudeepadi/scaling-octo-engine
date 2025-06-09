# Google Sign-In Troubleshooting Guide

## Issues Fixed

✅ **iOS URL Scheme** - Added required URL scheme to Info.plist  
✅ **Android Package Name** - Fixed namespace mismatch  
✅ **Enhanced Error Handling** - Added better error messages and debugging  

## Common Google Sign-In Issues & Solutions

### 1. "Google Sign-In is not enabled for this project"

**Solution:** Enable Google Sign-In in Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `quitxtmobile`
3. Go to Authentication → Sign-in method
4. Enable Google sign-in provider
5. Add your app's SHA-1 certificate fingerprint (Android) and bundle ID (iOS)

### 2. "Invalid credential" or "Missing Google tokens"

**Solution:** Verify configuration files
- **Android:** Ensure `google-services.json` is in `android/app/`
- **iOS:** Ensure `GoogleService-Info.plist` is in `ios/Runner/`
- Both files should be from the same Firebase project

### 3. Android SHA-1 Certificate Issues

**Get Debug SHA-1:**
```bash
cd android
./gradlew signingReport
```

**Get Release SHA-1:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Add SHA-1 to Firebase:**
1. Firebase Console → Project Settings → Your apps
2. Add fingerprint under SHA certificate fingerprints

### 4. iOS Bundle ID Issues

**Verify Bundle ID matches:**
- `ios/Runner.xcodeproj/project.pbxproj` 
- `GoogleService-Info.plist`
- Firebase Console app configuration

### 5. "PlatformException: sign_in_failed"

**Solutions:**
1. Check internet connection
2. Verify Firebase project is active
3. Ensure Google services are properly initialized
4. Clean and rebuild the app:
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   flutter run
   ```

### 6. iOS Simulator Issues

Google Sign-In may not work properly in iOS Simulator. Test on a real device.

### 7. Certificate/Keychain Issues (iOS)

If you see keychain errors:
```bash
cd ios
pod install --repo-update
```

## Testing Google Sign-In

### Debug Mode Testing
```bash
# Clean build
flutter clean
flutter pub get

# iOS
cd ios && pod install && cd ..
flutter run -d ios

# Android  
flutter run -d android
```

### Check Logs
- **Android:** Use `adb logcat` or Android Studio logcat
- **iOS:** Use Xcode console or `flutter logs`

Look for these log messages:
- "AuthProvider: Attempting Firebase sign in with Google credential"
- "AuthProvider: Google SignIn successful"
- Any error messages with "AuthProvider: Google SignIn"

## Firebase Console Checklist

### Authentication Settings
- [ ] Google sign-in provider is enabled
- [ ] Authorized domains include your test domains
- [ ] OAuth consent screen is configured (if using custom domain)

### Project Settings
- [ ] Android app has correct package name: `com.utsascns.quitTxTapp`
- [ ] iOS app has correct bundle ID: `com.utsascns.quitTxTapp`
- [ ] SHA-1 fingerprints are added for Android
- [ ] Latest `google-services.json` and `GoogleService-Info.plist` downloaded

## Manual Testing Steps

1. **Clean Installation:**
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   ```

2. **Test Google Sign-In Flow:**
   - Tap Google Sign-In button
   - Should open Google account picker
   - Select account
   - Should redirect back to app
   - Check if user is signed in

3. **Check Debug Console:**
   - Look for "Google SignIn successful" message
   - Check for any error messages

## Still Having Issues?

1. **Verify Firebase Project ID:** `quitxtmobile`
2. **Check Network:** Ensure stable internet connection
3. **Test on Real Device:** Especially for iOS
4. **Update Dependencies:** Run `flutter pub upgrade`
5. **Check Firebase Status:** [Firebase Status Page](https://status.firebase.google.com/)

## Emergency Reset

If nothing works, try a complete reset:

```bash
# 1. Clean everything
flutter clean
cd ios && rm -rf Pods Podfile.lock && cd ..
cd android && ./gradlew clean && cd ..

# 2. Re-download config files from Firebase Console
# Replace google-services.json and GoogleService-Info.plist

# 3. Reinstall dependencies
flutter pub get
cd ios && pod install && cd ..

# 4. Run again
flutter run
```

## Contact Information

If you continue having issues after following this guide:
1. Check the logs for specific error messages
2. Verify all Firebase console settings
3. Test on a real device (not simulator)
4. Ensure you're using the latest config files from Firebase 