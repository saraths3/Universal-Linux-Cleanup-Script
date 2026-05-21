#!/usr/bin/env bash

set -Eeuo pipefail

# =========================================================
# Fedora Cleanup Utility
# Supports:
#   - Fedora
#   - Nobara
#   - RHEL
#   - Rocky Linux
#   - AlmaLinux
# =========================================================

readonly LOG_FILE="cleanup.log"
readonly PACKAGE_LIST="installed_packages.txt"

DRY_RUN=false

# ---------- colors ----------
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

# ---------- logging ----------
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $1" >> "$LOG_FILE"
}

run_cmd() {
    if $DRY_RUN; then
        echo "[DRY RUN] $*"
    else
        "$@"
    fi
}

# ---------- checks ----------
check_system() {

    if [[ $EUID -eq 0 ]]; then
        error "Do not run this script as root."
        exit 1
    fi

    if ! command -v dnf >/dev/null 2>&1; then
        error "dnf not found. Fedora/RHEL-based distro required."
        exit 1
    fi
}

# ---------- system info ----------
system_info() {

    source /etc/os-release

    echo
    echo "========== SYSTEM INFO =========="
    echo "Hostname : $(hostname)"
    echo "OS       : $PRETTY_NAME"
    echo "Kernel   : $(uname -r)"
    echo "Desktop  : ${XDG_CURRENT_DESKTOP:-Unknown}"
    echo "Uptime   : $(uptime -p)"
    echo "CPU      : $(lscpu | awk -F: '/Model name/ {print $2}' | xargs)"
    echo "RAM      : $(free -h | awk '/Mem:/ {print $3 "/" $2}')"
    echo "Disk     : $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
    echo "Home     : $(df -h "$HOME" | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
    echo "================================="
    echo
}

# ---------- export package list ----------
save_packages() {

    info "Saving installed package list..."

    if rpm -qa > "$PACKAGE_LIST"; then
        success "Saved package list to $PACKAGE_LIST"
    else
        error "Failed to save package list"
    fi
}

# ---------- remove bloat ----------
remove_bloat() {

    info "Checking for unnecessary packages..."

    local packages=(
        cheese
        rhythmbox
        aisleriot
        gnome-mahjongg
        gnome-mines
        gnome-sudoku
        simple-scan
        gnome-games
        totem
    )

    local installed=()

    for pkg in "${packages[@]}"; do
        if rpm -q "$pkg" &>/dev/null; then
            installed+=("$pkg")
        fi
    done

    if [[ ${#installed[@]} -eq 0 ]]; then
        success "No bloat packages found"
        return
    fi

    echo
    echo "Packages to remove:"
    printf ' - %s\n' "${installed[@]}"
    echo

    read -rp "Continue removal? [y/N]: " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        run_cmd sudo dnf remove -y "${installed[@]}"
    else
        warn "Skipped package removal"
    fi
}

# ---------- cleanup ----------
system_cleanup() {

    info "Running system cleanup..."

    run_cmd sudo dnf autoremove -y
    run_cmd sudo dnf clean all
}

# ---------- user cache ----------
clean_user_cache() {

    info "Cleaning user cache..."

    find "$HOME/.cache" -mindepth 1 -delete 2>/dev/null || \
        error "Cache cleanup partially failed"

    find "$HOME/.local/share/Trash" -mindepth 1 -delete 2>/dev/null || \
        error "Trash cleanup partially failed"

    success "User cache cleaned"
}

# ---------- journals ----------
clean_journal() {

    info "Cleaning old journal logs..."

    run_cmd sudo journalctl --vacuum-time=7d
}

# ---------- finish ----------
finish() {

    echo
    echo "========== COMPLETE =========="

    if [[ -s "$LOG_FILE" ]]; then
        warn "Completed with warnings/errors"
        warn "Check: $LOG_FILE"
    else
        success "Cleanup completed successfully"
        rm -f "$LOG_FILE"
    fi

    echo "================================"
}

# ---------- args ----------
for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=true
            ;;
    esac
done

# ---------- main ----------
main() {

    : > "$LOG_FILE"

    check_system

    system_info

    save_packages

    remove_bloat

    system_cleanup

    clean_user_cache

    clean_journal

    finish
}

main
