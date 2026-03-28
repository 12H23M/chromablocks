#!/usr/bin/env bash
# run-autoplay.sh — Run ChromaBlocks AutoPlayer bot in headless mode
# Usage: ./scripts/run-autoplay.sh [--games N] [--timeout SECONDS]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
REPORT_FILE="$PROJECT_DIR/tools/autoplay_report.json"

# Defaults
GAMES=10
TIMEOUT=60

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --games)
      GAMES="$2"
      shift 2
      ;;
    --timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--games N] [--timeout SECONDS]"
      echo ""
      echo "Options:"
      echo "  --games N       Number of games to play (default: 10)"
      echo "  --timeout N     Max seconds per game (default: 60)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Verify Godot exists
if [[ ! -x "$GODOT" ]]; then
  echo "ERROR: Godot not found at $GODOT"
  exit 1
fi

echo "=== ChromaBlocks AutoPlay Bot ==="
echo "Games: $GAMES | Timeout: ${TIMEOUT}s per game"
echo "Project: $PROJECT_DIR"
echo ""

# Run Godot headless with the autoplay runner scene
TMPFILE=$(mktemp /tmp/autoplay_output.XXXXXX)
trap 'rm -f "$TMPFILE"' EXIT

"$GODOT" --headless --path "$PROJECT_DIR" \
  --main-scene "res://scenes/autoplay_runner.tscn" \
  -- --games "$GAMES" --timeout "$TIMEOUT" \
  2>&1 | tee "$TMPFILE"

# Extract JSON report from output
REPORT_JSON=$(sed -n '/===AUTOPLAY_REPORT_START===/,/===AUTOPLAY_REPORT_END===/{ /===AUTOPLAY_REPORT/d; p; }' "$TMPFILE")

if [[ -z "$REPORT_JSON" ]]; then
  echo ""
  echo "ERROR: No report found in output. Check Godot logs above."
  exit 1
fi

# Save report
mkdir -p "$(dirname "$REPORT_FILE")"
echo "$REPORT_JSON" > "$REPORT_FILE"

echo ""
echo "=== Report saved to: $REPORT_FILE ==="
echo ""

# Print summary
echo "$REPORT_JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
s = data['summary']
print(f\"Games played:  {data['num_games']}\")
print(f\"Avg score:     {s['avg_score']:,}\")
print(f\"Median score:  {s['median_score']:,}\")
print(f\"Best score:    {s['best_score']:,}\")
print(f\"Worst score:   {s['worst_score']:,}\")
print(f\"Avg turns:     {s['avg_turns']}\")
print(f\"Best combo:    {s['best_combo']}\")
print(f\"Total lines:   {s['total_lines_cleared']}\")
print(f\"Total chains:  {s['total_chains']}\")
print(f\"Total blasts:  {s['total_blasts']}\")
" 2>/dev/null || echo "(install python3 for formatted summary)"
