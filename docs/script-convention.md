# NEO App Script Convention v0

How to make an app's install script work with **NEOPlay**, so it can be added to
this catalog. NEOPlay installs an app by downloading **one script**, verifying its
`sha256`, and running it. This document is the contract that script must follow.

> TL;DR: one idempotent bash script that accepts `--version=X.Y.Z` and `--uninstall`,
> runs with **no sudo / no TTY**, installs into a **per-app venv**, and prints
> `NEOPLAY_INSTALLED version=X.Y.Z` on success.

---

## 1. How NEOPlay runs your script (runtime contract)

NEOPlay (`ScriptInstaller`) does exactly this:

| Step | Behaviour |
|------|-----------|
| Download | Fetches the **exact** script at the pinned `source.url`, verifies it against `source.sha256`, caches it. A mismatch aborts — the script never runs. |
| Install | Runs `bash <script> --version=<X.Y.Z>` as a **normal user**, **no sudo, no TTY**, with a **20-minute timeout** (the whole process group is killed on timeout). |
| Uninstall | Runs `bash <script> --uninstall`. |
| Parse | Scans **stdout** for `NEOPLAY_INSTALLED version=X.Y.Z`, and **stdout+stderr** for `NEOPLAY_ERROR=<code>`. |
| Result | Exit code `0` = success; non-zero = failure (NEOPlay shows a friendly message and rolls the button back to *Install*). |

Two consequences that trip people up:

- **NEOPlay always passes `--version=X.Y.Z`** (single token, `=` form). A script whose
  argument parser rejects unknown options (`*) echo "Unknown option"; exit 1`) will fail
  instantly, before it installs anything. Your script **must** accept `--version=X.Y.Z`.
- **There is no terminal.** Anything that calls `sudo` (which needs a password prompt)
  or otherwise expects a TTY will hang or fail. Run fully as the user.

---

## 2. The six requirements

| # | Requirement | Why |
|---|-------------|-----|
| 1 | **One script, idempotent, with `--uninstall`** in the same file. Re-running = update; `--uninstall` removes cleanly. | The catalog stores one URL; NEOPlay reuses it for update + remove. |
| 2 | **Accept `--version=X.Y.Z` (required)** and install exactly that version (`pip install pkg==X.Y.Z`, or `git+repo@vX.Y.Z`). | ThingEdu approves a specific version; every device installs the same one. NEOPlay always passes this flag. |
| 3 | **No sudo at runtime.** Check whether system deps are present; if they are missing and there's no TTY, print `NEOPLAY_ERROR=missing_system_deps` and exit non-zero. Heavy native deps (PyQt, OpenCV, …) are **pre-baked into the NEO image** at flash time. | NEOPlay runs your script without a TTY; `sudo` would hang. |
| 4 | **A per-app virtualenv** at `~/Applications/<id>/venv` — never `pip --break-system-packages` into the shared site-packages. | No dependency conflicts between apps; uninstall = delete the folder. |
| 5 | **Machine-readable output:** on success the last line is `NEOPLAY_INSTALLED version=X.Y.Z`; on error print `NEOPLAY_ERROR=<code>`; use correct exit codes. | NEOPlay parses this to update its registry and show the right message. |
| 6 | **Create a user-level `.desktop` entry + icon.** | So the app can be launched after install. |

### Error codes

Printed as `NEOPLAY_ERROR=<code>`:

| Code | Meaning shown to the user |
|------|----------------------------|
| `missing_system_deps` | "The machine is missing base software — contact ThingEdu to update the image." |
| *(anything else / non-zero exit with no code)* | Generic "installation failed, please try again." |

### Best-effort / legacy mode

A script that doesn't print `NEOPLAY_INSTALLED` still installs in a **degraded** mode:
NEOPlay trusts the catalog version and flags the app `legacy` (so it can be upgraded
later). This only works if the script still **exits 0** and still **accepts `--version`**
without erroring. Emitting the marker is strongly preferred.

---

## 3. Minimal compliant template

```bash
#!/usr/bin/env bash
# Install script for <app> — NEO App Script Convention v0.
set -euo pipefail

APP_ID="my-app"                       # must match catalog "id"
PYPI_PACKAGE="my-app"
APP_HOME="$HOME/Applications/$APP_ID"
VENV="$APP_HOME/venv"
BIN="$HOME/.local/bin/$APP_ID"
DESKTOP="$HOME/.local/share/applications/$APP_ID.desktop"

VERSION=""
UNINSTALL=false
while [ $# -gt 0 ]; do
    case "$1" in
        --version=*)  VERSION="${1#*=}"; shift ;;   # NEOPlay passes: --version=X.Y.Z
        --version)    VERSION="${2:-}"; shift 2 ;;  # also accept the space form (human CLI)
        --uninstall)  UNINSTALL=true; shift ;;
        --no-desktop) shift ;;                      # accept & ignore
        *)            shift ;;                       # never hard-fail on unknown args
    esac
done

uninstall() {
    rm -rf "$APP_HOME" "$BIN" "$DESKTOP"
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    exit 0
}
[ "$UNINSTALL" = true ] && uninstall

# Convention #2: --version is required under NEOPlay.
if [ -z "$VERSION" ]; then
    echo "NEOPLAY_ERROR=missing_version" >&2
    exit 1
fi

# Convention #3: check pre-baked system deps; NEVER sudo here.
if ! python3 -c "import PyQt6" 2>/dev/null; then
    echo "NEOPLAY_ERROR=missing_system_deps" >&2
    exit 1
fi

# Convention #4: per-app venv (system-site so pre-baked Qt is visible).
python3 -m venv --system-site-packages "$VENV"
"$VENV/bin/pip" install --quiet "${PYPI_PACKAGE}==${VERSION}"

mkdir -p "$(dirname "$BIN")"
ln -sf "$VENV/bin/$APP_ID" "$BIN"

# Convention #6: desktop entry.
mkdir -p "$(dirname "$DESKTOP")"
cat > "$DESKTOP" <<EOF
[Desktop Entry]
Type=Application
Name=My App
Exec=$BIN
Terminal=false
Categories=Education;
EOF
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# Convention #5: machine-readable success marker (last line).
echo "NEOPLAY_INSTALLED version=$VERSION"
```

---

## 4. The catalog entry

Once the script is ready, ThingEdu pins it into [`catalog.json`](../catalog.json).
Use the helper in the NeoPlay dev repo to generate the `source` block:

```bash
python tools/pin_script.py https://raw.githubusercontent.com/<org>/<repo>/v1.2.3/scripts/install_on_neo.sh
```

A script-source entry looks like:

```json
{
  "id": "my-app",
  "name": "My App",
  "summary": "Short one-line description",
  "version": "1.2.3",
  "category": "lap_trinh",
  "age_rating": "8+",
  "labels": ["free", "neo_native"],
  "exec": ["my-app"],
  "source": {
    "type": "script",
    "url": "https://raw.githubusercontent.com/<org>/<repo>/v1.2.3/scripts/install_on_neo.sh",
    "sha256": "<64-hex sha256 of the exact script>"
  }
}
```

Validation rules (enforced by CI — see [`.github/workflows/validate.yml`](../.github/workflows/validate.yml)):

| Field | Rule |
|-------|------|
| `version` | Semver `X.Y.Z`, **pinned** (required). `latest` etc. is rejected. |
| `source.type` | `script` (or `flathub` with an `app_id`). |
| `source.url` | Must contain a **git tag `vX.Y.Z`** or a **40-char commit SHA** — a branch (`main`/`master`/`HEAD`) is rejected. The version pin lives in the URL so it can never drift. |
| `source.sha256` | 64-hex digest of the exact script bytes. |
| `exec` | **Required** for script sources — the command NEOPlay launches. |
| `category` | One of `lap_trinh`, `robotics`, `khoa_hoc`, `sang_tao`, `sim2real`. |
| `labels` | Subset of `free`, `bundled`, `deploy_ready`, `foss`, `neo_native`. |
| `id` | Unique across the catalog. |

---

## 5. Submission checklist

- [ ] Single script, runs idempotently; re-running updates in place.
- [ ] Accepts `--version=X.Y.Z` and installs exactly that version.
- [ ] Accepts `--uninstall` and removes everything cleanly.
- [ ] **Never calls `sudo`**; if system deps are missing, prints `NEOPLAY_ERROR=missing_system_deps` and exits non-zero.
- [ ] Installs into a per-app venv under `~/Applications/<id>/`.
- [ ] Prints `NEOPLAY_INSTALLED version=X.Y.Z` as the last line on success.
- [ ] Creates a `.desktop` entry + icon.
- [ ] Script is tagged in its repo (`vX.Y.Z`); catalog `source.url` points at that tag.
- [ ] `python tools/validate_catalog.py catalog.json` passes.
