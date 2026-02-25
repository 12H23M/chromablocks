extends Control

signal play_again_pressed()
signal go_home_pressed()
signal continue_ad_pressed()
signal double_score_ad_pressed()

@onready var final_score: Label = $Content/ScoreCard/CardVBox/FinalScoreValue
@onready var best_score_label: Label = $Content/ScoreCard/CardVBox/BestScoreLabel
@onready var new_best_badge: PanelContainer = $Content/ScoreCard/CardVBox/NewBestBadge
@onready var lines_value: Label = $Content/ScoreCard/CardVBox/Stats/LinesBox/LinesValue
@onready var blocks_value: Label = $Content/ScoreCard/CardVBox/Stats/BlocksBox/BlocksValue
@onready var combos_value: Label = $Content/ScoreCard/CardVBox/Stats/CombosBox/CombosValue
@onready var grade_label: Label = $Content/GradeLabel
@onready var title_label: Label = $Content/GameOverTitle
@onready var score_card: PanelContainer = $Content/ScoreCard
@onready var stats_container: HBoxContainer = $Content/ScoreCard/CardVBox/Stats
@onready var particle_layer: Control = $ParticleLayer

var _continue_btn: Button
var _double_btn: Button
var _used_ad_this_game := false
var _glow_tween: Tween
var _particle_timer: float = 0.0
var _particles: Array = []

const GRADE_THRESHOLDS := {
	"S": 10000,
	"A": 5000,
	"B": 2000,
}
const GRADE_COLORS := {
	"S": Color(1, 0.84, 0, 1),
	"A": Color(0.65, 0.55, 0.87, 1),
	"B": Color(0.37, 0.73, 0.96, 1),
	"C": Color(0.5, 0.5, 0.5, 1),
}
const PARTICLE_COLORS: Array[Color] = [
	Color(0.37, 0.73, 0.96, 0.4),
	Color(0.42, 0.77, 0.54, 0.4),
	Color(0.65, 0.55, 0.87, 0.4),
	Color(1, 0.49, 0.56, 0.4),
	Color(1, 0.78, 0.32, 0.4),
]


func _ready() -> void:
	$Content/ButtonSection/PlayAgainButton.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		play_again_pressed.emit())
	$Content/ButtonSection/HomeButton.pressed.connect(func():
		SoundManager.play_sfx("button_press")
		go_home_pressed.emit())

	_continue_btn = $Content/AdSection/ContinueAdButton
	_double_btn = $Content/AdSection/DoubleScoreAdButton
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
	best_score_label.text = "BEST: " + FormatUtils.format_number(best)
	best_score_label.visible = true
	new_best_badge.visible = is_new_best

	# Grade setup (hidden initially)
	var grade_str: String = _get_grade(state.score)
	grade_label.text = grade_str
	grade_label.add_theme_color_override("font_color", GRADE_COLORS[grade_str])
	grade_label.modulate.a = 0.0
	grade_label.scale = Vector2(0.3, 0.3)

	# Stats start at 0
	lines_value.text = "0"
	blocks_value.text = "0"
	combos_value.text = "0"

	# Hide stats initially for stagger (alpha only — no position changes in VBox!)
	var lines_box: VBoxContainer = $Content/ScoreCard/CardVBox/Stats/LinesBox
	var blocks_box: VBoxContainer = $Content/ScoreCard/CardVBox/Stats/BlocksBox
	var combos_box: VBoxContainer = $Content/ScoreCard/CardVBox/Stats/CombosBox
	lines_box.modulate.a = 0.0
	blocks_box.modulate.a = 0.0
	combos_box.modulate.a = 0.0

	# Hide buttons initially (alpha only — position in VBox causes overlap!)
	var play_btn: Button = $Content/ButtonSection/PlayAgainButton
	var home_btn: Button = $Content/ButtonSection/HomeButton
	play_btn.modulate.a = 0.0
	home_btn.modulate.a = 0.0

	# Show/hide ad buttons
	var show_ads := not _used_ad_this_game and AdManager.is_rewarded_available()
	_continue_btn.visible = show_ads
	_double_btn.visible = show_ads

	# Entrance animation
	modulate.a = 0.0
	visible = true
	var content := $Content
	var original_y: float = content.position.y
	content.position.y += 30

	# Clear old particles
	_particles.clear()
	particle_layer.queue_redraw()

	var speed_scale: float = 1.0 / maxf(Engine.time_scale, 0.01)

	# --- Main entrance tween ---
	var tween := create_tween()
	tween.set_speed_scale(speed_scale)
	tween.tween_property(self, "modulate:a", 1.0, 0.25) \
		 .set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(content, "position:y", original_y, 0.3) \
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# --- Title glow pulse (looping) ---
	_start_title_glow(speed_scale)

	# --- Grade bounce in ---
	var grade_tween := create_tween()
	grade_tween.set_speed_scale(speed_scale)
	grade_tween.tween_interval(0.35)
	grade_tween.tween_property(grade_label, "modulate:a", 1.0, 0.2)
	grade_tween.parallel().tween_property(grade_label, "scale", Vector2(1.3, 1.3), 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	grade_tween.tween_property(grade_label, "scale", Vector2(1.0, 1.0), 0.15) \
		.set_ease(Tween.EASE_IN_OUT)

	# --- Score counting with bounce ---
	if state.score > 0:
		var count_tween := create_tween()
		count_tween.set_speed_scale(speed_scale)
		var target_score := state.score
		count_tween.tween_method(func(value: int) -> void:
			final_score.text = FormatUtils.format_number(value)
		, 0, target_score, 0.8).set_ease(Tween.EASE_OUT).set_delay(0.4)

		# Bounce at end of count
		var bounce_tween := create_tween()
		bounce_tween.set_speed_scale(speed_scale)
		bounce_tween.tween_interval(1.2)
		bounce_tween.tween_property(final_score, "scale", Vector2(1.15, 1.15), 0.1) \
			.set_ease(Tween.EASE_OUT)
		bounce_tween.tween_property(final_score, "scale", Vector2(1.0, 1.0), 0.15) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BOUNCE)

	# --- New best glow border ---
	if is_new_best:
		_animate_new_best_glow(speed_scale)

	# --- Stats stagger animation ---
	var stat_boxes: Array[VBoxContainer] = [lines_box, blocks_box, combos_box]
	var stat_values: Array[int] = [state.lines_cleared, state.blocks_placed, state.max_combo]
	var stat_labels: Array[Label] = [lines_value, blocks_value, combos_value]

	for i in range(3):
		var box: VBoxContainer = stat_boxes[i]
		var val: int = stat_values[i]
		var lbl: Label = stat_labels[i]
		var delay: float = 0.6 + i * 0.15

		var st := create_tween()
		st.set_speed_scale(speed_scale)
		st.tween_interval(delay)
		st.tween_property(box, "modulate:a", 1.0, 0.25) \
			.set_ease(Tween.EASE_OUT)

		if val > 0:
			var ct := create_tween()
			ct.set_speed_scale(speed_scale)
			ct.tween_method(func(v: int) -> void:
				lbl.text = str(v)
			, 0, val, 0.4).set_ease(Tween.EASE_OUT).set_delay(delay + 0.1)

	# --- Button stagger (alpha only) ---
	var btn_tween := create_tween()
	btn_tween.set_speed_scale(speed_scale)
	btn_tween.tween_interval(1.1)
	btn_tween.tween_property(play_btn, "modulate:a", 1.0, 0.25) \
		.set_ease(Tween.EASE_OUT)
	btn_tween.tween_interval(0.15)
	btn_tween.tween_property(home_btn, "modulate:a", 1.0, 0.25) \
		.set_ease(Tween.EASE_OUT)


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
	if _particle_timer > 0.15:
		_particle_timer = 0.0
		_spawn_particle()

	var to_remove: Array[int] = []
	for i in range(_particles.size()):
		_particles[i]["y"] += _particles[i]["speed"] * delta
		_particles[i]["alpha"] -= delta * 0.3
		if _particles[i]["alpha"] <= 0 or _particles[i]["y"] > size.y:
			to_remove.append(i)

	for i in range(to_remove.size() - 1, -1, -1):
		_particles.remove_at(to_remove[i])

	particle_layer.particles = _particles
	particle_layer.queue_redraw()


func _spawn_particle() -> void:
	if _particles.size() > 30:
		return
	var p := {
		"x": randf_range(0, size.x),
		"y": randf_range(-20, -5),
		"size": randf_range(3.0, 8.0),
		"speed": randf_range(20.0, 50.0),
		"color": PARTICLE_COLORS[randi() % PARTICLE_COLORS.size()],
		"alpha": randf_range(0.2, 0.5),
		"rotation": randf_range(0, TAU),
	}
	_particles.append(p)


func mark_ad_used() -> void:
	_used_ad_this_game = true
	_continue_btn.visible = false
	_double_btn.visible = false


func reset_ad_state() -> void:
	_used_ad_this_game = false
