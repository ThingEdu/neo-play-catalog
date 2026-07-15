# NEO Installation Script Convention v2.0.0 (`install_on_neo.sh`)

Every open-source NEO app repo ships a **human-friendly installer** at
`scripts/install_on_neo.sh`, so anyone can install the app with one line:

```bash
curl -fsSL https://raw.githubusercontent.com/<org>/<repo>/main/scripts/install_on_neo.sh | bash
```

> **This script is the install path for apps that are *not* published to
> NeoPlay.** The NeoPlay store never runs it. The store lists only apps in its
> catalog and installs their release `.deb` directly (see
> [`app-entry-convention.md`](app-entry-convention.md)); its `source` types are
> `deb` and `flathub` only — there is no `script` source. This one-liner is how
> an "outer" app — one not on the NeoPlay shelf — gets onto a NEO device: by
> developers, classrooms, and manual setups, installing the app's release `.deb`
> straight from its GitHub Release.

**What changed since v0/v1**: the script no longer carries a store contract —
no `NEOPLAY_INSTALLED` / `NEOPLAY_ERROR` markers, no sha256 pinning of the
script, no no-TTY constraints. It is a plain, friendly bash installer.

Reference implementations: **neo-piano**, **neo-stopmotion**.

---

## 1. Requirements

| # | Requirement | Why |
|---|-------------|-----|
| 1 | **Installs the release `.deb`** from GitHub Releases via `apt-get install` — never pip/venv/git-clone builds. | One artifact everywhere: humans and the store install the identical package. |
| 2 | **No arguments = latest release** (resolved via the GitHub API); `--version=X.Y.Z` installs that exact release. | The one-liner must work with no flags. |
| 3 | **`--uninstall`** removes the app (`apt-get remove -y <pkg>`), including cleanup of any legacy pre-`.deb` installation the repo ever shipped. | One script handles the full lifecycle. |
| 4 | **Idempotent** — re-running installs/updates in place; use `--allow-downgrades` so pinning an older version also works. | Safe to re-run, always converges to the requested version. |
| 5 | **Safe for `curl \| bash`**: `set -euo pipefail`, fail with a clear message when the system isn't apt-based or `curl` is missing, clean up temp files on exit (`trap`). | The script runs unattended on machines you don't control. |
| 6 | **Warn-and-ignore unknown flags.** | Old scripts keep working when new flags appear. |

Plain `sudo` is fine — a human is at the terminal and can type the password
(sudo prompts on `/dev/tty`, which works even when the script is piped).

## 2. The standard template

Copy [`../templates/install_on_neo.template.sh`](../templates/install_on_neo.template.sh)
to `scripts/install_on_neo.sh` and edit **only** the Configuration block:

```bash
REPO="ThingEdu/my-app"   # GitHub repo that publishes the releases
PKG="my-app"             # Debian package name (the .deb `Package:` field)
COMMAND="my-app"         # command on PATH after install
DEB_ARCH="all"           # .deb architecture suffix: "all" or "arm64"/...
```

Everything below the config block is fixed policy — argument parsing, version
resolution, download, `apt-get install --allow-downgrades`, verification.
If the template doesn't cover your app's needs, raise it here first so the
standard evolves for everyone, instead of forking the flow in your repo.

## 3. Checklist

- [ ] `scripts/install_on_neo.sh` is the standard template with only the
      Configuration block edited.
- [ ] `curl -fsSL <raw url> | bash` installs the latest release on a stock
      NEO image.
- [ ] `--version=X.Y.Z` installs exactly that release.
- [ ] `--uninstall` removes the app cleanly.
- [ ] Re-running the script converges (update / downgrade / same version).
