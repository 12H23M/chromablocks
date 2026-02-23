extends Control

const CellScene := preload("res://scenes/game/cell.tscn")
const ClearParticlesScript := preload("res://scripts/game/clear_particles.gd")
const CORNER_RADIUS := 20
const BORDER_WIDTH := 2.5

var _cells: Array = []  # Array[Array[CellView]] — [y][x]
var _cell_size: float = 36.0
var _bg_style: StyleBoxFlat
var _shake_tween: Tween
var _bounce_tween: Tween
var _crisis_pulse_tween: Tween
var _crisis_active: bool = false
var _shockwaves: Array = []
var _highlighted_cells: Array = []
var _predicted_cells: Array = []

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
			var cell_node := CellScene.instantiate()
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
	_gems_enabled = true
	if _gem_overlay:
		_gem_overlay.visible = true

func disable_gems() -> void:
	_gems_enabled = false
	if _gem_overlay:
		_gem_overlay.visible = false

func _setup_gem_overlay() -> void:
	if _gem_overlay:
		_gem_overlay.queue_free()
	_gem_overlay = Control.new()
	_gem_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gem_overlay.size = size
	_gem_overlay.z_index = 10
	_gem_overlay.visible = _gems_enabled
	add_child(_gem_overlay)
	_gem_overlay.draw.connect(_draw_gems_on_overlay)

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
				_cells[y][x].set_filled(cell_data["color"])
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
	for cell_pos in cells:
		if cell_pos.x >= 0 and cell_pos.x < GameConstants.BOARD_COLUMNS \
		   and cell_pos.y >= 0 and cell_pos.y < GameConstants.BOARD_ROWS:
			_cells[cell_pos.y][cell_pos.x].play_place_pulse(delay)
			delay += 0.015


# Cache cell colors before board state update for clear animations
var _cached_cell_colors: Dictionary = {}

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
	var delay := 0.0
	for row in rows:
		for x in GameConstants.BOARD_COLUMNS:
			var key := Vector2i(x, row)
			var cached: Color = _cached_cell_colors.get(key, Color.WHITE)
			_cells[row][x].play_clear_flash(
				GameConstants.LINE_CLEAR_ANIM_DURATION, delay, cached)
			delay += 0.02
	for col in cols:
		delay = 0.0
		for y in GameConstants.BOARD_ROWS:
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
	# Particle burst — add to parent to avoid board's clip_children clipping
	var particles := Control.new()
	particles.set_script(ClearParticlesScript)
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

func play_screen_shake(intensity: float, duration: float) -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	if _bounce_tween and _bounce_tween.is_valid():
		_bounce_tween.kill()
	var rest_pos := _get_rest_position()
	position = rest_pos

	var oscillations := 6
	var step_duration := duration / float(oscillations)
	_shake_tween = create_tween()

	for i in oscillations:
		var progress := float(i) / float(oscillations)
		# Sinusoidal decay: amplitude decreases as we progress
		var amplitude := intensity * (1.0 - progress)
		var angle := progress * TAU * 2.0  # Vary direction
		var offset := Vector2(cos(angle), sin(angle)) * amplitude
		_shake_tween.tween_property(self, "position",
			rest_pos + offset, step_duration) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	# Restore to rest position at the end
	_shake_tween.tween_property(self, "position",
		rest_pos, step_duration * 0.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)


# --- Board Micro-Bounce (Game Feel P0) ---

func play_place_bounce() -> void:
	if _bounce_tween and _bounce_tween.is_valid():
		_bounce_tween.kill()
	var rest_pos := _get_rest_position()
	position = rest_pos

	_bounce_tween = create_tween()
	_bounce_tween.tween_property(self, "position:y",
		rest_pos.y + 2.0, 0.04) \
		.set_ease(Tween.EASE_OUT)
	_bounce_tween.tween_property(self, "position:y",
		rest_pos.y, 0.08) \
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
	# Outer frame glow — 3-layer expanding glow with decreasing alpha
	for i in range(3, 0, -1):
		var expand := float(i) * 4.0
		var alpha := 0.15 * (1.0 - float(i) / 4.0)
		var glow_rect := Rect2(Vector2(-expand, -expand), size + Vector2(expand * 2, expand * 2))
		var glow_style := StyleBoxFlat.new()
		glow_style.bg_color = Color(0.39, 0.27, 1.0, alpha)
		glow_style.corner_radius_top_left = CORNER_RADIUS + int(expand)
		glow_style.corner_radius_top_right = CORNER_RADIUS + int(expand)
		glow_style.corner_radius_bottom_left = CORNER_RADIUS + int(expand)
		glow_style.corner_radius_bottom_right = CORNER_RADIUS + int(expand)
		draw_style_box(glow_style, glow_rect)

	# Draw dark rounded background with border
	if _bg_style:
		draw_style_box(_bg_style, Rect2(Vector2.ZERO, size))

	# Subtle inner glow — radial gradient overlay from corners
	var glow_base := Color(0.47, 0.39, 1.0, 0.06)
	var board_corners := [Vector2.ZERO, Vector2(size.x, 0), Vector2(0, size.y), size]
	for corner in board_corners:
		var glow_radius := size.length() * 0.3
		var steps := 6
		for s in range(steps, 0, -1):
			var t := float(s) / float(steps)
			var radius := glow_radius * t
			var a := glow_base.a * (1.0 - t)
			var c := Color(glow_base.r, glow_base.g, glow_base.b, a)
			draw_circle(corner, radius, c)

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
		var sw_color := Color(sw["color"].r, sw["color"].g, sw["color"].b, alpha)
		var width := lerpf(4.0, 1.0, progress)
		# Outer glow ring
		var glow_alpha := alpha * 0.3
		var glow_color := Color(sw["color"].r, sw["color"].g, sw["color"].b, glow_alpha)
		if radius > 2.0:
			draw_arc(sw["center"], radius, 0.0, TAU, 48, glow_color, width + 3.0)
		# Main ring
		draw_arc(sw["center"], radius, 0.0, TAU, 48, sw_color, width)


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
