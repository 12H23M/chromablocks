# Game Redesign Plan

> **Feature**: game-redesign
> **Date**: 2026-02-10
> **Status**: Draft
> **Previous**: godot-engine (completed, 96% match)

---

## 1. Background

ChromaBlocks was implemented as a Godot 4 + GDScript project (37 files, 9 scenes). The APK was built and tested on an Android phone. The following critical issues were discovered:

### 1.1 Issues Found on Android

| # | Issue | Severity | Description |
|---|-------|----------|-------------|
| 1 | **Portrait orientation not applied** | Critical | Game runs in landscape mode with portrait content rendered sideways. The `window/handheld/orientation="portrait"` in project.godot is not enforced in the Android APK (non-Gradle build). |
| 2 | **Cell visual layers broken** | Major | PanelContainer stacks all 4 ColorRect children on top of each other at full size. Only the topmost layer (Border) is visible. The "Luminous Flow" 4-layer visual effect doesn't render correctly. |
| 3 | **No responsive layout** | Major | Cell size is hardcoded at 36x36px in cell.tscn. Board doesn't adapt to different screen sizes. On phones with different resolutions, the board may be too small or overflow. |
| 4 | **Default Godot UI** | Major | All buttons, labels, and screens use Godot's default gray theme. No custom fonts, colors, or styling applied despite having Ghibli theme colors defined in AppColors. |
| 5 | **No sound effects** | Medium | SoundManager exists but `_sounds` dictionary is empty. All `play_sfx()` calls are no-ops. No audio files exist in the project. |
| 6 | **Placeholder files** | Medium | `grid_highlight.gd` and `clear_effect.gd` are empty stubs (comments only). Highlight handled inline in board_renderer (basic), clear effect is a simple white flash. |
| 7 | **Drag UX polish needed** | Medium | Return-to-tray after reparent may not restore position correctly in all cases. Drag offset may need tuning for different screen sizes. |
| 8 | **No app icon** | Low | Using a generic placeholder SVG icon. |

### 1.2 What Works Correctly

- Core game logic: placement, line clear, color match, scoring, combo, game over, difficulty - all verified at 96% match
- Drag & drop basic functionality (pick up, drag, drop, place)
- Board state management (immutable pattern)
- Game flow: home -> start -> play -> game over -> restart/home
- Save system (high score persistence)
- Haptic feedback calls (vibration works on Android)
- All 6 game systems pass logic verification

---

## 2. Goals

1. Fix Android portrait orientation enforcement
2. Implement responsive layout that adapts to any screen size
3. Replace cell visual system to properly render Luminous Flow 4-layer effect
4. Apply Ghibli theme styling to all UI elements
5. Add sound effects (procedurally generated or placeholder .wav files)
6. Polish animations (clear effects, score popups, combo text)
7. Improve drag & drop UX for mobile
8. Create proper app icon

---

## 3. Technical Analysis & Solutions

### 3.1 Portrait Orientation Fix

**Root Cause**: The `window/handheld/orientation="portrait"` project setting works in the Godot editor but the non-Gradle Android export may not correctly set `android:screenOrientation="portrait"` in the AndroidManifest.xml.

**Solution Options**:

**A. Force orientation via GDScript at runtime (Recommended)**:
```gdscript
# In _ready() of the main scene
DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
```
This works regardless of the export method and guarantees portrait mode on Android.

**B. Switch to Gradle build**: Properly configures the AndroidManifest.xml, but adds build complexity.

**Decision**: Option A - simple, reliable, no build system changes needed.

### 3.2 Cell Visual System Rewrite

**Root Cause**: PanelContainer lays out all children stacked at the same position and same size. All 4 ColorRect layers render at full cell size, so only the last-painted one is visible.

**Solution**: Replace PanelContainer with a Control node and use manual positioning/sizing for each layer:

```
Cell (Control) - cell_view.gd
  Size = dynamically set by board_renderer

  Layer rendering order (bottom to top):
  1. GlowOverlay: extends 2px beyond cell bounds (glow effect)
  2. Background: fills entire cell with small margin (main color)
  3. HighlightBand: covers top 35% of cell (lighter shade)
  4. Border: 1px outline around cell (lightest shade)
```

**Implementation**: Instead of using child ColorRect nodes, paint directly using `_draw()` override. This is more efficient (1 draw call per cell vs 4 nodes per cell) and gives precise control over layer positioning.

### 3.3 Responsive Layout System

**Root Cause**: Cell minimum_size is fixed at 36x36 in cell.tscn. GridContainer respects minimum_size but doesn't scale cells to fill available space.

**Solution**: Calculate cell size dynamically based on available screen width.

```gdscript
# In board_renderer.gd or chroma_blocks_game.gd
func _calculate_cell_size() -> float:
    var available_width := get_viewport_rect().size.x - HORIZONTAL_PADDING * 2
    var available_height := get_viewport_rect().size.y - HUD_HEIGHT - TRAY_HEIGHT - VERTICAL_PADDING
    var max_by_width := available_width / GameConstants.BOARD_COLUMNS
    var max_by_height := available_height / GameConstants.BOARD_ROWS
    return min(max_by_width, max_by_height)
```

**Approach**:
- Remove fixed `custom_minimum_size` from cell.tscn
- Board renderer calculates cell size on `_ready()` and `_notification(NOTIFICATION_RESIZED)`
- Set cell minimum_size dynamically based on calculated cell size
- Tray cell size = board cell size * 0.75 (slightly smaller for tray pieces)

### 3.4 Ghibli Theme Styling

**Solution**: Create a Godot Theme resource (.tres) with Ghibli colors:

- **Buttons**: Rounded corners, sage green background (#7B9E5E), cream text
- **Labels**: Custom fonts with proper sizing hierarchy (title 32px, heading 20px, body 16px, caption 12px)
- **Background**: Cream color (#FBF7F2)
- **Cards/Panels**: White with subtle shadow/border
- **Overlay screens**: Semi-transparent dark overlay (already partially implemented)

**Implementation**: Create `theme/game_theme.tres` resource and apply to root CanvasLayer.

### 3.5 Sound System

**Solution**: Generate minimal sound effects using Godot's AudioStreamGenerator or use simple procedural .wav files:

| Sound | Description | Duration |
|-------|-------------|----------|
| block_place | Short soft thud | 0.1s |
| line_clear | Rising chime | 0.3s |
| color_match | Sparkle/pop | 0.2s |
| combo | Ascending notes | 0.3s |
| level_up | Fanfare | 0.5s |
| game_over | Descending tone | 0.5s |
| button_press | Soft click | 0.05s |

**Approach**: Create a `SFXGenerator` that uses `AudioStreamGenerator` to produce simple tones procedurally (no external audio files needed). Alternatively, create minimal .wav files from code.

### 3.6 Animation Polish

**Current state**: Only `play_clear_flash()` exists (white flash -> transparent).

**Improvements needed**:
- Line clear: Sequential flash across row/column cells
- Color match: Cells pulse/scale before disappearing
- Score popup: Float up with fade (works but needs positioning relative to board)
- Combo text: Bouncy scale animation at screen center
- Perfect clear: Board-wide golden flash
- Tray refill: Slide-in animation for new pieces

### 3.7 Drag & Drop Mobile UX

**Issues**:
- After reparent to drag_layer, piece_node's position may jump
- On return_to_tray + reparent back, the tween target position is stale
- Need to properly track the original slot position in tray coordinate space

**Solution**:
- Store the original tray slot position in tray-local coordinates before reparenting
- On return, reparent first, then calculate correct position from tray layout
- Add snap animation when piece lands on valid grid position
- Increase drag finger offset for larger screens

---

## 4. Implementation Plan

### Phase 1: Critical Fixes (Orientation + Layout)

| # | Task | Files | Description |
|---|------|-------|-------------|
| 1.1 | Force portrait orientation | `chroma_blocks_game.gd` | Add `DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)` in `_ready()` |
| 1.2 | Dynamic cell sizing | `board_renderer.gd`, `cell.tscn` | Calculate cell_size from viewport, remove hardcoded 36px, resize cells dynamically |
| 1.3 | Responsive board layout | `main.tscn`, `board_renderer.gd` | Board fills available space between HUD and Tray, centers horizontally |
| 1.4 | Responsive tray layout | `piece_tray.gd`, `draggable_piece.gd` | Tray cell size = board cell size * 0.75, rebuild pieces on resize |

### Phase 2: Visual Overhaul (Cell + Theme)

| # | Task | Files | Description |
|---|------|-------|-------------|
| 2.1 | Rewrite cell rendering | `cell_view.gd`, `cell.tscn` | Replace PanelContainer+ColorRects with Control+_draw() for proper 4-layer Luminous Flow rendering |
| 2.2 | Create Ghibli theme | `theme/game_theme.tres` (new) | Button, Label, Panel styles with Ghibli colors |
| 2.3 | Style HomeScreen | `home_screen.tscn`, `home_screen.gd` | Title styling, button with sage green, best score display |
| 2.4 | Style GameOverScreen | `game_over_screen.tscn`, `game_over_screen.gd` | Styled card layout, stats display, NEW BEST badge |
| 2.5 | Style PauseScreen | `pause_screen.tscn` | Consistent button styling |
| 2.6 | Style HUD | `hud.tscn`, `hud.gd` | Score/level/combo with proper typography and layout |
| 2.7 | Board border & background | `board_renderer.gd` | Draw board border with subtle shadow/glow |

### Phase 3: Animation & Effects

| # | Task | Files | Description |
|---|------|-------|-------------|
| 3.1 | Improve line clear animation | `board_renderer.gd`, `cell_view.gd` | Sequential flash (staggered timing per cell) |
| 3.2 | Color match explosion | `cell_view.gd` | Scale up + fade out with delay per cell |
| 3.3 | Score popup positioning | `chroma_blocks_game.gd`, `score_popup.gd` | Position relative to board center, proper z-ordering |
| 3.4 | Combo text animation | `chroma_blocks_game.gd` (new combo label) | Bouncy scale at screen center |
| 3.5 | Tray refill animation | `piece_tray.gd`, `draggable_piece.gd` | Slide-in from below with stagger |
| 3.6 | Perfect clear effect | `board_renderer.gd` | Golden flash across entire board |

### Phase 4: Sound & Polish

| # | Task | Files | Description |
|---|------|-------|-------------|
| 4.1 | Procedural sound generation | `scripts/utils/sfx_generator.gd` (new) | Generate sine/triangle wave sounds procedurally |
| 4.2 | Wire sounds to game events | `sound_manager.gd`, `chroma_blocks_game.gd` | Connect generated sounds to game events |
| 4.3 | Drag & drop UX fix | `draggable_piece.gd`, `piece_tray.gd`, `chroma_blocks_game.gd` | Fix reparent position issues, snap animation |
| 4.4 | Grid snap visualization | `board_renderer.gd` | Subtle snap guide when dragging over board |
| 4.5 | App icon | `icon.svg` | Design proper ChromaBlocks icon with block shapes |

### Phase 5: Testing & Build

| # | Task | Description |
|---|------|-------------|
| 5.1 | Desktop testing | Test all features in Godot editor (PC) |
| 5.2 | Export APK | Build Android APK with all fixes |
| 5.3 | Android device testing | Test on Android phone - verify portrait, touch, layout, sounds |
| 5.4 | Edge case testing | Game over, tray refill, rapid tapping, background/foreground |

---

## 5. File Change Summary

### New Files
| File | Purpose |
|------|---------|
| `theme/game_theme.tres` | Ghibli-styled Godot Theme resource |
| `scripts/utils/sfx_generator.gd` | Procedural sound effect generation |

### Modified Files (Major Changes)
| File | Changes |
|------|---------|
| `scripts/game/cell_view.gd` | Complete rewrite: PanelContainer -> Control + _draw() for Luminous Flow |
| `scenes/game/cell.tscn` | Restructure: remove PanelContainer children, use Control base |
| `scripts/game/board_renderer.gd` | Dynamic cell sizing, board background/border drawing, responsive layout |
| `scenes/game/board.tscn` | Remove fixed size, add responsive sizing |
| `scripts/game/draggable_piece.gd` | Fix reparent positions, dynamic cell size, snap animation |
| `scripts/game/piece_tray.gd` | Dynamic cell size, refill animation |
| `scenes/main.tscn` | Theme assignment, layout adjustments |
| `scenes/ui/home_screen.tscn` | Ghibli theme styling |
| `scenes/ui/game_over_screen.tscn` | Ghibli theme styling |
| `scenes/ui/pause_screen.tscn` | Ghibli theme styling |
| `scenes/ui/hud.tscn` | Layout and typography |

### Modified Files (Minor Changes)
| File | Changes |
|------|---------|
| `scripts/game/chroma_blocks_game.gd` | Add DisplayServer orientation, combo label, sound wiring |
| `scripts/game/score_popup.gd` | Better positioning |
| `scripts/utils/sound_manager.gd` | Wire procedural sounds |
| `scripts/ui/hud.gd` | Better score formatting |
| `scripts/ui/home_screen.gd` | Best score formatting |
| `scripts/ui/game_over_screen.gd` | Stats formatting |
| `icon.svg` | Proper app icon design |

### Unchanged Files (Core logic - verified working)
- `scripts/core/enums.gd`
- `scripts/core/game_constants.gd`
- `scripts/core/app_colors.gd`
- `scripts/data/block_piece.gd`
- `scripts/data/board_state.gd`
- `scripts/data/game_state.gd`
- `scripts/data/piece_definitions.gd`
- `scripts/systems/*.gd` (all 6 systems)
- `scripts/utils/save_manager.gd`
- `scripts/utils/haptic_manager.gd`
- `project.godot` (orientation setting already present)
- `export_presets.cfg`

---

## 6. Godot 4 Technical References

### 6.1 Display Orientation (Android)

```gdscript
# Force portrait orientation at runtime
func _ready() -> void:
    DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
```

`DisplayServer.SCREEN_PORTRAIT` = 1 (portrait)
`DisplayServer.SCREEN_LANDSCAPE` = 0 (landscape)

This overrides any manifest setting and works with both Gradle and non-Gradle builds.

### 6.2 Responsive Layout with Control Nodes

```gdscript
# Calculate cell size based on available viewport
func _calculate_layout() -> void:
    var viewport_size := get_viewport_rect().size
    var available_width := viewport_size.x - padding * 2
    var cell_size := floor(available_width / BOARD_COLUMNS)
    var board_size := cell_size * BOARD_COLUMNS
```

Use `NOTIFICATION_RESIZED` to react to viewport changes:
```gdscript
func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        _recalculate_layout()
```

### 6.3 Custom Drawing with _draw()

```gdscript
extends Control

func _draw() -> void:
    # Layer 1: Glow (slightly larger than cell)
    draw_rect(Rect2(-2, -2, size.x + 4, size.y + 4), glow_color)
    # Layer 2: Background (full cell)
    draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), base_color)
    # Layer 3: Highlight band (top 35%)
    draw_rect(Rect2(1, 1, size.x - 2, (size.y - 2) * 0.35), light_color)
    # Layer 4: Border (outline)
    draw_rect(Rect2(0, 0, size.x, size.y), border_color, false, 1.0)
```

### 6.4 Theme Resource Structure

```
[gd_resource type="Theme" format=3]

[resource]
Button/colors/font_color = Color(0.984, 0.969, 0.949, 1)
Button/colors/font_hover_color = Color(1, 1, 1, 1)
Button/styles/normal = SubResource("StyleBoxFlat_btn_normal")
Button/styles/hover = SubResource("StyleBoxFlat_btn_hover")
Button/styles/pressed = SubResource("StyleBoxFlat_btn_pressed")
Label/colors/font_color = Color(0.239, 0.208, 0.161, 1)
Label/font_sizes/font_size = 16
```

### 6.5 Procedural Audio

```gdscript
# Simple tone generation
var generator := AudioStreamGenerator.new()
generator.mix_rate = 44100.0
generator.buffer_length = 0.1

var player := AudioStreamPlayer.new()
player.stream = generator
add_child(player)
player.play()

var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
for i in int(44100 * 0.1):
    var t := float(i) / 44100.0
    var sample := sin(t * 440.0 * TAU) * (1.0 - t * 10.0)  # 440Hz with decay
    playback.push_frame(Vector2(sample, sample))
```

---

## 7. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| _draw() performance with 100 cells | Low | High | Profile on device; fallback to TextureRect if needed |
| Dynamic sizing causes layout jitter | Medium | Medium | Floor all sizes to integers, cache calculations |
| Audio generator latency on Android | Medium | Medium | Pre-generate all sounds on _ready(), cache AudioStreamWAV |
| Theme resource compatibility across Godot versions | Low | Low | Use basic StyleBoxFlat, avoid version-specific features |
| Drag position offset varies by device | Medium | Medium | Scale offset by cell_size ratio, test on multiple devices |

---

## 8. Success Criteria

1. Game runs in portrait mode on Android (no rotation issue)
2. Board and cells resize correctly on different screen sizes (tested on 2+ devices or resolutions)
3. All 6 block colors render with visible Luminous Flow 4-layer effect
4. UI screens (home, game, game over, pause) have consistent Ghibli theme styling
5. At least basic sound effects play for: block place, line clear, game over
6. Clear animations are visually distinct (line clear vs color match)
7. Drag & drop works smoothly: pick up, drag over board with highlight, drop, snap or return
8. No crashes during 10-minute continuous play session

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-10 | Initial plan based on Android testing | AI-Assisted |
