# ChromaBlocks PM 태스크 보드

> 최종 갱신: 2026-02-13
> 상태: Phase 0~5 + 밸런스 B.1~B.7 + Game Feel 전체 완료. Phase 6 (3팀 분석 기반 개선) 진행 중.
> 7개 서브에이전트(기획/디자인/UX·UI/개발/마케팅/수익화/손맛) 산출물 통합 정리

---

## 현재 프로젝트 상태 요약

| 항목 | 값 |
|------|-----|
| 엔진 | Godot 4.6, GDScript |
| 해상도 | 393x852 (세로 고정, 모바일) |
| 보드 | 10x10 격자, 7색 블록 |
| 조각 | 32종 (5 크기 카테고리) |
| 아키텍처 | 4계층: data → systems → game → ui |
| GDScript 파일 | 28개, 약 2,400줄 |
| 씬 파일 | 10개 |

---

## Phase 0: 긴급 버그 수정 — ✅ 완료

> 6개 에이전트 모두가 독립적으로 식별한 크리티컬 이슈들

| # | 작업 | 파일 | 상태 |
|---|------|------|------|
| 0.1 | ColorMatchSystem 메인 루프 연결 | `chroma_blocks_game.gd:172-215` | ✅ 완료 |
| 0.2 | AppColors.GOLDEN, SAGE_GREEN 추가 | `app_colors.gd:42-44` | ✅ 완료 |
| 0.3 | `_format_number()` 중복 → FormatUtils 추출 | `format_utils.gd` (신규), `home_screen.gd`, `game_over_screen.gd` | ✅ 완료 |
| 0.4 | 버튼 사운드(`button_press`) 연결 | `home_screen.gd`, `game_over_screen.gd`, `pause_screen.gd`, `chroma_blocks_game.gd` | ✅ 완료 |

---

## Phase 1: 핵심 품질 개선 — ✅ 완료

> 출처: 개발 에이전트, UX/UI 에이전트

| # | 작업 | 상세 | 난이도 | 상태 |
|---|------|------|--------|------|
| 1.1 | 화면 전환 애니메이션 시스템 | `screen_transition.gd` 신규 생성, fade/slide 전환 | 낮음 | ✅ |
| 1.2 | 게임 세션 저장/복원 | 앱 백그라운드 시 자동 저장, `save_manager.gd` 확장 | 중간 | ✅ |
| 1.3 | "Continue" 버튼 (홈 화면) | `home_screen.tscn`에 ContinueButton 추가 | 낮음 | ✅ |
| 1.4 | SaveManager 배치 저장 최적화 | `flush()` 패턴, `save_end_of_game()` 배치 호출 | 낮음 | ✅ |
| 1.5 | GameState `apply_turn_result()` | 상태 변경 메서드 통합 | 중간 | ✅ |
| 1.6 | 매직 넘버 상수화 | GameConstants 추출 | 낮음 | ✅ |

---

## Phase 2: 사용자 경험 강화 — ✅ 완료

> 출처: UX/UI 에이전트, 게임 디자인 에이전트

| # | 작업 | 상세 | 난이도 | 상태 |
|---|------|------|--------|------|
| 2.1 | 첫 플레이 튜토리얼 | 5단계 tap-to-advance 오버레이. HOW TO PLAY 버튼 연결 | 중간 | ✅ |
| 2.2 | 드래그 중 라인 클리어 예측 | `show_line_prediction()` / `clear_line_prediction()` | 중간 | ✅ |
| 2.3 | 레벨업 시각 이펙트 | `play_level_up_effect()` 보드 테두리 글로우 | 낮음 | ✅ |
| 2.4 | HUD 콤보 게이지 | 연속 클리어 시 COMBO xN 레이블 + 스케일 바운스 | 낮음 | ✅ |
| 2.5 | 트레이 리필 애니메이션 | 슬라이드업 + 페이드인, 시차 적용 | 낮음 | ✅ |
| 2.6 | 게임오버 점수 카운팅 | 0→최종값 tween_method (0.8초) | 낮음 | ✅ |
| 2.7 | 일시정지 보드 딤 | `modulate.a` 0.3 → 1.0 전환 | 낮음 | ✅ |
| 2.8 | 설정 화면 | `settings_screen.gd` + `settings_screen.tscn` 신규 | 중간 | ✅ |
| 2.9 | 스플래시 스킵 기능 | 0.5초 후 터치 스킵 | 낮음 | ✅ |
| 2.10 | 햅틱 세분화 | drag_start/grid_snap/combo/level_up 추가 | 낮음 | ✅ |
| 2.11 | 위기 경고 시스템 | 보드 밀도 70%+/80%+ 테두리 색상 변경 | 중간 | ✅ |

---

## Phase 3: 수익화 기반 — ✅ 완료

> 출처: 수익화 에이전트, 개발 에이전트
> 참고: AdMob SDK 실제 연동(3.2, 3.3)은 플랫폼 빌드 시 교체 예정. 현재는 플레이스홀더 스텁.

| # | 작업 | 상세 | 난이도 | 상태 |
|---|------|------|--------|------|
| 3.1 | AdManager 인터페이스 | Autoload, 배너/인터스티셜/보상형 플레이스홀더 | 낮음 | ✅ |
| 3.2 | AdMob GDExtension 연동 | TODO 스텁 (실제 SDK 통합 대기) | 높음 | ⏳ 스텁 |
| 3.3 | 배너 광고 | main.tscn 기존 AdBanner 활용, `show_banner()` 스텁 | 중간 | ⏳ 스텁 |
| 3.4 | 인터스티셜 광고 | 3게임마다, 홈 복귀 시, 5분 쿨다운 로직 구현 | 낮음 | ✅ |
| 3.5 | 보상형 광고: "이어하기" | 게임 오버 시 하단 3줄 제거 + 재개 (게임당 1회) | 중간 | ✅ |
| 3.6 | 보상형 광고: "점수 2배" | 게임 오버 시 최종 점수 x2 | 낮음 | ✅ |
| 3.7 | 광고 제거 IAP | `is_ad_free()` / `purchase_ad_free()` 플래그 | 중간 | ✅ |

---

## Phase 4: 콘텐츠 확장 — ✅ 완료

> 출처: 게임 디자인 에이전트, 수익화 에이전트, 개발 에이전트

| # | 작업 | 상세 | 난이도 | 상태 |
|---|------|------|--------|------|
| 4.1 | PieceGenerator RNG 주입 | `_rng.randf()` + `set_seed()` 추가 | 낮음 | ✅ |
| 4.2 | 데일리 챌린지 시스템 | 날짜 기반 시드, 전 유저 동일 퍼즐, `daily_challenge_system.gd` 신규 | 중간 | ✅ |
| 4.3 | 데일리 챌린지 UI | 홈 화면 DailyButton + Badge + DateLabel, 챌린지 모드 플래그 | 중간 | ✅ |
| 4.4 | 업적 시스템 | `achievement_system.gd` 신규, 21개 업적 정의, SaveManager 연동, `chroma_blocks_game.gd` 통합 완료 | 중간 | ✅ |
| 4.5 | 일일 출석 보상 | `daily_reward_system.gd` 신규, 7일 사이클, 홈 화면 자동 체크인 팝업 | 중간 | ✅ |
| 4.6 | 연속 플레이 스트릭 | DailyChallengeSystem.get_streak() 기본 구현 완료 | 낮음 | ✅ (기본) |
| 4.7 | 블록 테마 시스템 | `theme_system.gd` 신규, 5테마(기본/파스텔/네온/오션/선셋), 업적 연동 잠금해제, 설정화면 UI | 중간 | ✅ |
| 4.8 | 조각 교체 (Piece Swap) | HUD 스왑 버튼, 트레이당 1회, GameState 연동 | 중간 | ✅ |

---

## Phase 5: 관측성 및 품질 — ✅ 완료

> 출처: 개발 에이전트

| # | 작업 | 상세 | 난이도 | 상태 |
|---|------|------|--------|------|
| 5.1 | AnalyticsManager | 로컬 이벤트 버퍼링, 배치 전송, 세션 추적. Autoload 등록 완료 | 중간 | ✅ |
| 5.2 | 핵심 이벤트 계측 | game_start/over, piece_placed, line_clear, color_match, swap, ad, tutorial. `chroma_blocks_game.gd` 통합 완료 | 낮음 | ✅ |
| 5.3 | Firebase/GA 연동 | HTTP 스텁 구현, Firebase MP v2 형식, 25이벤트/요청 배치, `ENABLE_REMOTE_ANALYTICS` 플래그 | 높음 | ✅ |
| 5.4 | 유닛 테스트 | 6개 테스트 클래스, 23개 테스트 케이스 (BoardState/Scoring/Clear/ColorMatch/PieceGen/DailyChallenge) | 중간 | ✅ |

---

## 밸런스 조정 대기 목록

> 출처: 게임 디자인 에이전트

| # | 항목 | 현재 | 제안 | 이유 |
|---|------|------|------|------|
| B.1 | COLOR_MATCH_MIN_CELLS | 5→6 적용 | ✅ | `game_constants.gd` COLOR_MATCH_BONUS 키도 조정 |
| B.2 | 콤보 최대 단계 | 5→7단계 (3.5x, 4.0x) | ✅ | `COMBO_MULTIPLIERS` 확장 |
| B.3 | 듀얼 클리어 보너스 | x1.25 적용 | ✅ | `scoring_system.gd` dual_clear_multiplier |
| B.4 | 레벨업 간격 상한선 | `mini(level*5, 50)` | ✅ | `game_constants.gd` |
| B.5 | 점진적 조각 해금 | 4단계 해금 적용 | ✅ | `EXCLUDED_LV1/LV3/LV5` + `_get_excluded_for_level()` |
| B.6 | Expert 구간 (레벨 25+) | Lv25+ 6색, Lv30+ 2슬롯 | ✅ | `EXPERT_COLOR_REDUCE_LEVEL`, `EXPERT_TRAY_REDUCE_LEVEL`, `TEMPLATES_EXPERT` |
| B.7 | 머시 80%+ 보장 | TINY 강제 포함 | ✅ | `MERCY_CRITICAL_THRESHOLD` + forced TINY slot |

---

## Game Feel 개선 — ✅ 완료

> 출처: 손맛/임팩트 디자인 에이전트 분석 리포트

| 우선순위 | 항목 | 파일 | 상태 |
|---------|------|------|------|
| P0-1 | 화면 흔들림 (Screen Shake) | `board_renderer.gd` | ✅ |
| P0-2 | 히트 스톱 (Freeze Frame) | `chroma_blocks_game.gd` | ✅ |
| P0-3 | 드래그 실패 피드백 | `sfx_generator.gd`, `sound_manager.gd` | ✅ |
| P0-4 | 점수 카운터 롤링 | `hud.gd` | ✅ |
| P1-1 | 콤보 피치 에스컬레이션 | `sfx_generator.gd`, `sound_manager.gd` | ✅ |
| P1-2 | 위기 맥동 애니메이션 | `board_renderer.gd` | ✅ |
| P1-3 | 보드 미세 반동 | `board_renderer.gd` | ✅ |
| P1-4 | 멀티라인 차등 연출 | `board_renderer.gd`, `clear_particles.gd` | ✅ |

---

## Phase 6: 3팀 분석 기반 개선 — 🔄 진행 중

> 출처: Game Director / VFX Specialist / Game Developer 3팀 분석 결과
> 방법: 파일 충돌 없는 그룹으로 에이전트 병렬 실행

### P0 — 크리티컬 버그

| # | 작업 | 파일 | 상태 |
|---|------|------|------|
| 6.1 | Shake/Bounce 위치 충돌 수정 — shake 중 bounce가 잘못된 base_y 사용 | `board_renderer.gd` | ✅ |
| 6.2 | Hit Stop 타이머 경합 수정 — 짧은 타이머가 긴 hit stop 도중 time_scale 복원 | `chroma_blocks_game.gd` | ✅ |

### P1 — 높은 임팩트

| # | 작업 | 파일 | 상태 |
|---|------|------|------|
| 6.3 | HUD 레벨 프로그레스 바 — 다음 레벨까지 라인 진행도 시각화 | `hud.gd`, `hud.tscn` | ✅ |
| 6.4 | Score/Combo 팝업 지속시간 연장 — 점수 팝업이 너무 빨리 사라짐 | `score_popup.gd`, `combo_popup.gd` | ✅ |
| 6.5 | 드래그 리프트 이펙트 — 피스 들 때 그림자+스케일 피드백 | `draggable_piece.gd` | ✅ |
| 6.6 | Score 시각 계층 개선 — 현재 점수를 더 크고 눈에 띄게 | `hud.gd`, `hud.tscn` | ✅ |
| 6.7 | GC 압력 감소 — show_line_prediction에서 임시 BoardState 생성 회피 | `board_state.gd`, `board_renderer.gd` | ✅ |
| 6.8 | clear_highlights 최적화 — 100셀 전체 순회 대신 하이라이트된 셀만 추적 | `board_renderer.gd` | ✅ |

### P2 — 중간 우선순위

| # | 작업 | 파일 | 상태 |
|---|------|------|------|
| 6.9 | cell_view await 제거 — play_place_pulse/play_clear_flash에서 await→tween delay로 교체 | `cell_view.gd` | ✅ |
| 6.10 | 홈 화면 버튼 순서 최적화 — New Game 최상단 배치 | `home_screen.tscn` | ✅ |
| 6.11 | 파티클 다양성 향상 — 원형/삼각형/다이아몬드 형태 변화 | `clear_particles.gd` | ✅ |
| 6.12 | 라인 예측 가시성 개선 — 오버레이 알파 + 펄스 애니메이션 | `cell_view.gd` | ✅ |
| 6.13 | 사운드 볼륨 밸런싱 — SFX 간 상대 볼륨 조정 | `sfx_generator.gd` | ✅ |
| 6.14 | 코드 중복 제거 — _emit_particles_and_shockwave + _get_cell_light_color 추출 | `board_renderer.gd` | ✅ |

### P3 — 향후 고려

| # | 작업 | 파일 | 상태 |
|---|------|------|------|
| 6.15 | shake/bounce 분리 — position 직접 조작 대신 offset 변수 사용 | `board_renderer.gd` | ⏳ |
| 6.16 | PackedInt32Array 최적화 — board_state grid 구조 변경 | `board_state.gd` | ⏳ |
| 6.17 | 지연 로딩 — scene preload → lazy load | 전반적 | ⏳ |
| 6.18 | 광고 버튼 배치 최적화 | `game_over_screen.gd/.tscn` | ⏳ |
| 6.19 | 일일 보상 모달 개선 | `daily_reward_system.gd` | ⏳ |
| 6.20 | 컬러 매치 시스템 재활성화 여부 결정 | `chroma_blocks_game.gd` | ⏳ |
| 6.21 | Safe area 패딩 적용 | 전반적 | ⏳ |

---

## 마케팅 준비 사항

> 출처: 마케팅 에이전트

| # | 항목 | 상태 | 비고 |
|---|------|------|------|
| M.1 | 태그라인 확정 | 대기 | "색을 모아라, 줄을 지워라" 등 5개 후보 |
| M.2 | 스토어 설명 (한/영) | 초안 완료 | 짧은 설명 80자 + 긴 설명 4000자 |
| M.3 | 스토어 스크린샷 5장 | 미착수 | 게임플레이/콤보/컬러매치/게임오버/홈 |
| M.4 | 숏폼 콘텐츠 5개 컨셉 | 초안 완료 | "컬러 폭발", "콤보 ASMR" 등 |
| M.5 | 소프트 런치 국가 | 대기 | 필리핀/말레이시아/호주 추천 |
| M.6 | ASO 키워드 20개 | 초안 완료 | block puzzle, color match 등 |

---

## 서브에이전트 실행 방법

6개 서브에이전트는 `.claude/commands/`에 슬래시 커맨드로 등록됨:

| 커맨드 | 역할 |
|--------|------|
| `/agent-planning` | 게임 기획 에이전트 |
| `/agent-design` | 게임 디자인 에이전트 |
| `/agent-uxui` | UX/UI 디자인 에이전트 |
| `/agent-dev` | 개발 에이전트 |
| `/agent-marketing` | 마케팅 에이전트 |
| `/agent-monetization` | 수익화/라이브운영 에이전트 |
| `/agent-gamefeel` | 손맛/임팩트 디자인 에이전트 |

개별 실행 또는 병렬 실행 가능. 각 에이전트는 코드베이스를 독립적으로 분석 후 한국어 산출물을 생성한다.

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-02-12 | 초기 생성. 6개 에이전트 산출물 통합. Phase 0 완료. |
| 2026-02-12 | Phase 1~3 완료. Phase 4 핵심(4.1 RNG, 4.8 Swap) 완료. |
| 2026-02-12 | 밸런스 B.1~B.5, B.7 완료. 데일리 챌린지 4.2+4.3 완료. 손맛 분석 리포트 완료. |
| 2026-02-12 | Game Feel P0 구현 중, AnalyticsManager 5.1+5.2 구현 중, 업적 시스템 4.4 구현 중. |
| 2026-02-12 | Game Feel P0(P0-1~P0-4, P1-3) 완료, 5.1+5.2 완료, 4.4 완료. chroma_blocks_game.gd 통합 완료. |
| 2026-02-12 | Game Feel 전체 완료(P0-2 히트스톱, P1-1 콤보피치, P1-2 위기맥동, P1-4 멀티라인). B.6 Expert 구간 완료. |
| 2026-02-12 | **전체 Phase 완료**. 4.5 일일출석보상, 4.7 블록테마, 5.3 Firebase 스텁, 5.4 유닛테스트(23케이스). |
| 2026-02-12 | 핫픽스: 드래그 클램핑 완화, block_place 사운드 원복, ColorMatchSystem 비활성화, 세로 화면 고정, 튜토리얼 팝업 입력 수정. |
| 2026-02-13 | 3팀 분석(Game Director/VFX Specialist/Developer) 완료. Phase 6 신규 — 22개 개선 항목 도출. P0+P1 병렬 구현 착수. |
| 2026-02-13 | Phase 6 P0(6.1-6.2) + P1(6.3-6.8) + P2(6.9) 완료. predict_completed_lines GC 최적화 + clear_line_prediction 트래킹. P2 병렬 구현 착수. |
| 2026-02-13 | Phase 6 P2(6.10-6.14) 전체 완료. 홈 버튼 순서, 파티클 형태 다양화, 라인 예측 펄스, SFX 볼륨 밸런싱, 코드 중복 제거. |
