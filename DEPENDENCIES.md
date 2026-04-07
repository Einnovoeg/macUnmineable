# Dependencies

## Runtime

- macOS 13 or newer
- Internet access to reach unMineable pools and download the managed miner releases
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
- Temporary disk space for the smoke-test download used by `./scripts/verify.sh`

## Optional

- A user-supplied custom secondary miner binary if you want to experiment beyond
  the managed Apple Silicon backends
- The official `UselethMiner` macOS package if you want optional `Ethash`
  support through its upstream `/usr/local/uselethminer` installation model
- `gh` if you want to publish or manage the repository from the command line
