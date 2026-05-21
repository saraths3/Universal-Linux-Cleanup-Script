# Fedora Cleanup Script

Cleanup utility for Fedora and RPM-based Linux distributions.

Supports:
- Fedora
- Nobara
- Rocky Linux
- AlmaLinux
- RHEL

## Features

- Remove common bloat packages
- DNF autoremove
- Cache cleanup
- Trash cleanup
- Journal cleanup
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
