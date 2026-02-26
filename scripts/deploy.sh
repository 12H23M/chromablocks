#!/bin/bash
# ChromaBlocks - Build & Deploy to Android
# Usage: ./scripts/deploy.sh [--skip-build] [--no-launch] [--screenshot]

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ADB="$HOME/Library/Android/sdk/platform-tools/adb"
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
APK="$PROJECT_DIR/chromablocks.apk"
PACKAGE="com.alba.chromablocks"
DEVICE_IP="100.70.88.124"
DEVICE_PORT="5555"
DEVICE="$DEVICE_IP:$DEVICE_PORT"

SKIP_BUILD=false
NO_LAUNCH=false
SCREENSHOT=false

for arg in "$@"; do
  case $arg in
    --skip-build) SKIP_BUILD=true ;;
    --no-launch) NO_LAUNCH=true ;;
    --screenshot) SCREENSHOT=true ;;
  esac
done

echo "🎮 ChromaBlocks Deploy Pipeline"
echo "================================"

# 1. Check device connection
echo "📱 Checking device..."
$ADB connect "$DEVICE" 2>/dev/null || true
sleep 1
if ! $ADB devices | grep -q "$DEVICE_IP"; then
  echo "❌ Cannot connect to device. Check VPN/wireless debugging."
  exit 1
fi
echo "✅ Device connected: $DEVICE"

# 2. Build APK
if [ "$SKIP_BUILD" = false ]; then
  echo ""
  echo "🔨 Building APK..."
  $GODOT --headless --path "$PROJECT_DIR" --export-debug "Android" "$APK" 2>&1 | tail -5
  echo "✅ Build complete: $(du -h "$APK" | cut -f1)"
else
  echo "⏭️  Skipping build (--skip-build)"
fi

# 3. Install APK
echo ""
echo "📦 Installing APK..."
$ADB -s "$DEVICE" install -r "$APK" 2>&1
echo "✅ Installed"

# 4. Launch app
if [ "$NO_LAUNCH" = false ]; then
  echo ""
  echo "🚀 Launching ChromaBlocks..."
  $ADB -s "$DEVICE" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 2>/dev/null
  echo "✅ App launched"
fi

# 5. Screenshot (optional)
if [ "$SCREENSHOT" = true ]; then
  echo ""
  echo "📸 Taking screenshot..."
  SHOT="$PROJECT_DIR/screenshots/device_$(date +%Y%m%d_%H%M%S).png"
  mkdir -p "$PROJECT_DIR/screenshots"
  sleep 2
  $ADB -s "$DEVICE" exec-out screencap -p > "$SHOT"
  echo "✅ Screenshot saved: $SHOT"
fi

echo ""
echo "================================"
echo "🎉 Deploy complete!"
