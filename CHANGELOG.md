# Changelog

All notable changes to this project are documented in this file.

This project follows Semantic Versioning for release tags.

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
