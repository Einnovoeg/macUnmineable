# macUnmineable

`macUnmineable` is a native SwiftUI macOS app for Apple Silicon that provides a
wallet-first GUI for unMineable mining workflows.

Current source release: `v1.0.0`

## What This App Does

1. Choose the payout coin from the full live unMineable catalog.
2. Paste your wallet address.
3. Select an Apple Silicon-compatible mining algorithm and backend.
4. Start and stop mining from a native macOS window.
5. Install, update, validate, and inspect managed miner binaries from secondary panels.
6. View live wallet stats from unMineable in a dedicated `Wallet` tab, including current balance, payout threshold, aggregate wallet hashrate, active workers, and total paid.
7. Customize appearance with `System`, `Light`, or `Dark` mode plus accent palette options.

## Supported Backends

The launcher only exposes Apple Silicon backends that were verified as real,
workable macOS paths for this app:

- `XMRig` on CPU for `RandomX`, `GhostRider`, and `KawPow`
- `cpuminer-scash` on CPU for `RandomX`

Unsupported or unverified backends are intentionally kept out of the launcher
UI. The payout coin is independent from the miner backend.

### Compatibility Review

Checked on **April 12, 2026** against official upstream release feeds and local
startup behavior:

| Miner | macOS Support |
|-------|---------------|
| XMRig | Official macOS arm64 release available and verified |
| cpuminer-scash | Official macOS Sonoma arm64 release available and verified locally; upstream repository is archived |
| SRBMiner-MULTI | No official macOS release |
| nanominer | Linux/Windows only |
| BzMiner | Linux/Windows only |
| OneZeroMiner | Linux ELF x86-64 only |

## Known Issues and What Still Needs Work

- **GPU mining is not supported**: no GPU-capable miner is currently bundled or exposed.
- **Algorithm coverage is limited**: only `RandomX`, `GhostRider`, and `KawPow` are available through the verified managed backends.
- **`cpuminer-scash` is archived upstream**: the current Apple Silicon release still works locally for `RandomX`, but long-term maintenance risk is higher than for `XMRig`.
- **Wallet stats are aggregates**: unMineable reports account-level totals for the wallet, not just work done by this app.
- **No live accepted/rejected share view yet**: the app does not currently surface share acceptance or rejection in the GUI.
- **No notarized distribution yet**: the app is not signed or notarized for direct end-user distribution outside local builds.
- **Pool test is TCP-only**: the built-in pool test verifies connectivity, not a full mining protocol handshake.

If you use this repository and encounter problems, please help fix them. Open an
issue, submit a patch, or send a pull request so the project can improve.

## Wallet Stats

`macUnmineable` uses the same public unMineable API family that backs the
official wallet stats pages:

- Address lookup: `/v5/address/{address}?coin={symbol}`
- Account stats: `/v5/account/{uuid}/stats`
- Account summary: `/v5/account/{uuid}/summary`

Wallet stats are read-only and may include activity from other miners pointed at
the same address.

## Repository Layout

- [native/MacUnmineableNative.swift](native/MacUnmineableNative.swift): native SwiftUI app source
- [scripts/build_native_app.sh](scripts/build_native_app.sh): app bundle builder
- [scripts/install_xmrig.sh](scripts/install_xmrig.sh): XMRig installer
- [scripts/install_cpuminer_scash.sh](scripts/install_cpuminer_scash.sh): cpuminer-scash installer
- [scripts/verify.sh](scripts/verify.sh): smoke-test verification script
- [VERSION](VERSION): release metadata
- [CHANGELOG.md](CHANGELOG.md): release history
- [DEPENDENCIES.md](DEPENDENCIES.md): build and runtime requirements
- [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md): third-party credits and license notes
- [LICENSE](LICENSE): project license

`AGENTS.md` exists locally for future agents but is intentionally not published
to GitHub.

## Installation

### Build the App

```bash
./scripts/build_native_app.sh
```

By default the builder downloads and embeds the managed Apple Silicon miner
binaries into the generated `.app` bundle.

For a source-only bundle without embedded miner binaries:

```bash
DOWNLOAD_MANAGED_MINERS=0 EMBED_MANAGED_MINERS=0 ./scripts/build_native_app.sh
```

### Run the App

```bash
open dist/macUnmineable.app
```

On first launch, allow the app to auto-install managed miners if they are
missing, or open `Setup` and install/update them manually.

### Developer Setup

```bash
./scripts/install_xmrig.sh
./scripts/install_cpuminer_scash.sh
```

## Verification

Run the full smoke test:

```bash
./scripts/verify.sh
```

That script:

- type-checks the SwiftUI source
- builds the native app bundle in embedded and source-only modes
- exercises the managed installer scripts
- verifies dry-run startup for the supported XMRig routes
- verifies bounded `cpuminer-scash` startup for `RandomX`
- verifies the built bundle boundaries for managed runtime payloads

## Dependencies

See [DEPENDENCIES.md](DEPENDENCIES.md).

## Security

- Managed tarball installers verify upstream `SHA256SUMS` manifests before installation.
- Installer scripts execute from the read-only app bundle instead of writable copies.
- Custom miner overrides are validated as native macOS Mach-O executables before saving.
- Miner binaries launch via direct executable arguments, not shell interpolation.
- External URLs are restricted to HTTPS destinations.
- Local config and runtime directories use tight user-only permissions.
- Wallet stats requests use HTTPS-only public unMineable endpoints.

## Support

If this project is useful to you, consider supporting it:

**Buy Me a Coffee**: [buymeacoffee.com/einnovoeg](https://buymeacoffee.com/einnovoeg)

## Contributing

Contributions are welcome. If you encounter issues:

1. Check the known issues above.
2. Open an issue with reproduction details.
3. Submit a pull request if you can fix the problem.

Help is especially useful for:

- notarized and signed macOS distribution packaging
- live accepted/rejected share validation
- additional verified Apple Silicon miner backends
- further GUI refinement without increasing clutter

## License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE).

Third-party miners remain under their original upstream licenses. See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for full attribution and
license-boundary details. Public GitHub releases from this repository are
source-only; if you redistribute a locally built bundle that embeds miner
payloads, you are responsible for satisfying the upstream license obligations.

## Credits

- unMineable workflow and wallet stats model: [unMineable](https://unmineable.com/)
- Managed miner integrations: [XMRig](https://github.com/xmrig/xmrig), [cpuminer-scash](https://github.com/scashnetwork/cpuminer-scash)
- UI and ecosystem references: [macmineable](https://github.com/2nthony/macmineable), [EasyMiner](https://github.com/shepp31/EasyMiner), [MacMiner](https://xcreate.com/macminer/)

## Disclaimer

Mining profitability, payout rules, device support, and remote pool behavior can
change at any time. Validate current unMineable settings and upstream miner
support before running long mining sessions.
