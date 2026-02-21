extends Node
## 크래시 디버그 로거 — 게임 이벤트를 파일에 기록하고, 비정상 종료 후 재시작 시 로그를 표시

const LOG_PATH := "user://debug_log.txt"
const CLEAN_EXIT_KEY := "clean_exit"
const MAX_LOG_LINES := 200

var _log_file: FileAccess
var _log_lines: PackedStringArray = []
var _previous_crash_log: String = ""
var _frame_count: int = 0
var _last_heartbeat_sec: float = 0.0


func _ready() -> void:
	# 이전 세션이 비정상 종료인지 확인
	var was_crash := not _read_clean_exit_flag()
	if was_crash:
		_previous_crash_log = _read_previous_log()

	# 새 로그 파일 시작
	_log_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if _log_file:
		_log_file.store_line("=== ChromaBlocks Debug Log ===")
		_log_file.store_line("Time: %s" % Time.get_datetime_string_from_system())
		_log_file.store_line("OS: %s" % OS.get_name())
		_log_file.store_line("Renderer: %s" % str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown")))
		_log_file.store_line("GPU: %s" % RenderingServer.get_video_adapter_name())
		_log_file.store_line("Previous crash: %s" % str(was_crash))
		_log_file.store_line("---")
		_log_file.flush()

	# Clean exit 플래그 초기화 (비정상 종료 감지용)
	_write_clean_exit_flag(false)

	# 이전 크래시 로그가 있으면 2초 후 표시
	if not _previous_crash_log.is_empty():
		var timer := get_tree().create_timer(2.0)
		timer.timeout.connect(_show_crash_log)


func _process(_delta: float) -> void:
	_frame_count += 1
	# Log a heartbeat every 2 seconds to track frame processing
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_heartbeat_sec >= 2.0:
		_last_heartbeat_sec = now
		log_event("FRAME", "count=%d fps=%.0f mem=%.1fMB" % [
			_frame_count,
			Engine.get_frames_per_second(),
			OS.get_static_memory_usage() / 1048576.0,
		])


func log_event(tag: String, message: String = "") -> void:
	var timestamp := "%.3f" % (Time.get_ticks_msec() / 1000.0)
	var line := "[%s] %s %s" % [timestamp, tag, message]
	_log_lines.append(line)

	# 최대 라인 수 초과 시 오래된 항목 제거
	if _log_lines.size() > MAX_LOG_LINES:
		_log_lines = _log_lines.slice(_log_lines.size() - MAX_LOG_LINES)

	if _log_file:
		_log_file.store_line(line)
		_log_file.flush()

	if OS.is_debug_build():
		print("[CrashLog] %s" % line)


func _read_previous_log() -> String:
	if not FileAccess.file_exists(LOG_PATH):
		return ""
	var f := FileAccess.open(LOG_PATH, FileAccess.READ)
	if f == null:
		return ""
	var content := f.get_as_text()
	f.close()
	# 마지막 50줄만 반환
	var lines := content.split("\n")
	var start := maxi(0, lines.size() - 50)
	var recent := lines.slice(start)
	return "\n".join(recent)


func _read_clean_exit_flag() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load("user://crash_state.cfg") != OK:
		return false
	return cfg.get_value("state", CLEAN_EXIT_KEY, false)


func _write_clean_exit_flag(value: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("state", CLEAN_EXIT_KEY, value)
	cfg.save("user://crash_state.cfg")


func _show_crash_log() -> void:
	if _previous_crash_log.is_empty():
		return

	# 크래시 로그를 화면에 표시하는 오버레이 생성
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.9)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox := VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.add_theme_constant_override("separation", 8)
	overlay.add_child(vbox)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(margin)

	var inner_vbox := VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(inner_vbox)

	var title := Label.new()
	title.text = "CRASH LOG (Previous Session)"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.RED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner_vbox.add_child(scroll)

	var log_label := Label.new()
	log_label.text = _previous_crash_log
	log_label.add_theme_font_size_override("font_size", 10)
	log_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(log_label)

	# 닫기 + 복사 버튼
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_vbox.add_child(btn_row)

	var copy_btn := Button.new()
	copy_btn.text = "COPY LOG"
	copy_btn.custom_minimum_size = Vector2(120, 44)
	copy_btn.add_theme_font_size_override("font_size", 14)
	copy_btn.pressed.connect(func():
		DisplayServer.clipboard_set(_previous_crash_log)
		copy_btn.text = "COPIED!"
	)
	btn_row.add_child(copy_btn)

	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(120, 44)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(func():
		overlay.queue_free()
	)
	btn_row.add_child(close_btn)

	# CanvasLayer 위에 표시 (모든 UI 위)
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(overlay)
	get_tree().root.add_child(canvas)


func get_previous_crash_log() -> String:
	return _previous_crash_log


func _notification(what: int) -> void:
	if what == Window.NOTIFICATION_WM_CLOSE_REQUEST or what == MainLoop.NOTIFICATION_APPLICATION_PAUSED:
		# 정상 종료 시 clean exit 기록
		log_event("APP", "Clean exit/pause")
		_write_clean_exit_flag(true)
		if _log_file:
			_log_file.flush()
