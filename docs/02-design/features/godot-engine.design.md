# Godot Engine Design Document

> **Summary**: ChromaBlocks 게임을 Godot 4 + GDScript로 구현하는 기술 설계. 모든 씬(.tscn), 리소스(.tres), 스크립트(.gd)를 텍스트로 직접 생성한다.
>
> **Project**: ChromaBlocks (Godot 4)
> **Version**: 0.1.0
> **Author**: AI-Assisted
> **Date**: 2026-02-10
> **Status**: Draft
> **Planning Doc**: [godot-engine.plan.md](../../01-plan/features/godot-engine.plan.md)
> **Game Design**: [game-pivot.plan.md](../../01-plan/features/game-pivot.plan.md) + [game-pivot.design.md](game-pivot.design.md)

---

## 1. Overview

### 1.1 Design Goals

1. 기존 Unity C# 로직을 GDScript로 1:1 변환 (게임 사양 동일)
2. .tscn/.gd 텍스트 파일로 프로젝트 전체 생성 (에디터 의존 최소화)
3. Godot 4 네이티브 패턴 활용 (Signal, Tween, Control 노드)
4. 모바일 최적화 (터치 입력, 60fps, <30MB APK)
5. "Luminous Flow" + Ghibli 테마 비주얼 유지

### 1.2 Design Principles

- **Godot-native**: Unity 패턴을 그대로 옮기지 않고 Godot 방식으로 재설계
- **Signal 기반 통신**: 컴포넌트 간 직접 참조 최소화, Signal로 느슨한 결합
- **씬 합성(Composition)**: 작은 씬을 조합하여 복잡한 화면 구성
- **Static 시스템 유지**: 순수 게임 로직은 static 함수로 유지 (테스트 용이)

---

## 2. Architecture

### 2.1 Node Tree Overview

```
Main (Node) — chroma_blocks_game.gd
├── UILayer (CanvasLayer)
│   ├── HomeScreen (Control) — home_screen.gd
│   ├── GameUI (Control)
│   │   ├── HUD (HBoxContainer) — hud.gd
│   │   ├── BoardContainer (CenterContainer)
│   │   │   └── Board (GridContainer) — board_renderer.gd
│   │   │       └── Cell x100 (PanelContainer) — cell_view.gd
│   │   ├── TrayContainer (HBoxContainer)
│   │   │   └── PieceTray (HBoxContainer) — piece_tray.gd
│   │   │       └── DraggablePiece x3 — draggable_piece.gd
│   │   └── DragLayer (Control)  ← 드래그 중 피스 + 하이라이트
│   ├── PauseScreen (Control) — pause_screen.gd
│   └── GameOverScreen (Control) — game_over_screen.gd
├── AudioPlayers (Node)
│   ├── SFXPlayer (AudioStreamPlayer)
│   └── MusicPlayer (AudioStreamPlayer)
└── Autoloads (프로젝트 설정)
    ├── GameConstants
    ├── AppColors
    ├── SaveManager
    └── SoundManager
```

### 2.2 Data Flow

```
[터치 시작] → DraggablePiece._gui_input()
     │
     ▼
[drag_started Signal] → ChromaBlocksGame
     │
     ▼
[드래그 중] → drag_moved Signal
     │    → board_renderer.show_highlight(gx, gy, can_place)
     ▼
[터치 종료] → drag_ended Signal → ChromaBlocksGame
     │
     ├─ 배치 불가 → draggable_piece.return_to_tray()
     │
     └─ 배치 가능 → place_piece(piece, gx, gy)
           │
           ▼
      BoardState.place_piece()
           │
           ▼
      ClearSystem.check_and_clear()
           │
           ▼
      ColorMatchSystem.check_color_match()
           │
           ▼
      ScoringSystem.calculate()
           │
           ▼
      board_renderer.update_from_state()
           │
           ▼
      [tray empty?] → refill_tray() / check_game_over()
```

### 2.3 File List

| 파일 경로 | 역할 | 의존성 |
|-----------|------|--------|
| `project.godot` | 프로젝트 설정 + Autoload 등록 | - |
| **Core** | | |
| `scripts/core/enums.gd` | BlockColor, PieceType, GameStatus, GameMode | - |
| `scripts/core/game_constants.gd` | 상수, 점수 테이블, 콤보 배율 | Autoload |
| `scripts/core/app_colors.gd` | Luminous Flow + Ghibli 색상 | Autoload |
| **Data** | | |
| `scripts/data/block_piece.gd` | 블록 조각 데이터 | enums |
| `scripts/data/piece_definitions.gd` | 12 폴리오미노 + 가중치 랜덤 | block_piece |
| `scripts/data/board_state.gd` | 10x10 보드 로직 (immutable) | enums |
| `scripts/data/game_state.gd` | 게임 상태 컨테이너 | board_state |
| **Systems** | | |
| `scripts/systems/placement_system.gd` | 배치 검증 | board_state |
| `scripts/systems/clear_system.gd` | 줄 클리어 | board_state |
| `scripts/systems/color_match_system.gd` | 컬러 매치 (flood fill) | board_state |
| `scripts/systems/scoring_system.gd` | 점수 계산 | game_constants |
| `scripts/systems/game_over_system.gd` | 게임 오버 판정 | board_state |
| `scripts/systems/difficulty_system.gd` | 난이도 레벨 | game_constants |
| **Game** | | |
| `scripts/game/chroma_blocks_game.gd` | 메인 게임 매니저 | 전체 |
| `scripts/game/board_renderer.gd` | 보드 시각화 | cell_view |
| `scripts/game/cell_view.gd` | 셀 렌더링 (4-layer) | app_colors |
| `scripts/game/draggable_piece.gd` | 드래그 & 드롭 | block_piece |
| `scripts/game/piece_tray.gd` | 3피스 트레이 | draggable_piece |
| `scripts/game/grid_highlight.gd` | 배치 프리뷰 | - |
| `scripts/game/score_popup.gd` | 점수 팝업 | - |
| `scripts/game/clear_effect.gd` | 클리어 이펙트 | - |
| **UI** | | |
| `scripts/ui/ui_manager.gd` | 화면 전환 | - |
| `scripts/ui/hud.gd` | HUD (점수/레벨/콤보) | - |
| `scripts/ui/home_screen.gd` | 메인 메뉴 | - |
| `scripts/ui/game_over_screen.gd` | 게임 오버 화면 | - |
| `scripts/ui/pause_screen.gd` | 일시정지 화면 | - |
| **Utils** | | |
| `scripts/utils/save_manager.gd` | ConfigFile 저장 | Autoload |
| `scripts/utils/sound_manager.gd` | 오디오 관리 | Autoload |
| `scripts/utils/haptic_manager.gd` | 진동 피드백 | - |
| **Scenes** | | |
| `scenes/main.tscn` | 루트 씬 | chroma_blocks_game |
| `scenes/game/board.tscn` | 10x10 보드 | board_renderer |
| `scenes/game/cell.tscn` | 셀 프리팹 (4-layer) | cell_view |
| `scenes/game/draggable_piece.tscn` | 드래그 가능한 피스 | draggable_piece |
| `scenes/game/piece_tray.tscn` | 3-slot 트레이 | piece_tray |
| `scenes/ui/hud.tscn` | HUD | hud |
| `scenes/ui/home_screen.tscn` | 메인 메뉴 | home_screen |
| `scenes/ui/game_over_screen.tscn` | 게임 오버 | game_over_screen |
| `scenes/ui/pause_screen.tscn` | 일시정지 | pause_screen |

---

## 3. Data Models (GDScript)

### 3.1 enums.gd

```gdscript
class_name Enums

enum BlockColor { CORAL, AMBER, LEMON, MINT, SKY, LAVENDER, SPECIAL }
enum PieceType { DUO, TRI_LINE, TRI_L, TET_SQUARE, TET_LINE, TET_T, TET_Z, TET_S, TET_L, PENT_PLUS, PENT_U, PENT_T }
enum GameStatus { READY, PLAYING, PAUSED, CLEARING, GAME_OVER }
enum GameMode { CLASSIC, DAILY_CHALLENGE }
```

### 3.2 game_constants.gd (Autoload)

```gdscript
extends Node

const BOARD_COLUMNS: int = 10
const BOARD_ROWS: int = 10
const TRAY_SIZE: int = 3

# Timing
const LINE_CLEAR_ANIM_DURATION: float = 0.3
const COLOR_MATCH_ANIM_DURATION: float = 0.4
const SCORE_POPUP_DURATION: float = 0.8
const PLACEMENT_ANIM_DURATION: float = 0.15

# Scoring
const PLACEMENT_POINTS_PER_CELL: int = 5
const PERFECT_CLEAR_BONUS: int = 2000

const LINE_CLEAR_POINTS: Dictionary = {
    1: 100, 2: 300, 3: 600, 4: 1000
}

const COMBO_MULTIPLIERS: Array[float] = [1.0, 1.2, 1.5, 2.0, 2.5, 3.0]

const COLOR_MATCH_BONUS: Dictionary = {
    5: 200, 6: 350, 7: 500
}

const COLOR_MATCH_MIN_CELLS: int = 5

static func line_clear_score(lines: int) -> int:
    if lines <= 0: return 0
    if lines <= 4: return LINE_CLEAR_POINTS[lines]
    return 1000 + (lines - 4) * 500

static func color_match_score(cells: int) -> int:
    if cells < 5: return 0
    if cells <= 7: return COLOR_MATCH_BONUS[cells]
    return 500 + (cells - 7) * 150

static func lines_for_next_level(level: int) -> int:
    return level * 5
```

### 3.3 app_colors.gd (Autoload)

```gdscript
extends Node

# Block Colors (Luminous Flow)
const CORAL := Color("EF4444")
const CORAL_LIGHT := Color("FCA5A5")
const CORAL_GLOW := Color("EF4444", 0.25)

const AMBER := Color("F59E0B")
const AMBER_LIGHT := Color("FCD34D")
const AMBER_GLOW := Color("F59E0B", 0.25)

const LEMON := Color("EAB308")
const LEMON_LIGHT := Color("FDE047")
const LEMON_GLOW := Color("EAB308", 0.25)

const MINT := Color("10B981")
const MINT_LIGHT := Color("6EE7B7")
const MINT_GLOW := Color("10B981", 0.25)

const SKY := Color("3B82F6")
const SKY_LIGHT := Color("93C5FD")
const SKY_GLOW := Color("3B82F6", 0.25)

const LAVENDER := Color("8B5CF6")
const LAVENDER_LIGHT := Color("C4B5FD")
const LAVENDER_GLOW := Color("8B5CF6", 0.25)

const SPECIAL := Color("FFD700")

# Ghibli UI Theme
const BACKGROUND := Color("FBF7F2")
const CARD_WHITE := Color.WHITE
const SAGE_GREEN := Color("7B9E5E")
const SAGE_GREEN_DARK := Color("5A7A42")
const GOLDEN := Color("D4A855")
const SKY_BLUE := Color("89B4C8")
const TEXT_PRIMARY := Color("3D3529")
const TEXT_SECONDARY := Color("7A7266")
const TEXT_MUTED := Color("A69D93")
const BORDER := Color("E5DDD3")
const GRID_LINE := Color("EDE8E2")

const HIGHLIGHT_VALID := Color("10B981", 0.1)
const HIGHLIGHT_INVALID := Color("EF4444", 0.15)

static func get_block_color(color: int) -> Color:
    match color:
        Enums.BlockColor.CORAL: return CORAL
        Enums.BlockColor.AMBER: return AMBER
        Enums.BlockColor.LEMON: return LEMON
        Enums.BlockColor.MINT: return MINT
        Enums.BlockColor.SKY: return SKY
        Enums.BlockColor.LAVENDER: return LAVENDER
        Enums.BlockColor.SPECIAL: return SPECIAL
    return Color.GRAY

static func get_block_light_color(color: int) -> Color:
    match color:
        Enums.BlockColor.CORAL: return CORAL_LIGHT
        Enums.BlockColor.AMBER: return AMBER_LIGHT
        Enums.BlockColor.LEMON: return LEMON_LIGHT
        Enums.BlockColor.MINT: return MINT_LIGHT
        Enums.BlockColor.SKY: return SKY_LIGHT
        Enums.BlockColor.LAVENDER: return LAVENDER_LIGHT
        Enums.BlockColor.SPECIAL: return SPECIAL
    return Color.WHITE

static func get_block_glow_color(color: int) -> Color:
    match color:
        Enums.BlockColor.CORAL: return CORAL_GLOW
        Enums.BlockColor.AMBER: return AMBER_GLOW
        Enums.BlockColor.LEMON: return LEMON_GLOW
        Enums.BlockColor.MINT: return MINT_GLOW
        Enums.BlockColor.SKY: return SKY_GLOW
        Enums.BlockColor.LAVENDER: return LAVENDER_GLOW
        Enums.BlockColor.SPECIAL: return Color("FFD700", 0.25)
    return Color.TRANSPARENT
```

### 3.4 block_piece.gd

```gdscript
class_name BlockPiece

var type: int  # Enums.PieceType
var color: int  # Enums.BlockColor
var shape: Array[Array]  # 2D array of int (0/1)

func _init(p_type: int, p_color: int, p_shape: Array[Array]) -> void:
    type = p_type
    color = p_color
    shape = p_shape

var width: int:
    get: return shape[0].size() if shape.size() > 0 else 0

var height: int:
    get: return shape.size()

var cell_count: int:
    get:
        var count := 0
        for row in shape:
            for cell in row:
                if cell == 1:
                    count += 1
        return count

func occupied_cells_at(gx: int, gy: int) -> Array[Vector2i]:
    var cells: Array[Vector2i] = []
    for row_idx in shape.size():
        for col_idx in shape[row_idx].size():
            if shape[row_idx][col_idx] == 1:
                cells.append(Vector2i(gx + col_idx, gy + row_idx))
    return cells
```

### 3.5 board_state.gd

```gdscript
class_name BoardState

var columns: int
var rows: int
var grid: Array  # Array[Array[Dictionary]] — {occupied: bool, color: int or -1}

func _init(p_cols: int = 10, p_rows: int = 10, p_grid: Array = []) -> void:
    columns = p_cols
    rows = p_rows
    if p_grid.is_empty():
        grid = _create_empty_grid()
    else:
        grid = p_grid

func _create_empty_grid() -> Array:
    var g: Array = []
    for y in rows:
        var row: Array = []
        for x in columns:
            row.append({"occupied": false, "color": -1})
        g.append(row)
    return g

var is_empty: bool:
    get:
        for y in rows:
            for x in columns:
                if grid[y][x]["occupied"]:
                    return false
        return true

func is_cell_occupied(x: int, y: int) -> bool:
    if x < 0 or x >= columns or y < 0 or y >= rows:
        return true  # out of bounds = occupied
    return grid[y][x]["occupied"]

func can_place_piece_at(piece: BlockPiece, gx: int, gy: int) -> bool:
    for cell in piece.occupied_cells_at(gx, gy):
        if cell.x < 0 or cell.x >= columns or cell.y < 0 or cell.y >= rows:
            return false
        if grid[cell.y][cell.x]["occupied"]:
            return false
    return true

func place_piece(piece: BlockPiece, gx: int, gy: int) -> BoardState:
    var new_grid := _copy_grid()
    for cell in piece.occupied_cells_at(gx, gy):
        if cell.x >= 0 and cell.x < columns and cell.y >= 0 and cell.y < rows:
            new_grid[cell.y][cell.x] = {"occupied": true, "color": piece.color}
    return BoardState.new(columns, rows, new_grid)

func get_completed_rows() -> Array[int]:
    var completed: Array[int] = []
    for y in rows:
        var full := true
        for x in columns:
            if not grid[y][x]["occupied"]:
                full = false
                break
        if full:
            completed.append(y)
    return completed

func get_completed_columns() -> Array[int]:
    var completed: Array[int] = []
    for x in columns:
        var full := true
        for y in rows:
            if not grid[y][x]["occupied"]:
                full = false
                break
        if full:
            completed.append(x)
    return completed

func clear_completed_lines() -> Dictionary:
    # Returns: {board: BoardState, lines_cleared: int, rows: Array[int], cols: Array[int]}
    var completed_rows := get_completed_rows()
    var completed_cols := get_completed_columns()

    if completed_rows.is_empty() and completed_cols.is_empty():
        return {"board": self, "lines_cleared": 0, "rows": [], "cols": []}

    var new_grid := _copy_grid()

    for row in completed_rows:
        for x in columns:
            new_grid[row][x] = {"occupied": false, "color": -1}

    for col in completed_cols:
        for y in rows:
            new_grid[y][col] = {"occupied": false, "color": -1}

    var new_board := BoardState.new(columns, rows, new_grid)
    return {
        "board": new_board,
        "lines_cleared": completed_rows.size() + completed_cols.size(),
        "rows": completed_rows,
        "cols": completed_cols
    }

func find_color_matches() -> Array:
    # Returns: Array of Arrays of Vector2i (each group = 5+ same-color adjacent)
    var visited: Array = []
    for y in rows:
        var row: Array = []
        for x in columns:
            row.append(false)
        visited.append(row)

    var matches: Array = []

    for y in rows:
        for x in columns:
            if visited[y][x] or not grid[y][x]["occupied"]:
                continue
            var color: int = grid[y][x]["color"]
            var group: Array[Vector2i] = []
            var stack: Array[Vector2i] = [Vector2i(x, y)]

            while not stack.is_empty():
                var pos := stack.pop_back()
                if pos.x < 0 or pos.x >= columns or pos.y < 0 or pos.y >= rows:
                    continue
                if visited[pos.y][pos.x]:
                    continue
                if not grid[pos.y][pos.x]["occupied"]:
                    continue
                if grid[pos.y][pos.x]["color"] != color:
                    continue
                visited[pos.y][pos.x] = true
                group.append(pos)
                stack.append(Vector2i(pos.x + 1, pos.y))
                stack.append(Vector2i(pos.x - 1, pos.y))
                stack.append(Vector2i(pos.x, pos.y + 1))
                stack.append(Vector2i(pos.x, pos.y - 1))

            if group.size() >= GameConstants.COLOR_MATCH_MIN_CELLS:
                matches.append(group)

    return matches

func remove_cells(cells: Array) -> BoardState:
    var new_grid := _copy_grid()
    for cell in cells:
        new_grid[cell.y][cell.x] = {"occupied": false, "color": -1}
    return BoardState.new(columns, rows, new_grid)

func can_place_any_piece(pieces: Array) -> bool:
    for piece in pieces:
        for gy in rows:
            for gx in columns:
                if can_place_piece_at(piece, gx, gy):
                    return true
    return false

func _copy_grid() -> Array:
    var new_grid: Array = []
    for y in rows:
        var row: Array = []
        for x in columns:
            row.append(grid[y][x].duplicate())
        new_grid.append(row)
    return new_grid
```

### 3.6 game_state.gd

```gdscript
class_name GameState

var board: BoardState
var tray_pieces: Array  # Array[BlockPiece]
var score: int = 0
var level: int = 1
var lines_cleared: int = 0
var combo: int = 0
var status: int = Enums.GameStatus.READY
var high_score: int = 0
var blocks_placed: int = 0
var total_color_matches: int = 0

func _init() -> void:
    board = BoardState.new()
    tray_pieces = []

func reset() -> void:
    board = BoardState.new()
    tray_pieces = []
    score = 0
    level = 1
    lines_cleared = 0
    combo = 0
    status = Enums.GameStatus.READY
    blocks_placed = 0
    total_color_matches = 0

var is_tray_empty: bool:
    get: return tray_pieces.is_empty()
```

---

## 4. Game Systems (GDScript)

모든 시스템은 static 함수로 구현. Node를 상속하지 않으며 Autoload 불필요.

### 4.1 PlacementSystem

```gdscript
class_name PlacementSystem

static func can_place(board: BoardState, piece: BlockPiece, gx: int, gy: int) -> bool:
    return board.can_place_piece_at(piece, gx, gy)

static func screen_to_grid(board_origin: Vector2, cell_size: float, piece: BlockPiece, screen_pos: Vector2) -> Vector2i:
    var rel := screen_pos - board_origin
    var gx := roundi((rel.x - (piece.width * cell_size / 2.0)) / cell_size)
    var gy := roundi((rel.y - (piece.height * cell_size / 2.0)) / cell_size)
    return Vector2i(gx, gy)
```

### 4.2 ClearSystem

```gdscript
class_name ClearSystem

# Returns: {board: BoardState, lines_cleared: int, rows: Array, cols: Array, is_perfect: bool}
static func check_and_clear(board: BoardState) -> Dictionary:
    var result := board.clear_completed_lines()
    result["is_perfect"] = result["board"].is_empty if result["lines_cleared"] > 0 else false
    result["has_clears"] = result["lines_cleared"] > 0
    return result
```

### 4.3 ColorMatchSystem

```gdscript
class_name ColorMatchSystem

# Returns: {board: BoardState, groups: Array, total_removed: int, has_matches: bool}
static func check_color_match(board: BoardState) -> Dictionary:
    var matches := board.find_color_matches()
    if matches.is_empty():
        return {"board": board, "groups": [], "total_removed": 0, "has_matches": false}

    var all_cells: Array[Vector2i] = []
    for group in matches:
        for cell in group:
            if cell not in all_cells:
                all_cells.append(cell)

    var new_board := board.remove_cells(all_cells)
    return {
        "board": new_board,
        "groups": matches,
        "total_removed": all_cells.size(),
        "has_matches": true
    }
```

### 4.4 ScoringSystem

```gdscript
class_name ScoringSystem

# Returns: {placement: int, line_clear: int, color_match: int, perfect_clear: int,
#           combo_multiplier: float, total: int}
static func calculate(cell_count: int, clear_result: Dictionary, color_result: Dictionary,
                      combo: int, level: int) -> Dictionary:
    # 1. Placement
    var placement := cell_count * GameConstants.PLACEMENT_POINTS_PER_CELL

    # 2. Line clear
    var line_clear := GameConstants.line_clear_score(clear_result.get("lines_cleared", 0))

    # 3. Color match
    var color_match := 0
    for group in color_result.get("groups", []):
        color_match += GameConstants.color_match_score(group.size())

    # 4. Perfect clear
    var perfect_clear := GameConstants.PERFECT_CLEAR_BONUS if clear_result.get("is_perfect", false) else 0

    # 5. Combo
    var combo_idx := clampi(combo, 0, GameConstants.COMBO_MULTIPLIERS.size() - 1)
    var multiplier: float = GameConstants.COMBO_MULTIPLIERS[combo_idx]

    # 6. Total
    var bonus := roundi((line_clear + color_match + perfect_clear) * multiplier)
    var total := placement + bonus

    return {
        "placement": placement,
        "line_clear": line_clear,
        "color_match": color_match,
        "perfect_clear": perfect_clear,
        "combo_multiplier": multiplier,
        "total": total
    }
```

### 4.5 GameOverSystem

```gdscript
class_name GameOverSystem

static func is_game_over(board: BoardState, tray_pieces: Array) -> bool:
    if tray_pieces.is_empty():
        return false
    return not board.can_place_any_piece(tray_pieces)
```

### 4.6 DifficultySystem

```gdscript
class_name DifficultySystem

static func calculate_level(total_lines_cleared: int) -> int:
    var level := 1
    var remaining := total_lines_cleared
    var needed := GameConstants.lines_for_next_level(level)
    while remaining >= needed:
        remaining -= needed
        level += 1
        needed = GameConstants.lines_for_next_level(level)
    return level
```

---

## 5. Game Components

### 5.1 Cell Scene (cell.tscn) — Node Tree

```
Cell (PanelContainer) — cell_view.gd
├── GlowOverlay (ColorRect)     ← Layer 1: 글로우 (셀보다 2px 크게)
├── Background (ColorRect)       ← Layer 2: 메인 색상
├── HighlightBand (ColorRect)    ← Layer 3: 상단 35% 밝은 밴드
└── Border (ColorRect)           ← Layer 4: 밝은 테두리
```

### 5.2 cell_view.gd

```gdscript
extends PanelContainer

@onready var glow_overlay: ColorRect = $GlowOverlay
@onready var background: ColorRect = $Background
@onready var highlight_band: ColorRect = $HighlightBand
@onready var border: ColorRect = $Border

const EMPTY_COLOR := Color(0.98, 0.97, 0.95, 1.0)
const EMPTY_BORDER := Color(0.93, 0.91, 0.89, 1.0)

var _occupied: bool = false
var _color: int = -1

func set_empty() -> void:
    _occupied = false
    _color = -1
    background.color = EMPTY_COLOR
    glow_overlay.color = Color.TRANSPARENT
    highlight_band.color = Color.TRANSPARENT
    border.color = EMPTY_BORDER

func set_filled(block_color: int) -> void:
    _occupied = true
    _color = block_color
    var base := AppColors.get_block_color(block_color)
    var light := AppColors.get_block_light_color(block_color)
    var glow := AppColors.get_block_glow_color(block_color)

    glow_overlay.color = glow
    background.color = base
    highlight_band.color = Color(light.r, light.g, light.b, 0.4)
    border.color = light

func set_highlight(can_place: bool) -> void:
    background.color = AppColors.HIGHLIGHT_VALID if can_place else AppColors.HIGHLIGHT_INVALID

func clear_highlight() -> void:
    if _occupied:
        set_filled(_color)
    else:
        set_empty()

func play_clear_flash(duration: float) -> void:
    background.color = Color.WHITE
    var tween := create_tween()
    tween.tween_property(background, "color", Color.TRANSPARENT, duration)
    tween.tween_callback(func(): set_empty())
```

### 5.3 BoardRenderer (board_renderer.gd)

```gdscript
extends GridContainer

const CellScene := preload("res://scenes/game/cell.tscn")

var _cells: Array = []  # Array[Array[CellView]] — [y][x]

func initialize() -> void:
    columns = GameConstants.BOARD_COLUMNS
    _cells.clear()

    for y in GameConstants.BOARD_ROWS:
        var row: Array = []
        for x in GameConstants.BOARD_COLUMNS:
            var cell_node := CellScene.instantiate()
            add_child(cell_node)
            cell_node.set_empty()
            row.append(cell_node)
        _cells.append(row)

func update_from_state(board: BoardState) -> void:
    for y in board.rows:
        for x in board.columns:
            var cell_data: Dictionary = board.grid[y][x]
            if cell_data["occupied"]:
                _cells[y][x].set_filled(cell_data["color"])
            else:
                _cells[y][x].set_empty()

func show_highlight(gx: int, gy: int, piece: BlockPiece, can_place: bool) -> void:
    clear_highlights()
    for cell_pos in piece.occupied_cells_at(gx, gy):
        if cell_pos.x >= 0 and cell_pos.x < GameConstants.BOARD_COLUMNS \
           and cell_pos.y >= 0 and cell_pos.y < GameConstants.BOARD_ROWS:
            _cells[cell_pos.y][cell_pos.x].set_highlight(can_place)

func clear_highlights() -> void:
    for y in GameConstants.BOARD_ROWS:
        for x in GameConstants.BOARD_COLUMNS:
            _cells[y][x].clear_highlight()

func play_line_clear_effect(rows: Array, cols: Array) -> void:
    for row in rows:
        for x in GameConstants.BOARD_COLUMNS:
            _cells[row][x].play_clear_flash(GameConstants.LINE_CLEAR_ANIM_DURATION)
    for col in cols:
        for y in GameConstants.BOARD_ROWS:
            _cells[y][col].play_clear_flash(GameConstants.LINE_CLEAR_ANIM_DURATION)

func play_color_match_effect(groups: Array) -> void:
    for group in groups:
        for cell_pos in group:
            if cell_pos.x >= 0 and cell_pos.x < GameConstants.BOARD_COLUMNS \
               and cell_pos.y >= 0 and cell_pos.y < GameConstants.BOARD_ROWS:
                _cells[cell_pos.y][cell_pos.x].play_clear_flash(
                    GameConstants.COLOR_MATCH_ANIM_DURATION)

func world_to_grid(local_pos: Vector2) -> Vector2i:
    var cell_size := size.x / GameConstants.BOARD_COLUMNS
    var gx := int(local_pos.x / cell_size)
    var gy := int(local_pos.y / cell_size)
    return Vector2i(gx, gy)
```

### 5.4 DraggablePiece (draggable_piece.gd)

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

const DRAG_OFFSET_Y: float = -80.0
const DRAG_SCALE: float = 1.1

func setup(p_piece: BlockPiece, p_index: int, p_cell_size: float) -> void:
    piece_data = p_piece
    tray_index = p_index
    _cell_size = p_cell_size
    _build_visual()

func _build_visual() -> void:
    # Clear existing children
    for child in get_children():
        child.queue_free()

    custom_minimum_size = Vector2(
        piece_data.width * _cell_size,
        piece_data.height * _cell_size
    )

    for row_idx in piece_data.shape.size():
        for col_idx in piece_data.shape[row_idx].size():
            if piece_data.shape[row_idx][col_idx] == 1:
                var rect := ColorRect.new()
                rect.color = AppColors.get_block_color(piece_data.color)
                rect.position = Vector2(col_idx * _cell_size, row_idx * _cell_size)
                rect.size = Vector2(_cell_size - 2, _cell_size - 2)
                add_child(rect)

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _dragging = true
            _original_position = global_position
            _drag_offset = global_position - event.global_position
            scale = Vector2.ONE * DRAG_SCALE
            z_index = 100
            drag_started.emit(self)
            accept_event()
        elif not event.pressed and _dragging:
            _dragging = false
            scale = Vector2.ONE
            z_index = 0
            drag_ended.emit(self, event.global_position + Vector2(0, DRAG_OFFSET_Y))
            accept_event()

    elif event is InputEventMouseMotion and _dragging:
        global_position = event.global_position + _drag_offset + Vector2(0, DRAG_OFFSET_Y)
        drag_moved.emit(self, event.global_position + Vector2(0, DRAG_OFFSET_Y))
        accept_event()

func return_to_tray() -> void:
    var tween := create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_BACK)
    tween.tween_property(self, "global_position", _original_position, 0.2)

func remove_from_tray() -> void:
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.15)
    tween.tween_callback(queue_free)
```

### 5.5 PieceTray (piece_tray.gd)

```gdscript
extends HBoxContainer

signal piece_drag_started(piece_node: Control)
signal piece_drag_moved(piece_node: Control, global_pos: Vector2)
signal piece_drag_ended(piece_node: Control, global_pos: Vector2)

const DraggablePieceScene := preload("res://scenes/game/draggable_piece.tscn")

@export var tray_cell_size: float = 28.0

var _active_pieces: Array = []

func populate_tray(pieces: Array) -> void:
    clear_tray()
    for i in pieces.size():
        var piece_node := DraggablePieceScene.instantiate()
        add_child(piece_node)
        piece_node.setup(pieces[i], i, tray_cell_size)
        piece_node.drag_started.connect(_on_drag_started)
        piece_node.drag_moved.connect(_on_drag_moved)
        piece_node.drag_ended.connect(_on_drag_ended)
        _active_pieces.append(piece_node)

func remove_piece_at(index: int) -> void:
    if index >= 0 and index < _active_pieces.size():
        var piece: Control = _active_pieces[index]
        piece.remove_from_tray()
        _active_pieces.remove_at(index)
        # Re-index remaining pieces
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

### 5.6 ScorePopup (score_popup.gd)

```gdscript
extends Label

func show_score(value: int, start_pos: Vector2) -> void:
    text = "+" + str(value)
    global_position = start_pos
    modulate.a = 1.0

    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "global_position:y", start_pos.y - 60, 0.8) \
         .set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "modulate:a", 0.0, 0.8) \
         .set_ease(Tween.EASE_IN).set_delay(0.3)
    tween.chain().tween_callback(queue_free)
```

---

## 6. Main Game Manager

### 6.1 ChromaBlocksGame (chroma_blocks_game.gd)

```gdscript
extends Node

signal state_changed(state: GameState)
signal game_over_triggered()

@onready var board_renderer: GridContainer = %Board
@onready var piece_tray: HBoxContainer = %PieceTray
@onready var hud: Control = %HUD
@onready var home_screen: Control = %HomeScreen
@onready var game_over_screen: Control = %GameOverScreen
@onready var pause_screen: Control = %PauseScreen
@onready var drag_layer: Control = %DragLayer

var _state: GameState

func _ready() -> void:
    _state = GameState.new()
    _state.high_score = SaveManager.get_high_score()
    board_renderer.initialize()

    piece_tray.piece_drag_started.connect(_on_drag_started)
    piece_tray.piece_drag_moved.connect(_on_drag_moved)
    piece_tray.piece_drag_ended.connect(_on_drag_ended)

    _show_home()

# ── Public API ──

func start_game() -> void:
    _state.reset()
    _state.high_score = SaveManager.get_high_score()
    _state.status = Enums.GameStatus.PLAYING

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
    # Reparent to drag layer for unrestricted movement
    piece_node.reparent(drag_layer)

func _on_drag_moved(piece_node: Control, global_pos: Vector2) -> void:
    if _dragging_piece == null:
        return
    var local_pos := board_renderer.get_local_mouse_position()
    var grid_pos := board_renderer.world_to_grid(local_pos)

    if grid_pos != _last_grid_pos:
        _last_grid_pos = grid_pos
        var can_place := PlacementSystem.can_place(
            _state.board, _dragging_piece, grid_pos.x, grid_pos.y)
        board_renderer.show_highlight(grid_pos.x, grid_pos.y, _dragging_piece, can_place)

func _on_drag_ended(piece_node: Control, global_pos: Vector2) -> void:
    if _dragging_piece == null:
        return

    board_renderer.clear_highlights()
    var local_pos := board_renderer.get_local_mouse_position()
    var grid_pos := board_renderer.world_to_grid(local_pos)

    var can_place := PlacementSystem.can_place(
        _state.board, _dragging_piece, grid_pos.x, grid_pos.y)

    if can_place:
        _place_piece(_dragging_piece, grid_pos.x, grid_pos.y, _dragging_index)
        piece_node.remove_from_tray()
    else:
        piece_node.return_to_tray()
        # Reparent back to tray
        piece_node.reparent(piece_tray)

    _dragging_piece = null
    _dragging_index = -1
    _last_grid_pos = Vector2i(-1, -1)

# ── Core Game Logic ──

func _place_piece(piece: BlockPiece, gx: int, gy: int, tray_index: int) -> void:
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
    # Re-index
    for i in _state.tray_pieces.size():
        pass  # BlockPiece has no index field

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
    popup.add_theme_font_size_override("font_size", 24)
    popup.add_theme_color_override("font_color", AppColors.GOLDEN)
    popup.set_script(preload("res://scripts/game/score_popup.gd"))
    drag_layer.add_child(popup)
    var cell_size := board_renderer.size.x / GameConstants.BOARD_COLUMNS
    var pos := board_renderer.global_position + Vector2(gx * cell_size, gy * cell_size)
    popup.show_score(value, pos)

func _show_home() -> void:
    home_screen.visible = true
    game_over_screen.visible = false
    pause_screen.visible = false
```

---

## 7. UI Components

### 7.1 HUD (hud.gd)

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

### 7.2 HomeScreen (home_screen.gd)

```gdscript
extends Control

signal start_pressed()

@onready var title_label: Label = $VBox/Title
@onready var best_score_label: Label = $VBox/BestScore
@onready var start_button: Button = $VBox/StartButton

func _ready() -> void:
    start_button.pressed.connect(func(): start_pressed.emit())
    best_score_label.text = "BEST: " + str(SaveManager.get_high_score())
```

### 7.3 GameOverScreen (game_over_screen.gd)

```gdscript
extends Control

signal play_again_pressed()
signal go_home_pressed()

@onready var final_score: Label = $VBox/FinalScore
@onready var new_best_badge: Label = $VBox/NewBestBadge
@onready var lines_label: Label = $VBox/Stats/Lines
@onready var blocks_label: Label = $VBox/Stats/Blocks
@onready var combos_label: Label = $VBox/Stats/Combos

func show_result(state: GameState) -> void:
    visible = true
    final_score.text = str(state.score)
    new_best_badge.visible = state.score > state.high_score and state.score > 0
    lines_label.text = str(state.lines_cleared)
    blocks_label.text = str(state.blocks_placed)
    combos_label.text = str(state.total_color_matches)
```

### 7.4 PauseScreen (pause_screen.gd)

```gdscript
extends Control

signal resume_pressed()
signal quit_pressed()

func _ready() -> void:
    $VBox/ResumeButton.pressed.connect(func(): resume_pressed.emit())
    $VBox/QuitButton.pressed.connect(func(): quit_pressed.emit())
```

---

## 8. Utils

### 8.1 SaveManager (Autoload)

```gdscript
extends Node

const SAVE_PATH := "user://chromablocks.cfg"

var _config := ConfigFile.new()

func _ready() -> void:
    _config.load(SAVE_PATH)

func get_high_score() -> int:
    return _config.get_value("game", "high_score", 0)

func save_high_score(score: int) -> void:
    var current := get_high_score()
    if score > current:
        _config.set_value("game", "high_score", score)
        _config.save(SAVE_PATH)

func get_games_played() -> int:
    return _config.get_value("game", "games_played", 0)

func increment_games_played() -> void:
    var count := get_games_played() + 1
    _config.set_value("game", "games_played", count)
    _config.save(SAVE_PATH)

func is_sound_enabled() -> bool:
    return _config.get_value("settings", "sound", true)

func set_sound_enabled(enabled: bool) -> void:
    _config.set_value("settings", "sound", enabled)
    _config.save(SAVE_PATH)
```

### 8.2 SoundManager (Autoload)

```gdscript
extends Node

@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

var _sounds: Dictionary = {}

func _ready() -> void:
    # Preload sounds when available
    # _sounds["line_clear"] = preload("res://assets/audio/line_clear.wav")
    # _sounds["color_match"] = preload("res://assets/audio/color_match.wav")
    # etc.
    pass

func play_sfx(name: String) -> void:
    if not SaveManager.is_sound_enabled():
        return
    if _sounds.has(name):
        sfx_player.stream = _sounds[name]
        sfx_player.play()
```

### 8.3 HapticManager

```gdscript
class_name HapticManager

static func light() -> void:
    Input.vibrate_handheld(20)

static func medium() -> void:
    Input.vibrate_handheld(40)

static func line_clear() -> void:
    Input.vibrate_handheld(50)

static func color_match() -> void:
    Input.vibrate_handheld(60)

static func game_over() -> void:
    Input.vibrate_handheld(100)
```

---

## 9. project.godot 설정

```ini
[application]
config/name="ChromaBlocks"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.3")

[autoload]
GameConstants="*res://scripts/core/game_constants.gd"
AppColors="*res://scripts/core/app_colors.gd"
SaveManager="*res://scripts/utils/save_manager.gd"
SoundManager="*res://scripts/utils/sound_manager.gd"

[display]
window/size/viewport_width=393
window/size/viewport_height=852
window/stretch/mode="canvas_items"
window/stretch/aspect="keep_width"
window/handheld/orientation="portrait"

[input_devices]
pointing/emulate_touch_from_mouse=true

[rendering]
renderer/rendering_method="mobile"
textures/vram_compression/import_etc2_astc=true
```

---

## 10. Animation Spec (Tween 기반)

| 애니메이션 | Godot 구현 | 시간 | 이징 |
|-----------|-----------|------|------|
| 블록 배치 스냅 | Tween → position | 0.15s | EASE_OUT |
| 블록 원위치 복귀 | Tween → global_position | 0.2s | TRANS_BACK |
| 줄 클리어 | Tween → color → TRANSPARENT | 0.3s | EASE_IN |
| 컬러 매치 | Tween → scale + modulate:a | 0.4s | EASE_OUT |
| 점수 팝업 | Tween → position:y + modulate:a | 0.8s | EASE_OUT |
| 트레이 새 블록 | Tween → position:y (slide up) | 0.3s | EASE_OUT |
| 게임 오버 쉐이크 | Tween → position (oscillate) | 0.5s | EASE_IN_OUT |

---

## 11. Screen Layout

```
┌─────────────────────────────────┐
│  StatusBar (투명)                │
├─────────────────────────────────┤
│                                 │
│  ┌─ HUD (HBoxContainer) ──────┐│
│  │ [≡]  SCORE: 12,450  Lv.3  ││
│  │       BEST: 28,900        ││
│  │       COMBO: x1.5         ││
│  └────────────────────────────┘│
│                                 │
│  ┌─ Board (GridContainer) ────┐│
│  │ ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐   ││
│  │ │ │ │ │ │ │ │ │ │ │ │   ││
│  │ ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤   ││
│  │ │ │ │ │ │ │ │ │ │ │ │   ││
│  │ │        ... (10 rows)    ││
│  │ └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘   ││
│  └────────────────────────────┘│
│                                 │
│  ┌─ PieceTray (HBoxContainer) ┐│
│  │ ┌──────┐ ┌──────┐ ┌──────┐││
│  │ │ ██   │ │ ████ │ │  █   │││
│  │ │ ██   │ │      │ │ ███  │││
│  │ └──────┘ └──────┘ └──────┘││
│  └────────────────────────────┘│
│                                 │
└─────────────────────────────────┘

치수 (iPhone 15 기준, 393x852):
- boardWidth = 393 - 32 = 361
- cellSize = 361 / 10 ≈ 36px
- boardHeight = 360px
- trayHeight ≈ 100px
```

---

## 12. Implementation Order

1. **project.godot** + 폴더 구조
2. **Core**: enums.gd, game_constants.gd, app_colors.gd
3. **Data**: block_piece.gd, piece_definitions.gd, board_state.gd, game_state.gd
4. **Systems**: placement → clear → color_match → scoring → game_over → difficulty
5. **Scenes + Game**: cell.tscn, board.tscn, board_renderer.gd, cell_view.gd
6. **Drag**: draggable_piece.tscn, piece_tray.tscn, draggable_piece.gd, piece_tray.gd
7. **UI**: hud.tscn, home_screen.tscn, game_over_screen.tscn, pause_screen.tscn
8. **Main**: main.tscn, chroma_blocks_game.gd (전체 조합)
9. **Utils**: save_manager.gd, sound_manager.gd, haptic_manager.gd
10. **Test**: 테스트 씬 생성 + 게임 로직 검증

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-10 | Initial draft — Godot 4 기술 설계 | AI-Assisted |
