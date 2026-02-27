extends Control
## Mission selection overlay — shows 3 pre-rolled missions before starting.

signal start_mission_run(missions: Array)
signal back_pressed()

var _missions: Array = []
var _fredoka_bold: Font = null
var _card_panels: Array = []  # Array[PanelContainer]
var _start_btn: Button

func _ready() -> void:
	_fredoka_bold = load("res://assets/fonts/Fredoka-Bold.ttf") as Font
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_missions = MissionSystem.generate_missions()
	_build_ui()


func _build_ui() -> void:
	# Semi-transparent background
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.04, 0.15, 0.92)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 80)
	margin.add_theme_constant_override("margin_bottom", 60)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set("theme_override_constants/separation", 20)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "MISSION RUN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _fredoka_bold:
		title.add_theme_font_override("font", _fredoka_bold)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#2196F3"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(title)

	# Subtitle
	var sub := Label.new()
	sub.text = "Complete missions for bonus XP!"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color("#8070B0"))
	vbox.add_child(sub)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Mission cards
	var difficulty_labels: Array = ["EASY", "MEDIUM", "HARD"]
	var difficulty_colors: Array = [Color("#4CAF50"), Color("#FF9800"), Color("#F44336")]
	for i in range(3):
		var mission: MissionSystem.Mission = _missions[i]
		var card := _build_mission_card(mission, difficulty_labels[i], difficulty_colors[i])
		_card_panels.append(card)
		vbox.add_child(card)

	# Spacer
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer2)

	# Total XP possible
	var total_xp: int = 0
	for m in _missions:
		var mission: MissionSystem.Mission = m
		total_xp += mission.xp_reward
	var xp_label := Label.new()
	xp_label.text = "Total possible: %d XP" % total_xp
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _fredoka_bold:
		xp_label.add_theme_font_override("font", _fredoka_bold)
	xp_label.add_theme_font_size_override("font_size", 14)
	xp_label.add_theme_color_override("font_color", Color("#FFD93D"))
	vbox.add_child(xp_label)

	# Button row
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.set("theme_override_constants/separation", 16)
	vbox.add_child(btn_row)

	# Back button
	var back_btn := Button.new()
	back_btn.text = "BACK"
	if _fredoka_bold:
		back_btn.add_theme_font_override("font", _fredoka_bold)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.add_theme_color_override("font_color", Color("#C4B5FD"))
	back_btn.custom_minimum_size = Vector2(120, 48)
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = Color("#2A2A5C")
	_r(back_style, 14)
	_b(back_style, 2, Color("#7C3AED"))
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.add_theme_stylebox_override("hover", back_style)
	var back_pressed_style := back_style.duplicate() as StyleBoxFlat
	back_pressed_style.bg_color = Color("#3A3A6C")
	back_btn.add_theme_stylebox_override("pressed", back_pressed_style)
	back_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	back_btn.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		back_pressed.emit())
	btn_row.add_child(back_btn)

	# START button
	_start_btn = Button.new()
	_start_btn.text = "START"
	if _fredoka_bold:
		_start_btn.add_theme_font_override("font", _fredoka_bold)
	_start_btn.add_theme_font_size_override("font_size", 18)
	_start_btn.add_theme_color_override("font_color", Color.WHITE)
	_start_btn.custom_minimum_size = Vector2(160, 48)
	var start_style := StyleBoxFlat.new()
	start_style.bg_color = Color("#2196F3")
	_r(start_style, 14)
	start_style.border_width_bottom = 3
	start_style.border_color = Color("#1565C0")
	start_style.shadow_color = Color(0.13, 0.59, 0.95, 0.3)
	start_style.shadow_size = 6
	_start_btn.add_theme_stylebox_override("normal", start_style)
	_start_btn.add_theme_stylebox_override("hover", start_style)
	var start_pressed_style := start_style.duplicate() as StyleBoxFlat
	start_pressed_style.bg_color = Color("#1976D2")
	start_pressed_style.shadow_size = 2
	_start_btn.add_theme_stylebox_override("pressed", start_pressed_style)
	_start_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_start_btn.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		start_mission_run.emit(_missions))
	btn_row.add_child(_start_btn)

	# Entrance animation
	modulate.a = 0.0
	var tw := create_tween()
	tw.set_speed_scale(1.0 / maxf(Engine.time_scale, 0.01))
	tw.tween_property(self, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)


func _build_mission_card(mission: MissionSystem.Mission, difficulty: String, diff_color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.10, 0.28, 0.9)
	_r(style, 14)
	_b(style, 1, Color(0.3, 0.25, 0.55, 0.5))
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.set("theme_override_constants/separation", 12)
	card.add_child(hbox)

	# Left: difficulty badge + description
	var left := VBoxContainer.new()
	left.set("theme_override_constants/separation", 4)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left)

	var badge := Label.new()
	badge.text = difficulty
	if _fredoka_bold:
		badge.add_theme_font_override("font", _fredoka_bold)
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", diff_color)
	left.add_child(badge)

	var desc := Label.new()
	desc.text = mission.description
	if _fredoka_bold:
		desc.add_theme_font_override("font", _fredoka_bold)
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color.WHITE)
	left.add_child(desc)

	# Right: XP reward
	var xp := Label.new()
	xp.text = "+%d XP" % mission.xp_reward
	if _fredoka_bold:
		xp.add_theme_font_override("font", _fredoka_bold)
	xp.add_theme_font_size_override("font_size", 16)
	xp.add_theme_color_override("font_color", Color("#FFD93D"))
	xp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(xp)

	return card


func _r(s: StyleBoxFlat, r: int) -> void:
	s.corner_radius_top_left = r
	s.corner_radius_top_right = r
	s.corner_radius_bottom_right = r
	s.corner_radius_bottom_left = r

func _b(s: StyleBoxFlat, w: int, c: Color) -> void:
	s.border_width_left = w
	s.border_width_top = w
	s.border_width_right = w
	s.border_width_bottom = w
	s.border_color = c
