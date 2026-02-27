class_name GameState

var board: BoardState
var tray_pieces: Array  # Array[BlockPiece]
var score: int = 0
var level: int = 1
var lines_cleared: int = 0
var combo: int = 0
var status: int = Enums.GameStatus.READY
var high_score: int = 0
var blocks_placed: int = 0
var max_combo: int = 0
var held_piece: BlockPiece = null
var hold_used_this_tray: bool = false


func _init() -> void:
	board = BoardState.new()
	tray_pieces = []


func reset() -> void:
	board = BoardState.new()
	tray_pieces = []
	score = 0
	level = 1
	lines_cleared = 0
	combo = 0
	status = Enums.GameStatus.READY
	blocks_placed = 0
	max_combo = 0
	held_piece = null
	hold_used_this_tray = false


func apply_turn_result(board_new: BoardState, score_total: int, lines_cleared_delta: int,
		new_combo: int, new_level: int, piece: BlockPiece) -> void:
	board = board_new
	score += score_total
	lines_cleared += lines_cleared_delta
	combo = new_combo
	if new_combo > max_combo:
		max_combo = new_combo
	level = new_level
	blocks_placed += 1
	tray_pieces.erase(piece)


var is_tray_empty: bool:
	get: return tray_pieces.is_empty()
