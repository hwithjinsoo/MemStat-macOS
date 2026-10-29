#!/bin/zsh
# MemStat 위젯 자동 재빌드 (무료 Personal Team은 서명이 7일마다 만료됨)
#
# 설치된 앱의 프로비저닝 프로파일 만료가 RENEW_BEFORE_DAYS 이내면
# 다시 빌드해서 /Applications의 앱을 교체하고 헬퍼를 재시작한다.
# LaunchAgent(com.jin.memorywidget.rebuild)가 로그인 시 + 매일 실행.
#
# 템플릿: ~/Library/Scripts/로 복사한 뒤 아래 REPO, TEAM_ID를 채워서 쓴다.
# Team ID가 들어간 복사본은 저장소에 커밋하지 말 것.
#
# 수동 실행:   ~/Library/Scripts/memstat-rebuild.sh          (만료 임박 시에만 빌드)
#              ~/Library/Scripts/memstat-rebuild.sh --force  (무조건 빌드)
# 로그:        ~/Library/Logs/memstat-rebuild.log

set -u

REPO="/path/to/public-memory-widget"   # 이 저장소를 클론한 절대 경로
TEAM_ID="YOUR_TEAM_ID"                 # 10자리 Team ID (README 참고)
RENEW_BEFORE_DAYS=2
BUILD_DIR="$HOME/Library/Caches/memstat-rebuild"
PRODUCTS="$BUILD_DIR/Build/Products/Debug"
HELPER_APP="/Applications/MemoryWidgetHelper.app"
WIDGET_APP="/Applications/widget-for-me.app"
WIDGET_APPEX="$WIDGET_APP/Contents/PlugIns/memory widgetExtension.appex"

log() { print -r -- "$(date '+%Y-%m-%d %H:%M:%S') $*" }

# 프로파일 만료 시각(epoch). 앱이 없거나 못 읽으면 0 (= 즉시 재빌드 대상)
expiry_epoch() {
    local profile="$1/Contents/embedded.provisionprofile"
    local iso
    iso=$(/usr/bin/security cms -D -i "$profile" 2>/dev/null | /usr/bin/plutil -extract ExpirationDate raw - 2>/dev/null) || { print 0; return }
    /bin/date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$iso" "+%s" 2>/dev/null || print 0
}

needs_rebuild() {
    local now=$(/bin/date +%s)
    local deadline=$(( now + RENEW_BEFORE_DAYS * 86400 ))
    local exp
    for app in "$HELPER_APP" "$WIDGET_APP" "$WIDGET_APPEX"; do
        exp=$(expiry_epoch "$app")
        log "만료: $(/bin/date -r $exp '+%Y-%m-%d %H:%M') - ${app:t}"
        (( exp < deadline )) && return 0
    done
    return 1
}

build() {
    local scheme="$1"
    log "빌드 시작: $scheme"
    /usr/bin/xcodebuild -project "$REPO/widget-for-me.xcodeproj" -scheme "$scheme" \
        -configuration Debug -derivedDataPath "$BUILD_DIR" \
        -allowProvisioningUpdates DEVELOPMENT_TEAM="$TEAM_ID" \
        build > "$BUILD_DIR/last-build-$scheme.log" 2>&1
    local rc=$?
    if (( rc != 0 )); then
        log "빌드 실패: $scheme (자세한 내용: $BUILD_DIR/last-build-$scheme.log)"
        /usr/bin/grep -E "error:" "$BUILD_DIR/last-build-$scheme.log" | /usr/bin/head -5 | while read -r line; do log "  $line"; done
    fi
    return $rc
}

# 새 빌드를 옆에 복사해 둔 뒤 바꿔치기 (복사 도중 실패해도 기존 앱은 남음)
install_app() {
    local src="$1" dst="$2"
    /usr/bin/ditto "$src" "$dst.new" || { log "복사 실패: $dst"; /bin/rm -rf "$dst.new"; return 1 }
    /bin/rm -rf "$dst" && /bin/mv "$dst.new" "$dst"
}

main() {
    log "===== 확인 시작"
    if [[ "$TEAM_ID" == "YOUR_TEAM_ID" || ! -d "$REPO/widget-for-me.xcodeproj" ]]; then
        log "설정 필요: 스크립트 맨 위 REPO, TEAM_ID를 채워주세요"
        return 1
    fi
    if [[ "${1:-}" != "--force" ]] && ! needs_rebuild; then
        log "아직 여유 있음, 빌드 안 함"
        return 0
    fi

    /bin/mkdir -p "$BUILD_DIR"
    build MemoryWidgetHelper || return 1
    build widget-for-me || return 1

    /usr/bin/pkill -x MemoryWidgetHelper
    install_app "$PRODUCTS/MemoryWidgetHelper.app" "$HELPER_APP" || return 1
    install_app "$PRODUCTS/widget-for-me.app" "$WIDGET_APP" || return 1
    /usr/bin/open -g "$HELPER_APP"

    log "교체 완료. 새 만료: $(/bin/date -r $(expiry_epoch "$HELPER_APP") '+%Y-%m-%d %H:%M')"
}

main "$@" >> "$HOME/Library/Logs/memstat-rebuild.log" 2>&1
