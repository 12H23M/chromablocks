class_name TestPieceGenerator
extends RefCounted
## PieceGenerator 유닛 테스트

const TEST_NAME := "TestPieceGenerator"

# ── 헬퍼 ──

## 빈 보드 생성
static func _empty_board() -> BoardState:
	return BoardState.new(10, 10)


## 지정 밀도로 채워진 보드 생성 (왼쪽 상단부터 순서대로 채움)
static func _filled_board(fill_ratio: float) -> BoardState:
	var board := BoardState.new(10, 10)
	var total_cells := 100  # 10x10
	var target := int(total_cells * fill_ratio)
	var filled := 0
	var new_grid := board._copy_grid()
	for y in 10:
		if filled >= target:
			break
		for x in 10:
			if filled >= target:
				break
			new_grid[y][x] = {"occupied": true, "color": 0}
			filled += 1
	return BoardState.new(10, 10, new_grid)


# ── 테스트 케이스 ──

## generate_tray는 BlockPiece 배열을 반환해야 한다
func test_generate_tray_returns_pieces() -> String:
	var gen := PieceGenerator.new()
	gen.set_seed(12345)
	var board := _empty_board()
	var tray := gen.generate_tray(1, board)

	# 트레이가 비어있지 않아야 한다
	var r := TestRunner.assert_true(tray.size() > 0, "트레이가 비어있지 않아야 함")
	if r != "":
		return r

	# 각 원소가 BlockPiece여야 한다
	for i in tray.size():
		var piece = tray[i]
		r = TestRunner.assert_true(piece is BlockPiece,
			"트레이[%d]가 BlockPiece여야 함" % i)
		if r != "":
			return r
		# 유효한 shape가 있어야 한다
		r = TestRunner.assert_true(piece.cell_count > 0,
			"트레이[%d]의 셀 수가 0보다 커야 함" % i)
		if r != "":
			return r
	return ""


## 같은 시드를 사용하면 동일한 결과를 생성해야 한다 (결정론적)
func test_seed_determinism() -> String:
	var board := _empty_board()
	var seed_val := 99999

	# 첫 번째 생성
	var gen1 := PieceGenerator.new()
	gen1.set_seed(seed_val)
	var tray1 := gen1.generate_tray(5, board)

	# 두 번째 생성 (같은 시드)
	var gen2 := PieceGenerator.new()
	gen2.set_seed(seed_val)
	var tray2 := gen2.generate_tray(5, board)

	# 크기 비교
	var r := TestRunner.assert_eq(tray1.size(), tray2.size(),
		"같은 시드 → 같은 트레이 크기")
	if r != "":
		return r

	# 각 피스의 타입과 색상이 동일해야 한다
	for i in tray1.size():
		r = TestRunner.assert_eq(tray1[i].type, tray2[i].type,
			"피스[%d] 타입 일치" % i)
		if r != "":
			return r
		r = TestRunner.assert_eq(tray1[i].color, tray2[i].color,
			"피스[%d] 색상 일치" % i)
		if r != "":
			return r
	return ""


## 보드 80%+ 밀도 시 TINY 카테고리 피스가 포함되어야 한다
func test_mercy_produces_small_pieces() -> String:
	var board := _filled_board(0.85)  # 85% 밀도
	var gen := PieceGenerator.new()
	gen.set_seed(42)

	# 여러 번 생성하여 TINY 피스(셀 수 1~2)가 포함되는지 확인
	var found_tiny := false
	for attempt in 10:
		gen.set_seed(42 + attempt)
		var tray := gen.generate_tray(10, board)
		for piece in tray:
			# TINY 카테고리: SINGLE(1셀), DUO(2셀), DUO_V(2셀)
			if piece.cell_count <= 2:
				found_tiny = true
				break
		if found_tiny:
			break

	return TestRunner.assert_true(found_tiny,
		"85% 밀도 보드에서 TINY 피스(1~2셀)가 포함되어야 함")


## 레벨 30+ (EXPERT_TRAY_REDUCE_LEVEL) 에서는 2개 피스 트레이
func test_expert_tray_has_two_pieces() -> String:
	var board := _empty_board()
	var gen := PieceGenerator.new()
	gen.set_seed(12345)

	var expert_level := GameConstants.EXPERT_TRAY_REDUCE_LEVEL  # 30
	var tray := gen.generate_tray(expert_level, board)

	# TEMPLATES_EXPERT는 모두 2개 피스 템플릿
	var r := TestRunner.assert_eq(tray.size(), 2,
		"레벨 %d+에서 트레이 피스 수 = 2" % expert_level)
	return r
