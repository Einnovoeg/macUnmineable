# Dependencies

## Runtime

- macOS 13 or newer
- Internet access to reach unMineable pools and download the managed miner releases
- Managed Apple Silicon miners supported by the app:
  - `XMRig` macOS arm64
  - `cpuminer-scash` macOS Sonoma arm64
  - `UselethMiner` macOS arm64 package payload
- The app can auto-install these managed miners on launch, or you can install
  them manually with:
  - `./scripts/install_xmrig.sh`
  - `./scripts/install_cpuminer_scash.sh`
  - `./scripts/install_uselethminer.sh`

## Build

- Xcode Command Line Tools with `swiftc`
- `bash`
- `curl`
- `pkgutil`
- `python3`
- `shasum`
- `tar`

## Verification

- Everything listed in **Build**
- Temporary disk space for the smoke-test download used by `./scripts/verify.sh`

## Optional

- A user-supplied custom secondary miner binary if you want to experiment beyond
  the managed Apple Silicon backends
- `gh` if you want to publish or manage the repository from the command line
