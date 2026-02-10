extends Node

signal state_changed(state: GameState)
signal game_over_triggered()

@onready var board_renderer: Control = %Board
@onready var piece_tray: HBoxContainer = %PieceTray
@onready var hud: Control = %HUD
@onready var home_screen: Control = %HomeScreen
@onready var game_over_screen: Control = %GameOverScreen
@onready var pause_screen: Control = %PauseScreen
@onready var drag_layer: Control = %DragLayer

var _state: GameState
var _piece_gen := PieceGenerator.new()

func _ready() -> void:
	# Force portrait orientation on mobile
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)

	_state = GameState.new()
	_state.high_score = SaveManager.get_high_score()
	board_renderer.initialize()

	# Set tray cell size based on board cell size
	piece_tray.set_cell_size(board_renderer.get_cell_size())

	piece_tray.piece_drag_started.connect(_on_drag_started)
	piece_tray.piece_drag_moved.connect(_on_drag_moved)
	piece_tray.piece_drag_ended.connect(_on_drag_ended)

	home_screen.start_pressed.connect(start_game)
	game_over_screen.play_again_pressed.connect(start_game)
	game_over_screen.go_home_pressed.connect(_show_home)
	pause_screen.resume_pressed.connect(resume_game)
	pause_screen.quit_pressed.connect(_show_home)

	var pause_btn := hud.get_node_or_null("HudRow1/PauseButton")
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
	_state.reset()
	_piece_gen.reset()
	_state.high_score = SaveManager.get_high_score()
	_state.status = Enums.GameStatus.PLAYING
	SaveManager.increment_games_played()

	var tray := _piece_gen.generate_tray(_state.level, _state.board)
	_state.tray_pieces = tray

	board_renderer.update_from_state(_state.board)
	piece_tray.populate_tray(tray)
	hud.update_from_state(_state)

	home_screen.visible = false
	game_over_screen.visible = false
	pause_screen.visible = false

	state_changed.emit(_state)

func pause_game() -> void:
	_state.status = Enums.GameStatus.PAUSED
	pause_screen.visible = true

func resume_game() -> void:
	_state.status = Enums.GameStatus.PLAYING
	pause_screen.visible = false

# ── Drag & Drop ──

var _dragging_piece: BlockPiece = null
var _last_grid_pos := Vector2i(-1, -1)
var _drag_placeholder: Control = null

func _on_drag_started(piece_node: Control) -> void:
	if _state.status != Enums.GameStatus.PLAYING:
		return
	_dragging_piece = piece_node.piece_data

	# Create placeholder to maintain tray layout while piece is dragged
	var idx := piece_node.get_index()
	_drag_placeholder = Control.new()
	_drag_placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_drag_placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL

	piece_node.reparent(drag_layer)
	piece_tray.add_child(_drag_placeholder)
	piece_tray.move_child(_drag_placeholder, idx)

func _on_drag_moved(piece_node: Control, global_pos: Vector2) -> void:
	if _dragging_piece == null:
		return
	var grid_pos := _piece_to_grid(piece_node)

	if grid_pos != _last_grid_pos:
		_last_grid_pos = grid_pos
		var can_place := PlacementSystem.can_place(
			_state.board, _dragging_piece, grid_pos.x, grid_pos.y)
		board_renderer.show_highlight(grid_pos.x, grid_pos.y, _dragging_piece, can_place)

func _on_drag_ended(piece_node: Control, global_pos: Vector2) -> void:
	if _dragging_piece == null:
		return

	board_renderer.clear_highlights()
	var grid_pos := _piece_to_grid(piece_node)

	var can_place := PlacementSystem.can_place(
		_state.board, _dragging_piece, grid_pos.x, grid_pos.y)

	if can_place:
		piece_node.remove_from_tray()
		_place_piece(_dragging_piece, grid_pos.x, grid_pos.y)
		# Placeholder stays in tray to maintain slot layout (cleared on refill)
		_drag_placeholder = null
	else:
		# Animate piece back in drag_layer, then swap placeholder for piece
		var tween: Tween = piece_node.return_to_tray()
		var placeholder := _drag_placeholder
		_drag_placeholder = null
		tween.tween_callback(func():
			if is_instance_valid(placeholder) and is_instance_valid(piece_node):
				var idx := placeholder.get_index()
				piece_tray.remove_child(placeholder)
				placeholder.queue_free()
				piece_node.reparent(piece_tray)
				piece_tray.move_child(piece_node, idx)
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

	# 2. Line clear (only full rows/columns of 10)
	var clear_result := ClearSystem.check_and_clear(board)
	board = clear_result["board"]

	# 3. Scoring
	var did_clear: bool = clear_result["lines_cleared"] > 0
	var new_combo: int = (_state.combo + 1) if did_clear else 0
	var empty_color := {"groups": [], "total_removed": 0}

	var score_result := ScoringSystem.calculate(
		piece.cell_count, clear_result, empty_color, new_combo, _state.level)

	# 4. Level check
	var total_lines: int = _state.lines_cleared + clear_result["lines_cleared"]
	var new_level: int = DifficultySystem.calculate_level(total_lines)
	var leveled_up: bool = new_level > _state.level

	# 5. Update state
	_state.board = board
	_state.score += score_result["total"]
	_state.lines_cleared = total_lines
	_state.combo = new_combo
	if new_combo > _state.max_combo:
		_state.max_combo = new_combo
	_state.level = new_level
	_state.blocks_placed += 1
	_state.tray_pieces.erase(piece)

	# 6. Visual updates
	board_renderer.update_from_state(board)
	hud.update_from_state(_state)

	# 7. Effects
	if clear_result["has_clears"]:
		board_renderer.play_line_clear_effect(clear_result["rows"], clear_result["cols"])
		SoundManager.play_sfx("line_clear")
		HapticManager.line_clear()

	if new_combo >= 2:
		SoundManager.play_sfx("combo")

	if score_result["total"] > 0:
		_spawn_score_popup(score_result["total"], gx, gy)

	if clear_result.get("is_perfect", false):
		_spawn_score_popup(GameConstants.PERFECT_CLEAR_BONUS, 5, 5)
		SoundManager.play_sfx("perfect_clear")

	if leveled_up:
		SoundManager.play_sfx("level_up")

	# 9. Tray refill or game over
	if _state.tray_pieces.is_empty():
		_refill_tray()
	else:
		_check_game_over()

	state_changed.emit(_state)

func _refill_tray() -> void:
	var new_tray := _piece_gen.generate_tray(_state.level, _state.board)
	_state.tray_pieces = new_tray
	piece_tray.populate_tray(new_tray)
	_check_game_over()

func _check_game_over() -> void:
	if GameOverSystem.is_game_over(_state.board, _state.tray_pieces):
		_state.status = Enums.GameStatus.GAME_OVER
		SaveManager.save_high_score(_state.score)
		SaveManager.add_score(_state.score)
		SoundManager.play_sfx("game_over")
		HapticManager.game_over()
		game_over_screen.show_result(_state)
		game_over_triggered.emit()

func _spawn_score_popup(value: int, gx: int, gy: int) -> void:
	var popup := Label.new()
	popup.set_script(preload("res://scripts/game/score_popup.gd"))
	drag_layer.add_child(popup)
	var cell_size: float = board_renderer.get_cell_size()
	var pos := board_renderer.global_position + Vector2(gx * cell_size, gy * cell_size)
	popup.show_score(value, pos)

func _show_home() -> void:
	home_screen.refresh_stats()
	home_screen.visible = true
	game_over_screen.visible = false
	pause_screen.visible = false
