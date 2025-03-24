# Xcode Settings Update Instructions

To fix the ClangStatCache issues, you need to update settings in Xcode directly:

1. Open Xcode by running:
   ```
   open ios/Runner.xcworkspace
   ```

2. Once Xcode opens, select the "Runner" project in the Project Navigator (left sidebar)

3. Select the "Runner" target 

4. Go to the "Build Settings" tab

5. Make the following changes:
   - Search for "Allow Non-modular Includes in Framework Modules" and set it to "Yes"
   - Search for "Included for Architecture" and set to "Any iOS Simulator SDK"
   - Search for "Valid Architectures" and add "$(ARCHS_STANDARD)"
   - Search for "Compiler Cache" and set "Disable Clang Compiler Cache" to "Yes"

   If you can't find any of these settings, you can add them manually by clicking the "+" button and selecting "Add User-Defined Setting":
   - Add `CLANG_STATCACHE_DISABLE` and set to `YES`

6. Save the changes (Cmd+S)

7. Try building directly in Xcode by clicking the "Play" button

8. If the build succeeds in Xcode, try building with Flutter again:
   ```
   flutter run
   ```

## Alternative: Full Xcode Reset

If the above steps don't work, try a more comprehensive Xcode reset:

1. Close Xcode

2. Run these commands in Terminal:
   ```
   sudo rm -rf ~/Library/Developer/Xcode/DerivedData
   sudo rm -rf ~/Library/Caches/com.apple.dt.Xcode
   sudo xcode-select --reset
   ```

3. Restart your Mac

4. Open the project in Xcode and try building again
