# Game Pivot Design Document

> **Summary**: BlockDrop을 테트리스 스타일 낙하 블록에서 **ChromaBlocks** (10x10 드래그 & 드롭 블록 퍼즐)로 전환하는 기술 설계
>
> **Project**: BlockDrop → ChromaBlocks
> **Version**: 0.1.0
> **Author**: AI-Assisted
> **Date**: 2026-02-10
> **Status**: Draft
> **Planning Doc**: [game-pivot.plan.md](../01-plan/features/game-pivot.plan.md)

---

## 1. Overview

### 1.1 Design Goals

1. 기존 코드베이스 65-70% 재활용하여 빠른 전환
2. 10x10 그리드 + 드래그 & 드롭 + 컬러 매칭의 새로운 게임 루프 구현
3. "Luminous Flow" 비주얼 시스템 100% 유지
4. 확장 가능한 수익화 아키텍처 (광고 + IAP) 기반 마련
5. 60fps 안정적 유지, 드래그 입력 <16ms 응답

### 1.2 Design Principles

- **최소 변경 원칙**: 동작하는 기존 코드는 최대한 유지, 필요한 부분만 변경
- **불변 상태 패턴 유지**: 모든 State 객체는 `copyWith`로 업데이트
- **시스템 분리**: 게임 로직(Systems)과 렌더링(Components)의 명확한 분리
- **단계적 구현**: MVP 코어 → 수익화 → 성장의 3단계 접근

---

## 2. Architecture

### 2.1 Component Diagram

```
┌──────────────────────────────────────────────────────┐
│  Flutter UI Layer                                     │
│  ┌───────────┐ ┌──────────────┐ ┌──────────────────┐ │
│  │HomeScreen  │ │GameScreen    │ │Overlays          │ │
│  │(수정)      │ │(대폭 수정)    │ │(텍스트 수정)      │ │
│  └─────┬─────┘ └──────┬───────┘ └────────┬─────────┘ │
└────────┼──────────────┼──────────────────┼───────────┘
         │              │                  │
┌────────▼──────────────▼──────────────────▼───────────┐
│  Flame GameWidget                                     │
│  ChromaBlocksGame (신규 — BlockDropGame 대체)          │
│  ┌───────────────┐ ┌────────────┐ ┌────────────────┐ │
│  │DragDropInput   │ │GameLoop    │ │AnimationCtrl   │ │
│  │(신규)          │ │Controller  │ │(수정)           │ │
│  └───────┬───────┘ └─────┬──────┘ └────────┬───────┘ │
└──────────┼───────────────┼─────────────────┼─────────┘
           │               │                 │
┌──────────▼───────────────▼─────────────────▼─────────┐
│  Components (Flame)                                   │
│  ┌──────────┐ ┌──────────┐ ┌───────────┐ ┌────────┐ │
│  │Board     │ │PieceTray │ │DragPreview│ │Score   │ │
│  │Component │ │Component │ │Component  │ │Popup   │ │
│  │(수정)    │ │(신규)    │ │(신규)     │ │(신규)  │ │
│  └──────────┘ └──────────┘ └───────────┘ └────────┘ │
└──────────────────────┬───────────────────────────────┘
                       │
┌──────────────────────▼───────────────────────────────┐
│  Game Systems (Pure Logic)                            │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ │
│  │Placement     │ │ClearSystem   │ │ColorMatch    │ │
│  │System (수정) │ │(수정)        │ │System (수정) │ │
│  ├──────────────┤ ├──────────────┤ ├──────────────┤ │
│  │Scoring       │ │Difficulty    │ │GameOver      │ │
│  │System (수정) │ │System (신규) │ │System (신규) │ │
│  └──────────────┘ └──────────────┘ └──────────────┘ │
└──────────────────────┬───────────────────────────────┘
                       │
┌──────────────────────▼───────────────────────────────┐
│  Data Models                                          │
│  ┌───────────┐ ┌──────────┐ ┌───────────┐           │
│  │BoardState │ │BlockPiece│ │GameState  │           │
│  │(수정)     │ │(수정)    │ │(대폭 수정) │           │
│  └───────────┘ └──────────┘ └───────────┘           │
└──────────────────────────────────────────────────────┘
```

### 2.2 Data Flow

```
[유저 터치] → DragDetector
     │
     ▼
[드래그 시작] → PieceTray에서 블록 선택
     │
     ▼
[드래그 중] → DragPreview 표시 + 그리드 위 스냅 위치 계산
     │         → GridHighlight로 배치 가능/불가 표시
     ▼
[드래그 종료] → PlacementSystem.canPlace() 체크
     │
     ├─ 배치 불가 → 블록 원위치로 복귀 (애니메이션)
     │
     └─ 배치 가능 → BoardState.placePiece()
           │
           ▼
      [ClearSystem.check()]
           │
           ├─ 줄 완성 → clearRows() + 애니메이션
           │
           └─ 줄 미완성 → 패스
                  │
                  ▼
           [ColorMatchSystem.check()]
                  │
                  ├─ 5+ 동색 인접 → removeCells() + 폭발 애니메이션
                  │
                  └─ 매치 없음 → 패스
                         │
                         ▼
                  [ScoringSystem.calculate()]
                         │
                         ▼
                  [트레이 블록 남음?]
                         │
                    Yes ──┤── No
                    │     │
                    ▼     ▼
                 [대기]  [새 블록 3개 생성]
                              │
                              ▼
                         [GameOverSystem.check()]
                              │
                         Game Over ──→ GameOverOverlay
```

### 2.3 File Change Summary

| 액션 | 파일 | 설명 |
|------|------|------|
| **삭제** | `lib/game/blockdrop_game.dart` | 새 게임 엔진으로 대체 |
| **삭제** | `lib/game/systems/gravity_system.dart` | 중력 없음 |
| **삭제** | `lib/game/components/ghost_piece_component.dart` | 고스트 피스 → DragPreview로 대체 |
| **삭제** | `lib/game/components/next_piece_preview.dart` | 단일 다음 블록 → PieceTray로 대체 |
| **삭제** | `lib/game/components/hold_piece_display.dart` | 홀드 기능 제거 |
| **신규** | `lib/game/chroma_blocks_game.dart` | 새 메인 Flame 게임 클래스 |
| **신규** | `lib/game/components/piece_tray_component.dart` | 3개 블록 트레이 |
| **신규** | `lib/game/components/drag_preview_component.dart` | 드래그 중 블록 프리뷰 |
| **신규** | `lib/game/components/grid_highlight_component.dart` | 배치 가능 위치 하이라이트 |
| **신규** | `lib/game/components/score_popup_component.dart` | 점수 팝업 애니메이션 |
| **신규** | `lib/game/components/clear_effect_component.dart` | 클리어/폭발 이펙트 |
| **신규** | `lib/game/systems/game_over_system.dart` | 게임 오버 판정 |
| **신규** | `lib/game/systems/difficulty_system.dart` | 난이도 프로그레션 |
| **수정** | `lib/core/constants/game_constants.dart` | 10x10 상수, 새 점수 테이블 |
| **수정** | `lib/data/models/block_piece.dart` | 회전 제거, 드래그 상태 불필요 |
| **수정** | `lib/data/models/board_state.dart` | 10x10, 세로줄 클리어, 색매치 5+ |
| **수정** | `lib/data/models/game_state.dart` | 트레이 상태, 새 필드 |
| **수정** | `lib/game/components/board_component.dart` | 10x10 렌더링 |
| **수정** | `lib/game/components/piece_component.dart` | 트레이 블록 렌더링용으로 변환 |
| **수정** | `lib/game/systems/collision_system.dart` | canPlace만 유지, 나머지 제거 |
| **수정** | `lib/game/systems/line_clear_system.dart` | 세로줄 클리어 추가 |
| **수정** | `lib/game/systems/scoring_system.dart` | 새 점수 테이블 |
| **수정** | `lib/game/data/piece_definitions.dart` | 가중치 조정, 회전 제거 |
| **수정** | `lib/screens/home/home_screen.dart` | 게임 이름/모드 변경 |
| **수정** | `lib/screens/game/game_screen.dart` | 레이아웃 재구성 |
| **수정** | `lib/screens/game/overlays/*` | 텍스트 변경 |
| **수정** | `lib/main.dart` | 앱 이름 변경 |
| **수정** | `lib/core/utils/sound_util.dart` | 새 이벤트 추가 |
| **수정** | `lib/core/utils/haptic_util.dart` | 새 이벤트 추가 |
| **유지** | `lib/core/constants/app_colors.dart` | 변경 없음 |
| **유지** | `lib/core/theme/app_theme.dart` | 변경 없음 |
| **유지** | `lib/data/repositories/game_repository.dart` | 변경 없음 |

---

## 3. Data Model

### 3.1 GameConstants 변경

**파일**: `lib/core/constants/game_constants.dart`

```dart
class GameConstants {
  GameConstants._();

  // ── Grid (10x10, 버퍼 없음) ──
  static const int boardColumns = 10;
  static const int boardRows = 10;
  // visibleRows, bufferRows 제거

  // ── Piece Tray ──
  static const int traySize = 3; // 동시 표시 블록 수

  // ── Timing (중력 관련 제거) ──
  static const double lineClearAnimDuration = 0.3;
  static const double colorMatchAnimDuration = 0.4;
  static const double scorePopupDuration = 0.8;
  static const double placementAnimDuration = 0.15;

  // ── Scoring (새 점수 테이블) ──
  static const int placementPointsPerCell = 5;

  static const Map<int, int> lineClearPoints = {
    1: 100,
    2: 300,
    3: 600,
    4: 1000,
  };
  // 4줄 초과 시: 1000 + (추가줄 × 500)
  static int lineClearScore(int lines) {
    if (lines <= 0) return 0;
    if (lines <= 4) return lineClearPoints[lines]!;
    return 1000 + (lines - 4) * 500;
  }

  static const List<double> comboMultipliers = [
    1.0, 1.2, 1.5, 2.0, 2.5, 3.0,
  ];

  static const Map<int, int> colorMatchBonus = {
    5: 200,
    6: 350,
    7: 500,
  };
  // 7셀 초과: 500 + (추가셀 × 150)
  static int colorMatchScore(int cells) {
    if (cells < 5) return 0;
    if (cells <= 7) return colorMatchBonus[cells]!;
    return 500 + (cells - 7) * 150;
  }

  static const int perfectClearBonus = 2000;

  // ── Color Match ──
  static const int colorMatchMinCells = 5;

  // ── Difficulty ──
  static int linesForNextLevel(int level) => level * 5;

  // ── 삭제 항목 ──
  // initialDropSpeed, softDropSpeed, lockDelay → 제거
  // difficultyCurveFactor, minDropSpeed → 제거
  // dropSpeedForLevel() → 제거
  // swipeThreshold, flickVelocity, dasDelay, dasRepeat → 제거
  // maxHearts, heartRegenMinutes → 제거
}
```

### 3.2 BlockPiece 변경

**파일**: `lib/data/models/block_piece.dart`

변경 사항:
- `rotation` 필드 제거 (블록 회전 없음)
- `rotatedShape` 제거 → `shape` 직접 사용
- `gridX`, `gridY`를 `int?`로 변경 (트레이에 있을 때는 null)
- `occupiedCells`에서 rotation 로직 제거

```dart
/// 색상 enum — 변경 없음 (BlockColor)

/// PieceType enum — 스킬 블록 제거 (Phase 2로 이동)
enum PieceType {
  // 1-cell (Phase 2 파워업)
  // mono, → Phase 2

  // 2-cell
  duo,

  // 3-cell
  triLine,
  triL,

  // 4-cell
  tetSquare,
  tetLine,
  tetT,
  tetZ,
  tetS,
  tetL,

  // 5-cell
  pentPlus,
  pentU,
  pentT;

  // skillBomb, skillLine, skillColor → 제거 (Phase 2)
  // isSkill getter → 제거
}

/// BlockPiece — 드래그 & 드롭 전용
class BlockPiece {
  final PieceType type;
  final BlockColor color;
  final List<List<int>> shape;

  // rotation 제거
  int? gridX; // null = 트레이에 있음
  int? gridY; // null = 트레이에 있음

  BlockPiece({
    required this.type,
    required this.color,
    required this.shape,
    this.gridX,
    this.gridY,
  });

  /// rotatedShape 제거 → shape 직접 사용

  int get width => shape[0].length;
  int get height => shape.length;

  /// gridX, gridY가 설정된 경우에만 사용
  List<(int x, int y)> occupiedCellsAt(int gx, int gy) {
    final cells = <(int, int)>[];
    for (int row = 0; row < shape.length; row++) {
      for (int col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 1) {
          cells.add((gx + col, gy + row));
        }
      }
    }
    return cells;
  }

  /// 기존 occupiedCells 호환용
  List<(int x, int y)> get occupiedCells {
    if (gridX == null || gridY == null) return [];
    return occupiedCellsAt(gridX!, gridY!);
  }

  BlockPiece copyWith({int? gridX, int? gridY}) {
    return BlockPiece(
      type: type,
      color: color,
      shape: shape,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
    );
  }

  // _rotateShape, _rotateCW 삭제
}
```

### 3.3 BoardState 변경

**파일**: `lib/data/models/board_state.dart`

핵심 변경:
- 기본값 10x10 (버퍼 없음)
- `getCompletedColumns()` 추가
- `clearRows()`에서 세로줄 클리어도 처리 → `clearLines()` 통합
- `findColorMatches()` 임계값 5로 유지 (이미 6으로 되어있으나 Plan에서 5)
- `isTopReached()` → `canPlaceAny()` (게임 오버 조건 변경)

```dart
class Cell {
  // 변경 없음
}

class BoardState {
  final int columns;
  final int rows;
  final List<List<Cell>> grid;

  // 기본값 변경: 10x10
  BoardState({
    this.columns = GameConstants.boardColumns, // 10
    this.rows = GameConstants.boardRows,       // 10
  }) : grid = List.generate(
          rows,
          (_) => List.generate(columns, (_) => const Cell.empty()),
        );

  BoardState.fromGrid({
    required this.columns,
    required this.rows,
    required this.grid,
  });

  // isCellOccupied — 변경 없음
  // isInBounds — 변경 없음

  /// 블록을 특정 위치에 배치 가능한지 체크 (드래그 & 드롭용)
  bool canPlacePieceAt(BlockPiece piece, int gx, int gy) {
    for (final (x, y) in piece.occupiedCellsAt(gx, gy)) {
      if (x < 0 || x >= columns || y < 0 || y >= rows) return false;
      if (grid[y][x].occupied) return false;
    }
    return true;
  }

  /// 블록 배치 (piece의 gridX/gridY 사용)
  BoardState placePiece(BlockPiece piece) {
    // 기존과 동일하지만 y < 0 체크 불필요 (버퍼 없음)
    final newGrid = _copyGrid();
    for (final (x, y) in piece.occupiedCells) {
      if (isInBounds(x, y)) {
        newGrid[y][x] = Cell.filled(piece.color);
      }
    }
    return BoardState.fromGrid(columns: columns, rows: rows, grid: newGrid);
  }

  /// 완성된 가로줄 찾기
  List<int> getCompletedRows() {
    // 기존과 동일
  }

  /// 완성된 세로줄 찾기 (신규)
  List<int> getCompletedColumns() {
    final completed = <int>[];
    for (int col = 0; col < columns; col++) {
      bool full = true;
      for (int row = 0; row < rows; row++) {
        if (!grid[row][col].occupied) {
          full = false;
          break;
        }
      }
      if (full) completed.add(col);
    }
    return completed;
  }

  /// 가로줄 + 세로줄 동시 클리어 (신규)
  /// 반환: (새 BoardState, 클리어된 총 라인 수)
  (BoardState, int) clearCompletedLines() {
    final completedRows = getCompletedRows();
    final completedCols = getCompletedColumns();

    if (completedRows.isEmpty && completedCols.isEmpty) {
      return (this, 0);
    }

    final newGrid = _copyGrid();

    // 1) 완성된 줄의 모든 셀을 비움 (행 + 열)
    for (final row in completedRows) {
      for (int x = 0; x < columns; x++) {
        newGrid[row][x] = const Cell.empty();
      }
    }
    for (final col in completedCols) {
      for (int y = 0; y < rows; y++) {
        newGrid[y][col] = const Cell.empty();
      }
    }

    // 중력 없음! 비운 셀은 그대로 빈칸으로 남음
    // (테트리스와 달리 위에서 아래로 떨어지지 않음)

    final totalLines = completedRows.length + completedCols.length;
    return (
      BoardState.fromGrid(columns: columns, rows: rows, grid: newGrid),
      totalLines,
    );
  }

  /// 컬러 매치 찾기 (5+ 인접 동색)
  List<List<(int, int)>> findColorMatches() {
    // 기존 flood fill 로직 동일
    // 임계값을 GameConstants.colorMatchMinCells (5)로 변경
    ...
    if (group.length >= GameConstants.colorMatchMinCells) {
      matches.add(group);
    }
    ...
  }

  // removeCells — 변경 없음

  /// 특정 블록 리스트 중 하나라도 배치 가능한지 체크 (게임 오버 판정)
  bool canPlaceAnyPiece(List<BlockPiece> pieces) {
    for (final piece in pieces) {
      for (int gy = 0; gy < rows; gy++) {
        for (int gx = 0; gx < columns; gx++) {
          if (canPlacePieceAt(piece, gx, gy)) return true;
        }
      }
    }
    return false;
  }

  /// 보드가 완전히 비었는지 (퍼펙트 클리어)
  bool get isEmpty {
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < columns; x++) {
        if (grid[y][x].occupied) return false;
      }
    }
    return true;
  }

  // isTopReached() → 삭제 (10x10에서 불필요)
  // clearRows() → clearCompletedLines()로 대체
}
```

### 3.4 GameState 변경

**파일**: `lib/data/models/game_state.dart`

핵심 변경:
- `currentPiece`, `nextPiece`, `heldPiece` → `trayPieces` (3개 블록 리스트)
- `dropSpeed`, `canHold` 제거
- `combo` 로직은 유지 (연속 클리어 시)
- `GameMode` 단순화

```dart
enum GameStatus {
  ready,
  playing,
  paused,
  clearing,     // lineClearing → clearing (줄 + 컬러 매치)
  gameOver,
  // completed, sprint → 제거
}

enum GameMode {
  classic,        // 메인 무한 모드
  dailyChallenge, // Phase 2
  // puzzle, sprint, zen, vs → 제거
}

class GameState {
  final BoardState board;
  final List<BlockPiece> trayPieces;  // 0~3개 (신규)
  final int score;
  final int level;
  final int linesCleared;
  final int combo;
  final GameStatus status;
  final GameMode mode;
  final Duration elapsed;
  final int highScore;
  final int blocksPlaced;             // 총 배치한 블록 수 (신규)
  final int totalColorMatches;        // 총 컬러 매치 횟수 (신규)

  const GameState({
    required this.board,
    this.trayPieces = const [],
    this.score = 0,
    this.level = 1,
    this.linesCleared = 0,
    this.combo = 0,
    this.status = GameStatus.ready,
    this.mode = GameMode.classic,
    this.elapsed = Duration.zero,
    this.highScore = 0,
    this.blocksPlaced = 0,
    this.totalColorMatches = 0,
  });

  GameState copyWith({
    BoardState? board,
    List<BlockPiece>? trayPieces,
    int? score,
    int? level,
    int? linesCleared,
    int? combo,
    GameStatus? status,
    GameMode? mode,
    Duration? elapsed,
    int? highScore,
    int? blocksPlaced,
    int? totalColorMatches,
  }) {
    return GameState(
      board: board ?? this.board,
      trayPieces: trayPieces ?? this.trayPieces,
      score: score ?? this.score,
      level: level ?? this.level,
      linesCleared: linesCleared ?? this.linesCleared,
      combo: combo ?? this.combo,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      elapsed: elapsed ?? this.elapsed,
      highScore: highScore ?? this.highScore,
      blocksPlaced: blocksPlaced ?? this.blocksPlaced,
      totalColorMatches: totalColorMatches ?? this.totalColorMatches,
    );
  }

  /// 트레이가 비었는지 (새 블록 생성 필요)
  bool get isTrayEmpty => trayPieces.isEmpty;
}
```

### 3.5 PieceDefinitions 변경

**파일**: `lib/game/data/piece_definitions.dart`

핵심 변경:
- `spawnPiece()` → `createPiece()` (gridX/gridY 설정하지 않음)
- 회전 없이 고정 형태만 반환
- 난이도 기반 가중치는 유지하되 기존 `boardColumns` 참조 제거

```dart
class PieceDefinitions {
  PieceDefinitions._();
  static final _random = Random();

  // shapes, colorFor — 기존과 동일

  /// 랜덤 블록 3개 생성 (트레이용)
  static List<BlockPiece> generateTray(int level) {
    return List.generate(3, (_) => createRandomPiece(level));
  }

  /// 난이도 기반 랜덤 블록 1개 생성
  static BlockPiece createRandomPiece(int level) {
    final weights = _weightsForLevel(level);
    final type = _weightedRandom(weights);
    final color = colorFor(type);
    final shape = shapes[type]!;

    return BlockPiece(
      type: type,
      color: color,
      shape: shape,
      // gridX, gridY는 null (트레이 상태)
    );
  }

  // _weightsForLevel, _weightedRandom — 기존과 동일
  // 단, 스킬 블록 가중치 제거
}
```

---

## 4. Game Systems

### 4.1 PlacementSystem (CollisionSystem 대체)

**파일**: `lib/game/systems/collision_system.dart` → 이름 유지, 내용 대폭 변경

```dart
/// 블록 배치 가능성 판단 시스템
class PlacementSystem {
  PlacementSystem._();

  /// 블록을 (gx, gy) 위치에 배치 가능한지
  static bool canPlace(BoardState board, BlockPiece piece, int gx, int gy) {
    return board.canPlacePieceAt(piece, gx, gy);
  }

  /// 드래그 중 스크린 좌표 → 그리드 좌표 변환
  /// boardOrigin: 보드 좌상단 스크린 좌표
  /// cellSize: 셀 하나의 픽셀 크기
  /// piece: 드래그 중인 블록
  /// screenPos: 현재 터치 위치 (블록 중심)
  static (int gx, int gy)? screenToGrid({
    required Offset boardOrigin,
    required double cellSize,
    required BlockPiece piece,
    required Offset screenPos,
  }) {
    // 블록의 중심을 기준으로 그리드 좌표 계산
    final relX = screenPos.dx - boardOrigin.dx;
    final relY = screenPos.dy - boardOrigin.dy;

    // 블록의 왼쪽 상단 기준 그리드 위치
    final gx = ((relX - (piece.width * cellSize / 2)) / cellSize).round();
    final gy = ((relY - (piece.height * cellSize / 2)) / cellSize).round();

    return (gx, gy);
  }

  // canMove, canRotate, getGhostY → 삭제
}
```

### 4.2 ClearSystem (LineClearSystem 확장)

**파일**: `lib/game/systems/line_clear_system.dart`

```dart
/// 줄 클리어 결과
class ClearResult {
  final BoardState newBoard;
  final int linesCleared;         // 가로 + 세로 합계
  final List<int> clearedRows;    // 클리어된 가로줄 인덱스
  final List<int> clearedColumns; // 클리어된 세로줄 인덱스
  final bool isPerfectClear;     // 보드 완전 비움

  const ClearResult({
    required this.newBoard,
    this.linesCleared = 0,
    this.clearedRows = const [],
    this.clearedColumns = const [],
    this.isPerfectClear = false,
  });
}

class ClearSystem {
  ClearSystem._();

  /// 블록 배치 후 줄 클리어 체크
  static ClearResult checkAndClear(BoardState board) {
    final completedRows = board.getCompletedRows();
    final completedCols = board.getCompletedColumns();

    if (completedRows.isEmpty && completedCols.isEmpty) {
      return ClearResult(newBoard: board);
    }

    final (newBoard, totalLines) = board.clearCompletedLines();

    return ClearResult(
      newBoard: newBoard,
      linesCleared: totalLines,
      clearedRows: completedRows,
      clearedColumns: completedCols,
      isPerfectClear: newBoard.isEmpty,
    );
  }
}
```

### 4.3 ColorMatchSystem (기존 BoardState 로직 시스템으로 분리)

**파일**: `lib/game/systems/line_clear_system.dart` 내에 통합 또는 별도 파일

```dart
/// 컬러 매치 결과
class ColorMatchResult {
  final BoardState newBoard;
  final List<List<(int, int)>> matchGroups; // 매치된 셀 그룹들
  final int totalCellsRemoved;

  const ColorMatchResult({
    required this.newBoard,
    this.matchGroups = const [],
    this.totalCellsRemoved = 0,
  });
}

/// 줄 클리어 후 컬러 매치 체크
/// ClearSystem과 순서: 배치 → 줄 클리어 → 컬러 매치
static ColorMatchResult checkColorMatch(BoardState board) {
  final matches = board.findColorMatches();
  if (matches.isEmpty) {
    return ColorMatchResult(newBoard: board);
  }

  // 모든 매치 그룹의 셀을 합침
  final allCells = <(int, int)>{};
  for (final group in matches) {
    allCells.addAll(group);
  }

  final newBoard = board.removeCells(allCells.toList());
  return ColorMatchResult(
    newBoard: newBoard,
    matchGroups: matches,
    totalCellsRemoved: allCells.length,
  );
}
```

### 4.4 ScoringSystem 변경

**파일**: `lib/game/systems/scoring_system.dart`

```dart
/// 배치 결과 종합 점수 계산
class ScoreResult {
  final int placementScore;    // 블록 배치 기본 점수
  final int lineClearScore;    // 줄 클리어 점수
  final int colorMatchScore;   // 컬러 매치 점수
  final int perfectClearScore; // 퍼펙트 클리어 보너스
  final double comboMultiplier;
  final int totalScore;

  const ScoreResult({
    this.placementScore = 0,
    this.lineClearScore = 0,
    this.colorMatchScore = 0,
    this.perfectClearScore = 0,
    this.comboMultiplier = 1.0,
    this.totalScore = 0,
  });
}

class ScoringSystem {
  ScoringSystem._();

  static ScoreResult calculate({
    required int cellCount,          // 배치된 블록의 셀 수
    required ClearResult clearResult,
    required ColorMatchResult colorResult,
    required int combo,
    required int level,
  }) {
    // 1. 배치 점수
    final placement = cellCount * GameConstants.placementPointsPerCell;

    // 2. 줄 클리어 점수
    final lineClear = GameConstants.lineClearScore(clearResult.linesCleared);

    // 3. 컬러 매치 점수
    int colorMatch = 0;
    for (final group in colorResult.matchGroups) {
      colorMatch += GameConstants.colorMatchScore(group.length);
    }

    // 4. 퍼펙트 클리어
    final perfectClear = clearResult.isPerfectClear
        ? GameConstants.perfectClearBonus
        : 0;

    // 5. 콤보 배율
    final comboIdx = combo.clamp(0, GameConstants.comboMultipliers.length - 1);
    final multiplier = GameConstants.comboMultipliers[comboIdx];

    // 6. 총점 (배치 점수는 콤보 배율 미적용)
    final bonusScore = ((lineClear + colorMatch + perfectClear) * multiplier).round();
    final total = placement + bonusScore;

    return ScoreResult(
      placementScore: placement,
      lineClearScore: lineClear,
      colorMatchScore: colorMatch,
      perfectClearScore: perfectClear,
      comboMultiplier: multiplier,
      totalScore: total,
    );
  }
}
```

### 4.5 GameOverSystem (신규)

**파일**: `lib/game/systems/game_over_system.dart`

```dart
/// 게임 오버 판정 시스템
class GameOverSystem {
  GameOverSystem._();

  /// 트레이의 모든 블록이 배치 불가능하면 게임 오버
  static bool isGameOver(BoardState board, List<BlockPiece> trayPieces) {
    if (trayPieces.isEmpty) return false;
    return !board.canPlaceAnyPiece(trayPieces);
  }
}
```

### 4.6 DifficultySystem (신규)

**파일**: `lib/game/systems/difficulty_system.dart`

```dart
/// 난이도 프로그레션 시스템
class DifficultySystem {
  DifficultySystem._();

  /// 현재 레벨 계산 (클리어한 줄 수 기반)
  static int calculateLevel(int totalLinesCleared) {
    int level = 1;
    int linesNeeded = GameConstants.linesForNextLevel(level);
    int remaining = totalLinesCleared;

    while (remaining >= linesNeeded) {
      remaining -= linesNeeded;
      level++;
      linesNeeded = GameConstants.linesForNextLevel(level);
    }

    return level;
  }

  /// 레벨업 여부 체크
  static bool shouldLevelUp(int currentLevel, int totalLinesCleared) {
    return calculateLevel(totalLinesCleared) > currentLevel;
  }
}
```

---

## 5. UI/UX Design

### 5.1 Screen Layout — GameScreen

```
┌─────────────────────────────────┐
│  StatusBar (투명)                │
├─────────────────────────────────┤
│                                 │
│  ┌─ HUD ──────────────────────┐ │
│  │ [≡]  SCORE: 12,450  Lv.3  │ │
│  │       BEST: 28,900        │ │
│  │       COMBO: x1.5         │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌─ Board (10x10) ───────────┐ │
│  │ ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐   │ │
│  │ │ │ │ │ │ │ │ │ │ │ │   │ │
│  │ ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤   │ │
│  │ │ │ │ │█│█│ │ │ │ │ │   │ │
│  │ ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤   │ │
│  │ │ │ │ │█│ │ │ │ │ │ │   │ │
│  │ ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤   │ │
│  │ │ │ │ │ │ │ │ │ │ │ │   │ │
│  │ │        ...              │ │
│  │ ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤   │ │
│  │ │ │ │ │ │ │ │ │ │ │ │   │ │
│  │ └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘   │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌─ Piece Tray ───────────────┐ │
│  │ ┌──────┐ ┌──────┐ ┌──────┐│ │
│  │ │ ██   │ │ ████ │ │  █   ││ │
│  │ │ ██   │ │      │ │ ███  ││ │
│  │ └──────┘ └──────┘ └──────┘│ │
│  └────────────────────────────┘ │
│                                 │
│  (광고 배너 — Phase 2)          │
│                                 │
└─────────────────────────────────┘
```

### 5.2 게임 화면 치수 계산

```
화면 폭: screenWidth
보드 폭: screenWidth - 2 * horizontalPadding (padding=16)
셀 크기: boardWidth / 10
보드 높이: cellSize * 10 (정사각형)

전체 레이아웃 (세로):
- StatusBar: ~44px
- HUD: ~80px
- Board: cellSize * 10
- 간격: 16px
- Piece Tray: ~cellSize * 3 (가장 큰 블록 높이 + 여백)
- 하단 여백: 16px + SafeArea

예시 (iPhone 15, 393x852):
- boardWidth = 393 - 32 = 361
- cellSize = 361 / 10 ≈ 36px
- boardHeight = 36 * 10 = 360px
- trayHeight ≈ 100px
- 총 필요 높이: 44 + 80 + 360 + 16 + 100 + 32 = 632px (여유 충분)
```

### 5.3 드래그 & 드롭 UX 상세

```
1. [터치 시작] → Tray에서 블록 터치
   - 블록이 약간 확대 (1.1x) + 그림자 효과
   - 햅틱: light

2. [드래그 중]
   - 블록이 터치 위치 위로 오프셋 (손가락에 가려지지 않도록, -cellSize * 2)
   - 그리드 위 hover 시:
     - 배치 가능: 해당 위치에 반투명 녹색 하이라이트
     - 배치 불가: 해당 위치에 반투명 빨간색 하이라이트
   - 그리드 밖: 하이라이트 없음

3. [드롭 — 배치 가능]
   - 블록이 그리드에 스냅 (0.15초 ease-out)
   - 즉시 줄 클리어 + 컬러 매치 체크
   - 햅틱: medium
   - 사운드: piece_land

4. [드롭 — 배치 불가 / 그리드 밖]
   - 블록이 트레이 원위치로 돌아감 (0.2초 spring 애니메이션)
   - 햅틱: 없음
```

### 5.4 애니메이션 명세

| 애니메이션 | 시간 | 이징 | 상세 |
|-----------|------|------|------|
| 블록 배치 스냅 | 0.15s | easeOut | 드롭 위치로 부드럽게 이동 |
| 블록 원위치 복귀 | 0.2s | spring | 트레이로 돌아감 |
| 줄 클리어 | 0.3s | linear | 행/열 전체가 밝게 플래시 → 사라짐 |
| 컬러 매치 폭발 | 0.4s | easeOut | 매치된 셀들이 확대 → 파티클 흩어짐 → 사라짐 |
| 점수 팝업 | 0.8s | easeOut | 클리어 위치에서 위로 떠오르며 페이드 |
| 콤보 텍스트 | 0.6s | elasticOut | "COMBO x2!" 확대 + 바운스 |
| 퍼펙트 클리어 | 1.2s | easeInOut | 보드 전체 빛 효과 + "PERFECT!" 텍스트 |
| 트레이 새 블록 | 0.3s | easeOut | 아래에서 위로 슬라이드 인 |
| 게임 오버 쉐이크 | 0.5s | — | 보드 좌우 진동 |

### 5.5 Component List

| 컴포넌트 | 파일 경로 | 역할 |
|---------|----------|------|
| BoardComponent | `game/components/board_component.dart` | 10x10 그리드 렌더링 (수정) |
| PieceTrayComponent | `game/components/piece_tray_component.dart` | 3개 블록 표시 + 드래그 시작 (신규) |
| DragPreviewComponent | `game/components/drag_preview_component.dart` | 드래그 중 블록 프리뷰 (신규) |
| GridHighlightComponent | `game/components/grid_highlight_component.dart` | 배치 가능/불가 위치 하이라이트 (신규) |
| ScorePopupComponent | `game/components/score_popup_component.dart` | 점수 팝업 (신규) |
| ClearEffectComponent | `game/components/clear_effect_component.dart` | 클리어/폭발 이펙트 (신규) |

---

## 6. Main Game Engine

### 6.1 ChromaBlocksGame

**파일**: `lib/game/chroma_blocks_game.dart`

```dart
/// 메인 Flame 게임 클래스
class ChromaBlocksGame extends FlameGame with DragCallbacks, TapCallbacks {

  // ── 콜백 (Flutter UI 레이어와 통신) ──
  final Function(GameState) onStateChanged;
  final VoidCallback onGameOver;

  // ── State ──
  late GameState _state;
  GameState get state => _state;

  // ── Components ──
  late BoardComponent _boardComponent;
  late PieceTrayComponent _pieceTrayComponent;
  DragPreviewComponent? _dragPreview;
  GridHighlightComponent? _gridHighlight;

  // ── Board layout (onGameResize에서 계산) ──
  double _cellSize = 0;
  Offset _boardOrigin = Offset.zero;
  Offset _trayOrigin = Offset.zero;

  // ── Drag state ──
  BlockPiece? _draggingPiece;
  int? _draggingIndex; // trayPieces에서의 인덱스

  @override
  Future<void> onLoad() async {
    _state = GameState(board: BoardState());
    _boardComponent = BoardComponent(...);
    _pieceTrayComponent = PieceTrayComponent(...);
    add(_boardComponent);
    add(_pieceTrayComponent);
  }

  // ── Public API ──

  void startGame() {
    final tray = PieceDefinitions.generateTray(_state.level);
    _state = _state.copyWith(
      status: GameStatus.playing,
      trayPieces: tray,
    );
    onStateChanged(_state);
  }

  void pauseGame() { ... }
  void resumeGame() { ... }

  // ── Drag & Drop ──

  @override
  void onDragStart(DragStartEvent event) {
    // PieceTrayComponent 영역 체크
    // 터치된 블록 식별 → _draggingPiece, _draggingIndex 설정
    // DragPreviewComponent 생성 & add
    // GridHighlightComponent 생성 & add
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // DragPreview 위치 업데이트
    // 그리드 위 hover 시 → PlacementSystem.screenToGrid()
    // → GridHighlight 업데이트 (가능/불가 색상)
  }

  @override
  void onDragEnd(DragEndEvent event) {
    // 그리드 위에서 놓았는지 체크
    // canPlace → _placePiece()
    // cannotPlace → 블록 원위치 복귀 애니메이션
    // DragPreview, GridHighlight 제거
  }

  // ── Core Game Logic ──

  void _placePiece(BlockPiece piece, int gx, int gy, int trayIndex) {
    final placed = piece.copyWith(gridX: gx, gridY: gy);

    // 1. 보드에 배치
    var board = _state.board.placePiece(placed);

    // 2. 줄 클리어 체크
    final clearResult = ClearSystem.checkAndClear(board);
    board = clearResult.newBoard;

    // 3. 컬러 매치 체크 (줄 클리어 후 보드에서)
    final colorResult = checkColorMatch(board);
    board = colorResult.newBoard;

    // 4. 점수 계산
    final didClear = clearResult.linesCleared > 0 || colorResult.totalCellsRemoved > 0;
    final newCombo = didClear ? _state.combo + 1 : 0;

    final scoreResult = ScoringSystem.calculate(
      cellCount: placed.occupiedCells.length,
      clearResult: clearResult,
      colorResult: colorResult,
      combo: newCombo,
      level: _state.level,
    );

    // 5. 트레이에서 블록 제거
    final newTray = List<BlockPiece>.from(_state.trayPieces)
      ..removeAt(trayIndex);

    // 6. 레벨 업 체크
    final totalLines = _state.linesCleared + clearResult.linesCleared;
    final newLevel = DifficultySystem.calculateLevel(totalLines);

    // 7. 상태 업데이트
    _state = _state.copyWith(
      board: board,
      trayPieces: newTray,
      score: _state.score + scoreResult.totalScore,
      linesCleared: totalLines,
      combo: newCombo,
      level: newLevel,
      blocksPlaced: _state.blocksPlaced + 1,
      totalColorMatches: _state.totalColorMatches + colorResult.matchGroups.length,
    );

    // 8. 애니메이션 트리거
    if (clearResult.linesCleared > 0) { /* 줄 클리어 애니메이션 */ }
    if (colorResult.matchGroups.isNotEmpty) { /* 컬러 매치 폭발 애니메이션 */ }
    if (scoreResult.totalScore > 0) { /* 점수 팝업 */ }
    if (clearResult.isPerfectClear) { /* 퍼펙트 클리어 이펙트 */ }

    // 9. 사운드 & 햅틱
    SoundUtil.playPieceLand();
    HapticUtil.pieceLand();
    if (clearResult.linesCleared > 0) {
      SoundUtil.playLineClear(clearResult.linesCleared);
      HapticUtil.lineClear(clearResult.linesCleared);
    }
    if (colorResult.matchGroups.isNotEmpty) {
      SoundUtil.playColorMatch();
      HapticUtil.colorMatch();
    }
    if (newLevel > _state.level) {
      SoundUtil.playLevelUp();
    }

    // 10. 트레이 비었으면 새 블록 생성
    if (newTray.isEmpty) {
      _refillTray();
    } else {
      // 11. 게임 오버 체크
      _checkGameOver();
    }

    onStateChanged(_state);
  }

  void _refillTray() {
    final newTray = PieceDefinitions.generateTray(_state.level);
    _state = _state.copyWith(trayPieces: newTray);

    // 트레이 채운 후 게임 오버 체크
    _checkGameOver();
  }

  void _checkGameOver() {
    if (GameOverSystem.isGameOver(_state.board, _state.trayPieces)) {
      _state = _state.copyWith(status: GameStatus.gameOver);
      SoundUtil.playGameOver();
      HapticUtil.gameOver();
      onGameOver();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_state.status == GameStatus.playing) {
      _state = _state.copyWith(
        elapsed: _state.elapsed + Duration(milliseconds: (dt * 1000).round()),
      );
    }
  }
}
```

---

## 7. Flame Components 상세

### 7.1 BoardComponent (수정)

**파일**: `lib/game/components/board_component.dart`

변경 사항:
- `visibleRows` 참조 제거 → `board.rows` (10) 사용
- 버퍼 행 오프셋 로직 제거
- 기존 `_drawOccupiedCell` (Luminous Flow 4-layer) 그대로 유지
- 줄 클리어 애니메이션에서 세로줄도 지원

```dart
class BoardComponent extends PositionComponent {
  BoardState board;
  // cellSize, boardOrigin은 부모(Game)에서 설정

  @override
  void render(Canvas canvas) {
    _drawBackground(canvas);
    _drawGrid(canvas);        // 10x10 그리드 라인
    _drawOccupiedCells(canvas); // Luminous Flow 4-layer
    _drawClearFlash(canvas);  // 가로 + 세로 클리어 플래시
    _drawBorder(canvas);      // 보드 테두리 + 글로우
  }
}
```

### 7.2 PieceTrayComponent (신규)

**파일**: `lib/game/components/piece_tray_component.dart`

```dart
/// 3개 블록을 가로로 배치하는 트레이
class PieceTrayComponent extends PositionComponent {
  List<BlockPiece> pieces;
  double cellSize;   // 트레이의 셀 크기 (보드 셀보다 약간 작음, 0.8배)
  Set<int> draggingIndices; // 현재 드래그 중인 블록 인덱스 (숨김 처리)

  @override
  void render(Canvas canvas) {
    // 배경 (다크 카드 + 라운드 코너)
    _drawBackground(canvas);

    // 각 블록을 균등 간격으로 배치
    final slotWidth = size.x / 3;
    for (int i = 0; i < pieces.length; i++) {
      if (draggingIndices.contains(i)) continue; // 드래그 중이면 숨김

      final piece = pieces[i];
      final slotCenter = Offset(slotWidth * i + slotWidth / 2, size.y / 2);

      // 블록을 슬롯 중앙에 배치
      _drawPiece(canvas, piece, slotCenter);
    }
  }

  void _drawPiece(Canvas canvas, BlockPiece piece, Offset center) {
    final pw = piece.width * cellSize;
    final ph = piece.height * cellSize;
    final origin = Offset(center.dx - pw / 2, center.dy - ph / 2);

    for (int row = 0; row < piece.shape.length; row++) {
      for (int col = 0; col < piece.shape[row].length; col++) {
        if (piece.shape[row][col] == 1) {
          final rect = Rect.fromLTWH(
            origin.dx + col * cellSize,
            origin.dy + row * cellSize,
            cellSize,
            cellSize,
          );
          // Luminous Flow 4-layer 렌더링 (BoardComponent와 동일)
          _drawLuminousCell(canvas, rect, piece.color);
        }
      }
    }
  }

  /// 터치 좌표가 어떤 블록 슬롯에 해당하는지 반환
  int? hitTestPiece(Offset localPos) {
    final slotWidth = size.x / 3;
    for (int i = 0; i < pieces.length; i++) {
      final slotRect = Rect.fromLTWH(slotWidth * i, 0, slotWidth, size.y);
      if (slotRect.contains(localPos)) return i;
    }
    return null;
  }
}
```

### 7.3 DragPreviewComponent (신규)

**파일**: `lib/game/components/drag_preview_component.dart`

```dart
/// 드래그 중 터치 위치를 따라다니는 반투명 블록
class DragPreviewComponent extends PositionComponent {
  final BlockPiece piece;
  final double cellSize;
  double opacity;       // 0.7 (기본)
  Offset fingerOffset;  // 손가락 위 오프셋 (-cellSize * 2)

  @override
  void render(Canvas canvas) {
    for (int row = 0; row < piece.shape.length; row++) {
      for (int col = 0; col < piece.shape[row].length; col++) {
        if (piece.shape[row][col] == 1) {
          final rect = Rect.fromLTWH(
            col * cellSize,
            row * cellSize,
            cellSize,
            cellSize,
          );
          // 반투명 Luminous Flow 렌더링
          _drawLuminousCellWithOpacity(canvas, rect, piece.color, opacity);
        }
      }
    }
  }

  void updatePosition(Offset screenPos) {
    position = Vector2(
      screenPos.dx - (piece.width * cellSize / 2),
      screenPos.dy - (piece.height * cellSize / 2) + fingerOffset.dy,
    );
  }
}
```

### 7.4 GridHighlightComponent (신규)

**파일**: `lib/game/components/grid_highlight_component.dart`

```dart
/// 드래그 중 그리드에 배치 가능/불가를 표시하는 하이라이트
class GridHighlightComponent extends PositionComponent {
  final double cellSize;
  List<(int x, int y)> highlightCells;
  bool canPlace;  // true: 녹색, false: 빨간색

  static const Color _canPlaceColor = Color(0x4000FF00);   // 반투명 녹색
  static const Color _cannotPlaceColor = Color(0x40FF0000); // 반투명 빨간색

  @override
  void render(Canvas canvas) {
    final color = canPlace ? _canPlaceColor : _cannotPlaceColor;
    final paint = Paint()..color = color;

    for (final (x, y) in highlightCells) {
      final rect = Rect.fromLTWH(
        x * cellSize,
        y * cellSize,
        cellSize,
        cellSize,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(2)),
        paint,
      );
    }
  }

  void updateHighlight(BlockPiece piece, int gx, int gy, bool placeable) {
    highlightCells = piece.occupiedCellsAt(gx, gy);
    canPlace = placeable;
  }

  void clear() {
    highlightCells = [];
  }
}
```

### 7.5 ScorePopupComponent (신규)

**파일**: `lib/game/components/score_popup_component.dart`

```dart
/// 점수 획득 시 위로 떠오르는 팝업 텍스트
class ScorePopupComponent extends PositionComponent with HasGameRef {
  final String text;        // "+300" 또는 "COMBO x2!"
  final Color color;
  double _elapsed = 0;
  static const double _duration = 0.8;

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
      return;
    }
    // 위로 떠오르기
    position.y -= dt * 60;
  }

  @override
  void render(Canvas canvas) {
    final opacity = 1.0 - (_elapsed / _duration);
    final textPaint = TextPaint(
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color.withOpacity(opacity),
        shadows: [Shadow(color: color.withOpacity(opacity * 0.5), blurRadius: 8)],
      ),
    );
    textPaint.render(canvas, text, Vector2.zero());
  }
}
```

### 7.6 ClearEffectComponent (신규)

**파일**: `lib/game/components/clear_effect_component.dart`

```dart
/// 줄 클리어 + 컬러 매치 폭발 이펙트
class ClearEffectComponent extends PositionComponent {
  final List<(int x, int y)> cells;
  final Color effectColor;
  final ClearEffectType type; // line, colorMatch

  double _elapsed = 0;

  @override
  void update(double dt) {
    _elapsed += dt;
    final duration = type == ClearEffectType.line ? 0.3 : 0.4;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // type에 따라:
    // line: 플래시 (흰색 → 투명)
    // colorMatch: 셀 확대 + 파티클 흩어짐
  }
}

enum ClearEffectType { line, colorMatch }
```

---

## 8. Screen Layer 변경

### 8.1 GameScreen 변경

**파일**: `lib/screens/game/game_screen.dart`

핵심 변경:
- `BlockDropGame` → `ChromaBlocksGame`
- HUD 레이아웃 변경 (NEXT/HOLD 제거, COMBO 추가)
- 하단 영역을 PieceTray가 Flame 내에서 처리하므로 Flutter 위젯 불필요
- START GAME 버튼은 유지

```dart
class GameScreen extends StatefulWidget { ... }

class _GameScreenState extends State<GameScreen> {
  late ChromaBlocksGame _game;
  GameState? _currentState;

  @override
  void initState() {
    super.initState();
    final highScore = gameRepository.getHighScore();

    _game = ChromaBlocksGame(
      onStateChanged: (state) {
        setState(() => _currentState = state);
      },
      onGameOver: () {
        gameRepository.saveHighScore(_currentState!.score);
        _game.overlays.add('GameOver');
      },
    );
    _currentState = _game.state;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHud(),       // Score, Level, Combo
            Expanded(
              child: GameWidget(
                game: _game,
                overlayBuilderMap: {
                  'Pause': (ctx, game) => PauseOverlay(...),
                  'GameOver': (ctx, game) => GameOverOverlay(...),
                },
              ),
            ),
            // Piece Tray는 Flame 내부에서 렌더링
            // 하단 여백만 SafeArea로 처리
          ],
        ),
      ),
    );
  }

  Widget _buildHud() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 일시정지 버튼
          IconButton(
            icon: const Icon(Icons.pause, color: AppColors.textLight),
            onPressed: () { _game.pauseGame(); _game.overlays.add('Pause'); },
          ),
          const Spacer(),
          // 점수
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('SCORE', style: ...),
              Text('${_currentState?.score ?? 0}', style: ...),
            ],
          ),
          const SizedBox(width: 16),
          // 레벨
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('LEVEL', style: ...),
              Text('${_currentState?.level ?? 1}', style: ...),
            ],
          ),
        ],
      ),
    );
  }
}
```

### 8.2 HomeScreen 변경

**파일**: `lib/screens/home/home_screen.dart`

변경 사항:
- 게임 이름: "BlockDrop" → "ChromaBlocks"
- 게임 모드 카드: Classic만 유지 (Phase 1)
- Daily Challenge 카드는 "Coming Soon" 뱃지 표시

### 8.3 Overlay 변경

- `game_over_overlay.dart`: "GAME OVER" 텍스트 유지, 통계에 "Blocks Placed", "Color Matches" 추가
- `pause_overlay.dart`: 텍스트만 변경, 나머지 유지

### 8.4 main.dart 변경

```dart
// title: 'BlockDrop' → 'ChromaBlocks'
// 나머지 동일
```

---

## 9. Sound & Haptic 변경

### 9.1 SoundUtil 추가 이벤트

```dart
// 기존 유지:
// playPieceLand, playLineClear(n), playColorMatch, playCombo,
// playLevelUp, playGameOver, playMenuTap

// 추가:
static Future<void> playBlockPickup() => _play('sfx/block_pickup.ogg');
static Future<void> playBlockReturn() => _play('sfx/block_return.ogg');
static Future<void> playPerfectClear() => _play('sfx/perfect_clear.ogg');

// 제거:
// playPieceMove, playPieceRotate, playHardDrop → 해당 없음
```

### 9.2 HapticUtil 추가 이벤트

```dart
// 기존 유지:
// pieceLand (→ blockPlace로 rename), lineClear, combo, colorMatch, gameOver

// 추가:
static Future<void> blockPickup() => _light();
static Future<void> blockPlace() => _medium();   // 기존 pieceLand
static Future<void> perfectClear() => _heavy();
static Future<void> invalidPlacement() => _light(); // 짧은 진동

// 제거:
// pieceMove, pieceRotate, hardDrop → 해당 없음
```

---

## 10. Error Handling

### 10.1 드래그 & 드롭 에지 케이스

| 상황 | 처리 |
|------|------|
| 드래그 중 화면 밖으로 나감 | `onDragCancel` → 블록 원위치 복귀 |
| 동시에 두 손가락 드래그 | 첫 번째 드래그만 처리, 두 번째 무시 |
| 드래그 중 앱 백그라운드 | 자동 일시정지, 블록 원위치 복귀 |
| 빈 트레이 슬롯 터치 | 무시 (hitTest null) |
| 극히 빠른 드래그 & 드롭 | 애니메이션 큐잉으로 처리 |
| 줄 클리어 애니메이션 중 터치 | 입력 무시 (status == clearing) |

### 10.2 상태 일관성

| 위험 | 대응 |
|------|------|
| 트레이에서 블록 제거 후 인덱스 불일치 | 즉시 리스트 복사 후 removeAt |
| 줄 클리어 + 컬러 매치 동시 발생 | 순차 처리 (줄 먼저 → 컬러) |
| 게임 오버 판정 타이밍 | 새 트레이 생성 후 즉시 체크 |

---

## 11. Test Plan

### 11.1 수동 테스트 (Zero Script QA)

| # | 시나리오 | 기대 결과 |
|---|---------|----------|
| 1 | 트레이에서 블록 드래그 시작 | 블록 확대 + 프리뷰 표시 |
| 2 | 빈 그리드에 블록 드래그 & 드롭 | 배치 성공, 점수 +N |
| 3 | 점유된 셀 위에 드롭 | 블록 원위치 복귀 |
| 4 | 가로줄 완성 | 줄 클리어 애니메이션 + 점수 |
| 5 | 세로줄 완성 | 줄 클리어 애니메이션 + 점수 |
| 6 | 가로 + 세로 동시 완성 | 양쪽 모두 클리어 + 높은 점수 |
| 7 | 5개 동색 인접 | 컬러 매치 폭발 + 보너스 점수 |
| 8 | 연속 클리어 | 콤보 배율 적용 |
| 9 | 보드 완전 비움 | 퍼펙트 클리어 보너스 2000점 |
| 10 | 트레이 3개 모두 사용 | 새 블록 3개 생성 |
| 11 | 배치 불가능 → 게임 오버 | 게임 오버 오버레이 표시 |
| 12 | 게임 오버 → Retry | 초기 상태로 리셋 |
| 13 | 일시정지 → 재개 | 상태 유지 |
| 14 | 드래그 중 화면 밖 | 블록 원위치 복귀 |
| 15 | 30분 연속 플레이 | 크래시/메모리 누수 없음 |
| 16 | 레벨 업 | 블록 복잡도 증가 확인 |

---

## 12. Implementation Order

### Phase 1: Core Data & Logic (Step 1-4)

1. **[Step 1] GameConstants 수정**
   - 파일: `lib/core/constants/game_constants.dart`
   - 10x10 상수, 새 점수 테이블, 중력 관련 삭제
   - 의존: 없음

2. **[Step 2] BlockPiece 수정**
   - 파일: `lib/data/models/block_piece.dart`
   - 회전 제거, `occupiedCellsAt()` 추가
   - 의존: Step 1

3. **[Step 3] BoardState 수정**
   - 파일: `lib/data/models/board_state.dart`
   - 10x10 기본값, `getCompletedColumns()`, `clearCompletedLines()`, `canPlaceAnyPiece()`, `isEmpty`
   - 의존: Step 1, Step 2

4. **[Step 4] GameState 수정**
   - 파일: `lib/data/models/game_state.dart`
   - `trayPieces`, 새 필드, `GameStatus`/`GameMode` 정리
   - 의존: Step 2, Step 3

### Phase 2: Game Systems (Step 5-9)

5. **[Step 5] PlacementSystem (CollisionSystem 대체)**
   - 파일: `lib/game/systems/collision_system.dart`
   - `canPlace`, `screenToGrid`
   - 의존: Step 3

6. **[Step 6] ClearSystem (LineClearSystem 확장)**
   - 파일: `lib/game/systems/line_clear_system.dart`
   - 가로 + 세로 클리어, 컬러 매치 통합
   - 의존: Step 3

7. **[Step 7] ScoringSystem 수정**
   - 파일: `lib/game/systems/scoring_system.dart`
   - 새 점수 계산
   - 의존: Step 1, Step 6

8. **[Step 8] GameOverSystem (신규)**
   - 파일: `lib/game/systems/game_over_system.dart`
   - 의존: Step 3

9. **[Step 9] DifficultySystem (신규)**
   - 파일: `lib/game/systems/difficulty_system.dart`
   - PieceDefinitions 가중치 조정
   - 의존: Step 1

### Phase 3: Flame Components (Step 10-14)

10. **[Step 10] BoardComponent 수정**
    - 파일: `lib/game/components/board_component.dart`
    - 10x10 렌더링, 세로줄 클리어 애니메이션
    - 의존: Step 3

11. **[Step 11] PieceTrayComponent (신규)**
    - 파일: `lib/game/components/piece_tray_component.dart`
    - 의존: Step 2, Step 10

12. **[Step 12] DragPreviewComponent (신규)**
    - 파일: `lib/game/components/drag_preview_component.dart`
    - 의존: Step 2

13. **[Step 13] GridHighlightComponent (신규)**
    - 파일: `lib/game/components/grid_highlight_component.dart`
    - 의존: Step 5

14. **[Step 14] ScorePopupComponent + ClearEffectComponent (신규)**
    - 파일: `lib/game/components/score_popup_component.dart`, `clear_effect_component.dart`
    - 의존: Step 6, Step 7

### Phase 4: Main Game Engine (Step 15)

15. **[Step 15] ChromaBlocksGame (신규)**
    - 파일: `lib/game/chroma_blocks_game.dart`
    - 기존 `blockdrop_game.dart` 삭제
    - 기존 `gravity_system.dart` 삭제
    - 기존 `ghost_piece_component.dart`, `next_piece_preview.dart`, `hold_piece_display.dart` 삭제
    - 의존: Step 4-14 전부

### Phase 5: Screen & UI (Step 16-18)

16. **[Step 16] GameScreen 수정**
    - 파일: `lib/screens/game/game_screen.dart`
    - HUD, GameWidget 연결
    - 의존: Step 15

17. **[Step 17] HomeScreen 수정**
    - 파일: `lib/screens/home/home_screen.dart`
    - 게임 이름, 모드 카드
    - 의존: 없음 (독립)

18. **[Step 18] Overlays 수정 + main.dart**
    - 파일: `lib/screens/game/overlays/*.dart`, `lib/main.dart`
    - 텍스트 변경, 통계 추가
    - 의존: Step 16

### Phase 6: Polish (Step 19-20)

19. **[Step 19] Sound & Haptic 업데이트**
    - 파일: `lib/core/utils/sound_util.dart`, `haptic_util.dart`
    - 의존: Step 15

20. **[Step 20] PieceDefinitions 가중치 최종 조정**
    - 파일: `lib/game/data/piece_definitions.dart`
    - 의존: Step 9, Step 15

---

## 13. Coding Convention

### 13.1 Dart/Flutter 기존 컨벤션 유지

| 대상 | 규칙 |
|------|------|
| 클래스 | PascalCase: `ChromaBlocksGame`, `PieceTrayComponent` |
| 메서드/변수 | camelCase: `canPlaceAnyPiece()`, `_draggingPiece` |
| 상수 | camelCase (Dart 관례): `boardColumns`, `lineClearPoints` |
| 파일 | snake_case: `chroma_blocks_game.dart`, `piece_tray_component.dart` |
| private | `_` 접두사: `_state`, `_placePiece()` |
| 패키지 import | `package:blockdrop/` (패키지명은 아직 변경 안 함) |

### 13.2 이 기능의 컨벤션

| 항목 | 적용 컨벤션 |
|------|------------|
| 컴포넌트 네이밍 | `{기능}Component` (PieceTrayComponent, DragPreviewComponent) |
| 시스템 네이밍 | `{기능}System` (PlacementSystem, ClearSystem) |
| 결과 객체 | `{기능}Result` (ClearResult, ColorMatchResult, ScoreResult) |
| 상태 업데이트 | 불변 `copyWith` 패턴 |
| 에러 처리 | 사운드/햅틱은 fire-and-forget, 로직은 null 체크 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-10 | Initial draft — 전체 기술 설계 | AI-Assisted |
| 0.2 | 2026-02-10 | 그리드 크기 8x8 → 10x10 변경 | AI-Assisted |
