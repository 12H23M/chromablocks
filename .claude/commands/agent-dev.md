# 🛠️ 개발자 에이전트

## 역할
ChromaBlocks의 GDScript 코드를 작성/수정하고, 아키텍처를 유지하며 빌드/배포한다.

## 지시사항

1. CLAUDE.md를 반드시 먼저 읽어라 — GDScript 함정과 금지 사항 포함.
2. 코드 수정 전 관련 파일 전체를 읽고, 아키텍처 계층을 지켜라.
3. 빌드/배포는 `scripts/deploy.sh`를 사용하라.

## 아키텍처 (4계층)

```
scripts/
├── core/       ← 상수, 열거형, 색상 (data에서만 참조)
│   ├── app_colors.gd      — Prismatic Pop 팔레트, UI 색상
│   ├── enums.gd            — BlockColor, GameMode 등
│   └── game_constants.gd   — 보드(8x8), 점수, 타이밍, DDA 파라미터
│
├── data/       ← 순수 데이터 모델 (로직 없음)
│   ├── block_piece.gd      — 블록 피스 구조체
│   ├── board_state.gd      — 8x8 보드 상태 관리
│   ├── game_state.gd       — 점수, 레벨, 콤보 상태
│   └── piece_definitions.gd — 32종 피스 모양 정의
│
├── systems/    ← 게임 로직 (data 참조, game/ui 참조 금지)
│   ├── scoring_system.gd      — 점수 계산
│   ├── clear_system.gd        — 라인 클리어 판정
│   ├── placement_system.gd    — 피스 배치 가능 여부
│   ├── piece_generator.gd     — DDA 기반 피스 생성
│   ├── difficulty_system.gd   — 레벨/난이도 관리
│   ├── chroma_chain_system.gd — 크로마 체인 (5+ 같은색 연쇄)
│   ├── chroma_blast_system.gd — 크로마 블라스트 (전체줄 동색)
│   ├── game_over_system.gd    — 게임오버 판정
│   ├── auto_player.gd         — 오토플레이 봇
│   ├── mission_system.gd      — 미션 런 모드
│   └── ...
│
├── game/       ← 게임 씬 (systems 호출, 렌더링 담당)
│   ├── chroma_blocks_game.gd  — 메인 게임 컨트롤러
│   ├── board_renderer.gd      — 보드 그리기
│   ├── cell_view.gd           — 셀 렌더링 (_draw)
│   ├── draggable_piece.gd     — 드래그 인터랙션
│   ├── piece_tray.gd          — 하단 트레이 (3피스)
│   ├── clear_particles.gd     — 클리어 파티클
│   └── *_popup.gd             — 점수/콤보/체인/블라스트 팝업
│
├── ui/         ← 화면 씬
│   ├── home_screen.gd, game_over_screen.gd, pause_screen.gd
│   ├── settings_screen.gd, splash_screen.gd
│   ├── hud.gd, xp_bar.gd, mission_hud.gd
│   └── tutorial_overlay.gd, screen_transition.gd
│
└── utils/      ← 유틸리티 (어디서든 참조 가능)
    ├── draw_utils.gd       — 블록 렌더링 (DO NOT MODIFY)
    ├── save_manager.gd     — 세이브/로드 (DO NOT MODIFY)
    ├── sound_manager.gd    — 효과음 (DO NOT MODIFY)
    ├── sfx_generator.gd    — 8-bit SFX 생성 (DO NOT MODIFY)
    ├── music_manager.gd    — BGM 관리 (DO NOT MODIFY)
    ├── music_generator.gd  — 프로시저럴 BGM
    ├── ad_manager.gd       — AdMob 스텁
    ├── haptic_manager.gd   — 진동 피드백
    └── format_utils.gd     — 숫자 포맷팅
```

## GDScript 컨벤션 (필수)

```gdscript
# ❌ NEVER — Dictionary/Array 접근에 := 사용 금지
var w := dict["key"].size()

# ✅ ALWAYS — 명시적 타입 선언
var w: int = dict["key"].size()

# Engine.time_scale 보정 (히트스탑 이펙트 때문)
# UI tween은 반드시:
tween.set_speed_scale(1.0 / Engine.time_scale)
# 또는 Time.get_ticks_msec() 사용
```

## 수정 금지 파일
- DrawUtils, SaveManager, SoundManager, SfxGenerator, MusicManager
- PieceDefinitions의 기존 피스 SHAPES (새 피스 추가만 가능)

## 빌드/배포

```bash
# 풀 파이프라인: 빌드 → 설치 → 실행
./scripts/deploy.sh

# 빌드 스킵, 기존 APK 설치만
./scripts/deploy.sh --skip-build

# 실행 후 스크린샷 캡처
./scripts/deploy.sh --screenshot
```

- Godot: `/Applications/Godot.app/Contents/MacOS/Godot`
- ADB: `~/Library/Android/sdk/platform-tools/adb`
- 디바이스: Galaxy S24+ (Tailscale: 100.70.88.124:5555)
- 패키지: `com.alba.chromablocks`

## 산출물
- 요청된 기능/버그 수정 코드
- 커밋 메시지에 `[auto]` 태그 포함
- 변경 파일 목록과 간단한 설명

## 이 에이전트를 사용하는 방법
```
/agent-dev [구현할 기능 또는 버그 설명]
```
코드 구현, 버그 수정, 리팩토링, 빌드 시 사용.
