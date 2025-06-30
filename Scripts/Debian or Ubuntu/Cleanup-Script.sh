#!/bin/bash

set -euo pipefail
ERROR_LOG="_"
> "$ERROR_LOG"

# system info
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

# app list
echo "listing installed apps..."
dpkg --get-selections | awk '{print $1}' > installed_apps.txt || { echo "failed to list apps" >> "$ERROR_LOG"; exit 1; }

# detect bloat
echo "checking for bloat..."
BLOAT_LIST=("libreoffice" "cheese" "rhythmbox" "thunderbird" "aisleriot" "gnome-mahjongg" "gnome-mines" "gnome-sudoku" "simple-scan" "gnome-games")
BLOAT_FOUND=()

while read -r app; do
    for bloat in "${BLOAT_LIST[@]}"; do
        [[ "$app" == *"$bloat"* ]] && BLOAT_FOUND+=("$app")
    done
done < installed_apps.txt

if [ ${#BLOAT_FOUND[@]} -eq 0 ]; then
    echo "no bloat found"
else
    echo "removing bloat..."
    for pkg in "${BLOAT_FOUND[@]}"; do
        echo "removing $pkg"
        sudo apt remove -y "$pkg" || { echo "error removing $pkg" >> "$ERROR_LOG"; exit 1; }
    done
fi

# cleanup
echo "cleaning system..."
sudo apt clean || { echo "apt clean failed" >> "$ERROR_LOG"; exit 1; }
sudo apt autoremove -y || { echo "autoremove failed" >> "$ERROR_LOG"; exit 1; }

rm -rf ~/.cache/* ~/.local/share/Trash/* ~/.thumbnails/* || echo "cache not fully cleaned" >> "$ERROR_LOG"
sudo journalctl --vacuum-time=7d || echo "journal not cleaned" >> "$ERROR_LOG"

# done
if [ -s "$ERROR_LOG" ]; then
    echo "done with errors, see _"
else
    echo "done"
    rm -f "$ERROR_LOG"
fi
