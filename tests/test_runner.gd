class_name TestRunner
extends Node
## 간단한 유닛 테스트 러너 — 에디터에서 씬으로 실행
## 각 테스트 클래스는 RefCounted를 상속하며, test_ 접두사 메서드를 자동 탐색합니다.

var _passed := 0
var _failed := 0
var _errors: Array = []


func _ready() -> void:
	print("\n=== ChromaBlocks Unit Tests ===\n")

	# 각 테스트 클래스 실행
	_run_tests(TestBoardState.new())
	_run_tests(TestScoringSystem.new())
	_run_tests(TestClearSystem.new())
	_run_tests(TestColorMatchSystem.new())
	_run_tests(TestPieceGenerator.new())
	_run_tests(TestDailyChallenge.new())

	# 결과 출력
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	for err in _errors:
		print("  FAIL: %s" % err)
	if _failed == 0:
		print("All tests passed!")
	else:
		print("%d test(s) failed." % _failed)

	# 종료
	get_tree().quit()


func _run_tests(test_obj: RefCounted) -> void:
	# 테스트 객체에 러너 참조를 넘겨줌 (assert 헬퍼 사용 위해)
	if test_obj.has_method("set_runner"):
		test_obj.set_runner(self)

	var class_name_str: String = test_obj.get("TEST_NAME") if test_obj.get("TEST_NAME") else "Unknown"
	print("--- %s ---" % class_name_str)

	var methods := test_obj.get_method_list()
	for m in methods:
		var method_name: String = m["name"]
		if not method_name.begins_with("test_"):
			continue

		var test_label := "%s.%s" % [class_name_str, method_name]
		var success := true
		# 테스트 실행 시도
		var err_msg := test_obj.call(method_name) as String
		if err_msg != null and err_msg != "":
			success = false
			_failed += 1
			_errors.append("%s — %s" % [test_label, err_msg])
			print("  FAIL: %s — %s" % [method_name, err_msg])
		else:
			_passed += 1
			print("  PASS: %s" % method_name)


# ── Assert 헬퍼 (정적 유틸리티) ──
# 각 assert 함수는 실패 시 에러 문자열을, 성공 시 빈 문자열을 반환합니다.

static func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> String:
	if actual != expected:
		var detail := "expected [%s] but got [%s]" % [str(expected), str(actual)]
		return "%s — %s" % [msg, detail] if msg != "" else detail
	return ""


static func assert_true(condition: bool, msg: String = "") -> String:
	if not condition:
		return msg if msg != "" else "condition is false, expected true"
	return ""


static func assert_false(condition: bool, msg: String = "") -> String:
	if condition:
		return msg if msg != "" else "condition is true, expected false"
	return ""


static func assert_gt(actual: Variant, threshold: Variant, msg: String = "") -> String:
	if actual <= threshold:
		var detail := "expected > %s but got %s" % [str(threshold), str(actual)]
		return "%s — %s" % [msg, detail] if msg != "" else detail
	return ""


static func assert_gte(actual: Variant, threshold: Variant, msg: String = "") -> String:
	if actual < threshold:
		var detail := "expected >= %s but got %s" % [str(threshold), str(actual)]
		return "%s — %s" % [msg, detail] if msg != "" else detail
	return ""


## 여러 assert 결과를 결합 — 첫 번째 실패를 반환
static func first_failure(results: Array) -> String:
	for r in results:
		if r != "":
			return r
	return ""
