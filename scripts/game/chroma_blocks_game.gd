extends Node

signal state_changed(state: GameState)
signal game_over_triggered()

@onready var board_renderer: Control = %Board
@onready var piece_tray: VBoxContainer = %PieceTray
@onready var hud: Control = %HUD
@onready var home_screen: Control = %HomeScreen
@onready var game_over_screen: Control = %GameOverScreen
@onready var pause_screen: Control = %PauseScreen
@onready var settings_screen: Control = %SettingsScreen
@onready var tutorial_overlay: Control = %TutorialOverlay
@onready var drag_layer: Control = %DragLayer

var _state: GameState
var _piece_gen := PieceGenerator.new()
var _pending_action := ""
var _is_daily_mode := false  # 일일 챌린지 모드 플래그
var _color_match_count := 0  # 누적 컬러 매치 횟수 (업적용)
var _had_perfect_clear := false  # 퍼펙트 클리어 발생 여부 (업적용)
var _hit_stop_duration := 0.0  # 현재 진행 중인 히트 스톱 잔여 시간
var _hit_stop_id := 0  # Monotonic counter to track the active hit stop

func _ready() -> void:
	_state = GameState.new()
	_state.high_score = SaveManager.get_high_score()
	board_renderer.initialize()

	# Set tray cell size based on board cell size
	piece_tray.set_cell_size(board_renderer.get_cell_size())

	piece_tray.piece_drag_started.connect(_on_drag_started)
	piece_tray.piece_drag_moved.connect(_on_drag_moved)
	piece_tray.piece_drag_ended.connect(_on_drag_ended)

	home_screen.start_pressed.connect(start_game)
	home_screen.continue_pressed.connect(continue_game)
	home_screen.daily_pressed.connect(start_daily_challenge)
	game_over_screen.play_again_pressed.connect(start_game)
	game_over_screen.go_home_pressed.connect(_on_go_home)
	game_over_screen.continue_ad_pressed.connect(_on_continue_ad)
	game_over_screen.double_score_ad_pressed.connect(_on_double_score_ad)
	AdManager.rewarded_ad_completed.connect(_on_rewarded_completed)
	AdManager.interstitial_closed.connect(_on_interstitial_closed)
	pause_screen.resume_pressed.connect(resume_game)
	pause_screen.quit_pressed.connect(_on_quit_to_home)
	home_screen.settings_pressed.connect(_show_settings)
	home_screen.how_to_play_pressed.connect(_show_tutorial)
	settings_screen.closed.connect(_hide_settings)
	piece_tray.swap_pressed.connect(_on_swap_pressed)

	var pause_btn := hud.get_node_or_null("TopBar/PauseButton")
	if pause_btn:
		pause_btn.pressed.connect(pause_game)

	var splash := get_node_or_null("UILayer/SplashScreen")
	if splash:
		home_screen.visible = false
		%Board.visible = false
		hud.visible = false
		piece_tray.visible = false
		splash.intro_finished.connect(func():
			%Board.visible = true
			hud.visible = true
			piece_tray.visible = true
			_show_home()
		)
	else:
		_show_home()

# ── Public API ──

func start_game() -> void:
	_start_new_game(false)

## 일일 챌린지 시작 — 오늘 날짜 기반 시드 사용
func start_daily_challenge() -> void:
	if DailyChallengeSystem.has_played_today():
		var best := DailyChallengeSystem.get_daily_best()
		print("[Daily] Already played today. Best: %d — replaying." % best)
	_start_new_game(true)

func _start_new_game(daily: bool) -> void:
	Engine.time_scale = 1.0
	_hit_stop_duration = 0.0
	_is_daily_mode = daily
	SaveManager.clear_active_game()
	_state.reset()
	_piece_gen.reset()
	if daily:
		_piece_gen.set_seed(DailyChallengeSystem.get_today_seed())
	_state.high_score = SaveManager.get_high_score()
	_state.status = Enums.GameStatus.PLAYING
	SaveManager.increment_games_played()
	game_over_screen.reset_ad_state()

	var tray := _piece_gen.generate_tray(_state.level, _state.board)
	_state.tray_pieces = tray

	board_renderer.update_from_state(_state.board)
	board_renderer.update_crisis_state(_state.board)
	piece_tray.populate_tray(tray)
	hud.update_from_state(_state)
	piece_tray.update_swap_state(_state.swaps_remaining)

	ScreenTransition.fade_out(home_screen)
	ScreenTransition.fade_out(game_over_screen)
	ScreenTransition.fade_out(pause_screen)

	_color_match_count = 0
	_had_perfect_clear = false
	var mode := "daily" if daily else "normal"
	AnalyticsManager.game_start(mode)
	if daily:
		AnalyticsManager.daily_challenge_start()
	state_changed.emit(_state)


func continue_game() -> void:
	Engine.time_scale = 1.0
	_hit_stop_duration = 0.0
	var saved_state := SaveManager.load_active_game()
	if saved_state == null:
		start_game()
		return
	_state = saved_state
	_state.high_score = SaveManager.get_high_score()
	_state.status = Enums.GameStatus.PLAYING
	board_renderer.update_from_state(_state.board)
	piece_tray.populate_tray(_state.tray_pieces)
	hud.update_from_state(_state)
	piece_tray.update_swap_state(_state.swaps_remaining)
	ScreenTransition.fade_out(home_screen)
	ScreenTransition.fade_out(game_over_screen)
	ScreenTransition.fade_out(pause_screen)
	SaveManager.clear_active_game()
	state_changed.emit(_state)

func pause_game() -> void:
	SoundManager.play_sfx("button_press")
	_state.status = Enums.GameStatus.PAUSED
	var tween := board_renderer.create_tween()
	tween.tween_property(board_renderer, "modulate:a", 0.3, 0.2)
	piece_tray.modulate.a = 0.3
	ScreenTransition.slide_up_in(pause_screen)

func resume_game() -> void:
	_state.status = Enums.GameStatus.PLAYING
	board_renderer.modulate.a = 1.0
	piece_tray.modulate.a = 1.0
	ScreenTransition.fade_out(pause_screen)

# ── Drag & Drop ──

var _dragging_piece: BlockPiece = null
var _last_grid_pos := Vector2i(-1, -1)
var _drag_placeholder: Control = null

func _on_drag_started(piece_node: Control) -> void:
	if _state.status != Enums.GameStatus.PLAYING:
		return
	_dragging_piece = piece_node.piece_data
	HapticManager.drag_start()

	# Create placeholder to maintain tray layout while piece is dragged
	var idx := piece_node.get_index()
	_drag_placeholder = Control.new()
	_drag_placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_drag_placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL

	piece_node.reparent(drag_layer)
	piece_tray.add_placeholder(_drag_placeholder, idx)

func _on_drag_moved(piece_node: Control, global_pos: Vector2) -> void:
	if _dragging_piece == null:
		return
	var grid_pos := _piece_to_grid(piece_node)

	if grid_pos != _last_grid_pos:
		_last_grid_pos = grid_pos
		HapticManager.grid_snap()
		var can_place := PlacementSystem.can_place(
			_state.board, _dragging_piece, grid_pos.x, grid_pos.y)
		board_renderer.show_highlight(grid_pos.x, grid_pos.y, _dragging_piece, can_place)
		if can_place:
			board_renderer.show_line_prediction(grid_pos.x, grid_pos.y, _dragging_piece, _state.board)
		else:
			board_renderer.clear_line_prediction()

func _on_drag_ended(piece_node: Control, global_pos: Vector2) -> void:
	if _dragging_piece == null:
		return
	board_renderer.clear_highlights()
	board_renderer.clear_line_prediction()
	var grid_pos := _piece_to_grid(piece_node)

	var can_place := PlacementSystem.can_place(
		_state.board, _dragging_piece, grid_pos.x, grid_pos.y)

	if can_place:
		piece_node.remove_from_tray()
		_place_piece(_dragging_piece, grid_pos.x, grid_pos.y)
		# Placeholder stays in tray to maintain slot layout (cleared on refill)
		_drag_placeholder = null
	else:
		# Place-fail feedback
		SoundManager.play_sfx("place_fail")
		HapticManager.medium()
		# Animate piece back in drag_layer, then swap placeholder for piece
		var tween: Tween = piece_node.return_to_tray()
		var placeholder := _drag_placeholder
		_drag_placeholder = null
		tween.tween_callback(func():
			if is_instance_valid(placeholder) and is_instance_valid(piece_node):
				var idx := placeholder.get_index()
				piece_tray.remove_placeholder(placeholder)
				piece_node.reparent(piece_tray.get_pieces_container())
				piece_tray.get_pieces_container().move_child(piece_node, idx)
		)

	_dragging_piece = null
	_last_grid_pos = Vector2i(-1, -1)

func _piece_to_grid(piece_node: Control) -> Vector2i:
	var center := piece_node.global_position + piece_node.size / 2.0
	var local_center := board_renderer.get_global_transform().affine_inverse() * center
	var cell_size: float = board_renderer.get_cell_size()
	var gx := roundi(local_center.x / cell_size - _dragging_piece.width / 2.0)
	var gy := roundi(local_center.y / cell_size - _dragging_piece.height / 2.0)
	return Vector2i(gx, gy)

# ── Core Game Logic ──

func _place_piece(piece: BlockPiece, gx: int, gy: int) -> void:
	SoundManager.play_sfx("block_place")
	HapticManager.light()

	# 1. Place on board
	var board := _state.board.place_piece(piece, gx, gy)

	# 2. Line clear
	var clear_result := ClearSystem.check_and_clear(board)
	board = clear_result["board"]

	# 3. Color match (toggle via GameConstants.COLOR_MATCH_ENABLED)
	var color_result: Dictionary
	if GameConstants.COLOR_MATCH_ENABLED:
		color_result = ColorMatchSystem.check_color_match(board)
		board = color_result["board"]
	else:
		color_result = {"board": board, "groups": [], "total_removed": 0, "has_matches": false}

	# 4. Scoring
	var did_clear: bool = clear_result["lines_cleared"] > 0 or color_result["has_matches"]
	var new_combo: int = (_state.combo + 1) if did_clear else 0

	var score_result := ScoringSystem.calculate(
		piece.cell_count, clear_result, color_result, new_combo, _state.level)

	# 5. Level check
	var total_lines: int = _state.lines_cleared + clear_result["lines_cleared"]
	var new_level: int = DifficultySystem.calculate_level(total_lines)
	var leveled_up: bool = new_level > _state.level

	# 6. Update state
	_state.apply_turn_result(board, score_result["total"],
		clear_result["lines_cleared"], new_combo, new_level, piece)

	# 7. Effects BEFORE visual state update (so cells still have their colors)
	var has_clear: bool = clear_result["has_clears"]

	if has_clear:
		var lines: int = clear_result["lines_cleared"]
		# Freeze-frame hit stop — short and sharp
		if lines >= 3:
			_apply_hit_stop(0.05)
		else:
			_apply_hit_stop(0.03)
		# Play clear effect BEFORE update_from_state so cells still know their color
		board_renderer.play_line_clear_effect(clear_result["rows"], clear_result["cols"])
		SoundManager.play_sfx("line_clear")
		HapticManager.line_clear_burst(lines)
		if lines >= 2:
			_spawn_multi_clear_popup(lines)
		AnalyticsManager.line_clear(lines, new_combo)
		# Screen shake: boosted intensity for post-freeze punch
		if lines >= 3:
			board_renderer.play_screen_shake(9.0, 0.20)
		elif lines >= 2:
			board_renderer.play_screen_shake(6.0, 0.15)
		else:
			board_renderer.play_screen_shake(4.0, 0.10)

	if color_result["has_matches"]:
		_apply_hit_stop(0.03)
		# Play color match BEFORE update_from_state so cells still have colors
		board_renderer.play_color_match_effect(color_result["groups"])
		SoundManager.play_sfx("color_match")
		HapticManager.color_match()
		_color_match_count += color_result["groups"].size()
		var total_cells := 0
		for g in color_result["groups"]:
			total_cells += g.size()
		AnalyticsManager.color_match(color_result["groups"].size(), total_cells)

	# NOW update visual state (cells become empty)
	board_renderer.update_from_state(board)
	hud.update_from_state(_state)

	# Crisis warning (board density check)
	board_renderer.update_crisis_state(board)

	# Placement pulse on newly placed cells
	board_renderer.play_place_effect(piece.occupied_cells_at(gx, gy))
	AnalyticsManager.piece_placed(Enums.PieceType.keys()[piece.type], gx, gy)

	# Micro-bounce only when no clear (shake replaces it on clears)
	if not has_clear:
		board_renderer.play_place_bounce()

	if new_combo >= 1:
		if new_combo >= 2:
			SoundManager.play_combo_sfx(new_combo)
		HapticManager.combo(new_combo)
		_spawn_combo_popup(new_combo)
		if new_combo >= 3:
			_apply_hit_stop(0.05)

	if score_result["total"] > 0:
		_spawn_score_popup(score_result["total"], gx, gy)

	if clear_result.get("is_perfect", false):
		_apply_hit_stop(0.09)
		_spawn_score_popup(GameConstants.PERFECT_CLEAR_BONUS, 5, 5)
		SoundManager.play_sfx("perfect_clear")
		board_renderer.play_screen_shake(10.0, 0.25)
		HapticManager.perfect_clear()
		_had_perfect_clear = true

	if leveled_up:
		SoundManager.play_sfx("level_up")
		HapticManager.level_up()
		board_renderer.play_level_up_effect()

	# 10. Tray refill or game over
	if _state.tray_pieces.is_empty():
		_refill_tray()
	else:
		_check_game_over()

	state_changed.emit(_state)

func _on_swap_pressed() -> void:
	if _state.status != Enums.GameStatus.PLAYING:
		return
	if _state.swaps_remaining <= 0 or _state.tray_pieces.is_empty():
		return
	# Replace the first remaining piece with a new random one
	var old_piece: BlockPiece = _state.tray_pieces[0]
	var new_tray_single := _piece_gen.generate_tray(_state.level, _state.board)
	var new_piece: BlockPiece = new_tray_single[0]
	_state.tray_pieces[0] = new_piece
	_state.swaps_remaining -= 1
	piece_tray.populate_tray(_state.tray_pieces, true)
	hud.update_from_state(_state)
	piece_tray.update_swap_state(_state.swaps_remaining)
	SoundManager.play_sfx("block_place")
	HapticManager.light()
	AnalyticsManager.swap_used()
	_check_game_over()

func _refill_tray() -> void:
	var new_tray := _piece_gen.generate_tray(_state.level, _state.board)
	_state.tray_pieces = new_tray
	_state.swaps_remaining = 1
	piece_tray.populate_tray(new_tray, true)
	hud.update_from_state(_state)
	piece_tray.update_swap_state(_state.swaps_remaining)
	_check_game_over()

func _check_game_over() -> void:
	if GameOverSystem.is_game_over(_state.board, _state.tray_pieces):
		# Ensure time_scale is restored if game over triggers during hit stop
		Engine.time_scale = 1.0
		_hit_stop_duration = 0.0
		_state.status = Enums.GameStatus.GAME_OVER
		SaveManager.clear_active_game()
		SaveManager.save_end_of_game(_state.score)
		# 일일 챌린지 모드 시 결과 저장
		if _is_daily_mode:
			DailyChallengeSystem.save_daily_result(_state.score)
			AnalyticsManager.daily_challenge_complete(_state.score)
		# 분석 이벤트
		var mode := "daily" if _is_daily_mode else "normal"
		AnalyticsManager.game_over(_state.score, _state.level, _state.lines_cleared, _state.max_combo, mode)
		# 업적 체크
		var daily_streak := DailyChallengeSystem.get_streak()
		var newly_unlocked := AchievementSystem.check_end_of_game(
			_state.score, _state.max_combo, _state.level,
			_state.lines_cleared, _color_match_count, _had_perfect_clear,
			SaveManager.get_games_played(), daily_streak)
		if not newly_unlocked.is_empty():
			print("[Achievement] Unlocked: %s" % str(newly_unlocked))
		AdManager.on_game_ended()
		SoundManager.play_sfx("game_over")
		HapticManager.game_over()
		game_over_screen.show_result(_state)
		game_over_triggered.emit()

func _apply_hit_stop(duration: float) -> void:
	# If a hit stop is already in progress, only replace with longer duration
	if _hit_stop_duration >= duration:
		return
	_hit_stop_duration = duration
	_hit_stop_id += 1
	var current_id := _hit_stop_id
	# Freeze-frame hit stop: tweens and _process receive delta=0 during the
	# pause, then resume at full speed.  Sound/haptics are unaffected.
	Engine.time_scale = 0.0
	var tree := get_tree()
	if tree == null:
		Engine.time_scale = 1.0
		return
	var timer := tree.create_timer(duration, true, false, true)
	timer.timeout.connect(func():
		# Guard against node being freed during hit stop
		if not is_instance_valid(self):
			Engine.time_scale = 1.0
			return
		# Only restore if this is still the active hit stop
		if _hit_stop_id == current_id:
			Engine.time_scale = 1.0
			_hit_stop_duration = 0.0
	)

func _spawn_combo_popup(combo: int) -> void:
	var popup := Control.new()
	popup.set_script(preload("res://scripts/game/combo_popup.gd"))
	# Add to a dedicated CanvasLayer so it renders on top of everything
	var overlay_layer := CanvasLayer.new()
	overlay_layer.layer = 20  # Above UI (default layer 1)
	add_child(overlay_layer)
	overlay_layer.add_child(popup)
	var board_center := board_renderer.global_position + board_renderer.size / 2.0
	popup.show_combo(combo, board_center)
	# Clean up the CanvasLayer when popup is freed
	popup.tree_exited.connect(overlay_layer.queue_free)

func _spawn_multi_clear_popup(lines: int) -> void:
	var popup := Control.new()
	popup.set_script(preload("res://scripts/game/multi_clear_popup.gd"))
	var overlay_layer := CanvasLayer.new()
	overlay_layer.layer = 19  # Behind combo (20) but above game
	add_child(overlay_layer)
	overlay_layer.add_child(popup)
	var board_center := board_renderer.global_position + board_renderer.size / 2.0
	popup.show_multi_clear(lines, board_center)
	popup.tree_exited.connect(overlay_layer.queue_free)

func _spawn_score_popup(value: int, gx: int, gy: int) -> void:
	var popup := Label.new()
	popup.set_script(preload("res://scripts/game/score_popup.gd"))
	drag_layer.add_child(popup)
	var cell_size: float = board_renderer.get_cell_size()
	var pos := board_renderer.global_position + Vector2(gx * cell_size, gy * cell_size)
	popup.show_score(value, pos)

func _on_quit_to_home() -> void:
	# Ensure time_scale is restored if quitting during hit stop
	Engine.time_scale = 1.0
	_hit_stop_duration = 0.0
	board_renderer.modulate.a = 1.0
	piece_tray.modulate.a = 1.0
	_show_home()

func _on_go_home() -> void:
	if AdManager.should_show_interstitial():
		_pending_action = "home"
		AnalyticsManager.ad_shown("interstitial")
		AdManager.show_interstitial()
	else:
		_show_home()

func _on_interstitial_closed() -> void:
	if _pending_action == "home":
		_show_home()
	_pending_action = ""

func _show_home() -> void:
	home_screen.refresh_stats()
	ScreenTransition.fade_in(home_screen)
	ScreenTransition.fade_out(game_over_screen)
	ScreenTransition.fade_out(pause_screen)

func _show_settings() -> void:
	ScreenTransition.fade_in(settings_screen)

func _hide_settings() -> void:
	ScreenTransition.fade_out(settings_screen)

func _show_tutorial() -> void:
	AnalyticsManager.tutorial_started()
	tutorial_overlay.show_tutorial()

# ── Rewarded Ad Handlers ──

func _on_continue_ad() -> void:
	AnalyticsManager.ad_shown("rewarded_continue")
	AdManager.show_rewarded("continue")

func _on_double_score_ad() -> void:
	AnalyticsManager.ad_shown("rewarded_double_score")
	AdManager.show_rewarded("double_score")

func _on_rewarded_completed(reward_type: String) -> void:
	AnalyticsManager.ad_reward_claimed(reward_type)
	game_over_screen.mark_ad_used()
	match reward_type:
		"continue":
			_continue_after_ad()
		"double_score":
			_double_score_after_ad()

func _continue_after_ad() -> void:
	# Clear bottom 3 rows of the board and resume play
	var board := _state.board
	var new_grid := board._copy_grid()
	for y in range(board.rows - 3, board.rows):
		for x in board.columns:
			new_grid[y][x] = {"occupied": false, "color": -1}
	_state.board = BoardState.new(board.columns, board.rows, new_grid)
	_state.status = Enums.GameStatus.PLAYING

	# Refill tray
	var new_tray := _piece_gen.generate_tray(_state.level, _state.board)
	_state.tray_pieces = new_tray

	board_renderer.update_from_state(_state.board)
	board_renderer.update_crisis_state(_state.board)
	piece_tray.populate_tray(new_tray, true)
	hud.update_from_state(_state)
	piece_tray.update_swap_state(_state.swaps_remaining)

	ScreenTransition.fade_out(game_over_screen)
	state_changed.emit(_state)

func _double_score_after_ad() -> void:
	var bonus := _state.score
	_state.score += bonus
	SaveManager.save_end_of_game(bonus)  # Save additional score
	hud.update_from_state(_state)
	piece_tray.update_swap_state(_state.swaps_remaining)
	game_over_screen.show_result(_state)

func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _state.status == Enums.GameStatus.PLAYING:
			# 일일 챌린지 모드에서는 중간 저장하지 않음 (시드 기반이므로)
			if not _is_daily_mode:
				SaveManager.save_active_game(_state)
