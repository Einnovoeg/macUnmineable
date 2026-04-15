# Third-Party Notices

This document provides attribution and license information for third-party
software integrated into or referenced by `macUnmineable`.

## Integrated Software

### XMRig

- Project: [xmrig/xmrig](https://github.com/xmrig/xmrig)
- Upstream site: [xmrig.com](https://xmrig.com/)
- License: `GPL-3.0-or-later`
- License metadata verified on **April 12, 2026**
- Upstream copyright notices from `src/version.h`:
  - `Copyright (c) 2018-2025 SChernykh`
  - `Copyright (c) 2016-2025 XMRig`

Compliance notes:

- This repository does **not** commit a prebuilt XMRig binary.
- The installer script downloads the official XMRig release from upstream.
- Local app builds may embed the downloaded XMRig payload into a redistributed
  `.app` bundle.
- If you redistribute a build that includes XMRig, you are responsible for
  satisfying GPL-3.0 obligations, including source access for that copied binary.

### cpuminer-scash

- Project: [scashnetwork/cpuminer-scash](https://github.com/scashnetwork/cpuminer-scash)
- Upstream site: [scashnetwork.org](https://scashnetwork.org)
- Upstream status: archived on GitHub as of **April 12, 2026**
- License source: upstream `LICENSE` states `GNU Public License version 2` and upstream `COPYING` contains the full `GNU General Public License Version 2` text
- GitHub repository license metadata currently reports `NOASSERTION`, so this project relies on the upstream license files themselves for notice purposes
- License metadata verified on **April 12, 2026**

Compliance notes:

- This repository does **not** commit a prebuilt cpuminer-scash binary.
- The installer script downloads the official upstream release and verifies the
  tarball against the upstream `SHA256SUMS` manifest before installation.
- Local app builds may embed the downloaded cpuminer-scash payload into a
  redistributed `.app` bundle.
- If you redistribute a build that includes cpuminer-scash, you are responsible
  for satisfying the applicable GPL obligations, including source access for
  that copied binary.

## Third-Party Service

### unMineable

- Site: [unMineable](https://unmineable.com/)
- Purpose in this project: pool endpoint, payout workflow, coin catalog, and wallet stats source

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
| [doktor83/SRBMiner-Multi](https://github.com/doktor83/SRBMiner-Multi) | Compatibility review only | Not integrated |
| [Chainfire/UselethMiner](https://github.com/Chainfire/UselethMiner) | Compatibility review only | Not integrated |
| [nanopool/nanominer](https://github.com/nanopool/nanominer) | Compatibility review only | Not integrated |
| [bzminer/bzminer](https://github.com/bzminer/bzminer) | Compatibility review only | Not integrated |
| [OneZeroMiner/onezerominer](https://github.com/OneZeroMiner/onezerominer) | Compatibility review only | Not integrated |

## Project License Boundary

- `macUnmineable` source code and original project files are licensed under the
  MIT License in this repository.
- Third-party miners remain under their original upstream licenses and are not
  relicensed by this project.
- Public GitHub releases from this repository are source-only.
- If you create or redistribute a binary app bundle that includes third-party
  miner payloads, you are responsible for the notice, source-access, and any
  other obligations required by those upstream licenses.
