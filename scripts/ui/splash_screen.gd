extends Control

signal intro_finished()

const BLOCK_SIZE := 32.0
const BLOCK_GAP := 3.0
const GRID_COLS := 5
const GRID_ROWS := 5

@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var block_container: Control = $BlockContainer

var _blocks: Array[ColorRect] = []

# Block pattern: chromatic cross/diamond shape
const PATTERN := [
	[0, 0, 1, 0, 0],
	[0, 1, 1, 1, 0],
	[1, 1, 1, 1, 1],
	[0, 1, 1, 1, 0],
	[0, 0, 1, 0, 0],
]

const BLOCK_COLORS := [
	Color("EF4444"),  # coral
	Color("F59E0B"),  # amber
	Color("06B6D4"),  # sky
	Color("10B981"),  # mint
	Color("8B5CF6"),  # lavender
	Color("EAB308"),  # lemon
]

func _ready() -> void:
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	_create_blocks()
	_start_animation()

func _create_blocks() -> void:
	var total_w := GRID_COLS * (BLOCK_SIZE + BLOCK_GAP) - BLOCK_GAP
	var total_h := GRID_ROWS * (BLOCK_SIZE + BLOCK_GAP) - BLOCK_GAP
	var start_x := (size.x - total_w) / 2.0
	var start_y := (size.y - total_h) / 2.0 - 80.0

	var color_idx := 0
	for row in GRID_ROWS:
		for col in GRID_COLS:
			if PATTERN[row][col] == 0:
				continue

			var block := ColorRect.new()
			block.size = Vector2(BLOCK_SIZE, BLOCK_SIZE)
			var target_x := start_x + col * (BLOCK_SIZE + BLOCK_GAP)
			var target_y := start_y + row * (BLOCK_SIZE + BLOCK_GAP)
			block.position = Vector2(target_x, -BLOCK_SIZE - randf_range(20, 120))
			block.color = BLOCK_COLORS[color_idx % BLOCK_COLORS.size()]
			block.modulate.a = 0.0
			block_container.add_child(block)
			_blocks.append(block)
			block.set_meta("target_y", target_y)
			color_idx += 1

func _start_animation() -> void:
	var delay := 0.15
	for i in _blocks.size():
		var block := _blocks[i]
		var target_y: float = block.get_meta("target_y")
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(block, "modulate:a", 1.0, 0.15).set_delay(delay * i)
		tween.tween_property(block, "position:y", target_y, 0.4) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(delay * i)

	var blocks_done_time := delay * _blocks.size() + 0.4

	# Title animation
	var title_tween := create_tween()
	title_label.pivot_offset = title_label.size / 2.0
	title_label.scale = Vector2(0.5, 0.5)
	title_tween.tween_property(title_label, "modulate:a", 1.0, 0.3) \
		.set_delay(blocks_done_time + 0.1)
	title_tween.parallel().tween_property(title_label, "scale", Vector2.ONE, 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK) \
		.set_delay(blocks_done_time + 0.1)

	# Subtitle animation
	var sub_tween := create_tween()
	sub_tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.3) \
		.set_delay(blocks_done_time + 0.5)

	# Fade out and finish
	var finish_tween := create_tween()
	finish_tween.tween_interval(blocks_done_time + 1.5)
	finish_tween.tween_property(self, "modulate:a", 0.0, 0.4)
	finish_tween.tween_callback(_on_intro_done)

func _on_intro_done() -> void:
	intro_finished.emit()
	queue_free()
