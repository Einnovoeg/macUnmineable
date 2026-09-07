# Changelog

All notable changes to this project are documented in this file.

This project follows Semantic Versioning for release tags.

## [2.0.0] - 2026-09-07

### Added

- Full 2.0 security and hygiene pass: PII sweep (only `buymeacoffee.com/einnovoeg` retained), `.DS_Store` purge, and comprehensive `.gitignore` for `dist/`, caches, secrets, and IDE artifacts
- Expanded `THIRD_PARTY_NOTICES.md` with September 07, 2026 re-verification, pinned release versions (XMRig v6.26.0, cpuminer-scash v3.0.9), and explicit upstream credit + license-boundary language
- Overhauled `DEPENDENCIES.md` with pinned versions, build SDK notes, and shared-library guidance for `/Volumes/Mac Stick/Library`
- Refined `README.md` with unified known-issues section, corrected compatibility table, and Buy Me a Coffee link preserved

### Changed

- Bumped release metadata to **v2.0.0 (build 2)** in `VERSION` and `Info.plist` template
- Pinned build SDK to `macosx26.5` when available in `scripts/build_native_app.sh` and `scripts/verify.sh` to work around Swift 6.4 + macOS 27 SDK breakage of SwiftUI macro plugins (`@State`)
- Cleaned duplicate “Known Issues and Future Work” section in README; dates normalized to 2026-09-07
- Tightened `.gitignore` to exclude `AGENTS.md`, `sessions*.md`, `*.app`, `.env`, certificates, and downloaded miner tarballs

### Fixed

- **Build break on macOS 27 SDK + CLT 14 / Swift 6.4**: `swiftc` now resolves `SwiftUIMacros.StateMacro` by selecting `macosx26.5` SDK; verified via `./scripts/verify.sh` end-to-end
- Verified dry-run for XMRig `rx`/`gr`/`kawpow` against `*.unmineable.com:3333` and bounded `cpuminer-scash` RandomX startup to `rx.unmineable.com:3333` (8 s window, `Starting Stratum …` + `miner threads started`)
- Removed stale `dist/` previews (`AppIcon-1024.png`, `iconset`, `macunmineable-app-icon-preview.png`) and purged `.DS_Store` from tracked tree

### Security

- Re-confirmed installer hygiene:
  - HTTPS-only downloads (`curl --proto '=https' --tlsv1.2`) for GitHub releases
  - `SHA256SUMS` manifest verification before `tar -xzf`
  - Mach-O `arm64` architecture assertion via `/usr/bin/file`
  - `umask 077`, `700`/`600` permissions on `Application Support` and `local_config.json`
  - No shell interpolation for miner argv; direct `Process` arguments only
  - External `open` restricted to `https://` and `buymeacoffee.com/einnovoeg`
- Re-audited wallet handling: no hardcoded addresses, no PII at rest, config writes are atomic with tight perms

### Known Issues and Limitations (unchanged from 1.0, re-affirmed for 2.0)

- **GPU mining is not supported**: no GPU-capable miner is currently bundled or exposed
- **Algorithm coverage is limited**: only `RandomX`, `GhostRider`, and `KawPow` via verified CPU backends
- **`cpuminer-scash` is archived upstream**: current Apple Silicon release still works locally for `RandomX`, but long-term maintenance risk is higher than for `XMRig`
- **Wallet stats are aggregates**: unMineable reports account-level totals, not just this app
- **No live accepted/rejected share view yet**
- **No notarized distribution yet**: app is not signed/notarized for direct end-user distribution outside local builds
- **Pool test is TCP-only**: verifies connectivity, not a full Stratum handshake

If you encounter problems, please help fix them — open an issue or submit a pull request.

### Documentation

- `AGENTS.md` remains **local-only** (gitignored) for future agents; not published to GitHub
- `sessions-*.md` is local-only per `.gitignore`

### Verification

- `swiftc` type-check (pinned SDK)
- Embedded + source-only app bundle builds
- Isolated installer runs for both miners via `$TMPDIR`
- Dry-run validation for `rx`/`gr`/`kawpow`
- Bounded cpuminer-scash startup to `rx.unmineable.com:3333`

---

## [1.0.0] - 2026-04-12

### Added

- Native SwiftUI macOS app for Apple Silicon providing a wallet-first GUI for unMineable mining workflows
- Single-window dashboard with secondary sheets for setup, advanced options, logs, and status information
- Live wallet stats from the public unMineable API, including current balance, payout threshold, aggregate wallet hashrate, active worker count, active algorithm count, and total paid
- Searchable payout coin picker with local caching and a bundled fallback catalog
- Appearance controls for System, Light, and Dark modes plus accent palette selection
- Managed Apple Silicon miner integrations for XMRig and cpuminer-scash with in-app install and update actions
- Built-in managed miner validation, menu bar controls, and detailed hover tooltips across the GUI
- Bounded `cpuminer-scash` startup verification against `rx.unmineable.com` in the repeatable smoke-test script

### Changed

- Consolidated the project to a single canonical GitHub release track for `1.0.0`
- Tightened the main window layout so the mining dashboard fits more comfortably without slight scrolling at normal window sizes
- Replaced the broken header theme shortcut with a real theme menu that changes appearance mode and accent palette directly from the dashboard header
- Reworked the generated app icon to use a darker lowercase `u` mark and a cooler blue/slate palette
- Restricted the launcher surface to Apple Silicon miner backends that are actually bundled, verifiable, and runnable in this app
- Cleaned the repository docs, dependency list, license notes, and version metadata for a publish-safe 1.0 release

### Security

- Managed tarball installers verify upstream `SHA256SUMS` manifests before installation
- Installer scripts execute from the read-only app bundle rather than writable copies
- Custom miner overrides are validated as native macOS Mach-O executables before saving
- Miner binaries launch via direct executable arguments rather than shell interpolation
- External links are restricted to HTTPS destinations
- Local config and runtime directories use tight user-only permissions
- Wallet stats requests use HTTPS-only public unMineable endpoints
- Rechecked `cpuminer-scash` licensing directly from the upstream `LICENSE` and `COPYING` files

### Known Issues and Limitations

- GPU mining is not supported
- Supported algorithms remain limited to the verified CPU-capable Apple Silicon paths
- Wallet stats are account-level aggregates for the selected wallet
- Accepted and rejected share counts are not yet surfaced in the GUI
- The app is not yet signed or notarized for direct end-user distribution
- The pool test verifies TCP connectivity only

### Documentation

- README now explicitly documents what does not work yet and where help is needed
- Repository docs ask users and contributors to help fix issues they encounter
- `AGENTS.md` remains available locally for future agents but is intentionally excluded from GitHub

### Verification

- Type-checked the native SwiftUI app
- Re-ran the full smoke verification suite
- Rebuilt the embedded and source-only app bundle shapes
- Revalidated dry-run startup against the supported unMineable mining routes
- Revalidated bounded `cpuminer-scash` startup against `rx.unmineable.com`
