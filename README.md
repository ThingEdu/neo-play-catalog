# neo-play-catalog

Public catalog & installer for **[NEOPlay](https://pypi.org/project/neo-play/)** — the app store/launcher for NEO devices (ARM Linux), by ThingEdu.

This repo is the public distribution point that NEO devices read at runtime. The NEOPlay app itself lives in a separate (private) repo and is published to PyPI as `neo-play`.

## Contents

- **`catalog.json`** — the curated app shelf. NEOPlay fetches this over HTTP. Source of truth.
- **`scripts/install_on_neo.sh`** — the on-device installer (`curl | bash`).

## Install NEOPlay on a device

```bash
# normal install (icon in the menu)
curl -sSL https://raw.githubusercontent.com/ThingEdu/neo-play-catalog/main/scripts/install_on_neo.sh | bash

# boot straight into NEOPlay fullscreen (classroom mode)
curl -sSL https://raw.githubusercontent.com/ThingEdu/neo-play-catalog/main/scripts/install_on_neo.sh | bash -s -- --autostart
```

Qt/PyQt6 comes from the apt packages already on the NEO image; the script installs `neo-play` from PyPI.

### Test / dev builds (TestPyPI)

To try a pre-release published to [TestPyPI](https://test.pypi.org/project/neo-play/), add `--test` (pulls `neo-play` from TestPyPI, dependencies from real PyPI). Pin the version with `--version=`:

```bash
curl -sSL https://raw.githubusercontent.com/ThingEdu/neo-play-catalog/main/scripts/install_on_neo.sh | bash -s -- --test --version=0.1.2
```

## Catalog URL

NEOPlay reads the catalog from:

```
https://raw.githubusercontent.com/ThingEdu/neo-play-catalog/main/catalog.json
```

## Adding an app (ThingEdu review)

1. The app's install script must meet **NEO App Script Convention v0**.
2. Pin the script (in the NeoPlay dev repo): `python tools/pin_script.py <url-pointing-at-tag-vX.Y.Z>` → copy the generated `source` entry into `catalog.json` here.
3. Validate before merging: from a NeoPlay checkout with this repo as a sibling, run `python tools/validate_catalog.py neo-play-catalog/catalog.json` (or `make check`). Every entry must have a pinned semver `version` and a tag/SHA URL — never a branch.

Each `source.url` must resolve publicly (e.g. `ThingEdu/neo-code@<sha>`), since devices fetch it unauthenticated.
