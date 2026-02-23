extends HBoxContainer

@onready var score_label: Label = $ScoreBox/ScoreContent/ScoreValue
@onready var level_label: Label = $LevelBox/LevelContent/LevelValue
@onready var level_progress: ProgressBar = $LevelBox/LevelContent/LevelProgress
@onready var best_label: Label = $BestBox/BestContent/BestValue

var _prev_combo := 0
var _combo_tween: Tween
var _displayed_score: int = 0
var _score_tween: Tween


func _ready() -> void:
	pass  # Combo display moved to full-screen overlay popup


func update_from_state(state: GameState) -> void:
	_animate_score(state.score)
	level_label.text = "%02d" % state.level
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
	# Combo display is handled by the full-screen overlay popup in combo_popup.gd
	_prev_combo = combo
