extends Control

signal start_pressed()

@onready var start_button: Button = $VBox/ButtonSection/StartButton
@onready var sound_toggle: Button = $VBox/BottomRow/SoundToggle
@onready var best_value: Label = $VBox/StatsSection/BestStat/BestValue
@onready var games_value: Label = $VBox/StatsSection/GamesStat/GamesValue
@onready var avg_value: Label = $VBox/StatsSection/AvgStat/AvgValue

func _ready() -> void:
	start_button.pressed.connect(func(): start_pressed.emit())
	sound_toggle.pressed.connect(_toggle_sound)
	refresh_stats()
	_update_sound_label()

func refresh_stats() -> void:
	best_value.text = _format_number(SaveManager.get_high_score())
	games_value.text = str(SaveManager.get_games_played())
	avg_value.text = _format_number(SaveManager.get_avg_score())

func _toggle_sound() -> void:
	var enabled := not SaveManager.is_sound_enabled()
	SaveManager.set_sound_enabled(enabled)
	_update_sound_label()

func _update_sound_label() -> void:
	sound_toggle.text = "♪" if SaveManager.is_sound_enabled() else "✕"

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
