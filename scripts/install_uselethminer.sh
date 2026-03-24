#!/usr/bin/env bash
set -euo pipefail
umask 077

# Download the official upstream UselethMiner macOS arm64 package and install
# its payload into the local project runtime tree (or an override path).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_BIN="${USELETHMINER_PATH:-${ROOT_DIR}/miners/uselethminer/uselethminer}"
TARGET_DIR="$(dirname "$TARGET_BIN")"

DRY_RUN=0
FORCE=0
VERSION_TAG=""

usage() {
  cat <<'USAGE'
Usage: ./scripts/install_uselethminer.sh [--dry-run] [--force] [--version <tag>]

Options:
  --dry-run         Resolve release asset and print what would be installed.
  --force           Overwrite existing payload without prompts.
  --version <tag>   Install a specific Git tag (example: v0.23).
USAGE
}

assert_safe_target_bin() {
  local path="$1"
  [[ "$path" = /* ]] || {
    echo "Target path must be absolute." >&2
    exit 1
  }
  [[ "$(basename "$path")" == "uselethminer" ]] || {
    echo "Target binary name must be uselethminer." >&2
    exit 1
  }
  [[ "$(basename "$(dirname "$path")")" == "uselethminer" ]] || {
    echo "Target directory name must be uselethminer." >&2
    exit 1
  }
  [[ "$path" != "/" ]] || {
    echo "Refusing to use / as a target path." >&2
    exit 1
  }
}

primary_interface() {
  route get default 2>/dev/null | awk '/interface: / { print $2; exit }'
}

github_curl() {
  if curl --proto '=https' --tlsv1.2 "$@"; then
    return 0
  fi
  local status=$?
  local fallback_if
  fallback_if="${MACUNMINEABLE_CURL_INTERFACE:-$(primary_interface)}"
  if [[ -n "$fallback_if" ]]; then
    echo "Retrying curl via interface: ${fallback_if}" >&2
    curl --proto '=https' --tlsv1.2 --interface "$fallback_if" "$@"
    return $?
  fi
  return "$status"
}

assert_package_signature() {
  local package_path="$1"
  local signature_output
  signature_output="$(pkgutil --check-signature "$package_path")"
  printf '%s\n' "$signature_output"
  grep -q 'Status: signed by a developer certificate issued by Apple for distribution' <<<"$signature_output" || {
    echo "UselethMiner package signature is not trusted for distribution." >&2
    exit 1
  }
  grep -q 'Notarization: trusted by the Apple notary service' <<<"$signature_output" || {
    echo "UselethMiner package is not notarized." >&2
    exit 1
  }
}

assert_architecture() {
  local path="$1"
  local file_info
  file_info="$(/usr/bin/file -b "$path")"
  echo "Installed architecture: ${file_info}"
  [[ "$file_info" == *"arm64"* ]] || {
    echo "Installed binary is not arm64." >&2
    exit 1
  }
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --version)
      if [[ $# -lt 2 ]]; then
        echo "--version requires a value" >&2
        exit 2
      fi
      VERSION_TAG="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

assert_safe_target_bin "$TARGET_BIN"

OS_NAME="$(uname -s)"
if [[ "$OS_NAME" != "Darwin" ]]; then
  echo "This installer currently supports macOS only (detected: $OS_NAME)." >&2
  exit 1
fi

ARCH_NAME="$(uname -m)"
case "$ARCH_NAME" in
  arm64|aarch64)
    ASSET_PATTERN="macos-arm64.pkg"
    ;;
  *)
    echo "Unsupported CPU architecture for UselethMiner: $ARCH_NAME" >&2
    exit 1
    ;;
esac

if [[ -n "$VERSION_TAG" ]]; then
  API_URL="https://api.github.com/repos/Chainfire/UselethMiner/releases/tags/${VERSION_TAG}"
else
  API_URL="https://api.github.com/repos/Chainfire/UselethMiner/releases/latest"
fi

echo "Resolving UselethMiner release from: $API_URL"
RELEASE_JSON="$(github_curl -fsSL "$API_URL")"

RELEASE_TSV="$(
  {
  printf '%s' "$RELEASE_JSON" | python3 -c '
import json
import sys
pattern = sys.argv[1]
release = json.load(sys.stdin)
assets = release.get("assets", [])
asset = None
for candidate in assets:
    name = str(candidate.get("name", ""))
    if pattern in name:
        asset = candidate
        break
if asset is None:
    raise SystemExit(f"No asset matching {pattern!r} found")
print("\t".join([
    str(release.get("tag_name", "")),
    str(asset.get("name", "")),
    str(asset.get("browser_download_url", "")),
]))
' "$ASSET_PATTERN"
  }
)"

IFS=$'\t' read -r TAG_NAME ASSET_NAME ASSET_URL <<<"$RELEASE_TSV"
if [[ -z "${TAG_NAME}" || -z "${ASSET_NAME}" || -z "${ASSET_URL}" ]]; then
  echo "Failed to resolve release metadata." >&2
  exit 1
fi

echo "Selected release: ${TAG_NAME}"
echo "Selected asset:   ${ASSET_NAME}"
echo "Install target:   ${TARGET_BIN}"

if [[ "$DRY_RUN" == "1" ]]; then
  echo "Dry run complete."
  exit 0
fi

if [[ -x "$TARGET_BIN" && "$FORCE" != "1" ]]; then
  echo "Existing UselethMiner payload found at ${TARGET_DIR}"
  echo "Refusing to overwrite existing UselethMiner payload without --force." >&2
  exit 1
fi

TMP_DIR="$(mktemp -d -t macunmineable-uselethminer.XXXXXX)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

ARCHIVE_PATH="${TMP_DIR}/${ASSET_NAME}"
EXPAND_DIR="${TMP_DIR}/expanded"

echo "Downloading ${ASSET_URL}"
github_curl -fL --retry 3 --connect-timeout 15 -o "$ARCHIVE_PATH" "$ASSET_URL"
assert_package_signature "$ARCHIVE_PATH"

echo "Expanding package"
pkgutil --expand-full "$ARCHIVE_PATH" "$EXPAND_DIR" >/dev/null

PAYLOAD_DIR="${EXPAND_DIR}/Payload"
FOUND_BIN="${PAYLOAD_DIR}/uselethminer"
if [[ ! -f "$FOUND_BIN" ]]; then
  echo "Could not find uselethminer inside package payload." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
find "$TARGET_DIR" -mindepth 1 -maxdepth 1 ! -name "README.md" -exec rm -rf {} + 2>/dev/null || true
cp -R "$PAYLOAD_DIR"/. "$TARGET_DIR"/
chmod +x "$TARGET_DIR/uselethminer"
assert_architecture "$TARGET_DIR/uselethminer"

echo "Installed successfully at ${TARGET_DIR}"
