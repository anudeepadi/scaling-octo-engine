# iOS Build Fix

This fix addresses the error: `unsupported option '-G' for target 'x86_64-apple-ios12.0-simulator'`

## What's Been Fixed

The BoringSSL-GRPC library in Firebase dependencies sometimes has compiler flags that aren't compatible with newer versions of Xcode. The Podfile has been updated to specifically remove the problematic `-G` flag.

## Steps to Apply the Fix

1. Make the cleaning script executable:
   ```
   chmod +x clean_ios.sh
   ```

2. Run the cleaning script:
   ```
   ./clean_ios.sh
   ```

3. Try building your app:
   ```
   flutter run
   ```

## If Issues Persist

If you still encounter build issues, try setting "Allow Non-modular Includes in Framework Modules" to YES:

1. Open your project in Xcode
2. Select "Runner" from the targets
3. Go to the "Build Settings" tab
4. Search for "Allow Non-modular Includes in Framework Modules"
5. Set it to "YES"

## Additional Resources

- Full cleanup: `rm -rf ~/Library/Developer/Xcode/DerivedData/*` (removes all cached builds)
- Update CocoaPods: `sudo gem install cocoapods`
- Clean Flutter build: `flutter clean`
