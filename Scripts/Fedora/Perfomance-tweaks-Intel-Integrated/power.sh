#!/usr/bin/env bash

# Fedora + CachyOS Ultimate Performance Script
# Tested for Fedora 44+
# Run with:
# sudo bash fedora-cachyos-performance.sh

set -e

echo "=========================================="
echo " Fedora + CachyOS High Performance Setup "
echo "=========================================="

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root:"
    echo "sudo bash fedora-cachyos-performance.sh"
    exit 1
fi

echo
echo "[1/13] Updating system..."
dnf -y update

echo
echo "[2/13] Installing DNF plugins..."
dnf -y install dnf-plugins-core

echo
echo "[3/13] Enabling CachyOS COPRs..."
dnf -y copr enable bieszczaders/kernel-cachyos
dnf -y copr enable bieszczaders/kernel-cachyos-addons

echo
echo "[4/13] Installing CachyOS kernel..."
dnf -y install \
    kernel-cachyos \
    kernel-cachyos-devel-matched

echo
echo "[5/13] Removing conflicting Fedora packages..."
dnf -y remove \
    power-profiles-daemon \
    zram-generator-defaults || true

echo
echo "[6/13] Installing performance packages..."
dnf -y install \
    cachyos-settings \
    scx-scheds \
    scx-tools \
    ananicy-cpp \
    tuned \
    tuned-ppd \
    kernel-tools \
    zram-generator \
    --allowerasing

echo
echo "[7/13] Enabling services..."

systemctl enable --now ananicy-cpp || true
systemctl enable --now tuned || true
systemctl enable --now cpupower || true

echo
echo "[8/13] Setting CPU governor to performance..."
cpupower frequency-set -g performance || true

echo
echo "[9/13] Setting tuned profile..."
tuned-adm profile latency-performance || true

echo
echo "[10/13] Configuring zram..."

mkdir -p /etc/systemd

cat > /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = ram * 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

systemctl restart systemd-zram-setup@zram0 || true

echo
echo "[11/13] Configuring sched-ext (scx_lavd)..."

mkdir -p /etc/systemd/system

cat > /etc/systemd/system/scx.service <<EOF
[Unit]
Description=Sched-ext lavd scheduler
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/scx_lavd
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now scx.service

echo
echo "[12/13] Applying I/O scheduler tweaks..."

mkdir -p /etc/udev/rules.d

cat > /etc/udev/rules.d/60-ioschedulers.rules <<EOF
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="mq-deadline"
EOF

udevadm control --reload
udevadm trigger

echo
echo "[13/13] Updating GRUB..."

if grep -q "GRUB_CMDLINE_LINUX" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="preempt=full mitigations=off nowatchdog transparent_hugepage=always /' /etc/default/grub
fi

if [ -d /sys/firmware/efi ]; then
    grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
else
    grub2-mkconfig -o /boot/grub2/grub.cfg
fi

echo
echo "=========================================="
echo " INSTALLATION COMPLETE "
echo "=========================================="

echo
echo "Recommended: reboot now"
echo

echo "Verification commands:"
echo "------------------------------------------"
echo "Kernel:        uname -r"
echo "Governor:      cpupower frequency-info"
echo "Scheduler:     systemctl status scx.service"
echo "THP:           cat /sys/kernel/mm/transparent_hugepage/enabled"
echo

echo "Expected kernel:"
echo "6.x.x-cachyos"

echo
echo "Reboot command:"
echo "sudo reboot"
