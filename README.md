# macUnmineable

`macUnmineable` is a native SwiftUI macOS app for Apple Silicon that wraps the
unMineable mining flow into a wallet-first desktop GUI.

Current source release: `v0.5.1`

The app lets you:

1. Choose the payout coin from the full live unMineable catalog.
2. Paste the wallet address.
3. Choose a real Apple Silicon-compatible mining algorithm/backend combination.
4. Start and stop mining from a native macOS window.
5. Install, update, validate, and inspect the managed miner binaries from
   secondary panels.
6. View live wallet stats from unMineable in a separate `Wallet` tab, including
   current balance, payout threshold, aggregate wallet hashrate, active
   workers, and total paid.

## Current support

The launcher only exposes Apple Silicon backends that were verified as real,
workable macOS paths for this app:

- `XMRig` on CPU for `RandomX`, `GhostRider`, and `KawPow`
- `cpuminer-scash` on CPU for `RandomX`

Unsupported or unverified backends are intentionally kept out of the launcher
UI. The payout coin is independent from the miner backend; many different coins
can still be paid out through the same supported mining algorithm.

### Compatibility review

Checked on **April 7, 2026** against official upstream release feeds and local
startup behavior:

- `XMRig`: official `macOS arm64` release available and locally verified
- `cpuminer-scash`: official `macOS Sonoma arm64` release available and locally verified
- `SRBMiner-MULTI`: no normal official macOS release asset
- `nanominer`: latest official release ships Linux/Windows assets only
- `BzMiner`: latest official release ships Linux/Windows assets only
- `OneZeroMiner`: latest generic tarball contains a Linux `ELF x86-64` binary, not macOS

## Wallet stats

`macUnmineable` uses the same public unMineable API family that backs the
official wallet stats pages:

- address lookup: `/v5/address/{address}?coin={symbol}`
- account stats: `/v5/account/{uuid}/stats`
- account summary: `/v5/account/{uuid}/summary`

The app displays wallet-level aggregate numbers reported by unMineable. Those
numbers can include this app and any other miners pointed at the same wallet.

## Repository layout

- [VERSION](VERSION): release metadata used by app bundles and tags
- [CHANGELOG.md](CHANGELOG.md): release history
- [native/MacUnmineableNative.swift](native/MacUnmineableNative.swift): native app source
- [scripts/build_native_app.sh](scripts/build_native_app.sh): app bundle builder
- [scripts/install_xmrig.sh](scripts/install_xmrig.sh): official XMRig installer
- [scripts/install_cpuminer_scash.sh](scripts/install_cpuminer_scash.sh): official cpuminer-scash installer
- [scripts/verify.sh](scripts/verify.sh): smoke-test verification script
- [DEPENDENCIES.md](DEPENDENCIES.md): developer and runtime requirements
- [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md): third-party credits and license notes
- [AGENTS.md](AGENTS.md): handoff instructions for future agents

## Install and run

### End users

1. Build the app bundle:

```bash
./scripts/build_native_app.sh
```

By default, the builder downloads and embeds the managed Apple Silicon miner
binaries into the generated `.app` bundle so the app can launch with built-in
backends.

If you need a source-only bundle that does not embed any third-party miner
binaries, disable both the download and embedding stages explicitly:

```bash
DOWNLOAD_MANAGED_MINERS=0 EMBED_MANAGED_MINERS=0 ./scripts/build_native_app.sh
```

2. Open the generated bundle:

```bash
open dist/macUnmineable.app
```

3. On first launch, let the app auto-install the managed miners if they are
   missing, or open `Setup` and install/update them manually.

### Developers

The source repository intentionally does not commit prebuilt managed miner
binaries. Use the installer scripts to download the official releases into the
local working tree when needed:

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
- builds the native app bundle in both embedded and source-only modes
- exercises the managed installer scripts
- verifies dry-run startup for the supported XMRig algorithm routes
- verifies that the built bundle contains only the expected managed runtime payloads

## Dependencies

See [DEPENDENCIES.md](DEPENDENCIES.md).

## Versioning and releases

- Release tags follow `vMAJOR.MINOR.PATCH`.
- Bundle version metadata is tracked in [VERSION](VERSION).
- User-facing release history lives in [CHANGELOG.md](CHANGELOG.md).
- GitHub releases from this repository are source-only so the project does not
  redistribute third-party miner binaries directly.
- Local builders can still produce an embedded `.app` bundle for personal use
  or compliant redistribution by leaving the default build flags enabled.

## Security

- Managed tarball installers verify upstream `SHA256SUMS` manifests before
  installing `XMRig` or `cpuminer-scash`.
- The app executes installer scripts from the read-only app bundle instead of a
  writable `Application Support` copy.
- Managed installer targets must be explicit absolute paths.
- Custom miner overrides are validated as native macOS Mach-O executables
  before they are saved.
- Local config and runtime directories are written with user-only permissions.
- The app launches miner binaries directly with fixed argument arrays rather
  than shelling user input through a shell.
- Wallet stats requests use HTTPS-only public unMineable endpoints.

## Support

- Buy Me a Coffee: [buymeacoffee.com/einnovoeg](https://buymeacoffee.com/einnovoeg)

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).

Third-party software remains under its own license terms. See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Credits

- unMineable workflow inspiration and wallet stats model: [unMineable](https://unmineable.com/)
- Managed miner backend integrations: [XMRig](https://github.com/xmrig/xmrig), [cpuminer-scash](https://github.com/scashnetwork/cpuminer-scash)
- UI and ecosystem references: [macmineable](https://github.com/2nthony/macmineable), [EasyMiner](https://github.com/shepp31/EasyMiner), [MacMiner](https://xcreate.com/macminer/)

## Disclaimer

Mining profitability, payout rules, device support, and remote pool behavior can
change at any time. Validate the current unMineable settings and upstream miner
support before running long-lived mining sessions.
