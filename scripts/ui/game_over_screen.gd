extends Control
## Game Over Screen — Design D2
## Dark purple/navy gradient, hexagon grade badge, glass stat chips,
## mission cards, rising color particles, score counting animation.

signal play_again_pressed()
signal go_home_pressed()
signal continue_ad_pressed()
signal double_score_ad_pressed()

# ── Constants ──────────────────────────────────────────────────────
const GRADE_THRESHOLDS := { "S": 10000, "A": 5000, "B": 2000 }
const GRADE_COLORS := {
	"S": Color(1.0, 0.84, 0.0),
	"A": Color(0.65, 0.55, 0.87),
	"B": Color(0.37, 0.73, 0.96),
	"C": Color(1.0, 0.55, 0.26),
}
const PARTICLE_COLORS: Array[Color] = [
	Color(1, 0.42, 0.61, 0.35),
	Color(0.30, 0.59, 1.0, 0.35),
	Color(0.42, 0.80, 0.47, 0.35),
	Color(1, 0.85, 0.24, 0.35),
	Color(0.61, 0.45, 0.81, 0.35),
	Color(1, 0.55, 0.26, 0.35),
]
const STAT_META := [
	{ "icon": "📏", "label": "Lines", "color": Color(0.30, 0.59, 1.0) },
	{ "icon": "🧱", "label": "Blocks", "color": Color(0.42, 0.80, 0.47) },
	{ "icon": "🔥", "label": "Combos", "color": Color(1.0, 0.55, 0.26) },
	{ "icon": "⚡", "label": "Chains", "color": Color(0.61, 0.45, 0.81) },
]
const BG_TOP := Color(0.039, 0.031, 0.125, 0.97)   # #0a0820
const BG_BOTTOM := Color(0.102, 0.078, 0.322, 0.97)  # #1a1452

# ── State ──────────────────────────────────────────────────────────
var _used_ad_this_game := false
var _glow_tween: Tween
var _particle_timer: float = 0.0
var _particles: Array = []
var _fredoka: Font

# ── Node references (assigned in _build_ui) ───────────────────────
var _bg_rect: ColorRect
var _particle_layer: Control
var _scroll: ScrollContainer
var _content: VBoxContainer
var _title_label: Label
var _grade_hex: Control    # custom hexagon draw node
var _grade_label: Label
var _score_label: Label
var _best_score_row: HBoxContainer
var _best_val_label: Label
var _new_best_label: Label
var _stat_chips: Array = []       # Array of PanelContainer
var _stat_value_labels: Array = [] # Array of Label
var _mission_container: VBoxContainer
var _continue_btn: Button
var _double_btn: Button
var _play_again_btn: Button
var _home_btn: Button
var _ad_section: HBoxContainer


func _ready() -> void:
	_fredoka = load("res://assets/fonts/Fredoka-Bold.ttf") as Font
	_build_ui()
	_connect_buttons()


func _process(delta: float) -> void:
	if not visible:
		return
	_update_particles(delta)


# ══════════════════════════════════════════════════════════════════
#  PUBLIC API  (matches existing interface)
# ══════════════════════════════════════════════════════════════════
func show_result(state: GameState) -> void:
	var is_new_best := state.score > state.high_score and state.score > 0
	var best: int = state.score if is_new_best else state.high_score
	var grade_str: String = _get_grade(state.score)
	var speed_scale: float = 1.0 / maxf(Engine.time_scale, 0.01)

	# Reset visuals
	_score_label.text = "0"
	_best_val_label.text = FormatUtils.format_number(best)
	_new_best_label.visible = is_new_best
	_grade_label.text = grade_str
	_grade_label.add_theme_color_override("font_color", GRADE_COLORS[grade_str])
	_grade_hex.set_meta("grade", grade_str)
	_grade_hex.queue_redraw()

	# Initial hidden states
	_grade_hex.modulate.a = 0.0
	_grade_hex.scale = Vector2(0.3, 0.3)
	_score_label.modulate.a = 0.0
	_best_score_row.modulate.a = 0.0
	for chip in _stat_chips:
		chip.modulate.a = 0.0
	_mission_container.modulate.a = 0.0
	_play_again_btn.modulate.a = 0.0
	_home_btn.modulate.a = 0.0
	_ad_section.modulate.a = 0.0

	# Show/hide ad buttons
	var show_ads := not _used_ad_this_game and AdManager.is_rewarded_available()
	_continue_btn.visible = show_ads
	_double_btn.visible = show_ads
	_ad_section.visible = show_ads

	# Clear particles
	_particles.clear()
	_particle_layer.queue_redraw()

	# Show screen
	modulate.a = 0.0
	visible = true

	# ── Animation sequence ──
	# 1) Fade in
	var tw := create_tween()
	tw.set_speed_scale(speed_scale)
	tw.tween_property(self, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)

	# 2) Title glow pulse
	_start_title_glow(speed_scale)

	# 3) Grade hexagon bounce
	var gt := create_tween()
	gt.set_speed_scale(speed_scale)
	gt.tween_interval(0.3)
	gt.tween_property(_grade_hex, "modulate:a", 1.0, 0.25)
	gt.parallel().tween_property(_grade_hex, "scale", Vector2(1.15, 1.15), 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	gt.tween_property(_grade_hex, "scale", Vector2(1.0, 1.0), 0.15) \
		.set_ease(Tween.EASE_IN_OUT)

	# 4) Score count-up
	var st := create_tween()
	st.set_speed_scale(speed_scale)
	st.tween_interval(0.35)
	st.tween_property(_score_label, "modulate:a", 1.0, 0.15)
	if state.score > 0:
		st.tween_method(func(v: int) -> void:
			_score_label.text = FormatUtils.format_number(v)
		, 0, state.score, 0.8).set_ease(Tween.EASE_OUT)
	# Score bounce at end
	st.tween_property(_score_label, "scale", Vector2(1.12, 1.12), 0.08) \
		.set_ease(Tween.EASE_OUT)
	st.tween_property(_score_label, "scale", Vector2(1.0, 1.0), 0.12) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BOUNCE)

	# 5) Best score row
	var bt := create_tween()
	bt.set_speed_scale(speed_scale)
	bt.tween_interval(1.2)
	bt.tween_property(_best_score_row, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	if is_new_best:
		_animate_new_best_glow(speed_scale)

	# 6) Stat chips stagger slide-in
	var stat_values: Array = [
		state.lines_cleared, state.blocks_placed, state.max_combo, state.chains_triggered
	]
	for i in range(4):
		var chip: PanelContainer = _stat_chips[i]
		var val_label: Label = _stat_value_labels[i]
		var val: int = stat_values[i]
		var delay: float = 1.3 + i * 0.12

		var ct := create_tween()
		ct.set_speed_scale(speed_scale)
		ct.tween_interval(delay)
		ct.tween_property(chip, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)

		if val > 0:
			var vt := create_tween()
			vt.set_speed_scale(speed_scale)
			vt.tween_method(func(v: int) -> void:
				val_label.text = str(v)
			, 0, val, 0.35).set_ease(Tween.EASE_OUT).set_delay(delay + 0.1)

	# 7) Mission results
	_clear_missions()
	var btn_delay: float = 1.8
	if state.is_mission_run and not state.active_missions.is_empty():
		_show_mission_results(state.active_missions, speed_scale)
		btn_delay = 2.3

	# 8) Buttons stagger
	var btnw := create_tween()
	btnw.set_speed_scale(speed_scale)
	btnw.tween_interval(btn_delay)
	if show_ads:
		btnw.tween_property(_ad_section, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
		btnw.tween_interval(0.1)
	btnw.tween_property(_play_again_btn, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	btnw.tween_interval(0.08)
	btnw.tween_property(_home_btn, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)


func mark_ad_used() -> void:
	_used_ad_this_game = true
	_continue_btn.visible = false
	_double_btn.visible = false
	_ad_section.visible = false


func reset_ad_state() -> void:
	_used_ad_this_game = false


# ══════════════════════════════════════════════════════════════════
#  UI BUILDING (all code, no .tscn dependency on node paths)
# ══════════════════════════════════════════════════════════════════
func _build_ui() -> void:
	# Remove any children from .tscn (we rebuild everything)
	for child in get_children():
		child.queue_free()

	# ── Background gradient ──
	_bg_rect = ColorRect.new()
	_bg_rect.set_anchors_preset(PRESET_FULL_RECT)
	_bg_rect.color = BG_TOP
	add_child(_bg_rect)

	# Gradient overlay via a custom draw node
	var grad_overlay := Control.new()
	grad_overlay.set_anchors_preset(PRESET_FULL_RECT)
	grad_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grad_overlay.draw.connect(func() -> void:
		var rect := grad_overlay.get_rect()
		var verts := PackedVector2Array([
			Vector2(0, 0), Vector2(rect.size.x, 0),
			Vector2(rect.size.x, rect.size.y), Vector2(0, rect.size.y)
		])
		var cols := PackedColorArray([BG_TOP, BG_TOP, BG_BOTTOM, BG_BOTTOM])
		grad_overlay.draw_polygon(verts, cols)
	)
	add_child(grad_overlay)

	# ── Particle layer ──
	_particle_layer = Control.new()
	_particle_layer.set_anchors_preset(PRESET_FULL_RECT)
	_particle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_particle_layer.set_script(load("res://scripts/ui/particle_canvas.gd"))
	add_child(_particle_layer)

	# ── ScrollContainer ──
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_preset(PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_theme_constant_override("separation", 12)
	_scroll.add_child(_content)

	# Top spacer
	var top_sp := Control.new()
	top_sp.custom_minimum_size = Vector2(0, 30)
	_content.add_child(top_sp)

	# ── GAME OVER title ──
	_title_label = Label.new()
	_title_label.text = "GAME OVER"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _fredoka:
		_title_label.add_theme_font_override("font", _fredoka)
	_title_label.add_theme_font_size_override("font_size", 40)
	_title_label.add_theme_color_override("font_color", Color(0.75, 0.55, 1.0))
	_content.add_child(_title_label)

	# ── Hexagon grade badge ──
	var grade_center := CenterContainer.new()
	grade_center.custom_minimum_size = Vector2(0, 120)
	_content.add_child(grade_center)

	_grade_hex = Control.new()
	_grade_hex.custom_minimum_size = Vector2(110, 110)
	_grade_hex.set_meta("grade", "C")
	_grade_hex.pivot_offset = Vector2(55, 55)
	_grade_hex.draw.connect(_draw_hexagon_badge.bind(_grade_hex))
	grade_center.add_child(_grade_hex)

	_grade_label = Label.new()
	_grade_label.text = "C"
	_grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_grade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _fredoka:
		_grade_label.add_theme_font_override("font", _fredoka)
	_grade_label.add_theme_font_size_override("font_size", 44)
	_grade_label.add_theme_color_override("font_color", GRADE_COLORS["C"])
	_grade_label.set_anchors_preset(PRESET_FULL_RECT)
	_grade_hex.add_child(_grade_label)

	# ── Score ──
	_score_label = Label.new()
	_score_label.text = "0"
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _fredoka:
		_score_label.add_theme_font_override("font", _fredoka)
	_score_label.add_theme_font_size_override("font_size", 48)
	_score_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_score_label.pivot_offset = Vector2(165, 28)
	_content.add_child(_score_label)

	# ── Best score row ──
	_best_score_row = HBoxContainer.new()
	_best_score_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_best_score_row.add_theme_constant_override("separation", 6)
	_content.add_child(_best_score_row)

	var crown := Label.new()
	crown.text = "👑 BEST:"
	crown.add_theme_font_size_override("font_size", 14)
	crown.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	_best_score_row.add_child(crown)

	_best_val_label = Label.new()
	_best_val_label.text = "0"
	_best_val_label.add_theme_font_size_override("font_size", 14)
	_best_val_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	_best_score_row.add_child(_best_val_label)

	_new_best_label = Label.new()
	_new_best_label.text = "✨ NEW BEST!"
	_new_best_label.visible = false
	if _fredoka:
		_new_best_label.add_theme_font_override("font", _fredoka)
	_new_best_label.add_theme_font_size_override("font_size", 14)
	_new_best_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	_best_score_row.add_child(_new_best_label)

	# ── Stat chips (glass style) ──
	var stat_margin := MarginContainer.new()
	stat_margin.add_theme_constant_override("margin_left", 12)
	stat_margin.add_theme_constant_override("margin_right", 12)
	_content.add_child(stat_margin)
	var stat_row := HBoxContainer.new()
	stat_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_row.add_theme_constant_override("separation", 6)
	stat_margin.add_child(stat_row)

	for i in range(4):
		var meta: Dictionary = STAT_META[i]
		var chip := _create_stat_chip(meta["icon"], meta["label"], meta["color"])
		stat_row.add_child(chip["panel"])
		_stat_chips.append(chip["panel"])
		_stat_value_labels.append(chip["value_label"])

	# ── Mission container (filled dynamically) ──
	_mission_container = VBoxContainer.new()
	_mission_container.add_theme_constant_override("separation", 6)
	_content.add_child(_mission_container)

	# ── Ad section ──
	_ad_section = HBoxContainer.new()
	_ad_section.alignment = BoxContainer.ALIGNMENT_CENTER
	_ad_section.add_theme_constant_override("separation", 8)
	_content.add_child(_ad_section)

	_continue_btn = _make_button("▶️ Continue\nWATCH AD", _ad_btn_style())
	_continue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ad_section.add_child(_continue_btn)

	_double_btn = _make_button("✨ 2× Score\nWATCH AD", _ad_btn_style())
	_double_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ad_section.add_child(_double_btn)

	# ── Play Again button ──
	_play_again_btn = _make_button("PLAY AGAIN", _play_btn_style(), 18)
	_play_again_btn.custom_minimum_size = Vector2(280, 54)
	_content.add_child(_play_again_btn)

	# ── Home button ──
	_home_btn = _make_button("HOME", _home_btn_style(), 13)
	_home_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.25))
	_content.add_child(_home_btn)

	# Bottom spacer
	var bot_sp := Control.new()
	bot_sp.custom_minimum_size = Vector2(0, 20)
	_content.add_child(bot_sp)


func _connect_buttons() -> void:
	_play_again_btn.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		play_again_pressed.emit())
	_home_btn.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		go_home_pressed.emit())
	_continue_btn.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		continue_ad_pressed.emit())
	_double_btn.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		double_score_ad_pressed.emit())


# ══════════════════════════════════════════════════════════════════
#  DRAWING
# ══════════════════════════════════════════════════════════════════
func _draw_hexagon_badge(node: Control) -> void:
	var cx: float = node.size.x * 0.5
	var cy: float = node.size.y * 0.5
	var radius: float = min(cx, cy) - 4.0
	var grade: String = node.get_meta("grade", "C")

	# Outer glow
	var glow_col: Color
	match grade:
		"S": glow_col = Color(1, 0.84, 0, 0.35)
		"A": glow_col = Color(0.65, 0.55, 0.87, 0.3)
		"B": glow_col = Color(0.37, 0.73, 0.96, 0.25)
		_:   glow_col = Color(1, 0.55, 0.26, 0.2)

	for g in range(3, 0, -1):
		var glow_pts := _hex_points(cx, cy, radius + g * 4.0)
		var glow_colors := PackedColorArray()
		var alpha: float = glow_col.a * (1.0 - float(g) / 4.0)
		for _p in glow_pts:
			glow_colors.append(Color(glow_col.r, glow_col.g, glow_col.b, alpha))
		node.draw_polygon(glow_pts, glow_colors)

	# Fill — dark semi-transparent
	var fill_pts := _hex_points(cx, cy, radius)
	var fill_colors := PackedColorArray()
	for _p in fill_pts:
		fill_colors.append(Color(0.05, 0.03, 0.15, 0.85))
	node.draw_polygon(fill_pts, fill_colors)

	# Border — gold→pink gradient
	var border_pts := _hex_points(cx, cy, radius)
	for i in range(border_pts.size()):
		var j := (i + 1) % border_pts.size()
		var t: float = float(i) / float(border_pts.size())
		var col: Color = Color(1, 0.84, 0).lerp(Color(1, 0.42, 0.61), t)
		node.draw_line(border_pts[i], border_pts[j], col, 2.5, true)


func _hex_points(cx: float, cy: float, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(6):
		var angle: float = TAU * i / 6.0 - PI / 6.0  # flat-top hexagon
		pts.append(Vector2(cx + cos(angle) * r, cy + sin(angle) * r))
	return pts


# ══════════════════════════════════════════════════════════════════
#  STAT CHIP FACTORY
# ══════════════════════════════════════════════════════════════════
func _create_stat_chip(icon_text: String, label_text: String, accent: Color) -> Dictionary:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.12)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(accent.r, accent.g, accent.b, 0.25)
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var icon := Label.new()
	icon.text = icon_text
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 16)
	vbox.add_child(icon)

	var val_label := Label.new()
	val_label.text = "0"
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _fredoka:
		val_label.add_theme_font_override("font", _fredoka)
	val_label.add_theme_font_size_override("font_size", 22)
	val_label.add_theme_color_override("font_color", accent)
	vbox.add_child(val_label)

	var name_label := Label.new()
	name_label.text = label_text.to_upper()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	vbox.add_child(name_label)

	return { "panel": panel, "value_label": val_label }


# ══════════════════════════════════════════════════════════════════
#  MISSION RESULTS
# ══════════════════════════════════════════════════════════════════
func _clear_missions() -> void:
	for child in _mission_container.get_children():
		child.queue_free()
	_mission_container.modulate.a = 0.0


func _show_mission_results(missions: Array, speed_scale: float) -> void:
	_clear_missions()

	# Header
	var header := Label.new()
	header.text = "⭐ MISSIONS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _fredoka:
		header.add_theme_font_override("font", _fredoka)
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(1, 0.85, 0.24))
	_mission_container.add_child(header)

	var total_xp: int = 0
	var shown := 0
	for m in missions:
		if shown >= 3:
			break
		shown += 1
		var mission: MissionSystem.Mission = m
		var card := _build_mission_card(mission)
		_mission_container.add_child(card)
		if mission.completed:
			total_xp += mission.xp_reward

	if total_xp > 0:
		var total_label := Label.new()
		total_label.text = "Mission XP: +%d" % total_xp
		total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _fredoka:
			total_label.add_theme_font_override("font", _fredoka)
		total_label.add_theme_font_size_override("font_size", 14)
		total_label.add_theme_color_override("font_color", Color(1, 0.85, 0.24))
		_mission_container.add_child(total_label)

	var tw := create_tween()
	tw.set_speed_scale(speed_scale)
	tw.tween_interval(1.8)
	tw.tween_property(_mission_container, "modulate:a", 1.0, 0.35).set_ease(Tween.EASE_OUT)


func _build_mission_card(mission: MissionSystem.Mission) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.04)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(1, 1, 1, 0.06)
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Row: icon + desc + progress
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vbox.add_child(row)

	var icon := Label.new()
	if mission.completed:
		icon.text = "✅"
	else:
		icon.text = "⬜"
	icon.add_theme_font_size_override("font_size", 14)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var desc := Label.new()
	desc.text = mission.description
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(desc)

	var progress_text := Label.new()
	if mission.completed:
		progress_text.text = "+%d XP" % mission.xp_reward
		progress_text.add_theme_color_override("font_color", Color(1, 0.85, 0.24))
	else:
		progress_text.text = "%d/%d" % [mission.progress, mission.target]
		progress_text.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
	progress_text.add_theme_font_size_override("font_size", 11)
	progress_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(progress_text)

	# Progress bar (for incomplete missions)
	if not mission.completed and mission.target > 0:
		var bar_bg := ColorRect.new()
		bar_bg.custom_minimum_size = Vector2(0, 3)
		bar_bg.color = Color(1, 1, 1, 0.08)
		vbox.add_child(bar_bg)

		var progress_ratio: float = clampf(float(mission.progress) / float(mission.target), 0.0, 1.0)
		var bar_fill := ColorRect.new()
		bar_fill.custom_minimum_size = Vector2(progress_ratio * 200.0, 3)
		bar_fill.color = Color(0.61, 0.45, 0.81, 0.6)
		bar_fill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		vbox.add_child(bar_fill)

	return card


# ══════════════════════════════════════════════════════════════════
#  BUTTON FACTORIES
# ══════════════════════════════════════════════════════════════════
func _make_button(text: String, style: StyleBoxFlat, font_size: int = 12) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	if _fredoka and font_size >= 16:
		btn.add_theme_font_override("font", _fredoka)
	return btn


func _play_btn_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.42, 0.31, 0.7, 1)
	s.corner_radius_top_left = 16
	s.corner_radius_top_right = 16
	s.corner_radius_bottom_left = 16
	s.corner_radius_bottom_right = 16
	s.content_margin_left = 24.0
	s.content_margin_top = 16.0
	s.content_margin_right = 24.0
	s.content_margin_bottom = 16.0
	s.shadow_color = Color(0.42, 0.31, 0.7, 0.4)
	s.shadow_size = 14
	return s


func _home_btn_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.corner_radius_top_left = 12
	s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	s.content_margin_top = 6.0
	s.content_margin_bottom = 6.0
	return s


func _ad_btn_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 1, 1, 0.04)
	s.corner_radius_top_left = 14
	s.corner_radius_top_right = 14
	s.corner_radius_bottom_left = 14
	s.corner_radius_bottom_right = 14
	s.content_margin_left = 10.0
	s.content_margin_top = 12.0
	s.content_margin_right = 10.0
	s.content_margin_bottom = 12.0
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = Color(1, 1, 1, 0.08)
	return s


# ══════════════════════════════════════════════════════════════════
#  ANIMATIONS
# ══════════════════════════════════════════════════════════════════
func _get_grade(score: int) -> String:
	if score >= GRADE_THRESHOLDS["S"]:
		return "S"
	elif score >= GRADE_THRESHOLDS["A"]:
		return "A"
	elif score >= GRADE_THRESHOLDS["B"]:
		return "B"
	return "C"


func _start_title_glow(speed_scale: float) -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	_glow_tween = create_tween()
	_glow_tween.set_speed_scale(speed_scale)
	_glow_tween.set_loops()
	_glow_tween.tween_property(_title_label, "modulate:a", 0.55, 1.2) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_glow_tween.tween_property(_title_label, "modulate:a", 1.0, 1.2) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _animate_new_best_glow(speed_scale: float) -> void:
	var tw := create_tween()
	tw.set_speed_scale(speed_scale)
	tw.set_loops()
	tw.tween_property(_new_best_label, "modulate:a", 0.6, 0.8) \
		.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_new_best_label, "modulate:a", 1.0, 0.8) \
		.set_ease(Tween.EASE_IN_OUT)


# ══════════════════════════════════════════════════════════════════
#  PARTICLES
# ══════════════════════════════════════════════════════════════════
func _update_particles(delta: float) -> void:
	_particle_timer += delta
	if _particle_timer > 0.18:
		_particle_timer = 0.0
		_spawn_particle()

	var to_remove: Array[int] = []
	for i in range(_particles.size()):
		_particles[i]["y"] -= _particles[i]["speed"] * delta
		_particles[i]["x"] += sin(_particles[i]["y"] * 0.02) * delta * 8.0  # gentle sway
		_particles[i]["alpha"] -= delta * 0.2
		if _particles[i]["alpha"] <= 0 or _particles[i]["y"] < -20:
			to_remove.append(i)

	for i in range(to_remove.size() - 1, -1, -1):
		_particles.remove_at(to_remove[i])

	_particle_layer.set("particles", _particles)
	_particle_layer.queue_redraw()


func _spawn_particle() -> void:
	if _particles.size() > 25:
		return
	var p := {
		"x": randf_range(0, size.x),
		"y": size.y + randf_range(5, 25),
		"size": randf_range(4.0, 12.0),
		"speed": randf_range(28.0, 60.0),
		"color": PARTICLE_COLORS[randi() % PARTICLE_COLORS.size()],
		"alpha": randf_range(0.15, 0.40),
	}
	_particles.append(p)
