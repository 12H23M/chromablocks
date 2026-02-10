# Design: BlockDrop UI Redesign

> **Feature**: ui-redesign
> **Date**: 2026-02-08
> **Status**: Draft
> **Plan Reference**: `docs/01-plan/features/ui-redesign.plan.md`
> **Design Concept**: "Luminous Flow" -- 깨끗하면서도 빛나는, 심플하면서도 살아있는

---

## 1. 변경 파일 목록

### 1.1 신규 / 수정 파일

| # | 파일 경로 | 변경 유형 | 설명 |
|---|----------|----------|------|
| 1 | `lib/core/constants/app_colors.dart` | 수정 | 새 컬러 팔레트 + 글로우 컬러 추가 |
| 2 | `lib/game/components/piece_component.dart` | 수정 | 블록 렌더링 개선 (글로우 + 하이라이트 + 그림자) |
| 3 | `lib/game/components/board_component.dart` | 수정 | 보드 프레임 글로우 테두리, 배경 개선 |
| 4 | `lib/game/components/ghost_piece_component.dart` | 수정 | 고스트 피스 점선 외곽선 + 펄스 |
| 5 | `lib/game/components/next_piece_preview.dart` | 수정 | 프리뷰 박스 글로우 스타일 |
| 6 | `lib/game/components/hold_piece_display.dart` | 수정 | 홀드 박스 글로우 스타일 |
| 7 | `lib/game/blockdrop_game.dart` | 수정 | 배경색 변경, 레벨별 배경 그라디언트 |
| 8 | `lib/screens/home/home_screen.dart` | 수정 | 홈 화면 전면 리디자인 |
| 9 | `lib/screens/game/game_screen.dart` | 수정 | HUD 글로우 스타일 개선 |
| 10 | `lib/screens/game/overlays/game_over_overlay.dart` | 수정 | 게임 오버 임팩트 개선 |
| 11 | `lib/screens/game/overlays/pause_overlay.dart` | 수정 | 일시정지 오버레이 스타일 통일 |
| 12 | `lib/data/models/block_piece.dart` | 수정 | BlockColor에 glowColor getter 추가 |

### 1.2 Pencil 디자인 (3개 화면)

| # | 화면 | Frame ID | 설명 |
|---|------|----------|------|
| 1 | Home Screen | `KEjqr` | 홈 화면 리디자인 |
| 2 | Game Screen | `im5at` | 게임 화면 리디자인 |
| 3 | Game Over Screen | `R9kGF` | 게임 오버 리디자인 |

---

## 2. 컬러 시스템 설계

### 2.1 배경/서피스 컬러 (As-Is → To-Be)

| 토큰 | 현재 (As-Is) | 변경 (To-Be) | 이유 |
|------|-------------|-------------|------|
| `darkBg` | `#1A1B2E` | `#0D1117` | 더 깊은 다크, OLED 최적화 |
| `darkCard` | `#252742` | `#21262D` | 배경과 충분한 대비 |
| `darkBoard` | `#2D2F4E` | `#161B22` | 보드 배경을 더 어둡게, 블록 대비 극대화 |
| `darkGridLine` | `#3A3C5E` | `#30363D` | 은은한 그리드 라인 |
| `darkBoardBorder` | (없음) | `#7C3AED40` (보라 글로우) | 보드 테두리 글로우 효과 |

### 2.2 UI 컬러

| 토큰 | 현재 (As-Is) | 변경 (To-Be) | 이유 |
|------|-------------|-------------|------|
| `primary` | `#6C5CE7` (단색) | `#7C3AED` (진한 보라) | 더 선명한 보라, 글로우 베이스 |
| `primaryLight` | (없음) | `#A78BFA` | 그라디언트 밝은 쪽 |
| `accent` | (없음) | `#06B6D4` (시안) | 강조 글로우 컬러 |
| `accentLight` | (없음) | `#22D3EE` | 시안 밝은 쪽 |

### 2.3 블록 컬러 (더 선명하고 글로우)

| 블록 | 현재 base | 변경 base | 변경 light | 글로우 (40% alpha) |
|------|----------|----------|------------|------------------|
| Coral | `#FF6B6B` | `#EF4444` | `#FCA5A5` | `#EF444440` |
| Amber | `#FFB347` | `#F59E0B` | `#FCD34D` | `#F59E0B40` |
| Lemon | `#FFE066` | `#EAB308` | `#FDE047` | `#EAB30840` |
| Mint | `#63E6BE` | `#10B981` | `#6EE7B7` | `#10B98140` |
| Sky | `#74C0FC` | `#3B82F6` | `#93C5FD` | `#3B82F640` |
| Lavender | `#B197FC` | `#8B5CF6` | `#C4B5FD` | `#8B5CF640` |

> 블록 컬러를 더 채도 높고 진하게 변경하여 어두운 배경 위에서 글로우 효과가 돋보이도록 함.

---

## 3. 블록 렌더링 설계

### 3.1 현재 (As-Is) 블록 렌더링

```
PieceComponent._drawCell():
  1. 그라디언트 채우기 (lightColor → baseColor, 위→아래)
  2. 좌측 상단 작은 하이라이트 (0x40FFFFFF)
```

### 3.2 변경 (To-Be) 블록 렌더링

```
PieceComponent._drawCell():
  1. 외부 글로우 (shadowColor, blurRadius: cellSize * 0.3)
  2. 그라디언트 채우기 (lightColor → baseColor, 위→아래)
  3. 내부 상단 하이라이트 (0x30FFFFFF, 상단 35% 영역)
  4. 얇은 밝은 테두리 (lightColor, alpha 0.4, strokeWidth 0.8)
```

**상세 변경 in `piece_component.dart`**:

```dart
void _drawCell(Canvas canvas, int col, int row, Color baseColor, Color lightColor, Color glowColor) {
  final inset = _cellSize * 0.06;
  final rect = RRect.fromRectAndRadius(
    Rect.fromLTWH(col * _cellSize + inset, row * _cellSize + inset,
                   _cellSize - inset * 2, _cellSize - inset * 2),
    Radius.circular(_cellSize * 0.15),
  );

  // 1. 외부 글로우 (새로 추가)
  final glowPaint = Paint()
    ..color = glowColor
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, _cellSize * 0.25);
  canvas.drawRRect(rect, glowPaint);

  // 2. 그라디언트 채우기 (기존 유지)
  final gradient = Gradient.linear(
    Offset(rect.left, rect.top), Offset(rect.left, rect.bottom),
    [lightColor, baseColor],
  );
  canvas.drawRRect(rect, Paint()..shader = gradient);

  // 3. 내부 상단 하이라이트 (영역 확대)
  final hlRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(rect.left + inset, rect.top + inset,
                   rect.width - inset * 2, rect.height * 0.35),
    Radius.circular(_cellSize * 0.12),
  );
  canvas.drawRRect(hlRect, Paint()..color = Color(0x30FFFFFF));

  // 4. 밝은 테두리 (새로 추가)
  final borderPaint = Paint()
    ..color = lightColor.withValues(alpha: 0.4)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  canvas.drawRRect(rect, borderPaint);
}
```

### 3.3 고스트 피스 변경

**현재**: 반투명 채우기 + 반투명 테두리
**변경**: 점선 외곽선 + 미세 글로우

```dart
void _drawGhostCell(Canvas canvas, int col, int row, Color color, Color glowColor) {
  // 1. 미세 글로우
  final glowPaint = Paint()
    ..color = glowColor.withValues(alpha: 0.15)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, _cellSize * 0.15);
  canvas.drawRRect(rect, glowPaint);

  // 2. 점선 외곽선 (Path + dashPath)
  final borderPaint = Paint()
    ..color = color.withValues(alpha: 0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  canvas.drawRRect(rect, borderPaint);

  // 3. 매우 연한 채우기
  canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.08));
}
```

---

## 4. 보드 렌더링 설계

### 4.1 보드 프레임

**현재**: 단색 배경 (`darkBoard`) + 얇은 그리드 라인
**변경**: 어두운 배경 + 글로우 테두리 + 미세 코너 장식

```dart
void _renderBackground(Canvas canvas) {
  // 보드 배경
  final bgPaint = Paint()..color = AppColors.darkBoard; // #161B22

  // 글로우 테두리
  final borderGlow = Paint()
    ..color = AppColors.primary.withValues(alpha: 0.25)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  // 안쪽 밝은 테두리
  final innerBorder = Paint()
    ..color = AppColors.primary.withValues(alpha: 0.15)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
}
```

### 4.2 라인 클리어 이펙트

**현재**: 화이트 플래시 페이드아웃
**변경**: Primary 컬러 글로우 웨이브 → 페이드아웃

```dart
void _renderLineClearFlash(Canvas canvas) {
  // 1. 보라색 글로우 (화이트 → 보라색)
  final glowPaint = Paint()
    ..color = AppColors.primary.withValues(alpha: alpha * 0.5)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0);

  // 2. 밝은 오버레이
  final overlayPaint = Paint()
    ..color = Color.fromRGBO(255, 255, 255, alpha * 0.4);
}
```

### 4.3 보드 배경 그라디언트 (레벨별)

```dart
// blockdrop_game.dart - backgroundColor() 변경
Color backgroundColor() {
  // 레벨에 따라 미세하게 변하는 배경 그라디언트
  // Level 1-5:  #0D1117 (순수 다크)
  // Level 6-10: #0D1117 → #0F1520 (아주 약간 블루)
  // Level 11+:  #0D1117 → #120F1F (아주 약간 퍼플)
}
```

---

## 5. 홈 화면 설계

### 5.1 레이아웃 구조 (To-Be)

```
┌──────────────────────────────┐
│         SafeArea Top         │
│                              │
│     ┌──────────────────┐     │
│     │   BLOCKDROP      │     │  ← 글로우 텍스트 + 펄스 애니메이션
│     │   Block Puzzle    │     │
│     └──────────────────┘     │
│                              │
│  ┌──────────────────────────┐│
│  │  🏆 Daily Challenge      ││  ← 글로우 보더 + 카운트다운
│  │  Clear 20 lines → 100   ││
│  └──────────────────────────┘│
│                              │
│  ┌────────┐  ┌────────┐     │
│  │CLASSIC │  │ PUZZLE │     │  ← 글로우 아이콘 + 보더
│  │Endless │  │Level 24│     │
│  │ ▶ Play │  │72 Stars│     │
│  └────────┘  └────────┘     │
│  ┌────────┐  ┌────────┐     │
│  │ SPRINT │  │  ZEN   │     │
│  │40 Lines│  │No over │     │
│  │Best:142│  │▶ Relax │     │
│  └────────┘  └────────┘     │
│                              │
│  High Score        28,900    │  ← 글로우 숫자
│                              │
│  ┌─┐  ┌─┐  ┌─┐  ┌─┐       │
│  │🏠│ │📊│ │🏪│ │👤│       │  ← 하단 네비게이션
│  └─┘  └─┘  └─┘  └─┘       │
└──────────────────────────────┘
```

### 5.2 주요 변경 사항

| 요소 | 현재 | 변경 |
|------|------|------|
| 배경 | `darkBg` 단색 | `darkBg` + 미세 래디얼 그라디언트 (중앙 약간 밝게) |
| 로고 | 흰색 텍스트 | 흰색 + `primary` 그림자 (`Shadow(color: primary, blurRadius: 20)`) |
| 카드 배경 | `darkCard` 단색 | `darkCard` + 활성 카드에 글로우 보더 |
| 카드 보더 | `color.withAlpha(0.4)` 단색 | `color.withAlpha(0.3)` 글로우 (`boxShadow`) |
| 카드 아이콘 | Material 아이콘 단색 | 아이콘 + 미세 글로우 (`Shadow`) |
| High Score | 흰색 텍스트 | `primaryLight` 컬러 + 미세 글로우 |
| Daily Banner | 보라 보더 | 보라 보더 + 글로우 + 미세 펄스 애니메이션 |

### 5.3 코드 변경 (`home_screen.dart`)

**로고 글로우 효과**:
```dart
Text(
  'BLOCKDROP',
  style: TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    letterSpacing: 6,
    color: AppColors.textLight,
    shadows: [
      Shadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 20),
      Shadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 40),
    ],
  ),
),
```

**카드 글로우 보더**:
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.darkCard,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: color.withValues(alpha: 0.3),
      width: 1.5,
    ),
    boxShadow: isEnabled ? [
      BoxShadow(
        color: color.withValues(alpha: 0.15),
        blurRadius: 12,
        spreadRadius: 0,
      ),
    ] : null,
  ),
),
```

---

## 6. 게임 HUD 설계

### 6.1 HUD 레이아웃 (To-Be)

```
┌──────────────────────────────┐
│ [⏸]  SCORE  LEVEL  LINES    │  ← SafeArea Top
│       12,450   7     42     │
├──────────────────────────────┤
│ HOLD                   NEXT  │
│ ┌─────┐             ┌─────┐ │  ← 글로우 보더 프리뷰
│ │  T  │             │  L  │ │
│ └─────┘             └─────┘ │
│                              │
│  ╔══════════════════════╗    │  ← 보드: 글로우 테두리
│  ║                      ║    │
│  ║    ■ ■               ║    │  ← 활성 피스 (글로우)
│  ║      ■               ║    │
│  ║                      ║    │
│  ║    ┈ ┈               ║    │  ← 고스트 (점선)
│  ║      ┈               ║    │
│  ║  ▓▓▓▓▓▓▓▓            ║    │  ← 잠긴 블록 (글로우)
│  ║  ▓▓▓▓▓▓▓▓▓▓          ║    │
│  ╚══════════════════════╝    │
│                              │
│  COMBO x3                    │  ← 글로우 텍스트
│  ┌──────────────────────┐    │
│  │      AD BANNER       │    │  ← 하단 광고
│  └──────────────────────┘    │
└──────────────────────────────┘
```

### 6.2 HUD 스타일 변경

| 요소 | 현재 | 변경 |
|------|------|------|
| 스코어 값 | 흰색 22px | 흰색 22px + 증가 시 미세 스케일 펄스 |
| 라벨 | 0.6 alpha 흰색 | `primaryLight` 0.5 alpha |
| Pause 버튼 | `darkCard` 0.8 alpha | `darkCard` 0.8 + `primary` 0.15 글로우 보더 |
| 콤보 텍스트 | 없음 (코드에서 처리) | 글로우 강조 텍스트 |

### 6.3 NEXT/HOLD 프리뷰 변경

```dart
// 컨테이너 변경
void _renderContainer(Canvas canvas) {
  final bgPaint = Paint()..color = AppColors.darkCard; // #21262D

  // 글로우 보더 추가
  final glowBorder = Paint()
    ..color = AppColors.primary.withValues(alpha: 0.2)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0);
}
```

---

## 7. 게임 오버 화면 설계

### 7.1 레이아웃 (To-Be)

```
┌──────────────────────────────┐
│     (반투명 다크 오버레이)     │
│                              │
│     ┌──────────────────┐     │
│     │    GAME OVER     │     │  ← 글로우 텍스트 (신기록 시 amber 글로우)
│     │                  │     │
│     │  ★ NEW BEST! ★  │     │  ← 신기록 배지 (amber 글로우 + 펄스)
│     │                  │     │
│     │  Score   12,450  │     │  ← 카운트업 애니메이션
│     │  Best    28,900  │     │  ← 신기록이면 amber 글로우
│     │  Level       7   │     │
│     │  Lines      42   │     │
│     │                  │     │
│     │ ┌──────────────┐ │     │
│     │ │    RETRY     │ │     │  ← Primary 글로우 버튼
│     │ └──────────────┘ │     │
│     │ ┌──────────────┐ │     │
│     │ │     HOME     │ │     │  ← 아웃라인 버튼
│     │ └──────────────┘ │     │
│     └──────────────────┘     │
└──────────────────────────────┘
```

### 7.2 주요 변경 사항

| 요소 | 현재 | 변경 |
|------|------|------|
| 카드 보더 | `primary` 0.3 / `amber` 0.6 | 글로우 보더 (`boxShadow` 추가) |
| "GAME OVER" | 흰색/amber 텍스트 | 글로우 Shadow 추가 |
| "NEW HIGH SCORE!" | 평문 텍스트 | 배지 스타일 + amber 글로우 + 별 장식 |
| 스코어 값 | 정적 표시 | 카운트업 애니메이션 (0 → 최종값) |
| Best 값 | 정적 표시 | 신기록이면 amber 컬러 + 글로우 |
| RETRY 버튼 | ElevatedButton 기본 | Primary 그라디언트 + 글로우 |
| 카드 배경 | `darkCard` 단색 | `darkCard` + 미세 래디얼 그라디언트 |

### 7.3 코드 변경 (`game_over_overlay.dart`)

**카드 글로우**:
```dart
decoration: BoxDecoration(
  color: AppColors.darkCard,
  borderRadius: BorderRadius.circular(24),
  border: Border.all(
    color: isNewHighScore
        ? AppColors.amber.withValues(alpha: 0.5)
        : AppColors.primary.withValues(alpha: 0.2),
    width: 1.5,
  ),
  boxShadow: [
    BoxShadow(
      color: (isNewHighScore ? AppColors.amber : AppColors.primary)
          .withValues(alpha: 0.15),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ],
),
```

**RETRY 버튼 글로우**:
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [AppColors.primary, AppColors.primaryLight],
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.4),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: // button content
),
```

**점수 카운트업 (StatefulWidget 전환)**:
```dart
// GameOverOverlay를 StatefulWidget으로 변환
// initState에서 _animateScore() 호출

void _animateScore() {
  _scoreController = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 800),
  );
  _scoreAnimation = IntTween(begin: 0, end: score)
      .animate(CurvedAnimation(parent: _scoreController!, curve: Curves.easeOut));
  _scoreController!.forward();
}
```

---

## 8. BlockColor 모델 변경

### 8.1 glowColor 추가

`lib/data/models/block_piece.dart`의 `BlockColor` enum에 `glowColor` getter 추가:

```dart
enum BlockColor {
  coral, amber, lemon, mint, sky, lavender, special;

  Color get color => switch (this) {
    coral    => const Color(0xFFEF4444),   // 변경
    amber    => const Color(0xFFF59E0B),   // 변경
    lemon    => const Color(0xFFEAB308),   // 변경
    mint     => const Color(0xFF10B981),   // 변경
    sky      => const Color(0xFF3B82F6),   // 변경
    lavender => const Color(0xFF8B5CF6),   // 변경
    special  => const Color(0xFFFFD700),   // 유지
  };

  Color get lightColor => switch (this) {
    coral    => const Color(0xFFFCA5A5),   // 변경
    amber    => const Color(0xFFFCD34D),   // 변경
    lemon    => const Color(0xFFFDE047),   // 변경
    mint     => const Color(0xFF6EE7B7),   // 변경
    sky      => const Color(0xFF93C5FD),   // 변경
    lavender => const Color(0xFFC4B5FD),   // 변경
    special  => const Color(0xFFFFD700),   // 유지
  };

  // 새로 추가
  Color get glowColor => switch (this) {
    coral    => const Color(0x40EF4444),
    amber    => const Color(0x40F59E0B),
    lemon    => const Color(0x40EAB308),
    mint     => const Color(0x4010B981),
    sky      => const Color(0x403B82F6),
    lavender => const Color(0x408B5CF6),
    special  => const Color(0x40FFD700),
  };
}
```

---

## 9. AppColors 변경 상세

```dart
class AppColors {
  AppColors._();

  // ── Block Colors (Luminous Flow) ──
  static const Color coral = Color(0xFFEF4444);
  static const Color coralLight = Color(0xFFFCA5A5);
  static const Color coralGlow = Color(0x40EF4444);

  static const Color amber = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFCD34D);
  static const Color amberGlow = Color(0x40F59E0B);

  static const Color lemon = Color(0xFFEAB308);
  static const Color lemonLight = Color(0xFFFDE047);
  static const Color lemonGlow = Color(0x40EAB308);

  static const Color mint = Color(0xFF10B981);
  static const Color mintLight = Color(0xFF6EE7B7);
  static const Color mintGlow = Color(0x4010B981);

  static const Color sky = Color(0xFF3B82F6);
  static const Color skyLight = Color(0xFF93C5FD);
  static const Color skyGlow = Color(0x403B82F6);

  static const Color lavender = Color(0xFF8B5CF6);
  static const Color lavenderLight = Color(0xFFC4B5FD);
  static const Color lavenderGlow = Color(0x408B5CF6);

  static const Color special = Color(0xFFFFD700);

  // ── Background - Dark Mode (Luminous Flow) ──
  static const Color darkBg = Color(0xFF0D1117);
  static const Color darkCard = Color(0xFF21262D);
  static const Color darkBoard = Color(0xFF161B22);
  static const Color darkGridLine = Color(0xFF30363D);

  // ── UI ──
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentLight = Color(0xFF22D3EE);

  static const Color secondary = Color(0xFF00B894);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textLight = Color(0xFFF8F9FA);
  static const Color disabled = Color(0xFF636E72);
  static const Color danger = Color(0xFFE17055);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color success = Color(0xFF00B894);

  // Ghost piece
  static const Color ghostPiece = Color(0x40FFFFFF);

  // (lightBg, lightCard, lightBoard, lightGridLine 유지)
}
```

---

## 10. 구현 순서

| 순서 | 항목 | 의존성 | 설명 |
|------|------|--------|------|
| 1 | AppColors 변경 | 없음 | 새 컬러 팔레트 적용 (모든 파일이 의존) |
| 2 | BlockColor 모델 변경 | #1 | glowColor getter 추가 |
| 3 | PieceComponent 블록 렌더링 | #1, #2 | 글로우 + 하이라이트 + 테두리 |
| 4 | BoardComponent 보드 렌더링 | #1 | 글로우 테두리, 배경, 라인 클리어 개선 |
| 5 | GhostPieceComponent | #1, #2 | 점선 외곽 + 미세 글로우 |
| 6 | NextPiecePreview / HoldPieceDisplay | #1 | 프리뷰 박스 글로우 스타일 |
| 7 | BlockDropGame 배경 | #1 | 배경색 변경 |
| 8 | HomeScreen | #1 | 홈 화면 글로우 효과 |
| 9 | GameScreen HUD | #1 | HUD 스타일 개선 |
| 10 | GameOverOverlay | #1 | 글로우 + 카운트업 + 신기록 배지 |
| 11 | PauseOverlay | #1 | 스타일 통일 |
| 12 | Pencil 디자인 리뉴얼 | 전체 | 3개 화면 Pencil 반영 |

---

## 11. Pencil 디자인 변경 명세

### 11.1 공통 변경

| 속성 | 현재 | 변경 |
|------|------|------|
| 화면 배경색 | `#1A1B2E` | `#0D1117` |
| 카드 배경색 | `#252742` | `#21262D` |
| 보드 배경색 | `#2D2F4E` | `#161B22` |
| 그리드 라인색 | `#3A3C5E` | `#30363D` |
| Primary | `#6C5CE7` | `#7C3AED` |

### 11.2 홈 화면 (KEjqr)

- 배경색 → `#0D1117`
- 로고 텍스트 → 흰색 + 보라 글로우 효과 (Shadow)
- 카드 배경 → `#21262D`
- 활성 카드 보더 → 각 컬러 0.3 alpha + 글로우 효과
- Daily Challenge 배너 → `#7C3AED` 보더 글로우
- High Score 숫자 → `#A78BFA` (primaryLight)

### 11.3 게임 화면 (im5at)

- 배경색 → `#0D1117`
- 보드 배경 → `#161B22` + `#7C3AED40` 글로우 테두리
- 블록 → 더 선명한 컬러 + 외부 글로우 효과 표현
- 고스트 피스 → 얇은 테두리만 (채우기 최소화)
- HOLD/NEXT 박스 → `#21262D` + 글로우 보더
- HUD 라벨 → `#A78BFA` 80% alpha
- COMBO 텍스트 → `#7C3AED` 글로우

### 11.4 게임 오버 화면 (R9kGF)

- 배경 오버레이 → `#000000` 75% alpha
- 카드 → `#21262D` + `#7C3AED` 글로우 보더
- "GAME OVER" → 글로우 텍스트
- 스코어 값 → 흰색, 신기록이면 amber 글로우
- RETRY 버튼 → `#7C3AED` → `#A78BFA` 그라디언트 + 글로우 shadow
- HOME 버튼 → 아웃라인 유지, 보더 `#A78BFA` 0.3 alpha

---

## 12. 성공 기준

| 지표 | 목표 | 측정 방법 |
|------|------|----------|
| 시각적 세련도 | Pencil 디자인에서 "Luminous Flow" 컨셉 구현 | 3개 화면 스크린샷 비교 |
| 블록 가시성 | 6가지 블록 컬러 + special 모두 구분 가능 | 게임 화면에서 시각 확인 |
| 컬러 일관성 | 3개 화면 동일 컬러 팔레트 사용 | AppColors 단일 소스 |
| 글로우 효과 | 블록, 보드 테두리, 버튼, 텍스트에 글로우 적용 | 렌더링 코드 확인 |
| 코드 호환성 | 기존 게임 로직 변경 없음, 렌더링만 변경 | flutter analyze 통과 |

---

> **Next Step**: Pencil 디자인 리뉴얼 (3개 화면) → 코드 구현 (`/pdca do ui-redesign`)
