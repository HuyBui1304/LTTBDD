#!/bin/bash

# Print SHA-1 and SHA-256 fingerprints for the Android debug keystore.
# Use these when registering the Android app in the Firebase console.

set -e

echo "=========================================="
echo "Android debug keystore fingerprints"
echo "=========================================="

keytool -list -v \
  -keystore "$HOME/.android/debug.keystore" \
  -alias androiddebugkey \
  -storepass android \
  -keypass android \
  | grep -E "SHA1|SHA256"

echo ""
echo "Add these in Firebase Console > Project Settings > Your apps > Android app > Add fingerprint."
