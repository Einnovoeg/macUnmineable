# Dependencies

## Runtime Requirements

- macOS 13 or newer
- Apple Silicon Mac (arm64)
- Internet access to reach unMineable endpoints and managed miner release downloads

## Managed Miner Support

| Miner | Algorithms | Delivery |
|-------|------------|----------|
| XMRig | RandomX, GhostRider, KawPow | Auto-installed or via script |
| cpuminer-scash | RandomX | Auto-installed or via script; upstream repository is archived |

Manual installation commands:

```bash
./scripts/install_xmrig.sh
./scripts/install_cpuminer_scash.sh
```

## Build Requirements

- Xcode Command Line Tools with `swiftc`
- `bash`
- `curl`
- `python3`
- Python package `Pillow`
- `shasum`
- `tar`
- `sips`
- `iconutil`
- `git`

## Verification Requirements

- Everything listed in **Build Requirements**
- Temporary disk space for smoke-test downloads used by `./scripts/verify.sh`

## Optional Tools

- `gh` CLI for GitHub release and repository management
- A user-supplied native macOS Mach-O miner binary for advanced testing outside the managed set

## Architecture Notes

This project targets Apple Silicon because the managed miners in this app have
verified official macOS arm64 release paths. Other reviewed miners do not ship
usable official macOS builds for this launcher.
