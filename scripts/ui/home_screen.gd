extends Control

signal start_pressed()
signal continue_pressed()
signal daily_pressed()
signal settings_pressed()
signal how_to_play_pressed()

# ─── Node references (created in _build_ui) ───
var _bg: ColorRect
var _play_btn: Button
var _continue_btn: Button
var _daily_btn: Button
var _howto_btn: Button
var _sound_btn: Button
var _settings_btn: Button
var _best_value: Label
var _games_value: Label
var _avg_value: Label
var _daily_desc: Label
var _fire_badge: Label

# ─── Animation state ───
var _sparkles: Array = []
var _deco_blocks: Array = []
var _logo_blocks: Array = []
var _play_glow_tween: Tween

# ─── Colors ───
const BG_COLOR := Color("#110d30")
const BG_LIGHTER := Color("#1a1145")
const BLOCK_COLORS := [
	[Color("#FF9EAA"), Color("#FF6E80")],  # Coral
	[Color("#FFC060"), Color("#FF9A30")],  # Amber
	[Color("#FFE060"), Color("#FFCC20")],  # Lemon
	[Color("#7EDB95"), Color("#4EBB6B")],  # Mint
	[Color("#62CCF8"), Color("#32A8E8")],  # Sky
	[Color("#BFA4E8"), Color("#9070D0")],  # Lavender
]
const MINI_BOARD_COLORS := [
	[-1, 0, 0, -1, -1, 4, -1],
	[1, 0, -1, 3, 3, 4, 4],
	[1, 1, 2, 3, -1, -1, 5],
	[5, -1, 2, 2, 5, 5, 5],
]


func _ready() -> void:
	_build_ui()
	_connect_signals()
	_play_entrance_animations()
	refresh_stats()


# ═══════════════════════════════════════
#  UI CONSTRUCTION
# ═══════════════════════════════════════

func _build_ui() -> void:
	# Root setup
	anchor_right = 1.0
	anchor_bottom = 1.0

	# ─── Background ───
	_bg = ColorRect.new()
	_bg.color = BG_COLOR
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	# Glow orbs
	_add_glow_orb(Vector2(320, 40), 220.0, Color(0.26, 0.73, 0.96, 0.1))
	_add_glow_orb(Vector2(-80, 650), 280.0, Color(0.65, 0.55, 0.87, 0.08))
	_add_glow_orb(Vector2(100, 400), 160.0, Color(1.0, 0.49, 0.56, 0.06))

	# Grid overlay
	_add_grid_overlay()

	# Sparkle dots
	_create_sparkles()

	# Floating decoration blocks
	_create_deco_blocks()

	# ─── Main container ───
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.set("theme_override_constants/separation", 0)
	add_child(main_vbox)

	# Top padding
	var top_pad := Control.new()
	top_pad.custom_minimum_size = Vector2(0, 44)
	main_vbox.add_child(top_pad)

	# Logo section
	var logo_section := _build_logo_section()
	main_vbox.add_child(logo_section)

	# Mini board
	var board_section := _build_mini_board()
	main_vbox.add_child(board_section)

	# Spacer
	var sp1 := Control.new()
	sp1.custom_minimum_size = Vector2(0, 18)
	main_vbox.add_child(sp1)

	# Buttons
	var btn_section := _build_buttons()
	main_vbox.add_child(btn_section)

	# Flexible spacer
	var flex := Control.new()
	flex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(flex)

	# Stats
	var stats_section := _build_stats()
	main_vbox.add_child(stats_section)

	# Bottom bar
	var bottom := _build_bottom_bar()
	main_vbox.add_child(bottom)

	# Bottom padding
	var bot_pad := Control.new()
	bot_pad.custom_minimum_size = Vector2(0, 28)
	main_vbox.add_child(bot_pad)


func _build_logo_section() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set("theme_override_constants/separation", 0)

	# Star sparkle
	var star := Label.new()
	star.text = "✦"
	star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star.add_theme_font_size_override("font_size", 24)
	star.add_theme_color_override("font_color", Color(1, 0.84, 0, 0.8))
	star.name = "LogoStar"
	vbox.add_child(star)

	# Logo blocks row
	var block_row := HBoxContainer.new()
	block_row.alignment = BoxContainer.ALIGNMENT_CENTER
	block_row.set("theme_override_constants/separation", 5)

	for i in range(6):
		var block := _create_logo_block(i)
		block_row.add_child(block)
		_logo_blocks.append(block)

	vbox.add_child(block_row)

	# Spacer
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(sp)

	# Title
	var title := Label.new()
	title.text = "ChromaBlocks"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.name = "LogoTitle"
	vbox.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "BLOCK  PUZZLE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color("#8B7AB8"))
	vbox.add_child(subtitle)

	return vbox


func _create_logo_block(idx: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(40, 40)

	var style := StyleBoxFlat.new()
	style.bg_color = BLOCK_COLORS[idx][0]
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.border_width_bottom = 5
	style.border_color = BLOCK_COLORS[idx][1].darkened(0.3)
	style.shadow_color = Color(BLOCK_COLORS[idx][0], 0.5)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)

	# Top highlight
	var highlight := ColorRect.new()
	highlight.color = Color(1, 1, 1, 0.25)
	highlight.custom_minimum_size = Vector2(10, 10)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(highlight)

	# Start offscreen for animation
	panel.modulate.a = 0.0
	panel.position.y = -40

	return panel


func _build_mini_board() -> CenterContainer:
	var center := CenterContainer.new()

	var frame := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.08, 0.05, 0.18, 0.9)
	frame_style.corner_radius_top_left = 16
	frame_style.corner_radius_top_right = 16
	frame_style.corner_radius_bottom_right = 16
	frame_style.corner_radius_bottom_left = 16
	frame_style.border_width_left = 2
	frame_style.border_width_top = 2
	frame_style.border_width_right = 2
	frame_style.border_width_bottom = 2
	frame_style.border_color = Color(0.47, 0.39, 0.78, 0.2)
	frame_style.content_margin_left = 12
	frame_style.content_margin_top = 12
	frame_style.content_margin_right = 12
	frame_style.content_margin_bottom = 12
	frame_style.shadow_color = Color(0, 0, 0, 0.4)
	frame_style.shadow_size = 10
	frame.add_theme_stylebox_override("panel", frame_style)

	var grid := GridContainer.new()
	grid.columns = 7
	grid.set("theme_override_constants/h_separation", 3)
	grid.set("theme_override_constants/v_separation", 3)

	for row in range(4):
		for col in range(7):
			var cell_idx: int = MINI_BOARD_COLORS[row][col]
			var cell := PanelContainer.new()
			cell.custom_minimum_size = Vector2(26, 26)

			var cell_style := StyleBoxFlat.new()
			cell_style.corner_radius_top_left = 5
			cell_style.corner_radius_top_right = 5
			cell_style.corner_radius_bottom_right = 5
			cell_style.corner_radius_bottom_left = 5

			if cell_idx >= 0:
				cell_style.bg_color = BLOCK_COLORS[cell_idx][0]
				cell_style.border_width_bottom = 3
				cell_style.border_color = Color(0, 0, 0, 0.3)
				cell_style.shadow_color = Color(BLOCK_COLORS[cell_idx][0], 0.15)
				cell_style.shadow_size = 3
			else:
				cell_style.bg_color = Color(1, 1, 1, 0.03)

			cell.add_theme_stylebox_override("panel", cell_style)
			grid.add_child(cell)

	frame.add_child(grid)
	center.add_child(frame)

	# Start hidden for entrance animation
	frame.modulate.a = 0.0
	frame.scale = Vector2(0.9, 0.9)
	frame.name = "BoardFrame"

	return center


func _build_buttons() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set("theme_override_constants/separation", 12)

	# PLAY button
	_play_btn = _create_game_button(
		"▶  PLAY", 26,
		Color("#6ddb8a"), Color("#28a84c"), Color("#1a7a38"),
		7, 22, 0.88
	)
	_play_btn.name = "PlayButton"
	vbox.add_child(_center_wrap(_play_btn, 0.88))

	# Continue button
	_continue_btn = _create_game_button(
		"↩  Continue", 19,
		Color("#60c8f8"), Color("#2888cc"), Color("#1a6090"),
		6, 18, 0.80
	)
	_continue_btn.name = "ContinueButton"
	vbox.add_child(_center_wrap(_continue_btn, 0.80))

	# Daily Challenge button (with fire badge)
	var daily_wrap := Control.new()
	daily_wrap.custom_minimum_size = Vector2(0, 58)

	_daily_btn = _create_game_button(
		"📅  Daily Challenge", 19,
		Color("#ffc852"), Color("#dd8810"), Color("#a06008"),
		6, 18, 0.80
	)
	_daily_btn.name = "DailyButton"

	# Daily description label
	_daily_desc = Label.new()
	_daily_desc.name = "DailyDesc"
	_daily_desc.text = ""
	_daily_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_daily_desc.add_theme_font_size_override("font_size", 10)
	_daily_desc.add_theme_color_override("font_color", Color("#7B6BA8"))

	var daily_vbox := VBoxContainer.new()
	daily_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	daily_vbox.set("theme_override_constants/separation", 4)
	daily_vbox.add_child(_center_wrap(_daily_btn, 0.80))
	daily_vbox.add_child(_daily_desc)

	# Fire badge
	_fire_badge = Label.new()
	_fire_badge.text = "🔥 7"
	_fire_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fire_badge.add_theme_font_size_override("font_size", 11)
	_fire_badge.add_theme_color_override("font_color", Color.WHITE)
	_fire_badge.name = "FireBadge"

	var badge_panel := PanelContainer.new()
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color("#FF2040")
	badge_style.corner_radius_top_left = 12
	badge_style.corner_radius_top_right = 12
	badge_style.corner_radius_bottom_right = 12
	badge_style.corner_radius_bottom_left = 12
	badge_style.content_margin_left = 8
	badge_style.content_margin_right = 8
	badge_style.content_margin_top = 2
	badge_style.content_margin_bottom = 2
	badge_style.shadow_color = Color(1, 0.2, 0.31, 0.55)
	badge_style.shadow_size = 5
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	badge_panel.add_child(_fire_badge)
	badge_panel.name = "BadgePanel"

	vbox.add_child(daily_vbox)

	# How to Play button
	_howto_btn = Button.new()
	_howto_btn.text = "📖  How to Play"
	_howto_btn.name = "HowToPlayButton"
	_howto_btn.add_theme_font_size_override("font_size", 15)
	_howto_btn.add_theme_color_override("font_color", Color("#b8a6e0"))

	var howto_style := StyleBoxFlat.new()
	howto_style.bg_color = Color(0.65, 0.55, 0.87, 0.12)
	howto_style.corner_radius_top_left = 14
	howto_style.corner_radius_top_right = 14
	howto_style.corner_radius_bottom_right = 14
	howto_style.corner_radius_bottom_left = 14
	howto_style.border_width_left = 1
	howto_style.border_width_top = 1
	howto_style.border_width_right = 1
	howto_style.border_width_bottom = 4
	howto_style.border_color = Color(0.31, 0.22, 0.55, 0.35)
	howto_style.content_margin_left = 20
	howto_style.content_margin_top = 12
	howto_style.content_margin_right = 20
	howto_style.content_margin_bottom = 12
	_howto_btn.add_theme_stylebox_override("normal", howto_style)
	_howto_btn.add_theme_stylebox_override("hover", howto_style)
	_howto_btn.add_theme_stylebox_override("pressed", howto_style)

	vbox.add_child(_center_wrap(_howto_btn, 0.55))

	# Hide for entrance
	for child in vbox.get_children():
		child.modulate.a = 0.0

	return vbox


func _create_game_button(text: String, font_size: int, color_top: Color, color_bot: Color, border_color: Color, border_w: int, radius: int, _width_ratio: float) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color.WHITE)

	var style := StyleBoxFlat.new()
	style.bg_color = color_top.lerp(color_bot, 0.4)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.border_width_bottom = border_w
	style.border_color = border_color
	style.content_margin_left = 28
	style.content_margin_top = 18
	style.content_margin_right = 28
	style.content_margin_bottom = 18
	style.shadow_color = Color(color_top, 0.4)
	style.shadow_size = 12

	# Pressed style — slightly darker + less bottom border
	var pressed_style := style.duplicate()
	pressed_style.bg_color = color_bot
	pressed_style.border_width_bottom = max(border_w - 3, 2)
	pressed_style.shadow_size = 6

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	return btn


func _center_wrap(ctrl: Control, width_ratio: float) -> CenterContainer:
	var center := CenterContainer.new()
	ctrl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ctrl.custom_minimum_size.x = 393.0 * width_ratio
	center.add_child(ctrl)
	return center


func _build_stats() -> MarginContainer:
	var hbox := HBoxContainer.new()
	hbox.set("theme_override_constants/separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var colors := [Color("#FFD536"), Color("#42B9F5"), Color("#5EC97B")]
	var icons := ["🏆", "🎮", "📊"]
	var labels_text := ["BEST", "GAMES", "AVG"]

	_best_value = Label.new()
	_games_value = Label.new()
	_avg_value = Label.new()
	var value_labels := [_best_value, _games_value, _avg_value]

	for i in range(3):
		var card := _build_stat_card(icons[i], value_labels[i], labels_text[i], colors[i])
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(card)

	# Left/right margin
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_child(hbox)

	margin.modulate.a = 0.0
	return margin


func _build_stat_card(icon_text: String, value_label: Label, label_text: String, accent_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()

	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.04)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.border_width_left = 1
	style.border_width_top = 2
	style.border_width_right = 1
	style.border_width_bottom = 3
	style.border_color = Color(1, 1, 1, 0.06)
	style.content_margin_left = 4
	style.content_margin_top = 10
	style.content_margin_right = 4
	style.content_margin_bottom = 10

	# Top accent — use border top with accent color
	style.border_width_top = 2
	style.border_color = accent_color.lerp(Color(1, 1, 1, 0.06), 0.5)

	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set("theme_override_constants/separation", 2)

	var icon := Label.new()
	icon.text = icon_text
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 16)
	vbox.add_child(icon)

	value_label.text = "0"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 20)
	value_label.add_theme_color_override("font_color", accent_color)
	vbox.add_child(value_label)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color("#7060A0"))
	vbox.add_child(lbl)

	panel.add_child(vbox)
	return panel


func _build_bottom_bar() -> CenterContainer:
	var center := CenterContainer.new()

	var hbox := HBoxContainer.new()
	hbox.set("theme_override_constants/separation", 20)

	_sound_btn = Button.new()
	_sound_btn.text = "🔊 Sound"
	_sound_btn.name = "SoundToggle"
	_style_bottom_btn(_sound_btn)

	_settings_btn = Button.new()
	_settings_btn.text = "⚙️ Settings"
	_settings_btn.name = "SettingsButton"
	_style_bottom_btn(_settings_btn)

	hbox.add_child(_sound_btn)
	hbox.add_child(_settings_btn)
	center.add_child(hbox)

	center.modulate.a = 0.0
	return center


func _style_bottom_btn(btn: Button) -> void:
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color("#6B5A98"))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.04)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.border_width_bottom = 2
	style.border_color = Color(0, 0, 0, 0.15)
	style.content_margin_left = 16
	style.content_margin_top = 8
	style.content_margin_right = 16
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


# ═══════════════════════════════════════
#  BACKGROUND DECORATIONS
# ═══════════════════════════════════════

func _add_glow_orb(pos: Vector2, size_val: float, color: Color) -> void:
	var orb := ColorRect.new()
	orb.color = color
	orb.size = Vector2(size_val, size_val)
	orb.position = pos - Vector2(size_val / 2, size_val / 2)
	orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Note: actual blur would need shader; using large soft ColorRect as approximation
	add_child(orb)


func _add_grid_overlay() -> void:
	# Subtle grid lines via multiple thin ColorRects
	for i in range(0, 860, 40):
		var h_line := ColorRect.new()
		h_line.color = Color(0.47, 0.39, 0.78, 0.04)
		h_line.size = Vector2(393, 1)
		h_line.position = Vector2(0, i)
		h_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(h_line)

		var v_line := ColorRect.new()
		v_line.color = Color(0.47, 0.39, 0.78, 0.04)
		v_line.size = Vector2(1, 852)
		v_line.position = Vector2(i if i < 393 else 0, 0)
		v_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if i < 393:
			add_child(v_line)


func _create_sparkles() -> void:
	var positions := [
		Vector2(45, 95), Vector2(338, 200), Vector2(70, 330),
		Vector2(313, 480), Vector2(320, 150), Vector2(40, 570),
		Vector2(343, 620), Vector2(100, 720), Vector2(303, 50), Vector2(273, 760),
	]
	for pos in positions:
		var dot := ColorRect.new()
		dot.color = Color.WHITE
		dot.size = Vector2(3, 3)
		dot.position = pos
		dot.modulate.a = 0.1
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dot)
		_sparkles.append(dot)


func _create_deco_blocks() -> void:
	var configs := [
		{"pos": Vector2(-6, 100), "size": Vector2(36, 36), "color": 0, "rot": 18.0},
		{"pos": Vector2(355, 180), "size": Vector2(24, 24), "color": 4, "rot": -22.0},
		{"pos": Vector2(8, 580), "size": Vector2(44, 18), "color": 2, "rot": 28.0},
		{"pos": Vector2(359, 610), "size": Vector2(18, 44), "color": 3, "rot": -12.0},
		{"pos": Vector2(14, 400), "size": Vector2(20, 20), "color": 5, "rot": 35.0},
		{"pos": Vector2(355, 360), "size": Vector2(28, 28), "color": 1, "rot": -28.0},
	]
	for cfg in configs:
		var block := ColorRect.new()
		block.color = BLOCK_COLORS[cfg["color"]][0]
		block.size = cfg["size"]
		block.position = cfg["pos"]
		block.rotation_degrees = cfg["rot"]
		block.modulate.a = 0.15
		block.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(block)
		_deco_blocks.append(block)


# ═══════════════════════════════════════
#  SIGNALS
# ═══════════════════════════════════════

func _connect_signals() -> void:
	_play_btn.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		start_pressed.emit())
	_continue_btn.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		continue_pressed.emit())
	_daily_btn.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		daily_pressed.emit())
	_howto_btn.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		how_to_play_pressed.emit())
	_sound_btn.pressed.connect(_toggle_sound)
	_settings_btn.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		settings_pressed.emit())


# ═══════════════════════════════════════
#  ANIMATIONS
# ═══════════════════════════════════════

func _play_entrance_animations() -> void:
	# Logo blocks drop in
	for i in range(_logo_blocks.size()):
		var block: PanelContainer = _logo_blocks[i]
		var delay: float = 0.05 + i * 0.07
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_property(block, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(block, "position:y", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Board frame entrance
	var board_frame := _find_child_by_name("BoardFrame")
	if board_frame:
		var bt := create_tween()
		bt.tween_interval(0.8)
		bt.tween_property(board_frame, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
		bt.parallel().tween_property(board_frame, "scale", Vector2.ONE, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Buttons entrance (staggered)
	var btn_section := _play_btn.get_parent().get_parent()  # CenterContainer → VBoxContainer
	if btn_section:
		var parent := btn_section.get_parent()
		if parent:
			var children := parent.get_children()
			var btn_idx := 0
			for child in children:
				if child.modulate.a < 0.5 and child != btn_section:
					continue
				if child is CenterContainer or child is VBoxContainer:
					var delay := 1.0 + btn_idx * 0.15
					var tw := create_tween()
					tw.tween_interval(delay)
					tw.tween_property(child, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
					btn_idx += 1

	# Stats + bottom entrance
	await get_tree().create_timer(1.5).timeout
	for child in get_children():
		if child is MarginContainer and child.modulate.a < 0.5:
			var tw := create_tween()
			tw.tween_property(child, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
		if child is CenterContainer and child.modulate.a < 0.5:
			var tw2 := create_tween()
			tw2.tween_property(child, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)

	# Start idle animations
	_start_idle_animations()


func _start_idle_animations() -> void:
	# Play button glow pulse
	_play_glow_pulse()

	# Sparkle twinkle
	_sparkle_loop()

	# Floating blocks drift
	_deco_float_loop()

	# Star rotation
	_star_sparkle_loop()

	# Fire badge bounce
	_badge_bounce_loop()


func _play_glow_pulse() -> void:
	if not is_inside_tree():
		return
	var style: StyleBoxFlat = _play_btn.get_theme_stylebox("normal")
	if not style:
		return
	_play_glow_tween = create_tween().set_loops()
	_play_glow_tween.tween_property(style, "shadow_size", 20, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_play_glow_tween.tween_property(style, "shadow_size", 8, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _sparkle_loop() -> void:
	for sparkle in _sparkles:
		var delay := randf_range(0.0, 3.0)
		var dur := randf_range(2.0, 4.0)
		var tw := create_tween().set_loops()
		tw.tween_interval(delay)
		tw.tween_property(sparkle, "modulate:a", randf_range(0.5, 0.8), dur * 0.5).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(sparkle, "modulate:a", 0.1, dur * 0.5).set_ease(Tween.EASE_IN_OUT)


func _deco_float_loop() -> void:
	for block in _deco_blocks:
		var dur := randf_range(4.0, 7.0)
		var tw := create_tween().set_loops()
		tw.tween_property(block, "position:y", block.position.y - 8, dur * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(block, "position:y", block.position.y, dur * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _star_sparkle_loop() -> void:
	var star := _find_child_by_name("LogoStar")
	if not star:
		return
	var tw := create_tween().set_loops()
	tw.tween_property(star, "modulate:a", 0.3, 1.5).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(star, "modulate:a", 1.0, 1.5).set_ease(Tween.EASE_IN_OUT)


func _badge_bounce_loop() -> void:
	var badge := _find_child_by_name("BadgePanel")
	if not badge:
		return
	var tw := create_tween().set_loops()
	tw.tween_property(badge, "scale", Vector2(1.1, 1.1), 0.5).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(badge, "scale", Vector2.ONE, 0.5).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(1.5)


func _find_child_by_name(child_name: String) -> Node:
	return find_child(child_name, true, false)


# ═══════════════════════════════════════
#  GAME LOGIC (preserved from original)
# ═══════════════════════════════════════

func refresh_stats() -> void:
	_best_value.text = FormatUtils.format_number(SaveManager.get_high_score())
	_games_value.text = str(SaveManager.get_games_played())
	_avg_value.text = FormatUtils.format_number(SaveManager.get_avg_score())
	_continue_btn.visible = SaveManager.has_active_game()
	_update_daily_button()
	_try_daily_reward()
	_update_sound_label()


func _toggle_sound() -> void:
	SoundManager.play_sfx("button_press")
	var enabled := not SaveManager.is_sound_enabled()
	SaveManager.set_sound_enabled(enabled)
	_update_sound_label()


func _update_sound_label() -> void:
	if _sound_btn:
		_sound_btn.text = "🔊 Sound" if SaveManager.is_sound_enabled() else "🔇 Sound"


func _update_daily_button() -> void:
	var played := DailyChallengeSystem.has_played_today()
	var now := Time.get_date_dict_from_system()
	var date_str := "%d/%d" % [now["month"], now["day"]]

	if played:
		var best := DailyChallengeSystem.get_daily_best()
		_daily_btn.text = "📅  DAILY  %s  -  %d pts" % [date_str, best]
	else:
		_daily_btn.text = "📅  DAILY CHALLENGE  %s" % date_str

	if _daily_desc:
		var streak := DailyChallengeSystem.get_streak()
		if played and streak >= 2:
			_daily_desc.text = "Streak %d days! Same puzzle for everyone" % streak
		elif played:
			_daily_desc.text = "Completed! Play again to beat your score"
		else:
			_daily_desc.text = "Same puzzle for everyone today"

	# Update fire badge
	if _fire_badge:
		var streak := DailyChallengeSystem.get_streak()
		if streak >= 2:
			_fire_badge.text = "🔥 %d" % streak
			_fire_badge.get_parent().visible = true
		else:
			_fire_badge.get_parent().visible = false


func _try_daily_reward() -> void:
	var reward := DailyRewardSystem.check_in()
	if reward.is_empty():
		return
	_show_reward_popup(reward)


func _show_reward_popup(reward: Dictionary) -> void:
	var day: int = reward["day"]
	var parts: Array[String] = []
	var multiplier: float = reward["score_multiplier"]
	var swaps: int = reward["bonus_swaps"]

	if multiplier > 1.0:
		parts.append("Score x%s" % str(multiplier))
	if swaps > 0:
		parts.append("Swap +%d" % swaps)

	var text := "Day %d Reward: %s" % [day, ", ".join(parts)]

	var popup := Label.new()
	popup.name = "DailyRewardPopup"
	popup.text = text
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.add_theme_font_size_override("font_size", 14)
	popup.add_theme_color_override("font_color", Color("#FFD536"))

	var panel := PanelContainer.new()
	panel.name = "DailyRewardPanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.18, 0.95)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_right = 20
	style.corner_radius_bottom_left = 20
	style.content_margin_left = 20.0
	style.content_margin_top = 12.0
	style.content_margin_right = 20.0
	style.content_margin_bottom = 12.0
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color("#FFD536")
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(popup)

	panel.layout_mode = 1
	panel.anchors_preset = 5
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -120.0
	panel.offset_right = 120.0
	panel.offset_top = 40.0
	panel.offset_bottom = 80.0
	panel.grow_horizontal = 2
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	add_child(panel)

	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)
