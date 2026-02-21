extends Node

const MUSIC_VOLUME_DB := -12.0
const FADE_DURATION := 1.0

var _player: AudioStreamPlayer
var _current_track_id: String = "classic"
var _fade_tween: Tween
var _cache: Dictionary = {}  # track_id -> AudioStreamWAV
var _gen_thread: Thread
var _mutex := Mutex.new()  # Protects _cache from concurrent thread access

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = MUSIC_VOLUME_DB
	_player.bus = "Master"
	add_child(_player)

	_current_track_id = SaveManager.get_music_track()

	# Generate all tracks in a background thread (current track first)
	_gen_thread = Thread.new()
	_gen_thread.start(_generate_all_tracks.bind(_current_track_id))


## Background thread: generate current track first, then remaining
func _generate_all_tracks(first_track_id: String) -> void:
	# Generate the selected track first so playback can start ASAP
	var first_stream := MusicGenerator.generate_track(first_track_id)
	_mutex.lock()
	_cache[first_track_id] = first_stream
	_mutex.unlock()

	# Begin playback on main thread as soon as the first track is ready
	call_deferred("_on_first_track_ready", first_stream)

	# Pre-generate remaining tracks
	for track in MusicGenerator.get_track_list():
		var tid: String = track["id"]
		if tid == first_track_id:
			continue
		var stream := MusicGenerator.generate_track(tid)
		_mutex.lock()
		_cache[tid] = stream
		_mutex.unlock()


func _on_first_track_ready(stream: AudioStreamWAV) -> void:
	_player.stream = stream
	if SaveManager.is_music_enabled():
		_player.play()


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


## Switch to a different music track with crossfade transition
func switch_track(track_id: String) -> void:
	if track_id == _current_track_id:
		return
	_current_track_id = track_id
	SaveManager.set_music_track(track_id)

	# Use cached stream or generate on-demand as fallback
	var new_stream: AudioStreamWAV
	_mutex.lock()
	var has_cached := _cache.has(track_id)
	if has_cached:
		new_stream = _cache[track_id]
	_mutex.unlock()
	if not has_cached:
		new_stream = MusicGenerator.generate_track(track_id)
		_mutex.lock()
		_cache[track_id] = new_stream
		_mutex.unlock()

	var was_playing := _player.playing and SaveManager.is_music_enabled()

	if was_playing:
		_kill_tween()
		_fade_tween = create_tween()
		_fade_tween.tween_property(_player, "volume_db", -60.0, 0.3)
		# Stop playback first, then wait a frame for audio thread to finish
		_fade_tween.tween_callback(func():
			_player.stop()
		)
		# Brief pause to let audio thread release the old stream
		_fade_tween.tween_interval(0.05)
		# Now safe to set new stream and play
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


func _exit_tree() -> void:
	if _gen_thread and _gen_thread.is_started():
		_gen_thread.wait_to_finish()
