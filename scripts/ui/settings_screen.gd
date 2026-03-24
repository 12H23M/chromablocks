extends Control

signal closed()

var _sound_toggle: Button
var _music_toggle: Button
var _track_button: Button
var _haptic_toggle: Button
var _autoplay_toggle: Button


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

	# Auto-play toggle (dynamically created if row doesn't exist in scene)
	var autoplay_row := $Card/VBox.get_node_or_null("AutoPlayRow")
	if autoplay_row == null:
		autoplay_row = _create_autoplay_row()
		$Card/VBox.add_child(autoplay_row)
		# Move before CloseButton
		var close_idx := $Card/VBox/CloseButton.get_index()
		$Card/VBox.move_child(autoplay_row, close_idx)

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


func _create_autoplay_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "AutoPlayRow"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "🤖 Auto Play"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 16)
	row.add_child(label)

	var toggle_scene := load("res://scenes/ui/toggle_switch.tscn")
	_autoplay_toggle = toggle_scene.instantiate()
	var game := _get_game_node()
	_autoplay_toggle.set_on(game.is_auto_play() if game else false, false)
	_autoplay_toggle.toggled_value.connect(_on_autoplay_toggled)
	row.add_child(_autoplay_toggle)

	return row


func _on_autoplay_toggled(is_on: bool) -> void:
	SoundManager.play_sfx("button_press")
	var game := _get_game_node()
	if game:
		game.set_auto_play(is_on)


func _get_game_node() -> Node:
	# Walk up the tree to find the game node
	var node := get_parent()
	while node:
		if node.has_method("set_auto_play"):
			return node
		node = node.get_parent()
	return null
