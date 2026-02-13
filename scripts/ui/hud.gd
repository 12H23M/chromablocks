extends VBoxContainer

@onready var score_label: Label = $ScoreCardContainer/ScoreCard/CurrentScore
@onready var level_label: Label = $HudRow1/LevelSection/LevelValue
@onready var level_progress: ProgressBar = $HudRow1/LevelSection/LevelProgress
@onready var best_label: Label = $HudRow1/ScoreSection/BestValue

var _prev_combo := 0
var _combo_label: Label
var _combo_tween: Tween
var _displayed_score: int = 0
var _score_tween: Tween


func _ready() -> void:
	_combo_label = Label.new()
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.add_theme_font_size_override("font_size", 18)
	_combo_label.add_theme_color_override("font_color", AppColors.SKY)
	_combo_label.modulate.a = 0.0
	add_child(_combo_label)
	move_child(_combo_label, get_child_count() - 1)


func update_from_state(state: GameState) -> void:
	_animate_score(state.score)
	level_label.text = "Level %02d" % state.level
	best_label.text = str(state.high_score)
	_update_combo(state.combo)
	_update_level_progress(state.lines_cleared, state.level)


func _update_level_progress(lines_cleared: int, current_level: int) -> void:
	# Sum lines needed to reach current level
	var lines_at_current := 0
	for lv in range(1, current_level):
		lines_at_current += GameConstants.lines_for_next_level(lv)
	# Lines needed to advance from current level
	var lines_to_next := GameConstants.lines_for_next_level(current_level)
	var progress := lines_cleared - lines_at_current
	if lines_to_next > 0:
		level_progress.value = clampf(float(progress) / float(lines_to_next) * 100.0, 0.0, 100.0)
	else:
		level_progress.value = 0.0


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

	# Scale bounce when score increases
	if score_increased:
		score_label.pivot_offset = score_label.size / 2.0
		_score_tween.parallel().tween_property(score_label, "scale",
			Vector2(1.15, 1.15), 0.075) \
			.set_ease(Tween.EASE_OUT)
		_score_tween.tween_property(score_label, "scale",
			Vector2.ONE, 0.075) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _set_score_display(value: int) -> void:
	_displayed_score = value
	score_label.text = str(value)


func _update_combo(combo: int) -> void:
	if combo == _prev_combo:
		return

	if _combo_tween and _combo_tween.is_valid():
		_combo_tween.kill()

	if combo >= 2:
		# Update text and color
		_combo_label.text = "COMBO x%d" % combo
		_combo_label.add_theme_color_override("font_color", _combo_color(combo))

		# Animate in with scale bounce
		_combo_tween = create_tween()
		_combo_label.pivot_offset = _combo_label.size / 2.0
		_combo_label.scale = Vector2(1.4, 1.4)
		_combo_label.modulate.a = 1.0
		_combo_tween.tween_property(_combo_label, "scale", Vector2.ONE, 0.25) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	elif _prev_combo >= 2:
		# Combo dropped to 0 — fade out
		_combo_tween = create_tween()
		_combo_tween.tween_property(_combo_label, "modulate:a", 0.0, 0.3) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	_prev_combo = combo


func _combo_color(combo: int) -> Color:
	match combo:
		2: return AppColors.SKY
		3: return AppColors.AMBER
		4: return AppColors.CORAL
		_: return AppColors.SPECIAL  # 5+
