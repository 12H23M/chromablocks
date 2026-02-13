extends Control

signal resume_pressed()
signal quit_pressed()

@onready var sound_toggle: Button = $Card/VBox/SoundRow/SoundToggle
@onready var haptic_toggle: Button = $Card/VBox/HapticRow/HapticToggle

func _ready() -> void:
	$Card/VBox/ResumeButton.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		resume_pressed.emit())
	$Card/VBox/QuitButton.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		quit_pressed.emit())
	sound_toggle.pressed.connect(_toggle_sound)
	haptic_toggle.pressed.connect(_toggle_haptic)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		_update_sound_label()
		_update_haptic_label()

func _toggle_sound() -> void:
	SoundManager.play_sfx("button_press")
	var enabled := not SaveManager.is_sound_enabled()
	SaveManager.set_sound_enabled(enabled)
	_update_sound_label()

func _toggle_haptic() -> void:
	SoundManager.play_sfx("button_press")
	var enabled := not SaveManager.is_haptic_enabled()
	SaveManager.set_haptic_enabled(enabled)
	_update_haptic_label()
	if enabled:
		HapticManager.light()

func _update_sound_label() -> void:
	sound_toggle.text = "ON" if SaveManager.is_sound_enabled() else "OFF"
	var color := Color(0.176, 0.831, 0.749, 1) if SaveManager.is_sound_enabled() else Color(0.42, 0.541, 0.62, 1)
	sound_toggle.add_theme_color_override("font_color", color)

func _update_haptic_label() -> void:
	haptic_toggle.text = "ON" if SaveManager.is_haptic_enabled() else "OFF"
	var color := Color(0.176, 0.831, 0.749, 1) if SaveManager.is_haptic_enabled() else Color(0.42, 0.541, 0.62, 1)
	haptic_toggle.add_theme_color_override("font_color", color)
