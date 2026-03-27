extends Control
## Game Over Screen — Design D2
## Dark purple/navy gradient, hexagon grade badge, glass stat chips,
## mission cards, rising color particles, score counting animation.

signal play_again_pressed()
signal go_home_pressed()
signal continue_ad_pressed()
signal double_score_ad_pressed()

# Preload to ensure class_name resolution
const NearMissAnalyzerScript := preload("res://scripts/systems/near_miss_analyzer.gd")

# ── Constants ──────────────────────────────────────────────────────
const GRADE_THRESHOLDS := { "S+": 15000, "S": 10000, "A+": 7000, "A": 5000, "B+": 3000, "B": 2000, "C+": 1000 }
const GRADE_COLORS := {
	"S+": Color(1.0, 0.92, 0.2),
	"S": Color(1.0, 0.84, 0.0),
	"A+": Color(0.75, 0.62, 0.92),
	"A": Color(0.65, 0.55, 0.87),
	"B+": Color(0.47, 0.80, 1.0),
	"B": Color(0.37, 0.73, 0.96),
	"C+": Color(1.0, 0.65, 0.36),
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
var _next_grade_label: Label
var _score_diff_label: Label
var _streak_label: Label
var _highlight_container: VBoxContainer
var _near_miss_hint: Label  # "What could have been" message


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
	# Smaller font for 2-char grades like S+, A+, etc.
	if grade_str.length() > 1:
		_grade_label.add_theme_font_size_override("font_size", 34)
	else:
		_grade_label.add_theme_font_size_override("font_size", 44)
	_grade_label.add_theme_color_override("font_color", GRADE_COLORS[grade_str])
	_grade_hex.set_meta("grade", grade_str)
	_grade_hex.queue_redraw()

	# Next grade hint
	var next_info: Dictionary = _get_next_grade_info(state.score)
	if not next_info.is_empty():
		_next_grade_label.text = "%s 등급까지 %s점!" % [next_info["grade"], FormatUtils.format_number(next_info["gap"])]
		_next_grade_label.visible = true
	else:
		_next_grade_label.text = "최고 등급 달성! 🏆"
		_next_grade_label.visible = true

	# Score diff vs previous game
	var prev_score: int = SaveManager.get_previous_score()
	if prev_score > 0:
		var diff: int = state.score - prev_score
		if diff > 0:
			_score_diff_label.text = "+%s점 향상!" % FormatUtils.format_number(diff)
			_score_diff_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
		elif diff < 0:
			_score_diff_label.text = "%s점" % FormatUtils.format_number(diff)
			_score_diff_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 0.6))
		else:
			_score_diff_label.text = "동점!"
			_score_diff_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
		_score_diff_label.visible = true
	else:
		_score_diff_label.visible = false

	# Play streak
	var play_streak: int = SaveManager.get_play_streak()
	if SaveManager.is_streak_alive() and play_streak >= 2:
		_streak_label.text = "🔥 x%d 스트릭 유지!" % play_streak
		_streak_label.visible = true
	else:
		_streak_label.visible = false

	# Near-miss hint (what could have been)
	if state.near_miss_result != null:
		_near_miss_hint.text = NearMissAnalyzerScript.get_near_miss_message(state.near_miss_result)
		_near_miss_hint.visible = true
	else:
		_near_miss_hint.visible = false

	# Initial hidden states
	_grade_hex.modulate.a = 0.0
	_grade_hex.scale = Vector2(0.3, 0.3)
	_score_label.modulate.a = 0.0
	_best_score_row.modulate.a = 0.0
	_next_grade_label.modulate.a = 0.0
	_score_diff_label.modulate.a = 0.0
	_streak_label.modulate.a = 0.0
	_near_miss_hint.modulate.a = 0.0
	for chip in _stat_chips:
		chip.modulate.a = 0.0
	_highlight_container.modulate.a = 0.0
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

	# 2b) Near-miss hint (if present)
	if _near_miss_hint.visible:
		var nmt := create_tween()
		nmt.set_speed_scale(speed_scale)
		nmt.tween_interval(0.2)
		nmt.tween_property(_near_miss_hint, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)

	# 3) Grade hexagon bounce
	var gt := create_tween()
	gt.set_speed_scale(speed_scale)
	gt.tween_interval(0.3)
	gt.tween_property(_grade_hex, "modulate:a", 1.0, 0.25)
	gt.parallel().tween_property(_grade_hex, "scale", Vector2(1.15, 1.15), 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	gt.tween_property(_grade_hex, "scale", Vector2(1.0, 1.0), 0.15) \
		.set_ease(Tween.EASE_IN_OUT)

	# 4) Score count-up — dramatic pacing: fast bulk, slow finish
	var st := create_tween()
	st.set_speed_scale(speed_scale)
	st.tween_interval(0.35)
	st.tween_property(_score_label, "modulate:a", 1.0, 0.15)
	if state.score > 0:
		_animate_score(st, state.score)
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

	# 5b) Next grade + score diff + streak (stagger after best score)
	var info_delay: float = 1.3
	if _next_grade_label.visible:
		var ngt := create_tween()
		ngt.set_speed_scale(speed_scale)
		ngt.tween_interval(info_delay)
		ngt.tween_property(_next_grade_label, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
		info_delay += 0.1
	if _score_diff_label.visible:
		var sdt := create_tween()
		sdt.set_speed_scale(speed_scale)
		sdt.tween_interval(info_delay)
		sdt.tween_property(_score_diff_label, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
		info_delay += 0.1
	if _streak_label.visible:
		var slt := create_tween()
		slt.set_speed_scale(speed_scale)
		slt.tween_interval(info_delay)
		slt.tween_property(_streak_label, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
		# Streak bounce
		slt.tween_property(_streak_label, "scale", Vector2(1.15, 1.15), 0.08).set_ease(Tween.EASE_OUT)
		slt.tween_property(_streak_label, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_IN_OUT)

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

	# 6b) Highlights section
	_build_highlights(state, speed_scale)

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
	# Play Again button bounce entrance
	btnw.tween_property(_play_again_btn, "scale", Vector2(1.08, 1.08), 0.1) \
		.set_ease(Tween.EASE_OUT)
	btnw.tween_property(_play_again_btn, "scale", Vector2(1.0, 1.0), 0.12) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	btnw.tween_callback(_start_play_again_pulse.bind(speed_scale))
	btnw.tween_interval(0.08)
	btnw.tween_property(_home_btn, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)


func mark_ad_used() -> void:
	_used_ad_this_game = true
	_continue_btn.visible = false
	_double_btn.visible = false
	_ad_section.visible = false


## 타임어택 모드 전용 결과 화면
func show_time_attack_result(state: GameState) -> void:
	# 기본 show_result 호출 (등급, 점수 등)
	show_result(state)

	# 타이틀을 "TIME'S UP"으로 변경
	_title_label.text = "TIME'S UP!"
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))  # 빨간-주황


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

	# ── Content container (no scroll — fits on one screen) ──
	_content = VBoxContainer.new()
	_content.set_anchors_preset(PRESET_FULL_RECT)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_theme_constant_override("separation", 8)  # tighter spacing
	add_child(_content)

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

	# ── Near-miss hint (what could have been) ──
	_near_miss_hint = Label.new()
	_near_miss_hint.text = ""
	_near_miss_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _fredoka:
		_near_miss_hint.add_theme_font_override("font", _fredoka)
	_near_miss_hint.add_theme_font_size_override("font_size", 16)
	_near_miss_hint.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	_content.add_child(_near_miss_hint)

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

	# ── Next grade hint ──
	_next_grade_label = Label.new()
	_next_grade_label.text = ""
	_next_grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_next_grade_label.add_theme_font_size_override("font_size", 13)
	_next_grade_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	_content.add_child(_next_grade_label)

	# ── Score diff vs previous game ──
	_score_diff_label = Label.new()
	_score_diff_label.text = ""
	_score_diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _fredoka:
		_score_diff_label.add_theme_font_override("font", _fredoka)
	_score_diff_label.add_theme_font_size_override("font_size", 14)
	_content.add_child(_score_diff_label)

	# ── Streak display ──
	_streak_label = Label.new()
	_streak_label.text = ""
	_streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _fredoka:
		_streak_label.add_theme_font_override("font", _fredoka)
	_streak_label.add_theme_font_size_override("font_size", 15)
	_streak_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	_streak_label.pivot_offset = Vector2(165, 10)
	_content.add_child(_streak_label)

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

	# ── Highlight section ──
	_highlight_container = VBoxContainer.new()
	_highlight_container.add_theme_constant_override("separation", 4)
	_content.add_child(_highlight_container)

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

	# ── Play Again button (large, prominent) ──
	_play_again_btn = _make_button("▶  PLAY AGAIN", _play_btn_style(), 22)
	_play_again_btn.custom_minimum_size = Vector2(320, 68)
	_content.add_child(_play_again_btn)

	# ── Home button (small, subtle) ──
	_home_btn = _make_button("HOME", _home_btn_style(), 12)
	_home_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.2))
	_home_btn.custom_minimum_size = Vector2(100, 32)
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
func _build_highlights(state: GameState, speed_scale: float) -> void:
	# Clear previous highlights
	for child in _highlight_container.get_children():
		child.queue_free()

	# Only show if there's something interesting
	var has_content := false

	# Header
	var header := Label.new()
	header.text = "🏆 이번 판 하이라이트"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _fredoka:
		header.add_theme_font_override("font", _fredoka)
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.47, 0.80, 1.0))
	_highlight_container.add_child(header)

	# Highlight items margin
	var highlight_margin := MarginContainer.new()
	highlight_margin.add_theme_constant_override("margin_left", 24)
	highlight_margin.add_theme_constant_override("margin_right", 24)
	_highlight_container.add_child(highlight_margin)

	var items_vbox := VBoxContainer.new()
	items_vbox.add_theme_constant_override("separation", 6)
	highlight_margin.add_child(items_vbox)

	# Max combo
	if state.max_combo >= 2:
		has_content = true
		var combo_item := _create_highlight_item(
			"🔥", "최대 콤보", "x%d" % state.max_combo, Color(1.0, 0.55, 0.26))
		items_vbox.add_child(combo_item)

	# Total cleared lines
	if state.lines_cleared > 0:
		has_content = true
		var lines_item := _create_highlight_item(
			"📏", "총 클리어 라인", "%d줄" % state.lines_cleared, Color(0.30, 0.59, 1.0))
		items_vbox.add_child(lines_item)

	# Best consecutive clears
	if state.best_consecutive_clears >= 2:
		has_content = true
		var consec_item := _create_highlight_item(
			"⚡", "최고 연속 클리어", "%d연속" % state.best_consecutive_clears, Color(0.61, 0.45, 0.81))
		items_vbox.add_child(consec_item)

	# Score comparison vs previous game
	var prev_score: int = SaveManager.get_previous_score()
	if prev_score > 0:
		var diff: int = state.score - prev_score
		if diff > 0:
			has_content = true
			var diff_item := _create_highlight_item(
				"📈", "이전 판 대비", "+%s점" % FormatUtils.format_number(diff), Color(0.3, 0.9, 0.4))
			items_vbox.add_child(diff_item)
		elif diff == 0:
			has_content = true
			var diff_item := _create_highlight_item(
				"🤝", "이전 판 대비", "동점!", Color(1, 1, 1, 0.5))
			items_vbox.add_child(diff_item)

	# Near-miss analysis (what could have been)
	if state.near_miss_result != null:
		var near_miss_details: Array = NearMissAnalyzerScript.get_near_miss_details(state.near_miss_result)
		for detail in near_miss_details:
			has_content = true
			var nm_item := _create_highlight_item(
				detail.get("icon", "💭"),
				detail.get("text", ""),
				detail.get("subtext", ""),
				Color(1.0, 0.6, 0.3))
			items_vbox.add_child(nm_item)

	if not has_content:
		# Remove header if nothing interesting
		for child in _highlight_container.get_children():
			child.queue_free()
		return

	# Animate
	_highlight_container.modulate.a = 0.0
	var ht := create_tween()
	ht.set_speed_scale(speed_scale)
	ht.tween_interval(1.7)
	ht.tween_property(_highlight_container, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)


func _create_highlight_item(icon_text: String, label_text: String, value_text: String, accent: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var icon := Label.new()
	icon.text = icon_text
	icon.add_theme_font_size_override("font_size", 14)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var desc := Label.new()
	desc.text = label_text
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(desc)

	var val := Label.new()
	val.text = value_text
	if _fredoka:
		val.add_theme_font_override("font", _fredoka)
	val.add_theme_font_size_override("font_size", 15)
	val.add_theme_color_override("font_color", accent)
	val.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(val)

	return row


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
	s.bg_color = Color(0.45, 0.28, 0.85, 1)
	s.corner_radius_top_left = 20
	s.corner_radius_top_right = 20
	s.corner_radius_bottom_left = 20
	s.corner_radius_bottom_right = 20
	s.content_margin_left = 32.0
	s.content_margin_top = 18.0
	s.content_margin_right = 32.0
	s.content_margin_bottom = 18.0
	s.shadow_color = Color(0.45, 0.28, 0.85, 0.5)
	s.shadow_size = 18
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.border_color = Color(0.7, 0.55, 1.0, 0.4)
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
	if score >= GRADE_THRESHOLDS["S+"]:
		return "S+"
	elif score >= GRADE_THRESHOLDS["S"]:
		return "S"
	elif score >= GRADE_THRESHOLDS["A+"]:
		return "A+"
	elif score >= GRADE_THRESHOLDS["A"]:
		return "A"
	elif score >= GRADE_THRESHOLDS["B+"]:
		return "B+"
	elif score >= GRADE_THRESHOLDS["B"]:
		return "B"
	elif score >= GRADE_THRESHOLDS["C+"]:
		return "C+"
	return "C"


## Get the next grade threshold above the current score
func _get_next_grade_info(score: int) -> Dictionary:
	var ordered_grades: Array = ["C+", "B", "B+", "A", "A+", "S", "S+"]
	var ordered_thresholds: Array = [1000, 2000, 3000, 5000, 7000, 10000, 15000]
	for i in ordered_grades.size():
		if score < ordered_thresholds[i]:
			return {"grade": ordered_grades[i], "threshold": ordered_thresholds[i], "gap": ordered_thresholds[i] - score}
	return {}


## Dramatic score count-up: fast for the first 90%, slow for the last 10%.
## Bigger scores count faster overall so the animation doesn't drag.
func _animate_score(tween: Tween, target: int) -> void:
	var threshold := int(target * 0.9)
	# Phase 1: Fast count — 90% of score in ~0.5s (logarithmic speed for big scores)
	var fast_duration: float = 0.5
	if threshold > 0:
		tween.tween_method(func(v: int) -> void:
			_score_label.text = FormatUtils.format_number(v)
		, 0, threshold, fast_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Phase 2: Slow dramatic finish — last 10% in 0.6s
	var slow_duration: float = 0.6
	tween.tween_method(func(v: int) -> void:
		_score_label.text = FormatUtils.format_number(v)
	, threshold, target, slow_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


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


var _play_again_pulse_tween: Tween

func _start_play_again_pulse(speed_scale: float) -> void:
	if _play_again_pulse_tween and _play_again_pulse_tween.is_valid():
		_play_again_pulse_tween.kill()
	# Set pivot for center-based scaling
	_play_again_btn.pivot_offset = _play_again_btn.size / 2.0
	_play_again_pulse_tween = create_tween()
	_play_again_pulse_tween.set_speed_scale(speed_scale)
	_play_again_pulse_tween.set_loops()
	_play_again_pulse_tween.tween_property(_play_again_btn, "scale", Vector2(1.04, 1.04), 0.8) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_play_again_pulse_tween.tween_property(_play_again_btn, "scale", Vector2(1.0, 1.0), 0.8) \
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

func _show_play_again_hint() -> void:
	var hint := Label.new()
	var messages := [
		"조금만 더 하면 됐는데!",
		"이번엔 더 잘할 수 있어!",
		"한판만 더?",
		"기록 갱신 도전!",
	]
	hint.text = messages[randi() % messages.size()]
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0, 0.7))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, size.y - 180)
	hint.size = Vector2(size.x, 24)
	add_child(hint)

	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(hint, "modulate:a", 0.0, 0.5)
	tw.tween_callback(hint.queue_free)
