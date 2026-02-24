# ChromaBlocks 스토어 배포 준비 체크리스트

> 최종 갱신: 2026-02-25
> 목표: Google Play Store 출시 (광고 수익 모델)

---

## 📊 현재 상태 요약

| 항목 | 상태 |
|------|------|
| 게임 코어 | ✅ 완료 (Phase 0~6) |
| UI/UX | ✅ 홈화면 리디자인 완료 |
| 수익화 기반 | ⚠️ 스텁만 존재 (AdMob 미연동) |
| 스토어 에셋 | ❌ 미준비 |
| 법적 요건 | ❌ 미준비 |
| Safe Area | ❌ 미적용 |
| 릴리스 빌드 | ❌ 미설정 |

---

## 🔴 P0 — 반드시 필요 (출시 불가 항목)

### 1. AdMob 실제 연동
- [ ] **AdMob 계정 생성** 및 앱 등록
- [ ] **Godot AdMob 플러그인 설치** (poing-studios/godot-admob-plugin 또는 GDExtension)
  - `gradle_build/use_gradle_build = true` 필요
  - min_sdk 21+, target_sdk 34+
- [ ] **광고 유닛 ID 발급**
  - 배너 (하단 상시)
  - 인터스티셜 (3게임마다 / 5분 쿨다운)
  - 보상형 (게임오버 Continue / 점수 2배)
- [ ] **ad_manager.gd 스텁 → 실제 SDK 호출로 교체**
- [ ] **테스트 광고로 검증** 후 프로덕션 ID 전환
- [ ] GDPR/ATT 동의 다이얼로그 (EU/한국 필수)

### 2. Google Play Console 설정
- [ ] **개발자 계정** 등록 ($25 일회성)
- [ ] **앱 등록** (com.alba.chromablocks)
- [ ] **앱 서명 키** (Upload Key + Google 관리 서명)
- [ ] **콘텐츠 등급 설문** 작성 (IARC)
- [ ] **타겟 연령** 설정 (광고 포함 → 13세 이상 권장)
- [ ] **데이터 안전** 섹션 작성

### 3. 스토어 에셋 제작
- [ ] **앱 아이콘** — 512×512 PNG (현재 icon.svg → 고해상도 PNG 필요)
- [ ] **피처 그래픽** — 1024×500 PNG
- [ ] **스크린샷** 최소 4장 (2~8장 권장, 16:9 또는 9:16)
  - 홈 화면 / 게임 플레이 / 콤보 / 게임오버
- [ ] **앱 제목** — "ChromaBlocks - Block Puzzle" (30자 이내)
- [ ] **짧은 설명** — 80자 이내
- [ ] **긴 설명** — 4000자 이내 (한국어 + 영어)

### 4. 법적 요건
- [ ] **개인정보 처리방침** 페이지 (URL 필요)
  - 광고 SDK 데이터 수집 내용 포함
  - GitHub Pages / Notion 등에 호스팅
- [ ] **이용약관** (권장)

### 5. Safe Area / 노치 대응
- [ ] **상단 Safe Area** 패딩 (노치/다이나믹 아일랜드)
- [ ] **하단 Safe Area** 패딩 (제스처 바/홈 인디케이터)
- [ ] HUD, 트레이, 배너 광고가 잘리지 않는지 다양한 기기 검증

---

## 🟡 P1 — 높은 우선순위 (출시 품질)

### 6. 릴리스 빌드 설정
- [ ] **Gradle 빌드 전환** (AdMob 플러그인 필요)
- [ ] **릴리스 키스토어** 생성 (debug → release)
- [ ] **ProGuard/R8** 난독화 확인
- [ ] **AAB 번들** 빌드 (APK 아닌 AAB로 Play Store 제출)
- [ ] **버전 관리** — version/code 자동 증가 체계

### 7. UI 디테일 마무리
- [ ] **홈화면 Daily/Continue 동일 크기** — 현재 불균등
- [ ] **로고 블록 회전** — draw_set_transform 검증
- [ ] **게임오버 화면 디자인** 홈화면과 통일
- [ ] **일시정지 화면 디자인** 홈화면과 통일
- [ ] **튜토리얼 화면 디자인** 홈화면과 통일
- [ ] **폰트 통일** — 전체 화면 Fredoka Bold 적용

### 8. 성능 최적화
- [ ] **저사양 기기 테스트** (2GB RAM 안드로이드)
- [ ] **메모리 프로파일링** — 누수 확인
- [ ] **프레임 드롭** 확인 (60fps 유지)
- [ ] Phase 6 P3 최적화 적용 (6.15~6.17)

### 9. 사운드/음악 보강
- [ ] **임팩트 있는 BGM 트랙** 추가 (Leo 피드백: "심장 강타하는 비트 없음")
- [ ] **게임오버 사운드** 추가/개선
- [ ] **레벨업 사운드** 검증
- [ ] 체인/블라스트 전용 사운드 인게임 테스트

---

## 🟢 P2 — 출시 후 개선 가능

### 10. 분석 / 추적
- [ ] Firebase Analytics 실제 연동 (현재 스텁)
- [ ] 핵심 KPI 대시보드: DAU, 리텐션, 세션 길이, ARPU
- [ ] 크래시 리포팅 (Firebase Crashlytics)

### 11. 추가 수익화
- [ ] IAP "광고 제거" 실제 연동 (Google Play Billing)
- [ ] 보상형 광고 추가 위치 검토

### 12. 콘텐츠 업데이트
- [ ] 위클리 챌린지
- [ ] 리더보드 (Google Play Games Services)
- [ ] 업적 시스템 Google Play Games 연동
- [ ] 더 다양한 특수 블록/이벤트

### 13. iOS 출시 (선택)
- [ ] Apple Developer 계정 ($99/년)
- [ ] Xcode 빌드 설정
- [ ] App Store Connect 등록
- [ ] ATT 프레임워크 연동

---

## 📋 작업 순서 (권장)

```
Week 1: P0.1 AdMob 연동 + P0.5 Safe Area
Week 2: P0.3 스토어 에셋 + P0.4 개인정보 처리방침
Week 3: P1.6 릴리스 빌드 + P1.7 UI 디테일
Week 4: P0.2 Play Console 등록 + 내부 테스트 트랙 배포
Week 5: 오픈 테스트 → 프로덕션 출시
```

---

## 🔧 기술 메모

### AdMob 플러그인 옵션
1. **poing-studios/godot-admob-plugin** — Godot 4 지원, Gradle 필수
2. **Shin-NiL/Godot-Android-Admob-Plugin** — 레거시
3. **직접 GDExtension** — 커스텀 JNI 바인딩

### 현재 AdManager 구조 (교체 포인트)
```
ad_manager.gd
├── show_banner() / hide_banner()     → 실제 SDK 호출로
├── show_interstitial()               → 실제 SDK 호출로
├── show_rewarded(type)               → 실제 SDK 호출로
├── is_rewarded_available()           → SDK 로드 상태 확인으로
└── should_show_interstitial()        → 로직 유지 (3게임/5분)
```

### 빌드 명령어
```bash
# 디버그 (현재)
Godot --headless --export-debug "Android" chromablocks.apk

# 릴리스 (Gradle 전환 후)
Godot --headless --export-release "Android" chromablocks.aab
```
