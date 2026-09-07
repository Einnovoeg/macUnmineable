# macUnmineable

`macUnmineable` is a native SwiftUI macOS app for **Apple Silicon** that provides a
wallet-first GUI for unMineable mining workflows — pick your payout coin, paste your
wallet, choose a verified CPU backend, and mine.

Current source release: **`v2.0.0`** · MIT License · macOS 13+ · Apple Silicon only

> **Buy Me a Coffee**: [buymeacoffee.com/einnovoeg](https://buymeacoffee.com/einnovoeg) — if this saves you time, consider supporting it.

---

## What This App Does

1. Choose the payout coin from the full live unMineable catalog (with local fallback)
2. Paste your wallet address (only required identity field)
3. Select an Apple Silicon-compatible mining algorithm and backend
4. Start and stop mining from a native macOS window
5. Install, update, validate, and inspect managed miner binaries from Setup
6. View live wallet stats from unMineable in a dedicated **Wallet** tab — balance, payout threshold, aggregate hashrate, active workers, and total paid
7. Customize appearance with `System` / `Light` / `Dark` plus accent palettes

## Supported Backends

The launcher only exposes **Apple Silicon backends that are bundled, verifiable, and runnable**:

- **XMRig** on CPU for `RandomX`, `GhostRider`, `KawPow` (v6.26.0, active upstream)
- **cpuminer-scash** on CPU for `RandomX` (v3.0.9, upstream archived but verified latest)

Unsupported or unverified backends are intentionally hidden. The payout coin is independent from the miner backend.

### Compatibility Review

Checked on **September 07, 2026** against official upstream release feeds and local startup behavior:

| Miner | macOS Support | Notes |
|-------|---------------|-------|
| **XMRig** | ✅ Official `macos-arm64` release | Dry-run verified for `rx`/`gr`/`kawpow` against `*.unmineable.com:3333` |
| **cpuminer-scash** | ✅ Official `macos-sonoma-arm64` release | Bounded startup verified for `RandomX` on Apple Silicon; upstream **archived** — higher maintenance risk |
| SRBMiner-MULTI | ❌ No macOS release | — |
| nanominer | ❌ Linux/Windows only | — |
| BzMiner | ❌ Linux/Windows only | — |
| OneZeroMiner | ❌ Linux ELF x86-64 only | — |

## Screenshots

> Run the app locally to capture screenshots — the GUI is best evaluated live given the theme variants (System/Light/Dark × Mint/Ocean/Ember/Citrus).

## Installation

### 1) Prerequisites

- macOS 13+ on Apple Silicon
- Xcode Command Line Tools (`xcode-select --install`)
- `pip3 install Pillow` for icon generation (see `DEPENDENCIES.md` for shared-library guidance)

### 2) Build the App

```bash
./scripts/build_native_app.sh
```

By default the builder downloads and embeds the managed Apple Silicon miner binaries so the `.app` works out of the box.

For a **source-only** bundle without embedded binaries (what GitHub releases publish):

```bash
DOWNLOAD_MANAGED_MINERS=0 EMBED_MANAGED_MINERS=0 ./scripts/build_native_app.sh
```

### 3) Run the App

```bash
open dist/macUnmineable.app
```

On first launch, allow auto-install if a managed miner is missing, or open **Setup → Miners** to install/update manually.

### 4) Developer Setup (alternative)

```bash
./scripts/install_xmrig.sh            # or --dry-run / --version v6.26.0
./scripts/install_cpuminer_scash.sh   # or --dry-run / --version v3.0.9
```

## Wallet Stats

`macUnmineable` uses the same public unMineable API family that powers the official stats pages:

- Address lookup: `GET https://api.unmineable.com/v5/address/{address}?coin={symbol}`
- Account stats: `GET https://api.unmineable.com/v5/account/{uuid}/stats`
- Account summary: `GET https://api.unmineable.com/v5/account/{uuid}/summary`

Wallet stats are **read-only** and **account-level** — they may include activity from other miners pointed at the same address.

## Repository Layout

```
native/MacUnmineableNative.swift     # SwiftUI app source (single-file, MARK-separated)
scripts/build_native_app.sh          # app bundle builder (SDK-pinned)
scripts/install_xmrig.sh             # XMRig installer (HTTPS + SHA256)
scripts/install_cpuminer_scash.sh    # cpuminer-scash installer (HTTPS + SHA256)
scripts/generate_app_icon.py         # app icon generator (Pillow)
scripts/verify.sh                    # smoke-test verification
VERSION                              # release metadata (APP_VERSION / APP_BUILD)
CHANGELOG.md                         # release history
DEPENDENCIES.md                      # build/runtime requirements
THIRD_PARTY_NOTICES.md               # attribution + license boundaries
LICENSE                              # MIT (project source)
```

`AGENTS.md` and `sessions*.md` exist **locally only** (gitignored) for maintainers/agents.

## Verification

Full smoke test (isolated, does not depend on your local `miners/`):

```bash
./scripts/verify.sh
```

What it covers:

- `swiftc` type-check (pinned to `macosx26.5` SDK when available)
- Embedded and source-only bundle builds
- Isolated installer runs for both miners via `$TMPDIR`
- Dry-run startup for XMRig `rx`/`gr`/`kawpow` (`--dry-run`)
- Bounded `cpuminer-scash` startup for `RandomX` to `rx.unmineable.com:3333` (8 s)
- Bundle boundary checks (no stray binaries in source-only shape)

> **Build note (Sept 2026)**: Swift 6.4 + CLT 14 + macOS 27 SDK breaks `@State` macro resolution via CLI `swiftc`. The build scripts now prefer `macosx26.5` when present; if you see `SwiftUIMacros.StateMacro not found`, install CLT 26.5 or full Xcode.

## Dependencies

See [DEPENDENCIES.md](DEPENDENCIES.md) for pinned versions and full requirements.

## Security

- Installer downloads use **HTTPS only** (`curl --proto '=https' --tlsv1.2`) and verify `SHA256SUMS` before extraction
- Mach-O `arm64` architecture asserted via `/usr/bin/file`
- Local config/runtime dirs use tight perms (`700`/`600`, `umask 077`)
- Custom miner overrides validated as native Mach-O before saving
- Miner execution via direct `Process` argv (no shell interpolation)
- External URLs restricted to `https://`
- Wallet API calls over `https://api.unmineable.com` only
- No hardcoded wallets or secrets in repo

## Known Issues and What Still Needs Work

> **Please help fix what you find** — open an issue or PR if you can improve any of these.

- **GPU mining is not supported**: no GPU-capable miner is bundled or exposed; this is CPU-only on Apple Silicon
- **Algorithm coverage is limited**: only `RandomX`, `GhostRider`, `KawPow` via verified CPU backends
- **`cpuminer-scash` is archived upstream**: still works locally for `RandomX`, but long-term maintenance risk > XMRig
- **Wallet stats are aggregates**: account-level totals, not just this app’s work
- **No live accepted/rejected share view yet**
- **No notarized distribution yet**: not signed/notarized for end-user distribution outside local builds
- **Pool test is TCP-only**: verifies connectivity, not a full Stratum handshake
- **Build toolchain quirk**: CLI builds on macOS 27 SDK need the `26.5` SDK workaround (see Verification)

If you use this repository and hit problems, **please contribute a fix**.

## Support

If this project is useful:

**Buy Me a Coffee**: [buymeacoffee.com/einnovoeg](https://buymeacoffee.com/einnovoeg)

Support is voluntary and does not affect licensing.

## Contributing

1. Check known issues above
2. Open an issue with reproduction details (macOS version, Apple Silicon, logs from `Setup → Validation` / `Installer`)
3. Submit a PR — especially welcome for:
   - notarized/signed distribution packaging
   - live accepted/rejected share validation
   - additional **verified** Apple Silicon miner backends
   - further GUI refinement without increasing clutter

## License

This project’s **original source** is licensed under the **MIT License** — see [LICENSE](LICENSE).

Third-party miners keep their own licenses (XMRig: GPL-3.0-or-later, cpuminer-scash: GPL-2.0). See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for full attribution and boundary details. GitHub releases from this repository are **source-only**; if you redistribute a locally built bundle that embeds miner payloads, you are responsible for satisfying upstream GPL obligations (including source access).

## Credits

- unMineable workflow and wallet stats: [unMineable](https://unmineable.com/)
- Managed miners: [XMRig](https://github.com/xmrig/xmrig), [cpuminer-scash](https://github.com/scashnetwork/cpuminer-scash)
- UI/ecosystem references: [macmineable](https://github.com/2nthony/macmineable), [EasyMiner](https://github.com/shepp31/EasyMiner), [MacMiner](https://xcreate.com/macminer/)

## Disclaimer

Mining profitability, payout rules, device support, and remote pool behavior can change at any time. Validate current unMineable settings and upstream miner support before long mining sessions. This software is provided **as-is** without warranty.

