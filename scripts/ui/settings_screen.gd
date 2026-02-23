extends Control

signal closed()

var _sound_toggle: Button
var _music_toggle: Button
var _track_button: Button
var _haptic_toggle: Button

# 테마 선택 UI 참조
var _theme_container: VBoxContainer
var _theme_buttons: Dictionary = {} # theme_id -> Button


func _ready() -> void:
	# Sound toggle
	_sound_toggle = $Card/VBox/SoundRow/SoundToggle
	_sound_toggle.pressed.connect(_toggle_sound)
	_update_sound_label()

	# Music toggle
	_music_toggle = $Card/VBox/MusicRow/MusicToggle
	_music_toggle.pressed.connect(_toggle_music)
	_update_music_label()

	# Track selector
	_track_button = $Card/VBox/TrackRow/TrackButton
	_track_button.pressed.connect(_cycle_track)
	_update_track_label()

	# Haptic toggle
	_haptic_toggle = $Card/VBox/HapticRow/HapticToggle
	_haptic_toggle.pressed.connect(_toggle_haptic)
	_update_haptic_label()

	# Close button
	$Card/VBox/CloseButton.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		closed.emit())

	# 테마 선택 섹션 동적 생성
	_build_theme_section()


func _toggle_sound() -> void:
	SoundManager.play_sfx("button_press")
	SaveManager.set_sound_enabled(not SaveManager.is_sound_enabled())
	_update_sound_label()


func _toggle_music() -> void:
	SoundManager.play_sfx("button_press")
	MusicManager.set_enabled(not SaveManager.is_music_enabled())
	_update_music_label()


func _toggle_haptic() -> void:
	SoundManager.play_sfx("button_press")
	var new_state := not SaveManager.is_haptic_enabled()
	SaveManager.set_haptic_enabled(new_state)
	_update_haptic_label()
	# Give immediate feedback vibration when enabling
	if new_state:
		Input.vibrate_handheld(30)


func _update_sound_label() -> void:
	_sound_toggle.text = "ON" if SaveManager.is_sound_enabled() else "OFF"


func _update_music_label() -> void:
	_music_toggle.text = "ON" if SaveManager.is_music_enabled() else "OFF"


func _cycle_track() -> void:
	SoundManager.play_sfx("button_press")
	var tracks := MusicManager.get_track_list()
	var current_id := MusicManager.get_current_track_id()
	var current_idx := 0
	for i in tracks.size():
		if tracks[i]["id"] == current_id:
			current_idx = i
			break
	var next_idx := (current_idx + 1) % tracks.size()
	var next_id: String = tracks[next_idx]["id"]
	MusicManager.switch_track(next_id)
	_update_track_label()


func _update_track_label() -> void:
	var tracks := MusicManager.get_track_list()
	var current_id := MusicManager.get_current_track_id()
	for track in tracks:
		if track["id"] == current_id:
			_track_button.text = track["name"]
			return
	_track_button.text = "Chroma Dream"


func _update_haptic_label() -> void:
	_haptic_toggle.text = "ON" if SaveManager.is_haptic_enabled() else "OFF"


## 테마 선택 섹션을 동적으로 생성
func _build_theme_section() -> void:
	var vbox: VBoxContainer = $Card/VBox

	# 구분선
	var separator := HSeparator.new()
	separator.add_theme_color_override("separator_color", AppColors.BORDER)
	vbox.add_child(separator)
	# CloseButton 위에 삽입하기 위해 순서 조정
	vbox.move_child(separator, vbox.get_child_count() - 2)

	# 테마 섹션 제목
	var theme_title := Label.new()
	theme_title.text = "Theme"
	theme_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	theme_title.add_theme_font_size_override("font_size", 16)
	theme_title.add_theme_color_override("font_color", AppColors.TEXT_SECONDARY)
	vbox.add_child(theme_title)
	vbox.move_child(theme_title, vbox.get_child_count() - 2)

	# 테마 버튼 컨테이너
	_theme_container = VBoxContainer.new()
	_theme_container.add_theme_constant_override("separation", 8)
	vbox.add_child(_theme_container)
	vbox.move_child(_theme_container, vbox.get_child_count() - 2)

	# 모든 테마에 대해 버튼 생성
	var current_theme := ThemeSystem.get_current_theme()
	var all_themes := ThemeSystem.get_all_themes()

	for theme_info in all_themes:
		var theme_id: String = theme_info["id"]
		var is_unlocked: bool = theme_info["unlocked"]

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		# 색상 미리보기 (작은 색상 사각형들)
		var preview: Control = _create_color_preview(theme_info["colors"])
		row.add_child(preview)

		# 테마 이름 + 잠금 상태 버튼
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 36)
		btn.add_theme_font_size_override("font_size", 14)

		if is_unlocked:
			btn.text = theme_info["name"]
			if theme_id == current_theme:
				btn.add_theme_color_override("font_color", AppColors.ACCENT_TEXT)
				btn.text += "  \u2713"
			else:
				btn.add_theme_color_override("font_color", AppColors.TEXT_SECONDARY)
			btn.pressed.connect(_on_theme_selected.bind(theme_id))
		else:
			# 잠금된 테마: 해제 조건 표시
			var condition: String = theme_info["unlock_condition"]
			var desc := ThemeSystem.get_unlock_description(condition)
			btn.text = theme_info["name"] + "  🔒"
			btn.tooltip_text = desc
			btn.add_theme_color_override("font_color", AppColors.TEXT_MUTED)
			btn.disabled = true

		row.add_child(btn)
		_theme_container.add_child(row)
		_theme_buttons[theme_id] = btn


## 테마 색상 미리보기 컨트롤 생성 (작은 색상 사각형 7개)
func _create_color_preview(colors: Dictionary) -> Control:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	container.custom_minimum_size = Vector2(56, 24)

	# BlockColor 순서: CORAL, AMBER, LEMON, MINT, SKY, LAVENDER, SPECIAL
	var color_order: Array = [
		Enums.BlockColor.CORAL,
		Enums.BlockColor.AMBER,
		Enums.BlockColor.LEMON,
		Enums.BlockColor.MINT,
		Enums.BlockColor.SKY,
		Enums.BlockColor.LAVENDER,
		Enums.BlockColor.SPECIAL,
	]

	for block_color in color_order:
		if colors.has(block_color):
			var swatch := ColorRect.new()
			swatch.custom_minimum_size = Vector2(6, 18)
			swatch.color = colors[block_color]["bg"]
			container.add_child(swatch)

	return container


## 테마 선택 시 호출
func _on_theme_selected(theme_id: String) -> void:
	SoundManager.play_sfx("button_press")
	ThemeSystem.set_theme(theme_id)
	AppColors.apply_theme(theme_id)
	# 버튼 상태 업데이트
	_update_theme_buttons(theme_id)


## 테마 버튼 시각 상태 업데이트
func _update_theme_buttons(selected_id: String) -> void:
	var all_themes := ThemeSystem.get_all_themes()
	for theme_info in all_themes:
		var theme_id: String = theme_info["id"]
		if not _theme_buttons.has(theme_id):
			continue
		var btn: Button = _theme_buttons[theme_id]
		var is_unlocked: bool = theme_info["unlocked"]
		if not is_unlocked:
			continue
		if theme_id == selected_id:
			btn.text = theme_info["name"] + "  \u2713"
			btn.add_theme_color_override("font_color", AppColors.ACCENT_TEXT)
		else:
			btn.text = theme_info["name"]
			btn.add_theme_color_override("font_color", AppColors.TEXT_SECONDARY)
