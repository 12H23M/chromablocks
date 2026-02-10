# Game Redesign - Technical Design

> **Feature**: game-redesign
> **Date**: 2026-02-10
> **Status**: Draft
> **Plan Reference**: docs/01-plan/features/game-redesign.plan.md
> **Previous Design**: docs/02-design/features/godot-engine.design.md

---

## 1. Overview

This design document specifies the exact changes to the existing ChromaBlocks Godot 4 project to fix 8 issues discovered during Android device testing. The core game logic (systems, data models) is verified working at 96% match rate and **remains unchanged**. All changes target rendering, layout, theming, sound, and UX.

### 1.1 Scope Summary

| Category | Files Changed | New Files |
|----------|---------------|-----------|
| Critical Fixes (Orientation + Layout) | 5 | 0 |
| Visual Overhaul (Cell + Theme) | 12 | 1 |
| Sound System | 2 | 1 |
| Total | 14 modified | 2 new |

### 1.2 Files NOT Changed (Core Logic)

These files are verified correct and must not be modified:

- `scripts/core/enums.gd`
- `scripts/core/game_constants.gd`
- `scripts/data/block_piece.gd`
- `scripts/data/board_state.gd`
- `scripts/data/game_state.gd`
- `scripts/data/piece_definitions.gd`
- `scripts/systems/placement_system.gd`
- `scripts/systems/clear_system.gd`
- `scripts/systems/color_match_system.gd`
- `scripts/systems/scoring_system.gd`
- `scripts/systems/game_over_system.gd`
- `scripts/systems/difficulty_system.gd`
- `scripts/utils/save_manager.gd`
- `scripts/utils/haptic_manager.gd`
- `export_presets.cfg`

---

## 2. Architecture

### 2.1 Current Node Tree (Unchanged)

```
Main (Node) ← chroma_blocks_game.gd
├── UILayer (CanvasLayer)
│   ├── GameUI (VBoxContainer) ← full-screen, vertical layout
│   │   ├── TopMargin (MarginContainer) ← padding: L16 T48 R16
│   │   │   └── HUD (HBoxContainer) ← hud.gd
│   │   ├── BoardContainer (CenterContainer) ← size_flags_vertical=EXPAND_FILL
│   │   │   └── Board (GridContainer) ← board_renderer.gd  [%Board]
│   │   └── TrayContainer (CenterContainer) ← min_height=120
│   │       └── PieceTray (HBoxContainer) ← piece_tray.gd  [%PieceTray]
│   ├── DragLayer (Control) ← mouse_filter=IGNORE  [%DragLayer]
│   ├── HomeScreen (Control) ← home_screen.gd
│   ├── GameOverScreen (Control) ← game_over_screen.gd
│   └── PauseScreen (Control) ← pause_screen.gd
└── AudioPlayers (Node)
    ├── SFXPlayer (AudioStreamPlayer)
    └── MusicPlayer (AudioStreamPlayer)
```

### 2.2 Data Flow (Unchanged)

```
User Touch → DraggablePiece._gui_input/_input
  → drag_started/moved/ended signals
  → PieceTray relay signals
  → ChromaBlocksGame._on_drag_*
  → PlacementSystem.can_place() / _place_piece()
  → ClearSystem / ColorMatchSystem / ScoringSystem
  → GameState update
  → board_renderer.update_from_state() + hud.update_from_state()
  → Visual effects (cell flash, score popup, sound, haptic)
```

---

## 3. Phase 1: Critical Fixes

### 3.1 Portrait Orientation Enforcement

**File**: `scripts/game/chroma_blocks_game.gd`
**Change**: Add single line in `_ready()`

```gdscript
func _ready() -> void:
    DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
    # ... rest unchanged
```

**Why**: `project.godot` setting `window/handheld/orientation="portrait"` is not reliably applied in non-Gradle Android APK exports. `DisplayServer.screen_set_orientation()` forces portrait at runtime regardless of export method.

### 3.2 Dynamic Cell Sizing — Board Renderer Rewrite

**File**: `scripts/game/board_renderer.gd`
**Change**: Complete rewrite. Replace GridContainer-based auto-layout with Control-based manual layout.

**Current Problems**:
1. Cell size hardcoded at 36x36 in cell.tscn `custom_minimum_size`
2. GridContainer auto-layouts cells but cannot dynamically size them to fill available space
3. `world_to_grid()` relies on `size.x / BOARD_COLUMNS` which is only correct if the GridContainer fills available width

**New Architecture**:
- Change base node from `GridContainer` to `Control`
- Calculate `cell_size` from available space in `_ready()` and on resize
- Position each cell manually at `(x * cell_size, y * cell_size)`
- Set each cell's `size` to `Vector2(cell_size, cell_size)`

```gdscript
extends Control

const CellScene := preload("res://scenes/game/cell.tscn")

var _cells: Array = []  # Array[Array[CellView]] — [y][x]
var _cell_size: float = 36.0

func initialize() -> void:
    _cells.clear()
    for child in get_children():
        child.queue_free()

    _calculate_cell_size()

    for y in GameConstants.BOARD_ROWS:
        var row: Array = []
        for x in GameConstants.BOARD_COLUMNS:
            var cell_node := CellScene.instantiate()
            add_child(cell_node)
            cell_node.set_empty()
            row.append(cell_node)
        _cells.append(row)

    _layout_cells()

func _calculate_cell_size() -> void:
    var viewport_size := get_viewport_rect().size

    # Available width = viewport width minus horizontal padding (16px * 2)
    var available_width := viewport_size.x - 32.0

    # Available height = viewport minus HUD (60px) minus tray (120px) minus margins (64px top + 16px gaps)
    var available_height := viewport_size.y - 260.0

    var max_by_width := floorf(available_width / float(GameConstants.BOARD_COLUMNS))
    var max_by_height := floorf(available_height / float(GameConstants.BOARD_ROWS))

    _cell_size = minf(max_by_width, max_by_height)

func _layout_cells() -> void:
    var board_pixel_size := _cell_size * GameConstants.BOARD_COLUMNS
    custom_minimum_size = Vector2(board_pixel_size, board_pixel_size)
    size = Vector2(board_pixel_size, board_pixel_size)

    for y in GameConstants.BOARD_ROWS:
        for x in GameConstants.BOARD_COLUMNS:
            var cell: Control = _cells[y][x]
            cell.position = Vector2(x * _cell_size, y * _cell_size)
            cell.size = Vector2(_cell_size, _cell_size)

func get_cell_size() -> float:
    return _cell_size

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and _cells.size() > 0:
        _calculate_cell_size()
        _layout_cells()

# update_from_state — UNCHANGED
func update_from_state(board: BoardState) -> void:
    for y in board.rows:
        for x in board.columns:
            var cell_data: Dictionary = board.grid[y][x]
            if cell_data["occupied"]:
                _cells[y][x].set_filled(cell_data["color"])
            else:
                _cells[y][x].set_empty()

# show_highlight — UNCHANGED
func show_highlight(gx: int, gy: int, piece: BlockPiece, can_place: bool) -> void:
    clear_highlights()
    for cell_pos in piece.occupied_cells_at(gx, gy):
        if cell_pos.x >= 0 and cell_pos.x < GameConstants.BOARD_COLUMNS \
           and cell_pos.y >= 0 and cell_pos.y < GameConstants.BOARD_ROWS:
            _cells[cell_pos.y][cell_pos.x].set_highlight(can_place)

# clear_highlights — UNCHANGED
func clear_highlights() -> void:
    for y in GameConstants.BOARD_ROWS:
        for x in GameConstants.BOARD_COLUMNS:
            _cells[y][x].clear_highlight()

# play_line_clear_effect — ENHANCED with stagger
func play_line_clear_effect(rows: Array, cols: Array) -> void:
    var delay := 0.0
    for row in rows:
        for x in GameConstants.BOARD_COLUMNS:
            _cells[row][x].play_clear_flash(
                GameConstants.LINE_CLEAR_ANIM_DURATION, delay)
            delay += 0.02  # 20ms stagger per cell
    for col in cols:
        delay = 0.0
        for y in GameConstants.BOARD_ROWS:
            _cells[y][col].play_clear_flash(
                GameConstants.LINE_CLEAR_ANIM_DURATION, delay)
            delay += 0.02

# play_color_match_effect — ENHANCED with stagger
func play_color_match_effect(groups: Array) -> void:
    for group in groups:
        var delay := 0.0
        for cell_pos in group:
            if cell_pos.x >= 0 and cell_pos.x < GameConstants.BOARD_COLUMNS \
               and cell_pos.y >= 0 and cell_pos.y < GameConstants.BOARD_ROWS:
                _cells[cell_pos.y][cell_pos.x].play_color_match_flash(
                    GameConstants.COLOR_MATCH_ANIM_DURATION, delay)
                delay += 0.03

# world_to_grid — UPDATED to use _cell_size
func world_to_grid(local_pos: Vector2) -> Vector2i:
    var gx := int(local_pos.x / _cell_size)
    var gy := int(local_pos.y / _cell_size)
    return Vector2i(gx, gy)

# draw board background + border
func _draw() -> void:
    # Board background (slightly darker than empty cells)
    var bg_rect := Rect2(Vector2.ZERO, size)
    draw_rect(bg_rect, AppColors.GRID_LINE)

    # Grid lines
    for i in range(1, GameConstants.BOARD_COLUMNS):
        var x := i * _cell_size
        draw_line(Vector2(x, 0), Vector2(x, size.y), AppColors.EMPTY_BORDER, 1.0)
    for i in range(1, GameConstants.BOARD_ROWS):
        var y := i * _cell_size
        draw_line(Vector2(0, y), Vector2(size.x, y), AppColors.EMPTY_BORDER, 1.0)

    # Outer border
    draw_rect(bg_rect, AppColors.BORDER, false, 2.0)
```

**Scene Change**: `scenes/game/board.tscn`

```
[gd_scene load_steps=2 format=3 uid="uid://board001"]

[ext_resource type="Script" path="res://scripts/game/board_renderer.gd" id="1_board"]

[node name="Board" type="Control"]
layout_mode = 2
size_flags_horizontal = 4
size_flags_vertical = 4
script = ExtResource("1_board")
```

Key change: `GridContainer` → `Control`. Remove `columns = 10` property. Board renderer handles all layout manually.

### 3.3 Cell Visual Rewrite — _draw() Based Rendering

**File**: `scripts/game/cell_view.gd`
**Change**: Complete rewrite. Replace PanelContainer with child ColorRects with Control using `_draw()` override.

**Current Problem**: PanelContainer lays out all children at the same position/full size. All 4 ColorRect layers render on top of each other identically, so only the topmost (Border) is visible. The Luminous Flow 4-layer effect is completely broken.

**New Architecture**:

```gdscript
extends Control

var _occupied: bool = false
var _color: int = -1

# Layer colors (set by set_filled / set_empty / set_highlight)
var _glow_color := Color.TRANSPARENT
var _bg_color := Color(0.98, 0.97, 0.95, 1.0)
var _highlight_color := Color.TRANSPARENT
var _border_color := Color(0.93, 0.91, 0.89, 1.0)

func set_empty() -> void:
    _occupied = false
    _color = -1
    _glow_color = Color.TRANSPARENT
    _bg_color = AppColors.EMPTY_CELL
    _highlight_color = Color.TRANSPARENT
    _border_color = AppColors.EMPTY_BORDER
    queue_redraw()

func set_filled(block_color: int) -> void:
    _occupied = true
    _color = block_color
    var base := AppColors.get_block_color(block_color)
    var light := AppColors.get_block_light_color(block_color)
    var glow := AppColors.get_block_glow_color(block_color)

    _glow_color = glow
    _bg_color = base
    _highlight_color = Color(light.r, light.g, light.b, 0.4)
    _border_color = light
    queue_redraw()

func set_highlight(can_place: bool) -> void:
    _bg_color = AppColors.HIGHLIGHT_VALID if can_place else AppColors.HIGHLIGHT_INVALID
    _glow_color = Color.TRANSPARENT
    _highlight_color = Color.TRANSPARENT
    _border_color = _bg_color
    queue_redraw()

func clear_highlight() -> void:
    if _occupied:
        set_filled(_color)
    else:
        set_empty()

func play_clear_flash(duration: float, delay: float = 0.0) -> void:
    if delay > 0.0:
        await get_tree().create_timer(delay).timeout
    _bg_color = Color.WHITE
    _glow_color = Color(1, 1, 1, 0.5)
    _highlight_color = Color.TRANSPARENT
    _border_color = Color.WHITE
    queue_redraw()

    var tween := create_tween()
    tween.tween_method(_tween_to_empty, 1.0, 0.0, duration)
    tween.tween_callback(set_empty)

func play_color_match_flash(duration: float, delay: float = 0.0) -> void:
    if delay > 0.0:
        await get_tree().create_timer(delay).timeout

    # Scale up briefly then fade
    var original_size := size
    var tween := create_tween()
    tween.set_parallel(true)

    # Flash the color brightly
    var bright := AppColors.get_block_light_color(_color) if _occupied else Color.WHITE
    _bg_color = bright
    _glow_color = Color(bright.r, bright.g, bright.b, 0.6)
    queue_redraw()

    tween.tween_method(_tween_to_empty, 1.0, 0.0, duration)
    tween.chain().tween_callback(set_empty)

func _tween_to_empty(t: float) -> void:
    # Interpolate all colors towards empty state
    _bg_color = _bg_color.lerp(AppColors.EMPTY_CELL, 1.0 - t)
    _glow_color.a = _glow_color.a * t
    _highlight_color.a = _highlight_color.a * t
    _border_color = _border_color.lerp(AppColors.EMPTY_BORDER, 1.0 - t)
    queue_redraw()

func _draw() -> void:
    var cell_rect := Rect2(Vector2.ZERO, size)
    var inset := 1.0

    # Layer 1: Glow (extends slightly beyond inset — full cell area)
    if _glow_color.a > 0.01:
        draw_rect(cell_rect, _glow_color)

    # Layer 2: Background (inset by 1px)
    var bg_rect := Rect2(
        Vector2(inset, inset),
        Vector2(size.x - inset * 2, size.y - inset * 2))
    draw_rect(bg_rect, _bg_color)

    # Layer 3: Highlight band (top 35% of the inset area)
    if _highlight_color.a > 0.01:
        var band_height := (size.y - inset * 2) * 0.35
        var band_rect := Rect2(
            Vector2(inset, inset),
            Vector2(size.x - inset * 2, band_height))
        draw_rect(band_rect, _highlight_color)

    # Layer 4: Border (1px outline around the inset area)
    draw_rect(bg_rect, _border_color, false, 1.0)
```

**Scene Change**: `scenes/game/cell.tscn`

```
[gd_scene load_steps=2 format=3 uid="uid://cell001"]

[ext_resource type="Script" path="res://scripts/game/cell_view.gd" id="1_cell"]

[node name="Cell" type="Control"]
script = ExtResource("1_cell")
```

Key changes:
- `PanelContainer` → `Control`
- Remove all 4 child ColorRect nodes (GlowOverlay, Background, HighlightBand, Border)
- Remove `custom_minimum_size` (board_renderer sets size dynamically)
- Remove `mouse_filter` settings (Control default is STOP; we'll set to IGNORE)

**Additional**: Add `mouse_filter = 2` (MOUSE_FILTER_IGNORE) to cell node so touch events pass through to the board.

### 3.4 Responsive Tray Layout

**File**: `scripts/game/piece_tray.gd`
**Change**: Accept dynamic cell_size from game manager instead of hardcoded `tray_cell_size = 28.0`

```gdscript
extends HBoxContainer

signal piece_drag_started(piece_node: Control)
signal piece_drag_moved(piece_node: Control, global_pos: Vector2)
signal piece_drag_ended(piece_node: Control, global_pos: Vector2)

const DraggablePieceScene := preload("res://scenes/game/draggable_piece.tscn")

var _tray_cell_size: float = 28.0
var _active_pieces: Array = []

func set_cell_size(board_cell_size: float) -> void:
    _tray_cell_size = board_cell_size * 0.7

func populate_tray(pieces: Array) -> void:
    clear_tray()
    for i in pieces.size():
        var piece_node := DraggablePieceScene.instantiate()
        add_child(piece_node)
        piece_node.setup(pieces[i], i, _tray_cell_size)
        piece_node.drag_started.connect(_on_drag_started)
        piece_node.drag_moved.connect(_on_drag_moved)
        piece_node.drag_ended.connect(_on_drag_ended)
        _active_pieces.append(piece_node)

func remove_piece_at(index: int) -> void:
    if index >= 0 and index < _active_pieces.size():
        var piece: Control = _active_pieces[index]
        piece.remove_from_tray()
        _active_pieces.remove_at(index)
        for i in _active_pieces.size():
            _active_pieces[i].tray_index = i

func clear_tray() -> void:
    for piece in _active_pieces:
        if is_instance_valid(piece):
            piece.queue_free()
    _active_pieces.clear()

func _on_drag_started(piece_node: Control) -> void:
    piece_drag_started.emit(piece_node)

func _on_drag_moved(piece_node: Control, pos: Vector2) -> void:
    piece_drag_moved.emit(piece_node, pos)

func _on_drag_ended(piece_node: Control, pos: Vector2) -> void:
    piece_drag_ended.emit(piece_node, pos)
```

Changes from current:
- Remove `@export var tray_cell_size: float = 28.0`
- Add `_tray_cell_size` private var
- Add `set_cell_size(board_cell_size)` method: tray cells = 70% of board cell size
- `populate_tray` uses `_tray_cell_size` instead of `tray_cell_size`

### 3.5 Draggable Piece — Dynamic Cell Size & Improved Visuals

**File**: `scripts/game/draggable_piece.gd`
**Change**: Use `_draw()` for piece rendering instead of child ColorRects. Fix return-to-tray positioning.

```gdscript
extends Control

signal drag_started(piece_node: Control)
signal drag_moved(piece_node: Control, global_pos: Vector2)
signal drag_ended(piece_node: Control, global_pos: Vector2)

var piece_data: BlockPiece
var tray_index: int = -1
var _cell_size: float = 28.0
var _dragging: bool = false
var _drag_offset := Vector2.ZERO
var _original_position := Vector2.ZERO
var _original_parent: Node = null

const DRAG_OFFSET_Y: float = -80.0
const DRAG_SCALE: float = 1.1

func setup(p_piece: BlockPiece, p_index: int, p_cell_size: float) -> void:
    piece_data = p_piece
    tray_index = p_index
    _cell_size = p_cell_size
    mouse_filter = Control.MOUSE_FILTER_STOP

    custom_minimum_size = Vector2(
        piece_data.width * _cell_size,
        piece_data.height * _cell_size
    )
    size = custom_minimum_size
    queue_redraw()

func _draw() -> void:
    if piece_data == null:
        return
    var base_color := AppColors.get_block_color(piece_data.color)
    var light_color := AppColors.get_block_light_color(piece_data.color)
    var glow_color := AppColors.get_block_glow_color(piece_data.color)

    for row_idx in piece_data.shape.size():
        for col_idx in piece_data.shape[row_idx].size():
            if piece_data.shape[row_idx][col_idx] == 1:
                var cell_rect := Rect2(
                    Vector2(col_idx * _cell_size + 1, row_idx * _cell_size + 1),
                    Vector2(_cell_size - 2, _cell_size - 2))

                # Glow
                if glow_color.a > 0.01:
                    var glow_rect := Rect2(
                        Vector2(col_idx * _cell_size, row_idx * _cell_size),
                        Vector2(_cell_size, _cell_size))
                    draw_rect(glow_rect, glow_color)

                # Background
                draw_rect(cell_rect, base_color)

                # Highlight band (top 35%)
                var band_rect := Rect2(
                    cell_rect.position,
                    Vector2(cell_rect.size.x, cell_rect.size.y * 0.35))
                draw_rect(band_rect, Color(light_color.r, light_color.g, light_color.b, 0.4))

                # Border
                draw_rect(cell_rect, light_color, false, 1.0)

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _dragging = true
            _original_position = global_position
            _original_parent = get_parent()
            _drag_offset = global_position - event.global_position
            scale = Vector2.ONE * DRAG_SCALE
            z_index = 100
            drag_started.emit(self)
            accept_event()

func _input(event: InputEvent) -> void:
    if not _dragging:
        return

    if event is InputEventMouseButton:
        if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _dragging = false
            scale = Vector2.ONE
            z_index = 0
            drag_ended.emit(self, event.global_position + Vector2(0, DRAG_OFFSET_Y))
            get_viewport().set_input_as_handled()

    elif event is InputEventMouseMotion:
        global_position = event.global_position + _drag_offset + Vector2(0, DRAG_OFFSET_Y)
        drag_moved.emit(self, event.global_position + Vector2(0, DRAG_OFFSET_Y))
        get_viewport().set_input_as_handled()

func return_to_tray() -> void:
    _dragging = false
    scale = Vector2.ONE
    z_index = 0
    var tween := create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_BACK)
    tween.tween_property(self, "global_position", _original_position, 0.2)

func remove_from_tray() -> void:
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.15)
    tween.tween_callback(queue_free)
```

Changes from current:
- Replace `_build_visual()` with child ColorRects → `_draw()` override with 4-layer rendering
- Store `_original_parent` on drag start for reparent-back tracking
- Keep `return_to_tray()` using `_original_position` (global position stored before reparent)
- Use `queue_redraw()` in `setup()` instead of building child nodes

### 3.6 Scene Changes for Responsive Layout

**File**: `scenes/game/piece_tray.tscn`
**Change**: Remove `@export tray_cell_size` reference (now set programmatically)

```
[gd_scene load_steps=2 format=3 uid="uid://tray001"]

[ext_resource type="Script" path="res://scripts/game/piece_tray.gd" id="1_tray"]

[node name="PieceTray" type="HBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 4
theme_override_constants/separation = 16
script = ExtResource("1_tray")
```

**File**: `scenes/main.tscn`
**Changes**:
- Board node type changes from GridContainer instance to Control instance
- Add `theme` reference to GameUI for Ghibli theme (Phase 2)

---

## 4. Phase 2: Visual Overhaul

### 4.1 Ghibli Theme Resource

**New File**: `theme/game_theme.tres`

This is a Godot Theme resource file that styles all UI controls with the Ghibli color palette.

```
[gd_resource type="Theme" load_steps=8 format=3]

[sub_resource type="StyleBoxFlat" id="btn_normal"]
bg_color = Color(0.482, 0.62, 0.369, 1)
corner_radius_top_left = 12
corner_radius_top_right = 12
corner_radius_bottom_right = 12
corner_radius_bottom_left = 12
content_margin_left = 24.0
content_margin_top = 12.0
content_margin_right = 24.0
content_margin_bottom = 12.0

[sub_resource type="StyleBoxFlat" id="btn_hover"]
bg_color = Color(0.424, 0.557, 0.318, 1)
corner_radius_top_left = 12
corner_radius_top_right = 12
corner_radius_bottom_right = 12
corner_radius_bottom_left = 12
content_margin_left = 24.0
content_margin_top = 12.0
content_margin_right = 24.0
content_margin_bottom = 12.0

[sub_resource type="StyleBoxFlat" id="btn_pressed"]
bg_color = Color(0.353, 0.478, 0.259, 1)
corner_radius_top_left = 12
corner_radius_top_right = 12
corner_radius_bottom_right = 12
corner_radius_bottom_left = 12
content_margin_left = 24.0
content_margin_top = 12.0
content_margin_right = 24.0
content_margin_bottom = 12.0

[sub_resource type="StyleBoxFlat" id="panel_normal"]
bg_color = Color(1, 1, 1, 0.95)
corner_radius_top_left = 16
corner_radius_top_right = 16
corner_radius_bottom_right = 16
corner_radius_bottom_left = 16
content_margin_left = 24.0
content_margin_top = 24.0
content_margin_right = 24.0
content_margin_bottom = 24.0
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.898, 0.867, 0.827, 1)

[sub_resource type="StyleBoxFlat" id="btn_flat_normal"]
bg_color = Color(0, 0, 0, 0)

[sub_resource type="StyleBoxFlat" id="btn_flat_hover"]
bg_color = Color(0, 0, 0, 0.05)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_right = 8
corner_radius_bottom_left = 8

[sub_resource type="StyleBoxEmpty" id="empty_stylebox"]

[resource]
default_font_size = 16

Button/colors/font_color = Color(0.984, 0.969, 0.949, 1)
Button/colors/font_hover_color = Color(1, 1, 1, 1)
Button/colors/font_pressed_color = Color(0.898, 0.867, 0.827, 1)
Button/font_sizes/font_size = 18
Button/styles/normal = SubResource("btn_normal")
Button/styles/hover = SubResource("btn_hover")
Button/styles/pressed = SubResource("btn_pressed")
Button/styles/focus = SubResource("empty_stylebox")

Label/colors/font_color = Color(0.239, 0.208, 0.161, 1)
Label/font_sizes/font_size = 16

PanelContainer/styles/panel = SubResource("panel_normal")
```

**Color Reference** (from AppColors):

| Name | Hex | Usage |
|------|-----|-------|
| SAGE_GREEN | #7B9E5E → `Color(0.482, 0.62, 0.369)` | Button bg |
| SAGE_GREEN_DARK | #5A7A42 → `Color(0.353, 0.478, 0.259)` | Button pressed |
| TEXT_PRIMARY | #3D3529 → `Color(0.239, 0.208, 0.161)` | Label text |
| BACKGROUND | #FBF7F2 → `Color(0.984, 0.969, 0.949)` | Button text, Screen bg |
| BORDER | #E5DDD3 → `Color(0.898, 0.867, 0.827)` | Panel border |

### 4.2 Apply Theme to Main Scene

**File**: `scenes/main.tscn`
**Change**: Add theme resource to GameUI node

```
[ext_resource type="Theme" path="res://theme/game_theme.tres" id="8_theme"]

[node name="GameUI" type="VBoxContainer" parent="UILayer"]
...
theme = ExtResource("8_theme")
```

All child controls (HUD labels, buttons, overlays) inherit this theme automatically.

### 4.3 HomeScreen Redesign

**File**: `scenes/ui/home_screen.tscn`

```
[gd_scene load_steps=2 format=3 uid="uid://home001"]

[ext_resource type="Script" path="res://scripts/ui/home_screen.gd" id="1_home"]

[node name="HomeScreen" type="Control"]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_home")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.984, 0.969, 0.949, 1)

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.4
anchor_right = 0.5
anchor_bottom = 0.4
offset_left = -160.0
offset_top = -140.0
offset_right = 160.0
offset_bottom = 140.0
grow_horizontal = 2
grow_vertical = 2
alignment = 1
theme_override_constants/separation = 32

[node name="Title" type="Label" parent="VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 36
theme_override_colors/font_color = Color(0.482, 0.62, 0.369, 1)
text = "ChromaBlocks"
horizontal_alignment = 1

[node name="Subtitle" type="Label" parent="VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
theme_override_colors/font_color = Color(0.478, 0.447, 0.4, 1)
text = "Color Block Puzzle"
horizontal_alignment = 1

[node name="BestScore" type="Label" parent="VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 16
theme_override_colors/font_color = Color(0.831, 0.659, 0.333, 1)
text = "BEST: 0"
horizontal_alignment = 1

[node name="StartButton" type="Button" parent="VBox"]
layout_mode = 2
size_flags_horizontal = 4
custom_minimum_size = Vector2(220, 56)
text = "START GAME"

[node name="SoundToggle" type="Button" parent="VBox"]
layout_mode = 2
size_flags_horizontal = 4
custom_minimum_size = Vector2(140, 40)
theme_override_font_sizes/font_size = 14
text = "Sound: ON"
flat = true
```

**File**: `scripts/ui/home_screen.gd`

```gdscript
extends Control

signal start_pressed()

@onready var title_label: Label = $VBox/Title
@onready var best_score_label: Label = $VBox/BestScore
@onready var start_button: Button = $VBox/StartButton
@onready var sound_toggle: Button = $VBox/SoundToggle

func _ready() -> void:
    start_button.pressed.connect(func(): start_pressed.emit())
    sound_toggle.pressed.connect(_toggle_sound)
    best_score_label.text = "BEST: " + str(SaveManager.get_high_score())
    _update_sound_label()

func _toggle_sound() -> void:
    var enabled := not SaveManager.is_sound_enabled()
    SaveManager.set_sound_enabled(enabled)
    _update_sound_label()

func _update_sound_label() -> void:
    sound_toggle.text = "Sound: ON" if SaveManager.is_sound_enabled() else "Sound: OFF"
```

Changes: Add sound toggle button and subtitle label. Style title with sage green and larger font.

### 4.4 GameOverScreen Redesign

**File**: `scenes/ui/game_over_screen.tscn`

```
[gd_scene load_steps=2 format=3 uid="uid://gameover001"]

[ext_resource type="Script" path="res://scripts/ui/game_over_screen.gd" id="1_go"]

[node name="GameOverScreen" type="Control"]
unique_name_in_owner = true
visible = false
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_go")

[node name="Overlay" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0, 0, 0, 0.5)

[node name="Card" type="PanelContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -160.0
offset_top = -200.0
offset_right = 160.0
offset_bottom = 200.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBox" type="VBoxContainer" parent="Card"]
layout_mode = 2
alignment = 1
theme_override_constants/separation = 16

[node name="GameOverTitle" type="Label" parent="Card/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 24
theme_override_colors/font_color = Color(0.239, 0.208, 0.161, 1)
text = "GAME OVER"
horizontal_alignment = 1

[node name="FinalScore" type="Label" parent="Card/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 40
theme_override_colors/font_color = Color(0.482, 0.62, 0.369, 1)
text = "0"
horizontal_alignment = 1

[node name="NewBestBadge" type="Label" parent="Card/VBox"]
layout_mode = 2
visible = false
theme_override_font_sizes/font_size = 16
theme_override_colors/font_color = Color(0.831, 0.659, 0.333, 1)
text = "NEW BEST!"
horizontal_alignment = 1

[node name="Separator" type="HSeparator" parent="Card/VBox"]
layout_mode = 2

[node name="Stats" type="HBoxContainer" parent="Card/VBox"]
layout_mode = 2
alignment = 1
theme_override_constants/separation = 32

[node name="LinesBox" type="VBoxContainer" parent="Card/VBox/Stats"]
layout_mode = 2
alignment = 1

[node name="LinesValue" type="Label" parent="Card/VBox/Stats/LinesBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "0"
horizontal_alignment = 1

[node name="LinesLabel" type="Label" parent="Card/VBox/Stats/LinesBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 12
theme_override_colors/font_color = Color(0.478, 0.447, 0.4, 1)
text = "Lines"
horizontal_alignment = 1

[node name="BlocksBox" type="VBoxContainer" parent="Card/VBox/Stats"]
layout_mode = 2
alignment = 1

[node name="BlocksValue" type="Label" parent="Card/VBox/Stats/BlocksBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "0"
horizontal_alignment = 1

[node name="BlocksLabel" type="Label" parent="Card/VBox/Stats/BlocksBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 12
theme_override_colors/font_color = Color(0.478, 0.447, 0.4, 1)
text = "Blocks"
horizontal_alignment = 1

[node name="CombosBox" type="VBoxContainer" parent="Card/VBox/Stats"]
layout_mode = 2
alignment = 1

[node name="CombosValue" type="Label" parent="Card/VBox/Stats/CombosBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "0"
horizontal_alignment = 1

[node name="CombosLabel" type="Label" parent="Card/VBox/Stats/CombosBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 12
theme_override_colors/font_color = Color(0.478, 0.447, 0.4, 1)
text = "Combos"
horizontal_alignment = 1

[node name="PlayAgainButton" type="Button" parent="Card/VBox"]
layout_mode = 2
size_flags_horizontal = 4
custom_minimum_size = Vector2(220, 56)
text = "PLAY AGAIN"

[node name="HomeButton" type="Button" parent="Card/VBox"]
layout_mode = 2
size_flags_horizontal = 4
custom_minimum_size = Vector2(220, 44)
text = "HOME"
flat = true
```

**File**: `scripts/ui/game_over_screen.gd`

```gdscript
extends Control

signal play_again_pressed()
signal go_home_pressed()

@onready var final_score: Label = $Card/VBox/FinalScore
@onready var new_best_badge: Label = $Card/VBox/NewBestBadge
@onready var lines_value: Label = $Card/VBox/Stats/LinesBox/LinesValue
@onready var blocks_value: Label = $Card/VBox/Stats/BlocksBox/BlocksValue
@onready var combos_value: Label = $Card/VBox/Stats/CombosBox/CombosValue

func _ready() -> void:
    $Card/VBox/PlayAgainButton.pressed.connect(func(): play_again_pressed.emit())
    $Card/VBox/HomeButton.pressed.connect(func(): go_home_pressed.emit())

func show_result(state: GameState) -> void:
    visible = true
    final_score.text = str(state.score)
    new_best_badge.visible = state.score > state.high_score and state.score > 0
    lines_value.text = str(state.lines_cleared)
    blocks_value.text = str(state.blocks_placed)
    combos_value.text = str(state.total_color_matches)
```

Changes: Wrap content in PanelContainer (Card) for styled border/shadow. Stats show labeled values vertically. Use themed fonts/colors.

### 4.5 PauseScreen Redesign

**File**: `scenes/ui/pause_screen.tscn`

```
[gd_scene load_steps=2 format=3 uid="uid://pause001"]

[ext_resource type="Script" path="res://scripts/ui/pause_screen.gd" id="1_pause"]

[node name="PauseScreen" type="Control"]
unique_name_in_owner = true
visible = false
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_pause")

[node name="Overlay" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0, 0, 0, 0.4)

[node name="Card" type="PanelContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -120.0
offset_top = -100.0
offset_right = 120.0
offset_bottom = 100.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBox" type="VBoxContainer" parent="Card"]
layout_mode = 2
alignment = 1
theme_override_constants/separation = 16

[node name="PausedLabel" type="Label" parent="Card/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 24
text = "PAUSED"
horizontal_alignment = 1

[node name="ResumeButton" type="Button" parent="Card/VBox"]
layout_mode = 2
size_flags_horizontal = 4
custom_minimum_size = Vector2(180, 50)
text = "RESUME"

[node name="QuitButton" type="Button" parent="Card/VBox"]
layout_mode = 2
size_flags_horizontal = 4
custom_minimum_size = Vector2(180, 44)
text = "QUIT"
flat = true
```

**File**: `scripts/ui/pause_screen.gd` — UNCHANGED (signal wiring is correct)

```gdscript
extends Control

signal resume_pressed()
signal quit_pressed()

func _ready() -> void:
    $Card/VBox/ResumeButton.pressed.connect(func(): resume_pressed.emit())
    $Card/VBox/QuitButton.pressed.connect(func(): quit_pressed.emit())
```

Note: Node paths changed from `$VBox/` to `$Card/VBox/`.

### 4.6 HUD Redesign

**File**: `scenes/ui/hud.tscn`

```
[gd_scene load_steps=2 format=3 uid="uid://hud001"]

[ext_resource type="Script" path="res://scripts/ui/hud.gd" id="1_hud"]

[node name="HUD" type="HBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8
script = ExtResource("1_hud")

[node name="MenuButton" type="Button" parent="."]
layout_mode = 2
custom_minimum_size = Vector2(40, 40)
text = "||"
flat = true

[node name="ScoreLabel" type="Label" parent="."]
layout_mode = 2
size_flags_horizontal = 3
theme_override_font_sizes/font_size = 22
text = "0"
horizontal_alignment = 1

[node name="LevelLabel" type="Label" parent="."]
layout_mode = 2
theme_override_font_sizes/font_size = 14
theme_override_colors/font_color = Color(0.478, 0.447, 0.4, 1)
text = "Lv.1"
horizontal_alignment = 1

[node name="ComboLabel" type="Label" parent="."]
layout_mode = 2
visible = false
theme_override_font_sizes/font_size = 14
theme_override_colors/font_color = Color(0.831, 0.659, 0.333, 1)
text = "COMBO x1.0"
horizontal_alignment = 1

[node name="BestLabel" type="Label" parent="."]
layout_mode = 2
theme_override_font_sizes/font_size = 12
theme_override_colors/font_color = Color(0.478, 0.447, 0.4, 1)
text = "BEST: 0"
horizontal_alignment = 2
```

**File**: `scripts/ui/hud.gd` — Minor formatting update

```gdscript
extends HBoxContainer

@onready var score_label: Label = $ScoreLabel
@onready var level_label: Label = $LevelLabel
@onready var combo_label: Label = $ComboLabel
@onready var best_label: Label = $BestLabel

func update_from_state(state: GameState) -> void:
    score_label.text = str(state.score)
    level_label.text = "Lv." + str(state.level)
    best_label.text = "BEST: " + str(state.high_score)
    if state.combo > 0:
        var idx := clampi(state.combo, 0, GameConstants.COMBO_MULTIPLIERS.size() - 1)
        combo_label.text = "COMBO x" + str(GameConstants.COMBO_MULTIPLIERS[idx])
        combo_label.visible = true
    else:
        combo_label.visible = false
```

Unchanged logic, only scene styling changes.

### 4.7 Score Popup Enhancement

**File**: `scripts/game/score_popup.gd`

```gdscript
extends Label

func show_score(value: int, start_pos: Vector2) -> void:
    text = "+" + str(value)
    global_position = start_pos
    modulate.a = 1.0

    # Style based on value
    if value >= 2000:
        # Perfect clear — golden, larger
        add_theme_font_size_override("font_size", 32)
        add_theme_color_override("font_color", AppColors.GOLDEN)
    elif value >= 500:
        # Big score — sage green, medium
        add_theme_font_size_override("font_size", 28)
        add_theme_color_override("font_color", AppColors.SAGE_GREEN)
    else:
        # Normal — primary text color
        add_theme_font_size_override("font_size", 22)
        add_theme_color_override("font_color", AppColors.TEXT_PRIMARY)

    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "global_position:y", start_pos.y - 80, 0.8) \
         .set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "modulate:a", 0.0, 0.8) \
         .set_ease(Tween.EASE_IN).set_delay(0.3)
    tween.chain().tween_callback(queue_free)
```

Changes: Score value-dependent styling. Larger/golden for perfect clear, green for big scores.

---

## 5. Phase 3: Sound System

### 5.1 Procedural Sound Generator

**New File**: `scripts/utils/sfx_generator.gd`

Generates simple AudioStreamWAV sounds procedurally (no external audio files needed).

```gdscript
class_name SFXGenerator

const SAMPLE_RATE := 22050
const MAX_16BIT := 32767.0

static func generate_block_place() -> AudioStreamWAV:
    return _generate_tone(220.0, 0.08, 0.8, "sine")

static func generate_line_clear() -> AudioStreamWAV:
    # Rising chime: 3 quick ascending tones
    var samples := PackedByteArray()
    var total_samples := int(SAMPLE_RATE * 0.25)
    var freqs := [523.0, 659.0, 784.0]  # C5, E5, G5

    for i in total_samples:
        var t := float(i) / SAMPLE_RATE
        var freq_idx := mini(int(t / 0.083), 2)
        var freq: float = freqs[freq_idx]
        var envelope := maxf(0.0, 1.0 - t * 3.0) * 0.6
        var sample := sin(t * freq * TAU) * envelope
        var s16 := int(clampf(sample, -1.0, 1.0) * MAX_16BIT)
        samples.append(s16 & 0xFF)
        samples.append((s16 >> 8) & 0xFF)

    return _make_wav(samples)

static func generate_color_match() -> AudioStreamWAV:
    # Sparkle: high frequency with fast decay
    return _generate_tone(880.0, 0.15, 0.5, "triangle")

static func generate_combo() -> AudioStreamWAV:
    # Ascending quick notes
    var samples := PackedByteArray()
    var total_samples := int(SAMPLE_RATE * 0.2)
    var freqs := [440.0, 554.0, 659.0, 880.0]

    for i in total_samples:
        var t := float(i) / SAMPLE_RATE
        var freq_idx := mini(int(t / 0.05), 3)
        var freq: float = freqs[freq_idx]
        var envelope := maxf(0.0, 1.0 - t * 4.0) * 0.5
        var sample := sin(t * freq * TAU) * envelope
        var s16 := int(clampf(sample, -1.0, 1.0) * MAX_16BIT)
        samples.append(s16 & 0xFF)
        samples.append((s16 >> 8) & 0xFF)

    return _make_wav(samples)

static func generate_level_up() -> AudioStreamWAV:
    # Fanfare: major chord arpeggio
    var samples := PackedByteArray()
    var total_samples := int(SAMPLE_RATE * 0.4)
    var freqs := [523.0, 659.0, 784.0, 1047.0]

    for i in total_samples:
        var t := float(i) / SAMPLE_RATE
        var freq_idx := mini(int(t / 0.1), 3)
        var freq: float = freqs[freq_idx]
        var envelope := maxf(0.0, 1.0 - t * 2.0) * 0.5
        var sample := sin(t * freq * TAU) * envelope
        var s16 := int(clampf(sample, -1.0, 1.0) * MAX_16BIT)
        samples.append(s16 & 0xFF)
        samples.append((s16 >> 8) & 0xFF)

    return _make_wav(samples)

static func generate_game_over() -> AudioStreamWAV:
    # Descending minor: sad tone
    var samples := PackedByteArray()
    var total_samples := int(SAMPLE_RATE * 0.5)

    for i in total_samples:
        var t := float(i) / SAMPLE_RATE
        var freq := lerpf(440.0, 220.0, t * 2.0)  # Descending pitch
        var envelope := maxf(0.0, 1.0 - t * 1.8) * 0.5
        var sample := sin(t * freq * TAU) * envelope
        var s16 := int(clampf(sample, -1.0, 1.0) * MAX_16BIT)
        samples.append(s16 & 0xFF)
        samples.append((s16 >> 8) & 0xFF)

    return _make_wav(samples)

static func generate_perfect_clear() -> AudioStreamWAV:
    # Triumphant: full chord then high note
    var samples := PackedByteArray()
    var total_samples := int(SAMPLE_RATE * 0.5)

    for i in total_samples:
        var t := float(i) / SAMPLE_RATE
        var envelope := maxf(0.0, 1.0 - t * 1.5) * 0.4
        # Major chord (C5 + E5 + G5)
        var sample := (sin(t * 523.0 * TAU) + sin(t * 659.0 * TAU) + sin(t * 784.0 * TAU)) / 3.0
        if t > 0.3:
            # High note resolve
            sample = sin(t * 1047.0 * TAU) * maxf(0.0, 1.0 - (t - 0.3) * 5.0)
        sample *= envelope
        var s16 := int(clampf(sample, -1.0, 1.0) * MAX_16BIT)
        samples.append(s16 & 0xFF)
        samples.append((s16 >> 8) & 0xFF)

    return _make_wav(samples)

static func generate_button_press() -> AudioStreamWAV:
    return _generate_tone(660.0, 0.04, 0.3, "sine")


# ── Private Helpers ──

static func _generate_tone(freq: float, duration: float, volume: float, wave_type: String) -> AudioStreamWAV:
    var samples := PackedByteArray()
    var total_samples := int(SAMPLE_RATE * duration)

    for i in total_samples:
        var t := float(i) / SAMPLE_RATE
        var envelope := maxf(0.0, 1.0 - t / duration) * volume
        var sample := 0.0

        match wave_type:
            "sine":
                sample = sin(t * freq * TAU) * envelope
            "triangle":
                var phase := fmod(t * freq, 1.0)
                sample = (4.0 * absf(phase - 0.5) - 1.0) * envelope

        var s16 := int(clampf(sample, -1.0, 1.0) * MAX_16BIT)
        samples.append(s16 & 0xFF)
        samples.append((s16 >> 8) & 0xFF)

    return _make_wav(samples)

static func _make_wav(samples: PackedByteArray) -> AudioStreamWAV:
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = SAMPLE_RATE
    wav.data = samples
    wav.stereo = false
    return wav
```

### 5.2 SoundManager Update

**File**: `scripts/utils/sound_manager.gd`

```gdscript
extends Node

@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

var _sounds: Dictionary = {}

func _ready() -> void:
    # Generate all sounds procedurally at startup
    _sounds["block_place"] = SFXGenerator.generate_block_place()
    _sounds["line_clear"] = SFXGenerator.generate_line_clear()
    _sounds["color_match"] = SFXGenerator.generate_color_match()
    _sounds["combo"] = SFXGenerator.generate_combo()
    _sounds["level_up"] = SFXGenerator.generate_level_up()
    _sounds["game_over"] = SFXGenerator.generate_game_over()
    _sounds["perfect_clear"] = SFXGenerator.generate_perfect_clear()
    _sounds["button_press"] = SFXGenerator.generate_button_press()

func play_sfx(sfx_name: String) -> void:
    if not SaveManager.is_sound_enabled():
        return
    if _sounds.has(sfx_name):
        sfx_player.stream = _sounds[sfx_name]
        sfx_player.play()
```

Changes: Replace commented-out preloads with `SFXGenerator` calls. All sounds are generated in `_ready()` and cached. No external audio files needed.

### 5.3 Wire Remaining Sound Events

**File**: `scripts/game/chroma_blocks_game.gd`

Add block place sound in `_place_piece()`:

```gdscript
func _place_piece(piece: BlockPiece, gx: int, gy: int, tray_index: int) -> void:
    # 1. Place on board
    SoundManager.play_sfx("block_place")
    HapticManager.light()
    var board := _state.board.place_piece(piece, gx, gy)
    # ... rest unchanged
```

Add combo sound where combo increases:

```gdscript
    # In _place_piece, after new_combo calculation:
    if new_combo >= 2:
        SoundManager.play_sfx("combo")
```

---

## 6. Phase 4: ChromaBlocksGame Main Script Updates

### 6.1 Complete Updated Script

**File**: `scripts/game/chroma_blocks_game.gd`

```gdscript
extends Node

signal state_changed(state: GameState)
signal game_over_triggered()

@onready var board_renderer: Control = %Board
@onready var piece_tray: HBoxContainer = %PieceTray
@onready var hud: Control = %HUD
@onready var home_screen: Control = %HomeScreen
@onready var game_over_screen: Control = %GameOverScreen
@onready var pause_screen: Control = %PauseScreen
@onready var drag_layer: Control = %DragLayer

var _state: GameState

func _ready() -> void:
    # Force portrait orientation on mobile
    DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)

    _state = GameState.new()
    _state.high_score = SaveManager.get_high_score()
    board_renderer.initialize()

    # Set tray cell size based on board cell size
    piece_tray.set_cell_size(board_renderer.get_cell_size())

    piece_tray.piece_drag_started.connect(_on_drag_started)
    piece_tray.piece_drag_moved.connect(_on_drag_moved)
    piece_tray.piece_drag_ended.connect(_on_drag_ended)

    home_screen.start_pressed.connect(start_game)
    game_over_screen.play_again_pressed.connect(start_game)
    game_over_screen.go_home_pressed.connect(_show_home)
    pause_screen.resume_pressed.connect(resume_game)
    pause_screen.quit_pressed.connect(_show_home)

    var menu_btn := hud.get_node_or_null("MenuButton")
    if menu_btn:
        menu_btn.pressed.connect(pause_game)

    _show_home()

# ── Public API ──

func start_game() -> void:
    _state.reset()
    _state.high_score = SaveManager.get_high_score()
    _state.status = Enums.GameStatus.PLAYING
    SaveManager.increment_games_played()

    var tray := PieceDefinitions.generate_tray(_state.level)
    _state.tray_pieces = tray

    board_renderer.update_from_state(_state.board)
    piece_tray.populate_tray(tray)
    hud.update_from_state(_state)

    home_screen.visible = false
    game_over_screen.visible = false
    pause_screen.visible = false

    state_changed.emit(_state)

func pause_game() -> void:
    _state.status = Enums.GameStatus.PAUSED
    pause_screen.visible = true

func resume_game() -> void:
    _state.status = Enums.GameStatus.PLAYING
    pause_screen.visible = false

# ── Drag & Drop ──

var _dragging_piece: BlockPiece = null
var _dragging_index: int = -1
var _last_grid_pos := Vector2i(-1, -1)

func _on_drag_started(piece_node: Control) -> void:
    if _state.status != Enums.GameStatus.PLAYING:
        return
    _dragging_piece = piece_node.piece_data
    _dragging_index = piece_node.tray_index
    piece_node.reparent(drag_layer)

func _on_drag_moved(piece_node: Control, global_pos: Vector2) -> void:
    if _dragging_piece == null:
        return
    var local_pos: Vector2 = board_renderer.get_global_transform().affine_inverse() * global_pos
    var grid_pos: Vector2i = board_renderer.world_to_grid(local_pos)

    if grid_pos != _last_grid_pos:
        _last_grid_pos = grid_pos
        var can_place := PlacementSystem.can_place(
            _state.board, _dragging_piece, grid_pos.x, grid_pos.y)
        board_renderer.show_highlight(grid_pos.x, grid_pos.y, _dragging_piece, can_place)

func _on_drag_ended(piece_node: Control, global_pos: Vector2) -> void:
    if _dragging_piece == null:
        return

    board_renderer.clear_highlights()
    var local_pos: Vector2 = board_renderer.get_global_transform().affine_inverse() * global_pos
    var grid_pos: Vector2i = board_renderer.world_to_grid(local_pos)

    var can_place := PlacementSystem.can_place(
        _state.board, _dragging_piece, grid_pos.x, grid_pos.y)

    if can_place:
        _place_piece(_dragging_piece, grid_pos.x, grid_pos.y, _dragging_index)
        piece_node.remove_from_tray()
    else:
        piece_node.return_to_tray()
        piece_node.reparent(piece_tray)

    _dragging_piece = null
    _dragging_index = -1
    _last_grid_pos = Vector2i(-1, -1)

# ── Core Game Logic ──

func _place_piece(piece: BlockPiece, gx: int, gy: int, tray_index: int) -> void:
    SoundManager.play_sfx("block_place")
    HapticManager.light()

    # 1. Place on board
    var board := _state.board.place_piece(piece, gx, gy)

    # 2. Line clear
    var clear_result := ClearSystem.check_and_clear(board)
    board = clear_result["board"]

    # 3. Color match
    var color_result := ColorMatchSystem.check_color_match(board)
    board = color_result["board"]

    # 4. Scoring
    var did_clear: bool = clear_result["lines_cleared"] > 0 or color_result["total_removed"] > 0
    var new_combo: int = (_state.combo + 1) if did_clear else 0

    var score_result := ScoringSystem.calculate(
        piece.cell_count, clear_result, color_result, new_combo, _state.level)

    # 5. Level check
    var total_lines: int = _state.lines_cleared + clear_result["lines_cleared"]
    var new_level: int = DifficultySystem.calculate_level(total_lines)
    var leveled_up: bool = new_level > _state.level

    # 6. Update state
    _state.board = board
    _state.score += score_result["total"]
    _state.lines_cleared = total_lines
    _state.combo = new_combo
    _state.level = new_level
    _state.blocks_placed += 1
    _state.total_color_matches += color_result["groups"].size()
    _state.tray_pieces.remove_at(tray_index)

    # 7. Visual updates
    board_renderer.update_from_state(board)
    hud.update_from_state(_state)

    # 8. Effects
    if clear_result["has_clears"]:
        board_renderer.play_line_clear_effect(clear_result["rows"], clear_result["cols"])
        SoundManager.play_sfx("line_clear")
        HapticManager.line_clear()

    if color_result["has_matches"]:
        board_renderer.play_color_match_effect(color_result["groups"])
        SoundManager.play_sfx("color_match")
        HapticManager.color_match()

    if new_combo >= 2:
        SoundManager.play_sfx("combo")

    if score_result["total"] > 0:
        _spawn_score_popup(score_result["total"], gx, gy)

    if clear_result.get("is_perfect", false):
        _spawn_score_popup(GameConstants.PERFECT_CLEAR_BONUS, 5, 5)
        SoundManager.play_sfx("perfect_clear")

    if leveled_up:
        SoundManager.play_sfx("level_up")

    # 9. Tray refill or game over
    if _state.tray_pieces.is_empty():
        _refill_tray()
    else:
        _check_game_over()

    state_changed.emit(_state)

func _refill_tray() -> void:
    var new_tray := PieceDefinitions.generate_tray(_state.level)
    _state.tray_pieces = new_tray
    piece_tray.populate_tray(new_tray)
    _check_game_over()

func _check_game_over() -> void:
    if GameOverSystem.is_game_over(_state.board, _state.tray_pieces):
        _state.status = Enums.GameStatus.GAME_OVER
        SaveManager.save_high_score(_state.score)
        SoundManager.play_sfx("game_over")
        HapticManager.game_over()
        game_over_screen.show_result(_state)
        game_over_triggered.emit()

func _spawn_score_popup(value: int, gx: int, gy: int) -> void:
    var popup := Label.new()
    popup.set_script(preload("res://scripts/game/score_popup.gd"))
    drag_layer.add_child(popup)
    var cell_size := board_renderer.get_cell_size()
    var pos := board_renderer.global_position + Vector2(gx * cell_size, gy * cell_size)
    popup.show_score(value, pos)

func _show_home() -> void:
    home_screen.visible = true
    game_over_screen.visible = false
    pause_screen.visible = false
```

Key changes from current:
1. Line 1: `@onready var board_renderer: Control` (was `GridContainer`)
2. Added `DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)` in `_ready()`
3. Added `piece_tray.set_cell_size(board_renderer.get_cell_size())` in `_ready()`
4. Added `SaveManager.increment_games_played()` in `start_game()`
5. Added `SoundManager.play_sfx("block_place")` + `HapticManager.light()` at start of `_place_piece()`
6. Added `SoundManager.play_sfx("combo")` for combo >= 2
7. `_spawn_score_popup` uses `board_renderer.get_cell_size()` instead of inline calculation
8. Removed `add_theme_font_size_override` and `add_theme_color_override` from `_spawn_score_popup` (now in score_popup.gd)

---

## 7. Files to Delete

These files are empty stubs and serve no purpose:

| File | Reason |
|------|--------|
| `scripts/game/grid_highlight.gd` | Only contains class_name + comments. Highlight logic is in board_renderer and cell_view |
| `scripts/game/clear_effect.gd` | Only contains class_name + comments. Clear effects are in cell_view |

---

## 8. Updated main.tscn

**File**: `scenes/main.tscn`

```
[gd_scene load_steps=9 format=3 uid="uid://main001"]

[ext_resource type="Script" path="res://scripts/game/chroma_blocks_game.gd" id="1_game"]
[ext_resource type="PackedScene" uid="uid://board001" path="res://scenes/game/board.tscn" id="2_board"]
[ext_resource type="PackedScene" uid="uid://tray001" path="res://scenes/game/piece_tray.tscn" id="3_tray"]
[ext_resource type="PackedScene" uid="uid://hud001" path="res://scenes/ui/hud.tscn" id="4_hud"]
[ext_resource type="PackedScene" uid="uid://home001" path="res://scenes/ui/home_screen.tscn" id="5_home"]
[ext_resource type="PackedScene" uid="uid://gameover001" path="res://scenes/ui/game_over_screen.tscn" id="6_gameover"]
[ext_resource type="PackedScene" uid="uid://pause001" path="res://scenes/ui/pause_screen.tscn" id="7_pause"]
[ext_resource type="Theme" path="res://theme/game_theme.tres" id="8_theme"]

[node name="Main" type="Node"]
script = ExtResource("1_game")

[node name="UILayer" type="CanvasLayer" parent="."]

[node name="GameUI" type="VBoxContainer" parent="UILayer"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme = ExtResource("8_theme")
theme_override_constants/separation = 16

[node name="TopMargin" type="MarginContainer" parent="UILayer/GameUI"]
layout_mode = 2
theme_override_constants/margin_left = 16
theme_override_constants/margin_top = 48
theme_override_constants/margin_right = 16

[node name="HUD" parent="UILayer/GameUI/TopMargin" instance=ExtResource("4_hud")]

[node name="BoardContainer" type="CenterContainer" parent="UILayer/GameUI"]
layout_mode = 2
size_flags_vertical = 3

[node name="Board" parent="UILayer/GameUI/BoardContainer" instance=ExtResource("2_board")]
unique_name_in_owner = true

[node name="TrayContainer" type="CenterContainer" parent="UILayer/GameUI"]
layout_mode = 2
custom_minimum_size = Vector2(0, 120)

[node name="PieceTray" parent="UILayer/GameUI/TrayContainer" instance=ExtResource("3_tray")]
unique_name_in_owner = true

[node name="DragLayer" type="Control" parent="UILayer"]
unique_name_in_owner = true
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="HomeScreen" parent="UILayer" instance=ExtResource("5_home")]

[node name="GameOverScreen" parent="UILayer" instance=ExtResource("6_gameover")]

[node name="PauseScreen" parent="UILayer" instance=ExtResource("7_pause")]

[node name="AudioPlayers" type="Node" parent="."]

[node name="SFXPlayer" type="AudioStreamPlayer" parent="AudioPlayers"]

[node name="MusicPlayer" type="AudioStreamPlayer" parent="AudioPlayers"]
```

Changes from current:
1. Added `[ext_resource type="Theme" path="res://theme/game_theme.tres" id="8_theme"]`
2. Added `theme = ExtResource("8_theme")` to GameUI node
3. Board instance works with both GridContainer and Control (packed scene change handles it)

---

## 9. Implementation Order

| Step | Files | Dependencies | Description |
|------|-------|-------------|-------------|
| 1 | `cell_view.gd`, `cell.tscn` | None | Rewrite cell to Control + _draw() |
| 2 | `board_renderer.gd`, `board.tscn` | Step 1 | Rewrite board to Control + manual layout + dynamic sizing |
| 3 | `draggable_piece.gd` | Step 2 (needs cell_size) | Rewrite piece rendering to _draw(), fix return_to_tray |
| 4 | `piece_tray.gd`, `piece_tray.tscn` | Step 3 | Add set_cell_size(), remove @export |
| 5 | `chroma_blocks_game.gd` | Steps 1-4 | Add orientation fix, wire cell_size, add sounds |
| 6 | `theme/game_theme.tres` | None | Create Ghibli theme resource |
| 7 | `main.tscn` | Step 6 | Apply theme to GameUI |
| 8 | `home_screen.tscn`, `home_screen.gd` | Step 7 | Redesign with theme + sound toggle |
| 9 | `game_over_screen.tscn`, `game_over_screen.gd` | Step 7 | Redesign with card layout + themed stats |
| 10 | `pause_screen.tscn`, `pause_screen.gd` | Step 7 | Redesign with card layout |
| 11 | `hud.tscn` | Step 7 | Styled labels with font sizes/colors |
| 12 | `score_popup.gd` | Step 7 | Value-dependent styling |
| 13 | `sfx_generator.gd` | None | Create procedural sound generator |
| 14 | `sound_manager.gd` | Step 13 | Wire generated sounds |
| 15 | Delete stubs | None | Remove grid_highlight.gd, clear_effect.gd |
| 16 | Test in editor | Steps 1-15 | Verify all features work |
| 17 | Export APK | Step 16 | Build and test on Android |

---

## 10. File Change Summary

### New Files (2)

| File | Lines | Purpose |
|------|-------|---------|
| `theme/game_theme.tres` | ~80 | Godot Theme resource with Ghibli colors |
| `scripts/utils/sfx_generator.gd` | ~140 | Procedural sound effect generation |

### Modified Files — Major Rewrite (5)

| File | Current Lines | New Lines | Change |
|------|--------------|-----------|--------|
| `scripts/game/cell_view.gd` | 48 | ~95 | PanelContainer → Control + _draw() |
| `scenes/game/cell.tscn` | 27 | ~6 | Remove 4 child nodes, PanelContainer → Control |
| `scripts/game/board_renderer.gd` | 62 | ~100 | GridContainer → Control, manual layout, dynamic sizing, board bg |
| `scenes/game/board.tscn` | 8 | ~6 | GridContainer → Control |
| `scripts/game/draggable_piece.gd` | 81 | ~95 | ColorRect children → _draw() rendering |

### Modified Files — Significant Changes (7)

| File | Change Summary |
|------|---------------|
| `scripts/game/chroma_blocks_game.gd` | +orientation, +cell_size wiring, +sounds, type fix |
| `scripts/game/piece_tray.gd` | +set_cell_size(), remove @export |
| `scripts/utils/sound_manager.gd` | Replace commented preloads with SFXGenerator calls |
| `scenes/ui/home_screen.tscn` | Redesigned with Ghibli styling + sound toggle |
| `scripts/ui/home_screen.gd` | +sound toggle functionality |
| `scenes/ui/game_over_screen.tscn` | Redesigned with card layout + labeled stats |
| `scripts/ui/game_over_screen.gd` | Updated node paths for card layout |

### Modified Files — Minor Changes (5)

| File | Change Summary |
|------|---------------|
| `scenes/main.tscn` | +theme reference |
| `scenes/ui/pause_screen.tscn` | +PanelContainer card, styled |
| `scripts/ui/pause_screen.gd` | Updated node paths |
| `scenes/ui/hud.tscn` | Font size/color overrides |
| `scripts/game/score_popup.gd` | Value-dependent styling |

### Deleted Files (2)

| File | Reason |
|------|--------|
| `scripts/game/grid_highlight.gd` | Empty stub |
| `scripts/game/clear_effect.gd` | Empty stub |

---

## 11. Verification Checklist

| # | Test | Expected Result |
|---|------|-----------------|
| 1 | Run in Godot editor (PC) | Game loads, cells render with 4-layer Luminous Flow effect |
| 2 | Resize editor viewport | Board and cells resize dynamically, maintain square aspect |
| 3 | Start game | 3 pieces in tray with Luminous Flow rendering |
| 4 | Drag piece over board | Green/red highlight shows on grid |
| 5 | Drop piece on valid position | Piece places, cells render correctly, score popup appears |
| 6 | Complete a line | Sequential flash animation, line_clear sound plays |
| 7 | Color match (5+ same color) | Flash animation, color_match sound plays |
| 8 | Build APK, install on Android | Game opens in portrait mode |
| 9 | Touch/drag on Android | Pieces draggable with finger offset |
| 10 | Home screen appearance | Sage green title, cream background, themed buttons |
| 11 | Game over screen | Card with styled stats (Lines/Blocks/Combos with labels) |
| 12 | Pause screen | Card with styled Resume/Quit buttons |
| 13 | Sound toggle on home | Toggles between ON/OFF, persists |
| 14 | 10-minute play session | No crashes, no memory growth |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-10 | Initial design based on game-redesign plan | AI-Assisted |
