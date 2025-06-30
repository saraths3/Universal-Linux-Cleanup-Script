#!/bin/bash

set -euo pipefail
ERROR_LOG="cleanup_errors.log"
> "$ERROR_LOG"

show_info() {
    echo "system info"
    echo "-----------"
    echo "host: $(hostname)"
    echo "os: $(source /etc/os-release && echo "$PRETTY_NAME")"
    echo "kernel: $(uname -r)"
    echo "uptime: $(uptime -p)"
    echo "cpu: $(lscpu | grep 'Model name' | sed 's/Model name:[ \t]*//')"
    echo "ram: $(free -h | awk '/Mem:/ {print $3 "/" $2}')"
    echo "disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
    echo "home: $(df -h "$HOME" | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
    echo "desktop: ${XDG_CURRENT_DESKTOP:-unknown}"
    echo ""
}

detect_distro() {
    . /etc/os-release || { echo "distro not found" | tee -a "$ERROR_LOG"; exit 1; }
    DISTRO=$ID
}

list_apps() {
    echo "listing apps..."
    case "$DISTRO" in
        ubuntu|debian) dpkg --get-selections | awk '{print $1}' > installed_apps.txt ;;
        arch|manjaro) pacman -Qq > installed_apps.txt ;;
        fedora) rpm -qa > installed_apps.txt ;;
        opensuse*) zypper search --installed-only | awk '{print $3}' | tail -n +6 > installed_apps.txt ;;
        *) echo "skip app listing" | tee -a "$ERROR_LOG"; exit 1 ;;
    esac
}

remove_bloat() {
    echo "checking bloat..."
    BLOAT_LIST=("libreoffice" "cheese" "rhythmbox" "thunderbird" "aisleriot" "gnome-mahjongg" "gnome-mines" "gnome-sudoku" "simple-scan" "gnome-games")
    BLOAT_FOUND=()

    while read -r app; do
        for bloat in "${BLOAT_LIST[@]}"; do
            [[ "$app" == *"$bloat"* ]] && BLOAT_FOUND+=("$app")
        done
    done < installed_apps.txt

    if [ ${#BLOAT_FOUND[@]} -eq 0 ]; then
        echo "no bloat"
        return
    fi

    echo "bloat found:"
    printf '%s\n' "${BLOAT_FOUND[@]}"

    read -p "remove bloat? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for pkg in "${BLOAT_FOUND[@]}"; do
            echo "removing $pkg"
            case "$DISTRO" in
                ubuntu|debian) sudo apt remove -y "$pkg" || echo "$pkg error" >> "$ERROR_LOG" ;;
                arch|manjaro) sudo pacman -Rsn --noconfirm "$pkg" || echo "$pkg error" >> "$ERROR_LOG" ;;
                fedora) sudo dnf remove -y "$pkg" || echo "$pkg error" >> "$ERROR_LOG" ;;
                opensuse*) sudo zypper rm -y "$pkg" || echo "$pkg error" >> "$ERROR_LOG" ;;
                *) echo "$pkg not removed" >> "$ERROR_LOG" ;;
            esac
        done
    else
        echo "skip bloat"
    fi
}

clean_system() {
    echo "cleaning starting..."
    case "$DISTRO" in
        ubuntu|debian) sudo apt clean && sudo apt autoremove -y || echo "apt clean error" >> "$ERROR_LOG" ;;
        arch|manjaro) sudo pacman -Sc --noconfirm || echo "pacman clean error" >> "$ERROR_LOG" ;;
        fedora) sudo dnf clean all && sudo dnf autoremove -y || echo "dnf clean error" >> "$ERROR_LOG" ;;
        opensuse*) sudo zypper clean --all || echo "zypper clean error" >> "$ERROR_LOG" ;;
        *) echo "clean skipped" >> "$ERROR_LOG" ;;
    esac

    rm -rf ~/.cache/* ~/.local/share/Trash/* ~/.thumbnails/* || echo "cache error" >> "$ERROR_LOG"
    sudo journalctl --vacuum-time=7d || echo "log clean skipped" >> "$ERROR_LOG"
    echo "cleaning done"
}

main() {
    clear
    echo "linux cleanup"
    echo "-------------"
    show_info
    detect_distro
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
