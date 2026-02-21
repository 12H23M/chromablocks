extends Control

signal start_pressed()
signal continue_pressed()
signal daily_pressed()
signal settings_pressed()
signal how_to_play_pressed()

@onready var continue_button: Button = $VBox/ButtonSection/ContinueButton
@onready var daily_button: Button = $VBox/ButtonSection/DailyButton
@onready var start_button: Button = $VBox/ButtonSection/StartButton
@onready var sound_toggle: Button = $VBox/BottomRow/SoundToggle
@onready var settings_button: Button = $VBox/BottomRow/SettingsButton
@onready var best_value: Label = $VBox/StatsSection/BestStat/BestValue
@onready var games_value: Label = $VBox/StatsSection/GamesStat/GamesValue
@onready var avg_value: Label = $VBox/StatsSection/AvgStat/AvgValue

func _ready() -> void:
	continue_button.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		continue_pressed.emit())
	continue_button.visible = false
	daily_button.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		daily_pressed.emit())
	start_button.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		start_pressed.emit())
	$VBox/ButtonSection/HowToPlayButton.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		how_to_play_pressed.emit())
	sound_toggle.pressed.connect(_toggle_sound)
	settings_button.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		settings_pressed.emit())
	refresh_stats()
	_update_sound_label()

func refresh_stats() -> void:
	best_value.text = FormatUtils.format_number(SaveManager.get_high_score())
	games_value.text = str(SaveManager.get_games_played())
	avg_value.text = FormatUtils.format_number(SaveManager.get_avg_score())
	continue_button.visible = SaveManager.has_active_game()
	_update_daily_button()
	_try_daily_reward()

func _toggle_sound() -> void:
	SoundManager.play_sfx("button_press")
	var enabled := not SaveManager.is_sound_enabled()
	SaveManager.set_sound_enabled(enabled)
	_update_sound_label()

func _update_sound_label() -> void:
	sound_toggle.text = "♪" if SaveManager.is_sound_enabled() else "✕"


## 일일 챌린지 버튼 상태 갱신 — 날짜 표시 + 플레이 상태 반영
func _update_daily_button() -> void:
	var played := DailyChallengeSystem.has_played_today()
	var now := Time.get_date_dict_from_system()
	var date_str := "%d/%d" % [now["month"], now["day"]]

	if played:
		var best := DailyChallengeSystem.get_daily_best()
		daily_button.text = "DAILY  %s  -  %d pts" % [date_str, best]
	else:
		daily_button.text = "DAILY CHALLENGE  %s" % date_str

	# 설명 텍스트 업데이트
	var desc_label := $VBox/ButtonSection/DailyDesc
	if desc_label:
		var streak := DailyChallengeSystem.get_streak()
		if played and streak >= 2:
			desc_label.text = "Streak %d days! Same puzzle for everyone" % streak
		elif played:
			desc_label.text = "Completed! Play again to beat your score"
		else:
			desc_label.text = "Same puzzle for everyone today"


## 일일 출석 보상 체크 — 보상이 있으면 팝업 레이블 표시
func _try_daily_reward() -> void:
	var reward := DailyRewardSystem.check_in()
	if reward.is_empty():
		return
	_show_reward_popup(reward)


## 출석 보상 팝업 레이블을 동적으로 생성하여 표시 (1초 후 페이드아웃)
func _show_reward_popup(reward: Dictionary) -> void:
	# 보상 텍스트 조합
	var day: int = reward["day"]
	var parts: Array[String] = []
	var multiplier: float = reward["score_multiplier"]
	var swaps: int = reward["bonus_swaps"]

	if multiplier > 1.0:
		parts.append("Score x%s" % str(multiplier))
	if swaps > 0:
		parts.append("Swap +%d" % swaps)

	var text := "Day %d Reward: %s" % [day, ", ".join(parts)]

	# 팝업 레이블 생성
	var popup := Label.new()
	popup.name = "DailyRewardPopup"
	popup.text = text
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.add_theme_font_size_override("font_size", 14)
	popup.add_theme_color_override("font_color", Color(0.957, 0.62, 0.043, 1))

	# 배경 패널 생성
	var panel := PanelContainer.new()
	panel.name = "DailyRewardPanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.95)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_right = 20
	style.corner_radius_bottom_left = 20
	style.content_margin_left = 20.0
	style.content_margin_top = 12.0
	style.content_margin_right = 20.0
	style.content_margin_bottom = 12.0
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.957, 0.62, 0.043, 0.4)
	style.shadow_color = Color(0, 0, 0, 0.08)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(popup)

	# 화면 상단 중앙에 배치
	panel.layout_mode = 1
	panel.anchors_preset = 5  # CENTER_TOP
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -120.0
	panel.offset_right = 120.0
	panel.offset_top = 40.0
	panel.offset_bottom = 80.0
	panel.grow_horizontal = 2
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	add_child(panel)

	# 페이드아웃 트윈 (1초 대기 후 0.5초 페이드)
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)
