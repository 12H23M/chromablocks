#!/bin/bash
# ChromaBlocks Auto Test Pipeline
# Usage: ./scripts/auto-test.sh [--skip-build] [--device SERIAL_OR_IP:PORT]

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ADB="$HOME/Library/Android/sdk/platform-tools/adb"
PACKAGE="com.alba.chromablocks"
DEVICE="${DEVICE:-100.70.88.124:5555}"
SCREENSHOT_DIR="$PROJECT_DIR/test-screenshots"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$SCREENSHOT_DIR"

SKIP_BUILD=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build) SKIP_BUILD=true; shift ;;
    --device) DEVICE="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "🧪 ChromaBlocks Auto Test"
echo "========================="
echo "Device: $DEVICE"

adb_connect_with_timeout() {
  python3 - "$ADB" "$DEVICE" <<'PY'
import subprocess, sys
adb, device = sys.argv[1], sys.argv[2]
try:
    r = subprocess.run([adb, 'connect', device], timeout=6, capture_output=True, text=True)
    sys.exit(0 if r.returncode == 0 else 1)
except subprocess.TimeoutExpired:
    sys.exit(124)
PY
}

adb_ensure() {
  # If DEVICE looks like host:port, try wireless connect first, but never hang forever.
  if [[ "$DEVICE" == *:* ]]; then
    adb_connect_with_timeout >/dev/null 2>&1 || true
  fi
  "$ADB" -s "$DEVICE" get-state >/dev/null 2>&1
}

# 0. Device check
echo "📱 Checking device..."
if ! adb_ensure; then
  echo "❌ Device not reachable: $DEVICE"
  echo "   Current devices:"
  "$ADB" devices -l
  exit 1
fi
"$ADB" -s "$DEVICE" shell wm size | tr -d '\r'
"$ADB" -s "$DEVICE" shell wm density | tr -d '\r'

# 1. Build & Deploy
if [ "$SKIP_BUILD" = false ]; then
  echo "📦 Building & deploying..."
  cd "$PROJECT_DIR" && ./scripts/deploy.sh --no-launch
else
  echo "⏭️  Skipping build (--skip-build)"
  echo "📦 Installing existing APK..."
  "$ADB" -s "$DEVICE" install -r "$PROJECT_DIR/chromablocks.apk"
fi

# 2. Clean start
echo "🧹 Clean app data..."
"$ADB" -s "$DEVICE" shell pm clear "$PACKAGE" 2>/dev/null || true
sleep 1

# 3. Launch
echo "🚀 Launching..."
"$ADB" -s "$DEVICE" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 2>&1 | tail -1
sleep 5

# 4. Home screen screenshot
echo "📸 Home screen..."
"$ADB" -s "$DEVICE" exec-out screencap -p > "$SCREENSHOT_DIR/home_${TIMESTAMP}.png"

# 5. Tap PLAY (Galaxy S24+ 1080x2340-ish; Godot keeps proportional center)
echo "🎮 Starting game..."
"$ADB" -s "$DEVICE" shell input tap 540 1290
sleep 3

# 6. Game screen screenshot
echo "📸 Game screen..."
"$ADB" -s "$DEVICE" exec-out screencap -p > "$SCREENSHOT_DIR/game_${TIMESTAMP}.png"

# 7. Basic logcat error snapshot
echo "🪵 Recent app errors..."
"$ADB" -s "$DEVICE" logcat -d -t 200 | grep -Ei "godot|chromablocks|fatal|exception|error" > "$SCREENSHOT_DIR/logcat_${TIMESTAMP}.txt" || true

echo ""
echo "✅ Test complete!"
echo "Artifacts: $SCREENSHOT_DIR/"
echo "  home_${TIMESTAMP}.png"
echo "  game_${TIMESTAMP}.png"
echo "  logcat_${TIMESTAMP}.txt"
