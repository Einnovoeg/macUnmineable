# Third-Party Notices

This project integrates with or references third-party software and services.
Original authors retain all rights to their respective work.

## Included integration target

### XMRig

- Project: [xmrig/xmrig](https://github.com/xmrig/xmrig)
- Upstream site: [xmrig.com](https://xmrig.com/)
- License: `GPL-3.0-or-later`
- Current upstream license metadata checked on **March 12, 2026**
- Upstream copyright notices from `src/version.h`:
  - `Copyright (c) 2018-2025 SChernykh`
  - `Copyright (c) 2016-2025 XMRig`

Compliance notes:

- The source repository for `macUnmineable` does **not** commit a prebuilt
  XMRig binary.
- The local installer script downloads the official XMRig release from the
  upstream project when requested.
- If you distribute a build that includes the XMRig binary, you are
  responsible for complying with XMRig's GPL terms for that redistributed copy.

### cpuminer-scash

- Project: [scashnetwork/cpuminer-scash](https://github.com/scashnetwork/cpuminer-scash)
- Upstream site: [scashnetwork.org](https://scashnetwork.org)
- License source in upstream repository: `COPYING` contains `GNU General Public License Version 2`
- Current upstream release metadata checked on **March 23, 2026**

Compliance notes:

- The source repository for `macUnmineable` does **not** commit a prebuilt
  cpuminer-scash binary.
- The installer script downloads the official upstream release and verifies the
  tarball against the upstream `SHA256SUMS` manifest before installing it.
- If you distribute a build that includes the cpuminer-scash binary, you are
  responsible for complying with its GPL terms for that redistributed copy.

### UselethMiner

- Project: [Chainfire/UselethMiner](https://github.com/Chainfire/UselethMiner)
- Upstream description: `Ethereum CPU miner and aggregating proxy`
- Upstream Apple Silicon note: the README documents a `metal` GPU backend for
  Apple Silicon
- Current upstream release metadata checked on **March 23, 2026**
- GitHub repository metadata does not expose an SPDX license identifier

Compliance notes:

- The source repository for `macUnmineable` does **not** commit or attach the
  UselethMiner binary payload.
- The installer script downloads the official upstream macOS package directly,
  requires the package to pass Apple signature and notarization checks, and
  then installs the payload locally.
- Because upstream license metadata is not clearly exposed in the repository
  metadata, this project does not publish the UselethMiner payload in its own
  source releases.

## Third-party service

### unMineable

- Site: [unMineable](https://unmineable.com/)
- Purpose in this project: mining pool endpoint and wallet login format

Compliance notes:

- `macUnmineable` is an independent client application and is not affiliated
  with, endorsed by, or sponsored by unMineable.
- `unMineable` and related marks belong to their respective owners.

## Reference projects

These projects informed compatibility research, UI expectations, or ecosystem
review. Their code is **not** redistributed by this repository.

### EasyMiner

- Project: [shepp31/EasyMiner](https://github.com/shepp31/EasyMiner)
- License metadata checked on **March 12, 2026**: `Apache-2.0`

### macmineable

- Project: [2nthony/macmineable](https://github.com/2nthony/macmineable)
- License metadata checked on **March 12, 2026**: `GPL-3.0`

### SRBMiner-Multi

- Project: [doktor83/SRBMiner-Multi](https://github.com/doktor83/SRBMiner-Multi)
- GitHub API license metadata checked on **March 12, 2026**: no SPDX license
  value exposed in repository metadata

### nanominer

- Project: [nanopool/nanominer](https://github.com/nanopool/nanominer)
- Used only for compatibility review of Apple Silicon/macOS support

### BzMiner

- Project: [bzminer/bzminer](https://github.com/bzminer/bzminer)
- Used only for compatibility review of Apple Silicon/macOS support

### OneZeroMiner

- Project: [OneZeroMiner/onezerominer](https://github.com/OneZeroMiner/onezerominer)
- Used only for compatibility review of Apple Silicon/macOS support
