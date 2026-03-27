#!/bin/bash
# ChromaBlocks — Store Screenshot Capture Pipeline
# Captures 5 store-quality screenshots via ADB
# Usage: ./scripts/store-screenshots.sh [--skip-build]

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ADB="$HOME/Library/Android/sdk/platform-tools/adb"
PACKAGE="com.alba.chromablocks"
SCREENSHOT_DIR="$PROJECT_DIR/screenshots"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Device: Try Tailscale IP first, then USB serial
DEVICE_IP="100.70.88.124"
DEVICE_PORT="5555"
DEVICE="$DEVICE_IP:$DEVICE_PORT"
DEVICE_SERIAL="R3CX40SKG7Z"

mkdir -p "$SCREENSHOT_DIR"

SKIP_BUILD=false
for arg in "$@"; do
  case $arg in
    --skip-build) SKIP_BUILD=true ;;
  esac
done

echo "📸 ChromaBlocks Store Screenshot Pipeline"
echo "========================================="

# Connect to device
echo "🔌 Connecting to device..."
$ADB connect "$DEVICE" 2>/dev/null || true
sleep 1

# Check connection
if ! $ADB -s "$DEVICE" get-state 2>/dev/null | grep -q "device"; then
  echo "  → Tailscale IP failed, trying USB serial..."
  DEVICE="$DEVICE_SERIAL"
fi

if ! $ADB -s "$DEVICE" get-state 2>/dev/null | grep -q "device"; then
  echo "❌ No device connected. Connect your Android device and retry."
  exit 1
fi

echo "  ✅ Device: $($ADB -s $DEVICE shell getprop ro.product.model 2>/dev/null | tr -d '\r')"

# Build & deploy if needed
if [ "$SKIP_BUILD" = false ]; then
  echo ""
  echo "📦 Building & deploying..."
  cd "$PROJECT_DIR" && ./scripts/deploy.sh --no-launch
fi

cap() {
  local name="$1"
  local delay="${2:-2}"
  echo "  📸 $name (wait ${delay}s)..."
  sleep "$delay"
  $ADB -s "$DEVICE" exec-out screencap -p > "$SCREENSHOT_DIR/${name}.png"
  echo "  ✅ Saved: screenshots/${name}.png"
}

tap() {
  $ADB -s "$DEVICE" shell input tap "$1" "$2"
}

swipe() {
  $ADB -s "$DEVICE" shell input swipe "$1" "$2" "$3" "$4" "${5:-300}"
}

key() {
  $ADB -s "$DEVICE" shell input keyevent "$1"
}

# === 1. HOME SCREEN ===
echo ""
echo "🏠 Screenshot 1: Home Screen"

# Clear & fresh launch
$ADB -s "$DEVICE" shell pm clear "$PACKAGE" 2>/dev/null || true
sleep 1
$ADB -s "$DEVICE" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 2>&1 | tail -1
sleep 5

cap "screenshot_home" 1

# === 2. GAMEPLAY — early game ===
echo ""
echo "🎮 Screenshot 2: Gameplay"

# Tap PLAY button (center-ish, adjust if needed)
tap 540 1290
sleep 4

cap "screenshot_play" 1

# === 3. GAMEPLAY — mid-game with combo ===
echo ""
echo "🔥 Screenshot 3: Combo in progress"

# Wait for auto-player to build combo (or play a few moves)
sleep 8

cap "screenshot_combo" 1

# === 4. GAME OVER SCREEN ===
echo ""
echo "💀 Screenshot 4: Game Over screen"

# Let game proceed or force game over by filling board
# If game hasn't ended naturally, wait a bit
sleep 15
cap "screenshot_gameover" 1

# === 5. BACK TO HOME / STATS ===
echo ""
echo "📊 Screenshot 5: Post-game stats"
sleep 3
cap "screenshot_stats" 1

# Return to home
key "KEYCODE_BACK" 2>/dev/null || true

echo ""
echo "========================================="
echo "✅ Store screenshots captured!"
echo ""
echo "Files in screenshots/:"
for f in home play combo gameover stats; do
  fp="$SCREENSHOT_DIR/screenshot_${f}.png"
  if [ -f "$fp" ]; then
    size=$(wc -c < "$fp")
    echo "  ✓ screenshot_${f}.png ($(echo $size | awk '{printf "%.0f KB", $1/1024}'))"
  else
    echo "  ✗ screenshot_${f}.png (missing)"
  fi
done

echo ""
echo "📌 Next steps:"
echo "  1. Review screenshots in: $SCREENSHOT_DIR"
echo "  2. Upload to Google Play Console"
echo "  3. Required sizes: 9:16 ratio, min 320px, max 3840px"
