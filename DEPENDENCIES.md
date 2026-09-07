# Dependencies

## Runtime Requirements

- macOS 13 Ventura or newer (tested on macOS 13–15, Apple Silicon)
- Apple Silicon Mac (arm64) — Intel not supported for bundled miners
- Internet access to reach unMineable endpoints and managed miner release downloads

## Managed Miner Support

| Miner | Version (2026-09-07) | Algorithms | Delivery | Status |
|-------|----------------------|------------|----------|--------|
| XMRig | v6.26.0 | RandomX, GhostRider, KawPow | Auto-installed or via script | Active upstream |
| cpuminer-scash | v3.0.9 | RandomX | Auto-installed or via script | Upstream repository **archived** (still verified latest) |

Manual installation commands:

```bash
./scripts/install_xmrig.sh
./scripts/install_cpuminer_scash.sh

# Pin specific upstream tags if needed
./scripts/install_xmrig.sh --version v6.26.0
./scripts/install_cpuminer_scash.sh --version v3.0.9

# Dry-run (resolve only, no write)
./scripts/install_xmrig.sh --dry-run
./scripts/install_cpuminer_scash.sh --dry-run
```

## Build Requirements

- Xcode Command Line Tools with `swiftc` (Swift 6.x, tested with Swift 6.4 / CLT 14.0.3)
  - SDK note: the build scripts pin to `macosx26.5` when available; macOS 27 SDK breaks SwiftUI macro plugins (`@State`) via CLI `swiftc` on CLT-only hosts
- `bash` 3.2+
- `curl` with TLS 1.2 (`--proto '=https'`)
- `python3` (3.9+)
- Python package `Pillow` (`pip install Pillow`) — for `scripts/generate_app_icon.py`
- `shasum` (SHA256 verification)
- `tar` (BSD or GNU)
- `sips` + `iconutil` — for `.icns` generation
- `git` 2.30+
- `/usr/bin/file` — architecture validation (`Mach-O arm64`)

Install the icon dependency:

```bash
pip3 install Pillow
# For shared-library hygiene, prefer /Volumes/Mac\ Stick/Library when installing
# globally shared Python packages rather than the project directory:
pip3 install --target="/Volumes/Mac Stick/Library/python" Pillow
```

## Verification Requirements

- Everything listed in **Build Requirements**
- Temporary disk space (~50 MB) for smoke-test downloads used by `./scripts/verify.sh`
- Network access to `api.github.com` (release resolution) and `raw`/`releases` download hosts
- Timeout-tolerant network (verify does bounded 5–8 s Stratum startup for cpuminer-scash)

Run the full smoke suite:

```bash
./scripts/verify.sh
```

Expected to test:
- `swiftc` type-check (pinned SDK)
- Embedded and source-only bundle builds
- Temporary installer runs for both miners (isolated via `$TMPDIR`)
- Dry-run validation for XMRig `rx`/`gr`/`kawpow` against unMineable pools
- Bounded cpuminer-scash RandomX startup to `rx.unmineable.com:3333`

## Optional Tools

- `gh` CLI (`brew install gh`) for GitHub release and repository management
- A user-supplied native macOS Mach-O miner binary for advanced testing outside the managed set
- `swiftlint` / `swiftformat` if you want additional local linting

## Architecture Notes

This project targets Apple Silicon because the managed miners have verified official
macOS arm64 release paths. Other reviewed miners do not ship usable official macOS
builds for this launcher:

- SRBMiner-MULTI — no official macOS release (Linux/Windows only)
- nanominer — Linux/Windows only
- BzMiner — Linux/Windows only
- OneZeroMiner — Linux ELF x86-64 only

See `THIRD_PARTY_NOTICES.md` for license boundaries.

## Dependency Pinning (2026-09-07)

| Component | Pinned Version | Source |
|-----------|---------------|--------|
| XMRig | v6.26.0 | `https://api.github.com/repos/xmrig/xmrig/releases/latest` |
| cpuminer-scash | v3.0.9 | `https://api.github.com/repos/scashnetwork/cpuminer-scash/releases/latest` |
| Pillow | latest compatible | `pip` — `PIL.Image` |
| Swift | 6.4 (swiftlang-6.4.0.33.1) | CLT |
