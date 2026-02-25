class_name PieceGenerator
## Smart piece generation with Block Blast-style Dynamic Difficulty Adjustment:
##   - Empty board → large pieces (快速 fill → line clear rush)
##   - Dense board → small/placeable pieces (survival mercy)
##   - Color mercy: boost same-color near chain threshold
##   - Anti-repetition + color clustering preserved

# ── Size categories ──

enum SizeCat { TINY, SMALL, MEDIUM, LARGE, HUGE }

const CATEGORY_PIECES: Dictionary = {
	SizeCat.TINY: [
		Enums.PieceType.SINGLE,
		Enums.PieceType.DUO,
		Enums.PieceType.DUO_V,
	],
	SizeCat.SMALL: [
		Enums.PieceType.TRI_LINE,
		Enums.PieceType.TRI_LINE_V,
		Enums.PieceType.TRI_L,
		Enums.PieceType.TRI_J,
	],
	SizeCat.MEDIUM: [
		Enums.PieceType.TET_SQUARE,
		Enums.PieceType.TET_LINE,
		Enums.PieceType.TET_LINE_V,
		Enums.PieceType.TET_T,
		Enums.PieceType.TET_T_UP,
		Enums.PieceType.TET_T_R,
		Enums.PieceType.TET_T_L,
		Enums.PieceType.TET_Z,
		Enums.PieceType.TET_S,
		Enums.PieceType.TET_Z_V,
		Enums.PieceType.TET_S_V,
		Enums.PieceType.TET_L,
		Enums.PieceType.TET_J,
		Enums.PieceType.TET_L_H,
		Enums.PieceType.TET_J_H,
	],
	SizeCat.LARGE: [
		Enums.PieceType.PENT_PLUS,
		Enums.PieceType.PENT_U,
		Enums.PieceType.PENT_T,
		# PENT_LINE / PENT_LINE_V removed — replaced by N-shapes
		Enums.PieceType.PENT_L3,
		Enums.PieceType.PENT_J3,
		Enums.PieceType.PENT_L3_R,
		Enums.PieceType.PENT_J3_R,
		Enums.PieceType.PENT_N,
		Enums.PieceType.PENT_N_R,
		Enums.PieceType.PENT_N_V,
		Enums.PieceType.PENT_N_V2,
	],
	SizeCat.HUGE: [
		Enums.PieceType.RECT_2x3,
		Enums.PieceType.SQ_3x3,
		Enums.PieceType.RECT_3x2,
	],
}

# Flat list of all generated piece types (excludes PENT_LINE/PENT_LINE_V)
var _all_types: Array = []

# ── Tray templates ──

const TEMPLATES_EASY: Array = [
	{ "t": [SizeCat.SMALL, SizeCat.MEDIUM, SizeCat.MEDIUM], "w": 0.22 },
	{ "t": [SizeCat.MEDIUM, SizeCat.MEDIUM, SizeCat.MEDIUM], "w": 0.15 },
	{ "t": [SizeCat.TINY, SizeCat.MEDIUM, SizeCat.MEDIUM], "w": 0.13 },
	{ "t": [SizeCat.SMALL, SizeCat.MEDIUM, SizeCat.LARGE], "w": 0.12 },
	{ "t": [SizeCat.TINY, SizeCat.MEDIUM, SizeCat.LARGE], "w": 0.10 },
	{ "t": [SizeCat.TINY, SizeCat.SMALL, SizeCat.MEDIUM], "w": 0.10 },
	{ "t": [SizeCat.SMALL, SizeCat.SMALL, SizeCat.MEDIUM], "w": 0.08 },
	{ "t": [SizeCat.MEDIUM, SizeCat.MEDIUM, SizeCat.HUGE], "w": 0.05 },
	{ "t": [SizeCat.TINY, SizeCat.SMALL, SizeCat.LARGE], "w": 0.05 },
]

const TEMPLATES_MEDIUM: Array = [
	{ "t": [SizeCat.SMALL, SizeCat.MEDIUM, SizeCat.MEDIUM], "w": 0.25 },
	{ "t": [SizeCat.TINY, SizeCat.MEDIUM, SizeCat.LARGE], "w": 0.20 },
	{ "t": [SizeCat.SMALL, SizeCat.SMALL, SizeCat.LARGE], "w": 0.15 },
	{ "t": [SizeCat.MEDIUM, SizeCat.MEDIUM, SizeCat.MEDIUM], "w": 0.15 },
	{ "t": [SizeCat.SMALL, SizeCat.MEDIUM, SizeCat.LARGE], "w": 0.10 },
	{ "t": [SizeCat.SMALL, SizeCat.LARGE, SizeCat.LARGE], "w": 0.10 },
	{ "t": [SizeCat.TINY, SizeCat.LARGE, SizeCat.HUGE], "w": 0.05 },
]

const TEMPLATES_HARD: Array = [
	{ "t": [SizeCat.SMALL, SizeCat.MEDIUM, SizeCat.LARGE], "w": 0.25 },
	{ "t": [SizeCat.MEDIUM, SizeCat.LARGE, SizeCat.LARGE], "w": 0.20 },
	{ "t": [SizeCat.SMALL, SizeCat.LARGE, SizeCat.HUGE], "w": 0.15 },
	{ "t": [SizeCat.MEDIUM, SizeCat.MEDIUM, SizeCat.LARGE], "w": 0.15 },
	{ "t": [SizeCat.LARGE, SizeCat.LARGE, SizeCat.LARGE], "w": 0.10 },
	{ "t": [SizeCat.TINY, SizeCat.LARGE, SizeCat.HUGE], "w": 0.10 },
	{ "t": [SizeCat.LARGE, SizeCat.HUGE, SizeCat.HUGE], "w": 0.05 },
]

const TEMPLATES_EXPERT: Array = [
	{ "t": [SizeCat.MEDIUM, SizeCat.LARGE], "w": 0.30 },
	{ "t": [SizeCat.SMALL, SizeCat.LARGE], "w": 0.25 },
	{ "t": [SizeCat.LARGE, SizeCat.LARGE], "w": 0.20 },
	{ "t": [SizeCat.MEDIUM, SizeCat.HUGE], "w": 0.15 },
	{ "t": [SizeCat.SMALL, SizeCat.HUGE], "w": 0.10 },
]

# ── DDA: Block Blast style templates for empty/sparse boards ──
const TEMPLATES_RUSH: Array = [
	{ "t": [SizeCat.LARGE, SizeCat.LARGE, SizeCat.HUGE], "w": 0.30 },
	{ "t": [SizeCat.MEDIUM, SizeCat.LARGE, SizeCat.HUGE], "w": 0.25 },
	{ "t": [SizeCat.LARGE, SizeCat.HUGE, SizeCat.HUGE], "w": 0.20 },
	{ "t": [SizeCat.MEDIUM, SizeCat.LARGE, SizeCat.LARGE], "w": 0.15 },
	{ "t": [SizeCat.LARGE, SizeCat.LARGE, SizeCat.LARGE], "w": 0.10 },
]

# Progressive piece exclusion by level
const EXCLUDED_LV1: Array = [
	Enums.PieceType.TET_T_R, Enums.PieceType.TET_T_L,
	Enums.PieceType.TET_Z, Enums.PieceType.TET_S,
	Enums.PieceType.TET_Z_V, Enums.PieceType.TET_S_V,
	Enums.PieceType.PENT_PLUS, Enums.PieceType.PENT_U,
	Enums.PieceType.PENT_T,
	Enums.PieceType.PENT_N, Enums.PieceType.PENT_N_R,
	Enums.PieceType.PENT_N_V, Enums.PieceType.PENT_N_V2,
]
const EXCLUDED_LV3: Array = [
	Enums.PieceType.TET_Z, Enums.PieceType.TET_S,
	Enums.PieceType.TET_Z_V, Enums.PieceType.TET_S_V,
	Enums.PieceType.PENT_PLUS, Enums.PieceType.PENT_U,
	Enums.PieceType.PENT_T,
	# N-pieces allowed from level 3+
]
const EXCLUDED_LV5: Array = [
	Enums.PieceType.PENT_PLUS, Enums.PieceType.PENT_U,
	Enums.PieceType.PENT_T,
]
# Level 8+: All pieces allowed

# ── DDA thresholds ──
const DDA_RUSH_THRESHOLD := 0.30       # fill < 30% → rush mode (big pieces)
const DDA_RUSH_CHANCE := 0.80           # 80% chance to use rush templates
const DDA_MERCY_MILD := 0.55            # fill 55-70% → mild mercy
const DDA_MERCY_STRONG := 0.70          # fill 70-80% → strong mercy
const DDA_MERCY_CRITICAL := 0.80        # fill 80%+ → critical mercy
const DDA_FIT_CHECK_CHANCE := 0.50      # placeable-only filter chance (55%+)
const DDA_FIT_CRITICAL_CHANCE := 0.70   # placeable-only filter (80%+)

# ── Color mercy ──
const COLOR_CLUSTER_CHANCE := 0.25      # basic tray color clustering
const COLOR_MERCY_THRESHOLD := 0.35     # board fill to activate color mercy
const COLOR_MERCY_CHANCE := 0.40        # chance to assign cluster color
const COLOR_MERCY_MIN_GROUP := 4        # min cluster size (chain triggers at 5)

# ── State ──

var _rng := RandomNumberGenerator.new()
var _previous_tray_types: Array = []
var _tight_tray_streak: int = 0
const MAX_TIGHT_STREAK: int = 3


func _init() -> void:
	# Build flat list of all generatable types
	for cat in CATEGORY_PIECES.values():
		for pt in cat:
			if pt not in _all_types:
				_all_types.append(pt)


func reset() -> void:
	_previous_tray_types = []
	_tight_tray_streak = 0
	_rng.randomize()


func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value


func generate_tray(level: int, board: BoardState) -> Array:
	var excluded := _get_excluded_for_level(level)
	var fill := _board_fill_ratio(board)

	# Anti-frustration: relief tray after consecutive tight trays
	if _tight_tray_streak >= MAX_TIGHT_STREAK and fill > 0.5:
		_tight_tray_streak = 0
		return _generate_relief_tray(board, level)

	# ── DDA: Pick template set based on board density ──
	var templates: Array
	if fill < DDA_RUSH_THRESHOLD and _rng.randf() < DDA_RUSH_CHANCE:
		# Empty board → rush mode! Big pieces for fast line clears
		templates = TEMPLATES_RUSH.duplicate(true)
	else:
		templates = _get_templates_for_level(level)
		templates = _apply_mercy(templates, fill)

	var template: Array = _pick_template(templates)

	# Critical mercy: guarantee TINY piece
	if fill >= DDA_MERCY_CRITICAL:
		var has_tiny := false
		for cat in template:
			if cat == SizeCat.TINY:
				has_tiny = true
				break
		if not has_tiny:
			template[0] = SizeCat.TINY

	# ── Color mercy: find largest near-chain cluster ──
	var mercy_color := -1
	if fill > COLOR_MERCY_THRESHOLD and _rng.randf() < COLOR_MERCY_CHANCE:
		mercy_color = _find_near_chain_color(board)

	# ── Generate pieces ──
	var tray: Array = []
	var used_types: Array = []
	var first_color := -1

	for i in template.size():
		var cat: int = template[i]
		var piece := _pick_piece_dda(cat, excluded, used_types, first_color if i > 0 else -1, level, board, fill, mercy_color)
		tray.append(piece)
		used_types.append(piece.type)
		if i == 0:
			first_color = piece.color

	_previous_tray_types = used_types.duplicate()

	# ── Playability guarantee ──
	if not board.can_place_any_piece(tray):
		tray = _rescue_tray(tray, board, level)

	# Anti-frustration: track tight trays
	var placeable := 0
	for p in tray:
		if _can_place_type_on_board(p.type, board):
			placeable += 1
	if placeable <= 1:
		_tight_tray_streak += 1
	else:
		_tight_tray_streak = maxi(0, _tight_tray_streak - 1)

	return tray


# ═══════════════════════════════════════════
# DDA-aware piece selection
# ═══════════════════════════════════════════

func _pick_piece_dda(category: int, excluded: Array, used_types: Array, cluster_color: int, level: int, board: BoardState, fill: float, mercy_color: int) -> BlockPiece:
	var pool: Array = CATEGORY_PIECES[category].duplicate()

	for ex in excluded:
		pool.erase(ex)
	for used in used_types:
		pool.erase(used)
	if pool.is_empty():
		pool = CATEGORY_PIECES[category].duplicate()

	# ── DDA fit check: when board is dense, prefer placeable pieces ──
	var fit_chance := 0.0
	if fill >= DDA_MERCY_CRITICAL:
		fit_chance = DDA_FIT_CRITICAL_CHANCE
	elif fill >= DDA_MERCY_MILD:
		fit_chance = DDA_FIT_CHECK_CHANCE

	if fit_chance > 0.0 and _rng.randf() < fit_chance:
		var placeable_pool: Array = []
		for pt in pool:
			if _can_place_type_on_board(pt, board):
				placeable_pool.append(pt)
		if not placeable_pool.is_empty():
			pool = placeable_pool

	# Build weights with anti-repetition
	var weights: Dictionary = {}
	for piece_type in pool:
		var w := 1.0
		if piece_type in _previous_tray_types:
			w *= 0.4
		weights[piece_type] = w

	var chosen_type := _weighted_pick(weights)
	var piece_shape: Array = PieceDefinitions.SHAPES[chosen_type]

	# ── Color selection with mercy ──
	var color_count := _get_color_count(level)
	var piece_color: int

	if mercy_color >= 0 and _rng.randf() < 0.50:
		# Color mercy: assign near-chain cluster color
		piece_color = mercy_color
	elif cluster_color >= 0 and _rng.randf() < COLOR_CLUSTER_CHANCE:
		piece_color = cluster_color
	else:
		piece_color = _rng.randi_range(0, color_count - 1)

	return BlockPiece.new(chosen_type, piece_color, piece_shape)


func _can_place_type_on_board(piece_type: int, board: BoardState) -> bool:
	"""Check if a piece type can be placed anywhere on the board."""
	var shape: Array = PieceDefinitions.SHAPES[piece_type]
	var piece := BlockPiece.new(piece_type, 0, shape)
	var h: int = shape.size()
	var first_row: Array = shape[0]
	var w: int = first_row.size()
	for gy in range(board.rows - h + 1):
		for gx in range(board.columns - w + 1):
			if board.can_place_piece_at(piece, gx, gy):
				return true
	return false


func _find_near_chain_color(board: BoardState) -> int:
	"""Find the color of the largest cluster that's close to chain threshold (4+ cells)."""
	var groups := board.find_color_matches_threshold(COLOR_MERCY_MIN_GROUP)
	if groups.is_empty():
		return -1
	# Find the largest group
	var best_group: Array = groups[0]
	for g in groups:
		if g.size() > best_group.size():
			best_group = g
	# Return the color of that group
	var pos: Vector2i = best_group[0]
	return board.grid[pos.y][pos.x]["color"]


# ═══════════════════════════════════════════
# Playability rescue system
# ═══════════════════════════════════════════

func _rescue_tray(tray: Array, board: BoardState, level: int) -> Array:
	# Level 1: DOWNSIZE — replace largest unplaceable piece with smaller category
	var downsize_map: Dictionary = {
		SizeCat.HUGE: SizeCat.LARGE,
		SizeCat.LARGE: SizeCat.MEDIUM,
		SizeCat.MEDIUM: SizeCat.SMALL,
		SizeCat.SMALL: SizeCat.TINY,
	}

	for idx in tray.size():
		var piece: BlockPiece = tray[idx]
		var cat: int = _get_piece_category(piece.type)
		if cat in downsize_map:
			var smaller_cat: int = downsize_map[cat]
			var pool: Array = CATEGORY_PIECES[smaller_cat].duplicate()
			pool.shuffle()
			for pt in pool:
				if _can_place_type_on_board(pt, board):
					var shape: Array = PieceDefinitions.SHAPES[pt]
					var color_count: int = _get_color_count(level)
					tray[idx] = BlockPiece.new(pt, _rng.randi_range(0, color_count - 1), shape)
					return tray

	# Level 2: FIT_SCAN — find ANY placeable piece from small categories
	for cat in [SizeCat.TINY, SizeCat.SMALL, SizeCat.MEDIUM]:
		var pool: Array = CATEGORY_PIECES[cat].duplicate()
		pool.shuffle()
		for pt in pool:
			if _can_place_type_on_board(pt, board):
				var shape: Array = PieceDefinitions.SHAPES[pt]
				var color_count: int = _get_color_count(level)
				tray[0] = BlockPiece.new(pt, _rng.randi_range(0, color_count - 1), shape)
				return tray

	# Level 3: SINGLE_FORCE — 1x1 fits if any empty cell exists
	if _has_any_empty_cell(board):
		var shape: Array = PieceDefinitions.SHAPES[Enums.PieceType.SINGLE]
		var color_count: int = _get_color_count(level)
		tray[0] = BlockPiece.new(Enums.PieceType.SINGLE, _rng.randi_range(0, color_count - 1), shape)

	return tray  # Board is 100% full — legitimate game over


## rescue_existing_tray removed — rescue only applies at new tray generation


func _generate_relief_tray(board: BoardState, level: int) -> Array:
	var tray: Array = []
	var color_count: int = _get_color_count(level)
	for cat in [SizeCat.TINY, SizeCat.SMALL, SizeCat.SMALL]:
		var pool: Array = CATEGORY_PIECES[cat].duplicate()
		pool.shuffle()
		var placed := false
		for pt in pool:
			if _can_place_type_on_board(pt, board):
				var shape: Array = PieceDefinitions.SHAPES[pt]
				tray.append(BlockPiece.new(pt, _rng.randi_range(0, color_count - 1), shape))
				placed = true
				break
		if not placed:
			var fallback_pt: int = pool[0]
			var shape: Array = PieceDefinitions.SHAPES[fallback_pt]
			tray.append(BlockPiece.new(fallback_pt, _rng.randi_range(0, color_count - 1), shape))
	_previous_tray_types = []
	for p in tray:
		_previous_tray_types.append(p.type)
	return tray


func _get_piece_category(piece_type: int) -> int:
	for cat in CATEGORY_PIECES:
		var types: Array = CATEGORY_PIECES[cat]
		if piece_type in types:
			return cat
	return SizeCat.MEDIUM


func _has_any_empty_cell(board: BoardState) -> bool:
	for y in board.rows:
		for x in board.columns:
			var cell: Dictionary = board.grid[y][x]
			if not cell["occupied"]:
				return true
	return false


# ═══════════════════════════════════════════
# Template selection
# ═══════════════════════════════════════════

func _get_templates_for_level(level: int) -> Array:
	if level <= 5:
		return TEMPLATES_EASY.duplicate(true)
	if level <= 15:
		return TEMPLATES_MEDIUM.duplicate(true)
	if level >= GameConstants.EXPERT_TRAY_REDUCE_LEVEL:
		return TEMPLATES_EXPERT.duplicate(true)
	return TEMPLATES_HARD.duplicate(true)


func _get_excluded_for_level(level: int) -> Array:
	if level <= 2:
		return EXCLUDED_LV1
	if level <= 4:
		return EXCLUDED_LV3
	if level <= 7:
		return EXCLUDED_LV5
	return []


func _apply_mercy(templates: Array, fill: float) -> Array:
	if fill < DDA_MERCY_MILD:
		return templates

	var result := templates.duplicate(true)
	for entry in result:
		var t: Array = entry["t"]
		var has_small := false
		for cat in t:
			if cat == SizeCat.TINY or cat == SizeCat.SMALL:
				has_small = true
				break

		if fill >= DDA_MERCY_STRONG:
			if has_small:
				entry["w"] *= 3.0
			else:
				entry["w"] *= 0.3
		else:
			if has_small:
				entry["w"] *= 1.8
			else:
				entry["w"] *= 0.6

	return result


func _pick_template(templates: Array) -> Array:
	var total := 0.0
	for entry in templates:
		total += entry["w"]
	var roll := _rng.randf() * total
	for entry in templates:
		roll -= entry["w"]
		if roll <= 0.0:
			return entry["t"]
	return templates.back()["t"]


# ═══════════════════════════════════════════
# Utilities
# ═══════════════════════════════════════════

func _get_color_count(level: int) -> int:
	return GameConstants.EXPERT_COLOR_COUNT if level >= GameConstants.EXPERT_COLOR_REDUCE_LEVEL else 6


func _weighted_pick(weights: Dictionary) -> int:
	var total := 0.0
	for w in weights.values():
		total += w
	var roll := _rng.randf() * total
	for key in weights:
		roll -= weights[key]
		if roll <= 0.0:
			return key
	return weights.keys().back()


func _board_fill_ratio(board: BoardState) -> float:
	return board.fill_ratio()
