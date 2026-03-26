extends Control

signal cell_tapped(grid_x: int, grid_y: int)

## Lazy-loaded resources — deferred until first use to speed up scene tree init.
var _CellScene: PackedScene
var _ClearParticlesScript: GDScript

func _get_cell_scene() -> PackedScene:
	if _CellScene == null:
		_CellScene = load("res://scenes/game/cell.tscn")
	return _CellScene

func _get_clear_particles_script() -> GDScript:
	if _ClearParticlesScript == null:
		_ClearParticlesScript = load("res://scripts/game/clear_particles.gd")
	return _ClearParticlesScript

## Get a particle system from pool (or create if pool empty)
func _get_particle_system() -> Control:
	if _particle_pool.size() > 0:
		var p: Control = _particle_pool.pop_back()
		p.set_script(_get_clear_particles_script())
		return p
	var p := Control.new()
	p.set_script(_get_clear_particles_script())
	return p

## Return a particle system to pool for reuse
func _return_particle_system(p: Control) -> void:
	if _particle_pool.size() < PARTICLE_POOL_SIZE:
		p.get_parent().remove_child(p)
		p.set_script(null)  # Clear script to reset state
		_particle_pool.append(p)
	else:
		p.queue_free()  # Pool full, discard
const CORNER_RADIUS := 20
const BORDER_WIDTH := 2.5

var _cells: Array = []  # Array[Array[CellView]] — [y][x]
var _cell_size: float = 36.0
var _bg_style: StyleBoxFlat
var _shake_tween: Tween
var _bounce_tween: Tween
var _shake_offset: Vector2 = Vector2.ZERO:
	set(value):
		_shake_offset = value
		_apply_offsets()
var _bounce_offset: Vector2 = Vector2.ZERO:
	set(value):
		_bounce_offset = value
		_apply_offsets()
var _crisis_pulse_tween: Tween
var _crisis_active: bool = false
var _border_style_cache: StyleBoxFlat  # Cached outer border style (avoid per-frame allocation)
var _particle_pool: Array = []  # Pool of reusable particle systems
const PARTICLE_POOL_SIZE := 3  # Max concurrent particle systems
var _shockwaves: Array = []
var _highlighted_cells: Array = []
var _predicted_cells: Array = []
var _blast_hint_cells: Array = []
var _near_line_hint_cells: Array = []
var _cluster_hint_cells: Array = []

func initialize() -> void:
	_cells.clear()
	for child in get_children():
		child.queue_free()

	clip_children = Control.CLIP_CHILDREN_ONLY
	_setup_styles()
	_calculate_cell_size()

	for y in GameConstants.BOARD_ROWS:
		var row: Array = []
		for x in GameConstants.BOARD_COLUMNS:
			var cell_node := _get_cell_scene().instantiate()
			cell_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(cell_node)
			cell_node.set_empty()
			row.append(cell_node)
		_cells.append(row)

	_layout_cells()
	_setup_gem_overlay()

## Gem overlay: draws on top of all cells
var _gem_overlay: Control = null

var _gems_enabled := false  # Hidden by default, shown when game starts

func enable_gems() -> void:
	# Gems disabled for visual redesign — no-op
	return

func disable_gems() -> void:
	_gems_enabled = false
	if _gem_overlay:
		_gem_overlay.visible = false

func _setup_gem_overlay() -> void:
	_gems_enabled = false  # Gems permanently disabled for visual redesign
	if _gem_overlay:
		_gem_overlay.queue_free()
	_gem_overlay = Control.new()
	_gem_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gem_overlay.size = size
	_gem_overlay.z_index = 10
	_gem_overlay.visible = false
	add_child(_gem_overlay)
	# _gem_overlay.draw.connect(_draw_gems_on_overlay)  # Gem drawing disabled

func _draw_gems_on_overlay() -> void:
	var gem_size := 5.0
	var inset := 4.0
	var s := _gem_overlay.size
	var gem_data := [
		{"pos": Vector2(inset, inset), "color": Color(0.231, 0.510, 0.965), "glow": Color(0.231, 0.510, 0.965, 0.5)},
		{"pos": Vector2(s.x - inset, inset), "color": Color(0.925, 0.286, 0.600), "glow": Color(0.925, 0.286, 0.600, 0.5)},
		{"pos": Vector2(inset, s.y - inset), "color": Color(0.063, 0.725, 0.506), "glow": Color(0.063, 0.725, 0.506, 0.5)},
		{"pos": Vector2(s.x - inset, s.y - inset), "color": Color(0.961, 0.620, 0.043), "glow": Color(0.961, 0.620, 0.043, 0.5)},
	]
	for gem in gem_data:
		var center: Vector2 = gem["pos"]
		var color: Color = gem["color"]
		var glow_color: Color = gem["glow"]
		_gem_overlay.draw_circle(center, gem_size + 6, Color(glow_color.r, glow_color.g, glow_color.b, 0.12))
		_gem_overlay.draw_circle(center, gem_size + 3, glow_color)
		var points := PackedVector2Array([
			center + Vector2(0, -gem_size),
			center + Vector2(gem_size, 0),
			center + Vector2(0, gem_size),
			center + Vector2(-gem_size, 0),
		])
		_gem_overlay.draw_colored_polygon(points, color)
		var highlight := PackedVector2Array([
			center + Vector2(0, -gem_size),
			center + Vector2(gem_size * 0.5, -gem_size * 0.5),
			center,
			center + Vector2(-gem_size * 0.5, -gem_size * 0.5),
		])
		_gem_overlay.draw_colored_polygon(highlight, Color(1, 1, 1, 0.25))

## Compute the board's correct rest position from the parent CenterContainer.
## This avoids stale cached positions that cause drift after shake/bounce.
func _get_rest_position() -> Vector2:
	var parent_ctrl := get_parent() as Control
	if parent_ctrl:
		return (parent_ctrl.size - size) * 0.5
	return position

func _setup_styles() -> void:
	_bg_style = StyleBoxFlat.new()
	_bg_style.bg_color = AppColors.BOARD_BG
	_bg_style.corner_radius_top_left = CORNER_RADIUS
	_bg_style.corner_radius_top_right = CORNER_RADIUS
	_bg_style.corner_radius_bottom_left = CORNER_RADIUS
	_bg_style.corner_radius_bottom_right = CORNER_RADIUS
	_bg_style.border_width_left = int(BORDER_WIDTH)
	_bg_style.border_width_top = int(BORDER_WIDTH)
	_bg_style.border_width_right = int(BORDER_WIDTH)
	_bg_style.border_width_bottom = int(BORDER_WIDTH)
	_bg_style.border_color = AppColors.BOARD_BORDER
	_bg_style.shadow_color = Color(0, 0, 0, 0.4)
	_bg_style.shadow_size = 8

func _calculate_cell_size() -> void:
	var viewport_size := get_viewport_rect().size
	var available_width := viewport_size.x - GameConstants.BOARD_HORIZONTAL_PADDING
	var available_height := viewport_size.y - GameConstants.BOARD_VERTICAL_RESERVED

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

	queue_redraw()

func get_cell_size() -> float:
	return _cell_size

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _cells.size() > 0:
		_calculate_cell_size()
		_layout_cells()

func update_from_state(board: BoardState) -> void:
	for y in board.rows:
		for x in board.columns:
			var cell_data: Dictionary = board.grid[y][x]
			if cell_data["occupied"]:
				var age: int = cell_data.get("age", 0)
				var special: int = cell_data.get("special_type", GameConstants.SPECIAL_TILE_NONE)
				_cells[y][x].set_filled(cell_data["color"], age, special)
			else:
				_cells[y][x].set_empty()

func show_highlight(gx: int, gy: int, piece: BlockPiece, can_place: bool) -> void:
	clear_highlights()
	_highlighted_cells.clear()
	for cell_pos in piece.occupied_cells_at(gx, gy):
		if cell_pos.x >= 0 and cell_pos.x < GameConstants.BOARD_COLUMNS \
		   and cell_pos.y >= 0 and cell_pos.y < GameConstants.BOARD_ROWS:
			_cells[cell_pos.y][cell_pos.x].set_highlight(can_place)
			_highlighted_cells.append(Vector2i(cell_pos.x, cell_pos.y))

func clear_highlights() -> void:
	for pos in _highlighted_cells:
		_cells[pos.y][pos.x].clear_highlight()
	_highlighted_cells.clear()

func play_place_effect(cells: Array) -> void:
	var delay := 0.0
	var placed_set: Dictionary = {}
	for cell_pos in cells:
		if cell_pos.x >= 0 and cell_pos.x < GameConstants.BOARD_COLUMNS \
		   and cell_pos.y >= 0 and cell_pos.y < GameConstants.BOARD_ROWS:
			_cells[cell_pos.y][cell_pos.x].play_place_pulse(delay)
			placed_set[Vector2i(cell_pos.x, cell_pos.y)] = true
			delay += 0.015

	# Adjacent block ripple: micro-bounce occupied cells within distance 2
	var rippled: Dictionary = {}
	for cell_pos in cells:
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var nx: int = cell_pos.x + dx
				var ny: int = cell_pos.y + dy
				if nx < 0 or nx >= GameConstants.BOARD_COLUMNS or ny < 0 or ny >= GameConstants.BOARD_ROWS:
					continue
				var npos := Vector2i(nx, ny)
				if npos in placed_set or npos in rippled:
					continue
				var dist: int = absi(dx) + absi(dy)
				if dist < 1 or dist > 2:
					continue
				var ripple_delay: float = 0.0 if dist == 1 else 0.03
				_cells[ny][nx].play_adjacent_ripple(ripple_delay)
				rippled[npos] = true


# Cache cell colors before board state update for clear animations
var _cached_cell_colors: Dictionary = {}

func cache_extra_cell_color(pos: Vector2i) -> void:
	if pos not in _cached_cell_colors:
		if pos.x >= 0 and pos.x < GameConstants.BOARD_COLUMNS and pos.y >= 0 and pos.y < GameConstants.BOARD_ROWS:
			_cached_cell_colors[pos] = _get_cell_light_color(pos.x, pos.y)


func cache_cell_colors_for_clear(rows: Array, cols: Array) -> void:
	_cached_cell_colors.clear()
	for row in rows:
		for x in GameConstants.BOARD_COLUMNS:
			_cached_cell_colors[Vector2i(x, row)] = _get_cell_light_color(x, row)
	for col in cols:
		for y in GameConstants.BOARD_ROWS:
			var key := Vector2i(col, y)
			if key not in _cached_cell_colors:
				_cached_cell_colors[key] = _get_cell_light_color(col, y)

func play_line_clear_effect(rows: Array, cols: Array) -> void:
	HapticManager.cell_clear()
	var particle_positions: Array = []
	var particle_colors: Array = []

	for row in rows:
		for x in GameConstants.BOARD_COLUMNS:
			particle_positions.append(Vector2(x * _cell_size, row * _cell_size))
			var key := Vector2i(x, row)
			particle_colors.append(_cached_cell_colors.get(key, Color.WHITE))

	for col in cols:
		for y in GameConstants.BOARD_ROWS:
			var pos := Vector2(col * _cell_size, y * _cell_size)
			if pos not in particle_positions:
				particle_positions.append(pos)
				var key := Vector2i(col, y)
				particle_colors.append(_cached_cell_colors.get(key, Color.WHITE))

	# Determine particle intensity based on total lines cleared
	var total_lines := rows.size() + cols.size()
	var intensity := 1.0
	if total_lines >= 3:
		intensity = 2.0
	elif total_lines == 2:
		intensity = 1.5

	_emit_particles_and_shockwave(particle_positions, particle_colors, intensity, _cell_size * 4.0)

	# Cell flash animations — pass cached color since cells are already empty
	# SKIP cells that were re-filled (e.g. special tile drops) after clear
	var delay := 0.0
	for row in rows:
		for x in GameConstants.BOARD_COLUMNS:
			if _cells[row][x]._occupied:
				continue  # Don't flash cells that got a special tile drop
			var key := Vector2i(x, row)
			var cached: Color = _cached_cell_colors.get(key, Color.WHITE)
			_cells[row][x].play_clear_flash(
				GameConstants.LINE_CLEAR_ANIM_DURATION, delay, cached)
			delay += 0.02
	for col in cols:
		delay = 0.0
		for y in GameConstants.BOARD_ROWS:
			if _cells[y][col]._occupied:
				continue  # Don't flash cells that got a special tile drop
			var key := Vector2i(col, y)
			var cached: Color = _cached_cell_colors.get(key, Color.WHITE)
			_cells[y][col].play_clear_flash(
				GameConstants.LINE_CLEAR_ANIM_DURATION, delay, cached)
			delay += 0.02

func play_color_match_effect(groups: Array) -> void:
	for group in groups:
		var particle_positions: Array = []
		var particle_colors: Array = []
		var delay := 0.0
		for cell_pos in group:
			if cell_pos.x >= 0 and cell_pos.x < GameConstants.BOARD_COLUMNS \
			   and cell_pos.y >= 0 and cell_pos.y < GameConstants.BOARD_ROWS:
				if _cells[cell_pos.y][cell_pos.x]._occupied:
					continue  # Don't flash cells re-filled after clear
				_cells[cell_pos.y][cell_pos.x].play_color_match_flash(
					GameConstants.COLOR_MATCH_ANIM_DURATION, delay)
				delay += 0.02
				particle_positions.append(Vector2(cell_pos.x * _cell_size, cell_pos.y * _cell_size))
				particle_colors.append(_get_cell_light_color(cell_pos.x, cell_pos.y))

		_emit_particles_and_shockwave(particle_positions, particle_colors, 0.8, _cell_size * 2.0)


func _get_cell_light_color(x: int, y: int) -> Color:
	var cell_color: int = _cells[y][x]._color
	if cell_color >= 0:
		return AppColors.get_block_light_color(cell_color)
	return Color.WHITE


func _emit_particles_and_shockwave(positions: Array, colors: Array, intensity: float, shockwave_radius: float) -> void:
	if positions.is_empty():
		return
	# Particle burst — use pooled system to avoid allocation churn
	var particles := _get_particle_system()
	particles.top_level = true
	var effect_parent := get_parent() if get_parent() != null else self
	effect_parent.add_child(particles)
	particles.global_position = global_position
	particles.size = get_viewport_rect().size
	particles.emit_at(positions, _cell_size, colors, intensity)
	# Shockwave rings at center of affected area
	var center := Vector2.ZERO
	for pos in positions:
		center += pos
	center /= positions.size()
	center += Vector2(_cell_size / 2.0, _cell_size / 2.0)
	var avg_color: Color = colors[0] if colors.size() > 0 else Color.WHITE
	# Primary shockwave
	_spawn_shockwave(center, avg_color, shockwave_radius)
	# Secondary larger, fainter shockwave for intense clears
	if intensity >= 1.5:
		_spawn_shockwave(center, Color(avg_color.r, avg_color.g, avg_color.b, 0.4), shockwave_radius * 1.6)
	# Tertiary white shockwave for 3+ lines
	if intensity >= 2.0:
		_spawn_shockwave(center, Color(1.0, 1.0, 1.0, 0.3), shockwave_radius * 2.0)

func world_to_grid(local_pos: Vector2) -> Vector2i:
	var gx := int(local_pos.x / _cell_size)
	var gy := int(local_pos.y / _cell_size)
	return Vector2i(gx, gy)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var grid_pos := world_to_grid(mb.position)
			if grid_pos.x >= 0 and grid_pos.x < GameConstants.BOARD_COLUMNS \
			   and grid_pos.y >= 0 and grid_pos.y < GameConstants.BOARD_ROWS:
				cell_tapped.emit(grid_pos.x, grid_pos.y)


# --- Line Clear Prediction (2.2) ---

func show_line_prediction(gx: int, gy: int, piece: BlockPiece, board: BoardState) -> void:
	clear_line_prediction()
	# Zero-allocation prediction — no temp BoardState created
	var result := board.predict_completed_lines(piece, gx, gy)
	var completed_rows: Array = result["rows"]
	var completed_cols: Array = result["cols"]
	# For each cell in completed rows/cols, show a subtle glow/highlight
	for row in completed_rows:
		for x in GameConstants.BOARD_COLUMNS:
			_cells[row][x].show_line_prediction()
			_predicted_cells.append(Vector2i(x, row))
	for col in completed_cols:
		for y in GameConstants.BOARD_ROWS:
			if not _predicted_cells.has(Vector2i(col, y)):
				_cells[y][col].show_line_prediction()
				_predicted_cells.append(Vector2i(col, y))


func clear_line_prediction() -> void:
	for pos in _predicted_cells:
		_cells[pos.y][pos.x].clear_line_prediction()
	_predicted_cells.clear()


# --- Blast Proximity Hint ---

func show_blast_hint(blast_rows: Array, blast_cols: Array) -> void:
	clear_blast_hint()
	for row in blast_rows:
		for x in GameConstants.BOARD_COLUMNS:
			_cells[row][x].show_blast_hint()
			_blast_hint_cells.append(Vector2i(x, row))
	for col in blast_cols:
		for y in GameConstants.BOARD_ROWS:
			if not _blast_hint_cells.has(Vector2i(col, y)):
				_cells[y][col].show_blast_hint()
				_blast_hint_cells.append(Vector2i(col, y))

func clear_blast_hint() -> void:
	for pos in _blast_hint_cells:
		_cells[pos.y][pos.x].clear_blast_hint()
	_blast_hint_cells.clear()


# --- Bomb Explosion Effect ---

func play_bomb_effect(destroyed_cells: Array) -> void:
	var positions: Array = []
	var colors: Array = []
	var bomb_color := Color(1.0, 0.6, 0.2)  # orange burst
	for pos in destroyed_cells:
		positions.append(Vector2(pos.x * _cell_size, pos.y * _cell_size))
		colors.append(bomb_color)
	if not positions.is_empty():
		_emit_particles_and_shockwave(positions, colors, 1.5, _cell_size * 3.0)


# --- Level Up Effect (2.3) ---

func play_level_up_effect() -> void:
	# Flash the board border from normal to accent color and back
	var tween := create_tween()
	tween.tween_property(_bg_style, "border_color", AppColors.ACCENT, 0.15) \
		 .set_ease(Tween.EASE_OUT)
	tween.tween_property(_bg_style, "border_color", AppColors.BOARD_BORDER, 0.3) \
		 .set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): queue_redraw())
	# Also trigger redraw during the animation
	tween.parallel().tween_callback(func(): queue_redraw()).set_delay(0.05)
	tween.parallel().tween_callback(func(): queue_redraw()).set_delay(0.15)
	tween.parallel().tween_callback(func(): queue_redraw()).set_delay(0.3)


# --- Crisis Warning (2.11) ---

func update_crisis_state(board: BoardState) -> void:
	var density := board.fill_ratio()

	if density >= 0.8:
		_bg_style.border_color = AppColors.CORAL
		_start_crisis_pulse(0.3)  # Fast pulse at 80%+
	elif density >= 0.7:
		_bg_style.border_color = Color(AppColors.AMBER, 0.8)
		_start_crisis_pulse(0.6)  # Normal pulse at 70%+
	else:
		_bg_style.border_color = AppColors.BOARD_BORDER
		_stop_crisis_pulse()
	queue_redraw()


func _start_crisis_pulse(period: float) -> void:
	# If already pulsing at the same speed, don't restart
	if _crisis_active and _crisis_pulse_tween and _crisis_pulse_tween.is_valid():
		return
	# Kill any existing pulse before starting a new one
	_stop_crisis_pulse()
	_crisis_active = true

	var half_period := period / 2.0
	_crisis_pulse_tween = create_tween()
	_crisis_pulse_tween.set_loops(0)  # Infinite looping

	# Pulse border alpha from 1.0 down to 0.4 and back
	_crisis_pulse_tween.tween_method(_set_border_alpha, 1.0, 0.4, half_period) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_crisis_pulse_tween.tween_method(_set_border_alpha, 0.4, 1.0, half_period) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _stop_crisis_pulse() -> void:
	_crisis_active = false
	if _crisis_pulse_tween and _crisis_pulse_tween.is_valid():
		_crisis_pulse_tween.kill()
		_crisis_pulse_tween = null
	# Restore full opacity on the border
	if _bg_style:
		_bg_style.border_color.a = 1.0
		queue_redraw()


func _set_border_alpha(alpha: float) -> void:
	if _bg_style:
		_bg_style.border_color.a = alpha
		queue_redraw()


# --- Screen Shake (Game Feel P0) ---

func _apply_offsets() -> void:
	position = _get_rest_position() + _shake_offset + _bounce_offset

func play_screen_shake(intensity: float, duration: float) -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_offset = Vector2.ZERO

	var oscillations := 6
	var step_duration := duration / float(oscillations)
	_shake_tween = create_tween()

	for i in oscillations:
		var progress := float(i) / float(oscillations)
		var amplitude := intensity * (1.0 - progress)
		var angle := progress * TAU * 2.0
		var target_offset := Vector2(cos(angle), sin(angle)) * amplitude
		_shake_tween.tween_property(self, "_shake_offset", target_offset, step_duration) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	_shake_tween.tween_property(self, "_shake_offset", Vector2.ZERO, step_duration * 0.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)


# --- Board Micro-Bounce (Game Feel P0) ---

func play_place_bounce() -> void:
	if _bounce_tween and _bounce_tween.is_valid():
		_bounce_tween.kill()
	_bounce_offset = Vector2.ZERO

	_bounce_tween = create_tween()
	_bounce_tween.tween_property(self, "_bounce_offset",
		Vector2(0.0, 2.0), 0.04) \
		.set_ease(Tween.EASE_OUT)
	_bounce_tween.tween_property(self, "_bounce_offset",
		Vector2.ZERO, 0.08) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _spawn_shockwave(center: Vector2, color: Color, max_radius: float) -> void:
	_shockwaves.append({
		"center": center,
		"color": color,
		"max_radius": max_radius,
		"age": 0.0,
		"duration": 0.4,
	})
	set_process(true)


func _process(delta: float) -> void:
	var alive := false
	for sw in _shockwaves:
		sw["age"] += delta
		if sw["age"] < sw["duration"]:
			alive = true
	if alive:
		queue_redraw()
	else:
		_shockwaves.clear()
		set_process(false)


func _draw() -> void:
	# Single subtle outer border (cached to avoid per-frame allocation)
	var border_rect := Rect2(Vector2(-2, -2), size + Vector2(4, 4))
	if _border_style_cache == null:
		_border_style_cache = StyleBoxFlat.new()
		_border_style_cache.bg_color = Color.TRANSPARENT
		_border_style_cache.border_width_left = 2
		_border_style_cache.border_width_top = 2
		_border_style_cache.border_width_right = 2
		_border_style_cache.border_width_bottom = 2
		_border_style_cache.border_color = Color("3D3D5C")
		_border_style_cache.corner_radius_top_left = CORNER_RADIUS + 2
		_border_style_cache.corner_radius_top_right = CORNER_RADIUS + 2
		_border_style_cache.corner_radius_bottom_left = CORNER_RADIUS + 2
		_border_style_cache.corner_radius_bottom_right = CORNER_RADIUS + 2
	draw_style_box(_border_style_cache, border_rect)

	# Draw dark rounded background with border
	if _bg_style:
		draw_style_box(_bg_style, Rect2(Vector2.ZERO, size))

	# Inner glow removed — was causing uneven empty cell appearance

	# Draw grid lines
	for i in range(1, GameConstants.BOARD_COLUMNS):
		var x := i * _cell_size
		draw_line(Vector2(x, 0), Vector2(x, size.y), AppColors.GRID_LINE, 1.0)
	for i in range(1, GameConstants.BOARD_ROWS):
		var y := i * _cell_size
		draw_line(Vector2(0, y), Vector2(size.x, y), AppColors.GRID_LINE, 1.0)

	# Corner gems drawn by _gem_overlay (on top of cells)

	# Shockwave rings with glow
	for sw in _shockwaves:
		if sw["age"] >= sw["duration"]:
			continue
		var progress: float = sw["age"] / sw["duration"]
		var radius: float = sw["max_radius"] * ease(progress, 0.5)
		var alpha: float = (1.0 - progress * progress) * 0.7
		var sw_col: Color = sw["color"]
		var sw_color: Color = Color(sw_col.r, sw_col.g, sw_col.b, alpha)
		var width: float = lerpf(4.0, 1.0, progress)
		# Outer glow ring
		var glow_alpha: float = alpha * 0.3
		var glow_color: Color = Color(sw_col.r, sw_col.g, sw_col.b, glow_alpha)
		if radius > 2.0:
			draw_arc(sw["center"], radius, 0.0, TAU, 48, glow_color, width + 3.0)
		# Main ring
		draw_arc(sw["center"], radius, 0.0, TAU, 48, sw_color, width)


## --- Near-Miss Hints (Phase 1: line near-complete + color cluster) ---

func update_near_miss_hints(board: BoardState) -> void:
	_update_near_line_hints(board)
	_update_cluster_hints(board)


func _update_near_line_hints(board: BoardState) -> void:
	# Clear previous hints
	for pos in _near_line_hint_cells:
		_cells[pos.y][pos.x].clear_near_line_hint()
	_near_line_hint_cells.clear()

	# Check rows: 7/8 filled = near complete
	for y in board.rows:
		var filled := 0
		for x in board.columns:
			var cell: Dictionary = board.grid[y][x]
			if cell["occupied"]:
				filled += 1
		if filled == 7:
			for x in board.columns:
				_cells[y][x].show_near_line_hint()
				_near_line_hint_cells.append(Vector2i(x, y))

	# Check columns: 7/8 filled = near complete
	for x in board.columns:
		var filled := 0
		for y in board.rows:
			var cell: Dictionary = board.grid[y][x]
			if cell["occupied"]:
				filled += 1
		if filled == 7:
			for y in board.rows:
				if not _near_line_hint_cells.has(Vector2i(x, y)):
					_cells[y][x].show_near_line_hint()
					_near_line_hint_cells.append(Vector2i(x, y))


func _update_cluster_hints(board: BoardState) -> void:
	# Clear previous hints
	for pos in _cluster_hint_cells:
		_cells[pos.y][pos.x].clear_cluster_hint()
	_cluster_hint_cells.clear()

	# Find color groups of 4+ connected cells (chain triggers at 5)
	var groups: Array = board.find_color_matches_threshold(4)
	for group in groups:
		if group.size() < 4:
			continue
		# Get group color from first cell
		var first_pos: Vector2i = group[0]
		var group_color: int = board.grid[first_pos.y][first_pos.x]["color"]
		for pos in group:
			var p: Vector2i = pos
			_cells[p.y][p.x].show_cluster_hint(group_color)
			_cluster_hint_cells.append(p)


func clear_near_miss_hints() -> void:
	for pos in _near_line_hint_cells:
		_cells[pos.y][pos.x].clear_near_line_hint()
	_near_line_hint_cells.clear()
	for pos in _cluster_hint_cells:
		_cells[pos.y][pos.x].clear_cluster_hint()
	_cluster_hint_cells.clear()


# --- Anticipation Phase (dim + pulse before clear) ---

var _anticipation_tween: Tween = null

func play_clear_anticipation(rows: Array, cols: Array) -> void:
	# Dim board modulate over 0.1s
	if _anticipation_tween and _anticipation_tween.is_valid():
		_anticipation_tween.kill()
	_anticipation_tween = create_tween()
	_anticipation_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_anticipation_tween.tween_property(self, "modulate:a", 0.85, 0.1)
	# Pulse white overlay on affected cells
	var affected: Dictionary = {}
	for row in rows:
		for x in GameConstants.BOARD_COLUMNS:
			affected[Vector2i(x, row)] = true
	for col in cols:
		for y in GameConstants.BOARD_ROWS:
			affected[Vector2i(col, y)] = true
	for pos in affected:
		var p: Vector2i = pos
		if p.x >= 0 and p.x < GameConstants.BOARD_COLUMNS and p.y >= 0 and p.y < GameConstants.BOARD_ROWS:
			_cells[p.y][p.x].play_anticipation_pulse()


func end_clear_anticipation() -> void:
	if _anticipation_tween and _anticipation_tween.is_valid():
		_anticipation_tween.kill()
	_anticipation_tween = create_tween()
	_anticipation_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_anticipation_tween.tween_property(self, "modulate:a", 1.0, 0.15)


# --- Camera Zoom Pulse ---

var _zoom_tween: Tween = null

func play_camera_zoom(zoom_in: float, duration: float) -> void:
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()
	# Set pivot to board center
	pivot_offset = size / 2.0
	_zoom_tween = create_tween()
	_zoom_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	var half_dur: float = duration / 2.0
	_zoom_tween.tween_property(self, "scale", Vector2(zoom_in, zoom_in), half_dur) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_zoom_tween.tween_property(self, "scale", Vector2.ONE, half_dur) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


# --- Blast Screen Flash ---

func play_blast_flash(color_idx: int) -> void:
	# Create a full-screen flash overlay via a temporary Control in parent
	var flash_overlay := Control.new()
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_overlay.top_level = true
	flash_overlay.z_index = 50
	var vp_size := get_viewport_rect().size
	flash_overlay.size = vp_size
	flash_overlay.position = Vector2.ZERO
	var effect_parent: Node = get_parent() if get_parent() != null else self
	effect_parent.add_child(flash_overlay)

	# White flash phase
	var white_panel := ColorRect.new()
	white_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	white_panel.size = vp_size
	white_panel.color = Color(1.0, 1.0, 1.0, 0.0)
	flash_overlay.add_child(white_panel)

	# Colored flash phase
	var blast_color: Color = AppColors.get_block_light_color(color_idx) if color_idx >= 0 else Color.WHITE
	var color_panel := ColorRect.new()
	color_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_panel.size = vp_size
	color_panel.color = Color(blast_color.r, blast_color.g, blast_color.b, 0.0)
	flash_overlay.add_child(color_panel)

	var tween := flash_overlay.create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	# White flash: 0→0.15→0 over 0.15s
	tween.tween_property(white_panel, "color:a", 0.15, 0.05)
	tween.tween_property(white_panel, "color:a", 0.0, 0.10)
	# Colored flash: 0→0.1→0 over 0.2s
	tween.tween_property(color_panel, "color:a", 0.1, 0.07)
	tween.tween_property(color_panel, "color:a", 0.0, 0.13)
	# Cleanup
	tween.tween_callback(flash_overlay.queue_free)


# --- Chain Visual Cascade ---

func play_chain_cascade_group(group: Array, stagger_delay: float) -> void:
	# Highlight cells in this group with their color glow, then pop them
	var delay: float = 0.0
	for cell_pos in group:
		var p: Vector2i = cell_pos
		if p.x >= 0 and p.x < GameConstants.BOARD_COLUMNS and p.y >= 0 and p.y < GameConstants.BOARD_ROWS:
			var cached_color: Color = _cached_cell_colors.get(p, Color.WHITE)
			_cells[p.y][p.x].play_chain_pop(delay, cached_color)
			delay += 0.02

	# Particles for this group
	var positions: Array = []
	var colors: Array = []
	for cell_pos in group:
		var p: Vector2i = cell_pos
		positions.append(Vector2(p.x * _cell_size, p.y * _cell_size))
		colors.append(_cached_cell_colors.get(p, Color.WHITE))
	if not positions.is_empty():
		_emit_particles_and_shockwave(positions, colors, 1.0, _cell_size * 3.0)


# --- Blast Cell Explosion ---

func play_blast_cell_explosion(removed_positions: Array, blast_color_idx: int) -> void:
	var positions: Array = []
	var colors: Array = []
	var blast_color: Color = AppColors.get_block_light_color(blast_color_idx) if blast_color_idx >= 0 else Color.WHITE
	for pos in removed_positions:
		var p: Vector2i = pos
		if p.x >= 0 and p.x < GameConstants.BOARD_COLUMNS and p.y >= 0 and p.y < GameConstants.BOARD_ROWS:
			positions.append(Vector2(p.x * _cell_size, p.y * _cell_size))
			colors.append(blast_color)
			# Scale up + fade on the cell
			_cells[p.y][p.x].play_blast_explode()
	if not positions.is_empty():
		_emit_particles_and_shockwave(positions, colors, 2.0, _cell_size * 5.0)


## Perfect clear: wave of cell flashes radiating from center outward
func play_perfect_clear_effect() -> void:
	var center_x: float = float(GameConstants.BOARD_COLUMNS) / 2.0
	var center_y: float = float(GameConstants.BOARD_ROWS) / 2.0
	# Collect cells with their distance from center
	var cell_dist: Array = []
	for y in GameConstants.BOARD_ROWS:
		for x in GameConstants.BOARD_COLUMNS:
			var dx: float = float(x) - center_x + 0.5
			var dy: float = float(y) - center_y + 0.5
			var dist: float = sqrt(dx * dx + dy * dy)
			cell_dist.append({"x": x, "y": y, "dist": dist})
	# Sort by distance
	cell_dist.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["dist"] < b["dist"])
	# Max distance for normalization
	var last_entry: Dictionary = cell_dist[cell_dist.size() - 1]
	var max_dist: float = last_entry["dist"]
	# Flash each cell with delay based on distance
	for cd in cell_dist:
		var x: int = cd["x"]
		var y: int = cd["y"]
		var d: float = cd["dist"]
		var norm_dist: float = d / max_dist
		var delay: float = norm_dist * 0.4  # 0 to 0.4s wave
		_cells[y][x].play_perfect_wave_flash(delay)


func _draw_corner_gems() -> void:
	var gem_size := 10.0  # Half-size of the diamond (20px total)
	var inset := 8.0  # Inside the frame corners
	var gem_data := [
		{"pos": Vector2(inset, inset), "color": Color(0.231, 0.510, 0.965), "glow": Color(0.231, 0.510, 0.965, 0.5)},       # TL: blue #3B82F6
		{"pos": Vector2(size.x - inset, inset), "color": Color(0.925, 0.286, 0.600), "glow": Color(0.925, 0.286, 0.600, 0.5)}, # TR: pink #EC4899
		{"pos": Vector2(inset, size.y - inset), "color": Color(0.063, 0.725, 0.506), "glow": Color(0.063, 0.725, 0.506, 0.5)}, # BL: green #10B981
		{"pos": Vector2(size.x - inset, size.y - inset), "color": Color(0.961, 0.620, 0.043), "glow": Color(0.961, 0.620, 0.043, 0.5)}, # BR: gold #F59E0B
	]
	for gem in gem_data:
		var center: Vector2 = gem["pos"]
		var color: Color = gem["color"]
		var glow_color: Color = gem["glow"]
		# Outer soft glow
		draw_circle(center, gem_size + 12, Color(glow_color.r, glow_color.g, glow_color.b, 0.15))
		# Inner glow circle behind the gem
		draw_circle(center, gem_size + 6, glow_color)
		# Diamond shape (rotated 45° square)
		var points := PackedVector2Array([
			center + Vector2(0, -gem_size),   # top
			center + Vector2(gem_size, 0),     # right
			center + Vector2(0, gem_size),     # bottom
			center + Vector2(-gem_size, 0),    # left
		])
		draw_colored_polygon(points, color)
		# Highlight on top half of diamond for depth
		var highlight_points := PackedVector2Array([
			center + Vector2(0, -gem_size),
			center + Vector2(gem_size * 0.5, -gem_size * 0.5),
			center,
			center + Vector2(-gem_size * 0.5, -gem_size * 0.5),
		])
		draw_colored_polygon(highlight_points, Color(1, 1, 1, 0.25))
