extends Node

# Grid
const BOARD_COLUMNS: int = 8
const BOARD_ROWS: int = 8

# Piece Tray
const TRAY_SIZE: int = 3

# Timing
const LINE_CLEAR_ANIM_DURATION: float = 0.4
const COLOR_MATCH_ANIM_DURATION: float = 0.25
const SCORE_POPUP_DURATION: float = 0.5
const PLACEMENT_ANIM_DURATION: float = 0.15

# Scoring
const PLACEMENT_POINTS_PER_CELL: int = 5
const PERFECT_CLEAR_BONUS: int = 2000

const LINE_CLEAR_POINTS: Dictionary = {
	1: 100,
	2: 300,
	3: 600,
	4: 1000,
}

const COMBO_MULTIPLIERS: Array = [1.0, 1.2, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0]

const COLOR_MATCH_BONUS: Dictionary = {
	6: 200,
	7: 350,
	8: 500,
}

# Color Match
const COLOR_MATCH_ENABLED: bool = false
const COLOR_MATCH_MIN_CELLS: int = 6

# Layout
const BOARD_HORIZONTAL_PADDING: float = 32.0
const BOARD_VERTICAL_RESERVED: float = 288.0

# Drag
const DRAG_OFFSET_Y: float = -130.0
const DRAG_SCALE: float = 1.1

# Expert mode (level 25+)
const EXPERT_COLOR_REDUCE_LEVEL := 25
const EXPERT_TRAY_REDUCE_LEVEL := 30
const EXPERT_COLOR_COUNT := 6

# Chroma Chain
const CHROMA_CHAIN_ENABLED: bool = true
const CHROMA_CHAIN_THRESHOLD: int = 5
const CHROMA_CHAIN_MAX_CASCADE: int = 2
const CHROMA_CHAIN_POINTS_PER_CELL: Array = [30, 60, 90]  # per cascade level
const CHROMA_CHAIN_CASCADE_DELAY: float = 0.3

# Chroma Blast
const CHROMA_BLAST_ENABLED: bool = true
const CHROMA_BLAST_THRESHOLD: int = 6  # cells of same color in cleared line
const CHROMA_BLAST_POINTS_PER_CELL: int = 50
const CHROMA_BLAST_TRIGGER_BONUS: int = 500
const CHROMA_BLAST_LINE_BONUS: int = 200

# Cell Aging — disabled (visual-only, no gameplay impact)
const CELL_AGE_ENABLED: bool = false
const CELL_AGE_STAGE1: int = 5
const CELL_AGE_STAGE2: int = 12
const CELL_AGE_DARKEN_STAGE1: float = 0.20
const CELL_AGE_DARKEN_STAGE2: float = 0.40

# Special Tiles — constants kept for mission mode, but disabled in normal play
const SPECIAL_TILE_NONE: int = -1
const SPECIAL_TILE_BOMB: int = 0
const SPECIAL_TILE_RAINBOW: int = 1
const SPECIAL_TILE_FREEZE: int = 2
const SPECIAL_TILE_DROP_CHANCE: float = 0.0   # disabled in normal mode (was 0.20)
const SPECIAL_TILE_BOMB_RADIUS: int = 1
const SPECIAL_TILE_FREEZE_RADIUS: int = 2
const SPECIAL_TILE_BOMB_BONUS: int = 300


static func line_clear_score(lines: int) -> int:
	if lines <= 0:
		return 0
	if lines <= 4:
		return LINE_CLEAR_POINTS[lines]
	return 1000 + (lines - 4) * 500


static func color_match_score(cells: int) -> int:
	if cells < COLOR_MATCH_MIN_CELLS:
		return 0
	if cells <= 8:
		return COLOR_MATCH_BONUS[cells]
	return 500 + (cells - 8) * 150


static func lines_for_next_level(level: int) -> int:
	return mini(level * 5, 50)
