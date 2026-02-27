#!/bin/bash
# ADB Keepalive — 30초마다 핑 보내서 TCP 연결 유지
ADB="$HOME/Library/Android/sdk/platform-tools/adb"
DEVICE="100.70.88.124:5555"

$ADB connect "$DEVICE" 2>/dev/null
echo "🔗 ADB keepalive started for $DEVICE (Ctrl+C to stop)"

while true; do
  if ! $ADB -s "$DEVICE" shell echo ok >/dev/null 2>&1; then
    echo "$(date +%H:%M:%S) ⚠️ Lost — reconnecting..."
    $ADB connect "$DEVICE" 2>/dev/null
  fi
  sleep 30
done
