extends Control

signal play_again_pressed()
signal go_home_pressed()
signal continue_ad_pressed()
signal double_score_ad_pressed()

@onready var final_score: Label = $ScrollContainer/Content/FinalScoreValue
@onready var best_score_label: Label = $ScrollContainer/Content/BestScoreLabel
@onready var new_best_badge: PanelContainer = $ScrollContainer/Content/NewBestBadge
@onready var near_miss_label: Label = $ScrollContainer/Content/NearMissLabel
@onready var lines_value: Label = $ScrollContainer/Content/Stats/LinesBox/LinesValue
@onready var blocks_value: Label = $ScrollContainer/Content/Stats/BlocksBox/BlocksValue
@onready var combos_value: Label = $ScrollContainer/Content/Stats/CombosBox/CombosValue
@onready var chains_value: Label = $ScrollContainer/Content/Stats/ChainsBox/ChainsValue
@onready var grade_label: Label = $ScrollContainer/Content/GradeContainer/GradeLabel
@onready var title_label: Label = $ScrollContainer/Content/GameOverTitle
@onready var stats_container: HBoxContainer = $ScrollContainer/Content/Stats
@onready var particle_layer: Control = $ParticleLayer

var _continue_btn: Button
var _double_btn: Button
var _used_ad_this_game := false
var _glow_tween: Tween
var _particle_timer: float = 0.0
var _particles: Array = []
var _mission_results_container: VBoxContainer = null
var _fredoka_bold: Font = null

const GRADE_THRESHOLDS := {
	"S": 10000,
	"A": 5000,
	"B": 2000,
}
const GRADE_COLORS := {
	"S": Color(1, 0.84, 0, 1),        # Gold
	"A": Color(0.65, 0.55, 0.87, 1),  # Purple
	"B": Color(0.37, 0.73, 0.96, 1),  # Blue
	"C": Color(1, 0.55, 0.26, 1),     # Orange (was grey)
}
const PARTICLE_COLORS: Array[Color] = [
	Color(1, 0.42, 0.61, 0.3),     # Pink
	Color(0.30, 0.59, 1.0, 0.3),   # Blue
	Color(0.42, 0.80, 0.47, 0.3),  # Green
	Color(1, 0.85, 0.24, 0.3),     # Gold
	Color(0.61, 0.45, 0.81, 0.3),  # Purple
	Color(1, 0.55, 0.26, 0.3),     # Orange
]


func _ready() -> void:
	_fredoka_bold = load("res://assets/fonts/Fredoka-Bold.ttf") as Font
	$ScrollContainer/Content/ButtonSection/PlayAgainButton.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		play_again_pressed.emit())
	$ScrollContainer/Content/ButtonSection/HomeButton.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		go_home_pressed.emit())

	_continue_btn = $ScrollContainer/Content/AdSection/ContinueAdButton
	_double_btn = $ScrollContainer/Content/AdSection/DoubleScoreAdButton
	_continue_btn.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		continue_ad_pressed.emit())
	_double_btn.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		double_score_ad_pressed.emit())


func _process(delta: float) -> void:
	if not visible:
		return
	_update_particles(delta)


func _get_grade(score: int) -> String:
	if score >= GRADE_THRESHOLDS["S"]:
		return "S"
	elif score >= GRADE_THRESHOLDS["A"]:
		return "A"
	elif score >= GRADE_THRESHOLDS["B"]:
		return "B"
	return "C"


func show_result(state: GameState) -> void:
	var is_new_best := state.score > state.high_score and state.score > 0
	var best: int = state.score if is_new_best else state.high_score

	# Reset values
	final_score.text = "0"
	best_score_label.text = "👑 BEST: " + FormatUtils.format_number(best)
	best_score_label.visible = true
	new_best_badge.visible = is_new_best

	# Near-miss feedback
	near_miss_label.visible = false
	if not is_new_best and state.high_score > 0:
		var threshold: float = state.high_score * 0.8
		if state.score >= int(threshold) and state.score > 0:
			var difference: int = state.high_score - state.score
			near_miss_label.text = "최고 기록까지 %d점!" % difference
			near_miss_label.visible = true

	# Grade
	var grade_str: String = _get_grade(state.score)
	grade_label.text = grade_str
	grade_label.add_theme_color_override("font_color", GRADE_COLORS[grade_str])
	grade_label.modulate.a = 0.0
	grade_label.scale = Vector2(0.3, 0.3)

	# Stats start at 0
	lines_value.text = "0"
	blocks_value.text = "0"
	combos_value.text = "0"
	chains_value.text = "0"

	# Hide stats initially
	var lines_box: VBoxContainer = $ScrollContainer/Content/Stats/LinesBox
	var blocks_box: VBoxContainer = $ScrollContainer/Content/Stats/BlocksBox
	var combos_box: VBoxContainer = $ScrollContainer/Content/Stats/CombosBox
	var chains_box: VBoxContainer = $ScrollContainer/Content/Stats/ChainsBox
	lines_box.modulate.a = 0.0
	blocks_box.modulate.a = 0.0
	combos_box.modulate.a = 0.0
	chains_box.modulate.a = 0.0

	# Hide buttons initially
	var play_btn: Button = $ScrollContainer/Content/ButtonSection/PlayAgainButton
	var home_btn: Button = $ScrollContainer/Content/ButtonSection/HomeButton
	play_btn.modulate.a = 0.0
	home_btn.modulate.a = 0.0

	# Show/hide ad buttons
	var show_ads := not _used_ad_this_game and AdManager.is_rewarded_available()
	_continue_btn.visible = show_ads
	_double_btn.visible = show_ads

	# Entrance animation
	modulate.a = 0.0
	visible = true

	# Clear old particles
	_particles.clear()
	particle_layer.queue_redraw()

	var speed_scale: float = 1.0 / maxf(Engine.time_scale, 0.01)

	# Fade in
	var tween := create_tween()
	tween.set_speed_scale(speed_scale)
	tween.tween_property(self, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)

	# Title glow pulse
	_start_title_glow(speed_scale)

	# Grade bounce in
	var grade_tween := create_tween()
	grade_tween.set_speed_scale(speed_scale)
	grade_tween.tween_interval(0.35)
	grade_tween.tween_property(grade_label, "modulate:a", 1.0, 0.2)
	grade_tween.parallel().tween_property(grade_label, "scale", Vector2(1.3, 1.3), 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	grade_tween.tween_property(grade_label, "scale", Vector2(1.0, 1.0), 0.15) \
		.set_ease(Tween.EASE_IN_OUT)

	# Score counting
	if state.score > 0:
		var count_tween := create_tween()
		count_tween.set_speed_scale(speed_scale)
		var target_score := state.score
		count_tween.tween_method(func(value: int) -> void:
			final_score.text = FormatUtils.format_number(value)
		, 0, target_score, 0.8).set_ease(Tween.EASE_OUT).set_delay(0.4)

		var bounce_tween := create_tween()
		bounce_tween.set_speed_scale(speed_scale)
		bounce_tween.tween_interval(1.2)
		bounce_tween.tween_property(final_score, "scale", Vector2(1.15, 1.15), 0.1) \
			.set_ease(Tween.EASE_OUT)
		bounce_tween.tween_property(final_score, "scale", Vector2(1.0, 1.0), 0.15) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BOUNCE)

	# New best glow
	if is_new_best:
		_animate_new_best_glow(speed_scale)

	# Stats stagger animation
	var stat_boxes: Array = [lines_box, blocks_box, combos_box, chains_box]
	var stat_values: Array = [state.lines_cleared, state.blocks_placed, state.max_combo, state.chains_triggered]
	var stat_labels: Array = [lines_value, blocks_value, combos_value, chains_value]

	for i in range(4):
		var box: VBoxContainer = stat_boxes[i]
		var val: int = stat_values[i]
		var lbl: Label = stat_labels[i]
		var delay: float = 0.6 + i * 0.12

		var st := create_tween()
		st.set_speed_scale(speed_scale)
		st.tween_interval(delay)
		st.tween_property(box, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)

		if val > 0:
			var ct := create_tween()
			ct.set_speed_scale(speed_scale)
			ct.tween_method(func(v: int) -> void:
				lbl.text = str(v)
			, 0, val, 0.4).set_ease(Tween.EASE_OUT).set_delay(delay + 0.1)

	# Mission results
	_clear_mission_results()
	var btn_delay: float = 1.1
	if state.is_mission_run and not state.active_missions.is_empty():
		_show_mission_results(state.active_missions, speed_scale)
		btn_delay = 1.6

	# Button stagger
	var btn_tween := create_tween()
	btn_tween.set_speed_scale(speed_scale)
	btn_tween.tween_interval(btn_delay)
	btn_tween.tween_property(play_btn, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	btn_tween.tween_interval(0.12)
	btn_tween.tween_property(home_btn, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)


func _clear_mission_results() -> void:
	if is_instance_valid(_mission_results_container):
		_mission_results_container.queue_free()
		_mission_results_container = null


func _show_mission_results(missions: Array, speed_scale: float) -> void:
	_mission_results_container = VBoxContainer.new()
	_mission_results_container.set("theme_override_constants/separation", 6)
	_mission_results_container.modulate.a = 0.0

	var content := $ScrollContainer/Content
	var btn_section := $ScrollContainer/Content/ButtonSection
	content.add_child(_mission_results_container)
	content.move_child(_mission_results_container, btn_section.get_index())

	# Header
	var header := Label.new()
	header.text = "⭐ MISSIONS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _fredoka_bold:
		header.add_theme_font_override("font", _fredoka_bold)
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", Color("#FFD93D"))
	_mission_results_container.add_child(header)

	var total_xp: int = 0
	for m in missions:
		var mission: MissionSystem.Mission = m
		var row := HBoxContainer.new()
		row.set("theme_override_constants/separation", 8)
		_mission_results_container.add_child(row)

		var icon := Label.new()
		if mission.completed:
			icon.text = "✓"
			icon.add_theme_color_override("font_color", Color("#6BCB77"))
			total_xp += mission.xp_reward
		else:
			icon.text = "✕"
			icon.add_theme_color_override("font_color", Color("#EF4444"))
		icon.add_theme_font_size_override("font_size", 13)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)

		var desc := Label.new()
		desc.text = mission.description
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(desc)

		var xp := Label.new()
		if mission.completed:
			xp.text = "+%d XP" % mission.xp_reward
			xp.add_theme_color_override("font_color", Color("#FFD93D"))
		else:
			xp.text = "%d/%d" % [mission.progress, mission.target]
			xp.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
		xp.add_theme_font_size_override("font_size", 11)
		xp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(xp)

	if total_xp > 0:
		var total_label := Label.new()
		total_label.text = "Mission XP: +%d" % total_xp
		total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _fredoka_bold:
			total_label.add_theme_font_override("font", _fredoka_bold)
		total_label.add_theme_font_size_override("font_size", 14)
		total_label.add_theme_color_override("font_color", Color("#FFD93D"))
		_mission_results_container.add_child(total_label)

	var tw := create_tween()
	tw.set_speed_scale(speed_scale)
	tw.tween_interval(1.1)
	tw.tween_property(_mission_results_container, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)


func _start_title_glow(speed_scale: float) -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	_glow_tween = create_tween()
	_glow_tween.set_speed_scale(speed_scale)
	_glow_tween.set_loops()
	_glow_tween.tween_property(title_label, "modulate:a", 0.6, 1.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_glow_tween.tween_property(title_label, "modulate:a", 1.0, 1.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _animate_new_best_glow(speed_scale: float) -> void:
	var badge_tween := create_tween()
	badge_tween.set_speed_scale(speed_scale)
	badge_tween.set_loops()
	badge_tween.tween_property(new_best_badge, "modulate:a", 0.7, 0.8) \
		.set_ease(Tween.EASE_IN_OUT)
	badge_tween.tween_property(new_best_badge, "modulate:a", 1.0, 0.8) \
		.set_ease(Tween.EASE_IN_OUT)


func _update_particles(delta: float) -> void:
	_particle_timer += delta
	if _particle_timer > 0.2:
		_particle_timer = 0.0
		_spawn_particle()

	var to_remove: Array[int] = []
	for i in range(_particles.size()):
		_particles[i]["y"] -= _particles[i]["speed"] * delta  # Rise upward
		_particles[i]["alpha"] -= delta * 0.25
		if _particles[i]["alpha"] <= 0 or _particles[i]["y"] < -20:
			to_remove.append(i)

	for i in range(to_remove.size() - 1, -1, -1):
		_particles.remove_at(to_remove[i])

	particle_layer.particles = _particles
	particle_layer.queue_redraw()


func _spawn_particle() -> void:
	if _particles.size() > 20:
		return
	var p := {
		"x": randf_range(0, size.x),
		"y": size.y + randf_range(5, 20),
		"size": randf_range(4.0, 10.0),
		"speed": randf_range(25.0, 55.0),
		"color": PARTICLE_COLORS[randi() % PARTICLE_COLORS.size()],
		"alpha": randf_range(0.15, 0.35),
		"rotation": randf_range(0, TAU),
	}
	_particles.append(p)


func mark_ad_used() -> void:
	_used_ad_this_game = true
	_continue_btn.visible = false
	_double_btn.visible = false


func reset_ad_state() -> void:
	_used_ad_this_game = false
