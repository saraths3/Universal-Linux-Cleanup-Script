#!/usr/bin/env bash

set -Eeuo pipefail

# =========================================================
# Arch System Cleanup Utility
# Supports:
#   - Arch Linux
#   - Manjaro
#   - EndeavourOS
#   - Garuda
# =========================================================

readonly LOG_FILE="cleanup.log"
readonly APP_LIST_FILE="installed_packages.txt"

# ---------- colors ----------
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

# ---------- settings ----------
DRY_RUN=false

# ---------- helpers ----------
msg() {
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

# ---------- safety ----------
check_environment() {

    if [[ $EUID -eq 0 ]]; then
        error "Do not run this script as root."
        exit 1
    fi

    if ! command -v pacman >/dev/null 2>&1; then
        error "pacman not found. Arch-based distro required."
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

# ---------- export installed packages ----------
save_installed_packages() {

    msg "Saving installed package list..."

    if pacman -Qqe > "$APP_LIST_FILE"; then
        success "Saved installed packages to $APP_LIST_FILE"
    else
        error "Failed to save installed packages"
    fi
}

# ---------- remove bloat ----------
remove_bloat() {

    msg "Checking for unnecessary packages..."

    source /etc/os-release

    local packages=(
        cheese
        rhythmbox
        aisleriot
        gnome-mahjongg
        gnome-mines
        gnome-sudoku
        simple-scan
        totem
    )

    # distro-specific packages
    if [[ "$ID" == "manjaro" ]]; then
        packages+=(
            manjaro-hello
            web-installer-url-handler
        )
    fi

    local installed=()

    for pkg in "${packages[@]}"; do
        if pacman -Qq "$pkg" &>/dev/null; then
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

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        warn "Skipped package removal"
        return
    fi

    run_cmd sudo pacman -Rns --noconfirm "${installed[@]}"
}

# ---------- remove orphan packages ----------
remove_orphans() {

    msg "Checking orphan packages..."

    mapfile -t orphans < <(pacman -Qdtq 2>/dev/null || true)

    if [[ ${#orphans[@]} -eq 0 ]]; then
        success "No orphan packages found"
        return
    fi

    echo
    echo "Orphan packages:"
    printf ' - %s\n' "${orphans[@]}"
    echo

    read -rp "Remove orphan packages? [y/N]: " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        run_cmd sudo pacman -Rns --noconfirm "${orphans[@]}"
    else
        warn "Skipped orphan cleanup"
    fi
}

# ---------- clean package cache ----------
clean_cache() {

    msg "Cleaning package cache..."

    if command -v paccache >/dev/null 2>&1; then
        run_cmd sudo paccache -r
    else
        warn "paccache not installed"
        warn "Install pacman-contrib for safer cache cleaning"

        read -rp "Use pacman -Sc instead? [y/N]: " confirm

        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            run_cmd sudo pacman -Sc --noconfirm
        fi
    fi
}

# ---------- clean user cache ----------
clean_user_cache() {

    msg "Cleaning user cache..."

    find "$HOME/.cache" -mindepth 1 -delete 2>/dev/null || \
        error "Cache cleanup partially failed"

    find "$HOME/.local/share/Trash" -mindepth 1 -delete 2>/dev/null || \
        error "Trash cleanup partially failed"

    success "User cache cleaned"
}

# ---------- clean journals ----------
clean_journal() {

    msg "Cleaning old journal logs..."

    run_cmd sudo journalctl --vacuum-time=7d
}

# ---------- summary ----------
finish() {

    echo
    echo "========== COMPLETE =========="

    if [[ -s "$LOG_FILE" ]]; then
        warn "Completed with warnings/errors"
        warn "See log file: $LOG_FILE"
    else
        success "Cleanup completed successfully"
        rm -f "$LOG_FILE"
    fi

    echo "================================"
}

# ---------- flags ----------
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

    check_environment

    system_info

    save_installed_packages

    remove_bloat

    remove_orphans

    clean_cache

    clean_user_cache

    clean_journal

    finish
}

main
