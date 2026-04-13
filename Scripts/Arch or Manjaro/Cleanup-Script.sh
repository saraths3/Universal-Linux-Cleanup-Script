#!/usr/bin/env bash
set -Eeuo pipefail

ERROR_LOG="error.log"
: > "$ERROR_LOG"

log_error() {
    echo "[ERROR] $1" >> "$ERROR_LOG"
}

# --- check requirements ---
if ! command -v pacman >/dev/null 2>&1; then
    echo "This script only supports Arch-based systems (pacman not found)."
    exit 1
fi

# --- system info ---
echo "system info"
echo "-----------"

. /etc/os-release

echo "host: $(hostname)"
echo "os: $PRETTY_NAME"
echo "kernel: $(uname -r)"
echo "uptime: $(uptime -p)"
echo "cpu: $(lscpu | awk -F: '/Model name/ {print $2}' | xargs)"
echo "ram: $(free -h | awk '/Mem:/ {print $3 "/" $2}')"
echo "disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
echo "home: $(df -h "$HOME" | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
echo "desktop: ${XDG_CURRENT_DESKTOP:-unknown}"
echo ""

# --- list installed apps ---
echo "listing installed apps..."
if ! pacman -Qq > installed_apps.txt; then
    log_error "failed to list installed apps"
    exit 1
fi

# --- detect bloat ---
echo "checking for bloat..."

BLOAT_LIST=(
    libreoffice cheese rhythmbox aisleriot
    gnome-mahjongg gnome-mines gnome-sudoku
    simple-scan gnome-games totem
    manjaro-hello web-installer-url-handler
)

pattern="$(IFS='|'; echo "${BLOAT_LIST[*]}")"

mapfile -t BLOAT_FOUND < <(grep -E "$pattern" installed_apps.txt || true)

if [ "${#BLOAT_FOUND[@]}" -eq 0 ]; then
    echo "no bloat found"
else
    echo "removing bloat..."
    for pkg in "${BLOAT_FOUND[@]}"; do
        echo "removing $pkg"
        if ! sudo pacman -Rsn --noconfirm "$pkg"; then
            log_error "failed removing $pkg"
        fi
    done
fi

# --- cleanup ---
echo "cleaning system..."

if ! sudo pacman -Sc --noconfirm; then
    log_error "pacman cache clean failed"
fi

orphans="$(pacman -Qdtq || true)"
if [ -n "$orphans" ]; then
    if ! sudo pacman -Rns --noconfirm $orphans; then
        log_error "failed removing orphan packages"
    fi
else
    echo "no orphan packages"
fi

# safer cache cleanup (no blind nuking)
rm -rf "$HOME/.cache/"* 2>/dev/null || log_error "cache cleanup partial"
rm -rf "$HOME/.local/share/Trash/"* 2>/dev/null || log_error "trash cleanup partial"

if ! sudo journalctl --vacuum-time=7d; then
    log_error "journal cleanup failed"
fi

# --- done ---
if [ -s "$ERROR_LOG" ]; then
    echo "done with errors. see $ERROR_LOG"
else
    echo "done"
    rm -f "$ERROR_LOG"
fi
