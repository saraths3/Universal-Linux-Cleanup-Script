# 🧼 Universal Linux Cleanup Script

![GitHub](https://img.shields.io/github/license/saraths3/Universal-Linux-Cleanup-Script)
![Platform](https://img.shields.io/badge/platform-linux-blue)
![Maintenance](https://img.shields.io/badge/maintained-yes-brightgreen)
![Shell](https://img.shields.io/badge/shell-bash-yellow)

A universal, human-readable shell script to clean, optimize, and maintain any Linux system.  
Supports **Ubuntu, Debian, Fedora, Arch, openSUSE, Manjaro, Pop!_OS, Linux Mint**, and many more.

> Ideal for fresh installs or regular maintenance. Lightweight, safe, and smart.

---

![Preview](https://github.com/saraths3/Universal-Linux-Cleanup-Script/raw/refs/heads/main/logo.png)

---

## ✨ Features

- 📊 Displays system information:
  - CPU, RAM, Disk, OS, Desktop Environment
- 🔍 Detects and removes common bloatware
- 🧹 Cleans system junk:
  - Package manager cache
  - User trash, thumbnails
  - Journal logs
  - Orphaned packages (Arch)
- 🛠️ Auto-detects distro & package manager
- 💥 Handles errors gracefully and logs output
- 🧠 Intelligent checks for sudo/root access
- 💻 Compatible with all major desktop environments (GNOME, KDE, XFCE, Cinnamon, etc.)

---

## 🗃️ Available Scripts

| Script Name             | Supported Distros        | Package Manager |
|-------------------------|---------------------------|------------------|
| `universal_cleanup.sh`  | Auto (All supported)      | Auto-detect      |
| `ubuntu_cleanup.sh`     | Ubuntu, Linux Mint, Debian| `apt`            |
| `fedora_cleanup.sh`     | Fedora                    | `dnf`            |
| `arch_cleanup.sh`       | Arch, Manjaro             | `pacman`         |
| `opensuse_cleanup.sh`   | openSUSE                  | `zypper`         |

---

## 📥 Installation

Clone this repository:

```bash
git clone https://github.com/saraths3/Universal-Linux-Cleanup-Script.git
cd Universal-Linux-Cleanup-Script
