extends Control

signal closed()

var _sound_toggle: Button
var _music_toggle: Button
var _track_button: Button
var _haptic_toggle: Button


func _ready() -> void:
	_sound_toggle = $Card/VBox/SoundRow/SoundToggle
	_sound_toggle.pressed.connect(_toggle_sound)
	_update_sound_label()

	_music_toggle = $Card/VBox/MusicRow/MusicToggle
	_music_toggle.pressed.connect(_toggle_music)
	_update_music_label()

	_track_button = $Card/VBox/TrackRow/TrackButton
	_track_button.pressed.connect(_cycle_track)
	_update_track_label()

	_haptic_toggle = $Card/VBox/HapticRow/HapticToggle
	_haptic_toggle.pressed.connect(_toggle_haptic)
	_update_haptic_label()

	$Card/VBox/CloseButton.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		closed.emit())

	$XCloseButton.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		closed.emit())


func _toggle_sound() -> void:
	SoundManager.play_sfx("button_press")
	SaveManager.set_sound_enabled(not SaveManager.is_sound_enabled())
	_update_sound_label()


func _toggle_music() -> void:
	SoundManager.play_sfx("button_press")
	MusicManager.set_enabled(not SaveManager.is_music_enabled())
	_update_music_label()


func _toggle_haptic() -> void:
	SoundManager.play_sfx("button_press")
	var new_state := not SaveManager.is_haptic_enabled()
	SaveManager.set_haptic_enabled(new_state)
	_update_haptic_label()
	if new_state:
		Input.vibrate_handheld(30)


func _update_sound_label() -> void:
	_sound_toggle.text = "ON" if SaveManager.is_sound_enabled() else "OFF"


func _update_music_label() -> void:
	_music_toggle.text = "ON" if SaveManager.is_music_enabled() else "OFF"


func _cycle_track() -> void:
	SoundManager.play_sfx("button_press")
	var tracks := MusicManager.get_track_list()
	var current_id := MusicManager.get_current_track_id()
	var current_idx := 0
	for i in tracks.size():
		if tracks[i]["id"] == current_id:
			current_idx = i
			break
	var next_idx := (current_idx + 1) % tracks.size()
	var next_id: String = tracks[next_idx]["id"]
	MusicManager.switch_track(next_id)
	_update_track_label()


func _update_track_label() -> void:
	var tracks := MusicManager.get_track_list()
	var current_id := MusicManager.get_current_track_id()
	for track in tracks:
		if track["id"] == current_id:
			_track_button.text = track["name"]
			return
	_track_button.text = "Chroma Dream"


func _update_haptic_label() -> void:
	_haptic_toggle.text = "ON" if SaveManager.is_haptic_enabled() else "OFF"
