extends Control

signal intro_finished()

const BLOCK_SIZE := 28.0
const BLOCK_GAP := 3.0
const GRID_COLS := 3
const GRID_ROWS := 3

@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var block_container: Control = $BlockContainer

var _blocks: Array[Panel] = []
var _skippable := false
var _tweens: Array[Tween] = []

# Simple 3x3 grid — matches home screen logo
const PATTERN := [
	[1, 1, 1],
	[1, 1, 1],
	[1, 1, 1],
]

const BLOCK_COLORS := [
	Color("FF6B9D"), Color("FF8C42"), Color("FFD93D"),
	Color("6BCB77"), Color("4D96FF"), Color("9B72CF"),
	Color("FF6B9D"), Color("FFD93D"), Color("4D96FF"),
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	_create_blocks()
	_start_animation()

	get_tree().create_timer(0.3).timeout.connect(func() -> void:
		_skippable = true
	)

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
	var fade_tween := create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	fade_tween.tween_callback(_on_intro_done)

func _create_blocks() -> void:
	var total_w := GRID_COLS * (BLOCK_SIZE + BLOCK_GAP) - BLOCK_GAP
	var total_h := GRID_ROWS * (BLOCK_SIZE + BLOCK_GAP) - BLOCK_GAP
	var start_x := (size.x - total_w) / 2.0
	var start_y := (size.y - total_h) / 2.0 - 60.0

	var color_idx := 0
	for row in GRID_ROWS:
		for col in GRID_COLS:
			if PATTERN[row][col] == 0:
				continue

			var block := Panel.new()
			block.size = Vector2(BLOCK_SIZE, BLOCK_SIZE)
			var target_x := start_x + col * (BLOCK_SIZE + BLOCK_GAP)
			var target_y := start_y + row * (BLOCK_SIZE + BLOCK_GAP)
			# Start from center, scaled to 0
			block.position = Vector2(target_x, target_y)
			block.pivot_offset = Vector2(BLOCK_SIZE / 2.0, BLOCK_SIZE / 2.0)
			block.scale = Vector2.ZERO
			var block_color: Color = BLOCK_COLORS[color_idx % BLOCK_COLORS.size()]
			var style := StyleBoxFlat.new()
			style.bg_color = block_color
			var rad := int(BLOCK_SIZE * 0.25)
			style.corner_radius_top_left = rad
			style.corner_radius_top_right = rad
			style.corner_radius_bottom_left = rad
			style.corner_radius_bottom_right = rad
			# Subtle bottom border only, no glow/shadow
			style.border_width_bottom = 3
			style.border_color = block_color.darkened(0.25)
			block.add_theme_stylebox_override("panel", style)
			block_container.add_child(block)
			_blocks.append(block)
			block.set_meta("target_y", target_y)
			color_idx += 1

func _start_animation() -> void:
	# Pop-in blocks with stagger (fast, snappy)
	var stagger := 0.06
	for i in _blocks.size():
		var block := _blocks[i]
		var tween := create_tween()
		tween.tween_property(block, "scale", Vector2(1.15, 1.15), 0.15) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(stagger * i)
		tween.tween_property(block, "scale", Vector2.ONE, 0.08) \
			.set_ease(Tween.EASE_IN_OUT)
		_tweens.append(tween)

	var blocks_done_time := stagger * _blocks.size() + 0.23

	# Title — slide up + fade in
	var title_tween := create_tween()
	title_label.pivot_offset = title_label.size / 2.0
	title_label.position.y += 20.0
	var title_target_y := title_label.position.y - 20.0
	title_tween.set_parallel(true)
	title_tween.tween_property(title_label, "modulate:a", 1.0, 0.25) \
		.set_delay(blocks_done_time)
	title_tween.tween_property(title_label, "position:y", title_target_y, 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC) \
		.set_delay(blocks_done_time)
	_tweens.append(title_tween)

	# Subtitle — fade in
	var sub_tween := create_tween()
	sub_tween.tween_property(subtitle_label, "modulate:a", 0.6, 0.25) \
		.set_delay(blocks_done_time + 0.2)
	_tweens.append(sub_tween)

	# Hold + fade out
	var finish_tween := create_tween()
	finish_tween.tween_interval(blocks_done_time + 1.2)
	finish_tween.tween_property(self, "modulate:a", 0.0, 0.35)
	finish_tween.tween_callback(_on_intro_done)
	_tweens.append(finish_tween)

func _on_intro_done() -> void:
	intro_finished.emit()
	queue_free()
