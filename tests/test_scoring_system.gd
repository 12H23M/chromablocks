class_name TestScoringSystem
extends RefCounted
## ScoringSystem 유닛 테스트

const TEST_NAME := "TestScoringSystem"

# ── 헬퍼 ──

## 기본 클리어 결과 (클리어 없음)
static func _no_clear() -> Dictionary:
	return {"lines_cleared": 0, "is_perfect": false}


## N줄 클리어 결과
static func _line_clear(n: int, is_perfect: bool = false) -> Dictionary:
	return {"lines_cleared": n, "is_perfect": is_perfect}


## 기본 컬러 매치 결과 (매치 없음)
static func _no_color() -> Dictionary:
	return {"groups": [], "total_removed": 0, "has_matches": false}


## 컬러 매치 결과 (그룹 크기 배열)
static func _color_groups(sizes: Array) -> Dictionary:
	var groups: Array = []
	for s in sizes:
		# 더미 그룹 — 크기만 중요
		var g: Array = []
		for i in s:
			g.append(Vector2i(i, 0))
		groups.append(g)
	return {"groups": groups, "total_removed": sizes.reduce(func(a, b): return a + b, 0), "has_matches": true}


# ── 테스트 케이스 ──

## 조각 배치 기본 점수: 셀 수 x PLACEMENT_POINTS_PER_CELL
func test_placement_score() -> String:
	# 4셀 조각 배치, 클리어 없음, 콤보 0
	var result := ScoringSystem.calculate(4, _no_clear(), _no_color(), 0, 1)
	# 기본 점수: 4 * 5 = 20
	var expected_placement := 4 * GameConstants.PLACEMENT_POINTS_PER_CELL
	var r := TestRunner.assert_eq(result["placement"], expected_placement,
		"배치 점수: 4셀 × %d = %d" % [GameConstants.PLACEMENT_POINTS_PER_CELL, expected_placement])
	if r != "":
		return r

	# 총점도 배치 점수와 동일 (클리어 없음)
	r = TestRunner.assert_eq(result["total"], expected_placement,
		"클리어 없을 때 총점은 배치 점수와 동일")
	return r


## 라인 클리어 점수: 1줄/2줄/3줄
func test_line_clear_score() -> String:
	# 1줄 클리어: 100점
	var r1 := ScoringSystem.calculate(10, _line_clear(1), _no_color(), 0, 1)
	var r := TestRunner.assert_eq(r1["line_clear"], 100, "1줄 클리어 = 100")
	if r != "":
		return r

	# 2줄 클리어: 300점
	var r2 := ScoringSystem.calculate(20, _line_clear(2), _no_color(), 0, 1)
	r = TestRunner.assert_eq(r2["line_clear"], 300, "2줄 클리어 = 300")
	if r != "":
		return r

	# 3줄 클리어: 600점
	var r3 := ScoringSystem.calculate(30, _line_clear(3), _no_color(), 0, 1)
	r = TestRunner.assert_eq(r3["line_clear"], 600, "3줄 클리어 = 600")
	return r


## 콤보 배율 적용: combo=0 → 1.0x, combo=1 → 1.2x, combo=3 → 2.0x
func test_combo_multiplier() -> String:
	# 콤보 0: 배율 1.0
	var r0 := ScoringSystem.calculate(10, _line_clear(1), _no_color(), 0, 1)
	var r := TestRunner.assert_eq(r0["combo_multiplier"], 1.0, "콤보 0 → 1.0x")
	if r != "":
		return r

	# 콤보 1: 배율 1.2
	var r1 := ScoringSystem.calculate(10, _line_clear(1), _no_color(), 1, 1)
	r = TestRunner.assert_eq(r1["combo_multiplier"], 1.2, "콤보 1 → 1.2x")
	if r != "":
		return r

	# 콤보 3: 배율 2.0
	var r3 := ScoringSystem.calculate(10, _line_clear(1), _no_color(), 3, 1)
	r = TestRunner.assert_eq(r3["combo_multiplier"], 2.0, "콤보 3 → 2.0x")
	if r != "":
		return r

	# 콤보 3에서 1줄 클리어: 보너스 = round(100 * 2.0) = 200
	# 총점 = 배치(10*5=50) + 보너스(200) = 250
	var expected_total := 50 + 200
	r = TestRunner.assert_eq(r3["total"], expected_total,
		"콤보 3 + 1줄 클리어: 총 %d" % expected_total)
	return r


## 라인 클리어 + 컬러 매치 동시 발생 시 dual_clear_multiplier = 1.25
func test_dual_clear_multiplier() -> String:
	# 라인 클리어만: dual_clear_multiplier = 1.0
	var r_line := ScoringSystem.calculate(10, _line_clear(1), _no_color(), 0, 1)
	var r := TestRunner.assert_eq(r_line["dual_clear_multiplier"], 1.0,
		"라인만 클리어 시 듀얼 배율 = 1.0")
	if r != "":
		return r

	# 컬러 매치만: dual_clear_multiplier = 1.0
	var r_color := ScoringSystem.calculate(10, _no_clear(), _color_groups([6]), 0, 1)
	r = TestRunner.assert_eq(r_color["dual_clear_multiplier"], 1.0,
		"컬러만 매치 시 듀얼 배율 = 1.0")
	if r != "":
		return r

	# 라인 + 컬러 동시: dual_clear_multiplier = 1.25
	var r_dual := ScoringSystem.calculate(10, _line_clear(1), _color_groups([6]), 0, 1)
	r = TestRunner.assert_eq(r_dual["dual_clear_multiplier"], 1.25,
		"듀얼 클리어 시 배율 = 1.25")
	if r != "":
		return r

	# 듀얼 클리어 총점 검증:
	# 배치 = 10*5 = 50
	# 라인 = 100, 컬러 = 200 (6셀)
	# 보너스 = round((100 + 200) * 1.0 * 1.25) = round(375.0) = 375
	# 총점 = 50 + 375 = 425
	r = TestRunner.assert_eq(r_dual["total"], 425, "듀얼 클리어 총점 = 425")
	return r
