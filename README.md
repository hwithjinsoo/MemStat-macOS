# 메모리 사용량 위젯 (macOS Memory Usage Widget)

macOS 데스크탑에 실시간 메모리 사용량과, 지금 메모리를 가장 많이 쓰고 있는 앱을 보여주는 WidgetKit 위젯입니다.

## 기능

- 사용 중인 메모리(GB) / 전체 메모리 / 사용률(%)을 색상 게이지와 함께 표시 (70% 미만 초록, 70~85% 주황, 85% 이상 빨강)
- 지금 메모리를 가장 많이 쓰고 있는 앱을 표시 (개별 프로세스가 아니라 같은 앱에 속한 프로세스끼리 합산해서 계산 — 예: 크롬 렌더러 여러 개를 "Google Chrome" 하나로 합산)
- small / medium 두 가지 위젯 크기 지원
- 30초 주기로 자동 갱신

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

## 참고

- 메모리 수치는 `(internal - purgeable) + wired + compressed` 페이지 기준으로 계산하며, Activity Monitor(활성 상태 보기)의 "메모리 사용량"과 같은 방식입니다. 다만 Apple이 정확한 내부 공식을 전부 공개하지는 않아서 100% 동일하지는 않을 수 있습니다.
- 최다 메모리 사용 앱 계산은 `proc_pidinfo`로 읽을 수 있는 프로세스 범위 내에서만 동작하며, 일부 시스템 보호 프로세스는 권한 문제로 집계에서 제외될 수 있습니다.
- 모든 데이터는 로컬(App Group 공유 저장소)에서만 처리되며, 외부로 전송되지 않습니다.
