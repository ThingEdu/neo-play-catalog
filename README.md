# neo-play-catalog

Public catalog & installer for **NEOPlay** — the app store/launcher for NEO devices (ARM Linux), by ThingEdu.

This repo is the public distribution point for NEO devices. The NEOPlay app itself lives in a separate (private) repo; since v2.0.0 it is a native (Rust/GTK4) app shipped as a `.deb` on **this repo's GitHub Releases** (tags are app-prefixed: `neo-play-vX.Y.Z`), because a device can't download assets from a private repo.

## Contents

- **`catalog.json`** — the curated app shelf (also the seed for the store backend).
- **`scripts/install_on_neo.sh`** — the on-device NEOPlay installer (`curl | bash`).
- **`scripts/install_default.sh`** — one-liner setup of a NEO One with the default ThingEdu apps.
- **`docs/conventions/`** — how NEO apps are packaged, released, and installed.

## Install NEOPlay on a device

```bash
# normal install (icon in the menu)
curl -sSL https://raw.githubusercontent.com/ThingEdu/neo-play-catalog/main/scripts/install_on_neo.sh | bash

# boot straight into NEOPlay fullscreen (classroom mode)
curl -sSL https://raw.githubusercontent.com/ThingEdu/neo-play-catalog/main/scripts/install_on_neo.sh | bash -s -- --autostart
```

The script downloads the release `.deb` and installs it via apt (dependencies come from the distro repos already on the NEO image). Uninstall with `-s -- --uninstall`; pin a specific release with `-s -- --version=X.Y.Z`.

## Adding an app (ThingEdu review)

1. Package the app per [`docs/conventions/app-entry-convention.md`](docs/conventions/app-entry-convention.md): semver, an immutable `.deb` per release with complete `Depends:`, desktop entry + icon inside, launch command on PATH.
2. Publish it per [`docs/conventions/github-release-convention.md`](docs/conventions/github-release-convention.md): org repo, `vX.Y.Z` tag, asset named `<pkg>_<X.Y.Z>_<arch>.deb`, assets never replaced.
3. Submit the release's `.deb` URL + sha256 to ThingEdu for the store entry.

Apps *not* published to the NEOPlay shelf ship a human-friendly `scripts/install_on_neo.sh` in their own repo instead — see [`docs/conventions/installation-script-convention.md`](docs/conventions/installation-script-convention.md).
