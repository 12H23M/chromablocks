extends Node

const MASTER_VOLUME_DB := -6.0

# Dedicated player per sound — stream is set once and never changed,
# eliminating the audio-thread race condition that occurred when rotating
# a shared pool and swapping the stream property mid-playback.
var _sfx_players: Dictionary = {}   # sfx_name -> AudioStreamPlayer
var _combo_players: Dictionary = {}  # level (int) -> AudioStreamPlayer
var _sfx_ready := false
var _gen_thread: Thread

func _ready() -> void:
	# Create players on main thread (no stream yet — assigned after bg synthesis)
	for sfx_name in ["block_place", "line_clear", "color_match", "level_up",
			"game_over", "perfect_clear", "button_press", "place_fail"]:
		_sfx_players[sfx_name] = _create_empty_player()
	for level in range(1, 8):
		_combo_players[level] = _create_empty_player()

	# Synthesize all SFX in a background thread
	_gen_thread = Thread.new()
	_gen_thread.start(_generate_all_sfx)


func _create_empty_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.volume_db = MASTER_VOLUME_DB
	add_child(player)
	return player


func _generate_all_sfx() -> void:
	var sfx_streams := {
		"block_place": SFXGenerator.generate_block_place(),
		"line_clear": SFXGenerator.generate_line_clear(),
		"color_match": SFXGenerator.generate_color_match(),
		"level_up": SFXGenerator.generate_level_up(),
		"game_over": SFXGenerator.generate_game_over(),
		"perfect_clear": SFXGenerator.generate_perfect_clear(),
		"button_press": SFXGenerator.generate_button_press(),
		"place_fail": SFXGenerator.generate_place_fail(),
	}
	var combo_streams := {}
	for level in range(1, 8):
		combo_streams[level] = SFXGenerator.generate_combo_clear(level)
	call_deferred("_apply_sfx_streams", sfx_streams, combo_streams)


func _apply_sfx_streams(sfx_streams: Dictionary, combo_streams: Dictionary) -> void:
	for sfx_name in sfx_streams:
		_sfx_players[sfx_name].stream = sfx_streams[sfx_name]
	for level in combo_streams:
		_combo_players[level].stream = combo_streams[level]
	_sfx_ready = true


func play_sfx(sfx_name: String) -> void:
	if not _sfx_ready:
		return
	if not SaveManager.is_sound_enabled():
		return
	if not _sfx_players.has(sfx_name):
		return
	# play() restarts from beginning — safe because stream never changes
	_sfx_players[sfx_name].play()


func play_combo_sfx(combo: int) -> void:
	if not _sfx_ready:
		return
	if not SaveManager.is_sound_enabled():
		return
	var level := clampi(combo, 1, 7)
	_combo_players[level].play()


func _exit_tree() -> void:
	if _gen_thread and _gen_thread.is_started():
		_gen_thread.wait_to_finish()
