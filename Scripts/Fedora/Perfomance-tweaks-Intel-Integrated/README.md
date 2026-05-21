# Fedora + CachyOS Performance Setup

High-performance Fedora optimization scripts using the CachyOS kernel, sched-ext schedulers, CPU tuning, zram optimization, and low-latency system tweaks.

## Overview

This repository provides two automation scripts for turning a standard Fedora installation into a highly optimized performance-focused system using:

* CachyOS kernel
* sched-ext schedulers (`scx_rusty` / `scx_lavd`)
* CPU governor tuning
* Tuned performance profiles
* Ananicy process optimization
* zram enhancements
* I/O scheduler tweaks
* GRUB performance parameters

Tested on:

* Fedora 44+
* UEFI and BIOS systems

---

# Scripts

## `kernel-p.sh`

A lightweight installer focused on:

* Installing the CachyOS kernel
* Enabling sched-ext support
* Configuring `scx_rusty`
* Setting up `ananicy-cpp`
* Applying tuned performance profile

### Features

* Enables CachyOS COPRs
* Installs:

  * `kernel-cachyos`
  * `scx-scheds`
  * `scx-tools`
  * `ananicy-cpp`
  * `tuned`
* Configures:

  * `scx_rusty`
  * `throughput-performance`
* Regenerates GRUB automatically

### Usage

```bash
chmod +x kernel-p.sh
sudo bash kernel-p.sh
```

---

## `power.sh`

An advanced "ultimate performance" setup script with aggressive system optimization.

### Features

Includes everything from `kernel-p.sh` plus:

* CPU governor tuning
* zram optimization
* I/O scheduler rules
* Transparent Huge Pages tuning
* Kernel boot parameter tweaks
* `cpupower`
* `latency-performance` tuned profile
* `scx_lavd` scheduler

### Additional Optimizations

#### CPU Performance Governor

Sets:

```bash
performance
```

for maximum responsiveness.

#### zram Configuration

Creates compressed RAM swap using:

* `zstd`
* 2× RAM allocation

#### I/O Scheduler Tweaks

Applies:

* `none` for NVMe
* `mq-deadline` for SATA drives

#### GRUB Performance Parameters

Adds:

```bash
preempt=full mitigations=off nowatchdog transparent_hugepage=always
```

---

## Usage

```bash
chmod +x power.sh
sudo bash power.sh
```

---

# Installed Components

| Component      | Purpose                                 |
| -------------- | --------------------------------------- |
| CachyOS Kernel | Performance-optimized Linux kernel      |
| sched-ext      | Experimental scheduler framework        |
| scx_rusty      | Balanced sched-ext scheduler            |
| scx_lavd       | Low-latency sched-ext scheduler         |
| ananicy-cpp    | Automatic process priority optimization |
| tuned          | System tuning profiles                  |
| cpupower       | CPU frequency management                |
| zram-generator | Compressed RAM swap                     |

---

# Verification

After reboot, verify everything is active.

## Check Kernel

```bash
uname -r
```

Expected output:

```bash
6.x.x-cachyos
```

---

## Check sched-ext Support

```bash
zcat /proc/config.gz | grep SCHED_CLASS_EXT
```

---

## Check Active Scheduler

```bash
systemctl status scx.service
```

---

## Check CPU Governor

```bash
cpupower frequency-info
```

---

## Check Transparent Huge Pages

```bash
cat /sys/kernel/mm/transparent_hugepage/enabled
```

---

# Switching Schedulers

Try alternative schedulers manually:

```bash
sudo scx_lavd
```

or

```bash
sudo scx_rusty
```

---

# Notes

* These scripts are designed for performance-first systems.
* `mitigations=off` disables some CPU security mitigations for lower latency and higher performance.
* sched-ext is experimental and may not be stable on all hardware.
* Recommended for gaming, workstation, and low-latency desktop setups.

---

# Reboot

After installation:

```bash
sudo reboot
```

---

# Disclaimer

Use at your own risk.

These scripts modify:

* Kernel packages
* GRUB configuration
* CPU tuning
* System services
* Scheduler behavior

Always keep backups or snapshots before applying system-level performance tweaks.

---

# License

MIT License
