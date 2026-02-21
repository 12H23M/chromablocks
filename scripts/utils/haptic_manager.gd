class_name HapticManager


static func _vibrate(duration_ms: int) -> void:
	if not SaveManager.is_haptic_enabled():
		return
	Input.vibrate_handheld(duration_ms)


## Schedule a delayed vibration pulse (non-blocking)
static func _vibrate_delayed(duration_ms: int, delay_sec: float) -> void:
	if not SaveManager.is_haptic_enabled():
		return
	var main_loop := Engine.get_main_loop()
	if main_loop == null:
		return
	var tree: SceneTree = main_loop as SceneTree
	if tree == null:
		return
	# Use process_always=true to ignore pause, ignore_time_scale=true to bypass hit stop
	var timer: SceneTreeTimer = tree.create_timer(delay_sec, true, false, true)
	if timer == null:
		return
	timer.timeout.connect(func():
		if SaveManager.is_haptic_enabled():
			Input.vibrate_handheld(duration_ms)
	)


static func light() -> void:
	_vibrate(20)


static func medium() -> void:
	_vibrate(40)


static func line_clear() -> void:
	_vibrate(50)


## Enhanced line clear with multi-pulse pattern based on line count
static func line_clear_burst(line_count: int = 1) -> void:
	if line_count >= 3:
		# Triple+ clear: strong initial hit + two follow-up pulses
		_vibrate(80)
		_vibrate_delayed(60, 0.1)
		_vibrate_delayed(40, 0.2)
	elif line_count >= 2:
		# Double clear: strong hit + follow-up
		_vibrate(70)
		_vibrate_delayed(50, 0.12)
	else:
		# Single clear: solid single pulse
		_vibrate(55)


static func color_match() -> void:
	_vibrate(60)


static func game_over() -> void:
	_vibrate(100)


## Piece pickup feedback
static func drag_start() -> void:
	_vibrate(10)


## Grid snap feedback (very subtle)
static func grid_snap() -> void:
	_vibrate(5)


## Combo feedback — intensity scales with combo level
static func combo(combo_level: int = 2) -> void:
	var duration := clampi(40 + combo_level * 12, 50, 120)
	_vibrate(duration)
	# Extra pulse for high combos
	if combo_level >= 4:
		_vibrate_delayed(clampi(combo_level * 10, 40, 80), 0.08)


## Level up - stronger pulse
static func level_up() -> void:
	_vibrate(40)
	_vibrate_delayed(25, 0.1)


## Perfect clear — dramatic multi-pulse crescendo
static func perfect_clear() -> void:
	_vibrate(100)
	_vibrate_delayed(80, 0.1)
	_vibrate_delayed(60, 0.2)
	_vibrate_delayed(100, 0.3)
