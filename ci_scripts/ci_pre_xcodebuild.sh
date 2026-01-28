#!/bin/bash
# Xcode Cloud pre-build script
# Sets the build number before Xcode builds the archive
# This ensures TestFlight receives unique build numbers

set -e

# Calculate build number from git commit count
BUILD_NUMBER=$(git rev-list --count HEAD)

echo "Setting build number to: $BUILD_NUMBER"

# Navigate to the Xcode project directory
cd "$CI_PRIMARY_REPOSITORY_PATH/Manuscript"

# Use agvtool to set the build number in the project
# This updates CURRENT_PROJECT_VERSION in the project file
agvtool new-version -all "$BUILD_NUMBER"

echo "Build number set to $BUILD_NUMBER"
