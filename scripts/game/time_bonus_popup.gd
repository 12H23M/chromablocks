extends Control
## 타임어택 라인 클리어 시 +N초 보너스 팝업

var _seconds: float = 0.0
var _center: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _scale_val: float = 0.0
var _alpha: float = 1.0

var _label: Label

const POP_DURATION := 0.12
const HOLD_DURATION := 0.5
const FADE_DURATION := 0.25
const TOTAL_DURATION := POP_DURATION + HOLD_DURATION + FADE_DURATION


func show_time_bonus(seconds: float, center_pos: Vector2) -> void:
	_seconds = seconds
	_center = center_pos
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var viewport_size := get_viewport_rect().size
	position = Vector2.ZERO
	size = viewport_size

	# 메인 라벨: +3s 형식 (녹색)
	_label = Label.new()
	_label.text = "+%.0fs" % seconds
	_label.add_theme_font_size_override("font_size", 36)
	_label.add_theme_color_override("font_color", Color("00FF88"))  # 밝은 녹색
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 5)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.anchors_preset = Control.PRESET_FULL_RECT
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.modulate.a = 0.0
	add_child(_label)

	# 보드 중앙 상단에 표시
	var cy := _center.y - 100.0
	_label.position = Vector2(0, cy)
	_label.size = Vector2(size.x, 50)

	_elapsed = 0.0
	_scale_val = 0.0
	_alpha = 1.0
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func _process(_delta: float) -> void:
	_elapsed += get_process_delta_time()

	if _elapsed >= TOTAL_DURATION:
		queue_free()
		return

	# Phase 1: Pop (scale 0 -> 1.2 -> 1.0)
	if _elapsed < POP_DURATION:
		var t := _elapsed / POP_DURATION
		if t < 0.5:
			_scale_val = (t / 0.5) * 1.2
		else:
			_scale_val = lerp(1.2, 1.0, (t - 0.5) / 0.5)
		_alpha = 1.0
	# Phase 2: Hold
	elif _elapsed < POP_DURATION + HOLD_DURATION:
		_scale_val = 1.0
		_alpha = 1.0
	# Phase 3: Fade up
	else:
		_scale_val = 1.0
		var fade_t := (_elapsed - POP_DURATION - HOLD_DURATION) / FADE_DURATION
		_alpha = clampf(1.0 - fade_t, 0.0, 1.0)

	var s := maxf(_scale_val, 0.01)
	_label.pivot_offset = _label.size / 2.0
	_label.scale = Vector2(s, s)
	_label.modulate.a = _alpha
