extends Node

const SAVE_PATH := "user://chromablocks.cfg"

var _config := ConfigFile.new()

func _ready() -> void:
	_config.load(SAVE_PATH)

func get_high_score() -> int:
	return _config.get_value("game", "high_score", 0)

func save_high_score(score: int) -> void:
	var current := get_high_score()
	if score > current:
		_config.set_value("game", "high_score", score)
		_config.save(SAVE_PATH)

func get_games_played() -> int:
	return _config.get_value("game", "games_played", 0)

func increment_games_played() -> void:
	var count := get_games_played() + 1
	_config.set_value("game", "games_played", count)
	_config.save(SAVE_PATH)

func add_score(score: int) -> void:
	var total: int = int(_config.get_value("game", "total_score", 0)) + score
	_config.set_value("game", "total_score", total)
	_config.save(SAVE_PATH)

func get_avg_score() -> int:
	var games := get_games_played()
	if games <= 0:
		return 0
	var total: int = int(_config.get_value("game", "total_score", 0))
	return roundi(float(total) / float(games))

func is_sound_enabled() -> bool:
	return _config.get_value("settings", "sound", true)

func set_sound_enabled(enabled: bool) -> void:
	_config.set_value("settings", "sound", enabled)
	_config.save(SAVE_PATH)
