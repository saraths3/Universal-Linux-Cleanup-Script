#!/usr/bin/env bash
set -Eeuo pipefail

ERROR_LOG="error.log"
: > "$ERROR_LOG"

log_error() {
    echo "[ERROR] $1" >> "$ERROR_LOG"
}

echo "This will do wonders"

# --- check requirements ---
if ! command -v rpm >/dev/null 2>&1 || ! command -v dnf >/dev/null 2>&1; then
    echo "This script requires an RPM-based system with dnf."
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

# --- list apps ---
echo "listing installed apps..."
if ! rpm -qa > installed_apps.txt; then
    log_error "failed to list installed apps"
    exit 1
fi

# --- detect bloat ---
echo "checking for bloat..."

BLOAT_LIST=(
    libreoffice cheese rhythmbox aisleriot
    gnome-mahjongg gnome-mines gnome-sudoku
    simple-scan gnome-games totem
)

pattern="$(IFS='|'; echo "${BLOAT_LIST[*]}")"
mapfile -t BLOAT_FOUND < <(grep -E "$pattern" installed_apps.txt || true)

if [ "${#BLOAT_FOUND[@]}" -eq 0 ]; then
    echo "no bloat found"
else
    echo "removing bloat..."
    for pkg in "${BLOAT_FOUND[@]}"; do
        echo "removing $pkg"
        if ! sudo dnf remove -y "$pkg"; then
            log_error "failed removing $pkg"
        fi
    done
fi

# --- cleanup ---
echo "cleaning system..."

if ! sudo dnf clean all; then
    log_error "dnf clean failed"
fi

if ! sudo dnf autoremove -y; then
    log_error "autoremove failed"
fi

# safer cleanup (avoid blind nuking errors)
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
