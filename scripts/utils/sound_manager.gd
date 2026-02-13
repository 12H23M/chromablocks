extends Node

const POOL_SIZE := 4
const MASTER_VOLUME_DB := -6.0

var _players: Array = []
var _sounds: Dictionary = {}
var _combo_sounds: Dictionary = {}
var _next_player := 0

func _ready() -> void:
	# Pool of players so overlapping sounds don't cut each other off
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.volume_db = MASTER_VOLUME_DB
		add_child(player)
		_players.append(player)

	_sounds["block_place"] = SFXGenerator.generate_block_place()
	_sounds["line_clear"] = SFXGenerator.generate_line_clear()
	_sounds["color_match"] = SFXGenerator.generate_color_match()
	_sounds["level_up"] = SFXGenerator.generate_level_up()
	_sounds["game_over"] = SFXGenerator.generate_game_over()
	_sounds["perfect_clear"] = SFXGenerator.generate_perfect_clear()
	_sounds["button_press"] = SFXGenerator.generate_button_press()
	_sounds["place_fail"] = SFXGenerator.generate_place_fail()

	# Pre-cache combo pitch-escalation sounds (levels 1–7)
	for level in range(1, 8):
		_combo_sounds[level] = SFXGenerator.generate_combo_clear(level)

func play_sfx(sfx_name: String) -> void:
	if not SaveManager.is_sound_enabled():
		return
	if not _sounds.has(sfx_name):
		return

	var player: AudioStreamPlayer = _players[_next_player]
	player.stream = _sounds[sfx_name]
	player.play()
	_next_player = (_next_player + 1) % POOL_SIZE

func play_combo_sfx(combo: int) -> void:
	if not SaveManager.is_sound_enabled():
		return
	var level := clampi(combo, 1, 7)
	var player: AudioStreamPlayer = _players[_next_player]
	player.stream = _combo_sounds[level]
	player.play()
	_next_player = (_next_player + 1) % POOL_SIZE
