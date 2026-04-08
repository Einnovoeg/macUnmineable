# AGENTS.md

This file is for future agents working in this repository.

## 1. Point of the Project

`macUnmineable` is a native SwiftUI macOS app for Apple Silicon that provides a
wallet-first GUI for unMineable mining workflows.

The product goal is:
- keep the main flow simple: coin, wallet, algorithm, hardware, start/stop
- use a real native macOS UI instead of a local web/server wrapper
- only expose miner backends that actually work on Apple Silicon macOS
- keep setup, validation, logs, and advanced controls in secondary panels
- show live wallet stats from unMineable inside the app
- keep the project secure, documented, and license-compliant

Core files:
- `native/MacUnmineableNative.swift`: native SwiftUI app
- `scripts/build_native_app.sh`: app bundle builder
- `scripts/verify.sh`: smoke-test and release verification
- `scripts/install_xmrig.sh`: managed XMRig installer
- `scripts/install_cpuminer_scash.sh`: managed cpuminer-scash installer
- `README.md`: user-facing documentation
- `THIRD_PARTY_NOTICES.md`: upstream credit and license boundary notes
- `CHANGELOG.md` and `VERSION`: release metadata

## 2. What Has Been Done

Current project state as of `v0.5.0`:
- the abandoned local web/server prototype was removed; this is a native macOS app
- the GUI was rebuilt into a single-window dashboard with secondary sheets for setup, advanced options, logs, and status
- hover tooltips were added across the GUI
- appearance controls were added for `System`, `Light`, and `Dark` modes plus accent palettes
- setup was reorganized into tabs and the main app bundle now includes a custom icon
- coin selection uses a searchable live unMineable catalog with local caching
- wallet stats now use the public unMineable API to show balance, payout threshold, aggregate wallet hashrate, worker count, and total paid
- the app now reflects the real Apple Silicon backend model instead of pretending unsupported miners are available
- unsupported `UselethMiner` and `SRBMiner` launcher paths were removed from the app and the stale repo payloads were deleted
- security hardening was added around installer execution, custom binary validation, config permissions, and external-link handling
- README, dependency docs, notices, license, changelog, and `.gitignore` were cleaned up
- personal machine-specific strings were removed from tracked files except where explicitly requested by the user
- the Buy Me a Coffee link was intentionally retained: `https://buymeacoffee.com/einnovoeg`

Verified launcher backend model:
- built-in managed: `XMRig`
- built-in managed: `cpuminer-scash`
- not exposed in the launcher: `UselethMiner`, `SRBMiner`, `nanominer`, `BzMiner`, `OneZeroMiner`

Important historical decisions:
- do not reintroduce a local server/web-app wrapper
- do not fake miner support on Apple Silicon
- do not present payout coin choice as if it implied a different miner backend
- do not bundle third-party miner payloads into source control
- only add a new built-in miner if it has a real official macOS-compatible path and a license/distribution model that can be defended

Verification already in place:
- `./scripts/verify.sh` type-checks the app, builds it, tests the managed installers, and runs XMRig dry-runs against unMineable pools
- `scripts/verify.sh` verifies both bundle shapes:
  - embedded managed-miner app bundle
  - source-only app bundle
- public GitHub releases are source-only; they do not attach third-party miner binaries

Canonical repository:
- use `Einnovoeg/macUnmineable`
- do not create duplicate repos for the same project

## 3. Steps That Need To Be Taken Next

When you make changes, follow this order:

1. Keep the product honest.
- Do not add unsupported miners just to make the matrix look larger.
- If you add a miner, verify official Apple Silicon/macOS support, installation model, and license requirements first.
- Update `THIRD_PARTY_NOTICES.md`, `README.md`, `DEPENDENCIES.md`, and the support matrix in the app if anything changes.

2. Keep the UI polished.
- Every interactive GUI control should have a hover tooltip.
- Keep the main window simple and avoid clutter.
- Put setup, diagnostics, and less-common controls in secondary sheets or menus.

3. Keep the code secure.
- Continue launching miners with direct executable arguments, not shell-interpolated user input.
- Keep external URLs restricted to HTTPS.
- Keep custom miner validation restricted to native macOS Mach-O executables.
- Keep config/runtime permissions tight.
- Keep unMineable wallet stats fetches read-only and debounced.

4. Verify before publishing.
- Run:
  - `bash -n scripts/build_native_app.sh scripts/verify.sh scripts/install_xmrig.sh scripts/install_cpuminer_scash.sh`
  - `swiftc -parse-as-library -typecheck native/MacUnmineableNative.swift -framework SwiftUI -framework AppKit -framework Foundation -framework Network`
  - `./scripts/verify.sh`
- If you change UI or runtime behavior, smoke-launch the built app bundle too.

5. Maintain release hygiene.
- bump `VERSION`
- update `CHANGELOG.md`
- keep `README.md` aligned with the real shipping behavior
- publish releases only from the canonical `macUnmineable` repo

6. Deploy the local app copy when done.
- rebuild the bundle if needed with `./scripts/build_native_app.sh`
- replace the installed app at `/Users/einnovoeg/Applications/macUnmineable.app`
- use a full bundle replacement, not a partial file copy into the app bundle

## Current Priority List

If no more specific user request is given, the next useful work is:
1. notarized/signable macOS distribution packaging
2. a live wallet-backed accepted-share validation pass
3. adding another built-in Apple Silicon miner only if it clears technical and license review
4. incremental GUI refinement without increasing complexity

## Do Not Regress

- no browser-tab GUI
- no localhost control server as the main app architecture
- no duplicate GitHub repos for the same project
- no pretending unsupported miners are built-in and working
- no release that contradicts the actual runtime model
