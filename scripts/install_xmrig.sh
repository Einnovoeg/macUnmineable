#!/usr/bin/env bash
set -euo pipefail

# Download the official upstream XMRig release for this Mac architecture and
# install it into the local project runtime tree (or an override path).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_BIN="${XMRIG_PATH:-${ROOT_DIR}/miners/xmrig/xmrig}"

DRY_RUN=0
FORCE=0
VERSION_TAG=""

usage() {
  cat <<'EOF'
Usage: ./scripts/install_xmrig.sh [--dry-run] [--force] [--version <tag>]

Options:
  --dry-run         Resolve release asset and print what would be installed.
  --force           Overwrite existing binary without prompts.
  --version <tag>   Install a specific Git tag (example: v6.25.0).
EOF
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

OS_NAME="$(uname -s)"
if [[ "$OS_NAME" != "Darwin" ]]; then
  echo "This installer currently supports macOS only (detected: $OS_NAME)." >&2
  exit 1
fi

ARCH_NAME="$(uname -m)"
case "$ARCH_NAME" in
  arm64|aarch64)
    ARCH_TOKEN="arm64"
    ;;
  x86_64)
    ARCH_TOKEN="x64"
    ;;
  *)
    echo "Unsupported CPU architecture: $ARCH_NAME" >&2
    exit 1
    ;;
esac

if [[ -n "$VERSION_TAG" ]]; then
  API_URL="https://api.github.com/repos/xmrig/xmrig/releases/tags/${VERSION_TAG}"
else
  API_URL="https://api.github.com/repos/xmrig/xmrig/releases/latest"
fi

echo "Resolving XMRig release from: $API_URL"
RELEASE_JSON="$(curl -fsSL "$API_URL")"

RELEASE_TSV="$(
  printf '%s' "$RELEASE_JSON" | python3 -c '
import json
import sys

arch = sys.argv[1]
release = json.load(sys.stdin)
assets = release.get("assets", [])

def pick_asset():
    needle = f"macos-{arch}.tar.gz"
    for asset in assets:
        name = str(asset.get("name", ""))
        if needle in name:
            return asset
    for asset in assets:
        name = str(asset.get("name", "")).lower()
        if "macos" in name and arch in name and name.endswith(".tar.gz"):
            return asset
    return None

asset = pick_asset()
if not asset:
    raise SystemExit(f"No macOS {arch} release asset found")

print(
    "\t".join(
        [
            str(release.get("tag_name", "")),
            str(asset.get("name", "")),
            str(asset.get("browser_download_url", "")),
        ]
    )
)
' "$ARCH_TOKEN"
)"

IFS=$'\t' read -r TAG_NAME ASSET_NAME ASSET_URL <<<"$RELEASE_TSV"
if [[ -z "${TAG_NAME}" || -z "${ASSET_NAME}" || -z "${ASSET_URL}" ]]; then
  echo "Failed to resolve release metadata." >&2
  exit 1
fi

if [[ -z "$ASSET_URL" ]]; then
  echo "Release asset URL is empty." >&2
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
    echo "Existing XMRig found: ${CURRENT_VERSION}"
  else
    echo "Existing XMRig binary found at ${TARGET_BIN}"
  fi
fi

TMP_DIR="$(mktemp -d -t macunmineable-xmrig.XXXXXX)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

ARCHIVE_PATH="${TMP_DIR}/${ASSET_NAME}"
EXTRACT_DIR="${TMP_DIR}/extract"
mkdir -p "$EXTRACT_DIR"

echo "Downloading ${ASSET_URL}"
curl -fL --retry 3 --connect-timeout 15 -o "$ARCHIVE_PATH" "$ASSET_URL"

echo "Extracting archive"
tar -xzf "$ARCHIVE_PATH" -C "$EXTRACT_DIR"

FOUND_BIN="$(find "$EXTRACT_DIR" -type f -name xmrig | head -n 1 || true)"
if [[ -z "$FOUND_BIN" ]]; then
  echo "Could not find xmrig binary inside archive." >&2
  exit 1
fi

mkdir -p "$(dirname "$TARGET_BIN")"
install -m 755 "$FOUND_BIN" "$TARGET_BIN"

INSTALLED_VERSION="$($TARGET_BIN --version 2>/dev/null | head -n 1 || true)"
echo "Installed successfully at ${TARGET_BIN}"
if [[ -n "$INSTALLED_VERSION" ]]; then
  echo "Installed version: ${INSTALLED_VERSION}"
fi
