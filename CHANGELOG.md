# Changelog

All notable changes to this project are documented in this file.

This project follows Semantic Versioning for release tags.

## [0.4.5] - 2026-04-07

### Fixed

- Reworked coin selection so the app no longer depends on a long inline menu
  for the unMineable coin catalog.
- Added a dedicated searchable coin picker sheet so the full live catalog is
  actually selectable from the GUI.
- Cached the last successful unMineable coin catalog locally so the app can
  keep a full coin list between launches instead of dropping back to the small
  bundled fallback list whenever the network fetch is unavailable.

### Verification

- Confirmed the live unMineable `/v5/coin` response currently returns 84 coins.
- Confirmed the Swift `URLSession` fetch path parses the live catalog
  successfully.

## [0.4.4] - 2026-03-29

### Changed

- Tightened the app bundle builder so embedded managed miners are staged
  deliberately instead of being copied accidentally from a developer-local tree.
- Added an explicit source-only build mode that omits third-party miner binaries
  even when they are present locally, while keeping the default end-user build
  path embedded and ready to run.
- Cleaned dependency documentation and aligned the README with the current build,
  verification, and licensing model.

### Verification

- Expanded `./scripts/verify.sh` so it now proves both supported distribution
  shapes: an embedded app bundle and a source-only app bundle.
- Re-runs the default embedded build after verification so the generated `dist`
  app remains the same bundle shape that end users expect.

## [0.4.3] - 2026-03-24

### Changed

- Removed the orphaned `install_uselethminer.sh` helper and the stale
  `miners/uselethminer` placeholder from the repository now that
  `UselethMiner` is no longer treated as a managed bundled backend.
- Cleaned `.gitignore` to match the corrected backend model.

## [0.4.2] - 2026-03-24

### Changed

- `UselethMiner` is no longer treated as a managed bundled backend. The app now
  recognizes it only when the official upstream macOS package has installed the
  binary to `/usr/local/uselethminer`.
- The `UselethMiner` command builder now uses explicit `--username` and
  `--password` flags so unMineable's `COIN:wallet.worker` login format is
  passed correctly.
- The app bundle builder no longer embeds the broken app-managed UselethMiner
  payload path.

### Fixed

- Corrected a real backend bug where the previous `UselethMiner`
  `username[:password]@host:port` launch string was incompatible with
  unMineable usernames containing `:`.
- Corrected a second backend bug where the app-managed UselethMiner payload
  failed at runtime because upstream macOS packaging expects a system install
  path under `/usr/local/uselethminer`.

## [0.4.1] - 2026-03-23

### Changed

- Added hover tooltips across the native dashboard, settings, menu bar, and
  secondary panels so the GUI explains each action without adding visual noise.
- Reduced privacy leakage in the status panel by showing OS and architecture
  instead of the local machine hostname.
- Cleaned repository documentation to remove machine-specific absolute file
  paths.

### Security

- The app now executes managed installer scripts from the read-only app bundle
  instead of a writable `Application Support` copy.
- Managed installer runs now pass explicit target paths and use `--force`
  intentionally, rather than relying on ambiguous overwrite behavior.
- Custom miner path overrides are validated as native macOS Mach-O executables
  before they are saved.
- Local config and runtime directories are now written with tighter
  user-only permissions.
- Installer scripts now enforce HTTPS/TLS for downloads, require safer target
  path shapes, and refuse to overwrite existing payloads unless `--force` is
  supplied.

## [0.4.0] - 2026-03-23

### Added

- Managed Apple Silicon miner integrations for `cpuminer-scash` and
  `UselethMiner` alongside `XMRig`.
- In-app install/update actions for the managed miners from the native Setup
  panel.
- Build-time embedding of managed miners into the generated `.app` bundle.

### Changed

- Apple Silicon algorithm routing now exposes real first-class backends instead
  of collapsing everything onto `XMRig`.
- The app now runs miner processes from each miner's own payload directory,
  which is required for the bundled `UselethMiner` payload.
- Verification now covers managed installer flows in addition to the existing
  XMRig dry-run pool checks.

### Security

- `XMRig` and `cpuminer-scash` installers now verify downloaded tarballs
  against upstream `SHA256SUMS` manifests before installation.
- `UselethMiner` installation now requires a valid Apple distribution
  signature and notarization result before unpacking the payload.
- Miner process launching continues to use direct executable arguments rather
  than shell interpolation for user input.

## [0.3.0] - 2026-03-13

### Added

- Native SwiftUI macOS app for Apple Silicon with a wallet-first mining flow.
- Single-window dashboard with secondary panels for setup, status, advanced
  options, and logs.
- Appearance controls for `System`, `Light`, and `Dark` modes plus accent
  palette selection.
- Installer and smoke-test scripts for the supported official XMRig path.
- Repository documentation covering installation, dependencies, third-party
  notices, and source distribution rules.

### Changed

- Removed the abandoned local server/web prototype from the repository and
  standardized on the native macOS app.
- Restricted the stock Apple Silicon support matrix to verified paths:
  `XMRig` on CPU for `RandomX`, `GhostRider`, and `KawPow`.
- Moved release metadata into the tracked `VERSION` file and surfaced the app
  version in the GUI.

### Fixed

- Corrected themed input field visibility so wallet text remains readable.
- Added explicit close actions to secondary windows and sheets.
- Normalized impossible Apple Silicon backend and hardware combinations back to
  working defaults instead of leaving the UI in dead states.

### Distribution

- GitHub releases for this repository are source-only. Third-party miner
  binaries are not attached to source releases from this project.
