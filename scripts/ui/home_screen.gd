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

# ─── Animation ───
var _sparkles: Array = []
var _deco_blocks: Array = []
var _play_glow_tween: Tween
var _logo_section: Control
var _hero_section: Control
var _btn_section: Control
var _bottom_section: Control

const BG_COLOR := Color("#0F0A35")
const BLOCK_COLORS := [
	[Color("#FF9EAA"), Color("#FF6E80")],
	[Color("#FFC060"), Color("#FF9A30")],
	[Color("#FFE060"), Color("#FFCC20")],
	[Color("#7EDB95"), Color("#4EBB6B")],
	[Color("#62CCF8"), Color("#32A8E8")],
	[Color("#BFA4E8"), Color("#9070D0")],
	[Color("#FF80AB"), Color("#E8508A")],
]


func _ready() -> void:
	_build_ui()
	_connect_signals()
	_play_entrance_animations()
	refresh_stats()


func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	_bg = ColorRect.new()
	_bg.color = BG_COLOR
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	_add_glow_orb(Vector2(300, 80), 180.0, Color(0.42, 0.36, 0.91, 0.12))
	_add_glow_orb(Vector2(80, 600), 200.0, Color(1.0, 0.4, 0.6, 0.06))
	_add_glow_orb(Vector2(200, 780), 160.0, Color(0.31, 0.78, 1.0, 0.06))
	_create_sparkles()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	add_child(margin)

	var main := VBoxContainer.new()
	main.set("theme_override_constants/separation", 0)
	margin.add_child(main)

	_add_spacer(main, 48)

	# 1. Logo
	_logo_section = _build_logo()
	main.add_child(_logo_section)
	_add_spacer(main, 24)

	# 2. Hero score + stats
	_hero_section = _build_hero()
	main.add_child(_hero_section)
	_add_spacer(main, 28)

	# 3. Buttons
	_btn_section = _build_buttons()
	main.add_child(_btn_section)

	# Flex
	var flex := Control.new()
	flex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(flex)

	# 4. Bottom icons
	_bottom_section = _build_bottom()
	main.add_child(_bottom_section)
	_add_spacer(main, 36)


func _add_spacer(p: Control, h: float) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	p.add_child(s)


# ═══════════════════════════════════════
#  1. LOGO — compact 3x3 + smaller title
# ═══════════════════════════════════════

func _build_logo() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set("theme_override_constants/separation", 2)
	v.modulate.a = 0.0

	var gc := CenterContainer.new()
	var g := GridContainer.new()
	g.columns = 3
	g.set("theme_override_constants/h_separation", 3)
	g.set("theme_override_constants/v_separation", 3)
	g.pivot_offset = Vector2(33, 33)
	g.rotation_degrees = -5.0

	var ci := [0, 1, 2, 3, 4, 5, 6, 0, 4]
	var al := [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.3, 0.3]
	for i in range(9):
		var b := PanelContainer.new()
		b.custom_minimum_size = Vector2(20, 20)
		var st := StyleBoxFlat.new()
		st.bg_color = BLOCK_COLORS[ci[i]][0]
		_r(st, 5)
		st.shadow_color = Color(0, 0, 0, 0.25)
		st.shadow_size = 3
		b.add_theme_stylebox_override("panel", st)
		b.modulate.a = al[i]
		g.add_child(b)
	gc.add_child(g)
	v.add_child(gc)

	_add_spacer(v, 12)

	var t := Label.new()
	t.text = "ChromaBlocks"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 34)
	t.add_theme_color_override("font_color", Color.WHITE)
	v.add_child(t)

	var s := Label.new()
	s.text = "BLOCK PUZZLE"
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_font_size_override("font_size", 10)
	s.add_theme_color_override("font_color", Color("#8070B0"))
	v.add_child(s)

	return v


# ═══════════════════════════════════════
#  2. HERO SCORE + MINI STATS — compact
# ═══════════════════════════════════════

func _build_hero() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set("theme_override_constants/separation", 18)
	v.modulate.a = 0.0

	# Score card
	var cc := CenterContainer.new()
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.42, 0.36, 0.91, 0.12)
	_r(cs, 20)
	_b(cs, 1, Color(0.42, 0.36, 0.91, 0.2))
	cs.content_margin_left = 36
	cs.content_margin_right = 36
	cs.content_margin_top = 14
	cs.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", cs)

	var cv := VBoxContainer.new()
	cv.alignment = BoxContainer.ALIGNMENT_CENTER
	cv.set("theme_override_constants/separation", -2)

	var bl := Label.new()
	bl.text = "BEST SCORE"
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.add_theme_font_size_override("font_size", 10)
	bl.add_theme_color_override("font_color", Color("#8070B0"))
	cv.add_child(bl)

	_best_value = Label.new()
	_best_value.text = "0"
	_best_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_value.add_theme_font_size_override("font_size", 36)
	_best_value.add_theme_color_override("font_color", Color.WHITE)
	cv.add_child(_best_value)

	card.add_child(cv)
	cc.add_child(card)
	v.add_child(cc)

	# Mini stats
	var sc := CenterContainer.new()
	var sh := HBoxContainer.new()
	sh.alignment = BoxContainer.ALIGNMENT_CENTER
	sh.set("theme_override_constants/separation", 20)

	var gv := _mini_stat("0", "GAMES")
	_games_value = gv.get_child(0) as Label
	sh.add_child(gv)
	sh.add_child(_divider())
	var av := _mini_stat("0", "AVERAGE")
	_avg_value = av.get_child(0) as Label
	sh.add_child(av)
	sh.add_child(_divider())
	var sv := _mini_stat("0", "STREAK")
	_streak_value = sv.get_child(0) as Label
	sh.add_child(sv)

	sc.add_child(sh)
	v.add_child(sc)
	return v


func _mini_stat(val: String, lbl: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set("theme_override_constants/separation", 1)
	var vl := Label.new()
	vl.text = val
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vl.add_theme_font_size_override("font_size", 15)
	vl.add_theme_color_override("font_color", Color("#C8B8FF"))
	v.add_child(vl)
	var ll := Label.new()
	ll.text = lbl
	ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ll.add_theme_font_size_override("font_size", 9)
	ll.add_theme_color_override("font_color", Color("#6B5FA0"))
	v.add_child(ll)
	return v


func _divider() -> Label:
	var d := Label.new()
	d.text = "|"
	d.add_theme_font_size_override("font_size", 14)
	d.add_theme_color_override("font_color", Color(1, 1, 1, 0.06))
	return d


# ═══════════════════════════════════════
#  3. BUTTONS — PLAY + Daily/Continue row
# ═══════════════════════════════════════

func _build_buttons() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set("theme_override_constants/separation", 10)
	v.modulate.a = 0.0

	# PLAY
	_play_btn = Button.new()
	_play_btn.text = "▶  PLAY"
	_play_btn.name = "PlayButton"
	_play_btn.add_theme_font_size_override("font_size", 20)
	_play_btn.add_theme_color_override("font_color", Color.WHITE)
	_play_btn.custom_minimum_size = Vector2(0, 58)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color("#8B5CF6")
	_r(ps, 18)
	ps.border_width_bottom = 4
	ps.border_color = Color("#6B3ACD")
	ps.shadow_color = Color(0.49, 0.23, 0.93, 0.35)
	ps.shadow_size = 10
	_play_btn.add_theme_stylebox_override("normal", ps)
	_play_btn.add_theme_stylebox_override("hover", ps)
	var pp := ps.duplicate() as StyleBoxFlat
	pp.bg_color = Color("#7B4CD6")
	pp.shadow_size = 4
	_play_btn.add_theme_stylebox_override("pressed", pp)
	_play_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	v.add_child(_play_btn)

	# Daily + Continue — force equal width with GridContainer
	var grid := GridContainer.new()
	grid.columns = 2
	grid.set("theme_override_constants/h_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Daily
	_daily_btn = Button.new()
	_daily_btn.text = "Daily Challenge"
	_daily_btn.name = "DailyButton"
	_daily_btn.add_theme_font_size_override("font_size", 13)
	_daily_btn.add_theme_color_override("font_color", Color("#5C3A10"))
	_daily_btn.custom_minimum_size = Vector2(160, 48)
	_daily_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color("#F5B020")
	_r(ds, 14)
	ds.border_width_bottom = 3
	ds.border_color = Color("#C88A10")
	ds.shadow_color = Color(0.96, 0.62, 0.04, 0.25)
	ds.shadow_size = 6
	ds.content_margin_left = 12
	ds.content_margin_right = 12
	ds.content_margin_top = 10
	ds.content_margin_bottom = 10
	_daily_btn.add_theme_stylebox_override("normal", ds)
	_daily_btn.add_theme_stylebox_override("hover", ds)
	var dp := ds.duplicate() as StyleBoxFlat
	dp.bg_color = Color("#D8980A")
	_daily_btn.add_theme_stylebox_override("pressed", dp)
	_daily_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	grid.add_child(_daily_btn)

	# Continue
	_continue_btn = Button.new()
	_continue_btn.text = "Continue"
	_continue_btn.name = "ContinueButton"
	_continue_btn.add_theme_font_size_override("font_size", 13)
	_continue_btn.add_theme_color_override("font_color", Color("#C8B8FF"))
	_continue_btn.custom_minimum_size = Vector2(160, 48)
	_continue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs2 := StyleBoxFlat.new()
	cs2.bg_color = Color(1, 1, 1, 0.05)
	_r(cs2, 14)
	_b(cs2, 1, Color(1, 1, 1, 0.12))
	cs2.content_margin_left = 12
	cs2.content_margin_right = 12
	cs2.content_margin_top = 10
	cs2.content_margin_bottom = 10
	_continue_btn.add_theme_stylebox_override("normal", cs2)
	_continue_btn.add_theme_stylebox_override("hover", cs2)
	var cp := cs2.duplicate() as StyleBoxFlat
	cp.bg_color = Color(1, 1, 1, 0.1)
	_continue_btn.add_theme_stylebox_override("pressed", cp)
	_continue_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	grid.add_child(_continue_btn)

	v.add_child(grid)

	# Daily desc
	_daily_desc = Label.new()
	_daily_desc.name = "DailyDesc"
	_daily_desc.text = ""
	_daily_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_daily_desc.add_theme_font_size_override("font_size", 9)
	_daily_desc.add_theme_color_override("font_color", Color("#6B5FA0"))
	v.add_child(_daily_desc)

	# Badge (hidden)
	_fire_badge = Label.new()
	_badge_panel = PanelContainer.new()
	_badge_panel.visible = false
	var bh := HBoxContainer.new()
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	_fire_badge.text = "7"
	_fire_badge.add_theme_font_size_override("font_size", 10)
	_fire_badge.add_theme_color_override("font_color", Color.WHITE)
	bh.add_child(_fire_badge)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color("#FF2040")
	_r(bs, 10)
	bs.content_margin_left = 8
	bs.content_margin_right = 8
	bs.content_margin_top = 2
	bs.content_margin_bottom = 2
	_badge_panel.add_theme_stylebox_override("panel", bs)
	_badge_panel.add_child(bh)
	var bcc := CenterContainer.new()
	bcc.add_child(_badge_panel)
	v.add_child(bcc)

	return v


# ═══════════════════════════════════════
#  4. BOTTOM ICONS — smaller, glass style
# ═══════════════════════════════════════

func _build_bottom() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.set("theme_override_constants/separation", 10)
	h.modulate.a = 0.0

	var guide := _icon("?", "Guide", Color(0.49, 0.23, 0.93), Color("#C8A8FF"))
	guide.get_child(0).gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			SoundManager.play_sfx("button_press")
			how_to_play_pressed.emit())
	h.add_child(guide)

	var themes := _icon("T", "Themes", Color(0.96, 0.62, 0.04), Color("#FFD080"))
	themes.get_child(0).gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			SoundManager.play_sfx("button_press")
			settings_pressed.emit())
	h.add_child(themes)

	var awards := _icon("W", "Awards", Color(0.18, 0.83, 0.75), Color("#70F0E0"))
	awards.get_child(0).gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			SoundManager.play_sfx("button_press"))
	h.add_child(awards)

	var sound := _icon("S", "Sound", Color(0.96, 0.45, 0.71), Color("#FFA0C8"))
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
	h.add_child(sound)

	var settings := _icon("G", "Settings", Color(0.5, 0.5, 0.6), Color("#A0A0B0"))
	settings.get_child(0).gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			SoundManager.play_sfx("button_press")
			settings_pressed.emit())
	h.add_child(settings)

	return h


func _icon(letter: String, lbl: String, accent: Color, lc: Color) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set("theme_override_constants/separation", 4)

	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(44, 44)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var s := StyleBoxFlat.new()
	s.bg_color = Color(accent.r, accent.g, accent.b, 0.15)
	_r(s, 14)
	_b(s, 1, Color(accent.r, accent.g, accent.b, 0.22))
	s.shadow_color = Color(accent.r, accent.g, accent.b, 0.08)
	s.shadow_size = 4
	p.add_theme_stylebox_override("panel", s)

	var il := Label.new()
	il.text = letter
	il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	il.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	il.add_theme_font_size_override("font_size", 17)
	il.add_theme_color_override("font_color", lc)
	il.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(il)
	v.add_child(p)

	var ll := Label.new()
	ll.text = lbl
	ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ll.add_theme_font_size_override("font_size", 9)
	ll.add_theme_color_override("font_color", Color("#8B7FC0"))
	v.add_child(ll)

	return v


# ─── Helpers ───

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


# ═══════════════════════════════════════
#  BACKGROUND
# ═══════════════════════════════════════

func _add_glow_orb(pos: Vector2, sz: float, color: Color) -> void:
	var o := ColorRect.new()
	o.color = color
	o.size = Vector2(sz, sz)
	o.position = pos - Vector2(sz / 2, sz / 2)
	o.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(o)

func _create_sparkles() -> void:
	var positions := [
		Vector2(45, 95), Vector2(338, 200), Vector2(70, 330),
		Vector2(313, 480), Vector2(320, 150), Vector2(40, 570),
		Vector2(343, 620), Vector2(100, 720), Vector2(303, 50),
	]
	for pos in positions:
		var d := ColorRect.new()
		d.color = Color.WHITE
		d.size = Vector2(2, 2)
		d.position = pos
		d.modulate.a = 0.08
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(d)
		_sparkles.append(d)


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
		tw.tween_property(_logo_section, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	if _hero_section:
		var tw := create_tween()
		tw.tween_interval(0.5)
		tw.tween_property(_hero_section, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
	if _btn_section:
		var tw := create_tween()
		tw.tween_interval(0.8)
		tw.tween_property(_btn_section, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
	if _bottom_section:
		var tw := create_tween()
		tw.tween_interval(1.1)
		tw.tween_property(_bottom_section, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	var idle := create_tween()
	idle.tween_interval(1.8)
	idle.tween_callback(_start_idle)


func _start_idle() -> void:
	# Play button glow pulse
	if is_inside_tree():
		var style: StyleBoxFlat = _play_btn.get_theme_stylebox("normal")
		if style:
			_play_glow_tween = create_tween().set_loops()
			_play_glow_tween.tween_property(style, "shadow_size", 16, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			_play_glow_tween.tween_property(style, "shadow_size", 6, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# Sparkles
	for sparkle in _sparkles:
		var tw := create_tween().set_loops()
		tw.tween_interval(randf_range(0.0, 3.0))
		tw.tween_property(sparkle, "modulate:a", randf_range(0.3, 0.6), randf_range(1.5, 3.0)).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(sparkle, "modulate:a", 0.08, randf_range(1.5, 3.0)).set_ease(Tween.EASE_IN_OUT)


# ═══════════════════════════════════════
#  GAME LOGIC
# ═══════════════════════════════════════

func refresh_stats() -> void:
	_best_value.text = FormatUtils.format_number(SaveManager.get_high_score())
	_games_value.text = str(SaveManager.get_games_played())
	_avg_value.text = FormatUtils.format_number(SaveManager.get_avg_score())
	if _streak_value:
		_streak_value.text = str(DailyChallengeSystem.get_streak())
	var has_save := SaveManager.has_active_game()
	if has_save:
		_continue_btn.modulate.a = 1.0
		_continue_btn.disabled = false
	else:
		_continue_btn.modulate.a = 0.3
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
		_daily_btn.text = "Daily %s · %d" % [date_str, best]
	else:
		_daily_btn.text = "Daily Challenge"
	if _daily_desc:
		var streak := DailyChallengeSystem.get_streak()
		if played and streak >= 2:
			_daily_desc.text = "%d day streak" % streak
		elif played:
			_daily_desc.text = "Completed! Try again?"
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
	var text := "Day %d: %s" % [day, ", ".join(parts)]

	var popup := Label.new()
	popup.text = text
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.add_theme_font_size_override("font_size", 13)
	popup.add_theme_color_override("font_color", Color("#FFD536"))

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.18, 0.95)
	_r(style, 16)
	_b(style, 1, Color("#FFD536"))
	style.content_margin_left = 16
	style.content_margin_top = 10
	style.content_margin_right = 16
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(popup)

	panel.layout_mode = 1
	panel.anchors_preset = 5
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -100
	panel.offset_right = 100
	panel.offset_top = 40
	panel.offset_bottom = 72
	panel.grow_horizontal = 2
	add_child(panel)

	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)
