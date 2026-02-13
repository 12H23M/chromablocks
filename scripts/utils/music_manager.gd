extends Node

const MUSIC_VOLUME_DB := -12.0
const FADE_DURATION := 1.0

var _player: AudioStreamPlayer
var _bgm: AudioStreamWAV
var _fade_tween: Tween

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = MUSIC_VOLUME_DB
	_player.bus = "Master"
	add_child(_player)

	# Generate BGM in background thread would be ideal,
	# but for simplicity generate on ready (takes ~100ms on mobile)
	_bgm = MusicGenerator.generate_bgm()
	_player.stream = _bgm

	# Auto-start if music is enabled
	if SaveManager.is_music_enabled():
		_player.play()


func play() -> void:
	if _player.playing:
		return
	_player.volume_db = MUSIC_VOLUME_DB
	_player.play()


func stop() -> void:
	_player.stop()


func fade_in() -> void:
	if _player.playing:
		return
	_kill_tween()
	_player.volume_db = -60.0
	_player.play()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_player, "volume_db", MUSIC_VOLUME_DB, FADE_DURATION)


func fade_out() -> void:
	if not _player.playing:
		return
	_kill_tween()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_player, "volume_db", -60.0, FADE_DURATION)
	_fade_tween.tween_callback(_player.stop)


func set_enabled(enabled: bool) -> void:
	SaveManager.set_music_enabled(enabled)
	if enabled:
		fade_in()
	else:
		fade_out()


func is_playing() -> bool:
	return _player.playing


func _kill_tween() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null
