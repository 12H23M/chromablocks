extends Control

signal play_again_pressed()
signal go_home_pressed()

@onready var final_score: Label = $Content/ScoreCard/CardVBox/FinalScoreValue
@onready var new_best_badge: PanelContainer = $Content/ScoreCard/CardVBox/NewBestBadge
@onready var lines_value: Label = $Content/ScoreCard/CardVBox/Stats/LinesBox/LinesValue
@onready var blocks_value: Label = $Content/ScoreCard/CardVBox/Stats/BlocksBox/BlocksValue
@onready var combos_value: Label = $Content/ScoreCard/CardVBox/Stats/CombosBox/CombosValue

func _ready() -> void:
	$Content/ButtonSection/PlayAgainButton.pressed.connect(func(): play_again_pressed.emit())
	$Content/ButtonSection/HomeButton.pressed.connect(func(): go_home_pressed.emit())

func show_result(state: GameState) -> void:
	visible = true
	final_score.text = _format_number(state.score)
	new_best_badge.visible = state.score > state.high_score and state.score > 0
	lines_value.text = str(state.lines_cleared)
	blocks_value.text = str(state.blocks_placed)
	combos_value.text = str(state.max_combo)

func _format_number(value: int) -> String:
	if value >= 1000:
		var s := str(value)
		var result := ""
		var count := 0
		for i in range(s.length() - 1, -1, -1):
			if count > 0 and count % 3 == 0:
				result = "," + result
			result = s[i] + result
			count += 1
		return result
	return str(value)
