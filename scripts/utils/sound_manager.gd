extends Node

const MASTER_VOLUME_DB := -6.0

# Per-sound volume levels — frequent sounds quieter, reward sounds louder
const SFX_VOLUMES: Dictionary = {
	"block_place": -14.0,
	"button_press": -16.0,
	"place_fail": -10.0,
	"color_match": -9.0,
	"level_up": -4.0,
	"game_over": -8.0,
	"perfect_clear": -3.0,
}
const COMBO_VOLUMES: Array = [
	-8.0,   # x1
	-8.0,   # x2
	-6.0,   # x3
	-4.0,   # x4
	-3.0,   # x5
	-3.0,   # x6
	-3.0,   # x7
]
const LINE_CLEAR_VOLUMES: Array = [
	-8.0,   # 1 line
	-6.0,   # 2 lines
	-4.0,   # 3 lines
	-3.0,   # 4 lines
]
const CHAIN_VOLUME := -7.0
const BLAST_VOLUME := -3.0

# Dedicated player per sound — stream is set once and never changed,
# eliminating the audio-thread race condition that occurred when rotating
# a shared pool and swapping the stream property mid-playback.
var _sfx_players: Dictionary = {}   # sfx_name -> AudioStreamPlayer
var _combo_players: Dictionary = {}  # level (int) -> AudioStreamPlayer
var _chain_players: Dictionary = {}  # cascade level (int) -> AudioStreamPlayer
var _line_clear_players: Dictionary = {}  # line count (int) -> AudioStreamPlayer
var _blast_player: AudioStreamPlayer
var _sfx_ready := false
var _gen_thread: Thread

func _ready() -> void:
	# Create players on main thread (no stream yet — assigned after bg synthesis)
	for sfx_name in ["block_place", "color_match", "level_up",
			"game_over", "perfect_clear", "button_press", "place_fail"]:
		_sfx_players[sfx_name] = _create_empty_player()
	for level in range(1, 8):
		_combo_players[level] = _create_empty_player()
	for level in range(1, 4):
		_chain_players[level] = _create_empty_player()
	for lines in range(1, 5):
		_line_clear_players[lines] = _create_empty_player()
	_blast_player = _create_empty_player()

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
	var chain_streams := {}
	for level in range(1, 4):
		chain_streams[level] = SFXGenerator.generate_chain_sound(level)
	var line_clear_streams := {}
	for lines in range(1, 5):
		line_clear_streams[lines] = SFXGenerator.generate_line_clear(lines)
	var blast_stream := SFXGenerator.generate_blast_sound()
	call_deferred("_apply_sfx_streams", sfx_streams, combo_streams, chain_streams, line_clear_streams, blast_stream)


func _apply_sfx_streams(sfx_streams: Dictionary, combo_streams: Dictionary, chain_streams: Dictionary = {}, line_clear_streams: Dictionary = {}, blast_stream: AudioStreamWAV = null) -> void:
	for sfx_name in sfx_streams:
		_sfx_players[sfx_name].stream = sfx_streams[sfx_name]
		if SFX_VOLUMES.has(sfx_name):
			_sfx_players[sfx_name].volume_db = SFX_VOLUMES[sfx_name]
	for level in combo_streams:
		_combo_players[level].stream = combo_streams[level]
		var idx: int = clampi(level - 1, 0, COMBO_VOLUMES.size() - 1)
		_combo_players[level].volume_db = COMBO_VOLUMES[idx]
	for level in chain_streams:
		_chain_players[level].stream = chain_streams[level]
		_chain_players[level].volume_db = CHAIN_VOLUME
	for lines in line_clear_streams:
		_line_clear_players[lines].stream = line_clear_streams[lines]
		var idx: int = clampi(lines - 1, 0, LINE_CLEAR_VOLUMES.size() - 1)
		_line_clear_players[lines].volume_db = LINE_CLEAR_VOLUMES[idx]
	if blast_stream:
		_blast_player.stream = blast_stream
		_blast_player.volume_db = BLAST_VOLUME
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


func play_line_clear_sfx(line_count: int) -> void:
	if not _sfx_ready:
		return
	if not SaveManager.is_sound_enabled():
		return
	var lines := clampi(line_count, 1, 4)
	_line_clear_players[lines].play()


func play_combo_sfx(combo: int) -> void:
	if not _sfx_ready:
		return
	if not SaveManager.is_sound_enabled():
		return
	var level := clampi(combo, 1, 7)
	# Apply sequential pitch-up: x2=1.0, x3=1.1, x4=1.2, ...
	var pitch: float = 1.0 + maxf(0.0, float(combo - 2)) * 0.1
	_combo_players[level].pitch_scale = clampf(pitch, 1.0, 2.0)
	_combo_players[level].play()


## Play combo sound with explicit combo_level pitch scaling.
## combo_level: 2=x2, 3=x3, etc. Pitch: 1.0, 1.1, 1.2, 1.3...
func play_combo_sound(combo_level: int) -> void:
	play_combo_sfx(combo_level)


func play_chain_sound(cascade_level: int) -> void:
	if not _sfx_ready:
		return
	if not SaveManager.is_sound_enabled():
		return
	var level := clampi(cascade_level, 1, 3)
	_chain_players[level].play()


func play_blast_sound() -> void:
	if not _sfx_ready:
		return
	if not SaveManager.is_sound_enabled():
		return
	_blast_player.play()


func _exit_tree() -> void:
	if _gen_thread and _gen_thread.is_started():
		_gen_thread.wait_to_finish()
