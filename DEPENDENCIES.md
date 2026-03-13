# Dependencies

## Runtime

- macOS 13 or newer
- Internet access to reach unMineable pools and download the official XMRig release
- XMRig macOS arm64 binary
  - The app can auto-install this on first launch
  - Or install it manually with `./scripts/install_xmrig.sh`

## Build

- Xcode Command Line Tools with `swiftc`
- `bash`
- `curl`
- `tar`

## Verification

- Everything listed in **Build**
- Temporary disk space for the smoke-test download used by `./scripts/verify.sh`

## Optional

- A user-supplied custom secondary miner binary if you want to experiment beyond
  the stock Apple Silicon `XMRig` path
- `gh` if you want to publish or manage the repository from the command line
