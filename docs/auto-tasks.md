# ChromaBlocks 자동 태스크 큐

> 리나가 자동으로 처리하는 태스크 목록
> 위에서부터 순서대로 처리. 완료되면 ✅ 표시.
> Leo가 직접 추가/삭제/순서변경 가능.

---

## 🔴 Tier 1 — 즉시 (출시 블로커)

- [x] **Performance Quick Wins 구현** ✅ 2026-03-27
  - StyleBoxFlat 캐시, Rounded rect polygon 캐시
  - GameOrb _process 최적화, Pulse tween 30fps 쓰로틀링
  - commit: 6f71cea, 715faa3

- [x] **BGM 볼륨 조정** ✅ (이미 -6dB로 설정됨)
  - MUSIC_VOLUME_DB: -6dB (확인 완료)

- [x] **미커밋 변경사항 커밋+push** ✅ 2026-03-28
  - GameUI visibility, gift piece type, near_miss API, hud combo badge
  - commit: 55d298c

- [x] **게임오버 화면 Design D2 구현** ✅ (이미 완성)
  - game_over_screen.gd에 D2 디자인 완전 구현됨
  - 헥사곤 등급 뱃지, 컬러 스탯 칩, 파티클 배경, near-miss 힌트

- [x] **Safe area 패딩** ✅ (이미 구현)
  - _apply_safe_area() 함수로 TopMargin/BottomNav에 적용됨

---

## 🟡 Tier 2 — 이번 주 (핵심 개선)

- [x] **밸런스 개선 + Color Match 활성화** ✅ 2026-03-28
  - COLOR_MATCH_ENABLED: false → true (중독성 핵심 피처 활성화)
  - PLACEMENT_POINTS_PER_CELL: 5 → 10 (배치 보상감 강화)
  - COMBO_MULTIPLIERS x2/x3 구간: 1.2/1.5 → 1.3/1.6 (체감 개선)
  - commit: 5e28dd0

- [ ] **ADB 자동 테스트 스크립트**
  - scripts/auto-test.sh 생성
  - 배포 → 스크린샷 → AI 분석 파이프라인

- [x] **오토플레이 봇 (GDScript)** ✅ 2026-03-28
  - autoplay_runner.gd + scenes/autoplay_runner.tscn + scripts/run-autoplay.sh 생성
  - headless 모드에서 N판 자동 실행 (`./scripts/run-autoplay.sh --games N`)
  - 통계 수집 (turns, score, lines_cleared, max_combo, chains, blasts, game_over_turn)
  - commit: ab1638d

- [x] **Python 게임 시뮬레이터** ✅ 2026-03-28
  - board_state + piece_generator + scoring 로직 포팅 완료
  - 1000판 × 5 프리필 전략 비교 → JSON 리포트
  - 결과: Spread 40% + 2 near-complete 전략 최우수
  - tools/simulator.py, docs/sim-results-2026-03-28.md

- [ ] **Phase 6 P3 잔여 태스크**
  - ~~6.15: shake/bounce offset 분리~~ ✅
  - ~~6.16: PackedInt32Array 최적화~~ ✅
  - 6.21: Safe area 패딩

---

## 🟡 Tier 2 추가 완료

- [x] **6.18 광고 버튼 배치 최적화** ✅ 2026-03-28
  - HBox→VBox 세로 배치, 한국어화 (이어하기/점수2배/다시시작/홈)
  - commit: 01921ac

- [x] **6.19 일일 보상 모달 개선** ✅ 2026-03-28
  - 풀스크린 오버레이 + 7일 캘린더 + 스트릭 표시
  - 입장 애니메이션 (슬라이드+바운스), 탭 닫기
  - commit: e25629e

---

## 🟢 Tier 3 — 다음 주 (폴리시)

- [x] **콤보 시각 가이드 개선** ✅ 2026-03-28
  - 콤보 힌트 레이블 (한국어 메시지, 콤보 색상 연동)
  - 콤보 히트 카운터 도트 (5개 도트, 콤보 레벨별 활성화)
  - commit: ffae667

- [x] **게임오버 → 재시작 전환 연출** ✅ (이미 구현)
  - _on_restart_from_game_over() + _play_restart_expand_animation() 완성
  - 보드 shrink/expand + fade + bounce 애니메이션

- [x] **스토어 준비** ✅ 2026-03-28 05:01
  - 개인정보처리방침 HTML (docs/privacy-policy.html) — 한/영 탭 전환
  - ADB 스크린샷 자동 캡처 스크립트 (scripts/store-screenshots.sh) — 5장
  - commit: 5c2997e

- [ ] **퍼포먼스 프로파일링**
  - 프레임 드롭 구간 확인
  - 파티클/tween 최적화

- [x] **미션 런 모드 폴리시** ✅ (commit b80fd97)

---

## 🔵 Tier 4 — 아이디어 풀 (Leo 승인 후)

- [ ] 타임어택 모드 (60초 최고점)
- [ ] 폭탄 블록 (배치 시 주변 클리어)
- [ ] 주간 토너먼트 (글로벌 랭킹)
- [ ] 시즌 시스템 (3개월 주기, 테마+보상)
- [ ] 소셜 공유 (점수 카드 이미지 생성)
- [ ] 스킨 상점 (코인으로 구매)
- [ ] 튜토리얼 개선 (인터랙티브)
- [ ] 리플레이 기능 (최고 기록 재생)

---

## 📝 완료 로그

| 날짜 | 태스크 | 결과 |
|------|--------|------|
| (자동 기록) | | |

---

## 📝 야간 자동 작업 로그 (2026-03-28 04:30)

- [x] **게임오버 아쉬움 극대화** ✅ 2026-03-28 04:30
  - 게임오버 시 near-complete 라인 보드 주황 글로우 하이라이트 (slow-motion 구간)
  - cell_view: show_game_over_near_miss_glow() + fade pulse 애니메이션
  - board_renderer: show_game_over_near_miss() / clear_game_over_near_miss()
  - near_miss_analyzer: 메시지 풀 15개+로 확대, 6/8도 감지, 상황별 분기
  - game_over_screen: 반투명 주황 배경 패널 + 18px 폰트 + shake 애니메이션
  - commit: fda1327

---

## 📝 야간 자동 작업 로그 (2026-03-28 05:01 — 마지막 세션)

- [x] **스토어 배포 준비** ✅ 2026-03-28 05:01
  - 개인정보처리방침 (docs/privacy-policy.html): 한/영 탭 전환, AdMob 명시, GDPR 권리 안내
  - ADB 스토어 스크린샷 자동화 (scripts/store-screenshots.sh): 5장 순서대로 캡처
  - commit: 5c2997e

---

## 📝 야간 자동 작업 로그 (2026-03-28 05:30 — 최종 회차)

- [확인] 마지막 커밋: `db38e07 [auto] docs: 야간 작업 로그 업데이트 - 스토어 준비 완료`
- [확인] 워킹 트리 클린, 진행 중 미완료 작업 없음
- [점검] 오늘밤 완료된 주요 퍼포먼스 최적화 항목:
  - ✅ StyleBoxFlat 캐시 (`_border_style_cache`) — `board_renderer.gd` 이미 적용됨
  - ✅ Rounded rect polygon 캐시 (`_poly_cache`) — `draw_utils.gd` 이미 적용됨
  - ✅ GameOrb `_process` 비활성 조건 — `PLAYING` 상태 아닐 때 skip 이미 적용됨
  - ✅ Pulse tween `_throttled_pulse_redraw()` 30fps 쓰로틀링 — `cell_view.gd` 이미 적용됨
  - ✅ Particle system pooling (`_particle_pool`) — `board_renderer.gd` 이미 적용됨
- [점검] 중독성 개선 완료 항목:
  - ✅ 게임오버 near-miss 보드 하이라이트 + 15가지 메시지 (fda1327)
  - ✅ 첫 트레이 선물 피스 (SaveManager.is_first_gift_available) 이미 구현됨
  - ✅ 콤보 유지 힌트 레이블 + 히트 카운터 도트 (ffae667)
- 6시 요약 Discord 보고 예정
