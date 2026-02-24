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
var _logo_section: Control
var _hero_section: Control
var _btn_section: Control
var _bottom_section: Control

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

	# Background
	_bg = ColorRect.new()
	_bg.color = BG_COLOR
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	_add_glow_orb(Vector2(320, 40), 220.0, Color(0.26, 0.73, 0.96, 0.1))
	_add_glow_orb(Vector2(-80, 650), 280.0, Color(0.65, 0.55, 0.87, 0.08))
	_add_glow_orb(Vector2(100, 400), 160.0, Color(1.0, 0.49, 0.56, 0.06))
	_add_grid_overlay()
	_create_sparkles()
	_create_deco_blocks()

	# Main layout — use MarginContainer for consistent 28px side padding
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_bottom", 0)
	add_child(margin)

	var main := VBoxContainer.new()
	main.set("theme_override_constants/separation", 0)
	margin.add_child(main)

	# Top padding
	_add_spacer(main, 50)

	# 1. Logo (3x3 grid + title + subtitle)
	_logo_section = _build_logo_section()
	main.add_child(_logo_section)

	_add_spacer(main, 28)

	# 2. Hero score card + mini stats
	_hero_section = _build_hero_section()
	main.add_child(_hero_section)

	_add_spacer(main, 36)

	# 3. Buttons (PLAY + Daily/Continue row)
	_btn_section = _build_buttons()
	main.add_child(_btn_section)

	# Flex spacer
	var flex := Control.new()
	flex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(flex)

	# 4. Bottom icons
	_bottom_section = _build_bottom_icons()
	main.add_child(_bottom_section)

	_add_spacer(main, 40)


func _add_spacer(parent: Control, h: float) -> void:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, h)
	parent.add_child(sp)


# ─── 1. Logo ───

func _build_logo_section() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set("theme_override_constants/separation", 2)
	vbox.modulate.a = 0.0

	# 3x3 block grid
	var grid_center := CenterContainer.new()
	var grid := GridContainer.new()
	grid.columns = 3
	grid.set("theme_override_constants/h_separation", 4)
	grid.set("theme_override_constants/v_separation", 4)
	grid.pivot_offset = Vector2(42, 42)
	grid.rotation_degrees = -5.0

	var colors := [0, 1, 2, 3, 4, 5, 6, 0, 4]
	var alphas := [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.3, 0.3]
	for i in range(9):
		var block := PanelContainer.new()
		block.custom_minimum_size = Vector2(24, 24)
		var s := StyleBoxFlat.new()
		s.bg_color = BLOCK_COLORS[colors[i]][0]
		_set_corner_radius(s, 6)
		s.shadow_color = Color(0, 0, 0, 0.3)
		s.shadow_size = 4
		block.add_theme_stylebox_override("panel", s)
		block.modulate.a = alphas[i]
		grid.add_child(block)
		_logo_blocks.append(block)
	grid_center.add_child(grid)
	vbox.add_child(grid_center)

	_add_spacer(vbox, 16)

	var title := Label.new()
	title.text = "ChromaBlocks"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "BLOCK  PUZZLE"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color("#8070B0"))
	vbox.add_child(sub)

	return vbox


# ─── 2. Hero Score + Mini Stats ───

func _build_hero_section() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set("theme_override_constants/separation", 24)
	vbox.modulate.a = 0.0

	# Score card
	var card_center := CenterContainer.new()
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.42, 0.36, 0.91, 0.12)
	_set_corner_radius(cs, 24)
	_set_border(cs, 1, Color(0.42, 0.36, 0.91, 0.2))
	cs.content_margin_left = 44
	cs.content_margin_right = 44
	cs.content_margin_top = 18
	cs.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", cs)

	var cv := VBoxContainer.new()
	cv.alignment = BoxContainer.ALIGNMENT_CENTER
	cv.set("theme_override_constants/separation", 0)

	var bl := Label.new()
	bl.text = "BEST SCORE"
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.add_theme_font_size_override("font_size", 12)
	bl.add_theme_color_override("font_color", Color("#8070B0"))
	cv.add_child(bl)

	_best_value = Label.new()
	_best_value.text = "0"
	_best_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_value.add_theme_font_size_override("font_size", 44)
	_best_value.add_theme_color_override("font_color", Color.WHITE)
	cv.add_child(_best_value)

	card.add_child(cv)
	card_center.add_child(card)
	vbox.add_child(card_center)

	# Mini stats row
	var sc := CenterContainer.new()
	var sh := HBoxContainer.new()
	sh.alignment = BoxContainer.ALIGNMENT_CENTER
	sh.set("theme_override_constants/separation", 24)

	var g := _make_mini_stat("0", "GAMES")
	_games_value = g.get_child(0) as Label
	sh.add_child(g)
	sh.add_child(_make_divider())

	var a := _make_mini_stat("0", "AVERAGE")
	_avg_value = a.get_child(0) as Label
	sh.add_child(a)
	sh.add_child(_make_divider())

	var st := _make_mini_stat("0", "STREAK")
	_streak_value = st.get_child(0) as Label
	sh.add_child(st)

	sc.add_child(sh)
	vbox.add_child(sc)
	return vbox


func _make_mini_stat(val: String, lbl_text: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set("theme_override_constants/separation", 2)
	var vl := Label.new()
	vl.text = val
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vl.add_theme_font_size_override("font_size", 18)
	vl.add_theme_color_override("font_color", Color("#C8B8FF"))
	v.add_child(vl)
	var ll := Label.new()
	ll.text = lbl_text
	ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ll.add_theme_font_size_override("font_size", 10)
	ll.add_theme_color_override("font_color", Color("#6B5FA0"))
	v.add_child(ll)
	return v


func _make_divider() -> Label:
	var d := Label.new()
	d.text = "|"
	d.add_theme_font_size_override("font_size", 16)
	d.add_theme_color_override("font_color", Color(1, 1, 1, 0.08))
	return d


# ─── 3. Buttons ───

func _build_buttons() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set("theme_override_constants/separation", 12)
	vbox.modulate.a = 0.0

	# PLAY — full width, 68px, purple
	_play_btn = Button.new()
	_play_btn.text = "▶  PLAY"
	_play_btn.name = "PlayButton"
	_play_btn.add_theme_font_size_override("font_size", 24)
	_play_btn.add_theme_color_override("font_color", Color.WHITE)
	_play_btn.custom_minimum_size = Vector2(0, 68)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color("#8B5CF6")
	_set_corner_radius(ps, 22)
	ps.border_width_bottom = 6
	ps.border_color = Color("#6B3ACD")
	ps.shadow_color = Color(0.49, 0.23, 0.93, 0.5)
	ps.shadow_size = 16
	_play_btn.add_theme_stylebox_override("normal", ps)
	_play_btn.add_theme_stylebox_override("hover", ps)
	var pp := ps.duplicate() as StyleBoxFlat
	pp.bg_color = Color("#7B4CD6")
	pp.shadow_size = 8
	_play_btn.add_theme_stylebox_override("pressed", pp)
	_play_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	vbox.add_child(_play_btn)

	# Daily + Continue row
	var row := HBoxContainer.new()
	row.set("theme_override_constants/separation", 10)

	# Daily — amber, height 54
	_daily_btn = Button.new()
	_daily_btn.text = "Daily Challenge"
	_daily_btn.name = "DailyButton"
	_daily_btn.add_theme_font_size_override("font_size", 15)
	_daily_btn.add_theme_color_override("font_color", Color("#78350F"))
	_daily_btn.custom_minimum_size = Vector2(0, 54)
	_daily_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color("#F5B020")
	_set_corner_radius(ds, 16)
	ds.border_width_bottom = 4
	ds.border_color = Color("#C88A10")
	ds.shadow_color = Color(0.96, 0.62, 0.04, 0.3)
	ds.shadow_size = 10
	_daily_btn.add_theme_stylebox_override("normal", ds)
	_daily_btn.add_theme_stylebox_override("hover", ds)
	var dp := ds.duplicate() as StyleBoxFlat
	dp.bg_color = Color("#D8980A")
	dp.shadow_size = 4
	_daily_btn.add_theme_stylebox_override("pressed", dp)
	_daily_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	row.add_child(_daily_btn)

	# Continue — outline, height 54
	_continue_btn = Button.new()
	_continue_btn.text = "Continue"
	_continue_btn.name = "ContinueButton"
	_continue_btn.add_theme_font_size_override("font_size", 15)
	_continue_btn.add_theme_color_override("font_color", Color("#C8B8FF"))
	_continue_btn.custom_minimum_size = Vector2(0, 54)
	_continue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs2 := StyleBoxFlat.new()
	cs2.bg_color = Color(1, 1, 1, 0.05)
	_set_corner_radius(cs2, 16)
	_set_border(cs2, 1, Color(1, 1, 1, 0.15))
	_continue_btn.add_theme_stylebox_override("normal", cs2)
	_continue_btn.add_theme_stylebox_override("hover", cs2)
	var cp := cs2.duplicate() as StyleBoxFlat
	cp.bg_color = Color(1, 1, 1, 0.1)
	_continue_btn.add_theme_stylebox_override("pressed", cp)
	_continue_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	row.add_child(_continue_btn)

	vbox.add_child(row)

	# Daily desc
	_daily_desc = Label.new()
	_daily_desc.name = "DailyDesc"
	_daily_desc.text = ""
	_daily_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_daily_desc.add_theme_font_size_override("font_size", 11)
	_daily_desc.add_theme_color_override("font_color", Color("#6B5FA0"))
	vbox.add_child(_daily_desc)

	# Fire badge
	_fire_badge = Label.new()
	_fire_badge.name = "FireBadge"
	_badge_panel = PanelContainer.new()
	_badge_panel.visible = false
	var bh := HBoxContainer.new()
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.set("theme_override_constants/separation", 4)
	var fi := Label.new()
	fi.text = "STREAK"
	fi.add_theme_font_size_override("font_size", 10)
	fi.add_theme_color_override("font_color", Color.WHITE)
	bh.add_child(fi)
	_fire_badge.text = "7"
	_fire_badge.add_theme_font_size_override("font_size", 11)
	_fire_badge.add_theme_color_override("font_color", Color.WHITE)
	bh.add_child(_fire_badge)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color("#FF2040")
	_set_corner_radius(bs, 12)
	bs.content_margin_left = 8
	bs.content_margin_right = 8
	bs.content_margin_top = 3
	bs.content_margin_bottom = 3
	_badge_panel.add_theme_stylebox_override("panel", bs)
	_badge_panel.add_child(bh)
	var bc := CenterContainer.new()
	bc.add_child(_badge_panel)
	vbox.add_child(bc)

	return vbox


# ─── 4. Bottom Icons ───

func _build_bottom_icons() -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.set("theme_override_constants/separation", 12)
	hbox.modulate.a = 0.0

	# Each icon: colored glass panel + single letter + label
	var guide := _make_icon_btn("?", "Guide", Color(0.49, 0.23, 0.93), Color("#C8A8FF"))
	guide.get_child(0).gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			SoundManager.play_sfx("button_press")
			how_to_play_pressed.emit())
	hbox.add_child(guide)

	var themes := _make_icon_btn("T", "Themes", Color(0.96, 0.62, 0.04), Color("#FFD080"))
	themes.get_child(0).gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			SoundManager.play_sfx("button_press")
			settings_pressed.emit())
	hbox.add_child(themes)

	var awards := _make_icon_btn("W", "Awards", Color(0.18, 0.83, 0.75), Color("#70F0E0"), true)
	awards.get_child(0).gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			SoundManager.play_sfx("button_press"))
	hbox.add_child(awards)

	var sound := _make_icon_btn("S", "Sound", Color(0.96, 0.45, 0.71), Color("#FFA0C8"))
	# Overlay invisible button for sound toggle
	_sound_btn = Button.new()
	_sound_btn.name = "SoundToggle"
	_sound_btn.flat = true
	_sound_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sound_btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_sound_btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	_sound_btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_sound_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	sound.get_child(0).add_child(_sound_btn)
	_sound_icon_label = sound.get_child(1) as Label
	hbox.add_child(sound)

	var settings := _make_icon_btn("G", "Settings", Color(0.5, 0.5, 0.6), Color("#A0A0B0"))
	settings.get_child(0).gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			SoundManager.play_sfx("button_press")
			settings_pressed.emit())
	hbox.add_child(settings)

	return hbox


func _make_icon_btn(letter: String, lbl_text: String, accent: Color, letter_color: Color, dot: bool = false) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.set("theme_override_constants/separation", 6)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(50, 50)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var s := StyleBoxFlat.new()
	s.bg_color = Color(accent.r, accent.g, accent.b, 0.18)
	_set_corner_radius(s, 16)
	_set_border(s, 1, Color(accent.r, accent.g, accent.b, 0.28))
	s.shadow_color = Color(accent.r, accent.g, accent.b, 0.1)
	s.shadow_size = 6
	panel.add_theme_stylebox_override("panel", s)

	var icon_lbl := Label.new()
	icon_lbl.text = letter
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 20)
	icon_lbl.add_theme_color_override("font_color", letter_color)
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon_lbl)

	if dot:
		var d := Control.new()
		d.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		d.position = Vector2(42, -3)
		d.size = Vector2(8, 8)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dot_rect := ColorRect.new()
		dot_rect.color = Color("#F43F5E")
		dot_rect.size = Vector2(8, 8)
		dot_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.add_child(dot_rect)
		panel.add_child(d)

	vb.add_child(panel)

	var lbl := Label.new()
	lbl.text = lbl_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#8B7FC0"))
	vb.add_child(lbl)

	return vb


# ─── Helpers ───

func _set_corner_radius(s: StyleBoxFlat, r: int) -> void:
	s.corner_radius_top_left = r
	s.corner_radius_top_right = r
	s.corner_radius_bottom_right = r
	s.corner_radius_bottom_left = r


func _set_border(s: StyleBoxFlat, w: int, c: Color) -> void:
	s.border_width_left = w
	s.border_width_top = w
	s.border_width_right = w
	s.border_width_bottom = w
	s.border_color = c


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
		var h := ColorRect.new()
		h.color = Color(0.47, 0.39, 0.78, 0.04)
		h.size = Vector2(393, 1)
		h.position = Vector2(0, i)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(h)
		if i < 393:
			var v := ColorRect.new()
			v.color = Color(0.47, 0.39, 0.78, 0.04)
			v.size = Vector2(1, 852)
			v.position = Vector2(i, 0)
			v.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(v)


func _create_sparkles() -> void:
	var positions := [
		Vector2(45, 95), Vector2(338, 200), Vector2(70, 330),
		Vector2(313, 480), Vector2(320, 150), Vector2(40, 570),
		Vector2(343, 620), Vector2(100, 720), Vector2(303, 50), Vector2(273, 760),
	]
	for pos in positions:
		var d := ColorRect.new()
		d.color = Color.WHITE
		d.size = Vector2(3, 3)
		d.position = pos
		d.modulate.a = 0.1
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(d)
		_sparkles.append(d)


func _create_deco_blocks() -> void:
	var cfgs := [
		{"pos": Vector2(-6, 100), "size": Vector2(36, 36), "color": 0, "rot": 18.0},
		{"pos": Vector2(355, 180), "size": Vector2(24, 24), "color": 4, "rot": -22.0},
		{"pos": Vector2(8, 580), "size": Vector2(44, 18), "color": 2, "rot": 28.0},
		{"pos": Vector2(359, 610), "size": Vector2(18, 44), "color": 3, "rot": -12.0},
		{"pos": Vector2(14, 400), "size": Vector2(20, 20), "color": 5, "rot": 35.0},
		{"pos": Vector2(355, 360), "size": Vector2(28, 28), "color": 1, "rot": -28.0},
	]
	for cfg in cfgs:
		var ci: int = cfg["color"]
		var b := ColorRect.new()
		b.color = BLOCK_COLORS[ci][0]
		var sz: Vector2 = cfg["size"]
		b.size = sz
		var p: Vector2 = cfg["pos"]
		b.position = p
		var r: float = cfg["rot"]
		b.rotation_degrees = r
		b.modulate.a = 0.15
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(b)
		_deco_blocks.append(b)


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
	if _logo_section:
		var tw := create_tween()
		tw.tween_interval(0.2)
		tw.tween_property(_logo_section, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT)
	if _hero_section:
		var tw := create_tween()
		tw.tween_interval(0.6)
		tw.tween_property(_hero_section, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	if _btn_section:
		var tw := create_tween()
		tw.tween_interval(1.0)
		tw.tween_property(_btn_section, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	if _bottom_section:
		var tw := create_tween()
		tw.tween_interval(1.3)
		tw.tween_property(_bottom_section, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)

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
	_play_glow_tween.tween_property(style, "shadow_size", 24, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_play_glow_tween.tween_property(style, "shadow_size", 10, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


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
	# Always show Continue (dimmed if no save)
	var has_save := SaveManager.has_active_game()
	if has_save:
		_continue_btn.modulate.a = 1.0
		_continue_btn.disabled = false
	else:
		_continue_btn.modulate.a = 0.35
		_continue_btn.disabled = true
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
	_set_corner_radius(style, 20)
	_set_border(style, 1, Color("#FFD536"))
	style.content_margin_left = 20.0
	style.content_margin_top = 12.0
	style.content_margin_right = 20.0
	style.content_margin_bottom = 12.0
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
