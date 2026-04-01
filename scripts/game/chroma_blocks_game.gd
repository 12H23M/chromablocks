extends Node

signal state_changed(state: GameState)
signal game_over_triggered()

# Preload systems to ensure class_name resolution
const NearMissAnalyzerScript := preload("res://scripts/systems/near_miss_analyzer.gd")

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
var _is_time_attack := false  # 타임어택 모드 플래그
var _time_remaining: float = 0.0  # 타임어택 남은 시간
var _time_attack_active := false  # 타이머 진행 중
var _is_mission_run := false
var _mission_select_overlay: Control = null
var _mission_hud: VBoxContainer = null
var _all_missions_completed_shown := false
var _color_match_count := 0  # 누적 컬러 매치 횟수 (업적용)
var _had_perfect_clear := false  # 퍼펙트 클리어 발생 여부 (업적용)
var _hit_stop_duration := 0.0  # 현재 진행 중인 히트 스톱 잔여 시간
var _hit_stop_id := 0  # Monotonic counter to track the active hit stop
var _game_orbs: Array = []
var _next_tray_pieces: Array = []
var _daily_bonus_active := false  # 데일리 보너스 (첫 게임 점수 x2)
var _bomb_reward_pending := false  # 폭탄 블록 보상 대기 중 (10콤보 달성 시)

# ── Auto-play ──
var _auto_player := AutoPlayer.new()
var _auto_play_enabled := false
var _auto_play_timer: Timer = null

func _ready() -> void:
	_apply_safe_area()
	_state = GameState.new()
	_state.high_score = SaveManager.get_high_score()
	board_renderer.initialize()
	_create_game_orbs()

	# Set tray cell size based on board cell size
	piece_tray.set_cell_size(board_renderer.get_cell_size())

	piece_tray.piece_drag_started.connect(_on_drag_started)
	piece_tray.piece_drag_moved.connect(_on_drag_moved)
	piece_tray.piece_drag_ended.connect(_on_drag_ended)
	board_renderer.cell_tapped.connect(_on_cell_tapped)

	home_screen.start_pressed.connect(start_game)
	home_screen.continue_pressed.connect(continue_game)
	home_screen.daily_pressed.connect(start_daily_challenge)
	home_screen.mission_pressed.connect(_show_mission_select)
	home_screen.time_attack_pressed.connect(start_time_attack)
	game_over_screen.play_again_pressed.connect(_on_restart_from_game_over)
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
	piece_tray.hold_pressed.connect(_on_hold_pressed)

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
			_show_home_initial()
		)
	else:
		_show_home_initial()

	# Auto-play timer
	_auto_play_timer = Timer.new()
	_auto_play_timer.wait_time = 0.3
	_auto_play_timer.one_shot = false
	_auto_play_timer.timeout.connect(_on_auto_play_tick)
	add_child(_auto_play_timer)

	# Create mission HUD (hidden by default) — insert after HudSpacer in GameUI
	_mission_hud = VBoxContainer.new()
	_mission_hud.set_script(load("res://scripts/ui/mission_hud.gd"))
	var game_ui := get_node("UILayer/GameUI")
	var hud_spacer := game_ui.get_node("HudSpacer")
	game_ui.add_child(_mission_hud)
	game_ui.move_child(_mission_hud, hud_spacer.get_index() + 1)
	var mission_hud_margin := MarginContainer.new()
	mission_hud_margin.name = "MissionHudMargin"
	mission_hud_margin.add_theme_constant_override("margin_left", 14)
	mission_hud_margin.add_theme_constant_override("margin_right", 14)
	game_ui.add_child(mission_hud_margin)
	game_ui.move_child(mission_hud_margin, hud_spacer.get_index() + 1)
	_mission_hud.reparent(mission_hud_margin)

# ── Public API ──

func start_game() -> void:
	_start_new_game(false)

## 일일 챌린지 시작 — 오늘 날짜 기반 시드 사용
func start_daily_challenge() -> void:
	if DailyChallengeSystem.has_played_today():
		var best := DailyChallengeSystem.get_daily_best()
		print("[Daily] Already played today. Best: %d — replaying." % best)
	_start_new_game(true)


## 타임어택 시작 — 60초 동안 최대 점수 달성
func start_time_attack() -> void:
	_start_new_game(false, false, [], true)


func _show_mission_select() -> void:
	if is_instance_valid(_mission_select_overlay):
		_mission_select_overlay.queue_free()
	_mission_select_overlay = Control.new()
	_mission_select_overlay.set_script(load("res://scripts/ui/mission_select_overlay.gd"))
	var ui_layer: CanvasLayer = get_node("UILayer")
	ui_layer.add_child(_mission_select_overlay)
	_mission_select_overlay.start_mission_run.connect(_on_mission_start)
	_mission_select_overlay.back_pressed.connect(func():
		if is_instance_valid(_mission_select_overlay):
			_mission_select_overlay.queue_free()
			_mission_select_overlay = null)


func _on_mission_start(missions: Array) -> void:
	if is_instance_valid(_mission_select_overlay):
		_mission_select_overlay.queue_free()
		_mission_select_overlay = null
	_start_new_game(false, true, missions)


func _start_new_game(daily: bool, mission_run: bool = false, missions: Array = [], time_attack: bool = false) -> void:
	ScreenTransition.fade_through_black(get_tree(), func() -> void:
		Engine.time_scale = 1.0
		_hit_stop_duration = 0.0
		_is_daily_mode = daily
		_is_time_attack = time_attack
		_time_attack_active = false
		_time_remaining = GameConstants.TIME_ATTACK_DURATION
		MusicManager.set_intensity(0)
		SaveManager.clear_active_game()
		_state.reset()
		_piece_gen.reset()
		if daily:
			_piece_gen.set_seed(DailyChallengeSystem.get_today_seed())
		_state.high_score = SaveManager.get_high_score()
		_state.status = Enums.GameStatus.PLAYING
		# Prefill board for exciting start (30% fill, color clusters)
		_prefill_board(_state.board)
		SaveManager.increment_games_played()
		game_over_screen.reset_ad_state()
		hud.reset_new_best()

		var tray := _piece_gen.generate_tray(_state.level, _state.board)

		# First game gift: add a special gift piece to tray
		if SaveManager.is_first_gift_available():
			var gift_piece := _create_gift_piece()
			tray.append(gift_piece)
			print("[Gift] First game gift piece added to tray!")

		_state.tray_pieces = tray
		_next_tray_pieces = _piece_gen.generate_tray(_state.level, _state.board)

		board_renderer.enable_gems()
		board_renderer.update_from_state(_state.board)
		board_renderer.update_crisis_state(_state.board)
		# board_renderer.update_near_miss_hints(_state.board)
		piece_tray.populate_tray(tray)
		piece_tray.update_hold_display(_state.held_piece, not _state.hold_used_this_tray)
		piece_tray.update_next_preview(_next_tray_pieces)
		hud.update_from_state(_state)

		get_node("UILayer/GameUI").visible = true
		home_screen.visible = false
		home_screen.modulate.a = 1.0
		game_over_screen.visible = false
		game_over_screen.modulate.a = 1.0
		pause_screen.visible = false
		pause_screen.modulate.a = 1.0

		_color_match_count = 0
		_had_perfect_clear = false

		# Daily bonus: consume if available
		_daily_bonus_active = SaveManager.is_daily_bonus_available()
		if _daily_bonus_active:
			SaveManager.consume_daily_bonus()

		# Mission run setup — missions activate in ALL modes when MISSION_ALWAYS_ACTIVE
		var effective_mission_run: bool = mission_run
		var effective_missions: Array = missions
		if not effective_mission_run and GameConstants.MISSION_ALWAYS_ACTIVE:
			effective_mission_run = true
			effective_missions = MissionSystem.generate_missions()
		_is_mission_run = effective_mission_run
		_all_missions_completed_shown = false
		_state.is_mission_run = effective_mission_run
		if effective_mission_run and not effective_missions.is_empty():
			_state.active_missions = effective_missions
			_mission_hud.setup(effective_missions)
		else:
			_state.active_missions = []
			_mission_hud.hide_hud()

		var mode := "time_attack" if time_attack else ("daily" if daily else ("mission" if mission_run else ("normal+mission" if effective_mission_run else "normal")))
		AnalyticsManager.game_start(mode)
		if daily:
			AnalyticsManager.daily_challenge_start()

		# Start time attack timer
		if time_attack:
			_start_time_attack()

		# Auto-play: restart timer if enabled
		if _auto_play_enabled:
			_auto_player.reset_stats()
			_auto_play_timer.start()

		state_changed.emit(_state)
	)


func continue_game() -> void:
	var saved_state := SaveManager.load_active_game()
	if saved_state == null:
		start_game()
		return
	ScreenTransition.fade_through_black(get_tree(), func() -> void:
		Engine.time_scale = 1.0
		_hit_stop_duration = 0.0
		_state = saved_state
		_state.high_score = SaveManager.get_high_score()
		_state.status = Enums.GameStatus.PLAYING
		hud.reset_new_best()
		board_renderer.update_from_state(_state.board)
		piece_tray.populate_tray(_state.tray_pieces)
		piece_tray.update_hold_display(_state.held_piece, not _state.hold_used_this_tray)
		_next_tray_pieces = _piece_gen.generate_tray(_state.level, _state.board)
		piece_tray.update_next_preview(_next_tray_pieces)
		hud.update_from_state(_state)

		get_node("UILayer/GameUI").visible = true
		home_screen.visible = false
		home_screen.modulate.a = 1.0
		game_over_screen.visible = false
		game_over_screen.modulate.a = 1.0
		pause_screen.visible = false
		pause_screen.modulate.a = 1.0

		SaveManager.clear_active_game()
	)
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

		# Bomb piece: show 3x3 explosion preview
		if _dragging_piece.type == Enums.PieceType.BOMB:
			var in_bounds := grid_pos.x >= 0 and grid_pos.x < _state.board.columns \
					and grid_pos.y >= 0 and grid_pos.y < _state.board.rows
			board_renderer.show_bomb_highlight(grid_pos.x, grid_pos.y, in_bounds)
			return

		var can_place := PlacementSystem.can_place(
			_state.board, _dragging_piece, grid_pos.x, grid_pos.y)
		board_renderer.show_highlight(grid_pos.x, grid_pos.y, _dragging_piece, can_place)
		if can_place:
			board_renderer.show_line_prediction(grid_pos.x, grid_pos.y, _dragging_piece, _state.board)
			# Blast proximity hint — only on lines that will actually complete
			var predicted := _state.board.predict_completed_lines(_dragging_piece, grid_pos.x, grid_pos.y)
			var pred_rows: Array = predicted["rows"]
			var pred_cols: Array = predicted["cols"]
			if not pred_rows.is_empty() or not pred_cols.is_empty():
				var virtual_board := _state.board.place_piece(_dragging_piece, grid_pos.x, grid_pos.y)
				var blast_potential := ChromaBlastSystem.check_blast_potential(virtual_board)
				# Filter blast hints to only completed lines
				var hint_rows: Array = []
				for r in blast_potential["rows"]:
					if r in pred_rows:
						hint_rows.append(r)
				var hint_cols: Array = []
				for c in blast_potential["cols"]:
					if c in pred_cols:
						hint_cols.append(c)
				if not hint_rows.is_empty() or not hint_cols.is_empty():
					board_renderer.show_blast_hint(hint_rows, hint_cols)
				else:
					board_renderer.clear_blast_hint()
			else:
				board_renderer.clear_blast_hint()
		else:
			board_renderer.clear_line_prediction()
			board_renderer.clear_blast_hint()

func _on_drag_ended(piece_node: Control, global_pos: Vector2) -> void:
	if _dragging_piece == null:
		return
	board_renderer.clear_highlights()
	board_renderer.clear_line_prediction()
	board_renderer.clear_blast_hint()
	var grid_pos := _piece_to_grid(piece_node)

	# Bombs can be placed anywhere within bounds (they explode)
	var can_place := false
	if _dragging_piece.type == Enums.PieceType.BOMB:
		can_place = grid_pos.x >= 0 and grid_pos.x < _state.board.columns \
				and grid_pos.y >= 0 and grid_pos.y < _state.board.rows
	else:
		can_place = PlacementSystem.can_place(
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
	# The piece node's drawn blocks are centered within its Control rect.
	# We need the top-left corner of the drawn piece area in global coords.
	var piece_pixel_w: float = _dragging_piece.width * piece_node._cell_size
	var piece_pixel_h: float = _dragging_piece.height * piece_node._cell_size
	var draw_offset_x: float = (piece_node.size.x - piece_pixel_w) / 2.0
	var draw_offset_y: float = (piece_node.size.y - piece_pixel_h) / 2.0

	# Account for scale: global_position is the scaled node's top-left,
	# and drawn content is offset by draw_offset * scale
	var current_scale: float = piece_node.scale.x
	var piece_center_global := piece_node.global_position + Vector2(
		draw_offset_x * current_scale + piece_pixel_w * current_scale / 2.0,
		draw_offset_y * current_scale + piece_pixel_h * current_scale / 2.0
	)

	var local_center := board_renderer.get_global_transform().affine_inverse() * piece_center_global
	var cell_size: float = board_renderer.get_cell_size()
	var gx := roundi(local_center.x / cell_size - _dragging_piece.width / 2.0)
	var gy := roundi(local_center.y / cell_size - _dragging_piece.height / 2.0)
	return Vector2i(gx, gy)

# ── Core Game Logic ──

func _place_piece(piece: BlockPiece, gx: int, gy: int) -> void:
	# Bomb piece: special handling (3x3 explosion, no placement)
	if piece.type == Enums.PieceType.BOMB:
		_handle_bomb_placement(gx, gy)
		return

	# Gift piece: award bonus score on first placement
	var gift_bonus: int = 0
	if piece.is_gift:
		gift_bonus = GameConstants.FIRST_GIFT_BONUS
		SaveManager.consume_first_gift()
		SoundManager.play_sfx("milestone")  # 특별 사운드
		print("[Gift] Gift piece placed! Bonus: +%d" % gift_bonus)

	SoundManager.play_sfx("block_place")
	HapticManager.placement(piece.cell_count)

	# 1. Place on board
	var board := _state.board.place_piece(piece, gx, gy)

	# 2. Get completed lines BEFORE clearing (need colors for blast check)
	var completed_rows := board.get_completed_rows()
	var completed_cols := board.get_completed_columns()
	var has_line_clear := completed_rows.size() > 0 or completed_cols.size() > 0

	# 3. Check Chroma Blast conditions (needs cell colors before clear)
	var blast_result := {"blast_colors": [], "trigger_lines": []}
	if has_line_clear:
		blast_result = ChromaBlastSystem.check_blast(board, completed_rows, completed_cols)

	# 4. Line clear (existing logic)
	var clear_result := ClearSystem.check_and_clear(board)
	board = clear_result["board"]

	# 5. Execute Chroma Blast
	var blast_executed := {"cells_removed": 0, "removed_positions": []}
	if not blast_result["blast_colors"].is_empty():
		blast_executed = ChromaBlastSystem.execute_blast(board, blast_result["blast_colors"])
		board = blast_executed["board"]
		# Blast may complete more lines
		var blast_line_result := board.clear_completed_lines()
		board = blast_line_result["board"]
		clear_result["lines_cleared"] += blast_line_result["lines_cleared"]

	# 6. Chroma Chain (only after line clear)
	var chain_result := {"cascades": 0, "total_cells_cleared": 0, "groups_per_cascade": [], "extra_lines_cleared": 0}
	if has_line_clear:
		chain_result = ChromaChainSystem.process_chains(board)
		board = chain_result["board"]
		clear_result["lines_cleared"] += chain_result["extra_lines_cleared"]
		if chain_result["cascades"] > 0:
			_state.chains_triggered += 1

	# 7. Color match (toggle via GameConstants.COLOR_MATCH_ENABLED)
	var color_result: Dictionary
	if GameConstants.COLOR_MATCH_ENABLED:
		color_result = ColorMatchSystem.check_color_match(board)
		board = color_result["board"]
	else:
		color_result = {"board": board, "groups": [], "total_removed": 0, "has_matches": false}

	# 7.1. Special tile drops (after all clearing settles)
	var special_result := {"board": board, "dropped": []}
	if has_line_clear:
		special_result = SpecialTileSystem.try_drop_specials(board, completed_rows, completed_cols)
		board = special_result["board"]

	# 7.2. Increment all cell ages (skip if aging disabled)
	if GameConstants.CELL_AGE_ENABLED:
		board = board.increment_ages()

	# 8. Scoring (base + chroma bonus)
	var did_clear: bool = clear_result["lines_cleared"] > 0 or color_result["has_matches"] or blast_executed["cells_removed"] > 0 or chain_result["total_cells_cleared"] > 0
	var new_combo: int = (_state.combo + 1) if did_clear else 0

	# 8.1. Bomb reward: trigger at 10 combo
	if new_combo >= GameConstants.BOMB_REWARD_COMBO_THRESHOLD and not _bomb_reward_pending:
		_bomb_reward_pending = true
		print("[Bomb] Combo %d reached — bomb reward pending!" % new_combo)

	var score_result := ScoringSystem.calculate(
		piece.cell_count, clear_result, color_result, new_combo, _state.level)

	# Chroma Chain bonus scoring
	var chain_bonus: int = 0
	for cascade_idx in chain_result["cascades"]:
		var pts_idx := mini(cascade_idx, GameConstants.CHROMA_CHAIN_POINTS_PER_CELL.size() - 1)
		var groups: Array = chain_result["groups_per_cascade"][cascade_idx]
		for group in groups:
			chain_bonus += group.size() * GameConstants.CHROMA_CHAIN_POINTS_PER_CELL[pts_idx]

	# Auto-player blast tracking
	if _auto_play_enabled and blast_executed["cells_removed"] > 0:
		_auto_player.record_blast()

	# Chroma Blast bonus scoring
	var blast_bonus: int = 0
	if blast_executed["cells_removed"] > 0:
		blast_bonus += blast_executed["cells_removed"] * GameConstants.CHROMA_BLAST_POINTS_PER_CELL
		blast_bonus += blast_result["blast_colors"].size() * GameConstants.CHROMA_BLAST_TRIGGER_BONUS

	var chroma_bonus: int = chain_bonus + blast_bonus
	score_result["total"] += chroma_bonus + gift_bonus  # 선물 피스 보너스 추가

	# Daily bonus: double score for first game of the day
	if _daily_bonus_active:
		score_result["total"] *= 2

	# 9. Level check
	var total_lines: int = _state.lines_cleared + clear_result["lines_cleared"]
	var new_level: int = DifficultySystem.calculate_level(total_lines)
	var leveled_up: bool = new_level > _state.level

	# 10. Update state
	_state.apply_turn_result(board, score_result["total"],
		clear_result["lines_cleared"], new_combo, new_level, piece)

	# 10.5 Mission tracking
	if _is_mission_run and not _state.active_missions.is_empty():
		_update_mission_progress(clear_result, chain_result, blast_executed, new_combo)

	# 10.6 Time Attack: 라인 클리어 시 +3초 보너스
	if _is_time_attack and clear_result["lines_cleared"] > 0:
		var bonus_seconds: float = clear_result["lines_cleared"] * 3.0
		_time_remaining = mini(_time_remaining + bonus_seconds, 120.0)  # 최대 120초 캡
		hud.update_timer(_time_remaining)
		_spawn_time_bonus_popup(bonus_seconds)

	# 11. Cache cell colors for clear animations BEFORE state update
	if clear_result["has_clears"]:
		board_renderer.cache_cell_colors_for_clear(clear_result["rows"], clear_result["cols"])

	# Also cache chain cell colors (cells are already empty in board, but cell_view still shows them)
	var chain_groups: Array = chain_result["groups_per_cascade"]
	for cascade_groups in chain_groups:
		for group in cascade_groups:
			for cell_pos in group:
				var p: Vector2i = cell_pos
				board_renderer.cache_extra_cell_color(p)

	# Cache blast cell colors
	var blast_positions: Array = blast_executed["removed_positions"]
	for pos in blast_positions:
		var p: Vector2i = pos
		board_renderer.cache_extra_cell_color(p)

	# Update board state (set_empty kills any running tweens)
	board_renderer.update_from_state(board)
	hud.update_from_state(_state)

	# 7.5 Crisis warning + near-miss hints
	board_renderer.update_crisis_state(board)
	# board_renderer.update_near_miss_hints(board)

	# 7.6 Placement pulse
	board_renderer.play_place_effect(piece.occupied_cells_at(gx, gy))
	AnalyticsManager.piece_placed(Enums.PieceType.keys()[piece.type], gx, gy)

	# 8. Effects AFTER state update — animations start on already-empty cells
	# Analytics and state flags fire immediately (no visual delay needed)
	var has_clear: bool = clear_result["has_clears"]
	if has_clear:
		var lines: int = clear_result["lines_cleared"]
		AnalyticsManager.line_clear(lines, new_combo)
	if color_result["has_matches"]:
		_color_match_count += color_result["groups"].size()
		var total_cells := 0
		for g in color_result["groups"]:
			total_cells += g.size()
		AnalyticsManager.color_match(color_result["groups"].size(), total_cells)
	if clear_result.get("is_perfect", false):
		_had_perfect_clear = true

	# Build effects data and play sequenced visual/audio effects
	var blast_color: int = -1
	if not blast_result["blast_colors"].is_empty():
		var bc_arr: Array = blast_result["blast_colors"]
		blast_color = bc_arr[0]
	var combo_idx := clampi(new_combo, 0, GameConstants.COMBO_MULTIPLIERS.size() - 1)
	var combo_mult: float = GameConstants.COMBO_MULTIPLIERS[combo_idx]
	var effects_data: Dictionary = {
		"has_clear": has_clear,
		"lines_cleared": clear_result["lines_cleared"],
		"clear_rows": clear_result.get("rows", []),
		"clear_cols": clear_result.get("cols", []),
		"has_color_match": color_result["has_matches"],
		"color_groups": color_result["groups"],
		"combo": new_combo,
		"chain_cascades": chain_result["cascades"],
		"chain_groups_per_cascade": chain_result["groups_per_cascade"],
		"blast_cells": blast_executed["cells_removed"],
		"blast_color": blast_color,
		"blast_positions": blast_executed["removed_positions"],
		"score": score_result["total"],
		"gx": gx,
		"gy": gy,
		"is_perfect": clear_result.get("is_perfect", false),
		"leveled_up": leveled_up,
		# Score cascade breakdown
		"line_clear_score": score_result["line_clear"],
		"chain_bonus": chain_bonus,
		"blast_bonus": blast_bonus,
		"combo_mult": combo_mult,
		"perfect_score": score_result["perfect_clear"],
	}
	_play_effects_sequence(effects_data)

	# 9.5. Check score milestones
	_check_milestones()

	# 9.6. BGM reactive intensity
	_update_bgm_intensity(board, new_combo)

	# 10. Tray refill or game over
	if _state.tray_pieces.is_empty():
		_refill_tray()
	else:
		# Check if remaining pieces can still be placed after board changed
		# Mid-tray: if remaining pieces can't fit, that's a legitimate game over
		# (rescue only happens when generating a NEW tray)
		_check_game_over()

	state_changed.emit(_state)

## Plays visual/audio effects in a staggered sequence so the player can
## see each event individually instead of everything firing at once.
## All timers use ignore_time_scale=true so hit-stops don't freeze the sequence.
##
## Timeline:
##   0ms   — Place bounce (if no clear)
## Tighter effect sequence — events overlap naturally instead of queuing.
## Total ~0.8s for simple clear, ~1.2s with chain/blast.
func _play_effects_sequence(ed: Dictionary) -> void:
	var delay: float = 0.0

	# Immediate: Place bounce if no line clear
	if not ed["has_clear"]:
		board_renderer.play_place_bounce()

	# 0ms: Score popup — instant feedback
	if ed["score"] > 0:
		_spawn_score_popup(ed["score"], ed["gx"], ed["gy"])

	# 0ms: Anticipation phase — brief dim + pulse before clear
	if ed["has_clear"]:
		board_renderer.play_clear_anticipation(ed["clear_rows"], ed["clear_cols"])
		# Camera zoom pulse for multi-line clears
		var lines_for_zoom: int = ed["lines_cleared"]
		if lines_for_zoom >= 2:
			var zoom_amount: float = 1.02 if lines_for_zoom >= 3 else 1.01
			board_renderer.play_camera_zoom(zoom_amount, 0.3)

	# 100ms: Line clear + haptic + shake (the core feel)
	if ed["has_clear"] or ed["has_color_match"]:
		get_tree().create_timer(0.1, true, false, true).timeout.connect(func():
			if ed["has_clear"]:
				var lines: int = ed["lines_cleared"]
				_apply_hit_stop(0.04 if lines >= 2 else 0.02)
				board_renderer.play_line_clear_effect(ed["clear_rows"], ed["clear_cols"])
				SoundManager.play_line_clear_sfx(lines)
				HapticManager.line_clear_burst(lines)
				if lines >= 2:
					_spawn_multi_clear_popup(lines)
				if lines >= 3:
					board_renderer.play_screen_shake(8.0, 0.18)
					board_renderer.play_screen_flash(Color(1, 1, 1, 0.2))
				elif lines >= 2:
					board_renderer.play_screen_shake(5.0, 0.12)
				else:
					board_renderer.play_screen_shake(3.0, 0.08)
			if ed["has_color_match"]:
				_apply_hit_stop(0.02)
				board_renderer.play_color_match_effect(ed["color_groups"])
				SoundManager.play_sfx("color_match")
				HapticManager.color_match()
			# End anticipation dim
			board_renderer.end_clear_anticipation()
		)
		delay = 0.35

	# +250ms after clear: Combo (x2+ only, overlaps with clear tail)
	if ed["combo"] >= 2:
		get_tree().create_timer(delay, true, false, true).timeout.connect(func():
			var combo: int = ed["combo"]
			SoundManager.play_combo_sfx(combo)
			HapticManager.combo(combo)
			_spawn_combo_popup(combo)
			if combo >= 3:
				_apply_hit_stop(0.03)
				board_renderer.play_zoom_effect(combo)
		)
		delay += 0.15  # short gap, not full wait

	# +150ms: Chain (compact — all groups fire quickly)
	if ed["chain_cascades"] > 0:
		var chain_start: float = delay
		var cascades_count: int = ed["chain_cascades"]
		get_tree().create_timer(chain_start, true, false, true).timeout.connect(func():
			_apply_hit_stop(0.04)
			_spawn_chain_popup(cascades_count)
			SoundManager.play_chain_sound(cascades_count)
			HapticManager.chroma_chain(cascades_count)
			board_renderer.play_screen_shake(4.0 + float(cascades_count) * 2.0, 0.12)
		)
		# Chain cascade groups fire with minimal stagger
		if ed.has("chain_groups_per_cascade"):
			var groups_per_cascade: Array = ed["chain_groups_per_cascade"]
			var group_offset: float = 0.0
			for cascade_idx in cascades_count:
				if cascade_idx < groups_per_cascade.size():
					var groups: Array = groups_per_cascade[cascade_idx]
					for group in groups:
						var captured_group: Array = group
						var t: float = chain_start + group_offset
						get_tree().create_timer(t, true, false, true).timeout.connect(func():
							board_renderer.play_chain_cascade_group(captured_group, 0.02)
						)
						group_offset += 0.1  # fast 0.1s between groups
		delay = chain_start + 0.2

	# +200ms: Blast (fires quickly after chain)
	if ed["blast_cells"] > 0:
		var blast_start: float = delay
		var blast_color: int = ed["blast_color"]
		var blast_positions: Array = ed.get("blast_positions", [])
		get_tree().create_timer(blast_start, true, false, true).timeout.connect(func():
			_apply_hit_stop(0.06)
			if board_renderer.has_method("play_blast_flash"):
				board_renderer.play_blast_flash(blast_color)
			if board_renderer.has_method("play_blast_cell_explosion") and not blast_positions.is_empty():
				board_renderer.play_blast_cell_explosion(blast_positions, blast_color)
			_spawn_blast_popup(blast_color)
			SoundManager.play_blast_sound()
			HapticManager.chroma_blast()
			board_renderer.play_screen_shake(10.0, 0.25)
		)
		delay = blast_start + 0.3

	# Score cascade breakdown (for complex scoring events)
	if ed["has_clear"] and (ed.get("chain_bonus", 0) > 0 or ed.get("blast_bonus", 0) > 0 or ed.get("combo_mult", 1.0) > 1.0 or ed.get("is_perfect", false)):
		get_tree().create_timer(delay + 0.1, true, false, true).timeout.connect(func():
			_spawn_score_cascade(ed)
		)

	# Perfect clear
	if ed["is_perfect"]:
		get_tree().create_timer(delay + 0.1, true, false, true).timeout.connect(func():
			_apply_hit_stop(0.06)
			SoundManager.play_sfx("perfect_clear")
			board_renderer.play_screen_shake(10.0, 0.25)
			HapticManager.perfect_clear()
		)

	# Level up
	if ed["leveled_up"]:
		get_tree().create_timer(delay + 0.2, true, false, true).timeout.connect(func():
			SoundManager.play_sfx("level_up")
			HapticManager.level_up()
			board_renderer.play_level_up_effect()
			_spawn_level_up_popup(_state.level)
		)

func _spawn_level_up_popup(level: int) -> void:
	var popup := Control.new()
	popup.set_script(preload("res://scripts/game/level_up_popup.gd"))
	var overlay_layer := CanvasLayer.new()
	overlay_layer.layer = 21
	add_child(overlay_layer)
	overlay_layer.add_child(popup)
	var board_center := board_renderer.global_position + board_renderer.size / 2.0
	popup.show_level_up(level, board_center)
	popup.tree_exited.connect(overlay_layer.queue_free)

func _on_cell_tapped(gx: int, gy: int) -> void:
	if _state.status != Enums.GameStatus.PLAYING:
		return
	if _dragging_piece != null:
		return
	var cell: Dictionary = _state.board.grid[gy][gx]
	if not cell["occupied"]:
		return
	var special: int = cell.get("special_type", GameConstants.SPECIAL_TILE_NONE)
	if special != GameConstants.SPECIAL_TILE_BOMB:
		return

	# Execute BOMB
	var bomb_result: Dictionary = SpecialTileSystem.execute_bomb(_state.board, gx, gy)
	var board: BoardState = bomb_result["board"]
	var destroyed: Array = bomb_result["destroyed"]

	# Check if bomb created completed lines
	var post_clear := board.clear_completed_lines()
	board = post_clear["board"]
	var bonus_lines: int = post_clear["lines_cleared"]

	# Score
	var score_bonus: int = bomb_result["score_bonus"]
	if bonus_lines > 0:
		score_bonus += GameConstants.line_clear_score(bonus_lines)
	_state.score += score_bonus
	_state.board = board

	# Update visuals
	board_renderer.update_from_state(board)
	board_renderer.update_crisis_state(board)
	# board_renderer.update_near_miss_hints(board)
	hud.update_from_state(_state)

	# Effects
	_apply_hit_stop(0.06)
	SoundManager.play_blast_sound()
	HapticManager.chroma_blast()
	board_renderer.play_screen_shake(8.0, 0.20)

	# Particle effect at bomb location
	board_renderer.play_bomb_effect(destroyed)

	if score_bonus > 0:
		_spawn_score_popup(score_bonus, gx, gy)

	# Check game over after bomb
	_check_game_over()
	state_changed.emit(_state)


func _on_hold_pressed() -> void:
	if _state.status != Enums.GameStatus.PLAYING:
		return
	if _state.hold_used_this_tray:
		return
	if _state.tray_pieces.is_empty():
		return
	# Pick first available piece from tray
	var tray_piece: BlockPiece = _state.tray_pieces[0]
	if _state.held_piece == null:
		# Empty hold: piece goes to hold, tray loses one piece
		_state.held_piece = tray_piece
		_state.tray_pieces.erase(tray_piece)
	else:
		# Swap: held ↔ tray piece
		var old_held: BlockPiece = _state.held_piece
		_state.held_piece = tray_piece
		_state.tray_pieces[0] = old_held
	_state.hold_used_this_tray = true
	piece_tray.populate_tray(_state.tray_pieces)
	piece_tray.update_hold_display(_state.held_piece, false, true)
	SoundManager.play_sfx("block_place")
	HapticManager.placement(tray_piece.cell_count)
	_check_game_over()
	state_changed.emit(_state)

## Create a gift piece for first-time players
func _create_gift_piece() -> BlockPiece:
	# 선물 피스: 2x2 블록 (사용하기 쉬운 모양)
	var gift := BlockPiece.new(
		Enums.PieceType.TET_SQUARE,
		Enums.BlockColor.CORAL,  # 눈에 띄게
		PieceDefinitions.SHAPES[Enums.PieceType.TET_SQUARE]
	)
	gift.is_gift = true
	return gift

## Handle bomb piece placement: 3x3 explosion centered at (gx, gy)
func _handle_bomb_placement(gx: int, gy: int) -> void:
	SoundManager.play_sfx("block_place")
	HapticManager.placement(9)  # 9 cells in 3x3

	# Remove bomb from tray state (visual already removed by drag handler)
	for i in _state.tray_pieces.size():
		var p: BlockPiece = _state.tray_pieces[i]
		if p.type == Enums.PieceType.BOMB:
			_state.tray_pieces.remove_at(i)
			break

	# Calculate 3x3 area bounds and collect cells to clear
	var radius := GameConstants.BOMB_EXPLOSION_RADIUS
	var cells_to_clear: Array = []
	var board := _state.board

	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var cx := gx + dx
			var cy := gy + dy
			# Check bounds
			if cx >= 0 and cx < board.columns and cy >= 0 and cy < board.rows:
				if board.is_cell_occupied(cx, cy):
					cells_to_clear.append(Vector2i(cx, cy))

	# Remove cells from board
	if not cells_to_clear.is_empty():
		board = board.remove_cells(cells_to_clear)
		_state.board = board

	# Award points for cleared cells
	var cells_cleared := cells_to_clear.size()
	var bomb_score := cells_cleared * GameConstants.BOMB_POINTS_PER_CELL
	_state.score += bomb_score
	_state.blocks_placed += 1

	# Cache cleared cell colors for animation
	for pos in cells_to_clear:
		board_renderer.cache_extra_cell_color(pos)

	# Update visuals
	board_renderer.update_from_state(board)
	hud.update_from_state(_state)

	# Play explosion effect
	_play_bomb_explosion(gx, gy, cells_to_clear)

	# Score popup
	if bomb_score > 0:
		_spawn_score_popup(bomb_score, gx, gy)

	print("[Bomb] Exploded at (%d, %d), cleared %d cells, +%d points" % [gx, gy, cells_cleared, bomb_score])

	# Continue combo (bomb clear counts as clear)
	_state.combo += 1
	if _state.combo > _state.max_combo:
		_state.max_combo = _state.combo

	# Check game over
	_check_game_over()
	state_changed.emit(_state)

## Play bomb explosion visual effect
func _play_bomb_explosion(gx: int, gy: int, cleared_positions: Array) -> void:
	# Use existing bomb effect for cleared cells
	board_renderer.play_bomb_effect(cleared_positions)

func _refill_tray() -> void:
	_state.hold_used_this_tray = false
	# Use pre-generated next tray, then generate a new preview
	var new_tray: Array = _next_tray_pieces if not _next_tray_pieces.is_empty() else _piece_gen.generate_tray(_state.level, _state.board)

	# Bomb reward: add bomb piece to tray if pending
	if _bomb_reward_pending:
		var bomb_piece := BlockPiece.new(
			Enums.PieceType.BOMB,
			Enums.BlockColor.SPECIAL,
			PieceDefinitions.SHAPES[Enums.PieceType.BOMB]
		)
		new_tray.append(bomb_piece)
		_bomb_reward_pending = false
		print("[Bomb] Bomb piece added to tray!")

	_state.tray_pieces = new_tray
	_next_tray_pieces = _piece_gen.generate_tray(_state.level, _state.board)
	piece_tray.populate_tray(new_tray, true)
	piece_tray.update_hold_display(_state.held_piece, true)
	piece_tray.update_next_preview(_next_tray_pieces)
	hud.update_from_state(_state)
	_check_game_over()

func _check_game_over() -> void:
	if GameOverSystem.is_game_over(_state.board, _state.tray_pieces, _state.held_piece, _state.hold_used_this_tray):
		# Ensure time_scale and board visuals are restored
		Engine.time_scale = 1.0
		_hit_stop_duration = 0.0
		board_renderer.modulate.a = 1.0
		board_renderer.scale = Vector2.ONE
		_state.status = Enums.GameStatus.GAME_OVER
		# Analyze near-miss situations for "what could have been" display
		_state.near_miss_result = NearMissAnalyzerScript.analyze(_state.board, _state.tray_pieces)
		_time_attack_active = false
		hud.show_timer(false)
		SaveManager.clear_active_game()
		SaveManager.save_previous_score(_state.score)
		SaveManager.update_play_streak()
		SaveManager.save_end_of_game(_state.score)
		# 일일 챌린지 모드 시 결과 저장
		if _is_daily_mode:
			DailyChallengeSystem.save_daily_result(_state.score)
			AnalyticsManager.daily_challenge_complete(_state.score)
		# 분석 이벤트
		var mode := "time_attack" if _is_time_attack else ("daily" if _is_daily_mode else "normal")
		AnalyticsManager.game_over(_state.score, _state.level, _state.lines_cleared, _state.max_combo, mode)
		# 업적 체크
		var daily_streak := DailyChallengeSystem.get_streak()
		var newly_unlocked := AchievementSystem.check_end_of_game(
			_state.score, _state.max_combo, _state.level,
			_state.lines_cleared, _color_match_count, _had_perfect_clear,
			SaveManager.get_games_played(), daily_streak)
		if not newly_unlocked.is_empty():
			print("[Achievement] Unlocked: %s" % str(newly_unlocked))
		# Hide mission HUD on game over
		if _is_mission_run:
			_mission_hud.hide_hud()
		AdManager.on_game_ended()
		SoundManager.play_sfx("game_over")
		# Slow motion effect + near-miss board highlight
		Engine.time_scale = 0.3
		if _state.near_miss_result != null and _state.near_miss_result.near_lines.size() > 0:
			board_renderer.show_game_over_near_miss(_state.near_miss_result.near_lines)
		await get_tree().create_timer(0.5, true).timeout
		Engine.time_scale = 1.0
		board_renderer.clear_game_over_near_miss()
		HapticManager.game_over()
		game_over_screen.show_result(_state)
		game_over_triggered.emit()

## Update mission progress after a piece placement turn.
func _update_mission_progress(clear_result: Dictionary, chain_result: Dictionary,
		blast_executed: Dictionary, new_combo: int) -> void:
	var missions: Array = _state.active_missions
	if missions.is_empty():
		return

	var lines: int = clear_result.get("lines_cleared", 0)
	if lines > 0:
		MissionSystem.update_progress(missions, MissionSystem.MissionType.CLEAR_LINES, lines)
	if new_combo > 0:
		MissionSystem.update_progress(missions, MissionSystem.MissionType.REACH_COMBO, new_combo)
	if chain_result.get("cascades", 0) > 0:
		var cascade_count: int = chain_result["cascades"]
		MissionSystem.update_progress(missions, MissionSystem.MissionType.TRIGGER_CHAIN, cascade_count)
	if blast_executed.get("cells_removed", 0) > 0:
		MissionSystem.update_progress(missions, MissionSystem.MissionType.TRIGGER_BLAST, 1)
	MissionSystem.update_progress(missions, MissionSystem.MissionType.SCORE_POINTS, _state.score)
	MissionSystem.update_progress(missions, MissionSystem.MissionType.PLACE_PIECES, 1)

	# Refresh HUD
	_mission_hud.refresh()

	# Check all completed — award bonus score and show popup
	if not _all_missions_completed_shown and MissionSystem.all_completed(missions):
		_all_missions_completed_shown = true
		if GameConstants.MISSION_ALL_COMPLETE_BONUS > 0:
			_state.score += GameConstants.MISSION_ALL_COMPLETE_BONUS
			hud.update_from_state(_state)
		var popup := Control.new()
		popup.set_script(load("res://scripts/ui/mission_complete_popup.gd"))
		popup.show_popup(self)


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

func _update_bgm_intensity(board: BoardState, combo: int) -> void:
	var fill := board.fill_ratio()
	var intensity: int
	if fill > 0.7:
		intensity = 2  # Crisis
	elif combo >= 2:
		intensity = 1  # Combo active
	else:
		intensity = 0  # Normal
	MusicManager.set_intensity(intensity)


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

func _spawn_chain_popup(cascade: int) -> void:
	var popup := Control.new()
	popup.set_script(preload("res://scripts/game/chain_popup.gd"))
	var overlay_layer := CanvasLayer.new()
	overlay_layer.layer = 20
	add_child(overlay_layer)
	overlay_layer.add_child(popup)
	var board_center := board_renderer.global_position + board_renderer.size / 2.0
	popup.show_chain(cascade, board_center)
	popup.tree_exited.connect(overlay_layer.queue_free)

func _spawn_blast_popup(blast_color_idx: int) -> void:
	var popup := Control.new()
	popup.set_script(preload("res://scripts/game/blast_popup.gd"))
	var overlay_layer := CanvasLayer.new()
	overlay_layer.layer = 21  # Above everything
	add_child(overlay_layer)
	overlay_layer.add_child(popup)
	var board_center := board_renderer.global_position + board_renderer.size / 2.0
	popup.show_blast(blast_color_idx, board_center)
	popup.tree_exited.connect(overlay_layer.queue_free)


func _spawn_time_bonus_popup(seconds: float) -> void:
	# 타임어택 모드에서 라인 클리어 시 +N초 팝업
	var popup := Control.new()
	popup.set_script(preload("res://scripts/game/time_bonus_popup.gd"))
	var overlay_layer := CanvasLayer.new()
	overlay_layer.layer = 19  # Behind combo but visible
	add_child(overlay_layer)
	overlay_layer.add_child(popup)
	var board_center := board_renderer.global_position + board_renderer.size / 2.0
	popup.show_time_bonus(seconds, board_center)
	popup.tree_exited.connect(overlay_layer.queue_free)


func _check_milestones() -> void:
	for milestone in GameConstants.SCORE_MILESTONES:
		if _state.score >= milestone and not _state.reached_milestones.has(milestone):
			_state.reached_milestones.append(milestone)
			_spawn_milestone_popup(milestone)
			SoundManager.play_sfx("level_up")
			HapticManager.level_up()


func _spawn_milestone_popup(score_value: int) -> void:
	var popup := Control.new()
	popup.set_script(preload("res://scripts/game/milestone_popup.gd"))
	var overlay_layer := CanvasLayer.new()
	overlay_layer.layer = 22
	add_child(overlay_layer)
	overlay_layer.add_child(popup)
	var board_center := board_renderer.global_position + board_renderer.size / 2.0
	popup.show_milestone(score_value, board_center)
	popup.tree_exited.connect(overlay_layer.queue_free)


func _spawn_score_popup(value: int, gx: int, gy: int) -> void:
	var popup := Label.new()
	popup.set_script(preload("res://scripts/game/score_popup.gd"))
	drag_layer.add_child(popup)
	var cell_size: float = board_renderer.get_cell_size()
	var pos := board_renderer.global_position + Vector2(gx * cell_size, gy * cell_size)
	popup.show_score(value, pos)

func _spawn_score_cascade(ed: Dictionary) -> void:
	var cascade := Control.new()
	cascade.set_script(preload("res://scripts/game/score_cascade.gd"))
	var overlay_layer := CanvasLayer.new()
	overlay_layer.layer = 22  # Above blast popup (21)
	add_child(overlay_layer)
	overlay_layer.add_child(cascade)
	var board_center: Vector2 = board_renderer.global_position + board_renderer.size / 2.0
	var cascade_data: Dictionary = {
		"line_clear": ed.get("line_clear_score", 0),
		"chain_bonus": ed.get("chain_bonus", 0),
		"blast_bonus": ed.get("blast_bonus", 0),
		"blast_color": ed.get("blast_color", -1),
		"combo_mult": ed.get("combo_mult", 1.0),
		"perfect": ed.get("perfect_score", 0),
		"total": ed.get("score", 0),
	}
	cascade.show_cascade(cascade_data, board_center, board_renderer)
	cascade.tree_exited.connect(overlay_layer.queue_free)

func _on_quit_to_home() -> void:
	# Ensure time_scale is restored if quitting during hit stop
	Engine.time_scale = 1.0
	_hit_stop_duration = 0.0
	board_renderer.modulate.a = 1.0
	board_renderer.scale = Vector2.ONE
	piece_tray.modulate.a = 1.0
	_mission_hud.hide_hud()
	_is_mission_run = false
	_is_time_attack = false
	_time_attack_active = false
	hud.show_timer(false)
	ScreenTransition.fade_through_black(get_tree(), func() -> void:
		board_renderer.disable_gems()
		home_screen.refresh_stats()
		home_screen.visible = true
		home_screen.modulate.a = 1.0
		game_over_screen.visible = false
		game_over_screen.modulate.a = 1.0
		pause_screen.visible = false
		pause_screen.modulate.a = 1.0
	)

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

func _show_home_initial() -> void:
	board_renderer.disable_gems()
	home_screen.refresh_stats()
	get_node("UILayer/GameUI").visible = false
	ScreenTransition.fade_in(home_screen)


# ── Restart Transition: Game Over → New Game ──

var _last_game_score: int = 0

func _on_restart_from_game_over() -> void:
	_last_game_score = _state.score
	# Phase 1: Shrink game-over screen + board
	var speed_scale: float = 1.0 / maxf(Engine.time_scale, 0.01)
	var tw := create_tween()
	tw.set_speed_scale(speed_scale)
	tw.set_parallel(true)
	# Shrink board
	board_renderer.pivot_offset = board_renderer.size / 2.0
	tw.tween_property(board_renderer, "scale", Vector2(0.85, 0.85), 0.25) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tw.tween_property(board_renderer, "modulate:a", 0.0, 0.2) \
		.set_ease(Tween.EASE_IN)
	# Fade out game over screen
	tw.tween_property(game_over_screen, "modulate:a", 0.0, 0.2) \
		.set_ease(Tween.EASE_IN)
	# Fade out piece tray
	tw.tween_property(piece_tray, "modulate:a", 0.0, 0.15) \
		.set_ease(Tween.EASE_IN)
	# Phase 2: Reset game state mid-transition, then expand
	tw.chain().tween_callback(_restart_game_mid_transition)


func _restart_game_mid_transition() -> void:
	Engine.time_scale = 1.0
	_hit_stop_duration = 0.0
	_is_daily_mode = false
	MusicManager.set_intensity(0)
	SaveManager.clear_active_game()
	_state.reset()
	_piece_gen.reset()
	_state.high_score = SaveManager.get_high_score()
	_state.status = Enums.GameStatus.PLAYING
	SaveManager.increment_games_played()
	game_over_screen.reset_ad_state()
	hud.reset_new_best()

	var tray := _piece_gen.generate_tray(_state.level, _state.board)
	_state.tray_pieces = tray
	_next_tray_pieces = _piece_gen.generate_tray(_state.level, _state.board)

	board_renderer.enable_gems()
	board_renderer.update_from_state(_state.board)
	board_renderer.update_crisis_state(_state.board)
	piece_tray.populate_tray(tray)
	piece_tray.update_hold_display(_state.held_piece, not _state.hold_used_this_tray)
	piece_tray.update_next_preview(_next_tray_pieces)
	hud.update_from_state(_state)

	game_over_screen.visible = false
	game_over_screen.modulate.a = 1.0
	pause_screen.visible = false
	pause_screen.modulate.a = 1.0
	home_screen.visible = false
	home_screen.modulate.a = 1.0

	_color_match_count = 0
	_had_perfect_clear = false

	# Daily bonus: consume if available (restart path)
	_daily_bonus_active = SaveManager.is_daily_bonus_available()
	if _daily_bonus_active:
		SaveManager.consume_daily_bonus()

	# Mission reset
	_is_mission_run = false
	_all_missions_completed_shown = false
	_state.is_mission_run = false
	_state.active_missions = []
	_mission_hud.hide_hud()

	# Time attack reset
	_is_time_attack = false
	_time_attack_active = false
	hud.show_timer(false)

	AnalyticsManager.game_start("normal")

	# Auto-play
	if _auto_play_enabled:
		_auto_player.reset_stats()
		_auto_play_timer.start()

	state_changed.emit(_state)

	# Phase 3: Expand board + fade in
	_play_restart_expand_animation()


func _play_restart_expand_animation() -> void:
	var speed_scale: float = 1.0 / maxf(Engine.time_scale, 0.01)
	board_renderer.pivot_offset = board_renderer.size / 2.0
	board_renderer.scale = Vector2(0.85, 0.85)
	board_renderer.modulate.a = 0.0
	piece_tray.modulate.a = 0.0

	var tw := create_tween()
	tw.set_speed_scale(speed_scale)
	tw.set_parallel(true)
	# Board expands from small to normal
	tw.tween_property(board_renderer, "scale", Vector2(1.0, 1.0), 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(board_renderer, "modulate:a", 1.0, 0.25) \
		.set_ease(Tween.EASE_OUT)
	# Piece tray fades in slightly later
	tw.tween_property(piece_tray, "modulate:a", 1.0, 0.25) \
		.set_ease(Tween.EASE_OUT).set_delay(0.1)

	# Show "previous score" toast after board appears
	tw.chain().tween_callback(_show_previous_score_toast)


func _show_previous_score_toast() -> void:
	if _last_game_score <= 0:
		return
	var formatted := FormatUtils.format_number(_last_game_score)
	var toast_text := "저번 판: %s점 → 이번엔?" % formatted

	# Create toast label overlay
	var toast_layer := CanvasLayer.new()
	toast_layer.layer = 15
	add_child(toast_layer)

	var toast := Label.new()
	var fredoka := load("res://assets/fonts/Fredoka-Bold.ttf") as Font
	if fredoka:
		toast.add_theme_font_override("font", fredoka)
	toast.add_theme_font_size_override("font_size", 15)
	toast.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	toast.text = toast_text
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH

	# Background panel
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.10, 0.35, 0.85)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.5, 0.35, 0.9, 0.3)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(toast)

	# Center the panel
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	center.offset_top = 100
	center.custom_minimum_size = Vector2(0, 50)
	center.add_child(panel)
	toast_layer.add_child(center)

	# Animate: slide in from top + fade, hold, then fade out
	center.modulate.a = 0.0
	center.offset_top = 80
	var tw := center.create_tween()
	# Slide down + fade in
	tw.set_parallel(true)
	tw.tween_property(center, "modulate:a", 1.0, 0.3) \
		.set_ease(Tween.EASE_OUT)
	tw.tween_property(center, "offset_top", 100.0, 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Hold
	tw.chain().tween_interval(2.0)
	# Fade out + slide up
	tw.tween_property(center, "modulate:a", 0.0, 0.4) \
		.set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(center, "offset_top", 85.0, 0.4) \
		.set_ease(Tween.EASE_IN)
	# Cleanup
	tw.tween_callback(toast_layer.queue_free)


func _show_home() -> void:
	ScreenTransition.fade_through_black(get_tree(), func() -> void:
		board_renderer.disable_gems()
		home_screen.refresh_stats()
		get_node("UILayer/GameUI").visible = false
		home_screen.visible = true
		home_screen.modulate.a = 1.0
		game_over_screen.visible = false
		game_over_screen.modulate.a = 1.0
		pause_screen.visible = false
		pause_screen.modulate.a = 1.0
	)

func _show_settings() -> void:
	home_screen.set_settings_active(true)
	ScreenTransition.fade_in(settings_screen)

func _hide_settings() -> void:
	home_screen.set_settings_active(false)
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
	_state.hold_used_this_tray = false
	var new_tray := _piece_gen.generate_tray(_state.level, _state.board)
	_state.tray_pieces = new_tray
	_next_tray_pieces = _piece_gen.generate_tray(_state.level, _state.board)

	board_renderer.update_from_state(_state.board)
	board_renderer.update_crisis_state(_state.board)
	piece_tray.populate_tray(new_tray, true)
	piece_tray.update_hold_display(_state.held_piece, true)
	piece_tray.update_next_preview(_next_tray_pieces)
	hud.update_from_state(_state)


	ScreenTransition.fade_out(game_over_screen)
	state_changed.emit(_state)

func _double_score_after_ad() -> void:
	var bonus := _state.score
	_state.score += bonus
	SaveManager.save_end_of_game(bonus)  # Save additional score
	hud.update_from_state(_state)

	game_over_screen.show_result(_state)

## Pre-fill board with strategic blocks for an exciting start.
## Creates near-complete rows/columns so player can clear within 1-2 moves.
## Fill: ~35% (~22 cells), bottom-heavy, never completes any line.
func _prefill_board(board: BoardState) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var cols: int = board.columns  # 8
	var rows: int = board.rows     # 8
	var target_cells := int(rows * cols * 0.35)  # ~22 cells
	var placed := 0

	# Phase 1: Near-complete rows (6/8 filled) — concentrated in bottom half
	# This gives player immediate satisfaction from first move
	var near_rows := [rows - 1, rows - 2, rows - 3]  # bottom 3 rows
	for row_y in near_rows:
		if placed >= target_cells:
			break
		# Fill 5-6 cells randomly, leave 2-3 gaps
		var gaps := rng.randi_range(2, 3)
		var gap_positions: Array = []
		while gap_positions.size() < gaps:
			var gx := rng.randi_range(0, cols - 1)
			if gx not in gap_positions:
				gap_positions.append(gx)
		var row_color: int = rng.randi_range(0, 5)
		for x in range(cols):
			if x in gap_positions:
				continue
			if not board.grid[row_y][x]["occupied"]:
				board.grid[row_y][x]["occupied"] = true
				# Mix colors: 60% same color cluster, 40% random
				board.grid[row_y][x]["color"] = row_color if rng.randf() < 0.6 else rng.randi_range(0, 5)
				placed += 1

	# Phase 2: Near-complete columns (5/8) in top half — creates vertical targets
	var near_cols := [1, 3, 5, 7]  # alternating columns
	for col_x in near_cols:
		if placed >= target_cells:
			break
		var col_color: int = rng.randi_range(0, 5)
		var filled_in_col := 0
		for y in range(0, rows - 3):  # only top 5 rows
			if board.grid[y][col_x]["occupied"]:
				filled_in_col += 1
		if filled_in_col >= 4:  # already dense, skip
			continue
		# Fill 3-4 cells in top area
		var fill_count := rng.randi_range(3, 4)
		for y in range(rows - 4, -1, -1):
			if fill_count <= 0:
				break
			if not board.grid[y][col_x]["occupied"]:
				# Safety: don't complete column (needs gap)
				var col_total := 0
				for cy in range(rows):
					if board.grid[cy][col_x]["occupied"]:
						col_total += 1
				if col_total >= rows - 1:
					break
				board.grid[y][col_x]["occupied"] = true
				board.grid[y][col_x]["color"] = col_color if rng.randf() < 0.5 else rng.randi_range(0, 5)
				placed += 1
				fill_count -= 1

	# Phase 3: Safety — remove any accidentally completed lines
	for y in range(rows):
		var row_full := true
		for x in range(cols):
			if not board.grid[y][x]["occupied"]:
				row_full = false
				break
		if row_full:
			# Clear one random cell in this row
			var clear_x := rng.randi_range(0, cols - 1)
			board.grid[y][clear_x]["occupied"] = false
			board.grid[y][clear_x]["color"] = -1
			placed -= 1

	for x in range(cols):
		var col_full := true
		for y in range(rows):
			if not board.grid[y][x]["occupied"]:
				col_full = false
				break
		if col_full:
			var clear_y := rng.randi_range(0, rows - 1)
			board.grid[clear_y][x]["occupied"] = false
			board.grid[clear_y][x]["color"] = -1
			placed -= 1


func _create_game_orbs() -> void:
	var bg := get_node_or_null("UILayer/Background")
	if bg == null:
		return
	var orb_data := [
		{"color": Color(0.486, 0.227, 0.929, 0.02), "radius": 140.0, "cx": 0.25, "cy": 0.3, "period": 10.0, "amp_x": 35.0, "amp_y": 30.0, "phase": 1.0},
		{"color": Color(0.302, 0.588, 1.0, 0.015), "radius": 120.0, "cx": 0.75, "cy": 0.55, "period": 9.0, "amp_x": 30.0, "amp_y": 40.0, "phase": 3.0},
		{"color": Color(1.0, 0.42, 0.616, 0.015), "radius": 130.0, "cx": 0.5, "cy": 0.8, "period": 11.0, "amp_x": 45.0, "amp_y": 25.0, "phase": 5.0},
	]
	for data in orb_data:
		var orb := GameOrb.new()
		orb.orb_color = data["color"]
		orb.orb_radius = data["radius"]
		orb.set_meta("cx", data["cx"])
		orb.set_meta("cy", data["cy"])
		orb.set_meta("period", data["period"])
		orb.set_meta("amp_x", data["amp_x"])
		orb.set_meta("amp_y", data["amp_y"])
		orb.set_meta("phase", data["phase"])
		orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Insert after Background but before GameUI
		var ui_layer: CanvasLayer = get_node("UILayer")
		ui_layer.add_child(orb)
		ui_layer.move_child(orb, 1)  # After Background (index 0)
		_game_orbs.append(orb)


func _process(_delta: float) -> void:
	# Time Attack timer update
	if _time_attack_active and _state.status == Enums.GameStatus.PLAYING:
		# Compensate for Engine.time_scale (hit-stop freezes)
		var real_delta: float = _delta
		if Engine.time_scale > 0.0:
			real_delta = _delta / Engine.time_scale
		_time_remaining -= real_delta
		hud.update_timer(_time_remaining)
		if _time_remaining <= 0.0:
			_time_remaining = 0.0
			hud.update_timer(0.0)
			_time_attack_active = false
			_trigger_time_attack_game_over()

	# Skip GameOrb animation when not playing (performance optimization)
	if _game_orbs.is_empty() or _state.status != Enums.GameStatus.PLAYING:
		return
	var t: float = float(Time.get_ticks_msec()) / 1000.0
	var viewport_size := get_viewport().get_visible_rect().size
	for orb in _game_orbs:
		if not is_instance_valid(orb):
			continue
		var cx: float = orb.get_meta("cx")
		var cy: float = orb.get_meta("cy")
		var period: float = orb.get_meta("period")
		var amp_x: float = orb.get_meta("amp_x")
		var amp_y: float = orb.get_meta("amp_y")
		var phase: float = orb.get_meta("phase")
		var freq: float = TAU / period
		var ox: float = sin(t * freq + phase) * amp_x
		var oy: float = cos(t * freq * 0.7 + phase) * amp_y
		orb.position.x = viewport_size.x * cx + ox - orb.orb_radius
		orb.position.y = viewport_size.y * cy + oy - orb.orb_radius


# ── Time Attack ──

func _start_time_attack() -> void:
	_time_remaining = GameConstants.TIME_ATTACK_DURATION
	_time_attack_active = true
	hud.show_timer(true)
	hud.update_timer(_time_remaining)


func _trigger_time_attack_game_over() -> void:
	Engine.time_scale = 1.0
	_hit_stop_duration = 0.0
	board_renderer.modulate.a = 1.0
	board_renderer.scale = Vector2.ONE
	_state.status = Enums.GameStatus.GAME_OVER
	SaveManager.clear_active_game()
	SaveManager.save_previous_score(_state.score)
	SaveManager.update_play_streak()
	SaveManager.save_end_of_game(_state.score)
	var mode := "time_attack"
	AnalyticsManager.game_over(_state.score, _state.level, _state.lines_cleared, _state.max_combo, mode)
	var newly_unlocked := AchievementSystem.check_end_of_game(
		_state.score, _state.max_combo, _state.level,
		_state.lines_cleared, _color_match_count, _had_perfect_clear,
		SaveManager.get_games_played(), DailyChallengeSystem.get_streak())
	if not newly_unlocked.is_empty():
		print("[Achievement] Unlocked: %s" % str(newly_unlocked))
	if _is_mission_run:
		_mission_hud.hide_hud()
	hud.show_timer(false)
	AdManager.on_game_ended()
	SoundManager.play_sfx("game_over")
	# Analyze near-miss for time attack too
	_state.near_miss_result = NearMissAnalyzerScript.analyze(_state.board, _state.tray_pieces)
	# Slow motion effect + near-miss board highlight
	Engine.time_scale = 0.3
	if _state.near_miss_result != null and _state.near_miss_result.near_lines.size() > 0:
		board_renderer.show_game_over_near_miss(_state.near_miss_result.near_lines)
	await get_tree().create_timer(0.5, true).timeout
	Engine.time_scale = 1.0
	board_renderer.clear_game_over_near_miss()
	HapticManager.game_over()
	game_over_screen.show_time_attack_result(_state)
	game_over_triggered.emit()


# ── Auto-play API ──

func set_auto_play(enabled: bool) -> void:
	_auto_play_enabled = enabled
	if enabled and _state.status == Enums.GameStatus.PLAYING:
		_auto_player.reset_stats()
		_auto_play_timer.start()
		print("[AutoPlayer] Started — stats reset")
	else:
		_auto_play_timer.stop()
		if not enabled:
			print("[AutoPlayer] Stopped — turns:%d score:%d combo:%d chains:%d blasts:%d" % [
				_auto_player.stats["turns"],
				_auto_player.stats["score"],
				_auto_player.stats["max_combo"],
				_auto_player.stats["chains"],
				_auto_player.stats["blasts"],
			])

func is_auto_play() -> bool:
	return _auto_play_enabled

func get_auto_play_stats() -> Dictionary:
	return _auto_player.stats.duplicate()

func _on_auto_play_tick() -> void:
	if _state.status != Enums.GameStatus.PLAYING:
		_auto_play_timer.stop()
		if _auto_play_enabled:
			print("[AutoPlayer] Game over — final stats: turns:%d score:%d combo:%d chains:%d blasts:%d lines:%d" % [
				_auto_player.stats["turns"],
				_auto_player.stats["score"],
				_auto_player.stats["max_combo"],
				_auto_player.stats["chains"],
				_auto_player.stats["blasts"],
				_auto_player.stats["lines_cleared"],
			])
		return
	if _dragging_piece != null:
		return  # User is dragging, skip this tick

	var move := _auto_player.find_best_move(_state.board, _state.tray_pieces)
	if move.is_empty():
		return  # No valid move — game over check will handle it

	# Remove the piece from the tray visually
	var piece: BlockPiece = move["piece"]
	var piece_idx := _state.tray_pieces.find(piece)
	if piece_idx >= 0:
		piece_tray.remove_piece_at(piece_idx)

	# Place piece using existing game logic
	_place_piece(piece, move["gx"], move["gy"])

	# Record stats
	_auto_player.record_turn(_state)


func _apply_safe_area() -> void:
	var safe_area := DisplayServer.get_display_safe_area()
	var screen_size := DisplayServer.screen_get_size()
	if screen_size.x <= 0 or screen_size.y <= 0:
		return
	# Convert safe area to viewport coords
	var viewport_size := get_viewport().get_visible_rect().size
	var scale_x := viewport_size.x / screen_size.x
	var scale_y := viewport_size.y / screen_size.y
	var top_margin := int(safe_area.position.y * scale_y)
	var bottom_margin := int((screen_size.y - safe_area.end.y) * scale_y)
	# Apply to TopMargin (min 48px for aesthetic padding)
	var top_container := get_node_or_null("UILayer/GameUI/TopMargin")
	if top_container:
		top_container.set("theme_override_constants/margin_top", maxi(top_margin + 8, 48))
	# Apply bottom safe area to ad banner / bottom nav area
	var bottom_nav := get_node_or_null("UILayer/GameUI/BottomNav")
	if bottom_nav and bottom_margin > 0:
		bottom_nav.set("theme_override_constants/margin_bottom", bottom_margin)


func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _state.status == Enums.GameStatus.PLAYING:
			# 일일 챌린지 모드에서는 중간 저장하지 않음 (시드 기반이므로)
			if not _is_daily_mode:
				SaveManager.save_active_game(_state)


class GameOrb extends Control:
	var orb_color := Color(0.5, 0.2, 0.9, 0.05)
	var orb_radius := 140.0

	func _ready() -> void:
		custom_minimum_size = Vector2(orb_radius * 2, orb_radius * 2)
		size = Vector2(orb_radius * 2, orb_radius * 2)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := Vector2(orb_radius, orb_radius)
		var steps := 20
		for i in range(steps, 0, -1):
			var frac: float = float(i) / float(steps)
			var r: float = orb_radius * frac
			var alpha: float = orb_color.a * (1.0 - frac) * 2.0
			alpha = clampf(alpha, 0.0, orb_color.a)
			var col := Color(orb_color.r, orb_color.g, orb_color.b, alpha)
			draw_circle(center, r, col)
