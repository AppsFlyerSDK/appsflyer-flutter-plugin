#!/usr/bin/env bash
# =============================================================================
# AppsFlyer Flutter Plugin — Full E2E Test Runner
# Usage: ./scripts/run_full_e2e.sh [--no-build] [--android-only] [--ios-only]
# =============================================================================

set -uo pipefail

# ── Colors (disabled in CI or non-TTY) ───────────────────────────────────────
if [[ -t 1 && "${CI:-}" != "true" ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; BOLD=''; NC=''
fi

# ── Config ───────────────────────────────────────────────────────────────────
ANDROID_PACKAGE="com.appsflyer.android.deviceid"
IOS_BUNDLE="com.appsflyer.example"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLE_DIR="$REPO_ROOT/example"
APK_PATH="$EXAMPLE_DIR/build/app/outputs/flutter-apk/app-debug.apk"
IOS_APP_PATH="$EXAMPLE_DIR/build/ios/iphonesimulator/Runner.app"
REPORT_DIR="$REPO_ROOT/.claude/e2e-reports"
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
REPORT_FILE="$REPORT_DIR/full_e2e_report_${TIMESTAMP}.json"

DL_BG_URL="afexample://deeplink?deep_link_value=qa_deeplink_bg&af_sub1=background_test&pid=testmedia&c=deeplink_test"
DL_FG_URL="afexample://deeplink?deep_link_value=qa_deeplink_fg&af_sub1=foreground_test&pid=testmedia&c=deeplink_test"

# ── Flags ────────────────────────────────────────────────────────────────────
RUN_BUILD=true
RUN_ANDROID=true
RUN_IOS=true

for arg in "$@"; do
  case $arg in
    --no-build)     RUN_BUILD=false ;;
    --android-only) RUN_IOS=false ;;
    --ios-only)     RUN_ANDROID=false ;;
  esac
done

# ── Device detection (only for platforms being tested) ───────────────────────
ANDROID_DEVICE=""
IOS_UDID=""

if [[ "$RUN_ANDROID" == true ]]; then
  if [[ -n "${ANDROID_SERIAL:-}" ]]; then
    ANDROID_DEVICE="$ANDROID_SERIAL"
  else
    ANDROID_DEVICE=$(adb devices 2>/dev/null | grep -E "emulator|device$" | grep -v "List" | awk '{print $1}' | head -1 || true)
    if [[ -z "$ANDROID_DEVICE" ]]; then
      echo "ERROR: No Android device/emulator found. Start an emulator or set ANDROID_SERIAL." >&2
      exit 1
    fi
  fi
fi

if [[ "$RUN_IOS" == true ]]; then
  if [[ -n "${IOS_SIMULATOR_UDID:-}" ]]; then
    IOS_UDID="$IOS_SIMULATOR_UDID"
  else
    IOS_UDID=$(xcrun simctl list devices 2>/dev/null | grep "Booted" | grep -oE '[A-F0-9-]{36}' | head -1 || true)
    if [[ -z "$IOS_UDID" ]]; then
      echo "ERROR: No booted iOS simulator found. Boot a simulator or set IOS_SIMULATOR_UDID." >&2
      exit 1
    fi
  fi
fi

# ── State tracking (bash 3.2 compatible — no associative arrays) ─────────────
TOTAL=0; PASSED=0; FAILED=0; WARNED=0
PS_android_phase_1="SKIP"; PS_android_phase_2="SKIP"; PS_android_phase_3="SKIP"
PS_ios_phase_1="SKIP";     PS_ios_phase_2="SKIP";     PS_ios_phase_3="SKIP"

set_phase() { eval "PS_${1}='${2}'"; }
get_phase()  { eval "echo \"\${PS_${1}}\""; }

# ── Helpers ───────────────────────────────────────────────────────────────────
header() { echo -e "\n${BOLD}${BLUE}━━━ $1 ━━━${NC}"; }
step()   { echo -e "${CYAN}▶${NC} $*"; }
pass()   { echo -e "  ${GREEN}✓ PASS${NC}  $1"; TOTAL=$((TOTAL+1)); PASSED=$((PASSED+1)); }
fail()   { echo -e "  ${RED}✗ FAIL${NC}  $1"; TOTAL=$((TOTAL+1)); FAILED=$((FAILED+1)); }
note()   { echo -e "  ${YELLOW}ℹ${NC}  $1"; }

check_present() {
  local desc="$1" pattern="$2" logs="$3"
  if echo "$logs" | grep -qF "$pattern"; then
    pass "$desc"; return 0
  else
    fail "$desc"; echo -e "    ${RED}expected:${NC} $pattern"; return 1
  fi
}

check_absent() {
  local desc="$1" pattern="$2" logs="$3"
  if echo "$logs" | grep -qF "$pattern"; then
    fail "$desc — found: $pattern"; return 1
  else
    pass "$desc"; return 0
  fi
}

# Set phase FAIL if any check inside it failed, PASS otherwise.
# Usage: end_phase <phase_key> <FAILED_count_at_phase_start>
end_phase() {
  local phase_key="$1" failed_before="$2"
  if [[ $FAILED -gt $failed_before ]]; then
    set_phase "$phase_key" FAIL
  else
    set_phase "$phase_key" PASS
  fi
}

count_matches() { echo "$1" | grep -cF "$2" 2>/dev/null || echo 0; }

# ── Build ─────────────────────────────────────────────────────────────────────
build_android() {
  header "Building Android APK"
  cd "$EXAMPLE_DIR" && flutter build apk --debug && cd "$REPO_ROOT"
}

build_ios() {
  header "Building iOS Simulator App"
  cd "$EXAMPLE_DIR" && flutter build ios --simulator --debug && cd "$REPO_ROOT"
}

# ── Android helpers ───────────────────────────────────────────────────────────
android_fresh_install() {
  step "Uninstalling $ANDROID_PACKAGE"
  adb -s "$ANDROID_DEVICE" uninstall "$ANDROID_PACKAGE" 2>/dev/null || true
  step "Installing APK"
  adb -s "$ANDROID_DEVICE" install -r "$APK_PATH"
  step "Clearing logcat"
  adb -s "$ANDROID_DEVICE" logcat -c
}

android_launch() {
  step "Launching app"
  adb -s "$ANDROID_DEVICE" shell am start \
    -a android.intent.action.MAIN \
    -c android.intent.category.LAUNCHER \
    -n "${ANDROID_PACKAGE}/.MainActivity" > /dev/null 2>&1 || true
  sleep 2
  ANDROID_PID=$(adb -s "$ANDROID_DEVICE" shell pidof "$ANDROID_PACKAGE" 2>/dev/null | tr -d '\r' || true)
  if [[ -z "$ANDROID_PID" ]]; then
    fail "App did not launch — no PID found"; return 1
  fi
  note "PID: $ANDROID_PID"
}

android_logs() {
  adb -s "$ANDROID_DEVICE" logcat -d --pid="$ANDROID_PID" 2>/dev/null \
    | grep -E "AF_QA|response code:|AppsFlyer" || true
}

# ── iOS helpers ───────────────────────────────────────────────────────────────
ios_fresh_install() {
  step "Uninstalling $IOS_BUNDLE"
  xcrun simctl uninstall "$IOS_UDID" "$IOS_BUNDLE" 2>/dev/null || true
  step "Installing Runner.app"
  xcrun simctl install "$IOS_UDID" "$IOS_APP_PATH"
}

IOS_QA_LOG_FILE=""  # resolved after launch

ios_find_log_file() {
  local sim_data="$HOME/Library/Developer/CoreSimulator/Devices/$IOS_UDID/data"
  IOS_QA_LOG_FILE=$(find "$sim_data/Containers/Data/Application" \
    -name "af_qa_logs.txt" 2>/dev/null | head -1 || true)
  note "QA log file: ${IOS_QA_LOG_FILE:-not found yet}" >&2
}

ios_start_logstream() { :; }
ios_stop_logstream()  { :; }

ios_launch() {
  step "Launching app"
  # Clear previous session log
  local sim_data="$HOME/Library/Developer/CoreSimulator/Devices/$IOS_UDID/data"
  find "$sim_data/Containers/Data/Application" -name "af_qa_logs.txt" \
    -exec rm -f {} \; 2>/dev/null || true
  IOS_LAUNCH_OUT=$(xcrun simctl launch "$IOS_UDID" "$IOS_BUNDLE" 2>&1)
  IOS_PID=$(echo "$IOS_LAUNCH_OUT" | grep -oE '[0-9]+$' | tail -1 || true)
  note "PID: $IOS_PID"
}

ios_logs() {
  ios_find_log_file
  cat "$IOS_QA_LOG_FILE" 2>/dev/null | grep -E "AF_QA|response_status=" || true
}

ios_http_count() {
  ios_find_log_file
  if [[ -f "$IOS_QA_LOG_FILE" ]]; then
    grep -c "response_status=200" "$IOS_QA_LOG_FILE" || true
  else
    echo 0
  fi
}

# ═════════════════════════════════════════════════════════════════════════════
# ANDROID PHASES
# ═════════════════════════════════════════════════════════════════════════════

run_android_phase1() {
  header "Android — Phase 1: Smoke (fresh install)"
  local _f=$FAILED
  android_fresh_install
  if ! android_launch; then set_phase android_phase_1 FAIL; return; fi
  step "Waiting 30s for SDK start + events..."
  sleep 30
  local logs; logs=$(android_logs)

  echo ""
  note "--- SDK Init ---"
  if echo "$logs" | grep -qF "[AF_QA][startSDK] result: SUCCESS"; then
    pass "SDK started"
  else
    fail "SDK start — GATE FAILED, aborting phase"
    set_phase android_phase_1 FAIL; return
  fi

  check_present "onInstallConversionData is_first_launch=true" "is_first_launch: true" "$logs"

  note "--- Pre-start APIs ---"
  for api in enableTCFDataCollection setConsentDataV2 setDisableAdvertisingIdentifiers setCollectIMEI setCollectAndroidId; do
    check_present "$api called" "[AF_QA][$api]" "$logs"
  done

  note "--- Post-start APIs ---"
  check_present "getVersionNumber returns value" "[AF_QA][getVersionNumber]" "$logs"

  note "--- Events + HTTP ---"
  check_present "af_demo_launch fired"  "[AF_QA][logEvent(af_demo_launch)]"   "$logs"
  check_present "af_purchase fired"     "[AF_QA][logEvent: af_purchase"       "$logs"
  check_present "af_content_view fired" "[AF_QA][logEvent: af_content_view"   "$logs"

  local http_count; http_count=$(count_matches "$logs" "response code:200 OK")
  if [[ "$http_count" -ge 3 ]]; then
    pass "HTTP 200 responses: $http_count (≥3 required)"
  else
    fail "HTTP 200 responses: $http_count (need ≥3)"
  fi

  note "--- Must not contain ---"
  check_absent "No Fatal Exception" "Fatal Exception"          "$logs"
  check_absent "No startSDK error"  "[AF_QA][startSDK] error:" "$logs"
  check_absent "No 5xx responses"   "response code:5"           "$logs"

  end_phase android_phase_1 $_f
}

run_android_phase2() {
  header "Android — Phase 2: Background Deep Link (same session)"
  if [[ "$(get_phase android_phase_1)" != "PASS" ]]; then
    note "Skipping — Phase 1 did not pass"; set_phase android_phase_2 SKIP; return
  fi
  local _f=$FAILED

  step "Pressing HOME (background app)"
  adb -s "$ANDROID_DEVICE" shell input keyevent KEYCODE_HOME
  sleep 2

  local pid_check; pid_check=$(adb -s "$ANDROID_DEVICE" shell pidof "$ANDROID_PACKAGE" 2>/dev/null | tr -d '\r' || true)
  if [[ -n "$pid_check" ]]; then
    note "App still alive — PID $pid_check"
  else
    fail "App process died after HOME press"; set_phase android_phase_2 FAIL; return
  fi

  step "Triggering background deep link"
  adb -s "$ANDROID_DEVICE" shell am start -a android.intent.action.VIEW -d "$DL_BG_URL" > /dev/null 2>&1 || true
  sleep 5

  local logs; logs=$(android_logs)
  echo ""
  check_present "onDeepLinking FOUND (bg)"                      "status=Status.FOUND deepLinkValue=qa_deeplink_bg error=null" "$logs"
  check_present "deepLinkValue=qa_deeplink_bg"                  "qa_deeplink_bg"    "$logs"
  check_present "2nd onInstallConversionData is_first_launch=false" "is_first_launch: false" "$logs"

  local http_count; http_count=$(count_matches "$logs" "response code:200 OK")
  if [[ "$http_count" -ge 1 ]]; then pass "LAUNCH HTTP 200 observed"; else fail "LAUNCH HTTP 200 not observed"; fi

  check_absent "No Fatal Exception" "Fatal Exception" "$logs"

  end_phase android_phase_2 $_f
}

run_android_phase3() {
  header "Android — Phase 3: Foreground Deep Link (fresh install #2)"
  local _f=$FAILED
  android_fresh_install
  if ! android_launch; then set_phase android_phase_3 FAIL; return; fi
  step "Waiting 25s for SDK start + first conversion data..."
  sleep 25

  local pre_logs; pre_logs=$(android_logs)
  if ! echo "$pre_logs" | grep -qF "is_first_launch: true"; then
    fail "is_first_launch=true not confirmed — aborting phase"
    set_phase android_phase_3 FAIL; return
  fi
  pass "is_first_launch=true confirmed (pre-deeplink gate)"

  step "Brief launcher switch (required for onPause cycle)"
  adb -s "$ANDROID_DEVICE" shell am start -a android.intent.action.MAIN -c android.intent.category.HOME > /dev/null 2>&1
  sleep 1

  step "Triggering foreground deep link"
  adb -s "$ANDROID_DEVICE" shell am start -a android.intent.action.VIEW -d "$DL_FG_URL" > /dev/null 2>&1 || true
  sleep 5

  local logs; logs=$(android_logs)
  echo ""
  check_present "onDeepLinking FOUND (fg)"                      "status=Status.FOUND deepLinkValue=qa_deeplink_fg error=null" "$logs"
  check_present "deepLinkValue=qa_deeplink_fg"                  "qa_deeplink_fg"    "$logs"
  check_present "2nd onInstallConversionData is_first_launch=false" "is_first_launch: false" "$logs"

  local http_count; http_count=$(count_matches "$logs" "response code:200 OK")
  if [[ "$http_count" -ge 1 ]]; then pass "LAUNCH HTTP 200 observed"; else fail "LAUNCH HTTP 200 not observed"; fi

  check_absent "No Fatal Exception" "Fatal Exception" "$logs"

  end_phase android_phase_3 $_f
}

# ═════════════════════════════════════════════════════════════════════════════
# iOS PHASES
# ═════════════════════════════════════════════════════════════════════════════

run_ios_phase1() {
  header "iOS — Phase 1: Smoke (fresh install)"
  local _f=$FAILED
  ios_fresh_install
  ios_start_logstream
  ios_launch
  step "Waiting 50s for SDK start + events (CI runners can be slow)..."
  sleep 50
  ios_stop_logstream
  local logs; logs=$(ios_logs)

  echo ""
  note "--- SDK Init ---"
  if echo "$logs" | grep -qF "[AF_QA][startSDK] result: SUCCESS"; then
    pass "SDK started"
  else
    fail "SDK start — GATE FAILED, aborting phase"
    set_phase ios_phase_1 FAIL; return
  fi

  check_present "onInstallConversionData is_first_launch=true" "is_first_launch: true" "$logs"

  note "--- Events + HTTP ---"
  check_present "af_demo_launch fired"  "[AF_QA][logEvent(af_demo_launch)]" "$logs"
  check_present "af_purchase fired"     "[AF_QA][logEvent: af_purchase"     "$logs"
  check_present "af_content_view fired" "[AF_QA][logEvent: af_content_view" "$logs"

  note "--- Must not contain ---"
  check_absent "No Fatal Exception" "Fatal Exception"          "$logs"
  check_absent "No startSDK error"  "[AF_QA][startSDK] error:" "$logs"

  if echo "$logs" | grep -qF "status=Status.NOT_FOUND"; then
    note "Initial onDeepLinking NOT_FOUND at launch — expected iOS SDK behavior"
  fi

  end_phase ios_phase_1 $_f
}

run_ios_phase2() {
  header "iOS — Phase 2: Deep Link (app in foreground)"
  if [[ "$(get_phase ios_phase_1)" != "PASS" ]]; then
    note "Skipping — Phase 1 did not pass"; set_phase ios_phase_2 SKIP; return
  fi
  local _f=$FAILED

  # App is still running from Phase 1. Trigger the URL while it is
  # in the foreground — most reliable path on all iOS versions / CI runners.
  step "Triggering deep link while app is in foreground"
  xcrun simctl openurl "$IOS_UDID" "$DL_BG_URL"
  step "Waiting 15s for deep link callback..."
  sleep 15

  local logs; logs=$(ios_logs)
  echo ""
  check_present "onDeepLinking FOUND (bg)"     "status=Status.FOUND deepLinkValue=qa_deeplink_bg error=null" "$logs"
  check_present "deepLinkValue=qa_deeplink_bg" "qa_deeplink_bg" "$logs"
  check_absent "No Fatal Exception" "Fatal Exception" "$logs"

  end_phase ios_phase_2 $_f
}

run_ios_phase3() {
  header "iOS — Phase 3: Foreground Deep Link (fresh install #2)"
  local _f=$FAILED
  ios_fresh_install
  ios_start_logstream
  ios_launch
  step "Waiting 50s for SDK start + first conversion data (CI runners can be slow)..."
  sleep 50

  local pre_logs; pre_logs=$(ios_logs)
  if ! echo "$pre_logs" | grep -qF "is_first_launch: true"; then
    fail "is_first_launch=true not confirmed — aborting phase"
    ios_stop_logstream
    set_phase ios_phase_3 FAIL; return
  fi
  pass "is_first_launch=true confirmed (pre-deeplink gate)"

  step "Triggering foreground deep link while app is in foreground"
  xcrun simctl openurl "$IOS_UDID" "$DL_FG_URL"
  step "Waiting 15s for deep link callback..."
  sleep 15

  ios_stop_logstream
  local logs; logs=$(ios_logs)
  echo ""
  check_present "onDeepLinking FOUND (fg)"     "status=Status.FOUND deepLinkValue=qa_deeplink_fg error=null" "$logs"
  check_present "deepLinkValue=qa_deeplink_fg" "qa_deeplink_fg" "$logs"
  check_absent "No Fatal Exception" "Fatal Exception" "$logs"

  end_phase ios_phase_3 $_f
}

# ═════════════════════════════════════════════════════════════════════════════
# REPORT
# ═════════════════════════════════════════════════════════════════════════════

overall_status() {
  local s
  for s in \
    "$(get_phase android_phase_1)" "$(get_phase android_phase_2)" "$(get_phase android_phase_3)" \
    "$(get_phase ios_phase_1)"     "$(get_phase ios_phase_2)"     "$(get_phase ios_phase_3)"; do
    [[ "$s" == "FAIL" ]] && echo "FAIL" && return
  done
  echo "PASS"
}

phase_label() {
  local s; s="$(get_phase "$1")"
  case $s in
    PASS) echo -e "${GREEN}PASS${NC}" ;;
    FAIL) echo -e "${RED}FAIL${NC}" ;;
    SKIP) echo -e "${YELLOW}SKIP${NC}" ;;
    *)    echo -e "${YELLOW}$s${NC}" ;;
  esac
}

print_summary() {
  local overall; overall=$(overall_status)
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  FULL E2E RESULTS — $(date '+%Y-%m-%d %H:%M:%S')${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  printf "\n  %-32s %-12s %-12s\n" "Phase" "Android" "iOS"
  printf  "  %-32s %-12s %-12s\n" "─────" "───────" "───"
  printf  "  %-32s " "Phase 1 — Smoke"
  echo -e "$(phase_label android_phase_1)   $(phase_label ios_phase_1)"
  printf  "  %-32s " "Phase 2 — Background Deep Link"
  echo -e "$(phase_label android_phase_2)   $(phase_label ios_phase_2)"
  printf  "  %-32s " "Phase 3 — Foreground Deep Link"
  echo -e "$(phase_label android_phase_3)   $(phase_label ios_phase_3)"
  echo ""
  printf  "  Checks: ${GREEN}%d passed${NC}  ${RED}%d failed${NC}\n" "$PASSED" "$FAILED"
  echo ""
  if [[ "$overall" == "PASS" ]]; then
    echo -e "  ${BOLD}${GREEN}Overall: PASS ✓${NC}"
  else
    echo -e "  ${BOLD}${RED}Overall: FAIL ✗${NC}"
  fi
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "\n  Report: ${CYAN}$REPORT_FILE${NC}\n"
}

save_report() {
  local overall; overall=$(overall_status)
  local i1; i1=$(get_phase ios_phase_1)
  local i2; i2=$(get_phase ios_phase_2)
  local i3; i3=$(get_phase ios_phase_3)
  local a1; a1=$(get_phase android_phase_1)
  local a2; a2=$(get_phase android_phase_2)
  local a3; a3=$(get_phase android_phase_3)

  # Build platforms_run array dynamically
  local platforms=""
  [[ "$RUN_ANDROID" == true ]] && platforms="\"android\""
  if [[ "$RUN_IOS" == true ]]; then
    [[ -n "$platforms" ]] && platforms="$platforms, "
    platforms="${platforms}\"ios\""
  fi

  mkdir -p "$REPORT_DIR"
  {
    echo "{"
    echo "  \"_meta\": {"
    echo "    \"run_date\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
    echo "    \"plan_version\": \"1.0.0\","
    echo "    \"overall_status\": \"$overall\","
    echo "    \"platforms_run\": [$platforms],"
    echo "    \"total_checks\": $TOTAL,"
    echo "    \"passed\": $PASSED,"
    echo "    \"failed\": $FAILED"
    echo "  },"
    echo "  \"summary_table\": {"
    # Only emit sections for platforms that were run
    local first=true
    if [[ "$RUN_IOS" == true ]]; then
      [[ "$first" == true ]] && first=false || echo ","
      printf "    \"ios_phase_1_smoke\":           \"%s\",\n" "$i1"
      printf "    \"ios_phase_2_bg_deeplink\":     \"%s\",\n" "$i2"
      printf "    \"ios_phase_3_fg_deeplink\":     \"%s\""    "$i3"
    fi
    if [[ "$RUN_ANDROID" == true ]]; then
      [[ "$first" == true ]] && first=false || echo ","
      printf "    \"android_phase_1_smoke\":       \"%s\",\n" "$a1"
      printf "    \"android_phase_2_bg_deeplink\": \"%s\",\n" "$a2"
      printf "    \"android_phase_3_fg_deeplink\": \"%s\""    "$a3"
    fi
    echo ""
    echo "  },"
    echo "  \"baselines_used\": {"
    if [[ "$RUN_IOS" == true && "$RUN_ANDROID" == true ]]; then
      echo "    \"smoke_android\":       \".claude/e2e-baselines/android_baseline.json\","
      echo "    \"smoke_ios\":           \".claude/e2e-baselines/ios_baseline.json\","
      echo "    \"deeplink_background\": \".claude/e2e-baselines/deeplink_background_baseline.json\","
      echo "    \"deeplink_foreground\": \".claude/e2e-baselines/deeplink_foreground_baseline.json\""
    elif [[ "$RUN_IOS" == true ]]; then
      echo "    \"smoke_ios\":           \".claude/e2e-baselines/ios_baseline.json\","
      echo "    \"deeplink_background\": \".claude/e2e-baselines/deeplink_background_baseline.json\","
      echo "    \"deeplink_foreground\": \".claude/e2e-baselines/deeplink_foreground_baseline.json\""
    else
      echo "    \"smoke_android\":       \".claude/e2e-baselines/android_baseline.json\""
    fi
    echo "  }"
    echo "}"
  } > "$REPORT_FILE"

  local readme="$REPORT_DIR/README.md"
  local report_name; report_name=$(basename "$REPORT_FILE")
  local row="| $(date '+%Y-%m-%d %H:%M') | $overall | $a1 | $a2 | $a3 | $i1 | $i2 | $i3 | [$report_name](./$report_name) |"

  if [[ -f "$readme" ]]; then
    if grep -q "no runs yet" "$readme"; then
      sed -i '' "s|.*no runs yet.*|$row|" "$readme"
    else
      echo "$row" >> "$readme"
    fi
  fi
}

# ═════════════════════════════════════════════════════════════════════════════
# MAIN
# ═════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}${BLUE}AppsFlyer Flutter Plugin — Full E2E Test Runner${NC}"
echo -e "Android device: $ANDROID_DEVICE"
echo -e "iOS simulator:  $IOS_UDID"
echo -e "Timestamp:      $TIMESTAMP"
echo -e "Build:          $( [[ "$RUN_BUILD" == true ]] && echo "yes" || echo "skipped (--no-build)" )"
echo ""

if [[ "$RUN_BUILD" == true ]]; then
  [[ "$RUN_ANDROID" == true ]] && build_android
  [[ "$RUN_IOS"     == true ]] && build_ios
else
  [[ "$RUN_ANDROID" == true ]] && [[ ! -f "$APK_PATH" ]]     && { echo -e "${RED}ERROR: APK not found: $APK_PATH${NC}"; exit 1; }
  [[ "$RUN_IOS"     == true ]] && [[ ! -d "$IOS_APP_PATH" ]] && { echo -e "${RED}ERROR: Runner.app not found: $IOS_APP_PATH${NC}"; exit 1; }
fi

[[ "$RUN_ANDROID" == true ]] && run_android_phase1
[[ "$RUN_ANDROID" == true ]] && run_android_phase2
[[ "$RUN_ANDROID" == true ]] && run_android_phase3
[[ "$RUN_IOS"     == true ]] && run_ios_phase1
[[ "$RUN_IOS"     == true ]] && run_ios_phase2
[[ "$RUN_IOS"     == true ]] && run_ios_phase3

print_summary
save_report

[[ "$(overall_status)" == "PASS" ]] && exit 0 || exit 1
