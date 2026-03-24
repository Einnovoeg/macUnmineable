#!/usr/bin/env bash
set -euo pipefail

# End-to-end smoke test for the native macOS app. The script intentionally
# installs the managed miners into temporary locations so verification does not
# depend on any developer-local binary already sitting in the repo tree.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BIN="${ROOT_DIR}/dist/macUnmineable.app/Contents/MacOS/macUnmineable"
TMP_DIR="$(mktemp -d -t macunmineable-verify.XXXXXX)"
TEST_XMRIG="${TMP_DIR}/xmrig"
TEST_CPUMINER="${TMP_DIR}/minerd"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

cd "${ROOT_DIR}"

echo "[verify] Type-checking SwiftUI app"
swiftc -parse-as-library -typecheck native/MacUnmineableNative.swift \
  -framework SwiftUI \
  -framework AppKit \
  -framework Foundation \
  -framework Network

echo "[verify] Building app bundle"
./scripts/build_native_app.sh

echo "[verify] Installing XMRig into temporary path"
XMRIG_PATH="${TEST_XMRIG}" ./scripts/install_xmrig.sh --force

echo "[verify] Installing cpuminer-scash into temporary path"
CPUMINER_SCASH_PATH="${TEST_CPUMINER}" ./scripts/install_cpuminer_scash.sh --force
"${TEST_CPUMINER}" --version

run_dry() {
  local host="$1"
  local algo="$2"
  echo "[verify] Dry-run ${algo} via ${host}"
  "${TEST_XMRIG}" --dry-run --no-color \
    --url "${host}:3333" \
    --algo "${algo}" \
    --user "BTC:11111111111111111111111111111111.macunmineable" \
    --pass "x" \
    --keepalive
}

run_dry "rx.unmineable.com" "rx"
run_dry "ghostrider.unmineable.com" "gr"
run_dry "kp.unmineable.com" "kawpow"

echo "[verify] Checking built app executable"
test -x "${APP_BIN}"
test -x "${ROOT_DIR}/dist/macUnmineable.app/Contents/Resources/runtime/miners/xmrig/xmrig"
test -x "${ROOT_DIR}/dist/macUnmineable.app/Contents/Resources/runtime/miners/cpuminer-scash/minerd"

echo "[verify] OK"
