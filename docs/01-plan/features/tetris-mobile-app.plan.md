# Plan: 블록 퍼즐 모바일 게임 (iOS/Android)

> **Feature**: tetris-mobile-app
> **Created**: 2026-02-08
> **Phase**: Plan
> **Status**: Draft

---

## 1. 프로젝트 개요

### 1.1 프로젝트 명
**BlockDrop** (가칭) - 블록 퍼즐 모바일 게임

### 1.2 프로젝트 목표
- iOS / Android 크로스 플랫폼 블록 퍼즐 게임 출시
- 중독성 있는 게임플레이 + 현대적 UI/UX로 차별화
- 하이브리드 수익 모델(IAP + 광고 + 구독)을 통한 지속 가능한 수익 창출
- 글로벌 시장 진출 (다국어 지원)

### 1.3 핵심 가치
- **접근성**: 누구나 30초 만에 배울 수 있는 직관적 조작
- **깊이**: 숙련자를 위한 전략적 요소 (콤보, 스코어링 시스템)
- **공정성**: Pay-to-Win 요소 배제, 기술 기반 경쟁
- **미적 완성도**: 세련된 비주얼과 만족스러운 피드백

---

## 2. 시장 분석

### 2.1 모바일 게임 시장 규모

| 연도 | 모바일 게임 시장 | 전체 게임 시장 | 모바일 비중 |
|------|-----------------|---------------|------------|
| 2024 | $92B | $187.7B | 49% |
| 2025 | $94B (예상) | - | - |
| 2026 | $98B (예상) | $205B (예상) | 56-58% |

- 퍼즐 게임 장르 IAP 매출: **$12.2B** (2024)
- 퍼즐 게임 다운로드 비중: 전체 모바일 게임의 ~20%
- 하이브리드 캐주얼 게임 IAP 매출 **전년 대비 37% 성장** (2024)

### 2.2 테트리스 프랜차이즈 현황
- 총 누적 판매: **5.2억+ 카피** (2024년 기준)
- 모바일 유료 다운로드: **4.25억+**
- 2023년 판매: 1,420만 유닛 (전년 대비 6.3% 성장)
- 구매자의 42%가 25세 미만 → 젊은 세대에서 지속적 수요

### 2.3 주요 경쟁작 분석

| 게임명 | 특징 | 수익모델 | 다운로드 |
|--------|------|---------|---------|
| **Block Blast** | 드래그 앤 드롭 블록 배치, 10x10 그리드 | 광고 + IAP | 5억+ |
| **Tetris (공식)** | 원조 라이선스 게임, 마라톤/스프린트 모드 | IAP + 광고 | 4.25억+ |
| **1010!** | 시간제한 없는 릴랙스 블록 배치 | 광고 + IAP | 1억+ |
| **Blockudoku** | 스도쿠 + 블록 퍼즐 융합, 9x9 | 광고 + IAP | 5천만+ |
| **Woodoku** | 나무 테마, 트리플 매치 + 블록 | 광고 + IAP | 3천만+ |
| **Block Match** | 광고 없음, 8x8 그리드 | IAP 전용 | 1천만+ |
| **Royal Match** | 퍼즐 + 인테리어, 광고 없음 | IAP 전용 | 3억+ |

### 2.4 시장 기회와 차별화 포인트

**기회:**
- 블록 퍼즐 시장은 성장 중이나, 대부분의 게임이 단순 배치형에 머물러 있음
- "떨어지는 블록" 메커닉의 현대적 재해석 수요 존재
- 오프라인 플레이 가능한 가벼운 퍼즐 게임 선호 트렌드 강화
- LiveOps 기반 장기 수익화 모델이 주류로 자리잡음

**차별화 방향:**
1. 클래식 낙하 블록 메커닉 + 현대적 시각/촉각 피드백
2. 독창적인 게임 모드 (AI 난이도 조절, 데일리 챌린지, 멀티플레이어)
3. 세련된 미니멀 디자인 (Royal Match 수준의 폴리시)
4. 플레이어 존중형 수익화 (광고 없는 프리미엄 옵션 제공)

---

## 3. 법적 고려사항 (중요)

### 3.1 테트리스 저작권/상표권

**핵심 판례: Tetris Holding v. Xio Interactive (2012)**

이 판례에서 법원은 게임의 **"룩 앤 필(look and feel)"**이 저작권으로 보호될 수 있다고 판결했습니다.

**보호되지 않는 요소 (아이디어 - 사용 가능):**
- "블록이 위에서 떨어지는 퍼즐 게임"이라는 일반적 개념
- 줄을 완성하면 사라지는 기본 규칙
- 낙하 블록 퍼즐 장르 자체

**보호되는 요소 (표현 - 반드시 차별화 필요):**
- 테트로미노의 구체적인 블록 모양, 색상, 텍스처
- 플레이필드의 정확한 크기 (10x20)
- 고스트 피스(미리보기), 가비지 피스의 구현 방식
- 블록의 회전, 이동 애니메이션 방식
- 전체적인 시각적 표현의 유사성

### 3.2 안전한 개발 방향

| 요소 | 테트리스 원본 | 우리의 차별화 |
|------|-------------|-------------|
| 블록 형태 | 테트로미노 (4칸) | 다양한 크기(2~6칸) 폴리오미노 |
| 그리드 크기 | 10x20 | 8x16 또는 커스텀 |
| 시각 스타일 | 직사각형 블록 | 둥근 모서리 + 그라데이션 |
| 게임 모드 | 마라톤/스프린트 | 퍼즐/챌린지/멀티 |
| 명칭 | Tetris/Tetromino | BlockDrop (독자적 브랜딩) |
| 클리어 방식 | 줄 클리어만 | 줄 + 컬러 매칭 하이브리드 |

> **결론**: "Tetris"라는 이름, 테트로미노의 정확한 형태, 10x20 그리드, 공식 게임의 시각적 표현을 피하고, 독자적인 비주얼과 게임 메커닉으로 충분히 차별화하면 법적 리스크를 최소화할 수 있습니다.

---

## 4. 기술 스택

### 4.1 프레임워크 선택: Flutter + Flame Engine

**Flutter를 선택하는 이유:**

| 기준 | Flutter | React Native |
|------|---------|-------------|
| 렌더링 | Impeller (자체 엔진, 픽셀 단위 제어) | Fabric + Skia |
| FPS (고부하) | 안정적 60/120 FPS | 45-50 FPS 드롭 가능 |
| 언어 | Dart (AOT 컴파일) | JavaScript (Hermes 바이트코드) |
| 애니메이션 | 내장, 120 FPS 지원 | 60 FPS 일반적 |
| 게임 엔진 | Flame (성숙한 생태계) | 제한적 |
| 시장 점유율 | ~46% | ~35% |
| 퍼즐 게임 적합성 | ★★★★★ | ★★★☆☆ |

**Flame Engine 장점:**
- Flutter 기반 경량 2D 게임 엔진
- 컴포넌트 기반 아키텍처
- 물리엔진 (Forge2D), 파티클 시스템 내장
- Google의 Casual Games Toolkit 공식 지원
- 활발한 커뮤니티 및 다수의 퍼즐 게임 레퍼런스

### 4.2 전체 기술 스택

```
┌─────────────────────────────────────────────┐
│                  클라이언트                    │
├─────────────────────────────────────────────┤
│  프레임워크: Flutter 3.x                       │
│  게임 엔진: Flame Engine                      │
│  상태 관리: Riverpod 또는 Bloc               │
│  로컬 저장: Hive / SharedPreferences         │
│  애니메이션: Flutter Animation + Flame Effects│
│  오디오: flame_audio (SoLoud)               │
├─────────────────────────────────────────────┤
│                  백엔드                       │
├─────────────────────────────────────────────┤
│  BaaS: Firebase / Supabase                  │
│  인증: Firebase Auth (소셜 로그인)            │
│  DB: Firestore (랭킹, 유저 데이터)           │
│  리얼타임: Firebase Realtime DB (멀티플레이)  │
│  분석: Firebase Analytics + Crashlytics     │
├─────────────────────────────────────────────┤
│                  수익화                       │
├─────────────────────────────────────────────┤
│  광고: Google AdMob (리워드 + 배너)          │
│  IAP: RevenueCat (iOS/Android 통합 관리)    │
│  구독: RevenueCat Subscription              │
├─────────────────────────────────────────────┤
│                  인프라/배포                   │
├─────────────────────────────────────────────┤
│  CI/CD: GitHub Actions + Fastlane           │
│  배포: App Store / Google Play              │
│  모니터링: Firebase Crashlytics + Analytics │
│  A/B 테스트: Firebase Remote Config          │
└─────────────────────────────────────────────┘
```

---

## 5. 게임 디자인 개요

### 5.1 핵심 게임 메커닉

**기본 규칙:**
- 다양한 형태의 블록(폴리오미노)이 화면 위에서 떨어짐
- 플레이어가 블록을 좌/우 이동, 회전하여 배치
- 가로줄이 완성되면 해당 줄이 사라지고 점수 획득
- 블록이 맨 위에 도달하면 게임 오버

**차별화 메커닉:**
- **컬러 매칭 보너스**: 같은 색 블록 3개 이상 연결 시 추가 점수
- **스킬 블록**: 폭탄(주변 블록 제거), 라인 클리어(한 줄 즉시 제거) 등 특수 블록
- **콤보 시스템**: 연속 줄 클리어 시 콤보 배율 증가
- **스타 시스템**: 각 레벨 클리어 조건 (1~3스타) 달성 목표

### 5.2 게임 모드

| 모드 | 설명 | 목적 |
|------|------|------|
| **클래식** | 무한 모드, 점점 빨라지는 속도 | 하이스코어 경쟁 |
| **퍼즐** | 레벨 기반, 제한된 블록으로 목표 달성 | 스토리 진행감 |
| **데일리 챌린지** | 매일 새로운 조건의 퍼즐 | 일일 리텐션 |
| **스프린트** | 40줄 클리어 타임어택 | 스킬 경쟁 |
| **VS 모드** | 1:1 실시간 대전 | 소셜/경쟁 |
| **젠 모드** | 게임 오버 없음, 릴랙스 플레이 | 캐주얼 유저 유입 |

### 5.3 비주얼 방향

- **스타일**: 미니멀 + 네오 모피즘 (깔끔하고 현대적인)
- **색상**: 파스텔 + 비비드 그라데이션 (피로감 적은 시각적 매력)
- **피드백**: 줄 클리어 시 파티클 이펙트 + 진동(햅틱) + 사운드
- **테마**: 다크/라이트 모드 + 시즌별 테마 (LiveOps)
- **애니메이션**: 60/120 FPS 부드러운 블록 이동/회전/낙하

---

## 6. 수익 전략

### 6.1 수익 모델: 하이브리드 (IAP + 광고 + 구독)

2026년 모바일 게임 시장에서 하이브리드 수익화는 기본(baseline)이며, 단일 모델로는 생존이 어렵습니다.

### 6.2 수익 채널 상세

#### A. 인앱 구매 (IAP) - 주요 수익원 (목표 비중: 50-60%)

| 상품 | 유형 | 가격대 | 설명 |
|------|------|-------|------|
| 하트(목숨) | 소모성 | $0.99~$4.99 | 게임 오버 후 이어하기 |
| 스킬 블록 팩 | 소모성 | $1.99~$9.99 | 특수 블록 아이템 |
| 코인 팩 | 소모성 | $0.99~$49.99 | 인게임 화폐 |
| 테마/스킨 | 영구 | $2.99~$7.99 | 블록/배경 커스터마이징 |
| 아바타 아이템 | 영구 | $0.99~$4.99 | 프로필 꾸미기 |
| 스타터 팩 | 1회성 | $4.99 | 초기 부스트 번들 |

**핵심 원칙:**
- 게임플레이에 영향을 주는 아이템은 코인으로도 획득 가능 (F2P 공정성)
- 한정 이벤트 상품으로 구매 긴급성 유도
- AI 기반 개인화 오퍼 (유저 행동 분석 기반)

#### B. 광고 수익 (목표 비중: 25-30%)

| 광고 유형 | 위치 | 보상 |
|----------|------|------|
| **리워드 비디오** | 게임 오버 후, 아이템 획득 | 추가 목숨, 코인, 스킬 블록 |
| **배너 광고** | 메인 화면 하단 (게임 중 X) | - |
| **인터스티셜** | 레벨 전환 시 (3-5판마다) | - |

**핵심 원칙:**
- 게임 플레이 중 광고 노출 **절대 금지**
- 리워드 광고 위주로 플레이어 선택권 보장
- 프리미엄 구독자에게 광고 완전 제거 옵션

#### C. 구독 (목표 비중: 15-20%)

| 플랜 | 가격 | 혜택 |
|------|------|------|
| **BlockDrop Pass (월간)** | $4.99/월 | 광고 제거 + 일일 코인 보너스 + 독점 테마 1개/월 |
| **BlockDrop Pass (연간)** | $29.99/년 | 월간 혜택 + 독점 아바타 + 시즌 패스 포함 |
| **시즌 패스 (분기별)** | $9.99/분기 | 시즌 독점 보상 트랙 + 이벤트 조기 접근 |

### 6.3 LiveOps 수익화 전략

| LiveOps 요소 | 주기 | 수익 기여 |
|-------------|------|----------|
| 시즌 이벤트 | 분기별 | 한정 테마/아이템 판매 |
| 데일리 챌린지 | 매일 | 일일 리텐션 → 광고/IAP 기회 |
| 주간 토너먼트 | 매주 | 경쟁심 자극 → 아이템 소비 |
| 한정 이벤트 | 월 2-3회 | FOMO 기반 IAP 촉진 |
| 배틀 패스 | 시즌별 | 지속적 과금 유도 |

### 6.4 예상 수익 시나리오 (출시 후 12개월)

| 시나리오 | DAU | ARPDAU | 월 매출 | 연 매출 |
|---------|-----|--------|--------|--------|
| 보수적 | 10K | $0.05 | $15K | $180K |
| 기본 | 50K | $0.08 | $120K | $1.44M |
| 낙관적 | 200K | $0.12 | $720K | $8.64M |

> **참고**: Block Blast 등 상위 블록 퍼즐 게임은 월 수천만 달러 매출을 기록하고 있으나, 이는 대규모 마케팅 투자가 수반된 결과입니다.

---

## 7. 사용자 획득 (UA) 전략

### 7.1 사전 등록 / 론칭

| 단계 | 활동 | 예산 |
|------|------|------|
| 사전 등록 | App Store/Google Play 사전 등록 + 소셜 미디어 | $0 (오가닉) |
| 소프트 론칭 | 특정 국가(캐나다, 호주) 제한 출시 | $5K-$10K |
| 글로벌 론칭 | 전 세계 출시 + ASO 최적화 | $10K-$30K |

### 7.2 마케팅 채널

- **ASO (App Store Optimization)**: 키워드 최적화, 스크린샷/비디오 A/B 테스트
- **소셜 미디어**: TikTok, Instagram Reels (게임플레이 숏폼 콘텐츠)
- **인플루언서**: 게임 유튜버/스트리머 협업
- **크로스 프로모션**: 다른 캐주얼 게임과 교차 홍보
- **UA 광고**: Facebook/Google UAC (소프트 론칭 데이터 기반 최적화)

### 7.3 리텐션 전략

| 지표 | 목표 | 방법 |
|------|------|------|
| D1 리텐션 | 40%+ | 매끄러운 온보딩, 첫 세션 보상 |
| D7 리텐션 | 20%+ | 데일리 챌린지, 연속 출석 보상 |
| D30 리텐션 | 10%+ | 시즌 이벤트, 새 콘텐츠, 소셜 기능 |

---

## 8. 개발 로드맵

### Phase 1: MVP (Minimum Viable Product)
- 기본 게임 엔진 (블록 낙하, 이동, 회전, 줄 클리어)
- 클래식 모드 1개
- 기본 UI/UX (메인 화면, 게임 화면, 결과 화면)
- 로컬 하이스코어 저장
- 기본 사운드/이펙트

### Phase 2: 핵심 기능 완성
- 퍼즐 모드 추가 (30개 레벨)
- 스킬 블록 시스템
- 콤보 시스템
- 테마/스킨 시스템
- Firebase 연동 (인증, 리더보드)
- 기본 IAP 구현

### Phase 3: 수익화 + 소셜
- AdMob 광고 통합
- RevenueCat 구독 시스템
- 데일리 챌린지
- 친구 초대/소셜 공유
- 푸시 알림

### Phase 4: 소프트 론칭
- 소프트 론칭 (캐나다/호주)
- A/B 테스트 (수익화 밸런스)
- 성능 최적화
- 크래시/버그 수정
- KPI 모니터링 및 조정

### Phase 5: 글로벌 론칭
- 글로벌 출시
- VS 모드 (멀티플레이어)
- 시즌 시스템/배틀 패스
- LiveOps 파이프라인 구축
- 다국어 지원 (영어, 한국어, 일본어, 중국어 등)

### Phase 6: 성장 + 라이브
- AI 난이도 조절
- 주간 토너먼트
- 커뮤니티 기능
- 지속적 콘텐츠 업데이트
- UA 확장

---

## 9. 리스크 분석

| 리스크 | 영향도 | 발생확률 | 대응 방안 |
|--------|-------|---------|----------|
| 테트리스사 법적 분쟁 | 높음 | 중간 | 독자적 디자인/메커닉 차별화, 법률 자문 |
| 시장 포화 (Block Blast 등) | 높음 | 높음 | 독특한 게임 모드, 우수한 UX로 차별화 |
| 유저 획득 비용 상승 | 중간 | 높음 | 오가닉/바이럴 성장 집중, ASO 최적화 |
| 리텐션 부족 | 높음 | 중간 | LiveOps, 데일리 챌린지, 소셜 기능 |
| Flutter/Flame 성능 한계 | 중간 | 낮음 | 퍼즐 게임은 저사양 OK, 프로파일링 조기 실시 |
| App Store 리뷰 반려 | 중간 | 낮음 | Apple 가이드라인 사전 숙지, 소프트 론칭 |

---

## 10. 성공 지표 (KPI)

### 핵심 지표

| 지표 | 목표 (6개월) | 목표 (12개월) |
|------|-------------|-------------|
| 총 다운로드 | 100K | 500K |
| DAU | 10K | 50K |
| D1 리텐션 | 40% | 45% |
| D7 리텐션 | 20% | 25% |
| D30 리텐션 | 8% | 12% |
| ARPDAU | $0.05 | $0.08 |
| 월 매출 | $15K | $120K |
| 앱 평점 | 4.3+ | 4.5+ |
| 크래시율 | <1% | <0.5% |

---

## 11. 참고 자료 및 출처

### 시장 데이터
- [Mobile Game Revenue 2026-2029 Report](https://www.blog.udonis.co/mobile-marketing/mobile-games/mobile-game-revenue)
- [Gaming Industry Report 2026: Market Size & Trends](https://www.blog.udonis.co/mobile-marketing/mobile-games/gaming-industry)
- [Mobile Gaming Revenue vs Console Gaming Statistics (2026)](https://icon-era.com/statistics/mobile-gaming-revenue-vs-console-gaming-statistics-and-trends/)
- [Mobile Game Revenue Statistics 2026](https://www.tekrevol.com/blogs/mobile-game-revenue-statistics/)
- [Tetris Statistics - LEVVVEL](https://levvvel.com/tetris-statistics/)

### 수익화 전략
- [Mobile Game Monetization Models That Still Work in 2026](https://studiokrew.com/blog/mobile-game-monetization-models-2026/)
- [Mobile Game Monetization in 2026: Ads, IAPs & Hybrid Strategies](https://www.tekrevol.com/blogs/mobile-game-monetization/)
- [Top Mobile Game Monetization Strategies for 2025](https://www.blog.udonis.co/mobile-marketing/mobile-games/mobile-game-monetization)
- [AI-Driven Game Monetization (GIANTY)](https://www.gianty.com/ai-driven-game-monetization/)
- [App Monetization in 2026](https://mobidictum.com/app-monetization-in-2026/)

### 법적 참고
- [Tetris Holding v. Xio Interactive - Wikipedia](https://en.wikipedia.org/wiki/Tetris_Holding,_LLC_v._Xio_Interactive,_Inc.)
- [Cloning Games - Argo Law](https://argolawyer.com/legality-of-cloning-games/)
- [Tetris Copyright Decision - Public Knowledge](https://publicknowledge.org/tetris-copyright-decision-shows-how-complicated-copyright-for-games-can-be/)

### 기술 스택
- [Flutter vs React Native 2026 - Simplilearn](https://www.simplilearn.com/tutorials/reactjs-tutorial/flutter-vs-react-native)
- [Flutter vs React Native 2026 - CrustLab](https://crustlab.com/blog/flutter-vs-react-native/)
- [Make Games with Flutter in 2025 - DEV Community](https://dev.to/krlz/make-games-with-flutter-in-2025-flame-engine-tools-and-free-assets-1n6)
- [Flutter Casual Games Toolkit](https://docs.flutter.dev/resources/games-toolkit)
- [Flame Engine - GitHub](https://github.com/flame-engine/flame)

### 경쟁 분석
- [Top 10 Most Downloaded Mobile Games 2025](https://respawn.outlookindia.com/gaming/gaming-guides/top-10-most-downloaded-mobile-games-2025-roblox-takes-the-crown)
- [Tetris-style Games Market Report (2025)](https://mobidictum.com/mobile-game-market-report-june-2025-color-block-jam/)
- [Games Like Block Blast](https://ant.games/blog/similar/games-like-block-blast/)

---

> **Next Step**: `/pdca design tetris-mobile-app` → 상세 설계 문서 작성
