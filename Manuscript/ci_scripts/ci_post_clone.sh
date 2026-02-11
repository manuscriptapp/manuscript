#!/bin/bash
# Xcode Cloud post-clone script
# Enables Swift package macros (e.g. AnyLanguageModelMacros) to avoid
# the "must be enabled before it can be used" trust dialog during CI builds.

set -e

defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

echo "Enabled Swift macro fingerprint validation skip for CI build"
