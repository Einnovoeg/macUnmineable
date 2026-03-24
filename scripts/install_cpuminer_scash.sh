#!/usr/bin/env bash
set -euo pipefail
umask 077

# Download the official upstream cpuminer-scash macOS arm64 release and
# install it into the local project runtime tree (or an override path).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_BIN="${CPUMINER_SCASH_PATH:-${ROOT_DIR}/miners/cpuminer-scash/minerd}"

DRY_RUN=0
FORCE=0
VERSION_TAG=""

usage() {
  cat <<'USAGE'
Usage: ./scripts/install_cpuminer_scash.sh [--dry-run] [--force] [--version <tag>]

Options:
  --dry-run         Resolve release asset and print what would be installed.
  --force           Overwrite existing binary without prompts.
  --version <tag>   Install a specific Git tag (example: v3.0.9).
USAGE
}

assert_safe_target_bin() {
  local path="$1"
  [[ "$path" = /* ]] || {
    echo "Target path must be absolute." >&2
    exit 1
  }
  [[ "$(basename "$path")" == "minerd" ]] || {
    echo "Target binary name must be minerd." >&2
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

verify_sha256() {
  local asset_path="$1"
  local checksums_path="$2"
  local asset_name
  asset_name="$(basename "$asset_path")"
  local expected actual
  expected="$(python3 -c 'import sys
asset = sys.argv[1]
path = sys.argv[2]
with open(path, "r", encoding="utf-8") as fh:
    for line in fh:
        parts = line.strip().split()
        if len(parts) >= 2 and parts[-1].lstrip("*") == asset:
            print(parts[0])
            raise SystemExit(0)
raise SystemExit(1)
' "$asset_name" "$checksums_path")" || {
    echo "Could not find checksum for ${asset_name}." >&2
    exit 1
  }
  actual="$(shasum -a 256 "$asset_path" | awk '{print $1}')"
  if [[ "$actual" != "$expected" ]]; then
    echo "SHA256 mismatch for ${asset_name}." >&2
    echo "Expected: ${expected}" >&2
    echo "Actual:   ${actual}" >&2
    exit 1
  fi
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
    ASSET_PATTERN="macos-sonoma-arm64.tgz"
    ;;
  *)
    echo "Unsupported CPU architecture for cpuminer-scash: $ARCH_NAME" >&2
    exit 1
    ;;
esac

if [[ -n "$VERSION_TAG" ]]; then
  API_URL="https://api.github.com/repos/scashnetwork/cpuminer-scash/releases/tags/${VERSION_TAG}"
else
  API_URL="https://api.github.com/repos/scashnetwork/cpuminer-scash/releases/latest"
fi

echo "Resolving cpuminer-scash release from: $API_URL"
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
checksum = None
for candidate in assets:
    name = str(candidate.get("name", ""))
    if pattern in name:
        asset = candidate
    if name == "SHA256SUMS":
        checksum = candidate
if asset is None:
    raise SystemExit(f"No asset matching {pattern!r} found")
if checksum is None:
    raise SystemExit("No SHA256SUMS asset found")
print("\t".join([
    str(release.get("tag_name", "")),
    str(asset.get("name", "")),
    str(asset.get("browser_download_url", "")),
    str(checksum.get("browser_download_url", "")),
]))
' "$ASSET_PATTERN"
  }
)"

IFS=$'\t' read -r TAG_NAME ASSET_NAME ASSET_URL CHECKSUM_URL <<<"$RELEASE_TSV"
if [[ -z "${TAG_NAME}" || -z "${ASSET_NAME}" || -z "${ASSET_URL}" || -z "${CHECKSUM_URL}" ]]; then
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
  CURRENT_VERSION="$($TARGET_BIN --version 2>/dev/null | head -n 1 || true)"
  if [[ -n "$CURRENT_VERSION" ]]; then
    echo "Existing cpuminer-scash found: ${CURRENT_VERSION}"
  else
    echo "Existing cpuminer-scash binary found at ${TARGET_BIN}"
  fi
  echo "Refusing to overwrite existing cpuminer-scash without --force." >&2
  exit 1
fi

TMP_DIR="$(mktemp -d -t macunmineable-cpuminer-scash.XXXXXX)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

ARCHIVE_PATH="${TMP_DIR}/${ASSET_NAME}"
CHECKSUM_PATH="${TMP_DIR}/SHA256SUMS"
EXTRACT_DIR="${TMP_DIR}/extract"
mkdir -p "$EXTRACT_DIR"

echo "Downloading ${ASSET_URL}"
github_curl -fL --retry 3 --connect-timeout 15 -o "$ARCHIVE_PATH" "$ASSET_URL"

echo "Downloading checksum manifest"
github_curl -fL --retry 3 --connect-timeout 15 -o "$CHECKSUM_PATH" "$CHECKSUM_URL"
verify_sha256 "$ARCHIVE_PATH" "$CHECKSUM_PATH"

echo "Extracting archive"
tar -xzf "$ARCHIVE_PATH" -C "$EXTRACT_DIR"

FOUND_BIN="$(find "$EXTRACT_DIR" -type f -name minerd | head -n 1 || true)"
if [[ -z "$FOUND_BIN" ]]; then
  echo "Could not find minerd binary inside archive." >&2
  exit 1
fi

mkdir -p "$(dirname "$TARGET_BIN")"
install -m 755 "$FOUND_BIN" "$TARGET_BIN"
assert_architecture "$TARGET_BIN"

INSTALLED_VERSION="$($TARGET_BIN --version 2>/dev/null | head -n 1 || true)"
echo "Installed successfully at ${TARGET_BIN}"
if [[ -n "$INSTALLED_VERSION" ]]; then
  echo "Installed version: ${INSTALLED_VERSION}"
fi
