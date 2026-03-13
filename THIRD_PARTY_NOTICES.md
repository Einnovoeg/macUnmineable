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
