#!/bin/bash

# This script searches for and removes problematic compiler flags in iOS build configuration files

set -e
echo "===== Searching for files with -G compiler flags ====="

cd "$(dirname "$0")"
cd ios

# Find files with -G compiler flag in Pods directory
files_with_g_flag=$(grep -l -- "-G" Pods --include="*.xcconfig" 2>/dev/null || true)

if [ -z "$files_with_g_flag" ]; then
  echo "No files found with -G flag in xcconfig files."
else
  echo "Found files with -G flag:"
  echo "$files_with_g_flag"
  
  echo "===== Removing -G flags from xcconfig files ====="
  for file in $files_with_g_flag; do
    echo "Patching $file"
    # Use perl for in-place editing with backup
    perl -i.bak -pe 's/-G\S*\s?//g' "$file"
  done
  
  echo "===== Verification ====="
  # Verify the flag was removed
  remaining_g_flags=$(grep -- "-G" Pods --include="*.xcconfig" 2>/dev/null || true)
  if [ -z "$remaining_g_flags" ]; then
    echo "Successfully removed all -G flags from xcconfig files."
  else
    echo "Warning: Some -G flags still remain:"
    echo "$remaining_g_flags"
  fi
fi

# Also check and fix the Pods.xcodeproj/project.pbxproj file
echo "===== Checking Pods.xcodeproj/project.pbxproj ====="
if [ -f "Pods/Pods.xcodeproj/project.pbxproj" ]; then
  if grep -q -- "-G" "Pods/Pods.xcodeproj/project.pbxproj"; then
    echo "Found -G flags in project.pbxproj, removing..."
    perl -i.bak -pe 's/-G\S*\s?//g' "Pods/Pods.xcodeproj/project.pbxproj"
    echo "Fixed project.pbxproj"
  else
    echo "No -G flags found in project.pbxproj"
  fi
else
  echo "project.pbxproj not found, skipping"
fi

# Check for the problematic flag in compile commands
echo "===== Checking for -G flag in .xcodebuild directory ====="
compile_commands=$(find . -name "*.dat" -o -name "compile_commands.json" -o -name "*.xccompileargs" 2>/dev/null | xargs grep -l -- "-G" 2>/dev/null || true)
if [ -n "$compile_commands" ]; then
  echo "Found -G flags in compile command files:"
  echo "$compile_commands"
  echo "These will be regenerated on next build."
fi

echo "===== Done fixing compiler flags ====="
echo "Now run 'flutter run' to try building again."
