#!/usr/bin/env bash
set -euo pipefail

# Build the native app bundle from the SwiftUI source file and stage the
# runtime assets that the app can mutate under Application Support.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
APP_NAME="macUnmineable.app"
APP_DIR="${DIST_DIR}/${APP_NAME}"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
APP_BIN="${MACOS_DIR}/macUnmineable"
PLIST_PATH="${CONTENTS_DIR}/Info.plist"
SOURCE_FILE="${ROOT_DIR}/native/MacUnmineableNative.swift"
RUNTIME_DIR="${RESOURCES_DIR}/runtime"
VERSION_FILE="${ROOT_DIR}/VERSION"
# Local app builds embed the managed miners by default so the generated bundle
# works out of the box. Public source releases stay binary-free because the repo
# does not commit those third-party payloads.
DOWNLOAD_MANAGED_MINERS="${DOWNLOAD_MANAGED_MINERS:-1}"
EMBED_MANAGED_MINERS="${EMBED_MANAGED_MINERS:-1}"

if [[ ! -f "${SOURCE_FILE}" ]]; then
  echo "Missing source file: ${SOURCE_FILE}" >&2
  exit 1
fi

if [[ ! -f "${VERSION_FILE}" ]]; then
  echo "Missing version metadata: ${VERSION_FILE}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${VERSION_FILE}"

if [[ -z "${APP_VERSION:-}" || -z "${APP_BUILD:-}" ]]; then
  echo "VERSION must define APP_VERSION and APP_BUILD" >&2
  exit 1
fi

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RUNTIME_DIR}"

if [[ "${DOWNLOAD_MANAGED_MINERS}" == "1" ]]; then
  echo "Ensuring managed miners are installed before bundling..."
  [[ -x "${ROOT_DIR}/miners/xmrig/xmrig" ]] || "${ROOT_DIR}/scripts/install_xmrig.sh" --force
  [[ -x "${ROOT_DIR}/miners/cpuminer-scash/minerd" ]] || "${ROOT_DIR}/scripts/install_cpuminer_scash.sh" --force
fi

cat > "${PLIST_PATH}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>English</string>
    <key>CFBundleDisplayName</key>
    <string>macUnmineable</string>
    <key>CFBundleExecutable</key>
    <string>macUnmineable</string>
    <key>CFBundleIdentifier</key>
    <string>org.macunmineable.native</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>macUnmineable</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${APP_BUILD}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
  </dict>
</plist>
EOF

swiftc \
  -O \
  -parse-as-library \
  -framework SwiftUI \
  -framework AppKit \
  -framework Foundation \
  -framework Network \
  "${SOURCE_FILE}" \
  -o "${APP_BIN}"

mkdir -p "${RUNTIME_DIR}/scripts" "${RUNTIME_DIR}/miners"
# Only bundle runtime-facing scripts. Build/publish helpers stay in the repo.
cp "${ROOT_DIR}/scripts/install_xmrig.sh" "${ROOT_DIR}/scripts/install_cpuminer_scash.sh" "${RUNTIME_DIR}/scripts/"

stage_runtime_dir() {
  local name="$1"
  local binary_name="$2"
  local source_dir="${ROOT_DIR}/miners/${name}"
  local destination_dir="${RUNTIME_DIR}/miners/${name}"

  [[ -d "${source_dir}" ]] || return 0

  mkdir -p "${destination_dir}"

  if [[ -f "${source_dir}/README.md" ]]; then
    cp "${source_dir}/README.md" "${destination_dir}/README.md"
  fi

  if [[ "${EMBED_MANAGED_MINERS}" == "1" && -f "${source_dir}/${binary_name}" ]]; then
    cp "${source_dir}/${binary_name}" "${destination_dir}/${binary_name}"
  fi
}

stage_runtime_dir "xmrig" "xmrig"
stage_runtime_dir "cpuminer-scash" "minerd"
stage_runtime_dir "srbminer" "SRBMiner-MULTI"

chmod +x "${APP_BIN}" || true
chmod +x "${RUNTIME_DIR}"/scripts/install_*.sh || true
if [[ -f "${RUNTIME_DIR}/miners/xmrig/xmrig" ]]; then
  chmod +x "${RUNTIME_DIR}/miners/xmrig/xmrig" || true
fi
if [[ -f "${RUNTIME_DIR}/miners/cpuminer-scash/minerd" ]]; then
  chmod +x "${RUNTIME_DIR}/miners/cpuminer-scash/minerd" || true
fi
if [[ -f "${RUNTIME_DIR}/miners/srbminer/SRBMiner-MULTI" ]]; then
  chmod +x "${RUNTIME_DIR}/miners/srbminer/SRBMiner-MULTI" || true
fi

echo "Built native app bundle: ${APP_DIR}"
echo "Version: ${APP_VERSION} (${APP_BUILD})"
echo "Launch by double-clicking in Finder."
