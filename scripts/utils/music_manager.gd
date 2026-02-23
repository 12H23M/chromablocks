extends Node

const MUSIC_VOLUME_DB := -12.0
const FADE_DURATION := 1.0

# WAV 트랙 목록 (프리로드 경로)
const TRACKS: Dictionary = {
	"chroma_dream": "res://assets/music/chroma_dream.wav",
	"neon_pulse": "res://assets/music/neon_pulse.wav",
}
const DEFAULT_TRACK := "chroma_dream"

var _player: AudioStreamPlayer
var _current_track_id: String = DEFAULT_TRACK
var _fade_tween: Tween

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = MUSIC_VOLUME_DB
	_player.bus = "Master"
	add_child(_player)

	# 저장된 트랙 ID (없으면 기본값)
	var saved := SaveManager.get_music_track()
	if TRACKS.has(saved):
		_current_track_id = saved
	else:
		_current_track_id = DEFAULT_TRACK

	# 트랙 로드 & 루프 설정
	var stream := _load_track(_current_track_id)
	if stream:
		_player.stream = stream
		if SaveManager.is_music_enabled():
			_player.play()


func _load_track(track_id: String) -> AudioStreamWAV:
	var path: String = TRACKS.get(track_id, TRACKS[DEFAULT_TRACK])
	var stream = load(path)
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / 2
		return stream
	return null


func play() -> void:
	if _player.playing or not _player.stream:
		return
	_player.volume_db = MUSIC_VOLUME_DB
	_player.play()


func stop() -> void:
	_player.stop()


func fade_in() -> void:
	if _player.playing or not _player.stream:
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


func get_current_track_id() -> String:
	return _current_track_id


func get_track_list() -> Array:
	var result: Array = []
	for tid in TRACKS.keys():
		result.append({"id": tid, "name": tid.replace("_", " ").capitalize()})
	return result


## Switch to a different music track with crossfade
func switch_track(track_id: String) -> void:
	if track_id == _current_track_id:
		return
	if not TRACKS.has(track_id):
		return

	_current_track_id = track_id
	SaveManager.set_music_track(track_id)

	var new_stream := _load_track(track_id)
	if not new_stream:
		return

	var was_playing := _player.playing and SaveManager.is_music_enabled()

	if was_playing:
		_kill_tween()
		_fade_tween = create_tween()
		_fade_tween.tween_property(_player, "volume_db", -60.0, 0.3)
		_fade_tween.tween_callback(func():
			_player.stop()
		)
		_fade_tween.tween_interval(0.05)
		_fade_tween.tween_callback(func():
			_player.stream = new_stream
			_player.volume_db = -60.0
			_player.play()
		)
		_fade_tween.tween_property(_player, "volume_db", MUSIC_VOLUME_DB, 0.5)
	else:
		_player.stop()
		_player.stream = new_stream


func _kill_tween() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null
