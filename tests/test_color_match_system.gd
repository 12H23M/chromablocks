class_name TestColorMatchSystem
extends RefCounted
## ColorMatchSystem 유닛 테스트

const TEST_NAME := "TestColorMatchSystem"

# ── 헬퍼 ──

## 보드의 특정 셀들에 동일 색상을 채우는 헬퍼
## cells: Array[Vector2i], color: int → BoardState
static func _fill_cells(board: BoardState, cells: Array, color: int) -> BoardState:
	var new_grid := board._copy_grid()
	for cell in cells:
		new_grid[cell.y][cell.x] = {"occupied": true, "color": color}
	return BoardState.new(board.columns, board.rows, new_grid)


# ── 테스트 케이스 ──

## 6셀 미만 그룹은 매치되지 않는다
func test_no_match_below_threshold() -> String:
	var board := BoardState.new(10, 10)
	# 같은 색상 5셀만 인접 배치 (임계값 6 미만)
	var cells: Array = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(0, 1), Vector2i(1, 1),
	]
	board = _fill_cells(board, cells, Enums.BlockColor.CORAL)

	var result := ColorMatchSystem.check_color_match(board)
	var r := TestRunner.assert_false(result["has_matches"],
		"5셀 그룹은 매치되지 않아야 함")
	if r != "":
		return r
	r = TestRunner.assert_eq(result["groups"].size(), 0, "매치 그룹 0개")
	return r


## 정확히 6셀 인접 그룹은 매치된다
func test_match_at_threshold() -> String:
	var board := BoardState.new(10, 10)
	# 같은 색상 6셀 인접 배치 (L자 형태)
	var cells: Array = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
	]
	board = _fill_cells(board, cells, Enums.BlockColor.SKY)

	var result := ColorMatchSystem.check_color_match(board)
	var r := TestRunner.assert_true(result["has_matches"],
		"6셀 그룹은 매치되어야 함")
	if r != "":
		return r
	r = TestRunner.assert_eq(result["groups"].size(), 1, "매치 그룹 1개")
	if r != "":
		return r

	# 매치 후 해당 셀들이 제거되어야 한다
	var new_board: BoardState = result["board"]
	for cell in cells:
		r = TestRunner.assert_false(
			new_board.is_cell_occupied(cell.x, cell.y),
			"매치 후 셀 (%d, %d)가 제거되어야 함" % [cell.x, cell.y]
		)
		if r != "":
			return r
	return ""


## 서로 다른 색상의 여러 그룹이 동시에 매치된다
func test_multiple_groups() -> String:
	var board := BoardState.new(10, 10)

	# 그룹 1: CORAL 색상 6셀 (왼쪽 상단)
	var group1: Array = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
	]
	board = _fill_cells(board, group1, Enums.BlockColor.CORAL)

	# 그룹 2: MINT 색상 7셀 (오른쪽 하단, 그룹1과 떨어져 있음)
	var group2: Array = [
		Vector2i(6, 6), Vector2i(7, 6), Vector2i(8, 6),
		Vector2i(6, 7), Vector2i(7, 7), Vector2i(8, 7),
		Vector2i(6, 8),
	]
	board = _fill_cells(board, group2, Enums.BlockColor.MINT)

	var result := ColorMatchSystem.check_color_match(board)
	var r := TestRunner.assert_true(result["has_matches"],
		"두 그룹 모두 매치되어야 함")
	if r != "":
		return r
	r = TestRunner.assert_eq(result["groups"].size(), 2, "매치 그룹 2개")
	if r != "":
		return r

	# 총 제거 셀 수: 6 + 7 = 13
	r = TestRunner.assert_eq(result["total_removed"], 13, "총 13셀 제거")
	return r
