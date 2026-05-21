# Arch Cleanup Script

Simple cleanup utility for Arch-based Linux distributions.

Supports:
- Arch Linux
- Manjaro
- EndeavourOS
- Garuda

## Features

- Remove common bloat packages
- Remove orphan packages
- Clean package cache
- Clean user cache
- Vacuum old journal logs
- Dry-run mode
- Error logging

---

## Installation

Clone the repository:

```bash
git clone <your-repo-url>
cd <repo-name>
```

Make the script executable:

```bash
chmod +x cleanup.sh
```

---

## Usage

Run normally:

```bash
./cleanup.sh
```

Run in dry-run mode:

```bash
./cleanup.sh --dry-run
```

---

## What It Cleans

### Packages
Removes optional packages like:

- cheese
- rhythmbox
- totem
- gnome games

### Cache
Cleans:

- package cache
- user cache
- trash
- old journal logs

---

## Logs

Errors are saved to:

```bash
cleanup.log
```

Installed package list:

```bash
installed_packages.txt
```

---

## Requirements

- bash
- pacman
- sudo

Optional:

```bash
sudo pacman -S pacman-contrib
```

for safer cache cleaning using `paccache`.

---

## Warning

Review packages before removal.

Use at your own risk.
