extends Control

signal resume_pressed()
signal quit_pressed()

func _ready() -> void:
	$Card/VBox/ResumeButton.pressed.connect(func(): resume_pressed.emit())
	$Card/VBox/QuitButton.pressed.connect(func(): quit_pressed.emit())
