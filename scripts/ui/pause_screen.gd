extends Control

signal resume_pressed()
signal quit_pressed()

@onready var sound_toggle: Control = $Card/VBox/SoundRow/SoundToggle
@onready var haptic_toggle: Control = $Card/VBox/HapticRow/HapticToggle

func _ready() -> void:
	$Card/VBox/ResumeButton.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		resume_pressed.emit())
	$Card/VBox/QuitButton.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		quit_pressed.emit())
	sound_toggle.toggled.connect(_on_sound_toggled)
	haptic_toggle.toggled.connect(_on_haptic_toggled)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		sound_toggle.set_on(SaveManager.is_sound_enabled(), false)
		haptic_toggle.set_on(SaveManager.is_haptic_enabled(), false)

func _on_sound_toggled(_is_on: bool) -> void:
	SoundManager.play_sfx("button_press")
	SaveManager.set_sound_enabled(_is_on)
	MusicManager.set_enabled(_is_on)

func _on_haptic_toggled(_is_on: bool) -> void:
	SoundManager.play_sfx("button_press")
	SaveManager.set_haptic_enabled(_is_on)
	if _is_on:
		HapticManager.light()
