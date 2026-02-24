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

var _fredoka_bold: Font = null

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
	_fredoka_bold = load("res://assets/fonts/Fredoka-Bold.ttf") as Font
	_build_ui()
	_connect_signals()
	_play_entrance_animations()
	refresh_stats()


func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Gradient background: top purple → mid dark → bottom dark purple
	var bg_tex := GradientTexture2D.new()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		Color("#0F0A35"),   # top — deep purple
		Color("#1C1068"),   # upper mid — brighter purple
		Color("#120D40"),   # center — dark
		Color("#0D0930"),   # bottom — deepest
	])
	grad.offsets = PackedFloat32Array([0.0, 0.35, 0.65, 1.0])
	bg_tex.gradient = grad
	bg_tex.fill = GradientTexture2D.FILL_LINEAR
	bg_tex.fill_from = Vector2(0.5, 0.0)
	bg_tex.fill_to = Vector2(0.5, 1.0)
	bg_tex.width = 4
	bg_tex.height = 852

	var bg_rect := TextureRect.new()
	bg_rect.texture = bg_tex
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_rect)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	add_child(margin)

	var main := VBoxContainer.new()
	main.set("theme_override_constants/separation", 0)
	margin.add_child(main)

	_add_spacer(main, 40)

	# 1. Logo
	_logo_section = _build_logo()
	main.add_child(_logo_section)
	_add_spacer(main, 20)

	# 2. Hero score + stats
	_hero_section = _build_hero()
	main.add_child(_hero_section)
	_add_spacer(main, 24)

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
	_add_spacer(main, 28)


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

	# Logo grid drawn manually for reliable rotation
	var logo_wrap := Control.new()
	logo_wrap.custom_minimum_size = Vector2(0, 96)
	logo_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var logo_draw := LogoGrid.new()
	logo_draw.block_colors = BLOCK_COLORS
	logo_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo_wrap.add_child(logo_draw)
	v.add_child(logo_wrap)

	_add_spacer(v, 12)

	var t := Label.new()
	t.text = "ChromaBlocks"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _fredoka_bold:
		t.add_theme_font_override("font", _fredoka_bold)
	t.add_theme_font_size_override("font_size", 38)
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
	if _fredoka_bold:
		_best_value.add_theme_font_override("font", _fredoka_bold)
	_best_value.add_theme_font_size_override("font_size", 40)
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
	if _fredoka_bold:
		vl.add_theme_font_override("font", _fredoka_bold)
	vl.add_theme_font_size_override("font_size", 16)
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
	if _fredoka_bold:
		_play_btn.add_theme_font_override("font", _fredoka_bold)
	_play_btn.add_theme_font_size_override("font_size", 22)
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

	# Daily + Continue — equal width row
	var row := HBoxContainer.new()
	row.set("theme_override_constants/separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Daily
	_daily_btn = Button.new()
	_daily_btn.text = "Daily Challenge"
	_daily_btn.name = "DailyButton"
	if _fredoka_bold:
		_daily_btn.add_theme_font_override("font", _fredoka_bold)
	_daily_btn.add_theme_font_size_override("font_size", 14)
	_daily_btn.add_theme_color_override("font_color", Color("#5C3A10"))
	_daily_btn.custom_minimum_size = Vector2(0, 48)
	_daily_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_daily_btn.size_flags_stretch_ratio = 1.0
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
	row.add_child(_daily_btn)

	# Continue
	_continue_btn = Button.new()
	_continue_btn.text = "Continue"
	_continue_btn.name = "ContinueButton"
	if _fredoka_bold:
		_continue_btn.add_theme_font_override("font", _fredoka_bold)
	_continue_btn.add_theme_font_size_override("font_size", 14)
	_continue_btn.add_theme_color_override("font_color", Color("#C8B8FF"))
	_continue_btn.custom_minimum_size = Vector2(0, 48)
	_continue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_continue_btn.size_flags_stretch_ratio = 1.0
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
	row.add_child(_continue_btn)

	v.add_child(row)

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
	h.set("theme_override_constants/separation", 16)
	h.modulate.a = 0.0

	# Guide
	var guide := _nav_item("guide", "Guide")
	guide.get_child(0).gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			SoundManager.play_sfx("button_press")
			how_to_play_pressed.emit())
	h.add_child(guide)

	# Awards
	var awards := _nav_item("awards", "Awards")
	awards.get_child(0).gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			SoundManager.play_sfx("button_press"))
	h.add_child(awards)

	# Sound
	var snd_type := "sound_on" if SaveManager.is_sound_enabled() else "sound_off"
	var sound := _nav_item(snd_type, "Sound")
	_sound_btn = Button.new()
	_sound_btn.name = "SoundToggle"
	_sound_btn.flat = true
	_sound_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for sn in ["normal", "hover", "pressed", "focus"]:
		_sound_btn.add_theme_stylebox_override(sn, StyleBoxEmpty.new())
	sound.get_child(0).add_child(_sound_btn)
	_sound_icon_label = sound.get_child(1) as Label
	h.add_child(sound)

	# Settings
	var settings := _nav_item("settings", "Settings")
	settings.get_child(0).gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			SoundManager.play_sfx("button_press")
			settings_pressed.emit())
	h.add_child(settings)

	return h


func _nav_item(icon_type: String, lbl: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set("theme_override_constants/separation", 5)
	v.custom_minimum_size = Vector2(56, 0)

	# Circular dark background with icon drawn inside
	var icon := NavIcon.new()
	icon.icon_type = icon_type
	v.add_child(icon)

	var ll := Label.new()
	ll.text = lbl
	ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ll.add_theme_font_size_override("font_size", 9)
	ll.add_theme_color_override("font_color", Color("#8888AA"))
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

# _add_glow_orb removed — using gradient bg instead

func _create_sparkles() -> void:
	pass  # Removed for cleaner background


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
	# Sparkles removed for cleaner look


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
	# Update icon shape
	if _sound_btn and _sound_btn.get_parent():
		var icon_parent := _sound_btn.get_parent()
		if icon_parent is NavIcon:
			icon_parent.icon_type = "sound_on" if SaveManager.is_sound_enabled() else "sound_off"
			icon_parent.queue_redraw()


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


# ═══════════════════════════════════════
#  INNER CLASS: LogoGrid — draw rotated 3x3 blocks
# ═══════════════════════════════════════

class LogoGrid extends Control:
	var block_colors: Array = []

	func _ready() -> void:
		custom_minimum_size = Vector2(0, 96)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if block_colors.is_empty():
			return
		var cell := 26.0
		var gap := 4.0
		var rad := 6.0
		var total := cell * 3.0 + gap * 2.0
		var cx := size.x / 2.0
		var cy := 48.0

		# Rotate -5 degrees around center
		var angle := deg_to_rad(-5.0)
		draw_set_transform(Vector2(cx, cy), angle, Vector2.ONE)

		var ci := [0, 1, 2, 3, 4, 5, 6, 0, 4]
		var al := [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.3, 0.3]

		for i in range(9):
			var row := i / 3
			var col := i % 3
			var bx := col * (cell + gap) - total / 2.0
			var by := row * (cell + gap) - total / 2.0

			var base: Color = block_colors[ci[i]][0]
			var dark: Color = block_colors[ci[i]][1]
			base.a = al[i]
			dark.a = al[i]

			# Drop shadow
			var sh := Color(0, 0, 0, 0.35 * al[i])
			_draw_rounded(bx + 1, by + 2, cell, cell, rad, sh)

			# Main block body (darker shade)
			_draw_rounded(bx, by, cell, cell, rad, dark)

			# Top highlight (lighter, top 70%)
			_draw_rounded(bx, by, cell, cell * 0.7, rad, base)

			# Shine line at top
			var shine := Color(1, 1, 1, 0.2 * al[i])
			draw_rect(Rect2(bx + rad, by + 1.5, cell - rad * 2, 1.5), shine)

		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _draw_rounded(x: float, y: float, w: float, h: float, r: float, c: Color) -> void:
		# Rounded rect using rects + circles
		draw_rect(Rect2(x + r, y, w - r * 2, h), c)
		draw_rect(Rect2(x, y + r, w, h - r * 2), c)
		draw_circle(Vector2(x + r, y + r), r, c)
		draw_circle(Vector2(x + w - r, y + r), r, c)
		draw_circle(Vector2(x + r, y + h - r), r, c)
		draw_circle(Vector2(x + w - r, y + h - r), r, c)


# ═══════════════════════════════════════
#  INNER CLASS: NavIcon — circular dark bg + white vector icon
# ═══════════════════════════════════════

class NavIcon extends Control:
	const SZ := 44.0
	const BG_COL := Color(0.10, 0.08, 0.25, 1.0)  # dark purple circle
	const BD_COL := Color(0.20, 0.16, 0.40, 0.3)   # subtle border
	const IC_COL := Color(0.85, 0.82, 0.95, 1.0)    # soft white
	var icon_type := ""

	func _ready() -> void:
		custom_minimum_size = Vector2(SZ, SZ)
		size = Vector2(SZ, SZ)
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		var c := Vector2(SZ / 2.0, SZ / 2.0)
		# Dark circle background
		draw_circle(c, SZ / 2.0, BG_COL)
		# Subtle border circle
		draw_arc(c, SZ / 2.0 - 0.5, 0, TAU, 48, BD_COL, 1.0)

		match icon_type:
			"guide":
				# Open book
				draw_rect(Rect2(c.x - 10, c.y - 8, 9, 16), IC_COL)
				draw_rect(Rect2(c.x + 1, c.y - 8, 9, 16), IC_COL)
				draw_rect(Rect2(c.x - 0.5, c.y - 9, 1, 18), Color(0.6, 0.55, 0.75))
				# Page lines
				for yy in [-3.0, 0.0, 3.0]:
					draw_rect(Rect2(c.x - 7, c.y + yy, 5, 1), BG_COL)
					draw_rect(Rect2(c.x + 3, c.y + yy, 5, 1), BG_COL)
			"themes":
				# 4 color dots (palette)
				draw_circle(Vector2(c.x - 6, c.y - 6), 4.5, Color("#FF7B8E"))
				draw_circle(Vector2(c.x + 6, c.y - 6), 4.5, Color("#FFE066"))
				draw_circle(Vector2(c.x - 6, c.y + 6), 4.5, Color("#64C8FF"))
				draw_circle(Vector2(c.x + 6, c.y + 6), 4.5, Color("#66E0A0"))
			"awards":
				# Trophy
				draw_rect(Rect2(c.x - 6, c.y - 8, 12, 10), IC_COL)
				draw_rect(Rect2(c.x - 1.5, c.y + 2, 3, 4), IC_COL)
				draw_rect(Rect2(c.x - 5, c.y + 6, 10, 2), IC_COL)
				# Handles
				draw_rect(Rect2(c.x - 9, c.y - 5, 3, 5), Color(IC_COL, 0.5))
				draw_rect(Rect2(c.x + 6, c.y - 5, 3, 5), Color(IC_COL, 0.5))
			"sound_on":
				# Speaker + waves
				draw_rect(Rect2(c.x - 8, c.y - 3, 5, 6), IC_COL)
				draw_rect(Rect2(c.x - 3, c.y - 6, 4, 12), IC_COL)
				draw_arc(Vector2(c.x + 2, c.y), 5.0, -0.7, 0.7, 12, IC_COL, 1.5)
				draw_arc(Vector2(c.x + 2, c.y), 9.0, -0.6, 0.6, 12, Color(IC_COL, 0.5), 1.5)
			"sound_off":
				# Speaker + X
				draw_rect(Rect2(c.x - 8, c.y - 3, 5, 6), IC_COL)
				draw_rect(Rect2(c.x - 3, c.y - 6, 4, 12), IC_COL)
				# X mark
				draw_line(Vector2(c.x + 3, c.y - 5), Vector2(c.x + 11, c.y + 5), Color("#FF4060"), 2.0)
				draw_line(Vector2(c.x + 11, c.y - 5), Vector2(c.x + 3, c.y + 5), Color("#FF4060"), 2.0)
			"settings":
				# Gear: outer ring with teeth + inner hole
				draw_circle(c, 7.0, IC_COL)
				draw_circle(c, 3.5, BG_COL)
				# 8 teeth
				for ang_i in range(8):
					var rad := deg_to_rad(float(ang_i) * 45.0)
					var tp := Vector2(c.x + cos(rad) * 10.0, c.y + sin(rad) * 10.0)
					draw_circle(tp, 2.5, IC_COL)
