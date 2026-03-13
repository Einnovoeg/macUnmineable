# Changelog

All notable changes to this project are documented in this file.

This project follows Semantic Versioning for release tags.

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
