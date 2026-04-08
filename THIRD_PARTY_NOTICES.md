# Third-Party Notices

This project integrates with or references third-party software and services.
Original authors retain all rights to their respective work.

## Included integration targets

### XMRig

- Project: [xmrig/xmrig](https://github.com/xmrig/xmrig)
- Upstream site: [xmrig.com](https://xmrig.com/)
- License: `GPL-3.0-or-later`
- Current upstream license metadata checked on **April 7, 2026**
- Upstream copyright notices from `src/version.h`:
  - `Copyright (c) 2018-2025 SChernykh`
  - `Copyright (c) 2016-2025 XMRig`

Compliance notes:

- The source repository for `macUnmineable` does **not** commit a prebuilt
  XMRig binary.
- The installer script downloads the official XMRig release from upstream when
  requested.
- The local app builder can embed the downloaded XMRig payload into a private
  or redistributed `.app` bundle. If you redistribute such a bundle, you must
  satisfy XMRig's GPL requirements for that copied binary.

### cpuminer-scash

- Project: [scashnetwork/cpuminer-scash](https://github.com/scashnetwork/cpuminer-scash)
- Upstream site: [scashnetwork.org](https://scashnetwork.org)
- License source in upstream repository: `COPYING` contains `GNU General Public License Version 2`
- Current upstream release metadata checked on **April 7, 2026**

Compliance notes:

- The source repository for `macUnmineable` does **not** commit a prebuilt
  cpuminer-scash binary.
- The installer script downloads the official upstream release and verifies the
  tarball against the upstream `SHA256SUMS` manifest before installing it.
- The local app builder can embed the downloaded cpuminer-scash payload into a
  private or redistributed `.app` bundle. If you redistribute such a bundle,
  you must satisfy the GPL terms that apply to that copied binary.

## Project license boundary

- `macUnmineable`'s own source code and original project files are licensed
  under the MIT License in this repository.
- Third-party miners remain under their original upstream licenses and are not
  relicensed by this project.
- Public GitHub releases from this repository are source-only. If you create or
  redistribute a binary app bundle that includes third-party miner payloads,
  you are responsible for including the notices, source access, and any other
  obligations required by those upstream licenses.

## Third-party service

### unMineable

- Site: [unMineable](https://unmineable.com/)
- Purpose in this project: pool endpoint, payout workflow, coin catalog, and
  wallet stats source

Compliance notes:

- `macUnmineable` is an independent client application and is not affiliated
  with, endorsed by, or sponsored by unMineable.
- `unMineable` and related marks belong to their respective owners.

## Reference projects

These projects informed compatibility research, UI expectations, or ecosystem
review. Their code is **not** redistributed by this repository.

### EasyMiner

- Project: [shepp31/EasyMiner](https://github.com/shepp31/EasyMiner)
- License metadata checked on **April 7, 2026**: `Apache-2.0`

### macmineable

- Project: [2nthony/macmineable](https://github.com/2nthony/macmineable)
- License metadata checked on **April 7, 2026**: `GPL-3.0`

### MacMiner

- Site: [xcreate.com/macminer](https://xcreate.com/macminer/)
- Used as a GUI layout and UX reference only

### SRBMiner-Multi

- Project: [doktor83/SRBMiner-Multi](https://github.com/doktor83/SRBMiner-Multi)
- Used for compatibility review only; not integrated into the launcher

### UselethMiner

- Project: [Chainfire/UselethMiner](https://github.com/Chainfire/UselethMiner)
- Used for compatibility review only; not integrated into the launcher

### nanominer

- Project: [nanopool/nanominer](https://github.com/nanopool/nanominer)
- Used only for compatibility review of Apple Silicon/macOS support

### BzMiner

- Project: [bzminer/bzminer](https://github.com/bzminer/bzminer)
- Used only for compatibility review of Apple Silicon/macOS support

### OneZeroMiner

- Project: [OneZeroMiner/onezerominer](https://github.com/OneZeroMiner/onezerominer)
- Used only for compatibility review of Apple Silicon/macOS support
