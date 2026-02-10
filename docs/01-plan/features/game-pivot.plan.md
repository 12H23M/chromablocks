# Game Pivot Planning Document

> **Summary**: BlockDrop을 테트리스 스타일 낙하 블록 게임에서, 저작권 문제가 없고 수익성 높은 **블록 퍼즐 게임**으로 전환
>
> **Project**: BlockDrop → ChromaBlocks (가제)
> **Author**: AI-Assisted
> **Date**: 2026-02-10
> **Status**: Draft

---

## 1. Overview

### 1.1 Purpose

테트리스(Tetris)의 저작권/상표권 문제를 완전히 회피하면서, 2025년 가장 빠르게 성장하는 모바일 퍼즐 서브장르인 **Block Puzzle**로 게임 콘셉트를 전환한다. 기존 Flutter + Flame 코드베이스를 최대한 재활용하면서 수익 구조를 갖춘 게임을 제작한다.

### 1.2 Background

#### 테트리스 IP 리스크

테트리스는 저작권, 상표권, 트레이드 드레스로 3중 보호되어 있다:

- **상표권**: "Tetris" 이름, 로고, 밝은 색 블록 + 세로 직사각형 플레이필드(trade dress)
- **저작권**: 게임의 시각적 표현과 "look and feel" (2012년 *Tetris Holding v. Xio Interactive* 판결)
- **범위**: The Tetris Company가 적극적으로 클론을 단속 (Tris 앱스토어 제거 사례 등)

현재 BlockDrop은 폴리오미노 형태를 변형하고 컬러 매칭을 추가했지만, "낙하 블록 + 라인 클리어 + 세로 플레이필드"라는 핵심 구조가 테트리스와 유사해 법적 리스크가 존재한다.

#### 시장 기회

2025년 모바일 퍼즐 시장 데이터 (AppMagic, Sensor Tower):

| 서브장르 | YoY 성장률 | 2025 매출 규모 | 진입 난이도 |
|---------|-----------|--------------|-----------|
| **Block Puzzle** | **+911%** | $156M | 중간 |
| Fill & Organize | +175% | $231M | 중간 |
| Sort Puzzle | +149% | $3M | 낮음 |
| Match-3 | +4% | $4.6B | 매우 높음 (기존 강자 독점) |
| Tile Match-3 | -31% | 하락 중 | - |
| Bubble Shooter | -20% | 하락 중 | - |

**Block Puzzle이 +911% 성장으로 가장 폭발적이며, 인디 개발자에게 가장 적합한 서브장르이다.**

대표 성공 사례 **Block Blast** (Hungry Studio):
- 40M+ DAU, 월 $30M+ 광고 수익
- 순수 광고 모델로도 $1M/일 달성
- 3,000회+ A/B 테스트 진행 (데이터 드리븐)

### 1.3 Related Documents

- 기존 계획서: `docs/01-plan/features/tetris-mobile-app.plan.md`
- UI 디자인: `docs/02-design/features/ui-redesign.design.md`
- 참고: [Tetris IP 보호 분석](https://ericguan.substack.com/p/why-is-tetris-ip-protection-so-strong)
- 참고: [Block Puzzle 시장 분석](https://www.deconstructoroffun.com/blog/2026/1/19/from-tetris-to-block-blast-why-block-puzzles-never-stop-printing)
- 참고: [2025 캐주얼 게임 리포트](https://appmagic.rocks/research/casual-report-h1-2025)
- 참고: [하이브리드 수익화 가이드](https://cas.ai/2025/10/09/hybrid-monetization-mobile-games-guide-2/)

---

## 2. Game Concept: ChromaBlocks (가제)

### 2.1 Core Concept

**"블록을 배치하고, 줄을 완성하고, 색을 맞춰 폭발시켜라"**

10x10 그리드에 폴리오미노 블록을 자유롭게 드래그 & 드롭으로 배치한다.
가로줄 또는 세로줄이 완성되면 클리어된다.
같은 색 블록이 5개 이상 인접하면 **컬러 매치 보너스**가 발생한다.

### 2.2 테트리스와의 핵심 차별점

| 요소 | 테트리스 | ChromaBlocks |
|-----|---------|-------------|
| 블록 이동 | 위에서 아래로 낙하 (중력) | 플레이어가 직접 드래그 & 드롭 (중력 없음) |
| 플레이필드 | 10x20 세로 직사각형 | 10x10 정사각형 그리드 |
| 클리어 조건 | 가로줄만 | 가로줄 + 세로줄 |
| 시간 압박 | 실시간 (블록이 계속 떨어짐) | 턴 기반 (시간 제한 없음) |
| 블록 선택 | 다음 블록 1개만 보임 | 3개 블록 중 순서 자유롭게 선택 |
| 회전 | 실시간 회전 필수 | 회전 없음 (배치 시 고정 형태) |
| 핵심 매력 | 반사 속도 + 공간 효율 | 전략적 배치 + 컬러 매칭 콤보 |
| IP 위험 | The Tetris Company 적극 단속 | 없음 (게임 매커닉은 저작권 보호 대상 아님) |

### 2.3 법적 안전성

미국 저작권법상 게임 매커닉, 규칙, 아이디어는 저작권 보호 대상이 아니다:
> "Copyright does not protect the idea for a game, its name or title, or the method or methods for playing it." — US Copyright Office

Block Puzzle 장르는 수백 개의 유사 게임이 공존하는 시장이다 (1010!, Woodoku, Block Blast, Blockudoku 등).
핵심은 **독자적 시각적 표현(expression)** 을 만드는 것이며, 이는 기존 "Luminous Flow" 디자인 시스템으로 이미 확보되어 있다.

---

## 3. Scope

### 3.1 In Scope (Phase 1 — MVP)

- [x] 10x10 그리드 기반 블록 퍼즐 코어 게임플레이
- [x] 3개 블록 동시 표시 & 드래그 드롭 배치
- [x] 가로/세로 줄 완성 시 클리어
- [x] 컬러 매칭 보너스 (5+ 인접 동색 블록)
- [x] 콤보 시스템 (연속 클리어 보너스)
- [x] 점수 시스템 & 로컬 하이스코어
- [x] "Luminous Flow" 비주얼 스타일 적용
- [x] 게임 오버 조건 (3개 블록 모두 배치 불가)
- [x] 효과음 & 햅틱 피드백
- [x] 기본 광고 통합 (Rewarded + Interstitial)

### 3.2 In Scope (Phase 2 — 수익화 & 리텐션)

- [ ] 데일리 챌린지 (매일 고정 블록 순서, 글로벌 랭킹)
- [ ] 프로그레시브 난이도 (레벨업에 따른 블록 복잡도 증가)
- [ ] 파워업 시스템 (Undo, Destroy Block, Shuffle)
- [ ] IAP 상점 (광고 제거, 코스메틱 테마, 파워업 팩)
- [ ] 리텐션 메커닉 (일일 보상, 연속 출석)

### 3.3 Out of Scope (미래 고려)

- 멀티플레이어 / VS 모드
- 소셜 기능 (친구, 클랜)
- 시즌 패스 / 배틀패스
- 클라우드 세이브 / 계정 시스템
- 라이브 이벤트 시스템

---

## 4. Game Design Details

### 4.1 Grid & Blocks

```
┌──────────────────────────────────┐
│  10x10 Grid (100 cells)          │
│                                  │
│  ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐         │
│  │ │ │ │ │ │ │ │ │ │ │  Row 1   │
│  ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤         │
│  │ │ │ │█│█│ │ │ │ │ │  Row 2   │
│  ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤         │
│  │ │ │ │█│ │ │ │ │ │ │  Row 3   │
│  ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤         │
│  │ │ │ │ │ │ │ │ │ │ │  ...     │
│  ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤         │
│  │ │ │ │ │ │ │ │ │ │ │  Row 10  │
│  └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘         │
│                                  │
│  ┌────┐ ┌────┐ ┌────┐           │
│  │ P1 │ │ P2 │ │ P3 │  Tray     │
│  └────┘ └────┘ └────┘           │
└──────────────────────────────────┘
```

**블록 형태** (기존 폴리오미노 재활용):

| 카테고리 | 형태 | 셀 수 | 출현 빈도 |
|---------|------|-------|----------|
| Mono | ■ | 1 | 희귀 (파워업용) |
| Duo | ■■ | 2 | 높음 |
| Tri-Line | ■■■ | 3 | 높음 |
| Tri-L | ■■ / ■ | 3 | 중간 |
| Quad-Square | ■■ / ■■ | 4 | 중간 |
| Quad-Line | ■■■■ | 4 | 중간 |
| Quad-T | ■■■ / _■ | 4 | 낮음 |
| Quad-Z | ■■_ / _■■ | 4 | 낮음 |
| Quad-S | _■■ / ■■_ | 4 | 낮음 |
| Quad-L | ■_ / ■_ / ■■ | 4 | 낮음 |
| Pent-Plus | _■_ / ■■■ / _■_ | 5 | 매우 낮음 |

**컬러 시스템** (기존 7색 재활용):
- Coral (#FF6B6B), Amber (#FFB347), Lemon (#FFED4E)
- Mint (#4ECDC4), Sky (#45B7D1), Lavender (#A78BFA)
- 블록당 랜덤 컬러 배정 (동일 블록 = 동일 색)

### 4.2 Gameplay Loop

```
[새 라운드 시작]
     │
     ▼
[블록 3개 랜덤 생성 → 트레이에 표시]
     │
     ▼
[플레이어: 블록 1개 드래그 → 그리드에 드롭] ◀──┐
     │                                         │
     ▼                                         │
[배치 가능 체크 → 그리드에 고정]                    │
     │                                         │
     ▼                                         │
[줄 완성 체크 (가로 + 세로)]                       │
     │ Yes          │ No                       │
     ▼              ▼                          │
[줄 클리어 애니]  [컬러 매치 체크]                   │
     │              │                          │
     ▼              ▼                          │
[점수 계산]      [5+ 동색 인접 → 보너스 폭발]       │
     │              │                          │
     ▼              ▼                          │
[콤보 카운터 업데이트]                              │
     │                                         │
     ▼                                         │
[트레이에 블록 남음?] ─── Yes ─────────────────────┘
     │ No
     ▼
[새 블록 3개 생성]
     │
     ▼
[어떤 블록도 배치 불가?] ─── No ──→ [계속 플레이]
     │ Yes
     ▼
[게임 오버]
```

### 4.3 Scoring System

| 액션 | 기본 점수 | 비고 |
|-----|----------|-----|
| 블록 배치 | 셀 수 x 5 | 2셀=10, 3셀=15, 5셀=25 |
| 1줄 클리어 | 100 | 가로 또는 세로 |
| 2줄 동시 | 300 | |
| 3줄 동시 | 600 | |
| 4줄+ 동시 | 1000+ | 추가 줄당 +500 |
| 컬러 매치 (5셀) | 200 | 동색 인접 5개 |
| 컬러 매치 (6셀) | 350 | |
| 컬러 매치 (7+셀) | 500+ | 추가 셀당 +150 |
| 콤보 (연속 클리어) | x1.2 ~ x3.0 | 6단계 콤보 배율 |
| 완벽 클리어 (보드 비우기) | 2000 | 보너스 |

### 4.4 Difficulty Progression

- **레벨 1-10**: 2~3셀 블록 위주, 쉬운 컬러 배치
- **레벨 11-25**: 4셀 블록 빈도 증가, 컬러 다양화
- **레벨 26+**: 5셀 블록 등장, 고난이도 형태 빈도 증가
- 레벨업 조건: 줄 클리어 누적 (레벨 x 5줄)

### 4.5 Game Over Condition

3개 블록이 모두 그리드에 배치할 수 없을 때 게임 오버.
- Block Blast와 동일한 방식
- 플레이어가 그리드 관리를 잘못하면 공간이 부족해짐
- 전략적 블록 배치가 핵심

---

## 5. Revenue Model (수익 구조)

### 5.1 Monetization Strategy: Hybrid (Ads + IAP)

2025년 하이브리드 캐주얼 퍼즐 시장에서 가장 효과적인 모델:
광고 60% + IAP 40% 비율 타겟 (초기에는 광고 중심, 이후 IAP 확대)

### 5.2 Ad Monetization (광고)

| 광고 유형 | 위치 | 빈도 | CPM 예상 |
|----------|------|------|---------|
| Banner | 하단 고정 | 상시 | $1-3 |
| Interstitial | 게임 오버 후 | 매 3게임 | $5-15 |
| Rewarded Video | 부활 / 파워업 | 유저 선택 | $10-30 |

**Rewarded Ad 활용**:
- 게임 오버 시 1회 부활 (트레이 블록 교체)
- 추가 파워업 획득
- 2배 점수 부스트 (다음 라운드)

### 5.3 IAP (인앱 구매)

| 상품 | 가격 | 유형 |
|-----|------|------|
| 광고 제거 | $2.99 | 영구 |
| 파워업 팩 (Undo x5 + Destroy x3) | $0.99 | 소모품 |
| 프리미엄 테마 팩 | $1.99 | 영구 |
| 주간 부스터 패스 | $4.99/주 | 구독 |

**파워업 종류**:
- **Undo**: 마지막 배치 취소
- **Destroy**: 선택한 블록 1개 제거
- **Shuffle**: 트레이 블록 3개 교체
- **Color Bomb**: 선택한 색의 모든 블록 제거

### 5.4 Revenue Projection (보수적 추정)

| 지표 | 목표 (6개월 후) |
|------|----------------|
| DAU | 10,000 |
| ARPDAU (Ads) | $0.05 |
| ARPDAU (IAP) | $0.02 |
| 월 매출 | ~$21,000 |
| 광고 제거 전환율 | 3-5% |

---

## 6. Technical Architecture

### 6.1 기존 코드 재활용 분석

| 모듈 | 파일 | 재활용 여부 | 변경 내용 |
|------|------|-----------|----------|
| AppColors | `core/constants/app_colors.dart` | **100% 재활용** | 변경 없음 |
| AppTheme | `core/theme/app_theme.dart` | **100% 재활용** | 변경 없음 |
| HapticUtil | `core/utils/haptic_util.dart` | **100% 재활용** | 변경 없음 |
| SoundUtil | `core/utils/sound_util.dart` | **90% 재활용** | 새 이벤트 추가 |
| BlockPiece | `data/models/block_piece.dart` | **80% 재활용** | 회전 제거, 드래그 상태 추가 |
| BoardState | `data/models/board_state.dart` | **70% 재활용** | 10x10 그리드, 세로줄 클리어 추가 |
| GameState | `data/models/game_state.dart` | **60% 재활용** | 트레이 상태, 새 게임 모드 |
| GameRepository | `data/repositories/game_repository.dart` | **100% 재활용** | 변경 없음 |
| BoardComponent | `game/components/board_component.dart` | **80% 재활용** | 10x10 렌더링 적응 |
| PieceComponent | `game/components/piece_component.dart` | **50% 재활용** | 드래그 & 드롭 UI로 변환 |
| GhostPieceComponent | `game/components/ghost_piece_component.dart` | **70% 재활용** | 드래그 중 프리뷰로 변환 |
| ScoringSystem | `game/systems/scoring_system.dart` | **60% 재활용** | 새 점수 테이블 |
| PieceDefinitions | `game/data/piece_definitions.dart` | **80% 재활용** | 가중치 조정 |
| GravitySystem | `game/systems/gravity_system.dart` | **0% 삭제** | 중력 없음 |
| CollisionSystem | `game/systems/collision_system.dart` | **30% 재활용** | canPlace만 필요 |
| LineClearSystem | `game/systems/line_clear_system.dart` | **50% 재활용** | 세로줄 클리어 추가 |
| HomeScreen | `screens/home/home_screen.dart` | **80% 재활용** | 게임 모드 변경 |
| GameScreen | `screens/game/game_screen.dart` | **60% 재활용** | 레이아웃 변경 |
| Overlays | `screens/game/overlays/` | **90% 재활용** | 텍스트 변경 |

**전체 코드 재활용률: ~65-70%**

### 6.2 Architecture Overview

```
┌─────────────────────────────────────┐
│  Flutter UI Layer                    │
│  (HomeScreen, GameScreen, Overlays) │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  Flame GameWidget                    │
│  ChromaBlocksGame (main loop)       │
│  - Touch Input (Drag & Drop)        │
│  - State Management                 │
│  - Animation Controller             │
└──────────────┬──────────────────────┘
               │
     ┌─────────┼─────────┐
     │         │         │
┌────▼───┐ ┌──▼───┐ ┌───▼────┐
│Drag &  │ │Game  │ │Rendering│
│Drop    │ │Logic │ │Engine   │
│Input   │ │      │ │         │
└────────┘ └──┬───┘ └────────┘
         ┌────▼──────────────┐
         │  Game Systems     │
         │  (Pure Logic)     │
         ├───────────────────┤
         │ PlacementSystem   │ ← 블록 배치 가능 체크
         │ ClearSystem       │ ← 줄 클리어 (가로+세로)
         │ ColorMatchSystem  │ ← 컬러 매치 검출
         │ ScoringSystem     │ ← 점수 계산
         │ DifficultySystem  │ ← 난이도 조절
         └───────┬───────────┘
                 │
     ┌───────────┼───────────┐
     │           │           │
┌────▼──┐ ┌─────▼──┐ ┌─────▼──┐
│Board  │ │Piece   │ │Score   │
│State  │ │Tray    │ │& Level │
│(10x10)│ │(3 pcs) │ │State   │
└───────┘ └────────┘ └────────┘
```

### 6.3 New Components Needed

| 컴포넌트 | 설명 | 우선순위 |
|---------|------|---------|
| PieceTray | 3개 블록 표시 + 드래그 시작점 | 높음 |
| DragPreview | 드래그 중 블록 프리뷰 (반투명) | 높음 |
| GridHighlight | 드래그 중 배치 가능 위치 표시 | 높음 |
| ClearAnimation | 줄 클리어 + 컬러 매치 폭발 애니메이션 | 중간 |
| ScorePopup | 점수 팝업 애니메이션 | 중간 |
| AdManager | Google AdMob 연동 | 중간 |
| PowerUpUI | 파워업 버튼 & 효과 | 낮음 (Phase 2) |

### 6.4 Key Architectural Decisions

| 결정 | 선택지 | 선택 | 이유 |
|------|-------|------|------|
| 프레임워크 | Flutter + Flame (유지) | **Flutter + Flame** | 기존 코드 재활용, 60fps 보장 |
| 그리드 크기 | 8x8 / 9x9 / 10x10 | **10x10** | 1010! 원조 검증 크기, 전략적 깊이, 초보자 친화적 |
| 입력 방식 | 터치 드래그 / 탭 배치 | **드래그 & 드롭** | 직관적, 업계 표준 |
| 상태 관리 | 직접 관리 / Riverpod | **직접 관리 (현재)** | 단순성, 추후 Riverpod 전환 가능 |
| 광고 SDK | AdMob / Unity Ads / AppLovin | **Google AdMob** | Flutter 공식 지원, 높은 Fill Rate |
| 로컬 DB | Hive (유지) | **Hive** | 기존 코드, 경량 |

---

## 7. Requirements

### 7.1 Functional Requirements

| ID | 요구사항 | 우선순위 | 상태 |
|----|---------|---------|------|
| FR-01 | 10x10 그리드에 블록 드래그 & 드롭 배치 | High | Pending |
| FR-02 | 가로/세로 줄 완성 시 클리어 애니메이션 | High | Pending |
| FR-03 | 3개 블록 트레이 표시 및 순서 자유 선택 | High | Pending |
| FR-04 | 블록 배치 불가 시 게임 오버 판정 | High | Pending |
| FR-05 | 점수 시스템 (배치, 클리어, 콤보, 컬러 매치) | High | Pending |
| FR-06 | 컬러 매치 보너스 (5+ 동색 인접 블록 폭발) | High | Pending |
| FR-07 | 콤보 시스템 (연속 클리어 배율) | Medium | Pending |
| FR-08 | 로컬 하이스코어 저장 | Medium | Partial (기존 구현) |
| FR-09 | Luminous Flow 비주얼 스타일 적용 | Medium | Partial (기존 구현) |
| FR-10 | 효과음 & 햅틱 피드백 | Medium | Partial (기존 구현) |
| FR-11 | 난이도 프로그레션 (레벨 시스템) | Medium | Pending |
| FR-12 | Rewarded 광고 (부활, 파워업) | Medium | Pending |
| FR-13 | Interstitial 광고 (게임 오버 후) | Medium | Pending |
| FR-14 | 광고 제거 IAP ($2.99) | Low | Pending |
| FR-15 | 데일리 챌린지 모드 | Low | Pending |

### 7.2 Non-Functional Requirements

| 카테고리 | 기준 | 측정 방법 |
|---------|------|----------|
| 성능 | 60fps 유지 (렌더링) | Flame DevTools FPS 카운터 |
| 응답성 | 드래그 입력 <16ms 지연 | 프로파일링 |
| 크기 | APK < 30MB | Release 빌드 측정 |
| 배터리 | 30분 플레이 시 배터리 <10% 소모 | 실기기 테스트 |
| 호환성 | Android 6.0+ / iOS 13.0+ | 실기기 + 에뮬레이터 |
| 접근성 | 색맹 지원 (형태로 구분 가능) | 시각 검토 |

---

## 8. Success Criteria

### 8.1 Definition of Done (MVP)

- [ ] 코어 게임플레이 완성 (드래그 & 드롭, 줄 클리어, 컬러 매치)
- [ ] 게임 오버 + 점수 시스템 작동
- [ ] Luminous Flow 비주얼 적용
- [ ] 효과음 & 햅틱 작동
- [ ] Android/iOS 빌드 성공
- [ ] 30분+ 연속 플레이 시 크래시 없음
- [ ] 60fps 안정적 유지

### 8.2 Quality Criteria

- [ ] 린트 에러 0개
- [ ] Release 빌드 성공 (Android + iOS)
- [ ] APK 크기 < 30MB
- [ ] 메모리 누수 없음 (DevTools 프로파일링)

### 8.3 비즈니스 KPI (출시 후 3개월)

| KPI | 목표 |
|-----|------|
| D1 리텐션 | > 40% |
| D7 리텐션 | > 20% |
| 세션 길이 | > 5분 |
| 일일 세션 수 | > 2회 |
| 광고 노출/DAU | > 3회 |

---

## 9. Risks and Mitigation

| 리스크 | 영향 | 가능성 | 대응 방안 |
|--------|------|-------|----------|
| Block Puzzle 시장 과포화 | High | Medium | 컬러 매칭이라는 차별점, Luminous Flow 비주얼로 차별화 |
| Block Blast 지배적 위치 | Medium | High | 틈새 타겟 (컬러 매칭 좋아하는 유저), ASO 최적화 |
| 광고 수익 낮음 (초기) | Medium | High | 하이브리드 모델로 IAP 보완, 리텐션 최적화 우선 |
| 유저 획득 비용 (UA) 높음 | High | Medium | 오가닉 성장 집중 (ASO, 바이럴 공유), 낮은 CPI 장르 활용 |
| 기존 코드 리팩토링 지연 | Medium | Low | 70% 재활용 가능, 모듈화된 구조 |
| 게임 밸런싱 어려움 | Medium | Medium | A/B 테스트, 플레이 데이터 분석 |

---

## 10. Implementation Roadmap

### Phase 1: Core Game (MVP)

1. BoardState 리팩토링 (10x22 → 10x10, 버퍼 제거)
2. 중력 시스템 제거, 드래그 & 드롭 입력 구현
3. PieceTray 컴포넌트 (3개 블록 표시)
4. 줄 클리어 시스템 (가로 + 세로)
5. 컬러 매치 시스템 개선
6. 점수 시스템 업데이트
7. 게임 오버 판정 로직
8. UI/UX 레이아웃 재구성
9. 애니메이션 (클리어, 컬러 매치, 점수 팝업)
10. 효과음 & 햅틱 연동

### Phase 2: Monetization & Polish

11. Google AdMob 통합
12. Rewarded Video (부활, 파워업)
13. IAP (광고 제거)
14. 난이도 프로그레션
15. 데일리 챌린지

### Phase 3: Growth

16. ASO (App Store Optimization)
17. 분석 도구 연동 (Firebase Analytics)
18. A/B 테스트 프레임워크
19. 파워업 시스템
20. 추가 테마 / 코스메틱

---

## 11. Convention Prerequisites

### 11.1 Existing Conventions

- [x] Flutter + Dart 코드 스타일 (기존 lint 룰)
- [x] Flame Engine 컴포넌트 패턴
- [x] 불변 상태 패턴 (copyWith)
- [x] "Luminous Flow" 디자인 시스템
- [x] 이벤트 기반 오디오/햅틱

### 11.2 New Conventions Needed

| 카테고리 | 현재 | 추가 필요 |
|---------|------|----------|
| 광고 ID 관리 | 없음 | AdMob ID 환경변수 분리 |
| 분석 이벤트 | 없음 | 이벤트 네이밍 컨벤션 |
| A/B 테스트 | 없음 | 피처 플래그 패턴 |

---

## 12. Next Steps

1. [ ] 이 Plan 문서 검토 및 승인
2. [ ] Design 문서 작성 (`game-pivot.design.md`)
3. [ ] 구현 시작 — BoardState 리팩토링부터
4. [ ] MVP 빌드 후 실기기 테스트

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-10 | Initial draft — 시장 조사 & 게임 콘셉트 정의 | AI-Assisted |
| 0.2 | 2026-02-10 | 그리드 크기 8x8 → 10x10 변경 (전략적 깊이, 초보자 친화적) | AI-Assisted |
