extends VBoxContainer

@onready var score_label: Label = $TopBar/ScoreDisplay/ScoreValue
@onready var level_label: Label = $TopBar/LevelBadge/LevelContent/LevelValue
@onready var best_label: Label = $InfoRow/BestChip/BestContent/BestValue
@onready var xp_bar: Control = $InfoRow/XPBar

var _prev_combo := 0
var _combo_tween: Tween
var _displayed_score: int = 0
var _score_tween: Tween
var _color_flash_tween: Tween
var _new_best_shown := false
var _new_best_label: Label
var _current_high_score: int = 0


func _ready() -> void:
	pass  # Combo display moved to full-screen overlay popup


func update_from_state(state: GameState) -> void:
	_current_high_score = state.high_score
	_animate_score(state.score)
	level_label.text = "%02d" % state.level
	best_label.text = _format_number(state.high_score)
	_update_combo(state.combo)
	_update_level_progress(state.lines_cleared, state.level)
	_check_new_best(state.score)


func _update_level_progress(lines_cleared: int, current_level: int) -> void:
	# Sum lines needed to reach current level
	var lines_at_current := 0
	for lv in range(1, current_level):
		lines_at_current += GameConstants.lines_for_next_level(lv)
	# Lines needed to advance from current level
	var lines_to_next := GameConstants.lines_for_next_level(current_level)
	var progress := lines_cleared - lines_at_current
	if lines_to_next > 0:
		xp_bar.set_progress(clampf(float(progress) / float(lines_to_next), 0.0, 1.0))
	else:
		xp_bar.set_progress(0.0)


func _animate_score(target_score: int) -> void:
	if target_score == _displayed_score:
		return

	# Kill any existing score tween before starting a new one
	if _score_tween and _score_tween.is_valid():
		_score_tween.kill()

	var score_increased := target_score > _displayed_score

	_score_tween = create_tween()
	_score_tween.tween_method(_set_score_display, _displayed_score, target_score, 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Scale bounce + color flash when score increases
	if score_increased:
		score_label.pivot_offset = score_label.size / 2.0
		_score_tween.parallel().tween_property(score_label, "scale",
			Vector2(1.15, 1.15), 0.075) \
			.set_ease(Tween.EASE_OUT)
		_score_tween.tween_property(score_label, "scale",
			Vector2.ONE, 0.075) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		# Gold color flash
		if _color_flash_tween and _color_flash_tween.is_valid():
			_color_flash_tween.kill()
		_color_flash_tween = create_tween()
		score_label.add_theme_color_override("font_color", Color("#FFD93D"))
		_color_flash_tween.tween_property(score_label, "theme_override_colors/font_color",
			Color.WHITE, 0.3).set_ease(Tween.EASE_OUT)


func _set_score_display(value: int) -> void:
	_displayed_score = value
	score_label.text = _format_number(value)


func _format_number(value: int) -> String:
	var s := str(value)
	if s.length() <= 3:
		return s
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "," + result
	return result


func _check_new_best(current_score: int) -> void:
	if _new_best_shown:
		return
	if _current_high_score <= 0:
		return
	if current_score <= _current_high_score:
		return
	_new_best_shown = true
	_show_new_best_label()


func _show_new_best_label() -> void:
	var score_display := score_label.get_parent()
	if score_display == null:
		return
	_new_best_label = Label.new()
	_new_best_label.text = "NEW BEST!"
	_new_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var fredoka: Font = score_label.get_theme_font("font")
	if fredoka:
		_new_best_label.add_theme_font_override("font", fredoka)
	_new_best_label.add_theme_font_size_override("font_size", 14)
	_new_best_label.add_theme_color_override("font_color", Color("#FFD93D"))
	_new_best_label.modulate.a = 0.7
	_new_best_label.scale = Vector2.ZERO
	score_display.add_child(_new_best_label)

	# Pop-in animation (defer one frame so size is computed for pivot)
	await get_tree().process_frame
	if not is_instance_valid(_new_best_label):
		return
	_new_best_label.pivot_offset = _new_best_label.size / 2.0
	var tw := create_tween()
	tw.tween_property(_new_best_label, "scale", Vector2(1.1, 1.1), 0.12) \
		.set_ease(Tween.EASE_OUT)
	tw.tween_property(_new_best_label, "scale", Vector2.ONE, 0.08) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Start pulse loop after pop-in
	tw.tween_callback(_start_new_best_pulse)


func _start_new_best_pulse() -> void:
	if not is_instance_valid(_new_best_label):
		return
	var pulse := create_tween().set_loops()
	pulse.tween_property(_new_best_label, "modulate:a", 1.0, 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_new_best_label, "modulate:a", 0.7, 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func reset_new_best() -> void:
	_new_best_shown = false
	if is_instance_valid(_new_best_label):
		_new_best_label.queue_free()
		_new_best_label = null


func _update_combo(combo: int) -> void:
	# Combo display is handled by the full-screen overlay popup in combo_popup.gd
	_prev_combo = combo
