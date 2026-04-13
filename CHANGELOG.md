# Changelog

All notable changes to this project are documented in this file.

This project follows Semantic Versioning for release tags.

## [1.0.0] - 2026-04-15

### Added
- Jumped to version 1.0.0 for first official release.
- Added copy buttons to wallet address and pool host fields for easier interaction.
- Added subtle breathing animations to the status pill when mining is active.
- Added numeric text transitions to hashrate displays for a more polished feel.
- Enhanced code with detailed documentation comments for all major components and methods.

### Changed
- Polished the overall GUI layout and user feedback.
- Ensured absolute removal of PII and machine-specific paths from the repository.
- Re-verified all third-party license compliance and credits.
- Applied the MIT License to the project source.
- Standardized the README and DEPENDENCIES for general use.

## [0.5.2] - 2026-04-12

### Changed

- Replaced the main-window theme shortcut with a real theme menu that changes
  appearance mode and accent palette directly from the dashboard header.
- Tightened card spacing, outer padding, and vertical gaps in the main window
  so the mining dashboard fits more comfortably without requiring a slight
  scroll on normal window sizes.
- Reworked the generated app icon to use a darker lowercase `u` mark and a
  cooler blue/slate palette instead of the previous mint-heavy look.

### Fixed

- Removed the broken header theme-button behavior where clicking the palette
  icon only attempted to open settings instead of changing the theme.

### Verification

- Type-checked the native SwiftUI app after the header-control and layout
  changes.
- Regenerated the app icon, rebuilt the app bundle, and re-ran the full smoke
  verification suite.

## [0.5.1] - 2026-04-08

### Changed

- Moved wallet balance, payout threshold, and aggregate wallet activity out of
  the main mining dashboard and into a dedicated top-level `Wallet` tab.
- Added a main-window tab switcher so mining and wallet-monitoring views stay
  separated without adding another popup window.

### Fixed

- Removed wallet-stat density from the `Mine` tab so the core mining flow is
  cleaner and easier to scan.

### Verification

- Type-checked the native SwiftUI app after the tab split.
- Re-ran the full smoke verification suite and rebuilt the deployed app bundle.

## [0.5.0] - 2026-04-07

### Added

- Added live wallet stats from the public unMineable API, including current
  balance, payout threshold, aggregate wallet hashrate, active worker count,
  active algorithm count, total paid, and last payment time.
- Added automatic wallet-stats refresh scheduling so the selected wallet stays
  in sync with unMineable without requiring manual refresh after every change.

### Changed

- Restricted the launcher surface to the Apple Silicon miner backends that are
  actually bundled, verifiable, and runnable in this app: `XMRig` and
  `cpuminer-scash`.
- Removed stale repository payloads and launcher-facing references for
  unsupported `UselethMiner` and `SRBMiner` paths.
- Updated the README, dependency list, third-party notices, AGENTS handoff,
  and support matrix to match the corrected runtime model.

### Fixed

- Corrected the live coin-catalog fetch URL to use the proper
  `api.unmineable.com` host.
- Removed the last Setup-sheet notes that still implied unsupported miners were
  relevant choices inside this launcher.

### Verification

- Verified the public unMineable wallet endpoints live and matched the in-app
  decoding path against real wallet/account responses.
- Re-ran full smoke verification, including typecheck, managed installer
  checks, embedded/source-only bundle builds, and dry-run starts against
  `rx.unmineable.com`, `ghostrider.unmineable.com`, and `kp.unmineable.com`.

## [0.4.6] - 2026-04-07

### Fixed

- Reworked the Setup sheet layout to stop long notes and validation content from
  clipping horizontally in the currently open panel.
- Split the Setup sheet into tabbed sections so overview, miner management,
  path overrides, validation, and installer output are easier to navigate.
- Converted long setup notes to wrapped selectable text so the panel remains
  readable at normal window sizes.
- Replaced the raw `TextEditor` log panes in Setup with read-only scrollable log
  panels that handle long validation and installer output more cleanly.
- Simplified custom path editing rows so the action buttons no longer get
  squeezed against the text field.
- Replaced the top-bar folder shortcut with a controls/settings-style icon that
  matches the function of the setup panel more closely.

### Added

- Added a generated macOS `.icns` app icon derived from the mint unMineable
  “U” language but adapted into an original rounded-square application icon.
- Integrated icon generation into the native app bundle build pipeline.

### Verification

- Captured the live app window and used that screenshot to drive the layout
  fixes in the Setup sheet.
- Rebuilt and smoke-launched the updated app bundle successfully.

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
