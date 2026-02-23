# ChromaBlocks — Coding Guide

## GDScript Pitfalls (Godot 4.x)

### ⚠️ Variant Type Inference — #1 Recurring Bug

Dictionary/Array access returns `Variant`. Using `:=` causes "Cannot infer type" parse errors.

```gdscript
# ❌ NEVER use := with Dictionary/Array access
var w := dict["key"].size()
var x := array[0].size()
var s := 5.0 + dict["val"] * 3.0

# ✅ ALWAYS use explicit type annotation
var w: int = dict["key"].size()
var first_row: Array = array[0]
var x: int = first_row.size()
var s: float = 5.0 + float(dict["val"]) * 3.0
```

**Rule: If the RHS touches `[]` on a Dictionary or untyped Array, use `: Type =` not `:=`**

### Engine.time_scale
Game uses `Engine.time_scale` for hit-stop effects. All UI animations must use wall-clock timing:
- `Time.get_ticks_msec()` for manual timing
- `tween.set_speed_scale(1.0 / Engine.time_scale)` for tweens

### Android VIBRATE Permission
Must be in `permissions/custom_permissions` in `export_presets.cfg` (not Gradle manifest) for non-Gradle builds.

### UID Files
Never create `.gd.uid` files manually. Run `Godot --headless --import` to regenerate.

## Architecture
- Board: 8x8, 7 colors (6 normal + SPECIAL)
- Cell rendering: custom `_draw()` via `DrawUtils.draw_bubble_block()` — don't modify
- DO NOT modify: DrawUtils, SaveManager, SoundManager, SfxGenerator, MusicManager
- DO NOT modify existing piece SHAPES in PieceDefinitions (add new ones only)

## DDA System (piece_generator.gd)
- fill < 30% → rush mode (big pieces 80%) — fast fill for line clear excitement
- fill 55-70% → mild mercy (placeable pieces 50%)
- fill 70-80% → strong mercy (small pieces prioritized)
- fill 80%+ → critical (guaranteed TINY + placeable 70%)
- Color mercy: 4+ cell clusters get same-color boost (40% chance)
