# macUnmineable

`macUnmineable` is a native SwiftUI macOS app that wraps the unMineable mining
workflow into a wallet-first GUI for Apple Silicon.

Current source release: `v0.4.1`

The app lets you:

1. Choose the payout coin.
2. Paste the wallet address.
3. Choose a supported mining algorithm.
4. Start and stop the backend from a native macOS window.
5. Install, update, validate, and inspect managed miners from secondary panels.

## Current support

The managed Apple Silicon backends in this project are:

- `XMRig` on CPU for `RandomX`, `GhostRider`, and `KawPow`
- `cpuminer-scash` on CPU for `RandomX`
- `UselethMiner` on CPU or Apple Silicon `Metal` GPU for `Ethash`

The app can still accept a custom secondary miner path, but the normal Apple
Silicon flow is now based on managed backends that the app can install and
update itself.

### Official miner matrix

Checked on **March 23, 2026** against official upstream release feeds:

- `XMRig`: official `macOS arm64` release available
- `cpuminer-scash`: official `macOS Sonoma arm64` release available
- `UselethMiner`: official `macOS arm64` package available, with Apple Silicon Metal GPU support documented upstream
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
- [scripts/install_uselethminer.sh](scripts/install_uselethminer.sh): official UselethMiner installer
- [scripts/verify.sh](scripts/verify.sh): smoke-test verification script
- [DEPENDENCIES.md](DEPENDENCIES.md): developer and runtime requirements
- [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md): third-party credits and license notes

## Install and run

### End users

1. Build the app bundle:

```bash
./scripts/build_native_app.sh
```

The build script downloads and embeds the managed Apple Silicon miners by
default. To build without that step, use:

```bash
DOWNLOAD_MANAGED_MINERS=0 ./scripts/build_native_app.sh
```

2. Open the generated bundle:

```bash
open dist/macUnmineable.app
```

3. On first launch, let the app auto-install the managed miners if they are
   missing, or open `Setup` and install/update them individually.

### Developers

The source repository intentionally does not commit prebuilt managed miner
binaries. Instead, use the installer scripts to download the official releases
into the local working tree when needed:

```bash
./scripts/install_xmrig.sh
./scripts/install_cpuminer_scash.sh
./scripts/install_uselethminer.sh
```

If you already have a compatible custom miner build, point the app at it from
the `Setup` panel.

## Verification

Run the full smoke test:

```bash
./scripts/verify.sh
```

That script:

- type-checks the SwiftUI source
- builds the native app bundle
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

## Security

- Managed tarball installers verify upstream `SHA256SUMS` manifests before
  installing `XMRig` or `cpuminer-scash`.
- The `UselethMiner` installer requires the downloaded package to pass Apple
  signature and notarization checks before its payload is installed.
- The app executes installer scripts from the read-only app bundle instead of a
  writable `Application Support` copy.
- Managed installer targets must be explicit absolute paths, and the app now
  validates custom miner overrides as native macOS Mach-O executables before
  saving them.
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
