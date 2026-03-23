#!/bin/bash
# ChromaBlocks Auto Test Pipeline
# Usage: ./scripts/auto-test.sh [--skip-build] [--game-over-only]

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ADB="$HOME/Library/Android/sdk/platform-tools/adb"
PACKAGE="com.alba.chromablocks"
DEVICE="R3CX40SKG7Z"
SCREENSHOT_DIR="$PROJECT_DIR/test-screenshots"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$SCREENSHOT_DIR"

SKIP_BUILD=false
for arg in "$@"; do
  case $arg in
    --skip-build) SKIP_BUILD=true ;;
  esac
done

echo "🧪 ChromaBlocks Auto Test"
echo "========================="

# 1. Build & Deploy
if [ "$SKIP_BUILD" = false ]; then
  echo "📦 Building & deploying..."
  cd "$PROJECT_DIR" && ./scripts/deploy.sh --no-launch
fi

# 2. Clean start
echo "🧹 Clean app data..."
$ADB -s $DEVICE shell pm clear $PACKAGE 2>/dev/null || true
sleep 1

# 3. Launch
echo "🚀 Launching..."
$ADB -s $DEVICE shell monkey -p $PACKAGE -c android.intent.category.LAUNCHER 1 2>&1 | tail -1
sleep 5

# 4. Home screen screenshot
echo "📸 Home screen..."
$ADB -s $DEVICE exec-out screencap -p > "$SCREENSHOT_DIR/home_${TIMESTAMP}.png"

# 5. Tap PLAY (1080x2340 phone, button at ~540, 1290)
echo "🎮 Starting game..."
$ADB -s $DEVICE shell input tap 540 1290
sleep 3

# 6. Game screen screenshot
echo "📸 Game screen..."
$ADB -s $DEVICE exec-out screencap -p > "$SCREENSHOT_DIR/game_${TIMESTAMP}.png"

echo ""
echo "✅ Test complete!"
echo "Screenshots: $SCREENSHOT_DIR/"
echo "  home_${TIMESTAMP}.png"
echo "  game_${TIMESTAMP}.png"
