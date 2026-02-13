extends Control

signal play_again_pressed()
signal go_home_pressed()
signal continue_ad_pressed()
signal double_score_ad_pressed()

@onready var final_score: Label = $Content/ScoreCard/CardVBox/FinalScoreValue
@onready var new_best_badge: PanelContainer = $Content/ScoreCard/CardVBox/NewBestBadge
@onready var lines_value: Label = $Content/ScoreCard/CardVBox/Stats/LinesBox/LinesValue
@onready var blocks_value: Label = $Content/ScoreCard/CardVBox/Stats/BlocksBox/BlocksValue
@onready var combos_value: Label = $Content/ScoreCard/CardVBox/Stats/CombosBox/CombosValue

var _continue_btn: Button
var _double_btn: Button
var _used_ad_this_game := false


func _ready() -> void:
	$Content/ButtonSection/PlayAgainButton.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		play_again_pressed.emit())
	$Content/ButtonSection/HomeButton.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		go_home_pressed.emit())

	# Rewarded ad buttons (created dynamically)
	_continue_btn = $Content/AdSection/ContinueAdButton
	_double_btn = $Content/AdSection/DoubleScoreAdButton
	_continue_btn.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		continue_ad_pressed.emit())
	_double_btn.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		double_score_ad_pressed.emit())


func show_result(state: GameState) -> void:
	# Set data before animation (score starts at 0 for counting effect)
	final_score.text = "0"
	new_best_badge.visible = state.score > state.high_score and state.score > 0
	lines_value.text = str(state.lines_cleared)
	blocks_value.text = str(state.blocks_placed)
	combos_value.text = str(state.max_combo)

	# Show/hide ad buttons (1 use per game)
	var show_ads := not _used_ad_this_game and AdManager.is_rewarded_available()
	_continue_btn.visible = show_ads
	_double_btn.visible = show_ads

	# Entrance animation: fade in overlay + slide up content
	modulate.a = 0.0
	visible = true
	var content := $Content
	var original_y: float = content.position.y
	content.position.y += 30

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25) \
		 .set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(content, "position:y", original_y, 0.3) \
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Score counting animation after entrance
	if state.score > 0:
		var target_score := state.score
		var count_tween := create_tween()
		count_tween.tween_method(func(value: int) -> void:
			final_score.text = FormatUtils.format_number(value)
		, 0, target_score, 0.8).set_ease(Tween.EASE_OUT).set_delay(0.3)


func mark_ad_used() -> void:
	_used_ad_this_game = true
	_continue_btn.visible = false
	_double_btn.visible = false


func reset_ad_state() -> void:
	_used_ad_this_game = false
