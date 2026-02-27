extends Control

signal tutorial_finished()

var _steps: Array[Dictionary] = []
var _current_step := 0

@onready var _dimmer: ColorRect = $Dimmer
@onready var _card: PanelContainer = $Card
@onready var _title: Label = $Card/VBox/TopRow/Title
@onready var _body: Label = $Card/VBox/Body
@onready var _hint: Label = $Card/VBox/Hint
@onready var _dots: HBoxContainer = $Card/VBox/Dots
@onready var _progress: Label = $Card/VBox/Progress
@onready var _close_button: Button = $Card/VBox/TopRow/CloseButton


func _ready() -> void:
	_steps = [
		{
			"title": "Drag & Place",
			"body": "Drag pieces from the tray onto the 10x10 board.\nEach piece has a fixed shape and color.",
			"hint": "Pieces cannot overlap or go outside the board.",
		},
		{
			"title": "Clear Lines",
			"body": "Fill an entire row or column to clear it!\nCleared cells free up space for new pieces.",
			"hint": "Try to complete multiple lines at once for bonus points.",
		},
		{
			"title": "Combos & Scoring",
			"body": "Consecutive clears build combos (up to 5x).\nMore lines at once = bigger score!",
			"hint": "High combos = massive score multipliers.",
		},
		{
			"title": "Hold",
			"body": "Tap the Hold slot to save a piece for later.\nSwap it back when you need it!",
			"hint": "You get 1 hold per tray — use it strategically!",
		},
		{
			"title": "Game Over",
			"body": "The game ends when no remaining piece\ncan fit on the board.",
			"hint": "Keep the board clean and plan ahead!",
		},
	]
	visible = false
	_close_button.pressed.connect(_close)


func show_tutorial() -> void:
	_current_step = 0
	_update_step()
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _update_step() -> void:
	var step: Dictionary = _steps[_current_step]
	_title.text = step["title"]
	_body.text = step["body"]
	_hint.text = step["hint"]
	_progress.text = "Tap anywhere to continue  (%d/%d)" % [_current_step + 1, _steps.size()]
	if _current_step == _steps.size() - 1:
		_progress.text = "Tap anywhere to close  (%d/%d)" % [_current_step + 1, _steps.size()]
	_update_dots()

	# Animate card entrance
	_card.pivot_offset = _card.size / 2.0
	_card.scale = Vector2(0.95, 0.95)
	var tween := create_tween()
	tween.tween_property(_card, "scale", Vector2.ONE, 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _update_dots() -> void:
	for child in _dots.get_children():
		child.queue_free()
	for i in _steps.size():
		var dot := Label.new()
		dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dot.add_theme_font_size_override("font_size", 16)
		if i == _current_step:
			dot.text = "●"
			dot.add_theme_color_override("font_color", AppColors.ACCENT)
		else:
			dot.text = "○"
			dot.add_theme_color_override("font_color", AppColors.TEXT_MUTED)
		_dots.add_child(dot)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		accept_event()
		SoundManager.play_sfx("button_press")
		_current_step += 1
		if _current_step >= _steps.size():
			_close()
		else:
			_update_step()


func _close() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func():
		visible = false
		modulate.a = 1.0
		tutorial_finished.emit()
	)
