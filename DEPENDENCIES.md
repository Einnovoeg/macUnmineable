# Dependencies

## Runtime

- macOS 13 or newer
- Internet access to reach unMineable pool and wallet-stat endpoints plus the
  managed miner release downloads
- Managed Apple Silicon miners supported by the app:
  - `XMRig` macOS arm64
  - `cpuminer-scash` macOS Sonoma arm64
- The app can auto-install these managed miners on launch, or you can install
  them manually with:
  - `./scripts/install_xmrig.sh`
  - `./scripts/install_cpuminer_scash.sh`

## Build

- Xcode Command Line Tools with `swiftc`
- `bash`
- `curl`
- `python3`
- Python package `Pillow`
- `shasum`
- `tar`
- `sips`
- `iconutil`

## Verification

- Everything listed in **Build**
- Temporary disk space for the smoke-test downloads used by `./scripts/verify.sh`

## Optional

- A user-supplied custom native macOS Mach-O miner binary if you want to test
  outside the managed backend set
- `gh` if you want to publish or manage the repository from the command line
