extends Control

signal start_pressed()
signal continue_pressed()
signal daily_pressed()
signal settings_pressed()
signal how_to_play_pressed()

# ─── Node references ───
var _bg: ColorRect
var _play_btn: Button
var _continue_btn: Button
var _daily_btn: Button
var _sound_btn: Button
var _best_value: Label
var _games_value: Label
var _avg_value: Label
var _streak_value: Label
var _daily_desc: Label
var _fire_badge: Label
var _badge_panel: PanelContainer
var _sound_icon_label: Label

# ─── Animation state ───
var _sparkles: Array = []
var _deco_blocks: Array = []
var _logo_blocks: Array = []
var _play_glow_tween: Tween

# ─── Sections for entrance anim ───
var _logo_section: VBoxContainer
var _hero_section: VBoxContainer
var _btn_section: VBoxContainer
var _bottom_section: HBoxContainer

# ─── Colors ───
const BG_COLOR := Color("#0F0A35")
const BLOCK_COLORS := [
	[Color("#FF9EAA"), Color("#FF6E80")],  # Coral
	[Color("#FFC060"), Color("#FF9A30")],  # Amber
	[Color("#FFE060"), Color("#FFCC20")],  # Lemon
	[Color("#7EDB95"), Color("#4EBB6B")],  # Mint
	[Color("#62CCF8"), Color("#32A8E8")],  # Sky
	[Color("#BFA4E8"), Color("#9070D0")],  # Lavender
	[Color("#FF80AB"), Color("#E8508A")],  # Pink
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
	_add_grid_overlay()
	_create_sparkles()
	_create_deco_blocks()

	# ─── Main container ───
	var main := VBoxContainer.new()
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.set("theme_override_constants/separation", 0)
	add_child(main)

	# Top padding
	_add_spacer(main, 50)

	# Logo section (icon + title + subtitle)
	_logo_section = _build_logo_section()
	main.add_child(_logo_section)

	_add_spacer(main, 24)

	# Hero score + mini stats
	_hero_section = _build_hero_section()
	main.add_child(_hero_section)

	_add_spacer(main, 32)

	# Buttons
	_btn_section = _build_buttons()
	main.add_child(_btn_section)

	# Flexible spacer
	var flex := Control.new()
	flex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(flex)

	# Bottom icons
	_bottom_section = _build_bottom_icons()
	main.add_child(_bottom_section)

	_add_spacer(main, 36)


func _add_spacer(parent: Control, height: float) -> void:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, height)
	parent.add_child(sp)


# ─── Logo Section ───

func _build_logo_section() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set("theme_override_constants/separation", 4)
	vbox.modulate.a = 0.0

	# 3x3 Block grid logo
	var logo_center := CenterContainer.new()
	var logo_grid := GridContainer.new()
	logo_grid.columns = 3
	logo_grid.set("theme_override_constants/h_separation", 4)
	logo_grid.set("theme_override_constants/v_separation", 4)
	logo_grid.pivot_offset = Vector2(42, 42)
	logo_grid.rotation_degrees = -5.0

	var grid_colors := [0, 1, 2, 3, 4, 5, 6, 0, 4]
	var grid_alphas := [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.3, 0.3]
	for i in range(9):
		var block := PanelContainer.new()
		block.custom_minimum_size = Vector2(24, 24)
		var style := StyleBoxFlat.new()
		style.bg_color = BLOCK_COLORS[grid_colors[i]][0]
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_right = 6
		style.corner_radius_bottom_left = 6
		style.shadow_color = Color(0, 0, 0, 0.3)
		style.shadow_size = 4
		block.add_theme_stylebox_override("panel", style)
		block.modulate.a = grid_alphas[i]
		logo_grid.add_child(block)
		_logo_blocks.append(block)

	logo_center.add_child(logo_grid)
	vbox.add_child(logo_center)

	_add_spacer(vbox, 16)

	# Title
	var title := Label.new()
	title.text = "ChromaBlocks"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "BLOCK  PUZZLE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("#8070B0"))
	vbox.add_child(subtitle)

	return vbox


# ─── Hero Score + Mini Stats ───

func _build_hero_section() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set("theme_override_constants/separation", 20)
	vbox.modulate.a = 0.0

	# Hero score card
	var card_center := CenterContainer.new()
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.42, 0.36, 0.91, 0.12)
	card_style.corner_radius_top_left = 24
	card_style.corner_radius_top_right = 24
	card_style.corner_radius_bottom_right = 24
	card_style.corner_radius_bottom_left = 24
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(0.42, 0.36, 0.91, 0.2)
	card_style.content_margin_left = 40
	card_style.content_margin_top = 18
	card_style.content_margin_right = 40
	card_style.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", card_style)

	var card_vbox := VBoxContainer.new()
	card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_vbox.set("theme_override_constants/separation", 2)

	var best_label := Label.new()
	best_label.text = "BEST SCORE"
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_font_size_override("font_size", 12)
	best_label.add_theme_color_override("font_color", Color("#8070B0"))
	card_vbox.add_child(best_label)

	_best_value = Label.new()
	_best_value.text = "0"
	_best_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_value.add_theme_font_size_override("font_size", 44)
	_best_value.add_theme_color_override("font_color", Color.WHITE)
	card_vbox.add_child(_best_value)

	card.add_child(card_vbox)
	card_center.add_child(card)
	vbox.add_child(card_center)

	# Mini stats row
	var stats_center := CenterContainer.new()
	var stats_hbox := HBoxContainer.new()
	stats_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_hbox.set("theme_override_constants/separation", 20)

	# Games
	var games_vbox := _build_mini_stat("0", "GAMES")
	_games_value = games_vbox.get_child(0) as Label
	stats_hbox.add_child(games_vbox)

	stats_hbox.add_child(_build_stat_divider())

	# Average
	var avg_vbox := _build_mini_stat("0", "AVERAGE")
	_avg_value = avg_vbox.get_child(0) as Label
	stats_hbox.add_child(avg_vbox)

	stats_hbox.add_child(_build_stat_divider())

	# Streak
	var streak_vbox := _build_mini_stat("0", "STREAK")
	_streak_value = streak_vbox.get_child(0) as Label
	stats_hbox.add_child(streak_vbox)

	stats_center.add_child(stats_hbox)
	vbox.add_child(stats_center)

	return vbox


func _build_mini_stat(value_text: String, label_text: String) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set("theme_override_constants/separation", 2)

	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", Color("#C8B8FF"))
	vbox.add_child(value)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#6B5FA0"))
	vbox.add_child(lbl)

	return vbox


func _build_stat_divider() -> Label:
	var div := Label.new()
	div.text = "|"
	div.add_theme_font_size_override("font_size", 16)
	div.add_theme_color_override("font_color", Color(1, 1, 1, 0.1))
	return div


# ─── Buttons ───

func _build_buttons() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set("theme_override_constants/separation", 12)
	vbox.modulate.a = 0.0

	# PLAY button (purple)
	_play_btn = _create_game_button(
		"▶  PLAY", 24,
		Color("#9B6EF3"), Color("#7B4ED3"), Color("#6B3ACD"),
		7, 22, 0.88
	)
	_play_btn.name = "PlayButton"
	_play_btn.custom_minimum_size.y = 68
	vbox.add_child(_center_wrap(_play_btn, 0.88))

	# Daily + Continue row
	var row := HBoxContainer.new()
	row.set("theme_override_constants/separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	_daily_btn = _create_game_button(
		"Daily Challenge", 15,
		Color("#ffc852"), Color("#dd8810"), Color("#a06008"),
		5, 16, 0.0
	)
	_daily_btn.name = "DailyButton"
	_daily_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_continue_btn = Button.new()
	_continue_btn.text = "↩ Continue"
	_continue_btn.name = "ContinueButton"
	_continue_btn.add_theme_font_size_override("font_size", 15)
	_continue_btn.add_theme_color_override("font_color", Color("#C8B8FF"))
	_continue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cont_style := StyleBoxFlat.new()
	cont_style.bg_color = Color(1, 1, 1, 0.05)
	cont_style.corner_radius_top_left = 16
	cont_style.corner_radius_top_right = 16
	cont_style.corner_radius_bottom_right = 16
	cont_style.corner_radius_bottom_left = 16
	cont_style.border_width_left = 1
	cont_style.border_width_top = 1
	cont_style.border_width_right = 1
	cont_style.border_width_bottom = 1
	cont_style.border_color = Color(1, 1, 1, 0.15)
	cont_style.content_margin_left = 16
	cont_style.content_margin_top = 14
	cont_style.content_margin_right = 16
	cont_style.content_margin_bottom = 14
	_continue_btn.add_theme_stylebox_override("normal", cont_style)
	_continue_btn.add_theme_stylebox_override("hover", cont_style)
	var cont_pressed := cont_style.duplicate() as StyleBoxFlat
	cont_pressed.bg_color = Color(1, 1, 1, 0.1)
	_continue_btn.add_theme_stylebox_override("pressed", cont_pressed)
	_continue_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	row.add_child(_daily_btn)
	row.add_child(_continue_btn)

	var row_margin := MarginContainer.new()
	row_margin.add_theme_constant_override("margin_left", 24)
	row_margin.add_theme_constant_override("margin_right", 24)
	row_margin.add_child(row)
	vbox.add_child(row_margin)

	# Daily description
	_daily_desc = Label.new()
	_daily_desc.name = "DailyDesc"
	_daily_desc.text = ""
	_daily_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_daily_desc.add_theme_font_size_override("font_size", 11)
	_daily_desc.add_theme_color_override("font_color", Color("#6B5FA0"))
	vbox.add_child(_daily_desc)

	# Fire badge (hidden by default)
	_fire_badge = Label.new()
	_fire_badge.name = "FireBadge"
	_badge_panel = PanelContainer.new()
	_badge_panel.visible = false
	var badge_hbox := HBoxContainer.new()
	badge_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_hbox.set("theme_override_constants/separation", 4)
	var fire_icon := Label.new()
	fire_icon.text = "🔥"
	fire_icon.add_theme_font_size_override("font_size", 12)
	badge_hbox.add_child(fire_icon)
	_fire_badge.text = "7"
	_fire_badge.add_theme_font_size_override("font_size", 11)
	_fire_badge.add_theme_color_override("font_color", Color.WHITE)
	badge_hbox.add_child(_fire_badge)

	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color("#FF2040")
	badge_style.corner_radius_top_left = 12
	badge_style.corner_radius_top_right = 12
	badge_style.corner_radius_bottom_right = 12
	badge_style.corner_radius_bottom_left = 12
	badge_style.content_margin_left = 8
	badge_style.content_margin_right = 8
	badge_style.content_margin_top = 3
	badge_style.content_margin_bottom = 3
	_badge_panel.add_theme_stylebox_override("panel", badge_style)
	_badge_panel.add_child(badge_hbox)

	var badge_center := CenterContainer.new()
	badge_center.add_child(_badge_panel)
	vbox.add_child(badge_center)

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

	var pressed_style := style.duplicate() as StyleBoxFlat
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


# ─── Bottom Icons ───

func _build_bottom_icons() -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.set("theme_override_constants/separation", 14)
	hbox.modulate.a = 0.0

	# Guide (purple)
	var guide_btn := _build_icon_button("📖", "Guide",
		Color(0.49, 0.23, 0.93, 0.25), Color(0.49, 0.23, 0.93, 0.3))
	guide_btn.get_child(0).gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			SoundManager.play_sfx("button_press")
			how_to_play_pressed.emit())
	hbox.add_child(guide_btn)

	# Themes (amber)
	var themes_btn := _build_icon_button("🎨", "Themes",
		Color(0.96, 0.62, 0.04, 0.2), Color(0.96, 0.62, 0.04, 0.25))
	themes_btn.get_child(0).gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			SoundManager.play_sfx("button_press")
			settings_pressed.emit())
	hbox.add_child(themes_btn)

	# Awards (teal) with notification dot
	var awards_btn := _build_icon_button("🏆", "Awards",
		Color(0.18, 0.83, 0.75, 0.2), Color(0.18, 0.83, 0.75, 0.25), true)
	awards_btn.get_child(0).gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			SoundManager.play_sfx("button_press"))
	hbox.add_child(awards_btn)

	# Sound (rose)
	var sound_vbox := _build_icon_button("🔊", "Sound",
		Color(0.96, 0.45, 0.71, 0.2), Color(0.96, 0.45, 0.71, 0.25))
	_sound_btn = Button.new()
	_sound_btn.name = "SoundToggle"
	_sound_btn.flat = true
	_sound_btn.mouse_filter = Control.MOUSE_FILTER_PASS
	_sound_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sound_btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_sound_btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	_sound_btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_sound_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	sound_vbox.get_child(0).add_child(_sound_btn)
	_sound_icon_label = sound_vbox.get_child(1) as Label
	hbox.add_child(sound_vbox)

	# Settings (glass)
	var settings_btn := _build_icon_button("⚙️", "Settings",
		Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.12))
	settings_btn.get_child(0).gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			SoundManager.play_sfx("button_press")
			settings_pressed.emit())
	hbox.add_child(settings_btn)

	return hbox


func _build_icon_button(icon_text: String, label_text: String, bg_color: Color, border_color: Color, show_dot: bool = false) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set("theme_override_constants/separation", 6)

	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(52, 52)
	icon_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = bg_color
	icon_style.corner_radius_top_left = 16
	icon_style.corner_radius_top_right = 16
	icon_style.corner_radius_bottom_right = 16
	icon_style.corner_radius_bottom_left = 16
	icon_style.border_width_left = 1
	icon_style.border_width_top = 1
	icon_style.border_width_right = 1
	icon_style.border_width_bottom = 1
	icon_style.border_color = border_color
	icon_style.shadow_color = Color(bg_color.r, bg_color.g, bg_color.b, 0.15)
	icon_style.shadow_size = 8
	icon_panel.add_theme_stylebox_override("panel", icon_style)

	var icon := Label.new()
	icon.text = icon_text
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 22)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_panel.add_child(icon)

	# Notification dot
	if show_dot:
		var dot := ColorRect.new()
		dot.color = Color("#F43F5E")
		dot.custom_minimum_size = Vector2(10, 10)
		dot.size = Vector2(10, 10)
		dot.position = Vector2(40, -2)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_panel.add_child(dot)

	vbox.add_child(icon_panel)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#8B7FC0"))
	vbox.add_child(lbl)

	return vbox


# ═══════════════════════════════════════
#  BACKGROUND DECORATIONS
# ═══════════════════════════════════════

func _add_glow_orb(pos: Vector2, size_val: float, color: Color) -> void:
	var orb := ColorRect.new()
	orb.color = color
	orb.size = Vector2(size_val, size_val)
	orb.position = pos - Vector2(size_val / 2, size_val / 2)
	orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(orb)


func _add_grid_overlay() -> void:
	for i in range(0, 860, 40):
		var h_line := ColorRect.new()
		h_line.color = Color(0.47, 0.39, 0.78, 0.04)
		h_line.size = Vector2(393, 1)
		h_line.position = Vector2(0, i)
		h_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(h_line)
		if i < 393:
			var v_line := ColorRect.new()
			v_line.color = Color(0.47, 0.39, 0.78, 0.04)
			v_line.size = Vector2(1, 852)
			v_line.position = Vector2(i, 0)
			v_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		var color_idx: int = cfg["color"]
		var block := ColorRect.new()
		block.color = BLOCK_COLORS[color_idx][0]
		var sz: Vector2 = cfg["size"]
		block.size = sz
		var pos: Vector2 = cfg["pos"]
		block.position = pos
		var rot: float = cfg["rot"]
		block.rotation_degrees = rot
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
	_sound_btn.pressed.connect(_toggle_sound)


# ═══════════════════════════════════════
#  ANIMATIONS
# ═══════════════════════════════════════

func _play_entrance_animations() -> void:
	# Logo fade in + slide up
	if _logo_section:
		var tw := create_tween()
		tw.tween_interval(0.2)
		tw.tween_property(_logo_section, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT)

	# Hero section
	if _hero_section:
		var tw := create_tween()
		tw.tween_interval(0.6)
		tw.tween_property(_hero_section, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)

	# Buttons
	if _btn_section:
		var tw := create_tween()
		tw.tween_interval(1.0)
		tw.tween_property(_btn_section, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)

	# Bottom icons
	if _bottom_section:
		var tw := create_tween()
		tw.tween_interval(1.3)
		tw.tween_property(_bottom_section, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)

	# Start idle after entrance
	var idle_tw := create_tween()
	idle_tw.tween_interval(2.0)
	idle_tw.tween_callback(_start_idle_animations)


func _start_idle_animations() -> void:
	_play_glow_pulse()
	_sparkle_loop()
	_deco_float_loop()
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


func _badge_bounce_loop() -> void:
	if not _badge_panel or not _badge_panel.is_inside_tree() or not _badge_panel.visible:
		return
	var tw := create_tween().set_loops()
	tw.tween_property(_badge_panel, "scale", Vector2(1.1, 1.1), 0.5).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_badge_panel, "scale", Vector2.ONE, 0.5).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(1.5)


# ═══════════════════════════════════════
#  GAME LOGIC
# ═══════════════════════════════════════

func refresh_stats() -> void:
	_best_value.text = FormatUtils.format_number(SaveManager.get_high_score())
	_games_value.text = str(SaveManager.get_games_played())
	_avg_value.text = FormatUtils.format_number(SaveManager.get_avg_score())
	if _streak_value:
		_streak_value.text = str(DailyChallengeSystem.get_streak())
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
	if _sound_icon_label:
		_sound_icon_label.text = "Sound" if SaveManager.is_sound_enabled() else "Muted"


func _update_daily_button() -> void:
	var played := DailyChallengeSystem.has_played_today()
	var now := Time.get_date_dict_from_system()
	var date_str := "%d/%d" % [now["month"], now["day"]]

	if played:
		var best := DailyChallengeSystem.get_daily_best()
		_daily_btn.text = "DAILY %s - %d pts" % [date_str, best]
	else:
		_daily_btn.text = "Daily  %s" % date_str

	if _daily_desc:
		var streak := DailyChallengeSystem.get_streak()
		if played and streak >= 2:
			_daily_desc.text = "Streak %d days! Same puzzle for everyone" % streak
		elif played:
			_daily_desc.text = "Completed! Play again to beat your score"
		else:
			_daily_desc.text = "Same puzzle for everyone today"

	if _fire_badge and _badge_panel:
		var streak := DailyChallengeSystem.get_streak()
		if streak >= 2:
			_fire_badge.text = "%d" % streak
			_badge_panel.visible = true
		else:
			_badge_panel.visible = false


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
