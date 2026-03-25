# 📦 APK 빌드 & 배포

## 역할
ChromaBlocks APK를 빌드하고 Android 기기에 배포한다.

## 빌드 파이프라인 (deploy.sh)

### 기본 사용법
```bash
# 풀 파이프라인: 빌드 → 설치 → 실행
./scripts/deploy.sh

# 빌드 스킵, 기존 APK만 설치
./scripts/deploy.sh --skip-build

# 실행하지 않음 (설치까지만)
./scripts/deploy.sh --no-launch

# 실행 후 스크린샷 캡처
./scripts/deploy.sh --screenshot
```

### 환경 정보
- **Godot**: `/Applications/Godot.app/Contents/MacOS/Godot`
- **ADB**: `~/Library/Android/sdk/platform-tools/adb`
- **APK 출력**: `chromablocks.apk` (프로젝트 루트)
- **패키지**: `com.alba.chromablocks`
- **아키텍처**: arm64-v8a
- **빌드 프리셋**: "Android" (export_presets.cfg)

### Godot Headless 빌드 (수동)
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --export-debug "Android" chromablocks.apk
```

## ADB 무선 디버깅

### 디바이스 정보
- **기기**: Galaxy S24+
- **로컬 WiFi**: 192.168.50.84:5555
- **Tailscale**: 100.70.88.124:5555

### 연결
```bash
ADB=~/Library/Android/sdk/platform-tools/adb

# Tailscale 연결
$ADB connect 100.70.88.124:5555

# 로컬 WiFi 연결
$ADB connect 192.168.50.84:5555

# 연결 확인
$ADB devices
```

### 유용한 ADB 명령
```bash
# 앱 데이터 초기화
$ADB shell pm clear com.alba.chromablocks

# 앱 실행
$ADB shell monkey -p com.alba.chromablocks -c android.intent.category.LAUNCHER 1

# 스크린샷 캡처
$ADB exec-out screencap -p > screenshot.png

# 터치 시뮬레이션
$ADB shell input tap 196 500

# 드래그 시뮬레이션 (x1,y1 → x2,y2, duration ms)
$ADB shell input swipe 100 750 200 400 300

# 로그 확인
$ADB logcat -s godot | tail -50

# APK 수동 설치
$ADB install -r chromablocks.apk
```

## GitHub Release 배포

```bash
# 1. 태그 생성
git tag -a v0.X.0 -m "ChromaBlocks v0.X.0"
git push origin v0.X.0

# 2. GitHub Release 생성 (gh CLI)
gh release create v0.X.0 chromablocks.apk \
  --title "ChromaBlocks v0.X.0" \
  --notes "변경 내역..."

# 3. 또는 릴리즈 빌드
/Applications/Godot.app/Contents/MacOS/Godot --headless --export-release "Android" chromablocks.apk
```

## 빌드 체크리스트
- [ ] `export_presets.cfg` 버전 번호 업데이트
- [ ] `project.godot` 버전 확인
- [ ] 디버그 로그 제거 확인
- [ ] .uid 파일 수동 생성하지 않았는지 확인
- [ ] VIBRATE 퍼미션: `permissions/custom_permissions`에 있어야 함 (Gradle 아님)

## 빌드 실패 시 체크
1. **UID 오류**: `Godot --headless --import` 실행
2. **서명 오류**: debug.keystore 경로 확인
3. **Export 프리셋 없음**: export_presets.cfg에 "Android" 확인
4. **ADB 연결 실패**: `adb kill-server && adb start-server`

## 이 에이전트를 사용하는 방법
```
/build-apk
```
APK 빌드, 기기 배포, 스크린샷 캡처, Release 생성 시 사용.
