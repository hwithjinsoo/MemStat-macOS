# 메모리 사용량 위젯 (macOS Memory Usage Widget)

macOS 데스크탑에 실시간 메모리 사용량과, 지금 메모리를 가장 많이 쓰고 있는 앱을 보여주는 WidgetKit 위젯입니다.

## 기능

- 사용 중인 메모리(GB) / 전체 메모리 / 사용률(%)을 색상 게이지와 함께 표시 (70% 미만 초록, 70~85% 주황, 85% 이상 빨강)
- 지금 메모리를 가장 많이 쓰고 있는 앱을 표시 (개별 프로세스가 아니라 같은 앱에 속한 프로세스끼리 합산해서 계산 — 예: 크롬 렌더러 여러 개를 "Google Chrome" 하나로 합산)
- small / medium 두 가지 위젯 크기 지원
- 30초 주기로 갱신 요청 (실제 갱신 간격은 WidgetKit이 정해서 더 길어질 수 있음 — 위젯 오른쪽 위에 마지막 갱신 시각 표시)
- 헬퍼가 멈추면(1분 넘게 값이 안 바뀌면) 위젯에 "헬퍼 응답 없음" 표시

## 구성

Xcode 프로젝트 안에 타겟이 3개 있습니다.

| 타겟 | 역할 |
|---|---|
| `widget-for-me` | 위젯을 담는 본체 앱 (위젯 익스텐션을 내장) |
| `memory widgetExtension` | 실제 데스크탑에 표시되는 WidgetKit 위젯 |
| `MemoryWidgetHelper` | 백그라운드에서 5초마다 전체 프로세스를 스캔해서 App Group 공유 저장소에 메모리 사용량을 기록하는 헬퍼 앱 (샌드박스 꺼짐, Dock 아이콘 없이 로그인 시 자동 실행) |

위젯 익스텐션은 샌드박스 때문에 직접 시스템 프로세스 목록을 못 읽어서, 별도의 `MemoryWidgetHelper`가 대신 스캔하고 App Group(`UserDefaults(suiteName:)`)을 통해 값을 전달하는 구조입니다.

## 요구사항

- macOS (Apple Silicon / Intel 무관)
- Xcode (최신 버전 권장)
- 무료 Apple ID면 충분 (유료 개발자 계정 필요 없음)

## ⚠️ 클론 후 반드시 채워야 하는 부분

이 레포는 개인 식별 정보(개발자 팀 ID 등)를 지운 공개용 버전이라, **그대로 빌드하면 반드시 에러가 납니다.** 아래 체크리스트를 순서대로 처리해야 빌드가 됩니다.

| # | 항목 | 위치 | 무엇을 채워야 하는지 |
|---|---|---|---|
| 1 | Apple ID 로그인 | Xcode → Settings → Accounts | 본인 Apple ID 추가 (무료 계정으로 충분) |
| 2 | Team 지정 | 타겟 3개 전부 → Signing & Capabilities → Team | 비어 있음 → 본인 계정으로 선택 |
| 3 | Bundle Identifier 변경 | 타겟 3개 전부 → Signing & Capabilities → Bundle Identifier | `com.jin.memorywidget...` → `com.본인이름.memorywidget...` 형태로 변경 |
| 4 | App Group 새로 생성 | 타겟 3개 전부 → Signing & Capabilities → App Groups | 기존 `group.com.jin.memorywidget` 대신 본인 명의 App Group 새로 추가 (예: `group.com.본인이름.memorywidget`) — 3개 타겟이 전부 같은 App Group을 써야 함 |
| 5 | 코드 안 App Group 문자열 수정 | `memory widget/SharedTopProcess.swift`, `MemoryWidgetHelper/MemoryWidgetHelperApp.swift` | 하드코딩된 `"group.com.jin.memorywidget"`를 4번에서 만든 값으로 교체 |

아래는 각 항목을 조금 더 자세히 풀어놓은 순서입니다.

### 1~2. Xcode에 Apple ID 로그인 & Team 지정

Xcode → Settings → Accounts → `+` 눌러서 본인 Apple ID 추가. 그 다음 `widget-for-me`, `memory widgetExtension`, `MemoryWidgetHelper` 타겟 3개 전부 Signing & Capabilities에서 Team을 본인 계정으로 지정합니다.

### 3. Bundle Identifier 변경

타겟 3개 전부 Bundle Identifier 앞부분을 본인 것으로 바꿉니다 (예: `com.본인이름.memorywidget.xxx`).

> ⚠️ `memory widgetExtension`의 Bundle ID는 반드시 `widget-for-me`의 Bundle ID로 시작해야 합니다. 안 그러면 "Embedded binary's bundle identifier is not prefixed..." 에러가 납니다.

### 4. App Group 새로 만들기

3개 타겟 모두 Signing & Capabilities → App Groups에서 새 App Group(예: `group.com.본인이름.memorywidget`)을 추가하고, 3개 타겟이 전부 같은 App Group을 쓰도록 맞춰주세요.

### 5. 코드에서도 App Group 문자열 맞추기

아래 두 파일에 하드코딩된 App Group 문자열을 4번에서 만든 값으로 바꿔주세요.

- `memory widget/SharedTopProcess.swift` — `fetchSharedTopProcess(groupID: String = "group.com.jin.memorywidget")`
- `MemoryWidgetHelper/MemoryWidgetHelperApp.swift` — `let groupID = "group.com.jin.memorywidget"`

### 6. 빌드

스킴을 `memory widgetExtension`으로 두고 `Cmd+B`로 먼저 빌드 확인 → 스킴을 `widget-for-me`로 바꿔서 실행.

## Xcode 없이 계속 쓰고 싶다면 (정식 설치)

Xcode로 Run만 해두면 Xcode를 끌 때 위젯도 같이 사라집니다. 로그인할 때마다 자동으로 뜨게 하려면:

1. Xcode에서 `Product → Show Build Folder in Finder`로 빌드 결과물 폴더 열기
2. `widget-for-me.app`, `MemoryWidgetHelper.app`을 `/Applications`로 복사
3. Xcode 완전히 종료
4. `/Applications`에서 `MemoryWidgetHelper.app`, `widget-for-me.app` 순서로 각각 한 번씩 직접 실행 (더블클릭)
5. 데스크탑 위젯 편집 화면에서 위젯 새로 추가

이후 코드를 다시 수정하면, 다시 빌드한 결과물을 `/Applications`에 덮어써야 반영됩니다 (Xcode에서 Run만 해서는 이미 설치된 앱에 반영 안 됨).

## 무료 계정 7일 만료 대응 (자동 재빌드)

무료 Apple ID(Personal Team)로 서명하면 프로비저닝 프로파일이 **7일마다 만료**됩니다. 만료된 뒤에도 이미 실행 중인 앱은 계속 돌지만, **재부팅하면 헬퍼와 위젯이 실행되지 않아서** 메모리 추적이 멈춥니다. 이때 위젯은 마지막 값에서 멈춰 있고, 헬퍼 쪽 줄에 "헬퍼 응답 없음"이 뜹니다.

만료된 앱을 직접 실행하면 이런 에러가 납니다.

```
Launchd job spawn failed (POSIX error 163)
```

다시 빌드해서 `/Applications`에 덮어쓰면 7일이 새로 생깁니다. `scripts/auto-rebuild/`의 스크립트를 설치하면 이 과정이 자동으로 됩니다.

- 로그인할 때 + 매일 12시에 설치된 앱의 만료일을 확인
- 만료 2일 전부터(또는 이미 만료됐으면) 명령줄로 다시 빌드 → `/Applications`의 앱 교체 → 헬퍼 재시작
- 아직 여유가 있으면 아무것도 안 함
- Team ID는 빌드 명령의 인자로만 넘기므로 프로젝트 파일은 바뀌지 않음

### 설치

먼저 위 "정식 설치"를 한 번 끝내서 `/Applications`에 앱이 있는 상태여야 합니다.

**1. 본인 Team ID 확인** (10자리 영문+숫자)

```
codesign -dv /Applications/MemoryWidgetHelper.app 2>&1 | grep TeamIdentifier
```

**2. 스크립트 복사 후 설정 채우기**

```
mkdir -p ~/Library/Scripts
cp scripts/auto-rebuild/memstat-rebuild.sh ~/Library/Scripts/
chmod +x ~/Library/Scripts/memstat-rebuild.sh
open -e ~/Library/Scripts/memstat-rebuild.sh
```

열린 파일 맨 위의 두 줄을 본인 값으로 바꿉니다.

```
REPO="/path/to/public-memory-widget"   # 이 저장소를 클론한 절대 경로
TEAM_ID="YOUR_TEAM_ID"                 # 1번에서 확인한 값
```

> ⚠️ Team ID가 들어간 이 복사본은 저장소 밖(`~/Library/Scripts`)에 두고 커밋하지 마세요.

**3. 동작 확인**

```
~/Library/Scripts/memstat-rebuild.sh --force
tail ~/Library/Logs/memstat-rebuild.log
```

로그 마지막에 `교체 완료. 새 만료: ...`가 나오면 성공입니다. 빌드 중에 키체인 비밀번호 창이 뜨면 아래 "빌드할 때마다 비밀번호 창이 뜰 때"를 먼저 처리하세요. 자동 실행 중에는 창에 답할 사람이 없어서 빌드가 멈춥니다.

**4. 자동 실행 등록**

```
sed "s|__HOME__|$HOME|" scripts/auto-rebuild/com.jin.memorywidget.rebuild.plist > ~/Library/LaunchAgents/com.jin.memorywidget.rebuild.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.jin.memorywidget.rebuild.plist
```

등록하자마자 한 번 실행됩니다. "백그라운드 항목이 추가됨" 알림이 뜰 수 있는데 정상입니다. 등록됐는지는 이렇게 확인합니다.

```
launchctl print gui/$(id -u)/com.jin.memorywidget.rebuild | grep -E "runs|last exit code"
```

**해제하려면**

```
launchctl bootout gui/$(id -u)/com.jin.memorywidget.rebuild
rm ~/Library/LaunchAgents/com.jin.memorywidget.rebuild.plist
```

### 주의할 점

- Xcode → Settings → Accounts에 Apple ID 로그인이 유지돼 있어야 새 프로파일을 받아올 수 있습니다.
- 스크립트는 저장소 폴더의 **현재 코드**로 빌드합니다. 커밋하지 않은 수정이 있으면 그것도 같이 설치됩니다.
- 빌드가 실패하면 원인이 `~/Library/Logs/memstat-rebuild.log`에 남습니다. 전체 빌드 로그는 `~/Library/Caches/memstat-rebuild/last-build-<스킴>.log`에 있습니다.

### 빌드할 때마다 비밀번호 창이 뜰 때

"codesign이(가) 키체인의 키를 사용하려고 합니다" 같은 창이 빌드마다 뜨고, **"항상 허용"을 눌러도 계속 뜨는** 경우입니다. 서명 키의 partition 목록에 Apple 도구(`apple:`)가 빠져 있어서 생기는 문제이고, "항상 허용"으로는 이 목록이 바뀌지 않습니다.

터미널 앱에서 `security set-key-partition-list` 명령으로 고칠 수 있는데, **이 명령은 로그인 키체인의 모든 개인 키에 적용됩니다.** (`-D`, `-l` 같은 조건으로 키를 골라내는 게 기대대로 동작하지 않을 수 있음) 그래서 다른 앱 키가 쓰던 기존 값을 먼저 확인해서 같이 넣어야 합니다.

**1. 지금 쓰이고 있는 partition 값 확인**

```
security dump-keychain -a ~/Library/Keychains/login.keychain-db | grep -A1 partition_id | grep description | sort -u
```

**2. 나온 `teamid:XXXXXXXXXX` 값을 전부 `-S` 뒤에 쉼표로 이어서 실행** (로그인 비밀번호를 물어봄)

```
security set-key-partition-list -S apple-tool:,apple:,teamid:XXXXXXXXXX,teamid:YYYYYYYYYY -s -t private ~/Library/Keychains/login.keychain-db
```

기존 값을 빠뜨리면 해당 앱(예: 게임 런처의 로그인 키)이 실행될 때 비밀번호 창이 뜰 수 있습니다. 그때는 빠진 값을 넣어서 2번을 다시 실행하면 됩니다.

## 참고

- 메모리 수치는 `(internal - purgeable) + wired + compressed` 페이지 기준으로 계산하며, Activity Monitor(활성 상태 보기)의 "메모리 사용량"과 같은 방식입니다. 다만 Apple이 정확한 내부 공식을 전부 공개하지는 않아서 100% 동일하지는 않을 수 있습니다.
- 최다 메모리 사용 앱은 Activity Monitor의 "메모리" 열과 같은 `phys_footprint`(`proc_pid_rusage`) 기준으로 계산합니다. 권한 때문에 다른 사용자나 root가 소유한 프로세스(`kernel_task` 등)는 읽을 수 없어서 집계에서 빠집니다.
- 모든 데이터는 로컬(App Group 공유 저장소)에서만 처리되며, 외부로 전송되지 않습니다.
