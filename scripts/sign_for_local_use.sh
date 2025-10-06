#!/bin/bash
# Script to properly sign the app for local development/testing
# This ensures macOS will actually grant Accessibility permissions

set -e

APP_PATH="/Applications/one-window.app"

echo "🔧 Signing one-window.app for local use..."
echo ""

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at: $APP_PATH"
    echo "Please build and copy the app to /Applications first"
    exit 1
fi

# Remove extended attributes (quarantine)
echo "📝 Removing quarantine attributes..."
xattr -cr "$APP_PATH"

# Sign with development team signature with proper entitlements
echo "✍️  Applying code signature with entitlements (Team: B5WVTESYK9)..."
codesign --force --deep --sign "Apple Development" \
    --entitlements "$(dirname "$0")/../one-window/one_window.entitlements" \
    --options runtime \
    --team B5WVTESYK9 \
    "$APP_PATH" 2>/dev/null || \
codesign --force --deep --sign - \
    --entitlements "$(dirname "$0")/../one-window/one_window.entitlements" \
    --options runtime \
    "$APP_PATH"

echo ""
echo "✅ App signed successfully!"
echo ""
echo "📋 Verification:"
codesign -dv "$APP_PATH" 2>&1 || true
echo ""
echo "🔐 Entitlements:"
codesign -d --entitlements - "$APP_PATH" 2>&1 || true
echo ""
echo "⚠️  IMPORTANT NEXT STEPS:"
echo "1. Run: tccutil reset Accessibility com.christopherpowroznik.one-window"
echo "2. Open System Settings → Privacy & Security → Accessibility"
echo "3. Remove any existing 'one-window' entries"
echo "4. Click '+' and manually add: $APP_PATH"
echo "5. Ensure the toggle is ON"
echo "6. Restart the app"
echo ""

