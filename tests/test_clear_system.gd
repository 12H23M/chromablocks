class_name TestClearSystem
extends RefCounted
## ClearSystem 유닛 테스트

const TEST_NAME := "TestClearSystem"

# ── 헬퍼 ──

## 한 행을 가득 채우는 10셀 가로 피스
static func _make_full_row_piece(color: int = 0) -> BlockPiece:
	return BlockPiece.new(0, color, [[1, 1, 1, 1, 1, 1, 1, 1, 1, 1]])


## 한 열을 가득 채우는 10셀 세로 피스
static func _make_full_col_piece(color: int = 0) -> BlockPiece:
	var shape: Array = []
	for i in 10:
		shape.append([1])
	return BlockPiece.new(0, color, shape)


## 5셀 가로 피스 (행 절반)
static func _make_half_row_piece(color: int = 0) -> BlockPiece:
	return BlockPiece.new(0, color, [[1, 1, 1, 1, 1]])


# ── 테스트 케이스 ──

## 미완성 행은 클리어되지 않아야 한다
func test_no_clear_on_incomplete_row() -> String:
	var board := BoardState.new(10, 10)
	# 행의 절반만 채움 (5셀)
	var half := _make_half_row_piece(0)
	board = board.place_piece(half, 0, 0)

	var result := ClearSystem.check_and_clear(board)
	var r := TestRunner.assert_eq(result["lines_cleared"], 0,
		"미완성 행은 클리어 안됨")
	if r != "":
		return r
	r = TestRunner.assert_false(result["has_clears"], "has_clears = false")
	return r


## 완성 행이 클리어되어야 한다
func test_clear_full_row() -> String:
	var board := BoardState.new(10, 10)
	# 행 0을 완전히 채움
	var row_piece := _make_full_row_piece(0)
	board = board.place_piece(row_piece, 0, 0)

	var result := ClearSystem.check_and_clear(board)
	var r := TestRunner.assert_eq(result["lines_cleared"], 1, "1행 클리어")
	if r != "":
		return r
	r = TestRunner.assert_true(result["has_clears"], "has_clears = true")
	if r != "":
		return r

	# 클리어 후 보드에서 해당 행이 비어있어야 한다
	var new_board: BoardState = result["board"]
	for x in 10:
		r = TestRunner.assert_false(
			new_board.is_cell_occupied(x, 0),
			"클리어 후 셀 (%d, 0)이 비어야 함" % x
		)
		if r != "":
			return r
	return ""


## 완성 열이 클리어되어야 한다
func test_clear_full_column() -> String:
	var board := BoardState.new(10, 10)
	# 열 0을 완전히 채움
	var col_piece := _make_full_col_piece(0)
	board = board.place_piece(col_piece, 0, 0)

	var result := ClearSystem.check_and_clear(board)
	var r := TestRunner.assert_eq(result["lines_cleared"], 1, "1열 클리어")
	if r != "":
		return r
	r = TestRunner.assert_true(result["has_clears"], "has_clears = true")
	if r != "":
		return r

	# 클리어 후 보드에서 해당 열이 비어있어야 한다
	var new_board: BoardState = result["board"]
	for y in 10:
		r = TestRunner.assert_false(
			new_board.is_cell_occupied(0, y),
			"클리어 후 셀 (0, %d)이 비어야 함" % y
		)
		if r != "":
			return r
	return ""


## 보드를 완전히 비우면 퍼펙트 클리어
func test_perfect_clear() -> String:
	var board := BoardState.new(10, 10)
	# 모든 행을 채움 → 10행 + 10열 모두 완성 → 퍼펙트 클리어
	var row_piece := _make_full_row_piece(0)
	for y in 10:
		board = board.place_piece(row_piece, 0, y)

	var result := ClearSystem.check_and_clear(board)
	# 모든 행(10) + 모든 열(10) = 20 라인 클리어
	var r := TestRunner.assert_eq(result["lines_cleared"], 20,
		"10행 + 10열 모두 클리어 = 20")
	if r != "":
		return r
	r = TestRunner.assert_true(result["is_perfect"], "퍼펙트 클리어 플래그")
	if r != "":
		return r

	# 클리어 후 보드가 완전히 비어있어야 한다
	var new_board: BoardState = result["board"]
	r = TestRunner.assert_true(new_board.is_empty, "퍼펙트 클리어 후 보드 비어야 함")
	return r
