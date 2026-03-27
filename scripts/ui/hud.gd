extends VBoxContainer

@onready var score_label: Label = $TopBar/ScoreDisplay/ScoreValue
@onready var level_label: Label = $TopBar/LevelBadge/LevelContent/LevelValue
@onready var best_label: Label = $InfoRow/BestChip/BestContent/BestValue
@onready var xp_bar: Control = $InfoRow/XPBar

var _prev_combo := 0
var _combo_tween: Tween
var _combo_badge: PanelContainer = null  # Combo badge in InfoRow
var _combo_label: Label = null
var _combo_glow: Control = null
var _combo_hint_label: Label = null
var _combo_dots: HBoxContainer = null
var _combo_hint_tween: Tween = null
var _displayed_score: int = 0
var _score_tween: Tween
var _color_flash_tween: Tween
var _new_best_shown := false
var _new_best_label: Label
var _new_best_pulse_tween: Tween = null  # perf: track loop tween for cleanup
var _current_high_score: int = 0

# Timer (Time Attack)
var _timer_label: Label = null
var _timer_visible := false
var _timer_pulse_tween: Tween = null
var _timer_was_urgent := false


func _ready() -> void:
	_create_timer_label()
	_create_combo_badge()


func _create_timer_label() -> void:
	_timer_label = Label.new()
	_timer_label.text = "60"
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var fredoka: Font = load("res://assets/fonts/Fredoka-Bold.ttf")
	if fredoka:
		_timer_label.add_theme_font_override("font", fredoka)
	_timer_label.add_theme_font_size_override("font_size", 28)
	_timer_label.add_theme_color_override("font_color", Color.WHITE)
	_timer_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	_timer_label.add_theme_constant_override("shadow_offset_x", 0)
	_timer_label.add_theme_constant_override("shadow_offset_y", 2)
	_timer_label.visible = false
	# Insert at top of HUD, before TopBar
	var top_bar := get_node_or_null("TopBar")
	if top_bar:
		add_child(_timer_label)
		move_child(_timer_label, top_bar.get_index())
	else:
		add_child(_timer_label)


func show_timer(visible_flag: bool) -> void:
	_timer_visible = visible_flag
	if _timer_label:
		_timer_label.visible = visible_flag
	if not visible_flag:
		_timer_was_urgent = false
		if _timer_pulse_tween and _timer_pulse_tween.is_valid():
			_timer_pulse_tween.kill()
			_timer_pulse_tween = null
		if _timer_label:
			_timer_label.modulate.a = 1.0
			_timer_label.add_theme_color_override("font_color", Color.WHITE)


func update_timer(time_remaining: float) -> void:
	if not _timer_label:
		return
	var secs := ceili(maxf(time_remaining, 0.0))
	_timer_label.text = str(secs)

	# Urgent state: <=10 seconds → red + pulse
	var is_urgent := secs <= 10
	if is_urgent and not _timer_was_urgent:
		_timer_was_urgent = true
		_timer_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
		_timer_label.add_theme_font_size_override("font_size", 32)
		if _timer_pulse_tween and _timer_pulse_tween.is_valid():
			_timer_pulse_tween.kill()
		_timer_pulse_tween = create_tween().set_loops()
		_timer_pulse_tween.tween_property(_timer_label, "modulate:a", 0.4, 0.3) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_timer_pulse_tween.tween_property(_timer_label, "modulate:a", 1.0, 0.3) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	elif not is_urgent and _timer_was_urgent:
		_timer_was_urgent = false
		_timer_label.add_theme_color_override("font_color", Color.WHITE)
		_timer_label.add_theme_font_size_override("font_size", 28)
		if _timer_pulse_tween and _timer_pulse_tween.is_valid():
			_timer_pulse_tween.kill()
			_timer_pulse_tween = null
		_timer_label.modulate.a = 1.0


func update_from_state(state: GameState) -> void:
	_current_high_score = state.high_score
	_animate_score(state.score)
	level_label.text = "%02d" % state.level
	best_label.text = _format_number(state.high_score)
	_update_combo(state.combo)
	_update_level_progress(state.lines_cleared, state.level)
	_check_new_best(state.score)


func _update_level_progress(lines_cleared: int, current_level: int) -> void:
	# Sum lines needed to reach current level
	var lines_at_current := 0
	for lv in range(1, current_level):
		lines_at_current += GameConstants.lines_for_next_level(lv)
	# Lines needed to advance from current level
	var lines_to_next := GameConstants.lines_for_next_level(current_level)
	var progress := lines_cleared - lines_at_current
	if lines_to_next > 0:
		xp_bar.set_progress(clampf(float(progress) / float(lines_to_next), 0.0, 1.0))
	else:
		xp_bar.set_progress(0.0)


func _animate_score(target_score: int) -> void:
	if target_score == _displayed_score:
		return

	# Kill any existing score tween before starting a new one
	if _score_tween and _score_tween.is_valid():
		_score_tween.kill()

	var score_increased := target_score > _displayed_score

	_score_tween = create_tween()
	_score_tween.tween_method(_set_score_display, _displayed_score, target_score, 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Scale bounce + color flash when score increases
	if score_increased:
		score_label.pivot_offset = score_label.size / 2.0
		_score_tween.parallel().tween_property(score_label, "scale",
			Vector2(1.15, 1.15), 0.075) \
			.set_ease(Tween.EASE_OUT)
		_score_tween.tween_property(score_label, "scale",
			Vector2.ONE, 0.075) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		# Gold color flash
		if _color_flash_tween and _color_flash_tween.is_valid():
			_color_flash_tween.kill()
		_color_flash_tween = create_tween()
		score_label.add_theme_color_override("font_color", Color("#FFD93D"))
		_color_flash_tween.tween_property(score_label, "theme_override_colors/font_color",
			Color.WHITE, 0.3).set_ease(Tween.EASE_OUT)


func _set_score_display(value: int) -> void:
	_displayed_score = value
	score_label.text = _format_number(value)


func _format_number(value: int) -> String:
	var s := str(value)
	if s.length() <= 3:
		return s
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "," + result
	return result


func _check_new_best(current_score: int) -> void:
	if _new_best_shown:
		return
	if _current_high_score <= 0:
		return
	if current_score <= _current_high_score:
		return
	_new_best_shown = true
	_show_new_best_label()


func _show_new_best_label() -> void:
	var score_display := score_label.get_parent()
	if score_display == null:
		return
	_new_best_label = Label.new()
	_new_best_label.text = "NEW BEST!"
	_new_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var fredoka: Font = score_label.get_theme_font("font")
	if fredoka:
		_new_best_label.add_theme_font_override("font", fredoka)
	_new_best_label.add_theme_font_size_override("font_size", 14)
	_new_best_label.add_theme_color_override("font_color", Color("#FFD93D"))
	_new_best_label.modulate.a = 0.7
	_new_best_label.scale = Vector2.ZERO
	score_display.add_child(_new_best_label)

	# Pop-in animation (defer one frame so size is computed for pivot)
	await get_tree().process_frame
	if not is_instance_valid(_new_best_label):
		return
	_new_best_label.pivot_offset = _new_best_label.size / 2.0
	var tw := create_tween()
	tw.tween_property(_new_best_label, "scale", Vector2(1.1, 1.1), 0.12) \
		.set_ease(Tween.EASE_OUT)
	tw.tween_property(_new_best_label, "scale", Vector2.ONE, 0.08) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Start pulse loop after pop-in
	tw.tween_callback(_start_new_best_pulse)


func _start_new_best_pulse() -> void:
	if not is_instance_valid(_new_best_label):
		return
	if _new_best_pulse_tween and _new_best_pulse_tween.is_valid():
		_new_best_pulse_tween.kill()
	_new_best_pulse_tween = create_tween().set_loops()
	_new_best_pulse_tween.tween_property(_new_best_label, "modulate:a", 1.0, 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_new_best_pulse_tween.tween_property(_new_best_label, "modulate:a", 0.7, 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func reset_new_best() -> void:
	_new_best_shown = false
	if _new_best_pulse_tween and _new_best_pulse_tween.is_valid():
		_new_best_pulse_tween.kill()
		_new_best_pulse_tween = null
	if is_instance_valid(_new_best_label):
		_new_best_label.queue_free()
		_new_best_label = null


const COMBO_HINTS: Array[String] = [
	"라인 클리어로 콤보 연장!",
	"계속 클리어해!",
	"콤보 이어가자!",
	"멈추지 마!",
]


func _update_combo(combo: int) -> void:
	# Update combo badge visibility and animation
	if _combo_badge == null:
		_prev_combo = combo
		return

	var was_zero := _prev_combo < 2
	var is_active := combo >= 2

	# Update combo badge
	if is_active:
		_combo_label.text = "x%d COMBO" % combo
		# Color based on combo level
		var combo_color: Color
		match combo:
			2: combo_color = Color(1.0, 0.95, 0.3)
			3: combo_color = Color(1.0, 0.7, 0.2)
			4: combo_color = Color(1.0, 0.4, 0.3)
			5: combo_color = Color(1.0, 0.2, 0.4)
			_: combo_color = Color(1.0, 0.15, 0.4)
		_combo_label.add_theme_color_override("font_color", combo_color)

		# Update combo dots
		_update_combo_dots(combo, combo_color)

		# Update hint label
		_update_combo_hint(combo, combo_color)

		# Show badge with animation if newly active
		if was_zero:
			_combo_badge.modulate.a = 0.0
			_combo_badge.scale = Vector2(0.5, 0.5)
			if _combo_tween and _combo_tween.is_valid():
				_combo_tween.kill()
			_combo_tween = create_tween()
			_combo_tween.tween_property(_combo_badge, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
			_combo_tween.parallel().tween_property(_combo_badge, "scale", Vector2(1.1, 1.1), 0.15).set_ease(Tween.EASE_OUT)
			_combo_tween.tween_property(_combo_badge, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_IN_OUT)
			# Start glow pulse
			_start_combo_glow(combo_color)
		elif combo > _prev_combo:
			# Combo increased - bounce animation
			if _combo_tween and _combo_tween.is_valid():
				_combo_tween.kill()
			_combo_tween = create_tween()
			_combo_tween.tween_property(_combo_badge, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT)
			_combo_tween.tween_property(_combo_badge, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_IN_OUT)
	else:
		# Hide badge when combo ends
		if not was_zero:
			if _combo_tween and _combo_tween.is_valid():
				_combo_tween.kill()
			_combo_tween = create_tween()
			_combo_tween.tween_property(_combo_badge, "modulate:a", 0.0, 0.2)
			_stop_combo_glow()
			_hide_combo_hint()

	_prev_combo = combo


func _update_combo_dots(combo: int, color: Color) -> void:
	if _combo_dots == null:
		return
	var dot_count: int = mini(combo - 1, 5)  # combo 2 = 1 dot, combo 6+ = 5 dots
	for i in range(_combo_dots.get_child_count()):
		var dot: ColorRect = _combo_dots.get_child(i)
		if i < dot_count:
			dot.color = Color(color.r, color.g, color.b, 0.9)
		else:
			dot.color = Color(1.0, 1.0, 1.0, 0.2)


func _update_combo_hint(combo: int, color: Color) -> void:
	if _combo_hint_label == null:
		return
	var idx: int = (combo - 2) % COMBO_HINTS.size()
	_combo_hint_label.text = COMBO_HINTS[idx]
	_combo_hint_label.add_theme_color_override("font_color", Color(color.r, color.g, color.b, 0.8))
	# Fade in hint
	if _combo_hint_tween and _combo_hint_tween.is_valid():
		_combo_hint_tween.kill()
	_combo_hint_tween = create_tween()
	_combo_hint_tween.tween_property(_combo_hint_label, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_OUT)


func _hide_combo_hint() -> void:
	if _combo_hint_label == null:
		return
	if _combo_hint_tween and _combo_hint_tween.is_valid():
		_combo_hint_tween.kill()
	_combo_hint_tween = create_tween()
	_combo_hint_tween.tween_property(_combo_hint_label, "modulate:a", 0.0, 0.2)


func _create_combo_badge() -> void:
	_combo_badge = PanelContainer.new()
	_combo_badge.modulate.a = 0.0
	_combo_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Style the badge
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.25, 0.9)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.6, 0.3, 0.6)
	_combo_badge.add_theme_stylebox_override("panel", style)

	# Glow effect behind badge
	_combo_glow = Control.new()
	_combo_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_glow.set_anchors_preset(PRESET_FULL_RECT)
	_combo_glow.z_index = -1
	_combo_glow.modulate.a = 0.0
	_combo_glow.draw.connect(func():
		var rect := _combo_glow.get_rect()
		var center := rect.size / 2.0
		var glow_color: Color = _combo_glow.get_meta("glow_color", Color(1.0, 0.6, 0.3, 0.3))
		for i in range(3):
			var alpha := glow_color.a * (1.0 - float(i) / 3.0)
			_combo_glow.draw_circle(center, 30.0 + i * 10.0, Color(glow_color.r, glow_color.g, glow_color.b, alpha))
	)
	_combo_badge.add_child(_combo_glow)

	# Inner VBox for label + hint + dots
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	_combo_badge.add_child(vbox)

	# Combo label
	_combo_label = Label.new()
	_combo_label.text = "x2 COMBO"
	var fredoka: Font = load("res://assets/fonts/Fredoka-Bold.ttf")
	if fredoka:
		_combo_label.add_theme_font_override("font", fredoka)
	_combo_label.add_theme_font_size_override("font_size", 16)
	_combo_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.3))
	_combo_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.2))
	_combo_label.add_theme_constant_override("outline_size", 2)
	vbox.add_child(_combo_label)

	# Combo dots (hit counter)
	_combo_dots = HBoxContainer.new()
	_combo_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	_combo_dots.add_theme_constant_override("separation", 4)
	for i in range(5):
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(6, 6)
		dot.color = Color(1.0, 1.0, 1.0, 0.2)
		_combo_dots.add_child(dot)
	vbox.add_child(_combo_dots)

	# Combo hint label
	_combo_hint_label = Label.new()
	_combo_hint_label.text = ""
	_combo_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if fredoka:
		_combo_hint_label.add_theme_font_override("font", fredoka)
	_combo_hint_label.add_theme_font_size_override("font_size", 10)
	_combo_hint_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 0.8))
	_combo_hint_label.modulate.a = 0.0
	vbox.add_child(_combo_hint_label)

	# Set pivot for center-based scaling
	_combo_badge.pivot_offset = Vector2(40, 14)

	# Insert into InfoRow
	var info_row := get_node_or_null("InfoRow")
	if info_row:
		# Insert after BestChip
		info_row.add_child(_combo_badge)
		info_row.move_child(_combo_badge, 2)  # After XPBar
	else:
		add_child(_combo_badge)


func _start_combo_glow(color: Color) -> void:
	if _combo_glow == null:
		return
	_combo_glow.set_meta("glow_color", Color(color.r, color.g, color.b, 0.3))
	_combo_glow.modulate.a = 1.0
	var tw := create_tween().set_loops()
	tw.tween_property(_combo_glow, "modulate:a", 0.5, 0.5).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_combo_glow, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_IN_OUT)
	_combo_glow.set_meta("glow_tween", tw)


func _stop_combo_glow() -> void:
	if _combo_glow == null:
		return
	var tw: Variant = _combo_glow.get_meta("glow_tween")
	if tw and tw is Tween and tw.is_valid():
		tw.kill()
	_combo_glow.modulate.a = 0.0
