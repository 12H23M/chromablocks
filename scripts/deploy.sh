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

# Retry ADB connection helper
adb_ensure() {
  for i in 1 2 3; do
    $ADB connect "$DEVICE" 2>/dev/null || true
    sleep 1
    if $ADB devices | grep -q "$DEVICE_IP"; then
      return 0
    fi
    echo "  ⏳ Retry $i..."
    sleep 2
  done
  return 1
}

echo "🎮 ChromaBlocks Deploy Pipeline"
echo "================================"

# 1. Check device connection
echo "📱 Checking device..."
if ! adb_ensure; then
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

# 3. Install APK (with auto-reconnect)
echo ""
echo "📦 Installing APK..."
for attempt in 1 2 3; do
  if $ADB -s "$DEVICE" install -r "$APK" 2>&1; then
    echo "✅ Installed"
    break
  fi
  echo "  ⚠️ Install failed, reconnecting... (attempt $attempt/3)"
  adb_ensure
  if [ "$attempt" -eq 3 ]; then
    echo "❌ Install failed after 3 attempts"
    exit 1
  fi
done

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

# 6. Discord notification
DISCORD_CHANNEL="1476561662936092722"
if command -v openclaw &>/dev/null; then
  openclaw message send --channel discord --target "$DISCORD_CHANNEL" --message "📱✅ **배포 완료!** 폰에서 확인해봐!" 2>/dev/null &
fi
