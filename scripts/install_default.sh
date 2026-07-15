#!/bin/bash
# ==============================================================================
# One-liner install script for NEO One setup.
# Sets up NEO One with the default STEAM applications shipped by ThingEdu.
# Author: lgthevinh (NEO One maintainer)
#
# Apps installed:
#   ThingEdu (self-installing scripts):
#     neo-stopmotion, neo-arcade, neo-piano, neo-stem
#   Distro packages (apt):
#     gcompris (gcompris-qt), kturtle
#
# Usage:
#   Local:  bash scripts/install_default.sh
#   Remote: curl -sSL https://raw.githubusercontent.com/ThingEdu/neo-play-catalog/main/scripts/install_default.sh | bash
# ==============================================================================
# No `-e`: one failing app must not abort the whole batch. Failures are
# collected and reported in a summary at the end instead.
set -uo pipefail

# -- Helpers -------------------------------------------------------------------
info()  { echo -e "\033[1;32m[INFO]\033[0m  $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m  $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

FAILED=()

# -- ThingEdu apps: each ships its own scripts/install_on_neo.sh ---------------
# Format: "display-name|raw install_on_neo.sh URL"
RAW="https://raw.githubusercontent.com"
APP_SCRIPTS=(
    "neo-stopmotion|$RAW/ThingEdu/neo-stopmotion/main/scripts/install_on_neo.sh"
    "neo-arcade|$RAW/ThingEdu/NeoArcade/main/scripts/install_on_neo.sh"
    "neo-piano|$RAW/ThingEdu/neo-piano/main/scripts/install_on_neo.sh"
    "neo-stem|$RAW/ThingEdu/neo-stem/master/scripts/install_on_neo.sh"
)

install_app_scripts() {
    for entry in "${APP_SCRIPTS[@]}"; do
        local name="${entry%%|*}"
        local url="${entry##*|}"
        info "Installing $name ..."
        if curl -fsSL "$url" | bash; then
            info "$name installed."
        else
            error "$name failed to install."
            FAILED+=("$name")
        fi
    done
}

# -- Distro apps via apt -------------------------------------------------------
APT_PACKAGES=(gcompris-qt kturtle)

install_apt_packages() {
    if ! command -v apt-get &>/dev/null; then
        warn "apt-get not found; skipping ${APT_PACKAGES[*]}."
        FAILED+=("${APT_PACKAGES[@]}")
        return
    fi
    info "Installing apt packages: ${APT_PACKAGES[*]} ..."
    sudo apt-get update -qq || warn "apt-get update reported errors; continuing."
    if sudo apt-get install -y "${APT_PACKAGES[@]}"; then
        info "apt packages installed."
    else
        error "apt install failed for: ${APT_PACKAGES[*]}"
        FAILED+=("${APT_PACKAGES[@]}")
    fi
}

# -- Run -----------------------------------------------------------------------
require_curl() {
    if ! command -v curl &>/dev/null; then
        error "'curl' is required but not found. Install it and rerun."
        exit 1
    fi
}

require_curl
install_app_scripts
install_apt_packages

# -- Summary -------------------------------------------------------------------
echo ""
info "=========================================="
if [ "${#FAILED[@]}" -eq 0 ]; then
    info "  All default NEO One apps installed!"
    info "=========================================="
    exit 0
fi
error "  Some apps failed to install:"
for f in "${FAILED[@]}"; do
    error "    - $f"
done
error "=========================================="
exit 1
