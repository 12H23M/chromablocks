extends VBoxContainer

@onready var score_label: Label = $ScoreCardContainer/ScoreCard/CurrentScore
@onready var level_label: Label = $HudRow1/LevelSection/LevelValue
@onready var best_label: Label = $HudRow1/ScoreSection/BestValue

func update_from_state(state: GameState) -> void:
	score_label.text = str(state.score)
	level_label.text = "Level %02d" % state.level
	best_label.text = str(state.high_score)
