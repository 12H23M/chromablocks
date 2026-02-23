class_name PieceGenerator
## Smart piece generation system that controls tray composition
## for balanced, fun gameplay through:
##   - Size-category-based tray templates (no 3x huge pieces)
##   - Board density mercy (lighter pieces when board is full)
##   - Anti-repetition (no duplicates in tray, reduce recent pieces)
##   - Color clustering (occasional same-color pairs for combo potential)

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
		Enums.PieceType.PENT_LINE,
		Enums.PieceType.PENT_LINE_V,
		Enums.PieceType.PENT_L3,
		Enums.PieceType.PENT_J3,
		Enums.PieceType.PENT_L3_R,
		Enums.PieceType.PENT_J3_R,
	],
	SizeCat.HUGE: [
		Enums.PieceType.RECT_2x3,
		Enums.PieceType.SQ_3x3,
		Enums.PieceType.RECT_3x2,
	],
}

# ── Tray templates ──
# Each entry: { "template": [SizeCat, SizeCat, SizeCat], "weight": float }
# Templates define the SIZE MIX of each 3-piece tray.

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

# Progressive piece exclusion lists per level range
# Level 1-2: Exclude T-variants, Z/S, and complex pentominoes
const EXCLUDED_LV1: Array = [
	Enums.PieceType.TET_T_R, Enums.PieceType.TET_T_L,
	Enums.PieceType.TET_Z, Enums.PieceType.TET_S,
	Enums.PieceType.TET_Z_V, Enums.PieceType.TET_S_V,
	Enums.PieceType.PENT_PLUS, Enums.PieceType.PENT_U,
	Enums.PieceType.PENT_T,
]
# Level 3-4: Allow T-variants, still exclude Z/S and complex pentominoes
const EXCLUDED_LV3: Array = [
	Enums.PieceType.TET_Z, Enums.PieceType.TET_S,
	Enums.PieceType.TET_Z_V, Enums.PieceType.TET_S_V,
	Enums.PieceType.PENT_PLUS, Enums.PieceType.PENT_U,
	Enums.PieceType.PENT_T,
]
# Level 5-7: Allow Z/S, still exclude complex pentominoes
const EXCLUDED_LV5: Array = [
	Enums.PieceType.PENT_PLUS, Enums.PieceType.PENT_U,
	Enums.PieceType.PENT_T,
]
# Level 8+: All pieces allowed (empty array)

# Board density thresholds for mercy system
const MERCY_MILD_THRESHOLD := 0.60
const MERCY_STRONG_THRESHOLD := 0.75
const MERCY_CRITICAL_THRESHOLD := 0.80
const COLOR_CLUSTER_CHANCE := 0.25

# ── State ──

var _rng := RandomNumberGenerator.new()
var _previous_tray_types: Array = []  # PieceType values from last tray


func reset() -> void:
	_previous_tray_types = []
	_rng.randomize()


func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value


func generate_tray(level: int, board: BoardState) -> Array:
	var templates := _get_templates_for_level(level)
	var excluded := _get_excluded_for_level(level)
	var fill_ratio := _board_fill_ratio(board)

	# Apply mercy: shift toward lighter templates when board is dense
	templates = _apply_mercy(templates, fill_ratio)

	# Pick a tray template
	var template: Array = _pick_template(templates)

	# Critical mercy: guarantee at least one TINY piece when board >= 80% full
	if fill_ratio >= MERCY_CRITICAL_THRESHOLD:
		var has_tiny := false
		for cat in template:
			if cat == SizeCat.TINY:
				has_tiny = true
				break
		if not has_tiny:
			# Force the first slot to TINY
			template[0] = SizeCat.TINY

	# Generate pieces for each slot
	var tray: Array = []
	var used_types: Array = []  # track types within this tray
	var first_color := -1

	for i in template.size():
		var cat: int = template[i]
		var piece := _pick_piece(cat, excluded, used_types, first_color if i > 0 else -1, level)
		tray.append(piece)
		used_types.append(piece.type)
		if i == 0:
			first_color = piece.color

	# Update history for anti-repetition
	_previous_tray_types = used_types.duplicate()

	return tray


# ── Template selection ──

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


func _apply_mercy(templates: Array, fill_ratio: float) -> Array:
	if fill_ratio < MERCY_MILD_THRESHOLD:
		return templates

	# Boost templates that contain TINY or SMALL pieces
	var result := templates.duplicate(true)
	for entry in result:
		var t: Array = entry["t"]
		var has_small := false
		for cat in t:
			if cat == SizeCat.TINY or cat == SizeCat.SMALL:
				has_small = true
				break

		if fill_ratio >= MERCY_STRONG_THRESHOLD:
			# Strong mercy: heavily favor light trays
			if has_small:
				entry["w"] *= 3.0
			else:
				entry["w"] *= 0.3
		else:
			# Mild mercy: moderately favor light trays
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


# ── Piece selection ──

func _pick_piece(category: int, excluded: Array, used_types: Array, cluster_color: int, level: int = 0) -> BlockPiece:
	var pool: Array = CATEGORY_PIECES[category].duplicate()

	# Remove excluded types
	for ex in excluded:
		pool.erase(ex)

	# Remove types already in this tray (anti-duplicate)
	for used in used_types:
		pool.erase(used)

	# If pool is empty (edge case), fall back to full category
	if pool.is_empty():
		pool = CATEGORY_PIECES[category].duplicate()

	# Build weights: reduce recently-seen types
	var weights: Dictionary = {}
	for piece_type in pool:
		var w := 1.0
		if piece_type in _previous_tray_types:
			w *= 0.4  # reduce recent pieces
		weights[piece_type] = w

	# Weighted random selection for shape (color is independent)
	var chosen_type := _weighted_pick(weights)
	var piece_shape: Array = PieceDefinitions.SHAPES[chosen_type]

	# Random color decoupled from shape
	var color_count := _get_color_count(level)
	var piece_color: int
	if cluster_color >= 0 and _rng.randf() < COLOR_CLUSTER_CHANCE:
		piece_color = cluster_color
	else:
		piece_color = _rng.randi_range(0, color_count - 1)

	return BlockPiece.new(chosen_type, piece_color, piece_shape)


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


# ── Utility ──

func _board_fill_ratio(board: BoardState) -> float:
	return board.fill_ratio()
