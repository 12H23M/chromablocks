extends Node

## Analytics event manager -- 로컬 이벤트 버퍼링, 세션 추적 및 Firebase Analytics 전송 스텁

const FLUSH_INTERVAL := 30.0  # seconds
const MAX_BUFFER_SIZE := 50

# Firebase / Google Analytics 설정
const GA_MEASUREMENT_ID := ""  # TODO: Firebase Measurement ID 입력
const GA_API_SECRET := ""  # TODO: Firebase API Secret 입력
const GA_ENDPOINT := "https://www.google-analytics.com/mp/collect"
const ENABLE_REMOTE_ANALYTICS := false  # 프로덕션에서 true로 변경

# Firebase MP v2는 요청당 최대 25개 이벤트만 허용
const MAX_EVENTS_PER_REQUEST := 25

var _event_buffer: Array = []
var _session_id: String = ""
var _session_start_time: float = 0.0
var _flush_timer: Timer
var _http_request: HTTPRequest
var _user_properties: Dictionary = {}


func _ready() -> void:
	_session_id = _generate_session_id()
	_session_start_time = Time.get_unix_time_from_system()

	# 플러시 타이머 설정
	_flush_timer = Timer.new()
	_flush_timer.wait_time = FLUSH_INTERVAL
	_flush_timer.autostart = true
	_flush_timer.timeout.connect(_flush_events)
	add_child(_flush_timer)

	# HTTP 요청 노드 설정 (Firebase 전송용)
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)

	# 유저 속성 수집
	_user_properties = {
		"platform": OS.get_name(),
		"app_version": ProjectSettings.get_setting("application/config/version", "1.0.0"),
		"screen_size": "%dx%d" % [DisplayServer.screen_get_size().x, DisplayServer.screen_get_size().y],
	}

	log_event("session_start", {})


func _generate_session_id() -> String:
	# 타임스탬프 기반 고유 ID 생성
	return "%d_%d" % [Time.get_unix_time_from_system(), randi()]


func log_event(event_name: String, params: Dictionary = {}) -> void:
	var event := {
		"event": event_name,
		"timestamp": Time.get_unix_time_from_system(),
		"session_id": _session_id,
		"params": params,
	}
	_event_buffer.append(event)
	if OS.is_debug_build():
		print("[Analytics] %s: %s" % [event_name, str(params)])
	if _event_buffer.size() >= MAX_BUFFER_SIZE:
		_flush_events()


func _flush_events() -> void:
	if _event_buffer.is_empty():
		return

	var count := _event_buffer.size()

	# 원격 전송이 비활성화되어 있으면 로컬 로그만 출력
	if not ENABLE_REMOTE_ANALYTICS:
		_event_buffer.clear()
		if OS.is_debug_build():
			print("[Analytics] Flushed %d events (local only)" % count)
		return

	# Firebase Measurement Protocol v2 형식으로 배치 전송
	# 요청당 최대 25개 이벤트 제한을 준수하여 분할 전송
	var batches: Array[Array] = []
	for i in range(0, count, MAX_EVENTS_PER_REQUEST):
		var end := mini(i + MAX_EVENTS_PER_REQUEST, count)
		batches.append(_event_buffer.slice(i, end))

	_event_buffer.clear()

	for batch in batches:
		_send_batch(batch)

	if OS.is_debug_build():
		print("[Analytics] Flushed %d events in %d batch(es)" % [count, batches.size()])


## Firebase MP v2 형식으로 이벤트 배치를 HTTP POST 전송
func _send_batch(events: Array) -> void:
	# 이벤트를 Firebase MP v2 형식으로 변환
	var ga_events: Array = []
	for event in events:
		var ga_event := {
			"name": event["event"],
			"params": event["params"].duplicate(),
		}
		# 타임스탬프를 마이크로초 단위로 변환하여 params에 포함
		ga_event["params"]["engagement_time_msec"] = "1"
		ga_event["params"]["session_id"] = event["session_id"]
		ga_events.append(ga_event)

	# JSON 페이로드 생성
	var payload := {
		"client_id": _session_id,
		"user_properties": {},
		"events": ga_events,
	}

	# 유저 속성을 Firebase 형식으로 변환
	for key in _user_properties:
		payload["user_properties"][key] = {"value": _user_properties[key]}

	var json_body := JSON.stringify(payload)
	var url := GA_ENDPOINT + "?measurement_id=" + GA_MEASUREMENT_ID + "&api_secret=" + GA_API_SECRET
	var headers := ["Content-Type: application/json"]

	# HTTP POST 요청 전송
	var error := _http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK and OS.is_debug_build():
		print("[Analytics] HTTP request failed with error: %d" % error)


## Firebase 전송 완료 콜백
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if OS.is_debug_build():
		if response_code == 204:
			print("[Analytics] Events sent successfully")
		else:
			print("[Analytics] Send failed: HTTP %d" % response_code)


# -- Convenience methods for core game events --


func game_start(mode: String = "normal") -> void:
	log_event("game_start", {"mode": mode})


func game_over(score: int, level: int, lines_cleared: int, combo_max: int, mode: String = "normal") -> void:
	var duration := Time.get_unix_time_from_system() - _session_start_time
	log_event("game_over", {
		"score": score, "level": level, "lines_cleared": lines_cleared,
		"combo_max": combo_max, "mode": mode,
		"session_duration_sec": roundi(duration),
	})


func piece_placed(piece_type: String, grid_x: int, grid_y: int) -> void:
	log_event("piece_placed", {"piece_type": piece_type, "x": grid_x, "y": grid_y})


func line_clear(lines: int, combo: int) -> void:
	log_event("line_clear", {"lines": lines, "combo": combo})


func color_match(groups: int, total_cells: int) -> void:
	log_event("color_match", {"groups": groups, "total_cells": total_cells})


func daily_challenge_start() -> void:
	log_event("daily_challenge_start", {"seed": DailyChallengeSystem.get_today_seed()})


func daily_challenge_complete(score: int) -> void:
	log_event("daily_challenge_complete", {"score": score})


func ad_shown(ad_type: String) -> void:
	log_event("ad_shown", {"type": ad_type})


func ad_reward_claimed(reward_type: String) -> void:
	log_event("ad_reward_claimed", {"type": reward_type})


func tutorial_started() -> void:
	log_event("tutorial_started", {})


func tutorial_completed() -> void:
	log_event("tutorial_completed", {})


func swap_used() -> void:
	log_event("swap_used", {})


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == MainLoop.NOTIFICATION_APPLICATION_PAUSED:
		log_event("session_end", {})
		_flush_events()
