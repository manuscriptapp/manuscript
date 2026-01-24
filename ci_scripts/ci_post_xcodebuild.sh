#!/bin/bash
# Xcode Cloud post-build script
# Creates a git tag with version and build number after App Store distribution

set -e

# Only run for archive action
if [[ "$CI_XCODEBUILD_ACTION" != "archive" ]]; then
    exit 0
fi

# Only tag for App Store distributions
if [[ "$CI_DISTRIBUTION_METHOD" != "app-store-connect" ]]; then
    echo "Skipping tag (distribution method: $CI_DISTRIBUTION_METHOD)"
    exit 0
fi

VERSION="$CI_BUNDLE_SHORT_VERSION_STRING"
BUILD="$CI_BUNDLE_VERSION"
TAG="v${VERSION}+${BUILD}"

echo "Version: $VERSION"
echo "Build: $BUILD"
echo "Creating tag: $TAG"

# Configure git
git config user.name "Xcode Cloud"
git config user.email "xcode-cloud@noreply.apple.com"

# Check if tag exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "Tag $TAG already exists, skipping"
    exit 0
fi

# Create annotated tag
git tag -a "$TAG" -m "Release $VERSION (build $BUILD)

Distributed via Xcode Cloud to App Store Connect"

# Push tag to origin
git push origin "$TAG"

echo "✓ Tag $TAG created and pushed"
