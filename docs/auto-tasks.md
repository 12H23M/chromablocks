# ChromaBlocks 자동 태스크 큐

> 리나가 자동으로 처리하는 태스크 목록
> 위에서부터 순서대로 처리. 완료되면 ✅ 표시.
> Leo가 직접 추가/삭제/순서변경 가능.

---

## 🔴 Tier 1 — 즉시 (출시 블로커)

- [x] **Performance Quick Wins 구현** ✅ 2026-03-27
  - StyleBoxFlat 캐시, Rounded rect polygon 캐시
  - GameOrb _process 최적화, Pulse tween 30fps 쓰로틀링
  - commit: 6f71cea, 715faa3

- [x] **BGM 볼륨 조정** ✅ (이미 -6dB로 설정됨)
  - MUSIC_VOLUME_DB: -6dB (확인 완료)

- [ ] **미커밋 변경사항 커밋+push**
  - icon.png, icon_192.png, icon_foreground.png, export_presets.cfg, project.godot
  - cell_view.gd (_clearing 플래그, glow 제거, inset 3.0)
  - draw_utils.gd (shadow 블록 내부로)
  - music_manager.gd (디버그 로그 정리)
  - generated/ 폴더 제거 확인

- [ ] **게임오버 화면 Design D2 구현**
  - 목업: gameover-d2.html (이미 완성)
  - 헥사곤 등급 뱃지, 컬러 스탯 칩, 미션 카드
  - 그라데이션 버튼, 파티클 배경

- [ ] **Safe area 패딩**
  - 노치/펀치홀/다이나믹 아일랜드 대응
  - HUD, 하단 네비 SafeArea margin

---

## 🟡 Tier 2 — 이번 주 (핵심 개선)

- [ ] **ADB 자동 테스트 스크립트**
  - scripts/auto-test.sh 생성
  - 배포 → 스크린샷 → AI 분석 파이프라인

- [ ] **오토플레이 봇 (GDScript)**
  - 빈 자리 탐색 → 최적 위치 배치 AI
  - headless 모드에서 N판 자동 실행
  - 통계 수집 (턴, 점수, 콤보, 체인, 즉사)

- [ ] **Python 게임 시뮬레이터**
  - board_state + piece_generator + scoring 로직 포팅
  - 1000판 시뮬 → JSON 리포트
  - 밸런스 파라미터 자동 최적화

- [ ] **Phase 6 P3 잔여 태스크**
  - 6.15: shake/bounce offset 분리
  - 6.16: PackedInt32Array 최적화
  - 6.21: Safe area 패딩

---

## 🟢 Tier 3 — 다음 주 (폴리시)

- [x] **콤보 시각 가이드 개선** ✅ 2026-03-28
  - 콤보 힌트 레이블 (한국어 메시지, 콤보 색상 연동)
  - 콤보 히트 카운터 도트 (5개 도트, 콤보 레벨별 활성화)
  - commit: ffae667

- [ ] **게임오버 → 재시작 전환 연출**
  - 페이드/슬라이드 전환
  - 보드 리셋 애니메이션

- [ ] **스토어 준비**
  - 스크린샷 5장 (ADB 캡처)
  - 태그라인 확정
  - 짧은 설명 + 긴 설명 최종본

- [ ] **퍼포먼스 프로파일링**
  - 프레임 드롭 구간 확인
  - 파티클/tween 최적화

- [ ] **미션 런 모드 폴리시**
  - 미션 밸런스 조정
  - 미션 완료 연출
  - 특수 타일 재활성화 (미션 전용)

---

## 🔵 Tier 4 — 아이디어 풀 (Leo 승인 후)

- [ ] 타임어택 모드 (60초 최고점)
- [ ] 폭탄 블록 (배치 시 주변 클리어)
- [ ] 주간 토너먼트 (글로벌 랭킹)
- [ ] 시즌 시스템 (3개월 주기, 테마+보상)
- [ ] 소셜 공유 (점수 카드 이미지 생성)
- [ ] 스킨 상점 (코인으로 구매)
- [ ] 튜토리얼 개선 (인터랙티브)
- [ ] 리플레이 기능 (최고 기록 재생)

---

## 📝 완료 로그

| 날짜 | 태스크 | 결과 |
|------|--------|------|
| (자동 기록) | | |
