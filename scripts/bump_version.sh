#!/bin/bash

# Script to bump version numbers in pubspec.yaml for release

# Help text
show_help() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -t, --type TYPE     Version bump type (patch, minor, major)"
  echo "  -b, --build         Bump build number only"
  echo "  -h, --help          Show this help message"
  echo
  echo "Examples:"
  echo "  $0 --type patch     # Bump patch version (1.0.0 -> 1.0.1)"
  echo "  $0 --type minor     # Bump minor version (1.0.0 -> 1.1.0)"
  echo "  $0 --type major     # Bump major version (1.0.0 -> 2.0.0)"
  echo "  $0 --build          # Bump build number only (1.0.0+1 -> 1.0.0+2)"
}

# Parse arguments
BUMP_TYPE=""
BUMP_BUILD=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--type)
      BUMP_TYPE="$2"
      shift 2
      ;;
    -b|--build)
      BUMP_BUILD=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Check required arguments
if [[ -z "$BUMP_TYPE" && "$BUMP_BUILD" == false ]]; then
  echo "Error: Version bump type or build flag is required"
  show_help
  exit 1
fi

# Validate bump type
if [[ -n "$BUMP_TYPE" && "$BUMP_TYPE" != "patch" && "$BUMP_TYPE" != "minor" && "$BUMP_TYPE" != "major" ]]; then
  echo "Error: Invalid version bump type. Must be one of: patch, minor, major"
  show_help
  exit 1
fi

# Path to pubspec.yaml
PUBSPEC_PATH="pubspec.yaml"

if [[ ! -f "$PUBSPEC_PATH" ]]; then
  echo "Error: $PUBSPEC_PATH not found"
  exit 1
fi

# Extract current version
CURRENT_VERSION=$(grep "^version: " "$PUBSPEC_PATH" | sed -E 's/version: +([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)/\1+\2/')

if [[ -z "$CURRENT_VERSION" ]]; then
  echo "Error: Could not extract version from $PUBSPEC_PATH"
  exit 1
fi

# Split version into components
VERSION_PARTS=(${CURRENT_VERSION//+/ })
SEMANTIC_VERSION=${VERSION_PARTS[0]}
BUILD_NUMBER=${VERSION_PARTS[1]}

# Split semantic version
IFS='.' read -ra VERSION_COMPONENTS <<< "$SEMANTIC_VERSION"
MAJOR=${VERSION_COMPONENTS[0]}
MINOR=${VERSION_COMPONENTS[1]}
PATCH=${VERSION_COMPONENTS[2]}

# Bump version based on type
if [[ "$BUMP_BUILD" == true ]]; then
  # Just bump build number
  NEW_BUILD=$((BUILD_NUMBER + 1))
  NEW_VERSION="$MAJOR.$MINOR.$PATCH+$NEW_BUILD"
else
  case "$BUMP_TYPE" in
    patch)
      NEW_PATCH=$((PATCH + 1))
      NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH+$BUILD_NUMBER"
      ;;
    minor)
      NEW_MINOR=$((MINOR + 1))
      NEW_VERSION="$MAJOR.$NEW_MINOR.0+$BUILD_NUMBER"
      ;;
    major)
      NEW_MAJOR=$((MAJOR + 1))
      NEW_VERSION="$NEW_MAJOR.0.0+$BUILD_NUMBER"
      ;;
  esac
fi

# Update pubspec.yaml
sed -i.bak -E "s/^version: .+$/version: $NEW_VERSION/" "$PUBSPEC_PATH"
rm "${PUBSPEC_PATH}.bak"

echo "Version bumped from $CURRENT_VERSION to $NEW_VERSION"

# Add to git
git add "$PUBSPEC_PATH"
echo "Changes added to git. Now you can commit with:"
echo "git commit -m \"Bump version to $NEW_VERSION\"" 