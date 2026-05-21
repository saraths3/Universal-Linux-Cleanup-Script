# Debian Cleanup Script

Cleanup utility for Debian-based Linux distributions.

Supports:
- Debian
- Ubuntu
- Linux Mint
- Pop!_OS
- KDE Neon

## Features

- Remove common bloat packages
- Run autoremove/autoclean
- Clean user cache
- Clean trash
- Vacuum old journal logs
- Dry-run support

---

## Installation

```bash
git clone <repo-url>
cd <repo>
chmod +x cleanup.sh
```

---

## Usage

Run normally:

```bash
./cleanup.sh
```

Dry run:

```bash
./cleanup.sh --dry-run
```

---

## Logs

Errors:

```bash
cleanup.log
```

Installed packages:

```bash
installed_packages.txt
```

---

## Warning

Review packages before removal.

Use at your own risk.
