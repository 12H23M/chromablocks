class_name HapticManager


static func _vibrate(duration_ms: int) -> void:
	if not SaveManager.is_haptic_enabled():
		return
	Input.vibrate_handheld(duration_ms)


static func light() -> void:
	_vibrate(20)


static func medium() -> void:
	_vibrate(40)


static func line_clear() -> void:
	_vibrate(50)


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
	var duration := clampi(30 + combo_level * 10, 40, 100)
	_vibrate(duration)


## Level up - stronger pulse
static func level_up() -> void:
	_vibrate(30)


## Explosion burst — subtle rumble during line clear
static func explosion(line_count: int = 1) -> void:
	var duration := clampi(25 + line_count * 15, 30, 80)
	_vibrate(duration)
