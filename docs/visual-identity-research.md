# ChromaBlocks — Visual Identity Redesign

> 작성일: 2026-03-24  
> 대상: 8×8 블록 퍼즐 게임 · Godot 4.6 · 393×852px (세로)  
> 목표: "주말 취미 프로젝트" → "앱스토어에서 돈 주고 살 것 같은" 수준으로

---

## 1. 시장 리서치 요약

### 2024–2026 모바일 퍼즐 게임 비주얼 트렌드

| 트렌드 | 설명 | 대표작 |
|---------|------|--------|
| **소프트 3D / 2.5D** | 평면 블록에 미묘한 깊이감, 부드러운 그림자, inner glow | Block Blast, Toon Blast |
| **파스텔 네온** | 채도 70-85% 범위의 밝고 깨끗한 컬러 + 어두운 배경 대비 | 1010!, Hexa Sort |
| **글래스모피즘** | 반투명 UI 패널, 블러 배경, 유리 질감 보드 | Royal Match UI |
| **마이크로 애니메이션** | idle bounce, 매치 시 파티클, 점수 팝업 ease-out | 거의 모든 Top 50 |
| **미니멀 + 프리미엄** | 요소 수 최소화, 여백 활용, 고급 타이포 | Monument Valley 계열 |

### 앱스토어 Top 퍼즐 게임 공통 비주얼 요소

1. **배경**: 단색 다크 or 그라디언트 (남색~다크블루 계열이 압도적)
2. **블록**: 라운드 코너 (12-20% radius), 내부 하이라이트, 미세한 그림자
3. **보드**: 배경보다 약간 밝은 반투명 영역으로 구분
4. **색상 수**: 5-7색, 서로 120° 이상 떨어진 색상환 배치
5. **폰트**: Geometric Sans (Poppins, Nunito, Inter) 계열 — Fredoka는 "귀여운 어린이" 느낌
6. **아이콘**: 블록 4개 조합 + 밝은 배경 그라디언트

### "프리미엄 무료 게임" 느낌을 만드는 핵심 요소

- ✅ **일관된 그림자 시스템** (모든 요소에 동일 방향 · 동일 blur)
- ✅ **제한된 컬러 팔레트** (UI는 2색 이내, 게임 오브젝트만 다채로움)
- ✅ **타이포 위계** (명확한 3단계: 제목/본문/캡션)
- ✅ **여백** (빽빽하지 않음, 보드 주변 최소 16px 마진)
- ✅ **미세한 텍스처** (완전 flat보다 노이즈 0.5-2% 추가)
- ❌ 과도한 그라디언트, 무지개 배경, 반짝이 효과 = "광고 게임" 느낌

---

## 2. 컬러 시스템 제안

### 공통 구조

| 역할 | 설명 |
|------|------|
| `bg_primary` | 화면 배경 (가장 어두운 색) |
| `bg_secondary` | 상단/하단 UI 영역 |
| `board_bg` | 보드 배경 |
| `cell_empty` | 빈 셀 |
| `block_1` ~ `block_7` | 블록 7색 |
| `accent` | 점수, 콤보, CTA 버튼 |
| `text_primary` | 주요 텍스트 |
| `text_secondary` | 보조 텍스트, 라벨 |

---

### 팔레트 A: "Midnight Prism" (추천 ⭐)

> 무드: 깊은 우주 느낌 + 보석처럼 빛나는 블록  
> 레퍼런스: Block Blast + Monument Valley의 중간

| 역할 | 이름 | Hex | 비고 |
|------|------|-----|------|
| `bg_primary` | Deep Space | `#0B1026` | 거의 블랙에 가까운 네이비 |
| `bg_secondary` | Cosmos | `#111638` | bg보다 약간 밝은 네이비 |
| `board_bg` | Nebula | `#161D4A` | 보드 영역 구분 |
| `cell_empty` | Void | `#1E2558` | 빈 셀, board_bg보다 약간 밝게 |
| `block_1` | Ruby | `#FF4D6A` | 코랄 대체 — 더 선명한 레드핑크 |
| `block_2` | Sapphire | `#4DA8FF` | 클래식 블루, 시인성 최고 |
| `block_3` | Emerald | `#4DFFB4` | 민트 그린, 다크 배경에서 팝 |
| `block_4` | Amethyst | `#B44DFF` | 보라, bg와 충분히 차별화 |
| `block_5` | Topaz | `#FFD84D` | 골드 옐로우, 따뜻한 악센트 |
| `block_6` | Coral | `#FF8B4D` | 오렌지, 에너지 |
| `block_7` | Aqua | `#4DFFF0` | 시안, Sapphire와 구분되는 밝은 톤 |
| `accent` | Solar Flare | `#FFB84D` | 점수/콤보 하이라이트 |
| `text_primary` | Starlight | `#F0F0FF` | 거의 화이트, 약간 블루 틴트 |
| `text_secondary` | Moonstone | `#8B8FB0` | 뮤트된 라벤더 그레이 |

**블록 색상 설계 원칙:**
- 7색 모두 채도 85-100%, 명도 70-100% 범위
- 어두운 배경 위에서 모든 블록이 "발광"하는 느낌
- 색맹 접근성: red-green 구분을 위해 green을 민트 톤으로 이동
- 인접 배치 시 구분: 가장 가까운 두 색(Sapphire ↔ Aqua)도 명도 차이 확보

---

### 팔레트 B: "Frosted Dawn"

> 무드: 밝고 깨끗한 아침 느낌, 프리미엄 미니멀  
> 레퍼런스: 1010! + Apple Design Award 수상작 계열

| 역할 | 이름 | Hex | 비고 |
|------|------|-----|------|
| `bg_primary` | Cream | `#F5F0E8` | 따뜻한 오프화이트 |
| `bg_secondary` | Pearl | `#EBE5DA` | 약간 어두운 크림 |
| `board_bg` | Linen | `#E2DCD0` | 린넨 느낌 |
| `cell_empty` | Mist | `#D8D2C6` | 빈 셀 |
| `block_1` | Poppy | `#E8534A` | 웜 레드 |
| `block_2` | Ocean | `#3D8BCC` | 클래식 블루 |
| `block_3` | Fern | `#5AAF6B` | 자연스러운 그린 |
| `block_4` | Iris | `#8B6CC1` | 소프트 퍼플 |
| `block_5` | Honey | `#E8B44A` | 골든 옐로우 |
| `block_6` | Tangerine | `#E87B3D` | 웜 오렌지 |
| `block_7` | Sky | `#4AB8CC` | 스카이 블루/틸 |
| `accent` | Sunset | `#E86B4A` | 레드-오렌지 악센트 |
| `text_primary` | Charcoal | `#2A2520` | 다크 브라운/블랙 |
| `text_secondary` | Stone | `#8A8378` | 뮤트 그레이 브라운 |

**특징:**
- 라이트 모드로 차별화 (대부분 퍼즐 게임이 다크)
- 블록 채도를 70-80%로 낮춰 "고급스러운" 느낌
- 눈의 피로도가 낮아 장시간 플레이에 유리
- 단, 앱스토어 스크린샷에서 "게임"보다 "앱" 느낌이 날 수 있음

---

### 팔레트 C: "Electric Dusk"

> 무드: 네온 사인 + 도시 일몰, 에너지 넘치는 캐주얼  
> 레퍼런스: Candy Crush + Tetris Effect

| 역할 | 이름 | Hex | 비고 |
|------|------|-----|------|
| `bg_primary` | Twilight | `#1A0A2E` | 딥 퍼플 (현재보다 더 레드 틴트) |
| `bg_secondary` | Dusk | `#231240` | 미드 퍼플 |
| `board_bg` | Plum | `#2D1A52` | 보드 영역 |
| `cell_empty` | Grape | `#3A2366` | 빈 셀 |
| `block_1` | Neon Rose | `#FF3B7A` | 핫핑크 |
| `block_2` | Electric Blue | `#3B8AFF` | 일렉트릭 블루 |
| `block_3` | Lime Surge | `#7AFF3B` | 라임 그린 (네온) |
| `block_4` | UV Violet | `#C03BFF` | 바이올렛 |
| `block_5` | Plasma Yellow | `#FFE03B` | 밝은 옐로우 |
| `block_6` | Magma | `#FF6B3B` | 레드 오렌지 |
| `block_7` | Cyan Pulse | `#3BFFF0` | 시안 |
| `accent` | Gold Rush | `#FFD700` | 순금색 악센트 |
| `text_primary` | Pure White | `#FFFFFF` | 퓨어 화이트 |
| `text_secondary` | Lavender | `#A89CC8` | 라벤더 그레이 |

**특징:**
- 현재 다크 퍼플 배경을 활용하되 블록을 "네온" 레벨로 업그레이드
- 가장 시각적 임팩트가 강함 (앱스토어 스크린샷에서 눈에 띔)
- 블록에 glow 효과 추가 시 시너지
- 단, 과할 경우 "저가 게임" 느낌이 될 수 있으므로 glow 강도 조절 필수

---

### 🏆 팔레트 추천

**1순위: Palette A "Midnight Prism"**
- 이유: 다크 배경(트렌드 부합) + 보석 톤 블록(프리미엄) + 색맹 접근성 고려
- 현재 스타일에서 자연스러운 업그레이드 가능

**2순위: Palette C "Electric Dusk"**  
- 이유: 시각적 임팩트가 강해 앱스토어 전환율에 유리, 단 절제 필요

---

## 3. 블록 스타일 제안

### 스타일 A: "Polished Gem" (추천 ⭐)

> 보석을 깎아놓은 듯한 faceted look, 미세한 내부 그라디언트 + 하이라이트

```
블록 구조 (레이어 순서):
┌─────────────────────────┐
│ 1. Base fill (블록 색)    │
│ 2. 상단 하이라이트 (15%)  │  ← 위에서 아래로 fade, 블록색의 밝은 버전
│ 3. 하단 섀도우 (10%)      │  ← 아래에서 위로 fade, 블록색의 어두운 버전
│ 4. 좌상단 스펙큘러 (8%)   │  ← 작은 원형 하이라이트, 약간 오프셋
│ 5. 테두리 (1px)           │  ← 블록색 + brightness(-15%)
│ 6. 드롭 섀도우             │  ← 아래 2px, blur 4px, 블랙 20%
└─────────────────────────┘

모서리: 둥근 사각형, radius = 셀 크기의 18% (약 6-7px at 38px cell)
```

**Godot 4 셰이더 의사 코드:**
```gdscript
# 블록 셰이더 (CanvasItem shader)
shader_type canvas_item;

uniform vec4 block_color : source_color;
uniform float cell_size = 38.0;

void fragment() {
    vec2 uv = UV;
    vec4 base = block_color;
    
    // 상단 하이라이트: 위에서 아래로 점점 투명해지는 밝은 오버레이
    float top_highlight = smoothstep(0.6, 0.0, uv.y) * 0.15;
    
    // 하단 섀도우: 아래에서 위로 점점 투명해지는 어두운 오버레이
    float bottom_shadow = smoothstep(0.5, 1.0, uv.y) * 0.12;
    
    // 좌상단 스펙큘러 하이라이트 (작은 원)
    float spec_dist = distance(uv, vec2(0.28, 0.25));
    float specular = smoothstep(0.18, 0.05, spec_dist) * 0.25;
    
    // 합성
    vec3 final_color = base.rgb;
    final_color += vec3(top_highlight + specular);  // 밝게
    final_color -= vec3(bottom_shadow);              // 어둡게
    
    // 1px 내부 테두리 (약간 어둡게)
    float border = step(uv.x, 0.03) + step(1.0 - 0.03, uv.x) 
                 + step(uv.y, 0.03) + step(1.0 - 0.03, uv.y);
    final_color = mix(final_color, base.rgb * 0.75, min(border, 1.0) * 0.5);
    
    COLOR = vec4(final_color, 1.0);
}
```

**장점:** 깊이감 + 고급스러움, "터치하고 싶은" 촉감  
**단점:** 셰이더 비용 약간 높음 (하지만 8x8이면 무시 가능)

---

### 스타일 B: "Soft Flat"

> 완전 플랫은 아닌, 미니멀한 그림자만 있는 클린 스타일

```
블록 구조 (레이어 순서):
┌─────────────────────────┐
│ 1. Base fill (단색)       │
│ 2. 드롭 섀도우             │  ← 아래 3px, blur 6px, 블랙 25%
│ 3. (옵션) 내부 1px 밝은 선 │  ← 상단 + 좌측에만, 블록색 + 20% white
└─────────────────────────┘

모서리: radius = 셀 크기의 22% (더 둥글게, 약 8px)
```

**Godot 4 구현 (StyleBoxFlat 사용):**
```gdscript
func create_block_style(color: Color) -> StyleBoxFlat:
    var style = StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_left = 8
    style.corner_radius_bottom_right = 8
    
    # 드롭 섀도우
    style.shadow_color = Color(0, 0, 0, 0.25)
    style.shadow_size = 3
    style.shadow_offset = Vector2(0, 2)
    
    # 미묘한 내부 밝은 테두리 (상단/좌측)
    style.border_width_top = 1
    style.border_width_left = 1
    style.border_color = color.lightened(0.2)
    
    return style
```

**장점:** 가볍고 깔끔, 구현 간단, 모던한 느낌  
**단점:** 시각적 임팩트가 Polished Gem보다 약함

---

### 스타일 C: "Neon Glow"

> 블록 자체가 발광하는 듯한 네온 효과, Palette C와 최적 조합

```
블록 구조 (레이어 순서):
┌─────────────────────────┐
│ 1. 외부 글로우              │  ← 블록색, blur 8px, opacity 40%
│ 2. Base fill (블록 색)      │
│ 3. 내부 밝은 코어           │  ← 중앙이 더 밝은 radial gradient
│ 4. 테두리                   │  ← 1px, 블록색의 밝은 버전
└─────────────────────────┘

모서리: radius = 셀 크기의 15% (약 5-6px, 약간 각진 느낌)
```

**Godot 4 셰이더:**
```gdscript
shader_type canvas_item;

uniform vec4 block_color : source_color;
uniform float glow_intensity = 0.4;

void fragment() {
    vec2 uv = UV;
    vec4 base = block_color;
    
    // 중앙이 더 밝은 radial gradient
    float center_dist = distance(uv, vec2(0.5, 0.45));
    float core_brightness = smoothstep(0.5, 0.0, center_dist) * 0.3;
    
    vec3 final_color = base.rgb + vec3(core_brightness);
    
    // 글로우는 블록 외부에 별도 Light2D 또는 BackBufferCopy로 처리
    COLOR = vec4(final_color, 1.0);
}

# 별도로 블록 노드에 부착:
# - PointLight2D: block_color, energy=0.3, texture=soft_circle
# 또는
# - SubViewport + blur post-process
```

**장점:** 시각적으로 가장 화려, "Tetris Effect" 급 분위기  
**단점:** 성능 비용 높음 (Light2D 64개), glow 과하면 가독성 저하

---

### 🏆 블록 스타일 추천

**"Polished Gem" + Palette A "Midnight Prism" 조합**

이유:
1. 보석 블록 + 우주 배경 = 테마 일관성
2. 셰이더 비용이 합리적 (8x8 = 64블록, 모바일에서도 OK)
3. 고급스러우면서도 "캐주얼 게임" 정체성 유지
4. 현재 버블 스타일에서 자연스러운 진화 (원형→라운드사각형, 하이라이트 유지)

---

## 4. 전체 무드보드 키워드

### 핵심 키워드 (Top 5)
1. **Polished** — 다듬어진, 완성도 높은
2. **Vibrant** — 생동감 있는 색상
3. **Spatial** — 깊이감, 공간감
4. **Satisfying** — 터치/매치 시 쾌감
5. **Minimal Luxury** — 최소한의 요소로 고급감

### 보조 키워드
- Cosmic / Celestial (우주적)
- Jewel-toned (보석 톤)
- Smooth transitions (부드러운 전환)
- Tactile feedback (촉각적 피드백)
- Dark mode native (다크 모드 네이티브)
- Geometric precision (기하학적 정밀함)

### 참고 무드 이미지 검색 키워드
```
"dark UI mobile game gem blocks"
"cosmic puzzle game aesthetic"  
"premium casual mobile game interface"
"jewel tone color palette dark background"
"glassmorphism game UI 2025"
```

---

## 5. 타이포그래피

### 현재 문제점
- **Fredoka**: 어린이/유아 타겟 느낌, 둥글고 굵은 글꼴이 "장난감" 인상
- 가격: Free (좋음), 하지만 프리미엄 퍼즐 게임에는 맞지 않음

### 추천 폰트 시스템

#### 1순위: **Nunito + Nunito Sans** (Google Fonts, Free)
| 용도 | 폰트 | Weight | 사이즈 | 비고 |
|------|------|--------|--------|------|
| 게임 타이틀 | Nunito | ExtraBold (800) | 32-36px | 둥글되 Fredoka보다 세련 |
| 점수/숫자 | Nunito | Bold (700) | 24-28px | 큰 숫자, 시인성 우선 |
| UI 라벨 | Nunito Sans | SemiBold (600) | 14-16px | 버튼, 라벨 |
| 설명 텍스트 | Nunito Sans | Regular (400) | 12-13px | 설정, 튜토리얼 |

**왜 Nunito?**
- Fredoka의 친근함을 유지하면서 성인 타겟에도 적합
- Geometric sans → 블록/퍼즐의 기하학적 본질과 맞음
- 한글 대응: Noto Sans KR과 자연스러운 조합

#### 2순위: **Poppins** (Google Fonts, Free)
| 용도 | 폰트 | Weight | 사이즈 |
|------|------|--------|--------|
| 게임 타이틀 | Poppins | Bold (700) | 30-34px |
| 점수/숫자 | Poppins | SemiBold (600) | 22-26px |
| UI 라벨 | Poppins | Medium (500) | 14-16px |
| 설명 텍스트 | Poppins | Regular (400) | 12-13px |

**왜 Poppins?**
- 가장 "모던 앱" 느낌, 깔끔하고 중성적
- 숫자가 예쁨 (tabular figures 지원)
- 단, Nunito보다 "따뜻함"이 부족

#### 3순위: **Space Grotesk** (Google Fonts, Free) — 차별화 옵션
| 용도 | 폰트 | Weight | 사이즈 |
|------|------|--------|--------|
| 게임 타이틀 | Space Grotesk | Bold (700) | 28-32px |
| 점수/숫자 | Space Grotesk | Medium (500) | 22-26px |
| UI 라벨 | Space Grotesk | Regular (400) | 14-16px |

**왜 Space Grotesk?**
- "Cosmic" 무드보드와 완벽 매치
- 약간의 레트로-퓨처 느낌으로 차별화
- 단, 한글 미지원 → Pretendard와 조합 필요

### 사이즈 체계 (393px 기준)

```
Title      : 32px / line-height 1.1 / letter-spacing -0.02em
Score      : 28px / line-height 1.0 / letter-spacing  0.00em  
H2 (섹션)  : 20px / line-height 1.2 / letter-spacing -0.01em
Body       : 15px / line-height 1.4 / letter-spacing  0.00em
Label      : 13px / line-height 1.3 / letter-spacing  0.02em
Caption    : 11px / line-height 1.3 / letter-spacing  0.03em
```

---

## 6. 앱스토어 아이콘 & 스크린샷 전략

### 아이콘 디자인

#### DO ✅
- **단순한 블록 조합** (2×2 또는 L자 모양) — 게임 본질을 즉시 전달
- **밝은 그라디언트 배경** (아이콘만 밝게! 게임은 다크여도 됨)
  - 추천: `#1E2A6B` → `#4A2D8B` (딥블루→퍼플 대각선)
- **블록에 미세한 3D감** (스타일 A의 축소판)
- **1024×1024에서 보고 128×128에서도 읽히는지** 테스트
- 블록 색상 3-4개만 사용 (전부 넣으면 산만)

#### DON'T ❌
- 텍스트 넣기 (128px에서 안 읽힘)
- 캐릭터 (캐릭터 없는 퍼즐 게임에 억지 캐릭터 = 의심)
- 검은 배경 (앱스토어 배경과 섞임)
- 얇은 선/디테일 (축소 시 사라짐)

#### 아이콘 레이아웃 제안

```
┌──────────────────┐
│  그라디언트 배경    │
│                    │
│    ┌──┐ ┌──┐      │
│    │🟥│ │🟦│      │    ← 4개 블록이 "떨어지는" 모션감
│    └──┘ └──┘      │
│       ┌──┐        │
│       │🟩│        │
│    ┌──┼──┤        │
│    │🟨│  │        │
│    └──┘──┘        │
│                    │
└──────────────────┘
```

### 스크린샷 전략 (5장 구성)

#### 1장: Hero Shot — "첫인상"
```
┌─────────────────────┐
│  "블록을 맞추는      │  ← 큰 텍스트 (영어/한국어)
│   가장 세련된 방법"   │
│                       │
│   ┌─────────────┐    │
│   │  게임 화면    │    │  ← 실제 게임 스크린 (75% 크기)
│   │  (매치 순간)  │    │
│   └─────────────┘    │
│                       │
└─────────────────────┘
배경: 게임 배경색의 확장
```

#### 2장: Gameplay — "이렇게 플레이"
- 블록을 드래그하는 순간 캡처
- 손가락 아이콘 + 모션 라인
- 작은 텍스트: "드래그 & 드롭"

#### 3장: 콤보/점수 — "쾌감"
- 줄이 사라지는 순간 + 파티클 효과 
- 점수 팝업이 크게 보이는 순간
- 텍스트: "콤보를 노려라!"

#### 4장: 컬러풀 보드 — "아름다움"
- 보드에 블록이 예쁘게 쌓인 상태
- 텍스트 없이 비주얼로 승부
- 또는 미니멀한 "Design meets puzzle"

#### 5장: 통계/성취 — "깊이"
- 최고 점수, 플레이 통계 화면
- 텍스트: "당신의 기록에 도전하세요"

### 스크린샷 공통 규칙

1. **디바이스 프레임 사용하지 않기** — 2024년 이후 트렌드, 풀블리드가 더 현대적
2. **텍스트는 2줄 이내**, 폰트 사이즈 최소 40px (실제 디바이스 스크린샷 기준)
3. **배경색**: 게임 bg_primary의 연장선 (일관성)
4. **텍스트 색**: `accent` 또는 `text_primary`만 사용
5. **첫 3장이 80%** — 대부분의 유저는 3장까지만 봄

---

## 7. 구현 우선순위

### Phase 1: 즉시 (1-2일)
- [ ] 컬러 팔레트 교체 (Palette A 적용)
- [ ] 폰트 교체 (Fredoka → Nunito)
- [ ] 블록 모서리 radius 조정 (원형 → 라운드 사각형 18%)
- [ ] 빈 셀 색상 업데이트

### Phase 2: 다음 주 (3-5일)
- [ ] 블록 셰이더 구현 (Polished Gem 스타일)
- [ ] 드롭 섀도우 시스템 통일
- [ ] UI 패널 글래스모피즘 적용 (점수 영역, 다음 블록 영역)
- [ ] 타이포 사이즈 체계 적용

### Phase 3: 출시 전 (1-2주)
- [ ] 매치/클리어 파티클 이펙트
- [ ] 블록 배치 애니메이션 (ease-out bounce)
- [ ] 앱 아이콘 제작
- [ ] 스크린샷 5장 제작
- [ ] 다크/라이트 모드 대응 (선택)

---

## 8. 벤치마크 게임 목록

직접 설치해서 비주얼 참고할 것:

| 게임 | 참고 포인트 |
|------|------------|
| **Block Blast!** | 다크 배경 + 블록 색감, UI 레이아웃 |
| **1010!** | 미니멀 디자인, 여백 활용 |
| **Toon Blast** | 파티클/애니메이션 품질 |
| **Royal Match** | UI 글래스모피즘, 프리미엄 느낌 |
| **Woodoku** | 텍스처 활용, 따뜻한 톤 |
| **Tetris (EA)** | 네온 글로우, 깔끔한 보드 |
| **Triple Match 3D** | 3D 블록 렌더링 |

---

## 요약: 한 줄 디렉션

> **"깊은 우주 위에 빛나는 보석 블록 — 터치할 때마다 만족스러운, 프리미엄 캐주얼 퍼즐"**

- 팔레트: **Midnight Prism** (다크 네이비 + 보석 톤 7색)
- 블록: **Polished Gem** (내부 그라디언트 + 스펙큘러 + 그림자)
- 폰트: **Nunito** (친근 + 모던의 균형)
- 키워드: Polished, Vibrant, Spatial, Satisfying, Minimal Luxury
