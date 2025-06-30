# Universal-Linux-Cleanup-Script
A universal shell script to clean and optimize any Linux system. It auto-detects the distro, removes cache, junk files, bloatware, and frees up space. Works on Ubuntu, Fedora, Arch, and more. Simple, human-readable, and safe for everyday use. Ideal for fresh installs or regular maintenance.

# 🧼 Universal Linux Cleanup Script

![Preview](https://pixabay.com/get/gd53a215ce99e3f8342925bf13e0701f03dfa6042c9681ee58329de3378025905108c021675d8d4a5bbedb0a55a0fb62e9be06a0387b88e9f1dc7f2cf240360856d01360b0ed1dfb27e452d55f9c40743_1280.png?attachment=)


A lightweight, smart, and safe bash script to clean and optimize **any Linux desktop system**.  
Supports **Ubuntu, Fedora, Arch, openSUSE, Manjaro, Pop!_OS, Linux Mint** and more.

---

## ✨ Features

- 📊 Displays system info (CPU, RAM, disk, uptime, desktop)
- 🔍 Scans and removes common bloatware
- 🧹 Cleans:
  - Package cache
  - User trash & thumbnail junk
  - Old logs (`journalctl`)
  - Orphan packages (Arch)
- ⚠️ Stops on critical errors and logs issues to `_`
- 💻 Works across all major desktop environments (GNOME, KDE, XFCE, etc.)

---

## 🗃️ Script List

| Script Name             | Distro(s)              | Package Manager |
|-------------------------|------------------------|------------------|
| `universal_cleanup.sh`  | Auto (All supported)   | Auto-detects     |
| `ubuntu_cleanup.sh`     | Ubuntu, Mint, Debian   | `apt`            |
| `fedora_cleanup.sh`     | Fedora                 | `dnf`            |
| `arch_cleanup.sh`       | Arch, Manjaro          | `pacman`         |
| `opensuse_cleanup.sh`   | openSUSE               | `zypper`         |

---

## 🚀 Quick Start

```bash
git clone https://github.com/saraths3/Universal-Linux-Cleanup-Script.git
cd Universal-Linux-Cleanup-Script
chmod +x *.sh
./universal_cleanup.sh       # or run specific: ./ubuntu_cleanup.sh
