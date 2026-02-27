extends Control

signal closed()

var _sound_toggle: Button
var _music_toggle: Button
var _track_button: Button
var _haptic_toggle: Button


func _ready() -> void:
	_sound_toggle = $Card/VBox/SoundRow/SoundToggle
	_sound_toggle.set_on(SaveManager.is_sound_enabled(), false)
	_sound_toggle.toggled_value.connect(_on_sound_toggled)

	_music_toggle = $Card/VBox/MusicRow/MusicToggle
	_music_toggle.set_on(SaveManager.is_music_enabled(), false)
	_music_toggle.toggled_value.connect(_on_music_toggled)

	_track_button = $Card/VBox/TrackRow/TrackButton
	_track_button.pressed.connect(_cycle_track)
	_update_track_label()

	_haptic_toggle = $Card/VBox/HapticRow/HapticToggle
	_haptic_toggle.set_on(SaveManager.is_haptic_enabled(), false)
	_haptic_toggle.toggled_value.connect(_on_haptic_toggled)

	$Card/VBox/CloseButton.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		closed.emit())

	$XCloseButton.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		closed.emit())


func _on_sound_toggled(_is_on: bool) -> void:
	SoundManager.play_sfx("button_press")
	SaveManager.set_sound_enabled(_is_on)


func _on_music_toggled(_is_on: bool) -> void:
	SoundManager.play_sfx("button_press")
	MusicManager.set_enabled(_is_on)


func _on_haptic_toggled(_is_on: bool) -> void:
	SoundManager.play_sfx("button_press")
	SaveManager.set_haptic_enabled(_is_on)
	if _is_on:
		Input.vibrate_handheld(30)


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
