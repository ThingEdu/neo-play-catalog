# NEO App Entry Convention v1.0.0

How to version and package a NEO app so it can become a **NEOPlay store entry**
the store installs directly. Applies to every open-source app repo (ThingEdu
org and partners).

> TL;DR: semver `X.Y.Z` → an immutable `.deb` per release that carries its
> dependencies, desktop entry, and launch command. NEOPlay downloads the `.deb`,
> verifies its sha256, and installs it via apt.

Publishing on GitHub is specified in
[`github-release-convention.md`](github-release-convention.md).
Reference implementations: **neo-piano**, **neo-stopmotion**.

---

## 1. Versioning

- **Semver `X.Y.Z`.** One version = one immutable `.deb` per architecture.
- The version appears identically in the package metadata (`Version:`), the
  release tag (`vX.Y.Z`), and the asset file name.
- Never re-release under the same version — the store pins each release's
  sha256, so a swapped artifact fails to install. Fixes get a new patch version.

## 2. The `.deb` package

| Field / content | Rule |
|---|---|
| `Package:` | The app id as it appears in the store (e.g. `neo-piano`). |
| `Version:` | `X.Y.Z` — identical to the release version. |
| `Architecture:` | `all` for pure-Python/interpreted apps; `arm64` (etc.) for compiled ones. |
| `Depends:` | **Complete** runtime dependencies (PyQt6, OpenCV, ffmpeg, QML modules, …) so `apt-get install` resolves everything on a stock NEO image. |
| Launch command | Installed on PATH (`usr/bin/<command>`); this is the `exec` the store launches. |
| Desktop integration | `.desktop` entry in `usr/share/applications/`, icon under `usr/share/icons/hicolor/...` — inside the package. |
| Uninstall | `apt-get remove -y <pkg>` must remove the app cleanly (standard dpkg behavior — don't scatter files outside the package). |

## 3. Store integration

For each approved release, the store backend records an **app version row**:

| Field | Content |
|---|---|
| `version` | `X.Y.Z` |
| `source` | type `deb`: the release asset URL + the **sha256 of the `.deb`** (the store verifies the artifact before installing — apt does not verify local files). |
| `launch_exec` | The command line the store launches (usually `["<command>"]`). |
| `size` | Artifact size in MB, for the disk-space check before download. |

Install path on the device: download `.deb` → verify sha256 →
`sudo -n apt-get install -y --allow-downgrades <file>` → record in the local
registry. Uninstall: `sudo -n apt-get remove -y <pkg>`.

## 4. Release checklist

- [ ] Version bumped to `X.Y.Z` in package metadata.
- [ ] `.deb` builds with complete `Depends:`, desktop entry + icon inside,
      launch command on PATH.
- [ ] `sudo apt-get install ./<pkg>_<X.Y.Z>_<arch>.deb` works on a stock NEO
      image (Armbian, 2 GB RAM) — and `apt-get remove` cleans it up.
- [ ] Published per [`github-release-convention.md`](github-release-convention.md).
- [ ] sha256 of the `.deb` submitted to ThingEdu for the store entry.
