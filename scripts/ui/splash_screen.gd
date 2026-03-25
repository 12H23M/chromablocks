extends Control

signal intro_finished()

const BLOCK_SIZE := 44.0
const BLOCK_GAP := 5.0
const GRID_COLS := 3
const GRID_ROWS := 3

@onready var chroma_label: Label = $TitleContainer/ChromaLabel
@onready var blocks_label: Label = $TitleContainer/BlocksLabel
@onready var title_container: HBoxContainer = $TitleContainer
@onready var subtitle_label: Label = $SubtitleLabel
@onready var block_container: Control = $BlockContainer

var _blocks: Array[Panel] = []
var _skippable := false
var _tweens: Array[Tween] = []
var _glow_node: Control = null

const BLOCK_COLORS: Array[Color] = [
	Color("FF6B6B"), Color("4ECDC4"), Color("FFE66D"),
	Color("A8A4FF"), Color("6BCB77"), Color("FF9A9E"),
	Color("FF6B6B"), Color("FFE66D"), Color("4ECDC4"),
]

# Spiral order: center → cross → corners
const SPIRAL_ORDER: Array[int] = [4, 1, 3, 5, 7, 0, 2, 6, 8]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	chroma_label.modulate.a = 0.0
	blocks_label.modulate.a = 0.0
	title_container.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	_create_glow_node()
	_create_blocks()
	_start_animation()

	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		_skippable = true
	)

func _draw() -> void:
	# Flat background
	draw_rect(Rect2(Vector2.ZERO, size), Color("0D0B2E"))
	_draw_radial_gradient()
	_draw_grid_lines()

func _draw_radial_gradient() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.4)
	var max_radius := 220.0
	var base_color := Color("1A1145")
	var steps := 20
	for i in range(steps, 0, -1):
		var t: float = float(i) / float(steps)
		var radius: float = max_radius * t
		var alpha: float = 0.12 * (1.0 - t) + 0.02
		var c := Color(base_color.r, base_color.g, base_color.b, alpha)
		draw_circle(center, radius, c)

func _draw_grid_lines() -> void:
	var line_color := Color(1.0, 1.0, 1.0, 0.03)
	var spacing := 40.0
	# Vertical lines
	var x := 0.0
	while x <= size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), line_color, 0.5)
		x += spacing
	# Horizontal lines
	var y := 0.0
	while y <= size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), line_color, 0.5)
		y += spacing

func _gui_input(event: InputEvent) -> void:
	if _skippable and event is InputEventScreenTouch and event.pressed:
		_skip_intro()
		accept_event()

func _skip_intro() -> void:
	_skippable = false
	for tween in _tweens:
		if tween and tween.is_valid():
			tween.kill()
	_tweens.clear()

	# Snap all elements to final state
	for block in _blocks:
		block.scale = Vector2.ONE
		block.modulate.a = 1.0
	chroma_label.modulate.a = 1.0
	chroma_label.scale = Vector2.ONE
	blocks_label.modulate.a = 1.0
	blocks_label.scale = Vector2.ONE
	title_container.modulate.a = 1.0
	title_container.position.y = title_container.get_meta("target_y", title_container.position.y)
	subtitle_label.modulate.a = 0.6
	if _glow_node:
		_glow_node.modulate.a = 1.0

	# Hold briefly, then fade out
	var fade_tween := create_tween()
	fade_tween.set_speed_scale(1.0 / Engine.time_scale)
	fade_tween.tween_interval(0.15)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	fade_tween.tween_callback(_on_intro_done)
	_tweens.append(fade_tween)

func _create_glow_node() -> void:
	_glow_node = Control.new()
	_glow_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glow_node.modulate.a = 0.0
	_glow_node.draw.connect(_draw_center_glow)
	block_container.add_child(_glow_node)
	# Move glow behind blocks
	block_container.move_child(_glow_node, 0)

func _draw_center_glow() -> void:
	if not _glow_node:
		return
	var total_w := GRID_COLS * (BLOCK_SIZE + BLOCK_GAP) - BLOCK_GAP
	var total_h := GRID_ROWS * (BLOCK_SIZE + BLOCK_GAP) - BLOCK_GAP
	var center_x := size.x / 2.0
	var center_y := (size.y / 2.0) - 60.0 + total_h / 2.0
	var glow_color := Color("A370F7")
	var radius := 160.0
	var steps := 16
	for i in range(steps, 0, -1):
		var t: float = float(i) / float(steps)
		var r: float = radius * t
		var alpha: float = 0.10 * (1.0 - t * t)
		var c := Color(glow_color.r, glow_color.g, glow_color.b, alpha)
		_glow_node.draw_circle(Vector2(center_x, center_y), r, c)

func _create_blocks() -> void:
	var total_w := GRID_COLS * (BLOCK_SIZE + BLOCK_GAP) - BLOCK_GAP
	var total_h := GRID_ROWS * (BLOCK_SIZE + BLOCK_GAP) - BLOCK_GAP
	var start_x := (size.x - total_w) / 2.0
	var start_y := (size.y - total_h) / 2.0 - 60.0

	for idx in 9:
		var row: int = idx / 3
		var col: int = idx % 3
		var block_color: Color = BLOCK_COLORS[idx]

		var block := Panel.new()
		block.size = Vector2(BLOCK_SIZE, BLOCK_SIZE)
		var target_x := start_x + col * (BLOCK_SIZE + BLOCK_GAP)
		var target_y := start_y + row * (BLOCK_SIZE + BLOCK_GAP)
		block.position = Vector2(target_x, target_y)
		block.pivot_offset = Vector2(BLOCK_SIZE / 2.0, BLOCK_SIZE / 2.0)
		block.scale = Vector2.ZERO
		block.modulate.a = 0.0

		var style := StyleBoxFlat.new()
		style.bg_color = block_color
		var rad := int(BLOCK_SIZE * 0.25)
		style.corner_radius_top_left = rad
		style.corner_radius_top_right = rad
		style.corner_radius_bottom_left = rad
		style.corner_radius_bottom_right = rad
		# Bottom border (darkened)
		style.border_width_bottom = 3
		style.border_color = block_color.darkened(0.3)
		# Shadow/glow
		style.shadow_color = Color(block_color, 0.35)
		style.shadow_size = 12

		block.add_theme_stylebox_override("panel", style)
		block_container.add_child(block)

		# Top highlight overlay
		var highlight := ColorRect.new()
		highlight.color = Color(block_color.lightened(0.15), 0.6)
		highlight.size = Vector2(BLOCK_SIZE - rad * 2, 2.0)
		highlight.position = Vector2(float(rad), 0.0)
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		block.add_child(highlight)

		_blocks.append(block)

func _start_animation() -> void:
	var stagger := 0.07
	var speed_scale: float = 1.0 / Engine.time_scale

	# --- Background glow fade in (0.0s → 0.5s) ---
	var glow_tween := create_tween()
	glow_tween.set_speed_scale(speed_scale)
	glow_tween.tween_property(_glow_node, "modulate:a", 1.0, 0.5)
	_tweens.append(glow_tween)

	# --- Block spiral pop-in ---
	var last_block_start := 0.0
	for i in SPIRAL_ORDER.size():
		var block_idx: int = SPIRAL_ORDER[i]
		var block: Panel = _blocks[block_idx]
		var delay: float = stagger * i

		var tween := create_tween()
		tween.set_speed_scale(speed_scale)

		# Alpha: 0 → 1
		tween.tween_property(block, "modulate:a", 1.0, 0.12).set_delay(delay)

		var scale_tween := create_tween()
		scale_tween.set_speed_scale(speed_scale)
		# Scale: 0 → 1.2 (bounce overshoot)
		scale_tween.tween_property(block, "scale", Vector2(1.2, 1.2), 0.14) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(delay)
		# Scale: 1.2 → 0.95 (settle back)
		scale_tween.tween_property(block, "scale", Vector2(0.95, 0.95), 0.08) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		# Scale: 0.95 → 1.0 (final settle)
		scale_tween.tween_property(block, "scale", Vector2.ONE, 0.06) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

		_tweens.append(tween)
		_tweens.append(scale_tween)
		last_block_start = delay

	# --- Title animation ---
	# Title triggers 0.08s after last block starts
	var title_delay: float = last_block_start + 0.08

	# Set up title labels for animation
	chroma_label.pivot_offset = chroma_label.size / 2.0
	chroma_label.scale = Vector2(0.85, 0.85)
	blocks_label.pivot_offset = blocks_label.size / 2.0
	blocks_label.scale = Vector2(0.85, 0.85)

	# Store original position and offset for slide-up
	title_container.modulate.a = 1.0
	var title_orig_y := title_container.position.y
	title_container.position.y += 12.0
	title_container.set_meta("target_y", title_orig_y)

	# "Chroma" animation
	var chroma_tween := create_tween()
	chroma_tween.set_speed_scale(speed_scale)
	chroma_tween.set_parallel(true)
	# Alpha
	chroma_tween.tween_property(chroma_label, "modulate:a", 1.0, 0.18).set_delay(title_delay)
	# Position slide up (on container)
	chroma_tween.tween_property(title_container, "position:y", title_orig_y, 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART).set_delay(title_delay)
	# Scale overshoot
	chroma_tween.tween_property(chroma_label, "scale", Vector2(1.05, 1.05), 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(title_delay)
	_tweens.append(chroma_tween)

	# Chroma scale settle
	var chroma_settle := create_tween()
	chroma_settle.set_speed_scale(speed_scale)
	chroma_settle.tween_property(chroma_label, "scale", Vector2.ONE, 0.15) \
		.set_delay(title_delay + 0.2)
	_tweens.append(chroma_settle)

	# "Blocks" animation — 0.1s after "Chroma"
	var blocks_delay: float = title_delay + 0.1
	var blocks_tween := create_tween()
	blocks_tween.set_speed_scale(speed_scale)
	blocks_tween.set_parallel(true)
	blocks_tween.tween_property(blocks_label, "modulate:a", 1.0, 0.18).set_delay(blocks_delay)
	blocks_tween.tween_property(blocks_label, "scale", Vector2(1.05, 1.05), 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(blocks_delay)
	_tweens.append(blocks_tween)

	var blocks_settle := create_tween()
	blocks_settle.set_speed_scale(speed_scale)
	blocks_settle.tween_property(blocks_label, "scale", Vector2.ONE, 0.15) \
		.set_delay(blocks_delay + 0.2)
	_tweens.append(blocks_settle)

	# --- Subtitle fade in ---
	var sub_delay: float = title_delay + 0.5
	var sub_tween := create_tween()
	sub_tween.set_speed_scale(speed_scale)
	sub_tween.tween_property(subtitle_label, "modulate:a", 0.6, 0.25).set_delay(sub_delay)
	_tweens.append(sub_tween)

	# --- Hold + fade out ---
	# All settled by ~1.64s, hold until 2.44s, fade out 0.3s
	var finish_tween := create_tween()
	finish_tween.set_speed_scale(speed_scale)
	finish_tween.tween_interval(2.44)
	finish_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	finish_tween.tween_callback(_on_intro_done)
	_tweens.append(finish_tween)

func _on_intro_done() -> void:
	intro_finished.emit()
	queue_free()
