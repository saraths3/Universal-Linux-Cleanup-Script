#!/usr/bin/env bash

set -e

echo "======================================="
echo " Fedora + CachyOS Performance Installer"
echo "======================================="

# Must run as root
if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo:"
    echo "sudo bash install-cachy-fedora.sh"
    exit 1
fi

echo
echo "[1/9] Updating system..."
dnf -y update

echo
echo "[2/9] Installing COPR plugin..."
dnf -y install dnf-plugins-core

echo
echo "[3/9] Enabling CachyOS kernel COPR..."
dnf -y copr enable bieszczaders/kernel-cachyos

echo
echo "[4/9] Enabling CachyOS addons COPR..."
dnf -y copr enable bieszczaders/kernel-cachyos-addons

echo
echo "[5/9] Installing CachyOS kernel..."
dnf -y install \
    kernel-cachyos \
    kernel-cachyos-devel-matched

echo
echo "[6/9] Installing performance addons..."
dnf -y install \
    cachyos-settings \
    scx-scheds \
    scx-tools \
    ananicy-cpp \
    tuned \
    tuned-ppd

echo
echo "[7/9] Enabling services..."

# ananicy
systemctl enable --now ananicy-cpp || true

# tuned
systemctl enable --now tuned

# use throughput-performance profile
tuned-adm profile throughput-performance || true

echo
echo "[8/9] Configuring sched-ext..."

mkdir -p /etc/scx

cat > /etc/default/scx <<EOF
SCX_SCHEDULER=scx_rusty
SCX_FLAGS=
EOF

cat > /etc/systemd/system/scx.service <<EOF
[Unit]
Description=sched-ext scheduler
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/scx_rusty
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now scx.service

echo
echo "[9/9] Regenerating GRUB..."

if [ -d /sys/firmware/efi ]; then
    grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
else
    grub2-mkconfig -o /boot/grub2/grub.cfg
fi

echo
echo "======================================="
echo " DONE"
echo "======================================="
echo
echo "Reboot now:"
echo "sudo reboot"
echo
echo "After reboot verify:"
echo "uname -r"
echo
echo "Check sched-ext support:"
echo "zcat /proc/config.gz | grep SCHED_CLASS_EXT"
echo
echo "Try alternative schedulers:"
echo "sudo scx_lavd"
echo "sudo scx_rusty"
echo
echo "Check active scheduler:"
echo "systemctl status scx.service"
