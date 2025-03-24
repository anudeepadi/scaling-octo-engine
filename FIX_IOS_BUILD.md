# Fix for iOS Build Error `-G` Flag Issue

This guide provides multiple approaches to fix the error: `unsupported option '-G' for target 'x86_64-apple-ios12.0-simulator'`

## Quick Fix (Try this first)

1. Make the fix script executable and run it:
```bash
chmod +x ios_fix_flags.sh
./ios_fix_flags.sh
```

2. Then try building again:
```bash
flutter run
```

## Deep Clean (Try this second)

If the quick fix doesn't work, try the deep clean approach:

1. Make the deep clean script executable and run it:
```bash
chmod +x ios_deep_clean.sh
./ios_deep_clean.sh
```

2. Then try building again:
```bash
flutter run
```

## Alternative Podfile (Try this third)

If both of the above approaches fail, try using the alternative Podfile configuration:

1. Replace the current Podfile with the alternative version:
```bash
cd ios
cp Podfile Podfile.original
cp Podfile.alt Podfile
```

2. Run the deep clean script again:
```bash
cd ..
./ios_deep_clean.sh
```

3. Then try building again:
```bash
flutter run
```

## Manual Fix (Last resort)

If all automated approaches fail, try these manual steps:

1. Run a Flutter clean:
```bash
flutter clean
```

2. Delete iOS build files:
```bash
cd ios
rm -rf Pods
rm -rf .symlinks
rm -f Podfile.lock
```

3. Try a different approach to running pod install:
```bash
pod repo update
env LANG=en_US.UTF-8 OTHER_CFLAGS="" pod install --verbose
```

4. Manually find and remove all instances of `-G` flags:
```bash
cd Pods
grep -r -- "-G" .
```

5. Edit any files that have the `-G` flag and remove those instances.

6. Try building again:
```bash
cd ..
cd ..
flutter run
```

## Try Building for a Physical Device

Sometimes simulator-specific issues can be bypassed by building for a physical device:

```bash
flutter run -d <your-device-id>
```

## Alternative: Build for Android

If you need to test your app functionality while the iOS build issues are being resolved, you can try building for Android instead:

```bash
flutter run -d android
```

## Technical Explanation

The `-G` compiler flag issue occurs when newer versions of CocoaPods or Firebase are used with older Xcode and iOS SDK versions. The flag is no longer supported in newer build environments but may still be included in some dependency configurations.

The fixes in this repository attempt to:

1. Update the minimum iOS version to 12.0
2. Remove the problematic `-G` compiler flags from all build configurations
3. Update post-install hooks to ensure proper compiler flags
4. Provide alternative configurations that avoid problematic dependencies

If all else fails, you may need to:
1. Update Xcode to the latest version
2. Update CocoaPods with `sudo gem install cocoapods`
3. Consider downgrading some of your Firebase dependencies to versions that are known to work with your Xcode version