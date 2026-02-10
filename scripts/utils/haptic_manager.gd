class_name HapticManager

static func light() -> void:
	Input.vibrate_handheld(20)

static func medium() -> void:
	Input.vibrate_handheld(40)

static func line_clear() -> void:
	Input.vibrate_handheld(50)

static func color_match() -> void:
	Input.vibrate_handheld(60)

static func game_over() -> void:
	Input.vibrate_handheld(100)
