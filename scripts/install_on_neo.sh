#!/bin/bash
# ==============================================================================
# NEOPlay Installer
# First-time installation script for the NEOPlay app store / launcher.
# Handles ARM (Armbian/Raspberry Pi) and x86 platforms automatically.
#
# Usage:
#   Local:  bash scripts/install_on_neo.sh
#   Remote: curl -sSL https://raw.githubusercontent.com/ThingEdu/neo-play-catalog/main/scripts/install_on_neo.sh | bash
#
# Options:
#   --no-desktop       Skip .desktop file installation
#   --autostart        Boot straight into NEOPlay fullscreen (XDG autostart)
#   --uninstall        Remove NEOPlay installation
#   --version=X.Y.Z    Install a specific version from PyPI (default: latest)
# ==============================================================================
set -euo pipefail

# -- Configuration ------------------------------------------------------------
APP_NAME="neo-play"
DISPLAY_NAME="NEOPlay"
BIN_LINK="$HOME/.local/bin/neoplay"
DESKTOP_FILE="$HOME/.local/share/applications/neoplay.desktop"
AUTOSTART_FILE="$HOME/.config/autostart/neoplay.desktop"
PYPI_PACKAGE="neo-play"
PYTHON_MODULE="neoplay"
INSTALL_VERSION=""   # set via --version=X.Y.Z; empty = latest from PyPI
RAW_INSTALL_URL="https://raw.githubusercontent.com/ThingEdu/neo-play-catalog/main/scripts/install_on_neo.sh"

# -- Parse arguments -----------------------------------------------------------
SKIP_DESKTOP=false
AUTOSTART=false
UNINSTALL=false

for arg in "$@"; do
    case "$arg" in
        --no-desktop) SKIP_DESKTOP=true ;;
        --autostart)  AUTOSTART=true ;;
        --uninstall)  UNINSTALL=true ;;
        --version=*)  INSTALL_VERSION="${arg#*=}" ;;
        *)            echo "Unknown option: $arg"; exit 1 ;;
    esac
done

if [ -n "$INSTALL_VERSION" ]; then
    PYPI_SPEC="${PYPI_PACKAGE}==${INSTALL_VERSION}"
else
    PYPI_SPEC="${PYPI_PACKAGE}"
fi

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

detect_arch() {
    local machine
    machine="$(uname -m)"
    case "$machine" in
        aarch64|armv7l|armv6l) echo "arm" ;;
        x86_64|i686|i386)     echo "x86" ;;
        *)                    echo "unknown" ;;
    esac
}

# pip install wrapper that adds --break-system-packages when needed.
pip_install() {
    local bsp=""
    if python3 -m pip install --help 2>&1 | grep -q "break-system-packages"; then
        bsp="--break-system-packages"
    fi
    python3 -m pip install $bsp "$@"
}

pip_uninstall() {
    local bsp=""
    if python3 -m pip install --help 2>&1 | grep -q "break-system-packages"; then
        bsp="--break-system-packages"
    fi
    python3 -m pip uninstall -y $bsp "$@" 2>/dev/null || true
}

python_has_pyqt6() {
    python3 - <<'PY' 2>/dev/null
from PyQt6.QtCore import QT_VERSION_STR
from PyQt6.QtWidgets import QApplication
from PyQt6.QtSvgWidgets import QSvgWidget
print(QT_VERSION_STR)
PY
}

# -- Uninstall -----------------------------------------------------------------
do_uninstall() {
    info "Uninstalling $DISPLAY_NAME..."

    pip_uninstall "$PYPI_PACKAGE"

    if [ -L "$BIN_LINK" ] || [ -f "$BIN_LINK" ]; then
        rm -f "$BIN_LINK"
        info "Removed symlink: $BIN_LINK"
    fi

    if [ -f "$DESKTOP_FILE" ]; then
        rm -f "$DESKTOP_FILE"
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
        info "Removed desktop entry: $DESKTOP_FILE"
    fi

    if [ -f "$AUTOSTART_FILE" ]; then
        rm -f "$AUTOSTART_FILE"
        info "Removed autostart entry: $AUTOSTART_FILE"
    fi

    info "$DISPLAY_NAME has been uninstalled."
    exit 0
}

if [ "$UNINSTALL" = true ]; then
    do_uninstall
fi

# -- Pre-flight checks ---------------------------------------------------------
ARCH="$(detect_arch)"
info "Detected architecture: $ARCH ($(uname -m))"

require_cmd python3

PYTHON_VERSION="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
PYTHON_MAJOR="${PYTHON_VERSION%%.*}"
PYTHON_MINOR="${PYTHON_VERSION##*.}"

if [ "$PYTHON_MAJOR" -lt 3 ] || { [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 11 ]; }; then
    error "Python 3.11+ is required (found $PYTHON_VERSION)."
    exit 1
fi
info "Python $PYTHON_VERSION found."

# -- Step 1: Install system dependencies --------------------------------------
install_system_deps() {
    if [ "$ARCH" = "arm" ]; then
        info "ARM detected - installing Qt/PyQt6 system packages (no source build)..."
        sudo apt-get update -qq
        sudo apt-get install -y -qq \
            python3-pip \
            python3-pyqt6 \
            python3-pyqt6.qtsvg \
            qt6-qpa-plugins \
            qt6-wayland \
            libegl1 \
            libgl1 \
            libglib2.0-0 \
            libxkbcommon-x11-0 \
            libxcb-cursor0 \
            libxcb-xinerama0 \
            2>/dev/null || true
    elif [ "$ARCH" = "x86" ]; then
        info "x86 detected - PyQt6 will be installed via pip wheels."
        if command -v apt-get &>/dev/null; then
            sudo apt-get update -qq
            sudo apt-get install -y -qq git python3-pip 2>/dev/null || true
        fi
    else
        warn "Unknown architecture '$(uname -m)'. Proceeding with pip-based install."
    fi
}

install_system_deps

# -- Step 2: Install package --------------------------------------------------
info "Installing $DISPLAY_NAME..."

if [ "$ARCH" = "arm" ]; then
    # ARM: avoid rebuilding PyQt6 from source - use the system apt packages.
    info "ARM detected - installing without Python package dependencies..."
    pip_install --no-deps --quiet "$PYPI_SPEC" \
        || { error "Failed to install ${PYPI_SPEC} from PyPI. Check your network and try again."; exit 1; }

    if ! python_has_pyqt6 >/dev/null; then
        error "PyQt6 (QtWidgets/QtSvgWidgets) is not available from apt packages."
        error "Install python3-pyqt6 and python3-pyqt6.qtsvg for this release, then rerun this script."
        exit 1
    fi
else
    # x86: PyQt6 wheels are available, normal install.
    pip_install --quiet "$PYPI_SPEC" \
        || { error "Failed to install ${PYPI_SPEC} from PyPI. Check your network and try again."; exit 1; }
    info "Installed ${PYPI_SPEC} from PyPI."
fi

# -- Step 3: Verify installation ----------------------------------------------
# pip installs scripts to ~/.local/bin on Linux
NEO_BIN="$(python3 -c "
import sysconfig, os
scripts = sysconfig.get_path('scripts', 'posix_user')
print(os.path.join(scripts, 'neoplay'))
" 2>/dev/null || echo "$HOME/.local/bin/neoplay")"

if [ ! -f "$NEO_BIN" ]; then
    # Also check if it ended up on the system path
    NEO_BIN="$(command -v neoplay 2>/dev/null || true)"
fi

if [ -z "$NEO_BIN" ] || [ ! -f "$NEO_BIN" ]; then
    error "Installation failed - 'neoplay' binary not found."
    error "Check the output above for errors."
    exit 1
fi

# Ensure symlink in ~/.local/bin
mkdir -p "$(dirname "$BIN_LINK")"
if [ "$NEO_BIN" != "$BIN_LINK" ]; then
    ln -sf "$NEO_BIN" "$BIN_LINK"
fi
info "Verified: $NEO_BIN"

# -- Step 4: Desktop integration ----------------------------------------------
install_desktop_entry() {
    if [ "$SKIP_DESKTOP" = true ]; then
        info "Skipping desktop integration (--no-desktop)."
        return
    fi

    mkdir -p "$(dirname "$DESKTOP_FILE")"
    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=NEOPlay
GenericName=App Store
Comment=App store and launcher for NEO devices
Exec=$BIN_LINK
Terminal=false
Categories=Education;
Keywords=neo;app store;launcher;education;maker;
StartupNotify=true
EOF

    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    info "Created desktop entry: $DESKTOP_FILE"
}

install_desktop_entry

# -- Step 5: Fullscreen autostart (classroom mode) ----------------------------
install_autostart() {
    if [ "$AUTOSTART" != true ]; then
        return
    fi

    mkdir -p "$(dirname "$AUTOSTART_FILE")"
    cat > "$AUTOSTART_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=NEOPlay
Comment=NEO app store — launches fullscreen on startup
Exec=env NEOPLAY_FULLSCREEN=1 $BIN_LINK
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
    info "Enabled fullscreen autostart: $AUTOSTART_FILE"
}

install_autostart

# -- Step 6: Ensure ~/.local/bin is in PATH -----------------------------------
ensure_path() {
    local bin_dir="$HOME/.local/bin"
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        warn "$bin_dir is not in your PATH."

        local shell_rc=""
        case "$(basename "${SHELL:-sh}")" in
            zsh)  shell_rc="$HOME/.zshrc" ;;
            bash) shell_rc="$HOME/.bashrc" ;;
            *)    shell_rc="$HOME/.profile" ;;
        esac

        if [ -f "$shell_rc" ] && ! grep -q 'local/bin' "$shell_rc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_rc"
            info "Added $bin_dir to PATH in $shell_rc"
            info "Run 'source $shell_rc' or open a new terminal to use 'neoplay'."
        fi
    fi
}

ensure_path

# -- Done ----------------------------------------------------------------------
echo ""
info "=========================================="
info "  $DISPLAY_NAME installed successfully!"
info "=========================================="
echo ""
echo "  Run:  neoplay"
echo ""
echo "  Uninstall:  curl -sSL $RAW_INSTALL_URL | bash -s -- --uninstall"
echo ""
