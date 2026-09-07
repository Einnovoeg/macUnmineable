# Third-Party Notices

This document provides attribution and license information for third-party
software integrated into or referenced by `macUnmineable`.

> Last verified: **September 07, 2026**

## Integrated Software

### XMRig

- Project: [xmrig/xmrig](https://github.com/xmrig/xmrig)
- Upstream site: [xmrig.com](https://xmrig.com/)
- License: `GPL-3.0-or-later` (per `LICENSE` and `src/version.h` in upstream)
- License metadata verified on **September 07, 2026**
- Upstream copyright notices from `src/version.h`:
  - `Copyright (c) 2018-2025 SChernykh`
  - `Copyright (c) 2016-2025 XMRig`
- Latest verified release: **v6.26.0** (`xmrig-6.26.0-macos-arm64.tar.gz` + `SHA256SUMS`)

Compliance notes:

- This repository does **not** commit a prebuilt XMRig binary.
- The installer script `scripts/install_xmrig.sh` downloads the official XMRig
  release from upstream and verifies it against the upstream `SHA256SUMS` manifest
  before installation.
- Local app builds may embed the downloaded XMRig payload into a redistributed
  `.app` bundle.
- If you redistribute a build that includes XMRig, you are responsible for
  satisfying GPL-3.0 obligations, including source access for that copied binary.

### cpuminer-scash

- Project: [scashnetwork/cpuminer-scash](https://github.com/scashnetwork/cpuminer-scash)
- Upstream site: [scashnetwork.org](https://scashnetwork.org)
- Upstream status: **archived** on GitHub (verified September 07, 2026; `archived: true`, last updated `2026-09-04`)
- License source: upstream `LICENSE` states `GNU Public License version 2` and upstream `COPYING` contains the full `GNU General Public License Version 2` text
- GitHub repository license metadata currently reports `NOASSERTION`, so this project relies on the upstream license files themselves for notice purposes
- License metadata verified on **September 07, 2026**
- Latest verified release: **v3.0.9** (`cpuminer-scash-3.0.9-macos-sonoma-arm64.tgz` + `SHA256SUMS`)

Compliance notes:

- This repository does **not** commit a prebuilt cpuminer-scash binary.
- The installer script `scripts/install_cpuminer_scash.sh` downloads the official
  upstream release and verifies the tarball against the upstream `SHA256SUMS`
  manifest before installation.
- Local app builds may embed the downloaded cpuminer-scash payload into a
  redistributed `.app` bundle.
- If you redistribute a build that includes cpuminer-scash, you are responsible
  for satisfying the applicable GPL obligations, including source access for
  that copied binary.

## Third-Party Service

### unMineable

- Site: [unMineable](https://unmineable.com/)
- API: `https://api.unmineable.com/v5/...` (public wallet/coin catalog and account stats)
- Purpose in this project: pool endpoint (`rx.unmineable.com`, `ghostrider.unmineable.com`, `kp.unmineable.com`), payout workflow, coin catalog, and wallet stats source

Compliance notes:

- `macUnmineable` is an independent client application.
- It is not affiliated with, endorsed by, or sponsored by unMineable.
- `unMineable` and related marks belong to their respective owners.

## Referenced Projects

These projects informed compatibility research, UI expectations, or ecosystem
review. Their code is **not** redistributed by this repository.

| Project | License / Metadata | Purpose |
|---------|--------------------|---------|
| [shepp31/EasyMiner](https://github.com/shepp31/EasyMiner) | Apache-2.0 | UI/UX reference |
| [2nthony/macmineable](https://github.com/2nthony/macmineable) | GPL-3.0 | UI/UX reference |
| [xcreate.com/macminer](https://xcreate.com/macminer/) | Site reference | GUI layout reference |
| [doktor83/SRBMiner-Multi](https://github.com/doktor83/SRBMiner-Multi) | Compatibility review only | Not integrated — no macOS release |
| [Chainfire/UselethMiner](https://github.com/Chainfire/UselethMiner) | Compatibility review only | Not integrated — no verifiable macOS arm64 path |
| [nanopool/nanominer](https://github.com/nanopool/nanominer) | Compatibility review only | Not integrated — Linux/Windows only |
| [bzminer/bzminer](https://github.com/bzminer/bzminer) | Compatibility review only | Not integrated — Linux/Windows only |
| [OneZeroMiner/onezerominer](https://github.com/OneZeroMiner/onezerominer) | Compatibility review only | Not integrated — Linux ELF x86-64 only |

## Project License Boundary

- `macUnmineable` source code and original project files are licensed under the
  **MIT License** (`LICENSE`) — Copyright (c) 2026 macUnmineable contributors.
- Third-party miners remain under their original upstream licenses and are **not**
  relicensed by this project.
- Public GitHub releases from this repository are **source-only** (no embedded miner binaries).
- If you create or redistribute a binary app bundle that includes third-party
  miner payloads, you are responsible for the notice, source-access, and any
  other obligations required by those upstream licenses.

## Attribution

Full credit is given to the original authors as required by each upstream license:

- **XMRig** authors: SChernykh and XMRig contributors (2016–2025) — see https://github.com/xmrig/xmrig
- **cpuminer-scash** authors: scashnetwork contributors — see https://github.com/scashnetwork/cpuminer-scash
- **unMineable** — pool and API operator — see https://unmineable.com/

No upstream license or attribution has been removed or altered. Any bundled
redistribution must preserve the upstream copyright notices and license texts.
