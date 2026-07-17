#!/bin/bash
# ==============================================================================
# NEO Play Installer (v2 — native .deb)
# First-time installation script for the NEO Play app store / launcher.
#
# Since v2.0.0 NEO Play is a native (Rust/GTK4) app shipped as a .deb on the
# repo's GitHub Releases, following github-release-convention.md — this script
# downloads the release asset and installs it via apt. The .deb carries the
# desktop entry, icon, and the `neoplay` launch command on PATH, so there is no
# per-user desktop integration step anymore (the old PyPI/pip flow is gone).
#
# Usage:
#   Local:  bash scripts/install_on_neo.sh
#   Remote: curl -sSL https://raw.githubusercontent.com/ThingEdu/neo-play-catalog/main/scripts/install_on_neo.sh | bash
#
# Options:
#   --autostart        Boot straight into NEO Play fullscreen (XDG autostart)
#   --uninstall        Remove NEO Play
#   --version=X.Y.Z    Install a specific release (default: $DEFAULT_VERSION)
# ==============================================================================
set -euo pipefail

# -- Configuration ------------------------------------------------------------
# Release .debs are hosted on THIS (public) repo's GitHub Releases — the app
# repo (ThingEdu/NeoPlay) is private, so its assets aren't downloadable from a
# device. Tags here are app-prefixed (neo-play-vX.Y.Z) since the catalog can
# host assets for more than one app.
REPO="ThingEdu/neo-play-catalog"
PKG="neo-play"                # dpkg Package: name; launch command of the same name
DISPLAY_NAME="NEO Play"
# v2.0.0 ships as a GitHub *pre-release*: `releases/latest` skips pre-releases,
# so the default is pinned here and bumped on each release of this script.
DEFAULT_VERSION="2.0.0"
AUTOSTART_FILE="$HOME/.config/autostart/neo-play.desktop"
RAW_INSTALL_URL="https://raw.githubusercontent.com/ThingEdu/neo-play-catalog/main/scripts/install_on_neo.sh"

# -- Parse arguments -----------------------------------------------------------
AUTOSTART=false
UNINSTALL=false
INSTALL_VERSION="$DEFAULT_VERSION"

for arg in "$@"; do
    case "$arg" in
        --autostart)  AUTOSTART=true ;;
        --uninstall)  UNINSTALL=true ;;
        --version=*)  INSTALL_VERSION="${arg#*=}" ;;
        *)            echo "Unknown option: $arg"; exit 1 ;;
    esac
done

# -- Helpers -------------------------------------------------------------------
info()  { echo -e "\033[1;32m[INFO]\033[0m  $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m  $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

require_cmd() {
    if ! command -v "$1" &>/dev/null; then
        error "'$1' is required but not found. Please install it first."
        exit 1
    fi
}

# -- Uninstall -----------------------------------------------------------------
do_uninstall() {
    info "Uninstalling $DISPLAY_NAME..."
    sudo apt-get remove -y "$PKG" || true

    if [ -f "$AUTOSTART_FILE" ]; then
        rm -f "$AUTOSTART_FILE"
        info "Removed autostart entry: $AUTOSTART_FILE"
    fi

    info "$DISPLAY_NAME has been uninstalled."
    exit 0
}

if [ "$UNINSTALL" = true ]; then
    require_cmd apt-get
    do_uninstall
fi

# -- Pre-flight checks ---------------------------------------------------------
require_cmd curl
require_cmd apt-get
require_cmd dpkg

ARCH="$(dpkg --print-architecture)"   # arm64 on NEO One, amd64 on dev machines
info "Detected architecture: $ARCH"

# -- Step 1: Download the release .deb ----------------------------------------
# Asset naming per github-release-convention.md: <pkg>_<X.Y.Z>_<arch>.deb
DEB_NAME="${PKG}_${INSTALL_VERSION}_${ARCH}.deb"
DEB_URL="https://github.com/$REPO/releases/download/${PKG}-v${INSTALL_VERSION}/${DEB_NAME}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

info "Downloading $DISPLAY_NAME v$INSTALL_VERSION ($DEB_NAME)..."
if ! curl -fSL --progress-bar -o "$TMP_DIR/$DEB_NAME" "$DEB_URL"; then
    error "Download failed: $DEB_URL"
    error "Check that release v$INSTALL_VERSION exists and your network is up."
    exit 1
fi

# -- Step 2: Install via apt ---------------------------------------------------
# apt resolves the package's Depends from the distro repos; --allow-downgrades
# makes pinning an older --version work.
info "Installing $DISPLAY_NAME (sudo required)..."
sudo apt-get update -qq || warn "apt-get update reported errors; continuing."
sudo apt-get install -y --allow-downgrades "$TMP_DIR/$DEB_NAME" \
    || { error "apt failed to install $DEB_NAME."; exit 1; }

# -- Step 3: Verify ------------------------------------------------------------
if ! command -v "$PKG" &>/dev/null; then
    error "Installation failed - '$PKG' command not found on PATH."
    exit 1
fi
info "Verified: $(command -v "$PKG") ($(dpkg-query -W -f='${Version}' "$PKG"))"

# -- Step 4: Fullscreen autostart (classroom mode) ----------------------------
install_autostart() {
    if [ "$AUTOSTART" != true ]; then
        return
    fi

    mkdir -p "$(dirname "$AUTOSTART_FILE")"
    cat > "$AUTOSTART_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=NEO Play
Comment=NEO app store — launches fullscreen on startup
Exec=env NEOPLAY_FULLSCREEN=1 $PKG
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
    info "Enabled fullscreen autostart: $AUTOSTART_FILE"
}

install_autostart

# -- Done ----------------------------------------------------------------------
echo ""
info "=========================================="
info "  $DISPLAY_NAME v$INSTALL_VERSION installed successfully!"
info "=========================================="
echo ""
echo "  Run:  $PKG"
echo ""
echo "  Uninstall:  curl -sSL $RAW_INSTALL_URL | bash -s -- --uninstall"
echo ""
