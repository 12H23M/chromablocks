# Design: BlockDrop - 블록 퍼즐 모바일 게임

> **Feature**: tetris-mobile-app
> **Plan Reference**: [tetris-mobile-app.plan.md](../../01-plan/features/tetris-mobile-app.plan.md)
> **Created**: 2026-02-08
> **Phase**: Design
> **Status**: Draft

---

## 1. 아키텍처 개요

### 1.1 시스템 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                        BlockDrop App                            │
├─────────────┬──────────────┬────────────────┬──────────────────┤
│   UI Layer  │  Game Layer  │ Service Layer  │  Data Layer      │
│  (Flutter)  │   (Flame)    │  (Providers)   │ (Repository)     │
├─────────────┼──────────────┼────────────────┼──────────────────┤
│ Screens     │ GameEngine   │ AuthService    │ LocalStorage     │
│ Widgets     │ Components   │ AdService      │ (Hive)           │
│ Navigation  │ Systems      │ IAPService     │                  │
│ Themes      │ Effects      │ AudioService   │ RemoteStorage    │
│ Dialogs     │ Input        │ AnalyticsServ  │ (Firestore)      │
│ Overlays    │ Physics      │ RemoteConfig   │                  │
│             │              │ SocialService  │ RealtimeDB       │
│             │              │ PushService    │ (RTDB)           │
└─────────────┴──────────────┴────────────────┴──────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │  State Management │
                    │    (Riverpod)     │
                    └───────────────────┘
```

### 1.2 레이어별 책임

| 레이어 | 책임 | 주요 패키지 |
|--------|------|------------|
| **UI Layer** | 화면 구성, 내비게이션, 테마, 위젯 | Flutter Widgets, go_router |
| **Game Layer** | 게임 로직, 렌더링, 입력 처리, 이펙트 | Flame Engine |
| **Service Layer** | 외부 서비스 통합, 비즈니스 로직 | firebase_auth, google_mobile_ads, purchases_flutter |
| **Data Layer** | 로컬/원격 데이터 저장, 캐싱 | hive, cloud_firestore |
| **State** | 전역 상태 관리, DI | flutter_riverpod |

---

## 2. 프로젝트 구조

### 2.1 디렉토리 구조

```
blockdrop/
├── android/                       # Android 네이티브 설정
├── ios/                           # iOS 네이티브 설정
├── assets/
│   ├── audio/
│   │   ├── bgm/                   # 배경 음악
│   │   └── sfx/                   # 효과음
│   ├── images/
│   │   ├── blocks/                # 블록 스프라이트
│   │   ├── backgrounds/           # 배경 이미지
│   │   ├── ui/                    # UI 에셋
│   │   └── effects/               # 파티클/이펙트 에셋
│   ├── fonts/                     # 커스텀 폰트
│   └── data/
│       └── levels/                # 퍼즐 레벨 JSON 데이터
├── lib/
│   ├── main.dart                  # 앱 엔트리포인트
│   ├── app.dart                   # MaterialApp + Router 설정
│   │
│   ├── core/                      # 공통 유틸리티
│   │   ├── constants/
│   │   │   ├── game_constants.dart    # 게임 상수 (그리드 크기, 속도 등)
│   │   │   ├── app_colors.dart        # 색상 팔레트
│   │   │   └── app_strings.dart       # 문자열 상수 (i18n 키)
│   │   ├── extensions/
│   │   │   └── context_extensions.dart
│   │   ├── utils/
│   │   │   ├── haptic_util.dart       # 진동 피드백
│   │   │   └── sound_util.dart        # 사운드 유틸
│   │   └── theme/
│   │       ├── app_theme.dart         # 앱 테마 정의
│   │       └── game_theme.dart        # 게임 내 테마 (블록 스킨 등)
│   │
│   ├── data/                      # 데이터 레이어
│   │   ├── models/
│   │   │   ├── block_piece.dart       # 블록 조각 모델
│   │   │   ├── board_state.dart       # 보드 상태 모델
│   │   │   ├── game_state.dart        # 게임 상태 모델
│   │   │   ├── player_profile.dart    # 플레이어 프로필
│   │   │   ├── score_record.dart      # 스코어 기록
│   │   │   ├── level_data.dart        # 레벨 데이터
│   │   │   ├── shop_item.dart         # 상점 아이템
│   │   │   ├── daily_challenge.dart   # 데일리 챌린지
│   │   │   └── achievement.dart       # 업적
│   │   ├── repositories/
│   │   │   ├── game_repository.dart       # 게임 데이터 저장/로드
│   │   │   ├── player_repository.dart     # 플레이어 데이터
│   │   │   ├── leaderboard_repository.dart # 리더보드
│   │   │   ├── shop_repository.dart       # 상점/인벤토리
│   │   │   └── level_repository.dart      # 레벨 데이터
│   │   └── datasources/
│   │       ├── local/
│   │       │   ├── hive_game_datasource.dart
│   │       │   └── hive_player_datasource.dart
│   │       └── remote/
│   │           ├── firestore_player_datasource.dart
│   │           └── firestore_leaderboard_datasource.dart
│   │
│   ├── game/                      # Flame 게임 레이어
│   │   ├── blockdrop_game.dart        # FlameGame 메인 클래스
│   │   ├── components/
│   │   │   ├── board_component.dart       # 게임 보드 (그리드)
│   │   │   ├── block_component.dart       # 개별 블록 셀
│   │   │   ├── piece_component.dart       # 낙하 블록 조각
│   │   │   ├── ghost_piece_component.dart # 고스트 피스 (착지 미리보기)
│   │   │   ├── next_piece_preview.dart    # 다음 블록 미리보기
│   │   │   ├── hold_piece_display.dart    # 홀드 블록 표시
│   │   │   ├── score_display.dart         # 점수 표시
│   │   │   ├── combo_display.dart         # 콤보 표시
│   │   │   └── background_component.dart  # 배경
│   │   ├── systems/
│   │   │   ├── input_system.dart          # 터치/스와이프 입력 처리
│   │   │   ├── gravity_system.dart        # 블록 낙하 시스템
│   │   │   ├── collision_system.dart      # 충돌 감지
│   │   │   ├── line_clear_system.dart     # 줄 클리어 판정
│   │   │   ├── color_match_system.dart    # 컬러 매칭 판정
│   │   │   ├── scoring_system.dart        # 점수 계산
│   │   │   ├── combo_system.dart          # 콤보 시스템
│   │   │   ├── level_system.dart          # 레벨/난이도 관리
│   │   │   └── skill_block_system.dart    # 스킬 블록 로직
│   │   ├── effects/
│   │   │   ├── line_clear_effect.dart     # 줄 클리어 이펙트
│   │   │   ├── combo_effect.dart          # 콤보 이펙트
│   │   │   ├── landing_effect.dart        # 블록 착지 이펙트
│   │   │   ├── skill_block_effect.dart    # 스킬 블록 발동 이펙트
│   │   │   └── particle_system.dart       # 파티클 시스템
│   │   ├── modes/
│   │   │   ├── game_mode.dart             # 게임 모드 추상 클래스
│   │   │   ├── classic_mode.dart          # 클래식 모드
│   │   │   ├── puzzle_mode.dart           # 퍼즐 모드
│   │   │   ├── sprint_mode.dart           # 스프린트 모드
│   │   │   ├── daily_challenge_mode.dart  # 데일리 챌린지 모드
│   │   │   ├── zen_mode.dart              # 젠 모드
│   │   │   └── vs_mode.dart               # VS 대전 모드
│   │   └── data/
│   │       ├── piece_definitions.dart     # 블록 조각 형태 정의
│   │       ├── piece_colors.dart          # 블록 색상 정의
│   │       └── difficulty_curves.dart     # 난이도 커브 데이터
│   │
│   ├── services/                  # 서비스 레이어
│   │   ├── auth_service.dart          # Firebase Auth 래퍼
│   │   ├── ad_service.dart            # AdMob 관리
│   │   ├── iap_service.dart           # RevenueCat IAP 관리
│   │   ├── audio_service.dart         # 배경음/효과음 관리
│   │   ├── analytics_service.dart     # Firebase Analytics 래퍼
│   │   ├── remote_config_service.dart # Firebase Remote Config
│   │   ├── push_service.dart          # FCM 푸시 알림
│   │   └── social_service.dart        # 소셜 공유/초대
│   │
│   ├── providers/                 # Riverpod 프로바이더
│   │   ├── game_providers.dart        # 게임 상태 프로바이더
│   │   ├── player_providers.dart      # 플레이어 프로바이더
│   │   ├── auth_providers.dart        # 인증 프로바이더
│   │   ├── shop_providers.dart        # 상점 프로바이더
│   │   ├── settings_providers.dart    # 설정 프로바이더
│   │   └── leaderboard_providers.dart # 리더보드 프로바이더
│   │
│   ├── screens/                   # UI 화면
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   └── widgets/
│   │   │       ├── mode_card.dart
│   │   │       ├── daily_challenge_banner.dart
│   │   │       └── player_stats_header.dart
│   │   ├── game/
│   │   │   ├── game_screen.dart
│   │   │   └── overlays/
│   │   │       ├── pause_overlay.dart
│   │   │       ├── game_over_overlay.dart
│   │   │       ├── countdown_overlay.dart
│   │   │       └── combo_toast.dart
│   │   ├── puzzle_select/
│   │   │   ├── puzzle_select_screen.dart
│   │   │   └── widgets/
│   │   │       ├── chapter_card.dart
│   │   │       └── level_grid.dart
│   │   ├── shop/
│   │   │   ├── shop_screen.dart
│   │   │   └── widgets/
│   │   │       ├── skin_preview.dart
│   │   │       ├── item_card.dart
│   │   │       └── subscription_banner.dart
│   │   ├── leaderboard/
│   │   │   ├── leaderboard_screen.dart
│   │   │   └── widgets/
│   │   │       └── rank_tile.dart
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   └── widgets/
│   │   │       ├── stats_card.dart
│   │   │       ├── achievement_grid.dart
│   │   │       └── avatar_picker.dart
│   │   └── settings/
│   │       └── settings_screen.dart
│   │
│   └── l10n/                      # 다국어 지원
│       ├── app_en.arb
│       ├── app_ko.arb
│       ├── app_ja.arb
│       └── app_zh.arb
│
├── test/                          # 테스트
│   ├── unit/
│   │   ├── game/
│   │   │   ├── gravity_system_test.dart
│   │   │   ├── collision_system_test.dart
│   │   │   ├── line_clear_system_test.dart
│   │   │   ├── scoring_system_test.dart
│   │   │   └── piece_definitions_test.dart
│   │   └── data/
│   │       └── repositories/
│   ├── widget/
│   │   └── screens/
│   └── integration/
│       └── game_flow_test.dart
│
└── pubspec.yaml
```

---

## 3. 데이터 모델

### 3.1 핵심 게임 모델

#### BlockPiece (낙하 블록 조각)

```dart
/// 게임에서 떨어지는 하나의 블록 조각 (폴리오미노)
class BlockPiece {
  final PieceType type;          // 블록 종류 (I, L, T, S, Z, O, Plus, ...)
  final BlockColor color;         // 블록 색상
  final List<List<int>> shape;   // 2D 행렬 (1=채워진 셀, 0=빈 셀)
  int rotation;                   // 현재 회전 상태 (0, 90, 180, 270)
  int gridX;                      // 보드 내 X 좌표
  int gridY;                      // 보드 내 Y 좌표

  /// 시계 방향 90도 회전된 shape 반환
  List<List<int>> getRotatedShape(int rotation);

  /// 이 조각이 차지하는 모든 셀 좌표 목록
  List<(int x, int y)> getOccupiedCells();
}

/// 블록 종류 - 테트로미노를 피하고 다양한 폴리오미노 사용
enum PieceType {
  // 2-cell (듀오미노)
  duo,           // ██

  // 3-cell (트리오미노)
  triLine,       // ███
  triL,          // ██
                 //  █

  // 4-cell (테트라 - 테트로미노와 다른 형태)
  tetSquare,     // ██
                 // ██
  tetLine,       // ████
  tetT,          // ███
                 //  █
  tetZ,          // ██
                 //  ██
  tetS,          //  ██
                 // ██
  tetL,          // █
                 // █
                 // ██

  // 5-cell (펜토미노) - 상위 레벨에서 등장
  pentPlus,      //  █
                 // ███
                 //  █
  pentU,         // █ █
                 // ███
  pentT,         // ███
                 //  █
                 //  █

  // 특수 블록
  skillBomb,     // 폭탄 (주변 3x3 제거)
  skillLine,     // 라인 클리어 (한 줄 즉시 제거)
  skillColor,    // 컬러 폭탄 (같은 색 모두 제거)
}

/// 블록 색상 (6색 + 특수)
enum BlockColor {
  coral,         // #FF6B6B (코랄 레드)
  amber,         // #FFB347 (앰버 오렌지)
  lemon,         // #FFE066 (레몬 옐로)
  mint,          // #63E6BE (민트 그린)
  sky,           // #74C0FC (스카이 블루)
  lavender,      // #B197FC (라벤더 퍼플)
  special,       // 특수 블록용 (그라데이션)
}
```

#### BoardState (보드 상태)

```dart
/// 게임 보드의 현재 상태
class BoardState {
  final int columns;              // 가로 칸 수 (기본: 8)
  final int rows;                 // 세로 칸 수 (기본: 16)
  final List<List<Cell>> grid;   // 2D 그리드 [row][col]

  /// 특정 좌표에 블록이 있는지 확인
  bool isCellOccupied(int x, int y);

  /// 블록 조각을 보드에 배치
  BoardState placePiece(BlockPiece piece);

  /// 완성된 줄 인덱스 목록 반환
  List<int> getCompletedRows();

  /// 줄 클리어 후 새 보드 상태 반환
  BoardState clearRows(List<int> rows);

  /// 컬러 매칭 그룹 찾기 (3개 이상 연결)
  List<List<(int x, int y)>> findColorMatches();

  /// 블록이 맨 위에 도달했는지 (게임 오버 조건)
  bool isTopReached();
}

/// 보드의 개별 셀
class Cell {
  final bool occupied;            // 블록이 있는지
  final BlockColor? color;        // 블록 색상
  final bool isSkillBlock;        // 스킬 블록 여부
  final SkillType? skillType;     // 스킬 종류
}
```

#### GameState (게임 전체 상태)

```dart
/// 진행 중인 게임의 전체 상태
@freezed
class GameState with _$GameState {
  const factory GameState({
    required BoardState board,
    required BlockPiece currentPiece,     // 현재 조작 중인 블록
    required BlockPiece nextPiece,        // 다음 블록
    BlockPiece? heldPiece,                // 홀드된 블록
    required int score,                    // 현재 점수
    required int level,                    // 현재 레벨
    required int linesCleared,            // 클리어한 줄 수
    required int combo,                    // 현재 콤보 수
    required double dropSpeed,            // 블록 낙하 속도 (초/칸)
    required GameStatus status,           // 게임 상태
    required GameMode mode,               // 게임 모드
    required Duration elapsed,            // 경과 시간
    @Default(false) bool canHold,         // 홀드 가능 여부
    @Default(0) int skillBlocksUsed,      // 사용한 스킬 블록 수
    @Default([]) List<int> recentClears,  // 최근 클리어 줄 수 (콤보 판정용)
  }) = _GameState;
}

enum GameStatus {
  ready,        // 게임 시작 전
  playing,      // 플레이 중
  paused,       // 일시정지
  lineClearing, // 줄 클리어 애니메이션 중
  gameOver,     // 게임 오버
  completed,    // 레벨 클리어 (퍼즐 모드)
}
```

### 3.2 유저/프로필 모델

```dart
/// 플레이어 프로필
@freezed
class PlayerProfile with _$PlayerProfile {
  const factory PlayerProfile({
    required String id,
    required String displayName,
    String? avatarUrl,
    required int totalCoins,              // 보유 코인
    required int totalHearts,             // 보유 하트 (목숨)
    required int totalGamesPlayed,
    required int highScoreClassic,        // 클래식 최고 점수
    required int highScoreSprint,         // 스프린트 최고 기록 (ms)
    required int puzzleLevelReached,      // 퍼즐 모드 진행도
    required int consecutiveDays,         // 연속 출석일
    required DateTime lastPlayedAt,
    required PlayerTier tier,             // 플레이어 등급
    required List<String> ownedSkins,     // 보유 스킨 ID 목록
    required List<String> ownedAvatars,   // 보유 아바타 ID 목록
    required String activeSkinId,         // 현재 사용 중인 스킨
    required SubscriptionStatus subscription, // 구독 상태
    required Map<String, bool> achievements,  // 업적 달성 현황
  }) = _PlayerProfile;
}

enum PlayerTier {
  bronze,       // 0 - 4,999 포인트
  silver,       // 5,000 - 19,999
  gold,         // 20,000 - 49,999
  platinum,     // 50,000 - 99,999
  diamond,      // 100,000+
}

enum SubscriptionStatus {
  none,         // 미구독
  monthly,      // 월간 구독
  yearly,       // 연간 구독
  expired,      // 만료
}
```

### 3.3 상점/아이템 모델

```dart
/// 상점 아이템
@freezed
class ShopItem with _$ShopItem {
  const factory ShopItem({
    required String id,
    required String name,
    required String description,
    required ShopItemType type,
    required int priceCoins,          // 코인 가격 (0이면 코인 구매 불가)
    required double priceUsd,         // USD 가격 (0이면 현금 구매 불가)
    required bool isLimited,          // 한정 판매 여부
    DateTime? availableUntil,         // 한정 판매 종료일
    required String thumbnailAsset,   // 썸네일 이미지 경로
  }) = _ShopItem;
}

enum ShopItemType {
  skin,           // 블록 스킨
  background,     // 배경 테마
  avatar,         // 프로필 아바타
  coinPack,       // 코인 팩 (소모성)
  heartPack,      // 하트 팩 (소모성)
  skillBlockPack, // 스킬 블록 팩 (소모성)
  starterPack,    // 스타터 팩 (1회성)
}
```

### 3.4 레벨/챌린지 모델

```dart
/// 퍼즐 모드 레벨 데이터
@freezed
class LevelData with _$LevelData {
  const factory LevelData({
    required int id,
    required int chapter,             // 챕터 번호
    required int levelInChapter,      // 챕터 내 레벨 번호
    required LevelObjective objective, // 클리어 조건
    required int targetValue,          // 목표값 (줄 수, 점수 등)
    required int maxMoves,             // 최대 블록 수 (0=무제한)
    required double initialSpeed,      // 초기 속도
    required List<PieceType> availablePieces, // 사용 가능한 블록 종류
    required List<List<int>>? prefilledRows,  // 미리 채워진 줄 (선택)
    required int star1Score,           // 1스타 기준 점수
    required int star2Score,           // 2스타 기준 점수
    required int star3Score,           // 3스타 기준 점수
  }) = _LevelData;
}

enum LevelObjective {
  clearLines,      // N줄 클리어
  reachScore,      // 목표 점수 달성
  clearColors,     // 특정 색 블록 N개 제거
  surviveTime,     // N초 버티기
  useSkillBlocks,  // 스킬 블록 N회 사용
}

/// 데일리 챌린지
@freezed
class DailyChallenge with _$DailyChallenge {
  const factory DailyChallenge({
    required DateTime date,
    required LevelData level,
    required int rewardCoins,          // 클리어 보상 코인
    required String? specialRewardId,  // 특별 보상 (스킨 등)
  }) = _DailyChallenge;
}
```

---

## 4. 게임 엔진 설계 (Flame)

### 4.1 컴포넌트 계층 구조

```
BlockDropGame (FlameGame)
├── BackgroundComponent
├── BoardComponent
│   ├── Cell[0,0] ... Cell[7,15]      (8x16 그리드)
│   ├── PieceComponent (현재 블록)
│   └── GhostPieceComponent (착지 미리보기)
├── NextPiecePreview
├── HoldPieceDisplay
├── ScoreDisplay
├── ComboDisplay
├── LevelDisplay
└── EffectsLayer
    ├── LineClearEffect
    ├── ComboEffect
    ├── LandingEffect
    └── ParticleSystem
```

### 4.2 게임 루프

```dart
/// 메인 게임 클래스
class BlockDropGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {

  late final BoardComponent board;
  late final GameMode gameMode;
  late GameState state;

  @override
  Future<void> onLoad() async {
    // 1. 보드 초기화
    board = BoardComponent(columns: 8, rows: 16);
    add(board);

    // 2. UI 컴포넌트 추가
    add(NextPiecePreview());
    add(HoldPieceDisplay());
    add(ScoreDisplay());
    add(ComboDisplay());

    // 3. 이펙트 레이어
    add(EffectsLayer());

    // 4. 게임 모드 초기화
    gameMode = ClassicMode(this);

    // 5. 첫 블록 생성
    spawnNextPiece();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state.status != GameStatus.playing) return;

    // 중력 시스템 (블록 자동 낙하)
    gravitySystem.update(dt);

    // 줄 클리어 판정
    if (gravitySystem.pieceLanded) {
      final cleared = lineClearSystem.check(state.board);
      if (cleared.isNotEmpty) {
        handleLineClears(cleared);
      }
      // 컬러 매칭 판정
      final colorMatches = colorMatchSystem.check(state.board);
      if (colorMatches.isNotEmpty) {
        handleColorMatches(colorMatches);
      }
      spawnNextPiece();
    }

    // 게임 오버 판정
    if (state.board.isTopReached()) {
      gameMode.onGameOver();
    }
  }
}
```

### 4.3 입력 시스템

```dart
/// 터치 입력 처리
class InputSystem extends Component with HasGameRef<BlockDropGame> {
  // 터치 제스처 매핑
  //
  // ┌─────────────────────────────┐
  // │  탭: 블록 시계 방향 회전     │
  // │  좌/우 스와이프: 블록 이동   │
  // │  하 스와이프: 소프트 드롭     │
  // │  하 플릭: 하드 드롭          │
  // │  좌측 탭: 반시계 방향 회전    │
  // │  길게 누르기: 홀드           │
  // └─────────────────────────────┘

  static const double swipeThreshold = 20.0;    // 스와이프 감지 최소 거리
  static const double flickVelocity = 500.0;    // 플릭 감지 최소 속도
  static const Duration holdDuration = Duration(milliseconds: 300);

  void onTapDown(TapDownInfo info) {
    final tapX = info.eventPosition.widget.x;
    final screenMid = gameRef.size.x / 2;

    if (tapX < screenMid * 0.3) {
      // 왼쪽 1/3 탭 → 반시계 방향 회전
      gameRef.rotatePiece(clockwise: false);
    } else {
      // 나머지 → 시계 방향 회전
      gameRef.rotatePiece(clockwise: true);
    }
  }

  void onPanUpdate(DragUpdateInfo info) {
    // 좌/우 드래그 → 블록 이동
    // 아래 드래그 → 소프트 드롭
  }

  void onPanEnd(DragEndInfo info) {
    // 아래 플릭 → 하드 드롭
    if (info.velocity.y > flickVelocity) {
      gameRef.hardDrop();
    }
  }
}
```

### 4.4 점수 시스템

```dart
/// 점수 계산 규칙
class ScoringSystem {
  // 기본 줄 클리어 점수 (레벨 배수 적용)
  static const Map<int, int> lineClearPoints = {
    1: 100,     // 싱글
    2: 300,     // 더블
    3: 500,     // 트리플
    4: 800,     // 쿼드 (4줄 동시)
    5: 1200,    // 펜타 (5줄 동시, 펜토미노 시)
  };

  // 콤보 배율
  static const List<double> comboMultipliers = [
    1.0,   // 0 콤보
    1.2,   // 1 콤보
    1.5,   // 2 콤보
    2.0,   // 3 콤보
    2.5,   // 4 콤보
    3.0,   // 5+ 콤보
  ];

  // 컬러 매칭 보너스 (연결된 블록 수 기준)
  static const Map<int, int> colorMatchBonus = {
    3: 50,
    4: 100,
    5: 200,
    6: 350,
    7: 500,
  };

  int calculate({
    required int linesCleared,
    required int level,
    required int combo,
    required int colorMatchCount,
    required bool usedHardDrop,
    required int dropDistance,
  }) {
    int score = 0;

    // 줄 클리어 점수
    score += (lineClearPoints[linesCleared] ?? 0) * level;

    // 콤보 배율
    final comboIdx = combo.clamp(0, comboMultipliers.length - 1);
    score = (score * comboMultipliers[comboIdx]).round();

    // 컬러 매칭 보너스
    if (colorMatchCount >= 3) {
      score += colorMatchBonus[colorMatchCount.clamp(3, 7)] ?? 500;
    }

    // 하드 드롭 보너스 (떨어뜨린 거리 * 2)
    if (usedHardDrop) {
      score += dropDistance * 2;
    }

    return score;
  }
}
```

### 4.5 난이도 시스템

```dart
/// 레벨별 난이도 커브
class DifficultyConfig {
  // 레벨별 블록 낙하 속도 (초/칸)
  // 레벨 1: 1.0초/칸 → 레벨 20: 0.05초/칸
  static double getDropSpeed(int level) {
    // 지수 감소 커브
    return max(0.05, 1.0 * pow(0.85, level - 1));
  }

  // 레벨업 기준 (클리어한 줄 수)
  static int getLinesForNextLevel(int currentLevel) {
    return currentLevel * 10;
  }

  // 레벨별 블록 출현 확률
  static Map<PieceType, double> getPieceWeights(int level) {
    if (level <= 5) {
      // 초반: 간단한 블록 위주
      return {
        PieceType.duo: 0.15,
        PieceType.triLine: 0.20,
        PieceType.triL: 0.15,
        PieceType.tetSquare: 0.15,
        PieceType.tetLine: 0.15,
        PieceType.tetT: 0.10,
        PieceType.tetL: 0.10,
      };
    } else if (level <= 15) {
      // 중반: Z/S 블록 추가, 펜토미노 소량
      return {
        PieceType.triLine: 0.10,
        PieceType.tetSquare: 0.12,
        PieceType.tetLine: 0.12,
        PieceType.tetT: 0.12,
        PieceType.tetZ: 0.10,
        PieceType.tetS: 0.10,
        PieceType.tetL: 0.12,
        PieceType.pentPlus: 0.07,
        PieceType.pentU: 0.07,
        PieceType.pentT: 0.08,
      };
    } else {
      // 후반: 대형 블록 비중 증가
      return {
        PieceType.tetT: 0.10,
        PieceType.tetZ: 0.10,
        PieceType.tetS: 0.10,
        PieceType.tetL: 0.10,
        PieceType.pentPlus: 0.15,
        PieceType.pentU: 0.15,
        PieceType.pentT: 0.15,
        PieceType.triL: 0.05,
        PieceType.tetLine: 0.05,
        PieceType.tetSquare: 0.05,
      };
    }
  }

  // 스킬 블록 출현율 (레벨별)
  static double getSkillBlockChance(int level) {
    if (level < 3) return 0.0;       // 3레벨 이하: 없음
    if (level < 10) return 0.05;     // 5%
    return 0.08;                      // 8%
  }
}
```

---

## 5. UI/UX 설계

### 5.1 내비게이션 플로우

```
┌──────────┐
│  Splash  │
│  Screen  │
└────┬─────┘
     │
┌────▼─────┐     ┌────────────┐
│   Home   │────▶│   Shop     │
│  Screen  │     │   Screen   │
└──┬─┬─┬───┘     └────────────┘
   │ │ │
   │ │ └────────▶┌────────────┐
   │ │           │ Leaderboard│
   │ │           │   Screen   │
   │ │           └────────────┘
   │ │
   │ └──────────▶┌────────────┐
   │             │  Profile   │
   │             │  Screen    │
   │             └────────────┘
   │
   ├─ 클래식 ───▶┌────────────┐     ┌────────────┐
   │             │   Game     │────▶│ Game Over  │
   ├─ 스프린트 ─▶│  Screen    │     │  Overlay   │
   │             └────────────┘     └────────────┘
   ├─ 젠 ──────▶       │
   │                    │
   │              ┌─────▼──────┐
   │              │   Pause    │
   │              │  Overlay   │
   │              └────────────┘
   │
   └─ 퍼즐 ────▶┌────────────┐     ┌────────────┐
                │  Puzzle    │────▶│   Game     │
                │  Select    │     │  Screen    │
                └────────────┘     └────────────┘
```

### 5.2 화면별 상세 설계

#### A. Home Screen (메인 화면)

```
┌─────────────────────────────────┐
│  ♦ 500    ♥ 5    ⚙️            │  ← 상태바 (코인, 하트, 설정)
├─────────────────────────────────┤
│                                 │
│        B L O C K D R O P        │  ← 로고
│                                 │
│  ┌─────────────────────────┐    │
│  │  🏆 Daily Challenge     │    │  ← 데일리 챌린지 배너
│  │  Clear 20 lines!        │    │
│  │  Reward: 100 coins      │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌──────────┐ ┌──────────┐     │
│  │          │ │          │     │
│  │ CLASSIC  │ │ PUZZLE   │     │  ← 게임 모드 카드 (2x2)
│  │  ▶ Play  │ │ Level 24 │     │
│  └──────────┘ └──────────┘     │
│                                 │
│  ┌──────────┐ ┌──────────┐     │
│  │          │ │          │     │
│  │ SPRINT   │ │   ZEN    │     │
│  │ Best: 42s│ │  ▶ Play  │     │
│  └──────────┘ └──────────┘     │
│                                 │
├─────────────────────────────────┤
│  🏠 Home  🏆 Rank  🛍 Shop  👤 │  ← 하단 내비게이션
└─────────────────────────────────┘
```

#### B. Game Screen (게임 화면)

```
┌─────────────────────────────────┐
│  ⏸  SCORE: 12,450   LV.7       │  ← 상단 바 (일시정지, 점수, 레벨)
├─────────────────────────────────┤
│  ┌────┐                ┌────┐   │
│  │HOLD│                │NEXT│   │  ← 홀드 / 다음 블록
│  │ ██ │                │ █  │   │
│  │ █  │                │ ██ │   │
│  └────┘                └────┘   │
│                                 │
│  ┌────────────────────────┐     │
│  │ · · · · · · · ·       │     │
│  │ · · · · · · · ·       │     │
│  │ · · · · · · · ·       │     │
│  │ · · · · · · · ·       │     │
│  │ · · · · · · · ·       │     │
│  │ · · · █ █ · · ·       │     │  ← 8x16 게임 보드
│  │ · · · · █ · · ·       │     │
│  │ · · · · █ · · ·       │     │
│  │ · · · · · · · ·       │     │
│  │ · · · · · · · ·       │     │
│  │ · · · ░ ░ · · ·       │     │  ← 고스트 피스
│  │ · · · · ░ · · ·       │     │
│  │ · · · · ░ · · ·       │     │
│  │ · · · · · · · ·       │     │
│  │ █ █ · · · █ █ █       │     │  ← 기존 블록
│  │ █ █ █ · █ █ █ █       │     │
│  └────────────────────────┘     │
│                                 │
│  COMBO x3      LINES: 42       │  ← 콤보/라인 카운트
│                                 │
│  [💣] [━] [🎨]                  │  ← 스킬 블록 슬롯
└─────────────────────────────────┘
```

#### C. Game Over Overlay

```
┌─────────────────────────────────┐
│         (반투명 배경)            │
│  ┌───────────────────────┐      │
│  │                       │      │
│  │     GAME OVER         │      │
│  │                       │      │
│  │   Score: 12,450       │      │
│  │   Best:  28,900       │      │
│  │   Lines: 42           │      │
│  │   Combo: x5 (max)     │      │
│  │                       │      │
│  │  ★ ★ ☆  (2 / 3 stars)│      │  ← 퍼즐 모드에서만
│  │                       │      │
│  │  ┌─────────────────┐  │      │
│  │  │ ▶ Continue (♥1) │  │      │  ← 하트로 이어하기
│  │  └─────────────────┘  │      │
│  │  ┌─────────────────┐  │      │
│  │  │ 📺 Watch Ad     │  │      │  ← 광고 시청으로 이어하기
│  │  └─────────────────┘  │      │
│  │  ┌─────────────────┐  │      │
│  │  │ 🏠 Home         │  │      │
│  │  └─────────────────┘  │      │
│  │  ┌─────────────────┐  │      │
│  │  │ 🔄 Retry        │  │      │
│  │  └─────────────────┘  │      │
│  │                       │      │
│  │  📤 Share Score       │      │  ← 소셜 공유
│  └───────────────────────┘      │
└─────────────────────────────────┘
```

#### D. Shop Screen

```
┌─────────────────────────────────┐
│  ← Shop               ♦ 500    │
├─────────────────────────────────┤
│  ┌─────────────────────────┐    │
│  │  BlockDrop Pass         │    │  ← 구독 배너
│  │  Ad-free + Daily Bonus  │    │
│  │  $4.99/month            │    │
│  └─────────────────────────┘    │
│                                 │
│  [Skins] [Backgrounds] [Items]  │  ← 카테고리 탭
│                                 │
│  ┌─────┐ ┌─────┐ ┌─────┐      │
│  │     │ │     │ │     │      │
│  │Neon │ │Pastel│ │Wood │      │
│  │     │ │     │ │     │      │
│  │♦300 │ │♦500 │ │$2.99│      │
│  └─────┘ └─────┘ └─────┘      │
│                                 │
│  ┌─────┐ ┌─────┐ ┌─────┐      │
│  │     │ │     │ │ 🔥  │      │
│  │Ocean│ │Space│ │ Ltd │      │  ← 한정 아이템
│  │     │ │     │ │     │      │
│  │♦800 │ │$4.99│ │$1.99│      │
│  └─────┘ └─────┘ └─────┘      │
│                                 │
│  ── Coin Packs ──               │
│  ┌──────┐ ┌──────┐ ┌──────┐   │
│  │ 100♦ │ │ 500♦ │ │2000♦ │   │
│  │$0.99 │ │$3.99 │ │$9.99 │   │
│  └──────┘ └──────┘ └──────┘   │
├─────────────────────────────────┤
│  🏠 Home  🏆 Rank  🛍 Shop  👤 │
└─────────────────────────────────┘
```

### 5.3 비주얼 디자인 시스템

#### 색상 팔레트

```
Primary Colors (블록):
  Coral:    #FF6B6B  →  #FF8787 (라이트)
  Amber:    #FFB347  →  #FFC078 (라이트)
  Lemon:    #FFE066  →  #FFE88A (라이트)
  Mint:     #63E6BE  →  #8CF0D2 (라이트)
  Sky:      #74C0FC  →  #99D0FD (라이트)
  Lavender: #B197FC  →  #C8B6FD (라이트)

Background:
  Dark Mode:  #1A1B2E (메인), #252742 (카드), #2D2F4E (보드)
  Light Mode: #F8F9FA (메인), #FFFFFF (카드), #E9ECEF (보드)

UI:
  Primary:    #6C5CE7 (메인 액센트)
  Secondary:  #00B894 (보조 액센트)
  Text:       #2D3436 (다크), #F8F9FA (라이트)
  Disabled:   #636E72
```

#### 타이포그래피

```
Font Family: "Nunito" (게임 UI) + "JetBrains Mono" (점수/숫자)

Heading:   Nunito Bold, 24-32px
Subhead:   Nunito SemiBold, 18-20px
Body:      Nunito Regular, 14-16px
Caption:   Nunito Regular, 12px
Score:     JetBrains Mono Bold, 20-40px
Combo:     Nunito Black, 48-72px (이펙트용)
```

#### 블록 렌더링 스타일

```
각 블록 셀:
  - 크기: 그리드에 따라 동적 (화면 폭 / 8)
  - 모서리: borderRadius 4px (둥근 사각형)
  - 외곽선: 1px, 색상보다 20% 어두운 색
  - 내부: 2단 그라데이션 (상단 밝음 → 하단 어두움)
  - 광택: 좌상단에 작은 하이라이트 (반투명 흰색)
  - 그림자: 2px 하단 그림자 (검정 10% 투명도)
```

---

## 6. 백엔드 설계 (Firebase)

### 6.1 Firestore 컬렉션 구조

```
firestore/
├── users/{userId}
│   ├── displayName: string
│   ├── avatarUrl: string?
│   ├── totalCoins: number
│   ├── totalHearts: number
│   ├── totalGamesPlayed: number
│   ├── highScoreClassic: number
│   ├── highScoreSprint: number
│   ├── puzzleLevelReached: number
│   ├── consecutiveDays: number
│   ├── lastPlayedAt: timestamp
│   ├── tier: string
│   ├── ownedSkins: string[]
│   ├── ownedAvatars: string[]
│   ├── activeSkinId: string
│   ├── subscription: string
│   ├── achievements: map<string, boolean>
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp
│
├── leaderboards/{mode}                  # "classic", "sprint"
│   └── entries/{entryId}
│       ├── userId: string
│       ├── displayName: string
│       ├── score: number
│       ├── level: number
│       ├── linesCleared: number
│       ├── duration: number             # 밀리초 (스프린트용)
│       ├── tier: string
│       ├── createdAt: timestamp
│       └── weekOf: string               # "2026-W06" (주간 리셋용)
│
├── dailyChallenges/{dateStr}            # "2026-02-08"
│   ├── level: map (LevelData)
│   ├── rewardCoins: number
│   ├── specialRewardId: string?
│   └── completions/{userId}
│       ├── score: number
│       ├── stars: number
│       └── completedAt: timestamp
│
├── seasons/{seasonId}
│   ├── name: string
│   ├── startDate: timestamp
│   ├── endDate: timestamp
│   ├── theme: map
│   ├── rewards: map[]
│   └── participants/{userId}
│       ├── points: number
│       ├── tier: number
│       └── claimedRewards: string[]
│
└── shopItems/{itemId}
    ├── name: string
    ├── description: string
    ├── type: string
    ├── priceCoins: number
    ├── priceUsd: number
    ├── isLimited: boolean
    ├── availableUntil: timestamp?
    ├── isActive: boolean
    └── thumbnailUrl: string
```

### 6.2 Firestore 보안 규칙

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 유저 프로필: 본인만 읽기/쓰기
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // 리더보드: 인증된 유저 읽기, 본인 점수만 쓰기
    match /leaderboards/{mode}/entries/{entryId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.score is number
        && request.resource.data.score > 0;
      allow update, delete: if false;
    }

    // 데일리 챌린지: 읽기 전체, 완료 기록은 본인만
    match /dailyChallenges/{dateStr} {
      allow read: if request.auth != null;

      match /completions/{userId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null
          && request.auth.uid == userId;
        allow update, delete: if false;
      }
    }

    // 시즌: 읽기 전체
    match /seasons/{seasonId} {
      allow read: if request.auth != null;

      match /participants/{userId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null
          && request.auth.uid == userId;
      }
    }

    // 상점 아이템: 읽기 전체
    match /shopItems/{itemId} {
      allow read: if true;
      allow write: if false;  // 관리자만 (Admin SDK)
    }
  }
}
```

### 6.3 Firebase Remote Config (A/B 테스트)

```json
{
  "ad_interstitial_frequency": 4,
  "rewarded_video_coin_reward": 50,
  "daily_free_hearts": 5,
  "heart_regen_minutes": 30,
  "starter_pack_enabled": true,
  "starter_pack_price_usd": 4.99,
  "season_theme": "spring_2026",
  "feature_vs_mode_enabled": false,
  "skill_block_bomb_radius": 3,
  "max_combo_multiplier": 3.0,
  "difficulty_curve_factor": 0.85
}
```

---

## 7. 수익화 통합 설계

### 7.1 RevenueCat (IAP + 구독) 아키텍처

```dart
/// IAP 서비스
class IAPService {
  // RevenueCat Product IDs
  static const String kMonthlyPass = 'blockdrop_pass_monthly';
  static const String kYearlyPass = 'blockdrop_pass_yearly';
  static const String kSeasonPass = 'blockdrop_season_pass';
  static const String kCoins100 = 'coins_100';
  static const String kCoins500 = 'coins_500';
  static const String kCoins2000 = 'coins_2000';
  static const String kHearts5 = 'hearts_5';
  static const String kStarterPack = 'starter_pack';

  // RevenueCat Entitlements
  static const String kEntitlementPremium = 'premium';   // 광고 제거
  static const String kEntitlementSeason = 'season_pass'; // 시즌 패스

  /// 구독 상태 확인
  Future<bool> isPremium();

  /// 구매 처리
  Future<PurchaseResult> purchase(String productId);

  /// 구매 복원
  Future<void> restorePurchases();
}
```

### 7.2 AdMob 통합

```dart
/// 광고 서비스
class AdService {
  // Ad Unit IDs (플랫폼별)
  static const String kBannerHome = 'ca-app-pub-xxx/banner_home';
  static const String kInterstitial = 'ca-app-pub-xxx/interstitial';
  static const String kRewardedVideo = 'ca-app-pub-xxx/rewarded';

  /// 리워드 광고 시청 (이어하기, 코인 획득 등)
  Future<RewardResult> showRewardedAd();

  /// 인터스티셜 광고 (게임 간 전환)
  Future<void> showInterstitialIfReady();

  /// 광고 표시 여부 (구독자는 표시하지 않음)
  bool shouldShowAds();

  /// 인터스티셜 빈도 체크 (Remote Config 기반)
  bool isInterstitialDue(int gamesPlayed);
}
```

### 7.3 수익화 플로우

```
게임 오버 시 플로우:

1. 게임 오버 발생
     │
2. 이어하기 가능 여부 확인
     ├── 하트 보유 → "Continue (♥1)" 버튼 표시
     ├── 하트 미보유 → "Watch Ad" 버튼 표시 (리워드 광고)
     └── 이어하기 거절 → 결과 화면
                           │
3. 결과 화면 표시
     │
4. 인터스티셜 광고 체크 (4판마다)
     ├── 구독자 → 광고 없음
     └── 비구독자 → 인터스티셜 표시
                           │
5. 홈으로 돌아가기 / 재시작
```

---

## 8. 오디오 설계

### 8.1 사운드 에셋 목록

```
audio/
├── bgm/
│   ├── menu_theme.ogg         # 메인 메뉴 BGM (루프)
│   ├── classic_theme.ogg      # 클래식 모드 BGM
│   ├── puzzle_theme.ogg       # 퍼즐 모드 BGM
│   ├── zen_theme.ogg          # 젠 모드 BGM (어쿠스틱)
│   └── boss_theme.ogg         # 고레벨/보스 스테이지 BGM
│
└── sfx/
    ├── piece_move.ogg         # 블록 좌/우 이동
    ├── piece_rotate.ogg       # 블록 회전
    ├── piece_land.ogg         # 블록 착지 (소프트)
    ├── hard_drop.ogg          # 하드 드롭
    ├── line_clear_1.ogg       # 싱글 줄 클리어
    ├── line_clear_2.ogg       # 더블
    ├── line_clear_3.ogg       # 트리플
    ├── line_clear_4.ogg       # 쿼드 (강렬한 효과음)
    ├── combo_1.ogg            # 콤보 1
    ├── combo_2.ogg            # 콤보 2
    ├── combo_3.ogg            # 콤보 3+
    ├── color_match.ogg        # 컬러 매칭
    ├── skill_bomb.ogg         # 폭탄 블록 발동
    ├── skill_line.ogg         # 라인 클리어 블록 발동
    ├── level_up.ogg           # 레벨업
    ├── star_earn.ogg          # 스타 획득
    ├── game_over.ogg          # 게임 오버
    ├── menu_tap.ogg           # UI 탭
    ├── coin_earn.ogg          # 코인 획득
    └── achievement.ogg        # 업적 달성
```

### 8.2 햅틱 피드백 매핑

```dart
class HapticConfig {
  // 이벤트별 햅틱 강도
  static const Map<GameEvent, HapticType> haptics = {
    GameEvent.pieceMove:     HapticType.light,
    GameEvent.pieceRotate:   HapticType.light,
    GameEvent.pieceLand:     HapticType.medium,
    GameEvent.hardDrop:      HapticType.heavy,
    GameEvent.lineClear1:    HapticType.medium,
    GameEvent.lineClear2:    HapticType.medium,
    GameEvent.lineClear3:    HapticType.heavy,
    GameEvent.lineClear4:    HapticType.heavy,
    GameEvent.combo:         HapticType.medium,
    GameEvent.colorMatch:    HapticType.medium,
    GameEvent.skillBlock:    HapticType.heavy,
    GameEvent.gameOver:      HapticType.heavy,
  };
}
```

---

## 9. 상태 관리 설계 (Riverpod)

### 9.1 프로바이더 구조

```dart
// ──────────────────────────────────
// 게임 상태 프로바이더
// ──────────────────────────────────

/// 현재 게임 상태
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>(
  (ref) => GameStateNotifier(ref),
);

/// 게임 설정 (볼륨, 햅틱, 다크모드 등)
final gameSettingsProvider = StateNotifierProvider<GameSettingsNotifier, GameSettings>(
  (ref) => GameSettingsNotifier(ref.read(gameRepositoryProvider)),
);

// ──────────────────────────────────
// 플레이어 프로바이더
// ──────────────────────────────────

/// 현재 로그인한 유저 프로필
final playerProfileProvider = StreamProvider<PlayerProfile?>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.value == null) return Stream.value(null);
  return ref.read(playerRepositoryProvider).watchProfile(auth.value!.uid);
});

/// 인증 상태
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

// ──────────────────────────────────
// 상점/구독 프로바이더
// ──────────────────────────────────

/// 구독 상태
final subscriptionProvider = StreamProvider<SubscriptionStatus>((ref) {
  return ref.read(iapServiceProvider).subscriptionStream;
});

/// 광고 표시 여부
final shouldShowAdsProvider = Provider<bool>((ref) {
  final sub = ref.watch(subscriptionProvider);
  return sub.value == SubscriptionStatus.none;
});

/// 상점 아이템 목록
final shopItemsProvider = FutureProvider<List<ShopItem>>((ref) {
  return ref.read(shopRepositoryProvider).getActiveItems();
});

// ──────────────────────────────────
// 리더보드 프로바이더
// ──────────────────────────────────

/// 주간 리더보드 (모드별)
final weeklyLeaderboardProvider = FutureProvider.family<List<ScoreRecord>, String>(
  (ref, mode) {
    return ref.read(leaderboardRepositoryProvider).getWeeklyTop(mode, limit: 100);
  },
);
```

---

## 10. 패키지 의존성

### 10.1 pubspec.yaml 핵심 의존성

```yaml
dependencies:
  flutter:
    sdk: flutter

  # ── 게임 엔진 ──
  flame: ^1.22.0
  flame_audio: ^2.10.0

  # ── 상태 관리 ──
  flutter_riverpod: ^2.6.0
  riverpod_annotation: ^2.6.0
  freezed_annotation: ^2.4.0

  # ── 내비게이션 ──
  go_router: ^14.0.0

  # ── Firebase ──
  firebase_core: ^3.8.0
  firebase_auth: ^5.3.0
  cloud_firestore: ^5.5.0
  firebase_analytics: ^11.3.0
  firebase_crashlytics: ^4.1.0
  firebase_remote_config: ^5.1.0
  firebase_messaging: ^15.1.0

  # ── 수익화 ──
  google_mobile_ads: ^5.2.0
  purchases_flutter: ^8.2.0        # RevenueCat

  # ── 로컬 저장 ──
  hive_flutter: ^1.1.0

  # ── UI/UX ──
  flutter_animate: ^4.5.0
  shimmer: ^3.0.0
  cached_network_image: ^3.4.0

  # ── 유틸리티 ──
  share_plus: ^10.0.0              # 소셜 공유
  url_launcher: ^6.3.0
  package_info_plus: ^8.1.0
  connectivity_plus: ^6.1.0
  flutter_local_notifications: ^18.0.0

  # ── 다국어 ──
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  riverpod_generator: ^2.6.0
  flutter_lints: ^5.0.0
  mocktail: ^1.0.0
```

---

## 11. 구현 순서 (Phase 별)

### Phase 1: MVP (Core Game)

```
구현 순서:
1. Flutter 프로젝트 생성 + Flame 초기 설정
2. 데이터 모델 정의 (BlockPiece, BoardState, GameState)
3. 블록 조각 형태 정의 (piece_definitions.dart)
4. BoardComponent + 그리드 렌더링
5. PieceComponent + 블록 렌더링
6. InputSystem (터치 이동/회전)
7. GravitySystem (자동 낙하)
8. CollisionSystem (충돌 감지)
9. LineClearSystem (줄 클리어 판정)
10. ScoringSystem (기본 점수)
11. GhostPieceComponent (착지 미리보기)
12. NextPiecePreview + HoldPieceDisplay
13. 기본 UI (홈 화면, 게임 화면, 게임 오버)
14. 기본 효과음 + 햅틱
15. 로컬 하이스코어 저장 (Hive)
```

### Phase 2-6: Plan 문서의 로드맵 참조

각 Phase의 상세 구현 사항은 Plan 문서 Section 8의 로드맵을 따릅니다.

---

## 12. 테스트 전략

### 12.1 단위 테스트 (필수)

| 대상 | 테스트 항목 |
|------|------------|
| `piece_definitions` | 모든 블록 형태의 회전이 올바른지 검증 |
| `collision_system` | 벽/바닥/기존 블록 충돌 감지 정확성 |
| `line_clear_system` | 완성된 줄 감지, 다중 줄 동시 클리어 |
| `color_match_system` | 3개 이상 연결 감지, 대각선 미포함 |
| `scoring_system` | 줄 클리어/콤보/컬러매칭 점수 계산 |
| `difficulty_config` | 레벨별 속도/블록 확률 커브 |
| `board_state` | 블록 배치, 줄 클리어, 게임 오버 판정 |

### 12.2 위젯 테스트

| 대상 | 테스트 항목 |
|------|------------|
| Home Screen | 모든 모드 카드 표시, 탭 시 올바른 화면 전환 |
| Game Over Overlay | 점수 표시, 이어하기/재시작 버튼 동작 |
| Shop Screen | 아이템 목록 로드, 구매 버튼 동작 |

### 12.3 통합 테스트

| 시나리오 | 검증 항목 |
|---------|----------|
| 클래식 모드 풀 플로우 | 시작 → 플레이 → 줄 클리어 → 레벨업 → 게임 오버 → 하이스코어 저장 |
| IAP 구매 플로우 | 상점 → 아이템 선택 → 결제 → 인벤토리 반영 |
| 데일리 챌린지 | 챌린지 로드 → 플레이 → 클리어 → 보상 지급 |

---

## 13. 성능 목표

| 지표 | 목표 |
|------|------|
| FPS | 60 FPS 안정 (저사양 기기에서도) |
| 앱 시작 시간 | < 2초 (Cold Start) |
| 메모리 사용 | < 150MB |
| APK 크기 | < 30MB (다운로드 크기) |
| IPA 크기 | < 50MB |
| 배터리 소모 | 1시간 플레이 시 < 10% |
| 크래시율 | < 0.5% |

---

> **Plan Reference**: [tetris-mobile-app.plan.md](../../01-plan/features/tetris-mobile-app.plan.md)
> **Next Step**: `/pdca do tetris-mobile-app` → Phase 1 MVP 구현 시작
