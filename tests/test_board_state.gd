class_name TestBoardState
extends RefCounted
## BoardState 유닛 테스트

const TEST_NAME := "TestBoardState"

# ── 헬퍼 ──

## 1x10 가로 조각 (한 행을 가득 채울 수 있는 라인 피스)
static func _make_full_row_piece(color: int = 0) -> BlockPiece:
	var shape := [[1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
	return BlockPiece.new(0, color, shape)


## 1x10 세로 조각 (한 열을 가득 채울 수 있는 라인 피스)
static func _make_full_col_piece(color: int = 0) -> BlockPiece:
	var shape: Array = []
	for i in 10:
		shape.append([1])
	return BlockPiece.new(0, color, shape)


## 간단한 2x2 블록 피스
static func _make_small_piece(color: int = 0) -> BlockPiece:
	return BlockPiece.new(0, color, [[1, 1], [1, 1]])


# ── 테스트 케이스 ──

## 새 보드는 모든 셀이 비어있어야 한다
func test_new_board_is_empty() -> String:
	var board := BoardState.new(10, 10)
	var r := TestRunner.assert_true(board.is_empty, "새 보드는 비어있어야 합니다")
	if r != "":
		return r
	# 모든 셀 개별 확인
	for y in board.rows:
		for x in board.columns:
			r = TestRunner.assert_false(
				board.is_cell_occupied(x, y),
				"셀 (%d, %d)이 비어있어야 합니다" % [x, y]
			)
			if r != "":
				return r
	return ""


## 조각 배치 후 해당 셀이 채워져야 한다
func test_place_piece_fills_cells() -> String:
	var board := BoardState.new(10, 10)
	var piece := _make_small_piece(1)
	var new_board := board.place_piece(piece, 0, 0)

	# 배치한 영역(0,0 ~ 1,1) 확인
	for y in 2:
		for x in 2:
			var r := TestRunner.assert_true(
				new_board.is_cell_occupied(x, y),
				"배치 후 셀 (%d, %d)가 채워져야 합니다" % [x, y]
			)
			if r != "":
				return r

	# 배치하지 않은 영역은 비어있어야 한다
	var r := TestRunner.assert_false(
		new_board.is_cell_occupied(5, 5),
		"배치하지 않은 셀 (5,5)는 비어있어야 합니다"
	)
	return r


## place_piece는 원본 보드를 변경하지 않는 불변 연산이다
func test_place_piece_returns_new_board() -> String:
	var board := BoardState.new(10, 10)
	var piece := _make_small_piece(2)
	var new_board := board.place_piece(piece, 0, 0)

	# 원본 보드는 여전히 비어있어야 한다
	var r := TestRunner.assert_true(board.is_empty, "원본 보드는 불변이어야 합니다")
	if r != "":
		return r

	# 새 보드는 비어있지 않아야 한다
	r = TestRunner.assert_false(new_board.is_empty, "새 보드는 비어있지 않아야 합니다")
	if r != "":
		return r

	# 두 보드는 다른 객체여야 한다
	r = TestRunner.assert_true(board != new_board, "원본과 새 보드는 다른 객체여야 합니다")
	return r


## 한 행이 모두 채워지면 완성 행으로 반환
func test_get_completed_rows() -> String:
	var board := BoardState.new(10, 10)
	# 행 0을 완전히 채움
	var row_piece := _make_full_row_piece(0)
	board = board.place_piece(row_piece, 0, 0)

	var completed := board.get_completed_rows()
	var r := TestRunner.assert_eq(completed.size(), 1, "완성 행이 1개여야 합니다")
	if r != "":
		return r
	r = TestRunner.assert_eq(completed[0], 0, "완성 행의 인덱스는 0이어야 합니다")
	return r


## 한 열이 모두 채워지면 완성 열로 반환
func test_get_completed_columns() -> String:
	var board := BoardState.new(10, 10)
	# 열 0을 완전히 채움
	var col_piece := _make_full_col_piece(0)
	board = board.place_piece(col_piece, 0, 0)

	var completed := board.get_completed_columns()
	var r := TestRunner.assert_eq(completed.size(), 1, "완성 열이 1개여야 합니다")
	if r != "":
		return r
	r = TestRunner.assert_eq(completed[0], 0, "완성 열의 인덱스는 0이어야 합니다")
	return r
