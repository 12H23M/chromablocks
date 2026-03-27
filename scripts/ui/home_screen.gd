extends Control

signal start_pressed()
signal continue_pressed()
signal daily_pressed()
signal mission_pressed()
signal time_attack_pressed()
signal settings_pressed()
signal how_to_play_pressed()

# ─── Node references ───
var _bg: ColorRect
var _play_btn: Button
var _time_attack_btn: Button
var _mission_btn: Button
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
var _orbs: Array = []
var _play_glow_tween: Tween
var _logo_section: Control
var _hero_section: Control
var _btn_section: Control
var _bottom_section: Control

var _daily_bonus_badge: PanelContainer = null
var _daily_bonus_label: Label = null

var _fredoka_bold: Font = null

# ─── Nav state ───
var _nav_items: Array = []  # Array of VBoxContainer nav items
var _active_nav_index: int = -1  # -1 = none active

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

	# Animated background orbs (behind all content)
	_create_orbs()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	add_child(margin)

	var main := VBoxContainer.new()
	main.set("theme_override_constants/separation", 0)
	margin.add_child(main)

	# Top flex — pushes content toward vertical center
	var top_flex := Control.new()
	top_flex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_flex.custom_minimum_size = Vector2(0, 20)
	main.add_child(top_flex)

	# 1. Logo
	_logo_section = _build_logo()
	main.add_child(_logo_section)
	_add_spacer(main, 16)

	# 2. Hero score + stats
	_hero_section = _build_hero()
	main.add_child(_hero_section)
	_add_spacer(main, 20)

	# 3. Buttons
	_btn_section = _build_buttons()
	main.add_child(_btn_section)

	# Bottom flex — balances with top flex for centering
	var bottom_flex := Control.new()
	bottom_flex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_flex.custom_minimum_size = Vector2(0, 20)
	main.add_child(bottom_flex)

	# 4. Bottom icons
	_bottom_section = _build_bottom()
	main.add_child(_bottom_section)
	_add_spacer(main, 20)

	# Floating decorative blocks
	_create_deco_blocks()


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

	# Two-part title: "Chroma" (white) + "Blocks" (gold)
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.set("theme_override_constants/separation", 0)

	var t1 := Label.new()
	t1.text = "Chroma"
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if _fredoka_bold:
		t1.add_theme_font_override("font", _fredoka_bold)
	t1.add_theme_font_size_override("font_size", 38)
	t1.add_theme_color_override("font_color", Color.WHITE)
	t1.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	t1.add_theme_constant_override("shadow_offset_x", 0)
	t1.add_theme_constant_override("shadow_offset_y", 3)
	title_row.add_child(t1)

	var t2 := Label.new()
	t2.text = "Blocks"
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if _fredoka_bold:
		t2.add_theme_font_override("font", _fredoka_bold)
	t2.add_theme_font_size_override("font_size", 38)
	t2.add_theme_color_override("font_color", Color("#FFD93D"))
	t2.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	t2.add_theme_constant_override("shadow_offset_x", 0)
	t2.add_theme_constant_override("shadow_offset_y", 3)
	title_row.add_child(t2)

	v.add_child(title_row)

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

	# TIME ATTACK + PLAY row
	var play_row := HBoxContainer.new()
	play_row.set("theme_override_constants/separation", 10)
	play_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Move play button into the row
	_play_btn.get_parent().remove_child(_play_btn) if _play_btn.get_parent() else null
	_play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play_btn.size_flags_stretch_ratio = 1.5
	play_row.add_child(_play_btn)

	# TIME ATTACK button
	_time_attack_btn = Button.new()
	_time_attack_btn.text = "⏱ TIME\nATTACK"
	_time_attack_btn.name = "TimeAttackButton"
	if _fredoka_bold:
		_time_attack_btn.add_theme_font_override("font", _fredoka_bold)
	_time_attack_btn.add_theme_font_size_override("font_size", 14)
	_time_attack_btn.add_theme_color_override("font_color", Color.WHITE)
	_time_attack_btn.custom_minimum_size = Vector2(0, 58)
	_time_attack_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_time_attack_btn.size_flags_stretch_ratio = 1.0
	var tas := StyleBoxFlat.new()
	tas.bg_color = Color("#E53935")
	_r(tas, 18)
	tas.border_width_bottom = 4
	tas.border_color = Color("#B71C1C")
	tas.shadow_color = Color(0.90, 0.22, 0.21, 0.35)
	tas.shadow_size = 10
	_time_attack_btn.add_theme_stylebox_override("normal", tas)
	_time_attack_btn.add_theme_stylebox_override("hover", tas)
	var tap := tas.duplicate() as StyleBoxFlat
	tap.bg_color = Color("#C62828")
	tap.shadow_size = 4
	_time_attack_btn.add_theme_stylebox_override("pressed", tap)
	_time_attack_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	play_row.add_child(_time_attack_btn)

	# Replace standalone PLAY with the row
	v.remove_child(_play_btn)
	v.add_child(play_row)

	# Daily Bonus Badge (above MISSION, below PLAY)
	_daily_bonus_badge = PanelContainer.new()
	_daily_bonus_badge.visible = false
	var db_style := StyleBoxFlat.new()
	db_style.bg_color = Color(1.0, 0.84, 0.0, 0.15)
	_r(db_style, 12)
	_b(db_style, 1, Color(1.0, 0.84, 0.0, 0.4))
	db_style.content_margin_left = 12
	db_style.content_margin_right = 12
	db_style.content_margin_top = 6
	db_style.content_margin_bottom = 6
	_daily_bonus_badge.add_theme_stylebox_override("panel", db_style)
	_daily_bonus_label = Label.new()
	_daily_bonus_label.text = "🎁 데일리 보너스! 점수 x2"
	_daily_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _fredoka_bold:
		_daily_bonus_label.add_theme_font_override("font", _fredoka_bold)
	_daily_bonus_label.add_theme_font_size_override("font_size", 13)
	_daily_bonus_label.add_theme_color_override("font_color", Color("#FFD93D"))
	_daily_bonus_badge.add_child(_daily_bonus_label)
	var db_center := CenterContainer.new()
	db_center.add_child(_daily_bonus_badge)
	v.add_child(db_center)

	# MISSION
	_mission_btn = Button.new()
	_mission_btn.text = "MISSION"
	_mission_btn.name = "MissionButton"
	if _fredoka_bold:
		_mission_btn.add_theme_font_override("font", _fredoka_bold)
	_mission_btn.add_theme_font_size_override("font_size", 18)
	_mission_btn.add_theme_color_override("font_color", Color.WHITE)
	_mission_btn.custom_minimum_size = Vector2(280, 56)
	var ms := StyleBoxFlat.new()
	ms.bg_color = Color("#2196F3")
	_r(ms, 16)
	ms.border_width_bottom = 4
	ms.border_color = Color("#1565C0")
	ms.shadow_color = Color(0.13, 0.59, 0.95, 0.3)
	ms.shadow_size = 8
	_mission_btn.add_theme_stylebox_override("normal", ms)
	_mission_btn.add_theme_stylebox_override("hover", ms)
	var mp := ms.duplicate() as StyleBoxFlat
	mp.bg_color = Color("#1976D2")
	mp.shadow_size = 3
	_mission_btn.add_theme_stylebox_override("pressed", mp)
	_mission_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	v.add_child(_mission_btn)

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
	_continue_btn.add_theme_font_size_override("font_size", 20)
	_continue_btn.add_theme_color_override("font_color", Color("#C4B5FD"))
	_continue_btn.custom_minimum_size = Vector2(0, 48)
	_continue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_continue_btn.size_flags_stretch_ratio = 1.0
	var cs2 := StyleBoxFlat.new()
	cs2.bg_color = Color("#2A2A5C")
	_r(cs2, 28)
	_b(cs2, 2, Color("#7C3AED"))
	cs2.content_margin_left = 12
	cs2.content_margin_right = 12
	cs2.content_margin_top = 10
	cs2.content_margin_bottom = 10
	_continue_btn.add_theme_stylebox_override("normal", cs2)
	_continue_btn.add_theme_stylebox_override("hover", cs2)
	var cp := cs2.duplicate() as StyleBoxFlat
	cp.bg_color = Color("#3A3A6C")
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
	_nav_items.clear()

	# Guide (index 0)
	var guide := _nav_item("guide", "Guide")
	guide.get_child(0).gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			SoundManager.play_sfx("button_press")
			_bounce_nav(0)
			how_to_play_pressed.emit())
	h.add_child(guide)
	_nav_items.append(guide)

	# Awards (index 1)
	var awards := _nav_item("awards", "Awards")
	awards.get_child(0).gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			SoundManager.play_sfx("button_press")
			_bounce_nav(1))
	h.add_child(awards)
	_nav_items.append(awards)

	# Sound (index 2)
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
	_nav_items.append(sound)

	# Settings (index 3)
	var settings := _nav_item("settings", "Settings")
	settings.get_child(0).gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			SoundManager.play_sfx("button_press")
			_bounce_nav(3)
			settings_pressed.emit())
	h.add_child(settings)
	_nav_items.append(settings)

	# Start all inactive
	_set_all_nav_inactive()

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
	ll.name = "NavLabel"
	ll.text = lbl
	ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ll.add_theme_font_size_override("font_size", 9)
	ll.add_theme_color_override("font_color", Color("#8888AA"))
	v.add_child(ll)

	# Active dot indicator (hidden by default)
	var dot := NavDot.new()
	dot.name = "NavDot"
	dot.visible = false
	v.add_child(dot)

	return v


func _set_nav_active(index: int) -> void:
	if index == _active_nav_index:
		return
	_set_all_nav_inactive()
	_active_nav_index = index
	if index < 0 or index >= _nav_items.size():
		return
	var item: VBoxContainer = _nav_items[index]
	var icon: NavIcon = item.get_child(0) as NavIcon
	var label: Label = item.get_node("NavLabel") as Label
	var dot: Control = item.get_node("NavDot")
	icon.modulate.a = 1.0
	label.modulate.a = 1.0
	dot.visible = true


func _set_all_nav_inactive() -> void:
	_active_nav_index = -1
	for item in _nav_items:
		if not is_instance_valid(item):
			continue
		var icon: NavIcon = item.get_child(0) as NavIcon
		var label: Label = item.get_node("NavLabel") as Label
		var dot: Control = item.get_node("NavDot")
		icon.modulate.a = 0.35
		label.modulate.a = 0.35
		dot.visible = false


func _bounce_nav(index: int) -> void:
	if index < 0 or index >= _nav_items.size():
		return
	var item: VBoxContainer = _nav_items[index]
	item.pivot_offset = item.size / 2.0
	var tw := create_tween()
	tw.tween_property(item, "scale", Vector2(0.9, 0.9), 0.05)
	tw.tween_property(item, "scale", Vector2.ONE, 0.05)


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


func _create_orbs() -> void:
	var orb_data := [
		{"color": Color("#A8A4FF", 0.02), "radius": 160.0, "cx": 0.3, "cy": 0.25, "period": 10.0, "amp_x": 40.0, "amp_y": 35.0, "phase": 0.0},
		{"color": Color("#4ECDC4", 0.015), "radius": 140.0, "cx": 0.7, "cy": 0.50, "period": 8.0, "amp_x": 35.0, "amp_y": 45.0, "phase": 2.0},
		{"color": Color("#FF6B6B", 0.015), "radius": 120.0, "cx": 0.4, "cy": 0.75, "period": 12.0, "amp_x": 50.0, "amp_y": 30.0, "phase": 4.0},
	]
	for data in orb_data:
		var orb := BackgroundOrb.new()
		orb.orb_color = data["color"]
		orb.orb_radius = data["radius"]
		orb.set_meta("cx", data["cx"])
		orb.set_meta("cy", data["cy"])
		orb.set_meta("period", data["period"])
		orb.set_meta("amp_x", data["amp_x"])
		orb.set_meta("amp_y", data["amp_y"])
		orb.set_meta("phase", data["phase"])
		orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(orb)
		_orbs.append(orb)


func _create_deco_blocks() -> void:
	var colors := [Color("#FF6E80"), Color("#FFE060"), Color("#62CCF8"), Color("#BFA4E8")]
	var positions := [
		Vector2(0.15, 0.65), Vector2(0.80, 0.58),
		Vector2(0.30, 0.78), Vector2(0.70, 0.72),
	]
	for i in range(4):
		var block := ColorRect.new()
		var block_size: float = 8.0 + float(i % 3) * 2.0
		block.custom_minimum_size = Vector2(block_size, block_size)
		block.size = Vector2(block_size, block_size)
		block.color = colors[i]
		block.color.a = 0.08 + float(i) * 0.01
		block.mouse_filter = Control.MOUSE_FILTER_IGNORE
		block.set_meta("base_y", positions[i].y)
		block.set_meta("phase", float(i) * 1.5)
		block.set_meta("frac_x", positions[i].x)
		add_child(block)
		_deco_blocks.append(block)


func _notification(what: int) -> void:
	# Auto-disable _process when home screen is hidden (during gameplay)
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_process(visible)


func _process(_delta: float) -> void:
	var t: float = float(Time.get_ticks_msec()) / 1000.0

	# Animate orbs
	for orb in _orbs:
		if not is_instance_valid(orb):
			continue
		var cx: float = orb.get_meta("cx")
		var cy: float = orb.get_meta("cy")
		var period: float = orb.get_meta("period")
		var amp_x: float = orb.get_meta("amp_x")
		var amp_y: float = orb.get_meta("amp_y")
		var phase: float = orb.get_meta("phase")
		var freq: float = TAU / period
		var ox: float = sin(t * freq + phase) * amp_x
		var oy: float = cos(t * freq * 0.7 + phase) * amp_y
		orb.position.x = size.x * cx + ox - orb.orb_radius
		orb.position.y = size.y * cy + oy - orb.orb_radius

	# Animate deco blocks
	if _deco_blocks.is_empty():
		return
	for block in _deco_blocks:
		if not is_instance_valid(block):
			continue
		var frac_x: float = block.get_meta("frac_x")
		var base_y: float = block.get_meta("base_y")
		var phase: float = block.get_meta("phase")
		var offset_y: float = sin(t * 0.5 + phase) * 8.0
		block.position.x = size.x * frac_x
		block.position.y = size.y * base_y + offset_y


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
	_mission_btn.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		mission_pressed.emit())
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

func set_settings_active(active: bool) -> void:
	if active:
		_set_nav_active(3)
	else:
		_set_all_nav_inactive()


func refresh_stats() -> void:
	_best_value.text = FormatUtils.format_number(SaveManager.get_high_score())
	_games_value.text = str(SaveManager.get_games_played())
	_avg_value.text = FormatUtils.format_number(SaveManager.get_avg_score())
	if _streak_value:
		var play_streak: int = SaveManager.get_play_streak()
		if SaveManager.is_streak_alive():
			_streak_value.text = str(play_streak)
		else:
			_streak_value.text = "0"
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
	_update_daily_bonus_badge()


func _update_daily_bonus_badge() -> void:
	if _daily_bonus_badge:
		_daily_bonus_badge.visible = SaveManager.is_daily_bonus_available()


func _toggle_sound() -> void:
	SoundManager.play_sfx("button_press")
	_bounce_nav(2)
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
		var play_streak: int = SaveManager.get_play_streak()
		if SaveManager.is_streak_alive() and play_streak >= 2:
			_fire_badge.text = "🔥 %d" % play_streak
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
	var multiplier: float = reward["score_multiplier"]
	var swaps: int = reward["bonus_swaps"]
	var cycle_day: int = SaveManager.get_value("daily_reward", "cycle_day", 1)
	var streak: int = SaveManager.get_value("daily_reward", "streak", 0)

	# ── Full-screen overlay ──
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	# ── Central card container ──
	var card_wrap := CenterContainer.new()
	card_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(card_wrap)

	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#1A1050")
	_r(card_style, 24)
	_b(card_style, 2, Color("#7C3AED"))
	card_style.shadow_color = Color(0.49, 0.23, 0.93, 0.4)
	card_style.shadow_size = 20
	card_style.content_margin_left = 24
	card_style.content_margin_right = 24
	card_style.content_margin_top = 28
	card_style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", card_style)
	card.custom_minimum_size = Vector2(320, 0)
	card_wrap.add_child(card)

	var card_vbox := VBoxContainer.new()
	card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_vbox.set("theme_override_constants/separation", 16)
	card.add_child(card_vbox)

	# ── Title ──
	var title := Label.new()
	title.text = "Daily Reward"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _fredoka_bold:
		title.add_theme_font_override("font", _fredoka_bold)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#FFD93D"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 2)
	card_vbox.add_child(title)

	# ── Streak label ──
	if streak >= 2:
		var streak_lbl := Label.new()
		streak_lbl.text = "🔥 %d일 연속 출석!" % streak
		streak_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _fredoka_bold:
			streak_lbl.add_theme_font_override("font", _fredoka_bold)
		streak_lbl.add_theme_font_size_override("font_size", 14)
		streak_lbl.add_theme_color_override("font_color", Color("#FF8A50"))
		card_vbox.add_child(streak_lbl)

	# ── 7-day calendar row ──
	var cal_center := CenterContainer.new()
	var cal_row := HBoxContainer.new()
	cal_row.set("theme_override_constants/separation", 6)
	cal_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cal_center.add_child(cal_row)
	card_vbox.add_child(cal_center)

	for i in range(1, 8):
		var day_panel := PanelContainer.new()
		var day_style := StyleBoxFlat.new()
		day_panel.custom_minimum_size = Vector2(36, 44)

		var is_today := (i == cycle_day)
		var is_past := (i < cycle_day)

		if is_today:
			day_style.bg_color = Color("#FFD93D")
			_r(day_style, 10)
			_b(day_style, 2, Color("#FFA000"))
		elif is_past:
			day_style.bg_color = Color(0.3, 0.25, 0.6, 0.6)
			_r(day_style, 10)
			_b(day_style, 1, Color(0.5, 0.4, 0.8, 0.4))
		else:
			day_style.bg_color = Color(0.15, 0.12, 0.35, 0.5)
			_r(day_style, 10)
			_b(day_style, 1, Color(0.3, 0.25, 0.5, 0.3))

		day_style.content_margin_left = 2
		day_style.content_margin_right = 2
		day_style.content_margin_top = 4
		day_style.content_margin_bottom = 4
		day_panel.add_theme_stylebox_override("panel", day_style)

		var day_vbox := VBoxContainer.new()
		day_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		day_vbox.set("theme_override_constants/separation", 0)

		# Day number
		var day_num := Label.new()
		day_num.text = str(i)
		day_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _fredoka_bold:
			day_num.add_theme_font_override("font", _fredoka_bold)
		day_num.add_theme_font_size_override("font_size", 12)
		if is_today:
			day_num.add_theme_color_override("font_color", Color("#3A2000"))
		elif is_past:
			day_num.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		else:
			day_num.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
		day_vbox.add_child(day_num)

		# Check mark or reward icon
		var icon_lbl := Label.new()
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 14)
		if is_past:
			icon_lbl.text = "✓"
			icon_lbl.add_theme_color_override("font_color", Color("#7EDB95"))
		elif is_today:
			icon_lbl.text = "★"
			icon_lbl.add_theme_color_override("font_color", Color("#FF8A00"))
		else:
			# Show small reward hint
			var r_data: Dictionary = DailyRewardSystem.REWARDS[i]
			var r_mult: float = r_data["score_multiplier"]
			if r_mult > 1.0:
				icon_lbl.text = "⭐"
			else:
				icon_lbl.text = "🔄"
			icon_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.25))
		day_vbox.add_child(icon_lbl)

		day_panel.add_child(day_vbox)
		cal_row.add_child(day_panel)

		# Pulse animation for today's cell
		if is_today:
			day_panel.pivot_offset = Vector2(18, 22)
			var pulse_tw := create_tween().set_loops()
			pulse_tw.set_speed_scale(1.0 / maxf(Engine.time_scale, 0.01))
			pulse_tw.tween_property(day_panel, "scale", Vector2(1.08, 1.08), 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			pulse_tw.tween_property(day_panel, "scale", Vector2.ONE, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			# Store reference so we can kill it on close
			overlay.set_meta("pulse_tween", pulse_tw)

	# ── Reward display ──
	var reward_center := CenterContainer.new()
	var reward_hbox := HBoxContainer.new()
	reward_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_hbox.set("theme_override_constants/separation", 20)
	reward_center.add_child(reward_hbox)
	card_vbox.add_child(reward_center)

	if multiplier > 1.0:
		var mult_vbox := VBoxContainer.new()
		mult_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		mult_vbox.set("theme_override_constants/separation", 4)
		var mult_icon := Label.new()
		mult_icon.text = "⭐"
		mult_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mult_icon.add_theme_font_size_override("font_size", 36)
		mult_vbox.add_child(mult_icon)
		var mult_text := Label.new()
		mult_text.text = "점수 x%s" % str(multiplier)
		mult_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _fredoka_bold:
			mult_text.add_theme_font_override("font", _fredoka_bold)
		mult_text.add_theme_font_size_override("font_size", 16)
		mult_text.add_theme_color_override("font_color", Color("#FFD93D"))
		mult_vbox.add_child(mult_text)
		reward_hbox.add_child(mult_vbox)

	if swaps > 0:
		var swap_vbox := VBoxContainer.new()
		swap_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		swap_vbox.set("theme_override_constants/separation", 4)
		var swap_icon := Label.new()
		swap_icon.text = "🔄"
		swap_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		swap_icon.add_theme_font_size_override("font_size", 36)
		swap_vbox.add_child(swap_icon)
		var swap_text := Label.new()
		swap_text.text = "스왑 +%d" % swaps
		swap_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _fredoka_bold:
			swap_text.add_theme_font_override("font", _fredoka_bold)
		swap_text.add_theme_font_size_override("font_size", 16)
		swap_text.add_theme_color_override("font_color", Color.WHITE)
		swap_vbox.add_child(swap_text)
		reward_hbox.add_child(swap_vbox)

	# ── Day indicator ──
	var day_label := Label.new()
	day_label.text = "Day %d / 7" % day
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_label.add_theme_font_size_override("font_size", 12)
	day_label.add_theme_color_override("font_color", Color("#8070B0"))
	card_vbox.add_child(day_label)

	# ── Tap to close hint ──
	var hint := Label.new()
	hint.text = "탭해서 닫기"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
	card_vbox.add_child(hint)

	# Hint blink
	var hint_tw := create_tween().set_loops()
	hint_tw.set_speed_scale(1.0 / maxf(Engine.time_scale, 0.01))
	hint_tw.tween_property(hint, "modulate:a", 0.4, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	hint_tw.tween_property(hint, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# ── Close logic ──
	var close_fn := func() -> void:
		if not is_instance_valid(overlay):
			return
		# Kill pulse tween
		if overlay.has_meta("pulse_tween"):
			var ptw: Tween = overlay.get_meta("pulse_tween")
			if ptw and ptw.is_valid():
				ptw.kill()
		hint_tw.kill()
		# Scale + fade out
		card.pivot_offset = card.size / 2.0
		var close_tw := create_tween()
		close_tw.set_speed_scale(1.0 / maxf(Engine.time_scale, 0.01))
		close_tw.set_parallel(true)
		close_tw.tween_property(overlay, "color:a", 0.0, 0.25)
		close_tw.tween_property(card, "scale", Vector2(0.85, 0.85), 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		close_tw.tween_property(card, "modulate:a", 0.0, 0.2)
		close_tw.chain().tween_callback(overlay.queue_free)

	# Tap overlay to close
	overlay.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			SoundManager.play_sfx("button_press")
			close_fn.call())

	# Auto-close after 3 seconds
	var auto_tw := create_tween()
	auto_tw.set_speed_scale(1.0 / maxf(Engine.time_scale, 0.01))
	auto_tw.tween_interval(3.0)
	auto_tw.tween_callback(close_fn)

	# ── Entrance animation ──
	overlay.modulate.a = 0.0
	card.pivot_offset = Vector2(160, 100)
	card.scale = Vector2(0.7, 0.7)
	card.position.y += 80

	var enter_tw := create_tween()
	enter_tw.set_speed_scale(1.0 / maxf(Engine.time_scale, 0.01))
	enter_tw.tween_interval(0.3)
	# Fade in overlay
	enter_tw.tween_property(overlay, "modulate:a", 1.0, 0.2)
	enter_tw.parallel().tween_property(overlay, "color", Color(0, 0, 0, 0.8), 0.2)
	# Card slide up + bounce
	enter_tw.parallel().tween_property(card, "position:y", 0.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	enter_tw.parallel().tween_property(card, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


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


# ═══════════════════════════════════════
#  INNER CLASS: NavDot — active indicator dot below nav label
# ═══════════════════════════════════════

class NavDot extends Control:
	const DOT_RADIUS := 2.0
	const DOT_COLOR := Color("#7C3AED")

	func _ready() -> void:
		custom_minimum_size = Vector2(4, 4)
		size = Vector2(4, 4)
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_circle(Vector2(DOT_RADIUS, DOT_RADIUS), DOT_RADIUS, DOT_COLOR)


# ═══════════════════════════════════════
#  INNER CLASS: BackgroundOrb — soft gradient circle for living background
# ═══════════════════════════════════════

class BackgroundOrb extends Control:
	var orb_color := Color(0.5, 0.2, 0.9, 0.06)
	var orb_radius := 150.0

	func _ready() -> void:
		custom_minimum_size = Vector2(orb_radius * 2, orb_radius * 2)
		size = Vector2(orb_radius * 2, orb_radius * 2)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := Vector2(orb_radius, orb_radius)
		# Draw radial gradient as concentric circles (soft falloff)
		var steps := 20
		for i in range(steps, 0, -1):
			var frac: float = float(i) / float(steps)
			var r: float = orb_radius * frac
			var alpha: float = orb_color.a * (1.0 - frac) * 2.0
			alpha = clampf(alpha, 0.0, orb_color.a)
			var col := Color(orb_color.r, orb_color.g, orb_color.b, alpha)
			draw_circle(center, r, col)
