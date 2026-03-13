# macUnmineable

`macUnmineable` is a native SwiftUI macOS app that wraps the unMineable mining
workflow into a wallet-first GUI for Apple Silicon.

The app lets you:

1. Choose the payout coin.
2. Paste the wallet address.
3. Choose a supported mining algorithm.
4. Start and stop the backend from a native macOS window.
5. Validate miners, inspect logs, and manage runtime paths from secondary panels.

## Current support

The stock Apple Silicon path in this project is:

- `XMRig` on CPU
- Supported algorithms: `RandomX`, `GhostRider`, `KawPow`

The app can still accept a custom secondary miner path, but it no longer
pretends that unsupported stock macOS backends are available.

### Official miner matrix

Checked on **March 12, 2026** against official upstream release feeds:

- `XMRig`: official `macOS arm64` release available
- `SRBMiner-MULTI`: no normal macOS release asset in the latest official release
- `nanominer`: latest official release ships Linux/Windows assets only
- `BzMiner`: latest official release ships Linux/Windows assets only
- `OneZeroMiner`: latest release includes a generic `.tar.gz`, but the contained binary is Linux `ELF x86-64`, not macOS

## Repository layout

- [native/MacUnmineableNative.swift](/Volumes/Mac%20Stick/Projects/macUnmineable/native/MacUnmineableNative.swift): native app source
- [scripts/build_native_app.sh](/Volumes/Mac%20Stick/Projects/macUnmineable/scripts/build_native_app.sh): app bundle builder
- [scripts/install_xmrig.sh](/Volumes/Mac%20Stick/Projects/macUnmineable/scripts/install_xmrig.sh): official XMRig installer
- [scripts/verify.sh](/Volumes/Mac%20Stick/Projects/macUnmineable/scripts/verify.sh): smoke-test verification script
- [DEPENDENCIES.md](/Volumes/Mac%20Stick/Projects/macUnmineable/DEPENDENCIES.md): developer and runtime requirements
- [THIRD_PARTY_NOTICES.md](/Volumes/Mac%20Stick/Projects/macUnmineable/THIRD_PARTY_NOTICES.md): third-party credits and license notes

## Install and run

### End users

1. Build the app bundle:

```bash
./scripts/build_native_app.sh
```

2. Open the generated bundle:

```bash
open dist/macUnmineable.app
```

3. On first launch, let the app auto-install `XMRig` if it is missing, or open
   `Setup` and click `Install / Update XMRig`.

### Developers

The source repository intentionally does not commit a prebuilt XMRig binary.
Instead, use the installer script to download the official release into the
local working tree when needed:

```bash
./scripts/install_xmrig.sh
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
- downloads XMRig into a temporary location
- verifies dry-run startup for `RandomX`, `GhostRider`, and `KawPow`

## Dependencies

See [DEPENDENCIES.md](/Volumes/Mac%20Stick/Projects/macUnmineable/DEPENDENCIES.md).

## Support

- Buy Me a Coffee: [buymeacoffee.com/einnovoeg](https://buymeacoffee.com/einnovoeg)

## License

This project is licensed under the MIT License. See [LICENSE](/Volumes/Mac%20Stick/Projects/macUnmineable/LICENSE).

Third-party software remains under its own license terms. See
[THIRD_PARTY_NOTICES.md](/Volumes/Mac%20Stick/Projects/macUnmineable/THIRD_PARTY_NOTICES.md).

## Credits

- unMineable workflow inspiration: [unMineable](https://unmineable.com/)
- Included miner backend integration: [XMRig](https://github.com/xmrig/xmrig)
- UI and ecosystem references: [macmineable](https://github.com/2nthony/macmineable), [EasyMiner](https://github.com/shepp31/EasyMiner), [SRBMiner-Multi](https://github.com/doktor83/SRBMiner-Multi)

## Disclaimer

Mining profitability, device support, payout rules, and remote pool behavior can
change at any time. Validate the current unMineable settings and upstream miner
support before running long-lived mining sessions.
