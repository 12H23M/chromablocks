# Godot Engine Migration Plan

> **Summary**: ChromaBlocks 게임을 Unity C#에서 Godot 4 + GDScript로 전환. Unity의 복잡한 에디터 의존성을 제거하고, 텍스트 기반 씬/스크립트로 AI 협업 개발을 극대화한다.
>
> **Project**: ChromaBlocks (Godot 4)
> **Author**: AI-Assisted
> **Date**: 2026-02-10
> **Status**: Draft
> **References**: `game-pivot.plan.md` (게임 디자인), `game-pivot.design.md` (기술 설계)

---

## 1. Overview

### 1.1 Purpose

기존 Unity C# 스크립트를 Godot 4 + GDScript로 전환한다.
게임 설계(ChromaBlocks 10x10 블록 퍼즐)는 `game-pivot.plan.md`에 정의된 그대로 유지하며, 엔진과 구현 언어만 변경한다.

### 1.2 Why Godot? (Unity 대비 장점)

| 항목 | Unity | Godot 4 |
|------|-------|---------|
| **Scene 파일** | 바이너리/YAML (에디터 필수) | `.tscn` 텍스트 파일 (AI가 직접 생성 가능) |
| **스크립트** | C# (IDE 필요) | GDScript (Python-like, 간결) |
| **리소스** | `.prefab`, `.asset` (에디터 필수) | `.tres` 텍스트 파일 (AI가 직접 생성 가능) |
| **프로젝트 설정** | ProjectSettings GUI | `project.godot` 텍스트 파일 |
| **빌드** | Unity CLI (라이선스 필요) | `godot --headless --export` (무료) |
| **에디터 의존도** | 높음 (씬/프리팹/Inspector 필수) | **낮음 (모든 파일이 텍스트)** |
| **라이선스** | 무료 (Personal) + 조건부 | **MIT 라이선스 (완전 무료)** |
| **앱 크기** | ~50MB+ | ~20-30MB |
| **학습 곡선** | 높음 | 낮음 |

**핵심 이점**: Godot의 모든 파일이 텍스트 기반이므로, AI가 씬(.tscn), 리소스(.tres), 스크립트(.gd), 프로젝트 설정(project.godot)을 **모두 직접 생성**할 수 있다. Unity에서 불가능했던 프리팹/씬 생성이 Godot에서는 가능하다.

### 1.3 AI 협업 가능 범위 비교

| 작업 | Unity | Godot |
|------|-------|-------|
| 스크립트 작성 | O | O |
| 씬 생성 | X (에디터 필수) | **O (.tscn 텍스트)** |
| 프리팹/리소스 생성 | X (에디터 필수) | **O (.tres 텍스트)** |
| 프로젝트 설정 | X (GUI 필수) | **O (project.godot 텍스트)** |
| 내보내기 설정 | X (GUI 필수) | **O (export_presets.cfg 텍스트)** |
| 빌드 실행 | 조건부 (라이선스) | **O (godot --headless)** |
| **AI 자동화율** | **~40%** | **~95%** |

### 1.4 Related Documents

- 게임 디자인: `docs/01-plan/features/game-pivot.plan.md` (10x10 그리드, 드래그&드롭, 컬러매치 등)
- 기술 설계: `docs/02-design/features/game-pivot.design.md` (시스템 설계, 점수 테이블, 난이도)
- 기존 Unity 스크립트: `Assets/Scripts/` (로직 참조용)

---

## 2. Scope

### 2.1 In Scope

- [x] 기존 Unity C# 게임 로직을 GDScript로 1:1 변환
- [x] Godot 4 프로젝트 구조 생성 (project.godot, 폴더 구조)
- [x] 씬 파일 직접 생성 (.tscn) — Main, Board, Cell, Tray, UI
- [x] 드래그 & 드롭 입력 시스템 (Godot Input 이벤트)
- [x] 10x10 보드 + GridContainer 렌더링
- [x] 줄 클리어 (가로+세로) + 컬러 매치 (flood fill)
- [x] 점수/콤보/레벨 시스템
- [x] Luminous Flow 비주얼 스타일
- [x] 기본 UI (HomeScreen, HUD, GameOver, Pause)
- [x] 효과음 + 햅틱 피드백
- [x] 모바일 내보내기 설정 (Android/iOS)

### 2.2 Out of Scope (Phase 2)

- 광고 통합 (AdMob GDExtension)
- IAP
- 데일리 챌린지
- 파워업 시스템
- 클라우드 세이브

### 2.3 기존 Unity 코드 처리

| 작업 | 결정 |
|------|------|
| `Assets/Scripts/` (30 C# 파일) | **참조 후 삭제** — GDScript 변환 완료 후 |
| `docs/` | **유지** — 게임 디자인 문서는 엔진 무관 |

---

## 3. Godot 4 Architecture

### 3.1 프로젝트 구조

```
project.godot                    # 프로젝트 설정
export_presets.cfg               # 내보내기 설정

scripts/
  core/
    enums.gd                     # BlockColor, PieceType, GameStatus
    game_constants.gd            # 상수 (10x10, 점수 테이블 등)
    app_colors.gd                # Luminous Flow + Ghibli 색상
  data/
    cell.gd                      # Cell 데이터 (Resource)
    block_piece.gd               # 블록 조각 데이터
    piece_definitions.gd         # 12 폴리오미노 정의 + 가중치 랜덤
    board_state.gd               # 10x10 보드 로직 (immutable)
    game_state.gd                # 게임 상태 컨테이너
  systems/
    placement_system.gd          # 배치 검증
    clear_system.gd              # 줄 클리어
    color_match_system.gd        # 컬러 매치 (flood fill)
    scoring_system.gd            # 점수 계산
    game_over_system.gd          # 게임 오버 판정
    difficulty_system.gd         # 난이도 레벨
  game/
    chroma_blocks_game.gd        # 메인 게임 매니저
    board_renderer.gd            # 보드 시각화
    cell_view.gd                 # 셀 렌더링 (4-layer Luminous Flow)
    draggable_piece.gd           # 드래그 & 드롭
    piece_tray.gd                # 3피스 트레이
    grid_highlight.gd            # 배치 프리뷰
    score_popup.gd               # 점수 팝업
    clear_effect.gd              # 클리어 이펙트
  ui/
    ui_manager.gd                # 화면 전환
    hud.gd                       # 점수/레벨/콤보 표시
    home_screen.gd               # 메인 메뉴
    game_over_screen.gd          # 게임 오버
    pause_screen.gd              # 일시정지
  utils/
    save_manager.gd              # ConfigFile 저장
    sound_manager.gd             # AudioStreamPlayer 관리
    haptic_manager.gd            # 진동 피드백

scenes/
  main.tscn                      # 루트 씬
  game/
    board.tscn                   # 10x10 보드 GridContainer
    cell.tscn                    # 셀 프리팹 (4-layer)
    draggable_piece.tscn         # 드래그 가능한 피스
    piece_tray.tscn              # 3-slot 트레이
  ui/
    hud.tscn                     # HUD 오버레이
    home_screen.tscn             # 메인 메뉴
    game_over_screen.tscn        # 게임 오버 화면
    pause_screen.tscn            # 일시정지 화면

resources/
  themes/
    ghibli_theme.tres            # Godot Theme 리소스
  fonts/
    (사용자 추가)

assets/
  audio/
    (사용자 추가)
  icons/
    (사용자 추가)
```

### 3.2 Unity → Godot 매핑

| Unity 개념 | Godot 대응 |
|-----------|-----------|
| MonoBehaviour | Node + .gd 스크립트 |
| GameObject | Node / Node2D / Control |
| Prefab (.prefab) | PackedScene (.tscn) |
| Canvas + UI | Control 노드 (VBoxContainer, HBoxContainer 등) |
| GridLayoutGroup | GridContainer |
| Image (UI) | TextureRect / ColorRect / Panel |
| TextMeshPro | Label / RichTextLabel |
| SerializeField | @export 변수 |
| EventSystem (Drag) | Input._input() / _gui_input() |
| IBeginDragHandler | _gui_input() + InputEventMouseButton |
| AudioSource | AudioStreamPlayer |
| PlayerPrefs | ConfigFile |
| Coroutine | await / Tween / Timer |
| static class | GDScript autoload (싱글톤) |
| ScriptableObject | Resource (.tres) |
| Instantiate(prefab) | scene.instantiate() |

### 3.3 핵심 아키텍처 결정

| 결정 | 선택 | 이유 |
|------|------|------|
| 스크립트 언어 | **GDScript** | C# 대비 간결, 에디터 통합 우수, 모바일 경량 |
| UI 시스템 | **Control 노드** | Godot 내장 UI, GridContainer로 보드 구성 |
| 드래그 & 드롭 | **_gui_input() + set_drag_preview()** | Godot 네이티브 D&D 또는 커스텀 입력 |
| 상태 관리 | **Signal 기반** | Godot의 핵심 패턴, Observer 패턴 내장 |
| 씬 전환 | **CanvasLayer + Visibility** | 오버레이 방식 (Unity와 동일) |
| 저장 | **ConfigFile** | Godot 내장, PlayerPrefs 대응 |
| 오디오 | **AudioStreamPlayer** | Godot 내장 |
| 싱글톤 | **Autoload** | Project Settings → Autoload 등록 |

### 3.4 Signal 구조 (이벤트 시스템)

```
ChromaBlocksGame (메인 매니저)
  ├── signal piece_placed(piece, position)
  ├── signal lines_cleared(result)
  ├── signal color_matched(result)
  ├── signal score_changed(new_score, delta)
  ├── signal combo_changed(combo)
  ├── signal level_changed(new_level)
  ├── signal game_over()
  ├── signal game_started()
  └── signal game_paused(is_paused)

DraggablePiece
  ├── signal drag_started(piece)
  ├── signal drag_moved(piece, position)
  └── signal drag_ended(piece, position)

PieceTray
  └── signal tray_emptied()
```

---

## 4. C# → GDScript 변환 전략

### 4.1 변환 규칙

| C# | GDScript |
|----|----------|
| `public class Foo : MonoBehaviour` | `class_name Foo extends Node` |
| `[SerializeField] private Type _field` | `@export var field: Type` |
| `private void Start()` | `func _ready():` |
| `private void Update()` | `func _process(delta):` |
| `public static class` | Autoload 또는 `static func` |
| `new Dictionary<K,V>()` | `{}` (dict literal) |
| `new List<T>()` | `[]` (array literal) |
| `struct` | `class` 또는 `Dictionary` |
| `event Action<T>` | `signal name(param)` |
| `?.` (null conditional) | `if x != null: x.method()` |
| `switch/case` | `match` |
| `foreach (var x in list)` | `for x in list:` |
| `Mathf.RoundToInt` | `roundi()` |
| `Color.clear` | `Color.TRANSPARENT` |
| `Destroy(obj)` | `obj.queue_free()` |

### 4.2 파일별 변환 난이도

| C# 파일 | GDScript 대응 | 난이도 | 비고 |
|---------|--------------|-------|------|
| Enums.cs | enums.gd (const dict) | 쉬움 | GDScript enum 또는 const |
| GameConstants.cs | game_constants.gd (autoload) | 쉬움 | static → autoload |
| AppColors.cs | app_colors.gd (autoload) | 쉬움 | Color("hex") |
| Cell.cs | cell.gd | 쉬움 | struct → class |
| BlockPiece.cs | block_piece.gd | 쉬움 | 데이터 클래스 |
| PieceDefinitions.cs | piece_definitions.gd | 쉬움 | Dictionary |
| BoardState.cs | board_state.gd | 중간 | flood fill 로직 |
| GameState.cs | game_state.gd | 쉬움 | 데이터 컨테이너 |
| PlacementSystem.cs | placement_system.gd | 쉬움 | 단순 검증 |
| ClearSystem.cs | clear_system.gd | 쉬움 | |
| ColorMatchSystem.cs | color_match_system.gd | 중간 | flood fill |
| ScoringSystem.cs | scoring_system.gd | 쉬움 | |
| GameOverSystem.cs | game_over_system.gd | 쉬움 | |
| DifficultySystem.cs | difficulty_system.gd | 쉬움 | |
| ChromaBlocksGame.cs | chroma_blocks_game.gd | 높음 | 메인 오케스트레이터 |
| BoardRenderer.cs | board_renderer.gd | 높음 | GridContainer 기반 |
| CellView.cs | cell_view.gd | 중간 | 4-layer 구성 |
| DraggablePiece.cs | draggable_piece.gd | 높음 | 입력 시스템 차이 |
| PieceTray.cs | piece_tray.gd | 중간 | |
| GridHighlight.cs | grid_highlight.gd | 중간 | |
| ScorePopup.cs | score_popup.gd | 쉬움 | Tween 사용 |
| ClearEffect.cs | clear_effect.gd | 쉬움 | Tween 사용 |
| UIManager.cs | ui_manager.gd | 쉬움 | visibility toggle |
| HUDController.cs | hud.gd | 쉬움 | Label 업데이트 |
| HomeScreen.cs | home_screen.gd | 쉬움 | |
| GameOverScreen.cs | game_over_screen.gd | 쉬움 | |
| PauseScreen.cs | pause_screen.gd | 쉬움 | |
| SaveManager.cs | save_manager.gd | 쉬움 | ConfigFile |
| SoundManager.cs | sound_manager.gd | 쉬움 | AudioStreamPlayer |
| HapticManager.cs | haptic_manager.gd | 쉬움 | Input.vibrate_handheld() |

**30개 중 쉬움 22개, 중간 5개, 높음 3개**

---

## 5. Implementation Roadmap

### Step 1: 프로젝트 기반 구축
- project.godot 생성
- 폴더 구조 생성
- Autoload 등록 (GameConstants, AppColors, SaveManager, SoundManager)

### Step 2: Core + Data (순수 로직)
- enums.gd, game_constants.gd, app_colors.gd
- cell.gd, block_piece.gd, piece_definitions.gd
- board_state.gd, game_state.gd

### Step 3: Systems (순수 로직)
- placement_system.gd
- clear_system.gd
- color_match_system.gd
- scoring_system.gd
- game_over_system.gd
- difficulty_system.gd

### Step 4: 씬 + 게임 컴포넌트
- cell.tscn + cell_view.gd (4-layer Luminous Flow)
- board.tscn + board_renderer.gd (GridContainer 10x10)
- draggable_piece.tscn + draggable_piece.gd
- piece_tray.tscn + piece_tray.gd
- grid_highlight.gd

### Step 5: UI 씬
- hud.tscn + hud.gd
- home_screen.tscn + home_screen.gd
- game_over_screen.tscn + game_over_screen.gd
- pause_screen.tscn + pause_screen.gd
- ui_manager.gd

### Step 6: 메인 게임 + 이펙트
- main.tscn (루트 씬 조합)
- chroma_blocks_game.gd (메인 매니저)
- score_popup.gd + clear_effect.gd
- sound_manager.gd + haptic_manager.gd

### Step 7: Utils + 폴리싱
- save_manager.gd (ConfigFile)
- 내보내기 설정 (Android/iOS)
- 테스트 씬

### Step 8: 기존 Unity 코드 정리
- Assets/Scripts/ 삭제 (Godot 변환 완료 후)

---

## 6. Requirements

게임 요구사항은 `game-pivot.plan.md` Section 7과 동일. 엔진 전환에 따른 추가 요구사항:

| ID | 요구사항 | 우선순위 |
|----|---------|---------|
| GE-01 | Godot 4.3+ LTS 대응 | High |
| GE-02 | GDScript 전용 (C# 미사용) | High |
| GE-03 | 모든 씬/리소스를 텍스트 파일로 생성 | High |
| GE-04 | Mobile 터치 입력 최적화 | High |
| GE-05 | Android 내보내기 설정 | High |
| GE-06 | iOS 내보내기 설정 | Medium |
| GE-07 | 60fps 유지 (모바일) | High |
| GE-08 | APK 크기 < 30MB | Medium |

---

## 7. Risks and Mitigation

| 리스크 | 영향 | 가능성 | 대응 |
|--------|------|-------|------|
| Godot 모바일 성능 | Medium | Low | 2D 게임이므로 성능 이슈 가능성 낮음 |
| Godot 광고 SDK 부족 | Medium | Medium | GDExtension으로 AdMob 연동 가능, Phase 2에서 처리 |
| GDScript 정적 타이핑 부재 | Low | Low | Godot 4는 정적 타입 힌트 지원 |
| iOS 내보내기 복잡성 | Medium | Medium | Xcode 필수, 별도 설정 필요 |
| .tscn 수동 작성 오류 | Medium | Medium | 씬 작성 후 Godot 에디터에서 검증 |

---

## 8. Success Criteria

- [ ] Godot 4 프로젝트 에디터에서 열림 (오류 없음)
- [ ] 코어 게임플레이 작동 (드래그&드롭, 줄 클리어, 컬러 매치)
- [ ] 게임 오버 + 점수 시스템 작동
- [ ] Luminous Flow 비주얼 적용
- [ ] 모바일 터치 입력 정상 동작
- [ ] Android 내보내기 성공

---

## 9. Godot 설치 필요 사항

사용자 환경: macOS

```bash
# Homebrew로 설치
brew install --cask godot

# 또는 공식 사이트에서 다운로드
# https://godotengine.org/download/macos/
```

설치 후 확인:
```bash
# CLI 접근 가능 여부
godot --version
```

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-10 | Initial draft — Unity → Godot 전환 플랜 | AI-Assisted |
