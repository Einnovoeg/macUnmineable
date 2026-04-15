# Changelog

All notable changes to this project are documented in this file.

This project follows Semantic Versioning for release tags.

## [1.0.0] - 2026-04-12

### Added

- Native SwiftUI macOS app for Apple Silicon providing a wallet-first GUI for unMineable mining workflows.
- Single-window dashboard with secondary sheets for setup, advanced options, logs, and status information.
- Live wallet stats from the public unMineable API, including current balance, payout threshold, aggregate wallet hashrate, active worker count, active algorithm count, and total paid.
- Searchable payout coin picker with local caching and a bundled fallback catalog.
- Appearance controls for System, Light, and Dark modes plus accent palette selection.
- Managed Apple Silicon miner integrations for XMRig and cpuminer-scash with in-app install and update actions.
- Built-in managed miner validation, menu bar controls, and detailed hover tooltips across the GUI.
- Bounded `cpuminer-scash` startup verification against `rx.unmineable.com` in the repeatable smoke-test script.

### Changed

- Consolidated the project to a single canonical GitHub release track for `1.0.0`.
- Tightened the main window layout so the mining dashboard fits more comfortably without slight scrolling at normal window sizes.
- Replaced the broken header theme shortcut with a real theme menu that changes appearance mode and accent palette directly from the dashboard header.
- Reworked the generated app icon to use a darker lowercase `u` mark and a cooler blue/slate palette.
- Restricted the launcher surface to Apple Silicon miner backends that are actually bundled, verifiable, and runnable in this app.
- Cleaned the repository docs, dependency list, license notes, and version metadata for a publish-safe 1.0 release.

### Security

- Managed tarball installers verify upstream `SHA256SUMS` manifests before installation.
- Installer scripts execute from the read-only app bundle rather than writable copies.
- Custom miner overrides are validated as native macOS Mach-O executables before saving.
- Miner binaries launch via direct executable arguments rather than shell interpolation.
- External links are restricted to HTTPS destinations.
- Local config and runtime directories use tight user-only permissions.
- Wallet stats requests use HTTPS-only public unMineable endpoints.
- Rechecked `cpuminer-scash` licensing directly from the upstream `LICENSE` and `COPYING` files because GitHub does not machine-assert the repository SPDX identifier.

### Known Issues and Limitations

- GPU mining is not supported.
- Supported algorithms remain limited to the verified CPU-capable Apple Silicon paths.
- Wallet stats are account-level aggregates for the selected wallet.
- Accepted and rejected share counts are not yet surfaced in the GUI.
- The app is not yet signed or notarized for direct end-user distribution.
- The pool test verifies TCP connectivity only.

### Documentation

- README now explicitly documents what does not work yet and where help is needed.
- Repository docs ask users and contributors to help fix issues they encounter.
- `AGENTS.md` remains available locally for future agents but is intentionally excluded from GitHub.

### Verification

- Type-checked the native SwiftUI app.
- Re-ran the full smoke verification suite.
- Rebuilt the embedded and source-only app bundle shapes.
- Revalidated dry-run startup against the supported unMineable mining routes.
- Revalidated bounded `cpuminer-scash` startup against `rx.unmineable.com`.
