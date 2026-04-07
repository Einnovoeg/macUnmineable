# macUnmineable

`macUnmineable` is a native SwiftUI macOS app that wraps the unMineable mining
workflow into a wallet-first GUI for Apple Silicon.

Current source release: `v0.4.6`

The app lets you:

1. Choose the payout coin.
2. Paste the wallet address.
3. Choose a supported mining algorithm.
4. Start and stop the backend from a native macOS window.
5. Install, update, validate, and inspect managed miners from secondary panels.
6. Search the full live unMineable coin catalog from a dedicated picker that
   caches the last successful result locally.
7. Run with a native macOS app icon instead of the default executable bundle
   icon.

## Current support

The managed Apple Silicon backends in this project are:

- `XMRig` on CPU for `RandomX`, `GhostRider`, and `KawPow`
- `cpuminer-scash` on CPU for `RandomX`
- Optional external `UselethMiner` on CPU or Apple Silicon `Metal` GPU for `Ethash` when the official macOS package is installed to `/usr/local/uselethminer`

The app can still accept a custom secondary miner path. The normal Apple
Silicon flow is based on managed backends that the app can install and update
itself, plus optional external backends only when their upstream installation
model is compatible.

### Official miner matrix

Checked on **March 24, 2026** against official upstream release feeds and local
startup behavior:

- `XMRig`: official `macOS arm64` release available
- `cpuminer-scash`: official `macOS Sonoma arm64` release available
- `UselethMiner`: official `macOS arm64` package available, with Apple Silicon Metal GPU support documented upstream, but upstream macOS packaging expects installation to `/usr/local/uselethminer`
- `SRBMiner-MULTI`: no normal macOS release asset in the latest official release
- `nanominer`: latest official release ships Linux/Windows assets only
- `BzMiner`: latest official release ships Linux/Windows assets only
- `OneZeroMiner`: latest release includes a generic `.tar.gz`, but the contained binary is Linux `ELF x86-64`, not macOS

## Repository layout

- [VERSION](VERSION): tracked release metadata used by the app bundle build
- [CHANGELOG.md](CHANGELOG.md): release history
- [native/MacUnmineableNative.swift](native/MacUnmineableNative.swift): native app source
- [scripts/build_native_app.sh](scripts/build_native_app.sh): app bundle builder
- [scripts/install_xmrig.sh](scripts/install_xmrig.sh): official XMRig installer
- [scripts/install_cpuminer_scash.sh](scripts/install_cpuminer_scash.sh): official cpuminer-scash installer
- [scripts/verify.sh](scripts/verify.sh): smoke-test verification script
- [DEPENDENCIES.md](DEPENDENCIES.md): developer and runtime requirements
- [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md): third-party credits and license notes

## Install and run

### End users

1. Build the app bundle:

```bash
./scripts/build_native_app.sh
```

By default, the builder downloads and embeds the managed Apple Silicon miners
into the generated `.app` bundle so the app can launch with built-in backends.

If you want a source-only bundle that does not embed any third-party miner
binaries, disable both the download and embedding stages explicitly:

```bash
DOWNLOAD_MANAGED_MINERS=0 EMBED_MANAGED_MINERS=0 ./scripts/build_native_app.sh
```

2. Open the generated bundle:

```bash
open dist/macUnmineable.app
```

3. On first launch, let the app auto-install the managed miners if they are
   missing, or open `Setup` and install/update them individually.

4. If you want `Ethash` through `UselethMiner`, install the official upstream
   macOS package separately so the binary is present at
   `/usr/local/uselethminer/uselethminer`.

### Developers

The source repository intentionally does not commit prebuilt managed miner
binaries. Instead, use the installer scripts to download the official releases
into the local working tree when needed:

```bash
./scripts/install_xmrig.sh
./scripts/install_cpuminer_scash.sh
```

If you install the official `UselethMiner` macOS package separately, the app
can detect it at `/usr/local/uselethminer/uselethminer`. If you already have a
compatible custom secondary miner build, point the app at it from the `Setup`
panel.

## Verification

Run the full smoke test:

```bash
./scripts/verify.sh
```

That script:

- type-checks the SwiftUI source
- builds the native app bundle in both embedded and source-only modes
- exercises the managed installer scripts
- verifies dry-run startup for the XMRig-backed algorithms that can be tested safely in automation

## Dependencies

See [DEPENDENCIES.md](DEPENDENCIES.md).

## Versioning and releases

- Release tags follow `vMAJOR.MINOR.PATCH`.
- Bundle version metadata is tracked in [VERSION](VERSION).
- User-facing release history lives in [CHANGELOG.md](CHANGELOG.md).
- GitHub releases from this source repository are source-only so the project
  does not redistribute third-party miner binaries.
- Local builders can still produce an embedded `.app` bundle for personal use
  or compliant redistribution by leaving the default build flags enabled.

## Security

- Managed tarball installers verify upstream `SHA256SUMS` manifests before
  installing `XMRig` or `cpuminer-scash`.
- The app executes installer scripts from the read-only app bundle instead of a
  writable `Application Support` copy.
- `UselethMiner` is not treated as a managed bundled backend because upstream
  macOS packaging expects a system install path outside the app runtime.
- Managed installer targets must be explicit absolute paths, and the app now
  validates custom miner overrides as native macOS Mach-O executables before
  saving them.
- The build script now supports an explicit source-only mode so maintainers can
  verify that public source distributions stay free of third-party miner
  binaries even when local development machines already have downloaded payloads.
- Local config and runtime directories are written with tighter user-only
  permissions.
- The app launches miner binaries directly with fixed argument arrays rather
  than shelling untrusted input through a shell.

## Support

- Buy Me a Coffee: [buymeacoffee.com/einnovoeg](https://buymeacoffee.com/einnovoeg)

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).

Third-party software remains under its own license terms. See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Credits

- unMineable workflow inspiration: [unMineable](https://unmineable.com/)
- Included miner backend integration: [XMRig](https://github.com/xmrig/xmrig)
- UI and ecosystem references: [macmineable](https://github.com/2nthony/macmineable), [EasyMiner](https://github.com/shepp31/EasyMiner), [SRBMiner-Multi](https://github.com/doktor83/SRBMiner-Multi)

## Disclaimer

Mining profitability, device support, payout rules, and remote pool behavior can
change at any time. Validate the current unMineable settings and upstream miner
support before running long-lived mining sessions.
