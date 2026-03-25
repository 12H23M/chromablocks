# ChromaBlocks 중독성 분석 — Game Director Report

> 작성일: 2026-03-25  
> 작성자: Game Director Analysis (Opus)  
> 핵심 질문: "왜 계속 하고 싶은 생각이 안 드는가?"

---

## 1. Executive Summary

ChromaBlocks는 기술적으로 완성도가 높다. Chroma Chain, Chroma Blast, 콤보 시스템, DDA, 히트스톱, 햅틱 피드백까지 — **메커닉은 충분하다.** 그런데 "한판만 더"가 안 나온다.

**근본 원인: 게임이 플레이어에게 "다음에는 더 잘할 수 있다"는 확신을 주지 못한다.**

Block Blast가 월 5천만 DAU를 유지하는 건 메커닉이 뛰어나서가 아니라, **매 판마다 "아 그때 거기 놓았으면 됐는데"라는 후회를 만들기 때문**이다. 후회 = 재도전 욕구. ChromaBlocks에는 이 후회가 없다.

---

## 2. 5 Whys 분석

### Why 1: "왜 계속 하고 싶지 않은가?"
→ 게임이 끝났을 때 **"다음에는 더 잘할 수 있다"는 느낌이 없다.**

### Why 2: "왜 다음에 더 잘할 수 있다는 느낌이 없는가?"
→ **내 실력이 결과에 영향을 준다는 체감이 약하다.** Chroma Chain/Blast는 "의도적으로" 만들기 어렵고, 콤보는 운에 가깝다. 게임 오버가 "내 실수" 때문이 아니라 "피스가 안 맞아서"처럼 느껴진다.

### Why 3: "왜 내 실력이 결과에 영향을 준다는 체감이 약한가?"
→ **전략적 의사결정의 피드백 루프가 느리고 불명확하다.**
- 8x8 보드에 6색 + 30% 프리필 = 보드 상태가 혼돈에 가까움
- Chain/Blast 조건(5연결/6동색)이 보드를 읽는 것만으로 파악하기 어려움
- 좋은 수를 뒀는지 나쁜 수를 뒀는지 즉시 알 수 없음

### Why 4: "왜 피드백 루프가 느리고 불명확한가?"
→ **게임이 "라인 클리어"라는 명확한 목표 대신 너무 많은 보조 시스템에 의존한다.** 라인 클리어 → 체인 → 블라스트 → 콤보까지 복합 점수 체계가 숙련 플레이어에겐 깊이지만, 대부분의 플레이어에겐 **"뭘 해야 점수가 오르는지 모르겠다"**로 느껴진다.

### Why 5: "왜 보조 시스템이 문제인가?"
→ **핵심 루프(놓기→클리어→쾌감)의 빈도와 강도가 경쟁작 대비 낮다.**
- Block Blast: 한 줄 클리어까지 평균 3-4수 → 빠른 도파민
- ChromaBlocks: 30% 프리필에서 시작하면 첫 클리어까지 도달이 불확실
- 클리어 빈도가 낮으니 콤보 기회도 적고, 체인/블라스트는 더더욱 드물다

### 근본 원인 (Root Cause)
> **"기본 루프(놓기→클리어→보상)의 빈도가 낮고, 플레이어의 의도적 전략이 보상으로 연결되는 경로가 불투명하다."**

---

## 3. 경쟁작 비교 — 우리에게 없는 중독 요소

### 3-1. Block Blast와의 비교

| 중독 요소 | Block Blast | ChromaBlocks | 갭 |
|-----------|------------|--------------|-----|
| **첫 클리어까지 수** | 3-4수 (빈 보드 시작) | 불확실 (30% 프리필) | 🔴 Critical |
| **클리어 빈도** | 높음 (8x8 빈 시작) | 낮음 (30% 프리필+복잡 조건) | 🔴 Critical |
| **"아 거기 놓을걸" 후회** | 매판 발생 | 거의 없음 | 🔴 Critical |
| **점수=실력 체감** | 높음 (단순 라인 클리어) | 낮음 (복합 시스템) | 🟡 High |
| **하이스코어 추격** | 강력한 동기 | 약함 (의미 불명확) | 🟡 High |
| **세션 길이 예측** | 5-10분 | 불확실 | 🟡 High |
| **near-miss 체험** | 자주 (1칸 부족으로 게임오버) | 드물게 | 🟡 High |

### 3-2. Woodoku와의 비교

| 중독 요소 | Woodoku | ChromaBlocks | 갭 |
|-----------|---------|--------------|-----|
| **스트릭 시스템** | 🔥 연속 클리어 스트릭 (연소 효과) | 없음 | 🔴 Critical |
| **3x3 박스 보너스** | 추가 목표 = 전략 깊이 | 없음 (단순 행/열만) | 🟡 High |
| **일일 목표** | 매일 달성 과제 | 일일 챌린지 있지만 약함 | 🟢 Exists |
| **메타 진행** | 스코어보드 + 스트릭 | 업적 있지만 인게임 노출 약함 | 🟡 High |

### 3-3. 1010!과의 비교

| 중독 요소 | 1010! | ChromaBlocks | 갭 |
|-----------|-------|--------------|-----|
| **극단적 단순함** | 규칙 3초 이해 | Chain/Blast 학습 필요 | 🟡 High |
| **빈 보드 시작** | ✅ 깨끗한 캔버스 | ❌ 30% 프리필 | 🔴 Critical |
| **게임오버=내 실수** | 100% 확실 | 애매함 | 🔴 Critical |

### 3-4. 종합: 우리에게 없는 핵심 중독 요소 TOP 7

1. **🔴 빈 보드 시작 → 첫 클리어의 빠른 도달** (Block Blast, 1010!)
2. **🔴 "내 실수"로 느껴지는 게임오버** (전 경쟁작)
3. **🔴 연속 클리어 스트릭/보상** (Woodoku의 🔥)
4. **🟡 명확한 "다음 목표"가 항상 화면에 보임** (Blockudoku의 레벨바)
5. **🟡 게임 오버 시 "이번 판 하이라이트"** (재도전 동기)
6. **🟡 점수의 사회적 의미** (리더보드/공유)
7. **🟡 세션 간 메타 진행 체감** (업적이 게임 중에 보이지 않음)

---

## 4. 구체적 해결책

---

### P0: 즉시 적용 (이번 주 내)

#### P0-1. 프리필 제거 또는 대폭 축소
**문제:** 30% 프리필은 "쌓아가는 재미"를 박탈한다.  
**해결:** 빈 보드 시작 (또는 최대 10%, 1-2개 소규모 클러스터만)

```gdscript
# game_constants.gd — 변경 제안
# 기존: _prefill_board()에서 30% 채움
# 변경: 프리필 비율을 상수로 분리하고 10% 이하로

const PREFILL_RATIO: float = 0.0  # 0% = 빈 보드 시작 (Block Blast 방식)
# 또는 0.10 (약간의 시드만 제공)
```

```gdscript
# chroma_blocks_game.gd — _prefill_board() 수정
func _prefill_board(board: BoardState) -> void:
    if GameConstants.PREFILL_RATIO <= 0.0:
        return  # 빈 보드 시작!
    
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var target_cells := int(board.rows * board.columns * GameConstants.PREFILL_RATIO)
    # ... 기존 로직 유지하되 target_cells만 줄어듦
```

**기대효과:**
- 첫 클리어까지 3-5수 → 빠른 첫 도파민
- "내가 쌓은 보드"에서 클리어 = 성취감 ↑
- 게임오버 = "내 선택의 결과" 체감 ↑

**위험:** 초반이 심심할 수 있음 → P0-2로 보완

---

#### P0-2. 첫 트레이에 "선물 피스" 보장
**문제:** 빈 보드에서 시작하면 초반 전략이 없어 지루할 수 있음  
**해결:** 첫 트레이에 반드시 큰 피스(LARGE/HUGE) 1개 + 라인 완성하기 좋은 조합 제공

```gdscript
# piece_generator.gd — generate_tray() 수정
func generate_tray(level: int, board: BoardState) -> Array:
    var excluded := _get_excluded_for_level(level)
    var fill := _board_fill_ratio(board)
    
    # ★ NEW: 빈 보드(첫 수)일 때 Rush 템플릿 강제
    if fill < 0.05:  # 거의 빈 보드
        return _generate_rush_tray(board, level)
    
    # ... 기존 로직
```

```gdscript
func _generate_rush_tray(board: BoardState, level: int) -> Array:
    # 첫 트레이: HUGE + MEDIUM + SMALL 조합으로 
    # 빠른 라인 클리어 가능하게
    var tray: Array = []
    var color_count := _get_color_count(level)
    
    # 큰 피스 하나 (3x3 or 2x3)
    var big_pool := CATEGORY_PIECES[SizeCat.HUGE].duplicate()
    big_pool.shuffle()
    var big_type: int = big_pool[0]
    var big_shape: Array = PieceDefinitions.SHAPES[big_type]
    var first_color := _rng.randi_range(0, color_count - 1)
    tray.append(BlockPiece.new(big_type, first_color, big_shape))
    
    # 중간 피스 하나
    var med_pool := CATEGORY_PIECES[SizeCat.MEDIUM].duplicate()
    med_pool.shuffle()
    var med_type: int = med_pool[0]
    var med_shape: Array = PieceDefinitions.SHAPES[med_type]
    tray.append(BlockPiece.new(med_type, first_color, med_shape))  # 같은 색 = 체인 기대감
    
    # 작은 피스 하나
    var sm_pool := CATEGORY_PIECES[SizeCat.SMALL].duplicate()
    sm_pool.shuffle()
    var sm_type: int = sm_pool[0]
    var sm_shape: Array = PieceDefinitions.SHAPES[sm_type]
    tray.append(BlockPiece.new(sm_type, _rng.randi_range(0, color_count - 1), sm_shape))
    
    return tray
```

**기대효과:** 첫 트레이에서 "와 큰 거 왔다!" → 어디에 놓을지 고민하는 재미 즉시 시작

---

#### P0-3. 연속 클리어 스트릭 시스템 (Woodoku의 🔥)
**문제:** 콤보 시스템은 있지만, "연속으로 라인을 클리어했다"는 시각적 보상이 없다.  
**해결:** 피스를 놓을 때마다 라인을 클리어하면 스트릭 카운터 증가. 못 하면 리셋.

```gdscript
# game_state.gd — 추가
var clear_streak: int = 0       # 연속 클리어 횟수
var best_streak: int = 0        # 이번 판 최고 스트릭
```

```gdscript
# chroma_blocks_game.gd — _place_piece() 내부, scoring 후
# 기존 combo와 별개로, "연속으로 라인을 클리어했느냐"를 추적
var did_any_clear: bool = clear_result["lines_cleared"] > 0 or chain_result["total_cells_cleared"] > 0 or blast_executed["cells_removed"] > 0

if did_any_clear:
    _state.clear_streak += 1
    if _state.clear_streak > _state.best_streak:
        _state.best_streak = _state.clear_streak
else:
    _state.clear_streak = 0  # 리셋!

# 스트릭 보너스 점수
var streak_bonus: int = 0
if _state.clear_streak >= 3:
    streak_bonus = _state.clear_streak * 50  # 3연속=150, 5연속=250...
    score_result["total"] += streak_bonus
```

```gdscript
# HUD에 스트릭 표시 — hud.gd에 추가
# 🔥 x5 형태로 3 이상일 때만 표시
func _update_streak_display(streak: int) -> void:
    if streak >= 3:
        streak_label.text = "🔥 x%d" % streak
        streak_label.visible = true
        # 펄스 애니메이션
        var tween := create_tween()
        tween.tween_property(streak_label, "scale", Vector2(1.3, 1.3), 0.1)
        tween.tween_property(streak_label, "scale", Vector2(1.0, 1.0), 0.15)
    else:
        streak_label.visible = false
```

**기대효과:**
- "스트릭 끊기기 싫다" → 더 신중하게 플레이 → 몰입 ↑
- 스트릭이 쌓일수록 긴장감 → 끊기면 "아 아까웠는데" → 재도전
- **이것이 Woodoku의 핵심 중독 메커니즘**

---

#### P0-4. 게임 오버 화면 "후회 유발" 리디자인
**문제:** 현재 게임 오버 화면이 결과만 보여주고 끝. "다시 하면 더 잘할 수 있다"는 동기 없음.  
**해결:** 게임 오버 시 "이번 판 하이라이트" + "아쉬운 순간" 표시

```gdscript
# game_over_screen.gd — show_result() 확장
func show_result(state: GameState) -> void:
    # 기존 점수 표시 유지
    
    # ★ NEW: 이번 판 하이라이트
    var highlights: Array = []
    
    if state.best_streak >= 3:
        highlights.append("🔥 최고 연속 클리어: %d회" % state.best_streak)
    
    if state.max_combo >= 2:
        highlights.append("⚡ 최대 콤보: x%d" % state.max_combo)
    
    if state.chains_triggered > 0:
        highlights.append("💎 크로마 체인: %d회" % state.chains_triggered)
    
    if state.lines_cleared >= 10:
        highlights.append("📊 총 %d줄 클리어" % state.lines_cleared)
    
    # ★ NEW: "다음 목표" 표시
    var next_goal := _get_next_goal(state)
    # 예: "하이스코어까지 1,200점 남았어요!"
    # 또는 "다음 업적: 5콤보 달성 (현재 최대 3)"
    
    # ★ NEW: 하이스코어 갱신 여부에 따른 차별화
    if state.score > state.high_score:
        _show_new_record_celebration(state.score)
    else:
        var diff := state.high_score - state.score
        _show_near_miss("하이스코어까지 %s점!" % FormatUtils.comma_number(diff))
```

```gdscript
func _get_next_goal(state: GameState) -> String:
    # 가장 가까운 미달성 업적 찾기
    var goals: Array = [
        {"id": "score_1000", "check": state.score, "target": 1000, "text": "1,000점 돌파"},
        {"id": "score_5000", "check": state.score, "target": 5000, "text": "5,000점 돌파"},
        {"id": "combo_3", "check": state.max_combo, "target": 3, "text": "3콤보 달성"},
        {"id": "combo_5", "check": state.max_combo, "target": 5, "text": "5콤보 달성"},
    ]
    
    for goal in goals:
        if not AchievementSystem.is_unlocked(goal["id"]):
            var progress := float(goal["check"]) / float(goal["target"])
            if progress >= 0.5:  # 50% 이상 달성한 목표만 보여줌 (달성 가능성 체감)
                return "다음 목표: %s (%d%%)" % [goal["text"], int(progress * 100)]
    
    return ""
```

**기대효과:**
- "하이스코어까지 1,200점이었네... 한 판 더!" → 즉시 재도전
- "5콤보까지 한 번만 더 하면 되는데..." → 목표 추격

---

### P1: 이번 주 (3-5일 내)

#### P1-1. 점수 마일스톤 시스템
**문제:** 점수가 올라가는 것 자체에 의미가 없다. 숫자만 커질 뿐.  
**해결:** 특정 점수 도달 시 인게임 축하 이펙트 + 마일스톤 배지

```gdscript
# game_constants.gd — 추가
const SCORE_MILESTONES: Array = [
    500, 1000, 2000, 3000, 5000, 7500, 10000, 
    15000, 20000, 30000, 50000, 75000, 100000
]
```

```gdscript
# chroma_blocks_game.gd — _place_piece() 내부, 점수 업데이트 후
func _check_score_milestones(old_score: int, new_score: int) -> void:
    for milestone in GameConstants.SCORE_MILESTONES:
        if old_score < milestone and new_score >= milestone:
            _celebrate_milestone(milestone)
            break  # 한 번에 하나만

func _celebrate_milestone(milestone: int) -> void:
    # 짧은 축하 (200ms, 게임 중단 없이)
    var popup := Control.new()
    popup.set_script(preload("res://scripts/game/milestone_popup.gd"))
    var overlay_layer := CanvasLayer.new()
    overlay_layer.layer = 22
    add_child(overlay_layer)
    overlay_layer.add_child(popup)
    var board_center := board_renderer.global_position + board_renderer.size / 2.0
    popup.show_milestone(milestone, board_center)
    popup.tree_exited.connect(overlay_layer.queue_free)
    
    SoundManager.play_sfx("milestone")
    HapticManager.medium()
```

**기대효과:** "5,000점 돌파!" → 작은 성취감 → "10,000점까지 가보자" → 목표 형성

---

#### P1-2. Near-Miss 피드백 강화
**문제:** 게임 오버 시 "왜 졌는지" 모르겠다.  
**해결:** 게임 오버 직전 상태에서 "만약 이 피스가 왔다면..." 시각화

```gdscript
# game_over_screen.gd — 게임 오버 시 near-miss 정보
func _show_board_analysis(board: BoardState, tray: Array) -> void:
    # 1. 가장 많이 찬 행/열 찾기 (1-2칸만 비어있는)
    var near_rows: Array = []
    for y in board.rows:
        var empty_count := 0
        for x in board.columns:
            if not board.grid[y][x]["occupied"]:
                empty_count += 1
        if empty_count <= 2 and empty_count > 0:
            near_rows.append({"row": y, "empty": empty_count})
    
    if not near_rows.is_empty():
        # "7번째 줄이 1칸만 더 있었으면 클리어였어요!"
        var closest = near_rows[0]
        near_miss_label.text = "%d번째 줄: %d칸만 더 채웠으면! 😱" % [
            closest["row"] + 1, closest["empty"]]
        near_miss_label.visible = true
```

**기대효과:** "1칸만 더 있었으면 됐는데!!" → 강렬한 후회 → 즉시 재도전

---

#### P1-3. 인게임 진행 바 (레벨 + 다음 레벨까지)
**문제:** 레벨 시스템이 있지만 인게임에서 거의 느껴지지 않는다.  
**해결:** HUD 상단에 얇은 진행 바 추가

```gdscript
# hud.gd — 레벨 진행 바 추가
func update_from_state(state: GameState) -> void:
    # 기존 업데이트 유지
    
    # ★ NEW: 레벨 진행 바
    var lines_for_current := 0
    var temp_lines := state.lines_cleared
    for lv in range(1, state.level):
        temp_lines -= GameConstants.lines_for_next_level(lv)
    var needed := GameConstants.lines_for_next_level(state.level)
    var progress := clampf(float(temp_lines) / float(needed), 0.0, 1.0)
    
    level_label.text = "Lv.%d" % state.level
    level_progress_bar.value = progress
    
    # 레벨업 직전이면 바 색상 강조
    if progress >= 0.8:
        level_progress_bar.modulate = Color(1.0, 0.8, 0.2)  # 골드
    else:
        level_progress_bar.modulate = Color(1.0, 1.0, 1.0)
```

**기대효과:** "레벨업까지 2줄만 더..." → 단기 목표 형성 → 플로우 유지

---

#### P1-4. "한판만 더" 트리거 — 게임 오버 후 즉시 재시작 UX
**문제:** 게임 오버 → 결과 확인 → Play Again 버튼 → 로딩 = 3단계. 재시작 마찰이 크다.  
**해결:** 아래로 스와이프 = 즉시 재시작 (0.5초 내)

```gdscript
# game_over_screen.gd — 빠른 재시작
func _ready() -> void:
    # ... 기존 코드
    
    # 스와이프 업 감지 (또는 화면 아무데나 탭)
    set_process_input(true)

func _input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventScreenDrag:
        if event.velocity.y < -500:  # 빠른 위로 스와이프
            _quick_restart()

func _quick_restart() -> void:
    # 결과 화면 생략, 바로 게임 시작
    HapticManager.light()
    play_again_pressed.emit()
```

추가로, 결과 화면에 **"탭하면 재시작"** 텍스트를 하단에 표시 (2초 후에 나타나도록):

```gdscript
# 결과 표시 2초 후 "탭하면 재시작" 안내 페이드인
get_tree().create_timer(2.0).timeout.connect(func():
    quick_restart_hint.visible = true
    var tween := create_tween()
    tween.tween_property(quick_restart_hint, "modulate:a", 1.0, 0.5)
)
```

**기대효과:** 재시작 마찰 3단계 → 1단계. "한판만 더"의 물리적 장벽 제거

---

#### P1-5. 콤보 시스템 시각적 가이드
**문제:** 콤보가 "연속 클리어"인지, "동시 클리어"인지 직관적이지 않다.  
**해결:** 콤보 활성 중일 때 보드 테두리에 시각적 표시

```gdscript
# board_renderer.gd — 콤보 활성 표시
func update_combo_border(combo: int) -> void:
    if combo >= 1:
        # 보드 테두리에 글로우 이펙트 (콤보 수에 따라 강도 증가)
        var intensity := minf(combo * 0.15, 0.8)
        var color := Color(1.0, 0.8, 0.2, intensity)  # 골드
        _set_border_glow(color)
        
        # "다음 클리어도 하면 콤보 유지!" 암시
        if combo >= 2:
            _show_combo_timer_hint()  # 콤보 유지 가능 상태 표시
    else:
        _clear_border_glow()
```

**기대효과:** 콤보 상태의 시각적 인지 → "지금 콤보 중이니까 빨리 클리어해야 해!" → 긴장감

---

### P2: 다음 주

#### P2-1. 세션 간 메타 진행 — "플레이어 프로필"
**문제:** 매 판이 독립적. 100판을 해도 1판과 달라지는 게 없다.  
**해결:** 누적 통계 기반 "플레이어 레벨" + 언락 요소

```gdscript
# player_profile.gd — 새 파일
class_name PlayerProfile

const XP_PER_LINE: int = 10
const XP_PER_COMBO: int = 25
const XP_PER_GAME: int = 50
const XP_TABLE: Array = [
    0, 100, 250, 500, 800, 1200, 1800, 2500, 3500, 5000,  # Lv 1-10
    7000, 9500, 12500, 16000, 20000, 25000, 31000, 38000, 46000, 55000,  # Lv 11-20
]

static func add_game_xp(score: int, lines: int, max_combo: int) -> Dictionary:
    var xp_gain := XP_PER_GAME
    xp_gain += lines * XP_PER_LINE
    xp_gain += max_combo * XP_PER_COMBO
    xp_gain += score / 100  # 점수 보너스
    
    var current_xp: int = SaveManager.get_value("profile", "xp", 0)
    var old_level := _level_for_xp(current_xp)
    current_xp += xp_gain
    var new_level := _level_for_xp(current_xp)
    
    SaveManager.set_value("profile", "xp", current_xp)
    SaveManager.flush()
    
    return {
        "xp_gain": xp_gain,
        "total_xp": current_xp,
        "old_level": old_level,
        "new_level": new_level,
        "leveled_up": new_level > old_level,
    }

static func _level_for_xp(xp: int) -> int:
    for i in range(XP_TABLE.size() - 1, -1, -1):
        if xp >= XP_TABLE[i]:
            return i + 1
    return 1
```

**언락 제안:**
- Lv 3: 새 배경 테마 1
- Lv 5: 새 블록 스킨
- Lv 8: 새 배경 테마 2  
- Lv 10: 새 SFX 팩
- Lv 15: 프리미엄 파티클 이펙트
- Lv 20: 골드 블록 스킨

**기대효과:** "레벨 10까지 올려서 그 스킨 쓰고 싶다" → 장기 동기

---

#### P2-2. "오늘의 베스트" 시스템
**문제:** 하이스코어는 하나뿐. 갱신이 어려워지면 목표 상실.  
**해결:** "오늘의 최고 점수"를 별도 추적

```gdscript
# save_manager.gd — 추가 함수
static func save_today_score(score: int) -> bool:
    var today := DailyChallengeSystem.get_today_seed()
    var key := "daily_best_%d" % today
    var current: int = get_value("daily_scores", key, 0)
    if score > current:
        set_value("daily_scores", key, score)
        flush()
        return true
    return false
```

```gdscript
# home_screen.gd — 표시
func refresh_stats() -> void:
    # 기존 코드
    
    # ★ NEW: 오늘의 최고 점수
    var today_best := SaveManager.get_today_best()
    if today_best > 0:
        today_best_label.text = "오늘 베스트: %s" % FormatUtils.comma_number(today_best)
    else:
        today_best_label.text = "오늘 첫 판을 시작해보세요!"
```

**기대효과:**
- 매일 리셋되는 목표 = 매일 새로운 도전
- 올타임 하이스코어가 너무 높아도 "오늘의 베스트"는 매일 달성 가능

---

#### P2-3. 게임 오버 시 "리플레이 가치" 표시
**문제:** 왜 다시 해야 하는지 모르겠다.  
**해결:** 게임 오버 화면에 여러 동기부여 요소를 랜덤 표시

```gdscript
# game_over_screen.gd
const RETRY_HOOKS: Array = [
    "try_beat_score",      # "이 점수 깰 수 있을 것 같은데?"
    "streak_potential",    # "이번엔 5연속 클리어 도전!"
    "near_level_up",       # "플레이어 레벨업까지 50XP!"
    "achievement_close",   # "업적 '5콤보' 달성까지 78%"
    "daily_best_chase",    # "오늘 베스트까지 800점!"
]

func _pick_retry_hook(state: GameState) -> String:
    # 현재 상태에서 가장 설득력 있는 훅 선택
    var hooks: Array = []
    
    # 하이스코어 근접
    if state.score >= state.high_score * 0.7:
        hooks.append({"type": "score", "weight": 3.0,
            "text": "하이스코어(%s)까지 %s점!" % [
                FormatUtils.comma_number(state.high_score),
                FormatUtils.comma_number(state.high_score - state.score)]})
    
    # 업적 근접
    var next_achievement := _get_nearest_achievement(state)
    if next_achievement:
        hooks.append({"type": "achievement", "weight": 2.0,
            "text": "'%s' 달성까지 %d%%!" % [next_achievement.name, next_achievement.progress]})
    
    # 플레이어 레벨업 근접
    var xp_to_next := PlayerProfile.xp_to_next_level()
    if xp_to_next < 100:
        hooks.append({"type": "level", "weight": 4.0,
            "text": "레벨업까지 %dXP만 더!" % xp_to_next})
    
    # 가중치 기반 랜덤 선택
    return _weighted_random(hooks)
```

**기대효과:** 매번 다른 "이유"를 제시 → 변동 보상 원리로 재도전 유도

---

#### P2-4. Chroma Chain/Blast 튜토리얼 개선
**문제:** Chain과 Blast가 뭔지 모르는 채로 플레이하는 유저가 많을 것.  
**해결:** 첫 발동 시 슬로모션 + 설명 오버레이 (1회만)

```gdscript
# chroma_blocks_game.gd — 체인 첫 발동 시
func _on_first_chain_trigger() -> void:
    if SaveManager.get_value("tutorial", "chain_shown", false):
        return
    
    # 시간 슬로다운
    Engine.time_scale = 0.3
    
    # 체인 설명 오버레이
    var tutorial := Control.new()
    tutorial.set_script(preload("res://scripts/ui/chain_tutorial_popup.gd"))
    # "같은 색 블록 5개가 연결되면 크로마 체인! 💎"
    # [알겠어요] 버튼 → Engine.time_scale = 1.0
    
    SaveManager.set_value("tutorial", "chain_shown", true)
    SaveManager.flush()
```

**기대효과:** "아 이렇게 하면 체인이 발동되는구나!" → 의도적 플레이 가능 → 전략적 재미 ↑

---

#### P2-5. 보드 밀도 기반 배경 분위기 변화
**문제:** 위기 상황의 긴장감이 부족하다.  
**해결:** fill ratio에 따른 점진적 배경/음악 변화

```gdscript
# chroma_blocks_game.gd — 이미 _update_bgm_intensity가 있음
# 이것을 시각적으로도 확장

func _update_atmosphere(board: BoardState) -> void:
    var fill := board.fill_ratio()
    
    if fill > 0.75:
        # 위기: 보드 가장자리에 붉은 바이닝 펄스
        board_renderer.set_crisis_intensity(1.0)
        # 배경 미세하게 붉은 톤으로 쉬프트
    elif fill > 0.55:
        # 긴장: 보드 가장자리에 약한 주황 글로우
        board_renderer.set_crisis_intensity(0.3)
    else:
        board_renderer.set_crisis_intensity(0.0)
```

**기대효과:** "보드가 빨갛게 변하고 있어... 빨리 클리어해야 해!" → 긴장감과 안도감의 사이클

---

## 5. 우선순위 종합 로드맵

```
┌─────────────────────────────────────────────────────────────────┐
│                    P0: 즉시 (1-2일)                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │
│  │ 프리필    │ │ 첫 트레이 │ │ 스트릭   │ │ 게임오버 리디자인 │   │
│  │ 제거     │ │ 선물 피스 │ │ 🔥 시스템 │ │ + 후회 유발      │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘   │
│  → 핵심 루프 개선: 빈보드→빠른클리어→스트릭→후회→재도전           │
├─────────────────────────────────────────────────────────────────┤
│                    P1: 이번 주 (3-5일)                           │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │ 마일스톤 │ │ Near-miss│ │ 레벨 바  │ │ 빠른     │          │
│  │ 축하     │ │ 피드백   │ │ HUD     │ │ 재시작   │          │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
│  → 목표감 강화 + 재시작 마찰 제거                                │
├─────────────────────────────────────────────────────────────────┤
│                    P2: 다음 주                                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │ 메타 진행│ │ 오늘의   │ │ 리트라이 │ │ Chain/   │          │
│  │ XP 시스템│ │ 베스트   │ │ 훅      │ │ Blast 튜│          │
│  └──────────┘ └──────────┘ └──────────┘ │ 토리얼   │          │
│                                          └──────────┘          │
│  → 장기 리텐션 + 학습 경로                                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. 핵심 메트릭 변화 예측

| 지표 | 현재 (추정) | P0 후 | P1+P2 후 | 목표 |
|------|-----------|-------|---------|------|
| **첫 클리어까지 수** | 5-8수 | 3-4수 | 3-4수 | ≤4수 |
| **평균 세션 시간** | 3-4분 | 5-7분 | 7-10분 | 8분+ |
| **즉시 재시작율** | ~15% | ~30% | ~45% | 40%+ |
| **D1 리텐션** | ~20% | ~30% | ~40% | 35%+ |
| **스트릭 3+ 빈도** | 없음 | ~20% | ~25% | 20%+ |
| **콤보 3+ 빈도** | ~5% | ~8% | ~12% | 10%+ |

---

## 7. 결론: "한판만 더"를 만드는 3가지 핵심

### 1. **빠른 첫 보상** (P0-1, P0-2)
프리필을 제거하고 빈 보드에서 시작하면, 플레이어가 3-4수 만에 첫 라인 클리어를 경험한다. 이것이 세션의 첫 도파민이다. Block Blast가 매일 5천만 명을 유지하는 비밀은 이 "3수 만에 찾아오는 첫 쾌감"에 있다.

### 2. **잃기 싫은 것을 만들어라** (P0-3)
스트릭 시스템은 "이미 쌓아놓은 것"을 만든다. 🔥x5 스트릭이 쌓이면 플레이어는 "이거 끊기면 안 돼"라고 생각한다. 콤보보다 스트릭이 더 강력한 이유: 콤보는 "잘하면 생기는 것"이지만 스트릭은 "못하면 잃는 것"이다. **손실 회피(Loss Aversion)가 이득 추구보다 2배 강력하다** (Kahneman & Tversky, 1979).

### 3. **후회를 만들어라** (P0-4, P1-2)
게임 오버 시 "1칸만 더 있었으면 클리어였어요!"를 보여주는 것은 단순한 UI가 아니다. 이것은 **"다음에는 그 실수를 안 하면 된다"는 확신을 심는 것**이다. 확신 = 재도전 = "한판만 더".

---

> **최종 한줄:** ChromaBlocks의 메커닉은 충분하다. 부족한 건 **"빠른 첫 보상 → 잃기 싫은 스트릭 → 후회하는 게임오버"라는 감정의 3단 사이클**이다. P0만 적용해도 체감이 완전히 달라질 것이다.
