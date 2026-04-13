#!/usr/bin/env bash
set -Eeuo pipefail

ERROR_LOG="cleanup_errors.log"
: > "$ERROR_LOG"

log_error() {
    echo "[ERROR] $1" >> "$ERROR_LOG"
}

show_info() {
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
}

detect_distro() {
    if ! . /etc/os-release; then
        log_error "failed to detect distro"
        exit 1
    fi
    DISTRO="$ID"
}

list_apps() {
    echo "listing apps..."

    case "$DISTRO" in
        ubuntu|debian)
            dpkg --get-selections | awk '{print $1}' > installed_apps.txt || { log_error "dpkg failed"; exit 1; }
            ;;
        arch|manjaro)
            pacman -Qq > installed_apps.txt || { log_error "pacman list failed"; exit 1; }
            ;;
        fedora)
            rpm -qa > installed_apps.txt || { log_error "rpm list failed"; exit 1; }
            ;;
        opensuse*)
            zypper search --installed-only | awk 'NR>5 {print $3}' > installed_apps.txt || { log_error "zypper list failed"; exit 1; }
            ;;
        *)
            log_error "unsupported distro"
            exit 1
            ;;
    esac
}

remove_bloat() {
    echo "checking bloat..."

    BLOAT_LIST=(
        libreoffice cheese rhythmbox thunderbird
        aisleriot gnome-mahjongg gnome-mines
        gnome-sudoku simple-scan gnome-games
    )

    pattern="$(IFS='|'; echo "${BLOAT_LIST[*]}")"
    mapfile -t BLOAT_FOUND < <(grep -E "$pattern" installed_apps.txt || true)

    if [ "${#BLOAT_FOUND[@]}" -eq 0 ]; then
        echo "no bloat"
        return
    fi

    echo "bloat found:"
    printf '%s\n' "${BLOAT_FOUND[@]}"

    read -rp "remove bloat? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "skip bloat"; return; }

    for pkg in "${BLOAT_FOUND[@]}"; do
        echo "removing $pkg"
        case "$DISTRO" in
            ubuntu|debian)
                sudo apt remove -y "$pkg" || log_error "failed removing $pkg"
                ;;
            arch|manjaro)
                sudo pacman -Rsn --noconfirm "$pkg" || log_error "failed removing $pkg"
                ;;
            fedora)
                sudo dnf remove -y "$pkg" || log_error "failed removing $pkg"
                ;;
            opensuse*)
                sudo zypper rm -y "$pkg" || log_error "failed removing $pkg"
                ;;
        esac
    done
}

clean_system() {
    echo "cleaning starting..."

    case "$DISTRO" in
        ubuntu|debian)
            sudo apt clean || log_error "apt clean failed"
            sudo apt autoremove -y || log_error "autoremove failed"
            ;;
        arch|manjaro)
            sudo pacman -Sc --noconfirm || log_error "pacman clean failed"
            orphans="$(pacman -Qdtq || true)"
            [ -n "$orphans" ] && sudo pacman -Rns --noconfirm $orphans || true
            ;;
        fedora)
            sudo dnf clean all || log_error "dnf clean failed"
            sudo dnf autoremove -y || log_error "autoremove failed"
            ;;
        opensuse*)
            sudo zypper clean --all || log_error "zypper clean failed"
            ;;
    esac

    rm -rf "$HOME/.cache/"* 2>/dev/null || log_error "cache cleanup partial"
    rm -rf "$HOME/.local/share/Trash/"* 2>/dev/null || log_error "trash cleanup partial"

    sudo journalctl --vacuum-time=7d || log_error "journal cleanup failed"

    echo "cleaning done"
}

main() {
    clear
    echo "linux cleanup"
    echo "-------------"

    detect_distro
    show_info
    list_apps
    remove_bloat
    clean_system

    if [ -s "$ERROR_LOG" ]; then
        echo "errors found, see $ERROR_LOG"
    else
        echo "done"
        rm -f "$ERROR_LOG"
    fi
}

main
