extends Control
## Cascading score breakdown: shows each score source one by one, then merges
## into a total.  Uses wall-clock timing (Time.get_ticks_msec) so hit-stop
## (Engine.time_scale = 0) doesn't freeze the animation.

const ENTRY_INTERVAL := 0.25    # seconds between each entry appearing
const COUNT_UP_DURATION := 0.12 # typewriter count-up per entry
const MERGE_DELAY := 0.25       # pause after last entry before merge
const MERGE_DURATION := 0.3     # entries fade and merge
const BOUNCE_DURATION := 0.2    # total bounces 1.0 → 1.2 → 1.0
const FLOAT_DURATION := 0.5     # float up + fade out after bounce
const ENTRY_SPACING := 28.0     # vertical px between stacked entries

# Font
var _font: Font = null

# Data
var _entries: Array = []   # [{label, text, value, color, font_size, target_value}]
var _total_value: int = 0
var _combo_mult: float = 1.0
var _is_perfect: bool = false

# Timing
var _start_msec: int = 0
var _phase: int = 0  # 0=entries, 1=merge, 2=bounce, 3=float, 4=done
var _phase_start_msec: int = 0

# Layout
var _center: Vector2 = Vector2.ZERO
var _board_center: Vector2 = Vector2.ZERO

# Total label (created during merge)
var _total_label: Label = null

# Perfect effect
var _perfect_label: Label = null
var _perfect_bonus_label: Label = null
var _perfect_ring_radius: float = 0.0
var _perfect_ring_alpha: float = 0.0

# Board renderer reference for perfect clear wave
var _board_renderer: Control = null


func show_cascade(data: Dictionary, board_center: Vector2, board_renderer_ref: Control = null) -> void:
	_board_center = board_center
	_center = board_center
	_board_renderer = board_renderer_ref
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var viewport_size: Vector2 = get_viewport_rect().size
	position = Vector2.ZERO
	size = viewport_size

	# Load Fredoka font
	_font = load("res://assets/fonts/Fredoka-Bold.ttf") as Font

	_is_perfect = data.get("perfect", 0) > 0
	_combo_mult = data.get("combo_mult", 1.0)
	_total_value = data.get("total", 0)

	# Build entry list — only add non-zero sources
	_entries.clear()

	var line_clear: int = data.get("line_clear", 0)
	if line_clear > 0:
		_add_entry("Line Clear", line_clear, Color.WHITE, 20)

	var chain_bonus: int = data.get("chain_bonus", 0)
	if chain_bonus > 0:
		_add_entry("Chroma Chain", chain_bonus, Color("FFD700"), 24)

	var blast_bonus: int = data.get("blast_bonus", 0)
	if blast_bonus > 0:
		var blast_color: Color = Color("FFD700")
		var bc: int = data.get("blast_color", -1)
		if bc >= 0:
			blast_color = AppColors.get_block_light_color(bc)
		_add_entry("Chroma Blast", blast_bonus, blast_color, 28)

	if _combo_mult > 1.0:
		# Combo entry shows multiplier text instead of a point value
		_add_combo_entry(_combo_mult)

	if _is_perfect:
		_add_entry("Perfect Clear", data.get("perfect", GameConstants.PERFECT_CLEAR_BONUS), Color("FFD93D"), 26)

	# If no entries (placement-only score), just show total briefly
	if _entries.is_empty() and _total_value > 0:
		_add_entry("Score", _total_value, Color.WHITE, 20)

	# Layout entries vertically centered on board
	_layout_entries()

	_start_msec = Time.get_ticks_msec()
	_phase = 0
	_phase_start_msec = _start_msec
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func _add_entry(label_text: String, value: int, color: Color, font_size: int) -> void:
	var lbl := Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("outline_size", clampi(font_size / 4, 3, 8))
	if _font:
		lbl.add_theme_font_override("font", _font)
	lbl.text = "+0"
	lbl.modulate.a = 0.0
	lbl.size = Vector2(size.x, font_size + 10.0)
	add_child(lbl)

	_entries.append({
		"label": lbl,
		"prefix": label_text + ":  +",
		"target_value": value,
		"current_display": 0,
		"color": color,
		"font_size": font_size,
		"appeared": false,
		"appear_msec": 0,
		"counting": false,
	})


func _add_combo_entry(mult: float) -> void:
	var lbl := Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color("60A5FA"))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("outline_size", 5)
	if _font:
		lbl.add_theme_font_override("font", _font)
	# Show as "×2.0" format
	var mult_str: String
	if is_equal_approx(mult, floorf(mult)):
		mult_str = "x%d" % int(mult)
	else:
		mult_str = "x%.1f" % mult
	lbl.text = "Combo  " + mult_str
	lbl.modulate.a = 0.0
	lbl.size = Vector2(size.x, 32.0)
	add_child(lbl)

	_entries.append({
		"label": lbl,
		"prefix": "",
		"target_value": 0,
		"current_display": 0,
		"color": Color("60A5FA"),
		"font_size": 22,
		"appeared": false,
		"appear_msec": 0,
		"counting": false,
		"is_combo": true,
	})


func _layout_entries() -> void:
	var count: int = _entries.size()
	if count == 0:
		return
	var total_height: float = count * ENTRY_SPACING
	var start_y: float = _center.y - total_height / 2.0
	for i in count:
		var entry: Dictionary = _entries[i]
		var lbl: Label = entry["label"]
		lbl.position = Vector2(0, start_y + i * ENTRY_SPACING)  # centered, hidden via alpha


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_msec()

	match _phase:
		0:
			_process_entries_phase(now)
		1:
			_process_merge_phase(now)
		2:
			_process_bounce_phase(now)
		3:
			_process_float_phase(now)
		4:
			queue_free()


func _process_entries_phase(now: int) -> void:
	var elapsed_s: float = float(now - _phase_start_msec) / 1000.0
	var all_done := true

	for i in _entries.size():
		var entry: Dictionary = _entries[i]
		var appear_time: float = float(i) * ENTRY_INTERVAL

		# Should this entry appear now?
		if not entry["appeared"] and elapsed_s >= appear_time:
			entry["appeared"] = true
			entry["appear_msec"] = now
			entry["counting"] = true
			var lbl: Label = entry["label"]
			lbl.modulate.a = 1.0
			# Slide in from left
			_slide_in_entry(entry, i)

		# Count-up effect
		if entry["appeared"] and entry["counting"]:
			var is_combo: bool = entry.get("is_combo", false)
			if is_combo:
				entry["counting"] = false
			else:
				var count_elapsed: float = float(now - entry["appear_msec"]) / 1000.0
				var count_t: float = clampf(count_elapsed / COUNT_UP_DURATION, 0.0, 1.0)
				var target: int = entry["target_value"]
				var current: int = int(float(target) * count_t)
				if count_t >= 1.0:
					current = target
					entry["counting"] = false
				entry["current_display"] = current
				var lbl: Label = entry["label"]
				lbl.text = entry["prefix"] + _format_number(current)

		if not entry["appeared"] or entry["counting"]:
			all_done = false

	# Check if all entries are done
	if all_done and not _entries.is_empty():
		# Wait a beat after last entry finishes counting
		var last_entry: Dictionary = _entries[_entries.size() - 1]
		var since_last: float = float(now - last_entry["appear_msec"]) / 1000.0
		if since_last >= COUNT_UP_DURATION + MERGE_DELAY:
			_phase = 1
			_phase_start_msec = now


func _slide_in_entry(entry: Dictionary, index: int) -> void:
	var lbl: Label = entry["label"]
	lbl.pivot_offset = lbl.size / 2.0
	lbl.scale = Vector2(0.6, 0.6)

	# Simple center pop-in (no horizontal slide)
	var tween: Tween = lbl.create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.tween_property(lbl, "scale", Vector2(1.1, 1.1), 0.1) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(lbl, "scale", Vector2.ONE, 0.06) \
		.set_ease(Tween.EASE_IN_OUT)


func _process_merge_phase(now: int) -> void:
	var elapsed_s: float = float(now - _phase_start_msec) / 1000.0
	var t: float = clampf(elapsed_s / MERGE_DURATION, 0.0, 1.0)

	# Slide all entries to center and shrink
	for entry in _entries:
		var lbl: Label = entry["label"]
		lbl.pivot_offset = lbl.size / 2.0
		var target_y: float = _center.y - 15.0
		lbl.position.y = lerp(lbl.position.y, target_y, t)
		lbl.scale = Vector2.ONE * lerp(1.0, 0.3, t)
		lbl.modulate.a = lerp(1.0, 0.0, t)

	if t >= 1.0:
		# Remove entry labels
		for entry in _entries:
			var lbl: Label = entry["label"]
			lbl.queue_free()
		_entries.clear()

		# Create total label
		_create_total_label()
		_phase = 2
		_phase_start_msec = now


func _create_total_label() -> void:
	_total_label = Label.new()
	_total_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_total_label.add_theme_font_size_override("font_size", 36)
	_total_label.add_theme_color_override("font_color", Color("FFD93D"))
	_total_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_total_label.add_theme_constant_override("outline_size", 10)
	if _font:
		_total_label.add_theme_font_override("font", _font)
	_total_label.text = _format_number(_total_value)
	_total_label.size = Vector2(size.x, 50.0)
	_total_label.position = Vector2(0, _center.y - 25.0)
	_total_label.pivot_offset = Vector2(size.x / 2.0, 25.0)
	_total_label.scale = Vector2(0.5, 0.5)
	_total_label.modulate.a = 0.0
	add_child(_total_label)


func _process_bounce_phase(now: int) -> void:
	var elapsed_s: float = float(now - _phase_start_msec) / 1000.0
	var t: float = clampf(elapsed_s / BOUNCE_DURATION, 0.0, 1.0)

	if _total_label:
		_total_label.modulate.a = 1.0
		# Bounce: 0.5 → 1.3 → 1.0
		var scale_val: float
		if t < 0.5:
			scale_val = lerp(0.5, 1.3, t / 0.5)
		else:
			scale_val = lerp(1.3, 1.0, (t - 0.5) / 0.5)
		_total_label.scale = Vector2(scale_val, scale_val)

	if t >= 1.0:
		# If perfect, show perfect effect before floating
		if _is_perfect:
			_start_perfect_effect(now)
		_phase = 3
		_phase_start_msec = now


func _start_perfect_effect(now: int) -> void:
	# "PERFECT!" rainbow label
	_perfect_label = Label.new()
	_perfect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_perfect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_perfect_label.add_theme_font_size_override("font_size", 48)
	_perfect_label.add_theme_color_override("font_color", Color.WHITE)
	_perfect_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_perfect_label.add_theme_constant_override("outline_size", 10)
	if _font:
		_perfect_label.add_theme_font_override("font", _font)
	_perfect_label.text = "PERFECT!"
	_perfect_label.size = Vector2(size.x, 60.0)
	_perfect_label.position = Vector2(0, _center.y - 80.0)
	_perfect_label.pivot_offset = Vector2(size.x / 2.0, 30.0)
	_perfect_label.scale = Vector2.ZERO
	add_child(_perfect_label)

	# Pop in the PERFECT label
	var tween: Tween = _perfect_label.create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.tween_property(_perfect_label, "scale", Vector2(1.3, 1.3), 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_perfect_label, "scale", Vector2.ONE, 0.08) \
		.set_ease(Tween.EASE_IN_OUT)

	# "+2,000" bonus label below PERFECT
	_perfect_bonus_label = Label.new()
	_perfect_bonus_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_perfect_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_perfect_bonus_label.add_theme_font_size_override("font_size", 32)
	_perfect_bonus_label.add_theme_color_override("font_color", Color("FFD93D"))
	_perfect_bonus_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_perfect_bonus_label.add_theme_constant_override("outline_size", 8)
	if _font:
		_perfect_bonus_label.add_theme_font_override("font", _font)
	_perfect_bonus_label.text = "+" + _format_number(GameConstants.PERFECT_CLEAR_BONUS)
	_perfect_bonus_label.size = Vector2(size.x, 45.0)
	_perfect_bonus_label.position = Vector2(0, _center.y - 30.0)
	_perfect_bonus_label.pivot_offset = Vector2(size.x / 2.0, 22.0)
	_perfect_bonus_label.scale = Vector2.ZERO
	add_child(_perfect_bonus_label)

	var tween2: Tween = _perfect_bonus_label.create_tween()
	tween2.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween2.tween_property(_perfect_bonus_label, "scale", Vector2.ONE, 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(0.1)

	# Rainbow ring
	_perfect_ring_radius = 0.0
	_perfect_ring_alpha = 0.8

	# Trigger board wave if we have a board reference
	if _board_renderer and _board_renderer.has_method("play_perfect_clear_effect"):
		_board_renderer.play_perfect_clear_effect()


func _process_float_phase(now: int) -> void:
	var elapsed_s: float = float(now - _phase_start_msec) / 1000.0

	# Extend float duration if perfect (need more time for the effect)
	var actual_float_duration: float = FLOAT_DURATION
	if _is_perfect:
		actual_float_duration = 2.0  # longer for perfect effect

	var t: float = clampf(elapsed_s / actual_float_duration, 0.0, 1.0)

	# Float up + fade
	if _total_label:
		_total_label.position.y = _center.y - 25.0 - t * 40.0
		# Start fading at 60% through
		if t > 0.6:
			_total_label.modulate.a = 1.0 - (t - 0.6) / 0.4
		else:
			_total_label.modulate.a = 1.0

	# Perfect effect updates
	if _is_perfect:
		# Rainbow hue cycling on PERFECT label
		if _perfect_label and is_instance_valid(_perfect_label):
			var hue: float = fmod(elapsed_s * 0.8, 1.0)
			var rainbow_color := Color.from_hsv(hue, 0.8, 1.0)
			_perfect_label.add_theme_color_override("font_color", rainbow_color)
			# Fade out in the last portion
			if t > 0.5:
				var fade: float = 1.0 - (t - 0.5) / 0.5
				_perfect_label.modulate.a = fade
				if _perfect_bonus_label and is_instance_valid(_perfect_bonus_label):
					_perfect_bonus_label.modulate.a = fade

		# Expanding ring
		_perfect_ring_radius = elapsed_s * 200.0
		_perfect_ring_alpha = maxf(0.0, 0.8 - elapsed_s * 0.5)
		queue_redraw()

	if t >= 1.0:
		_phase = 4


func _draw() -> void:
	# Rainbow ring for perfect clear
	if _is_perfect and _perfect_ring_alpha > 0.01 and _perfect_ring_radius > 0.0:
		var hue: float = fmod(float(Time.get_ticks_msec()) / 1000.0 * 0.5, 1.0)
		for i in 6:
			var ring_hue: float = fmod(hue + float(i) * 0.16, 1.0)
			var ring_color := Color.from_hsv(ring_hue, 0.9, 1.0, _perfect_ring_alpha * 0.4)
			var r: float = _perfect_ring_radius + float(i) * 8.0
			if r > 0.0:
				draw_arc(_board_center, r, 0, TAU, 64, ring_color, 2.5)


static func _format_number(value: int) -> String:
	var s: String = str(absi(value))
	var result: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	if value < 0:
		result = "-" + result
	return result
