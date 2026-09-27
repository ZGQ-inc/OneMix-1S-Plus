# OneMix 1S+ Dedicated Optimization & Hardware Fix Toolkit

[简体中文](README.md) | [English](README_EN.md)

---

An open-source repository containing verified reverse-engineered firmware, modern Linux drivers, display & sensor calibrations, and system tuning tools specifically designed for the **One-Netbook OneMix 1S+ (OneMix 1S Plus)** 7.0-inch UMPC convertible laptop.

---

## Table of Contents

- [Hardware Architecture & Specs](#hardware-architecture--specs)
- [Windows Drivers Guide (2nd-Gen Core Truth)](#windows-drivers-guide-2nd-gen-core-truth)
- [Key Features & Fixes](#key-features--fixes)
  - [1. Boot & Screen Rotation (Crucial Prerequisite)](#1-boot--screen-rotation)
  - [2. Gyroscope Auto-Rotation (Bosch BMA2x)](#2-gyroscope-auto-rotation)
  - [3. Keyboard & OFN Optical Mouse Firmware (SH68F83)](#3-keyboard--ofn-mouse-firmware)
  - [4. FocalTech FT9536W (2808:9338) Fingerprint Driver for Modern Linux](#4-focaltech-ft9536w-fingerprint-driver)
  - [5. Intel Core m3-8100Y Power & Thermal Profiles](#5-intel-m3-8100y-power--thermal-tuning)
  - [6. Sleep Mode & Lid Power-Cut Fix (s2idle Modern Standby)](#6-sleep-mode--lid-power-cut-fix-s2idle-modern-standby)
- [Interactive Master CLI (`onemix-tool.sh`)](#interactive-master-cli)
- [Repository Structure](#repository-structure)
- [Disclaimer & License](#disclaimer--license)

---

## Hardware Architecture & Specs

Although named "1S+", the machine's motherboard internally uses the **2nd-generation Intel Core m3-8100Y (Amber Lake-Y) platform**, identical to the OneMix 2 / 2S:

| Component | Hardware Specification | Identifier |
| :--- | :--- | :--- |
| **CPU** | Intel Core m3-8100Y (2C/4T, up to 3.4GHz, 14nm) | `Amber Lake-Y` |
| **GPU** | Intel UHD Graphics 615 (24 EUs) | Integrated |
| **RAM** | 8GB LPDDR3-1866 Dual-Channel | On-board |
| **Storage** | PCIe 3.0 NVMe Solid State Drive | M.2 / BGA |
| **Display** | 7.0" 1920x1200 IPS Touchscreen (Native Portrait Panel) | Interface: `eDP-1` |
| **Keyboard MCU** | Sinowealth SH68F83 (Enhanced 8051 Core) | USB ID: `258a:0021` |
| **Pointing Device**| Hynitron OFN Optical Finger Navigation Sensor | I2C Address: `0x33` |
| **Fingerprint** | FocalTech FT9536W (64x128 resolution) | USB ID: `2808:9338` |
| **Accelerometer** | Bosch Sensortec BMA2x (3-axis) | ACPI ID: `BOSC0200` |
| **Wi-Fi & BT** | Intel Dual Band Wireless-AC 3165 (802.11ac + BT 4.2) | USB ID: `8087:0a2a` |

Detailed hardware architecture & topology: [docs/en/hardware-spec.md](docs/en/hardware-spec.md) ([中文](docs/hardware-spec.md)).

---

## Windows Drivers Guide (2nd-Gen Core Truth)

Because the OneMix 1S+ motherboard is essentially a 2nd-gen platform:
* ❌ **DO NOT install official drivers marked for "OneMix 1S"** (1S 1st-gen was Atom/3965Y);
* ✔ **You MUST install the official OneMix 2nd Generation (OneMix 2/2S) driver suite**!

### Official Driver Package Direct Download:
* 📥 **Direct Link**: [`https://download.one-netbook.com/驱动/二代驱动/二代完整驱动包.rar`](https://download.one-netbook.com/驱动/二代驱动/二代完整驱动包.rar)

> [!WARNING]
> While the official 2nd-gen drivers for chipset, GPU, Wi-Fi, audio, and sensors work out-of-the-box, **DO NOT flash the keyboard firmware included in the official package**! It will shift key mappings and rotate the optical mouse by 90°. For the keyboard and OFN mouse, flash our verified custom firmware `firmware/OFN_1S+_Perfect_Final.hex`. See: [docs/en/windows-drivers-guide.md](docs/en/windows-drivers-guide.md) ([中文](docs/windows-drivers-guide.md)).

---

## Key Features & Fixes

### 1. Boot & Screen Rotation (Including Hardware Rotated GRUB)

The LCD screen is physically a portrait panel (`eDP-1`). This toolkit provides a complete end-to-end landscape experience:
* **Rotated GRUB Bootloader**: Overcomes GNU GRUB's limitation with portrait UEFI GOP panels by applying the Kyle Bader 2D Framebuffer rotation patch. We provide a self-contained, pre-compiled standalone EFI binary (`packages/bootloader/grubx64_rotated.efi`) with 295 built-in modules. Dual-booting Windows and Linux is rendered cleanly in 1920×1200 landscape without touching stock Ubuntu or Windows bootloaders.
* **Plymouth & Console**: Injects `video=eDP-1:panel_orientation=right_side_up fbcon=rotate:1`.
* **SDDM Display Manager**: Synchronizes user space KDE Plasma 6 Wayland configuration (`kwinoutputconfig.json`) and X11 scripts.

> [!IMPORTANT]
> **【MANDATORY PREREQUISITE】**
> Before applying the script to persist the screen rotation, you MUST configure the orientation once in the desktop GUI:
> 1. Open **System Settings -> Display and Monitor**;
> 2. Under **Orientation**, select the 4th option: **Counterclockwise 90° (逆时针转 90°)**;
> 3. Click **Apply**, and verify the screen displays normally in landscape mode.
>
> *Reason: Doing this causes KDE Plasma to generate the valid display descriptor (`~/.config/kwinoutputconfig.json`). Our script will then copy and sync this file to SDDM and inject the correct kernel parameters.*

#### Apply Fix:
```bash
sudo bash scripts/01-setup-screen-rotation.sh
```
*Technical details & safe EFI testing: [docs/en/screen-and-rotation.md](docs/en/screen-and-rotation.md) ([中文](docs/screen-and-rotation.md))*

---

### 2. Gyroscope Auto-Rotation

OneMix 1S+ uses a Bosch BMA2x (`BOSC0200`) accelerometer. Due to physical mounting angles, default Linux drivers produce inverted or 90° phase-shifted orientation.

We provide the precise hardware mounting matrix:
```ini
sensor:modalias:acpi:BOSC0200*:dmi:*
 ACCEL_MOUNT_MATRIX=0, 1, 0; 1, 0, 0; 0, 0, 1
```

#### Apply Fix:
```bash
sudo bash scripts/02-setup-sensor-gyroscope.sh
```
After installation, enable "Automatic screen rotation" in Display Settings to enjoy 360° auto-rotation.
*Technical guide: [docs/en/sensor-calibration.md](docs/en/sensor-calibration.md) ([中文](docs/sensor-calibration.md))*

---

### 3. Keyboard & OFN Mouse Firmware

* **Problem**: 1S+ physically uses the 1S matrix layout with 2nd-gen motherboard integration. Official FW1 inverts Fn and Ctrl keys. Official FW2 scrambles top-row number/symbol keys and rotates the optical mouse 90°.
* **Solution**: Our reverse-engineered firmware [`firmware/OFN_1S+_Perfect_Final.hex`](firmware/OFN_1S+_Perfect_Final.hex) flashed using [`firmware/Hailuck_KeyBoard_Update_Tool_for_68F83.exe`](firmware/Hailuck_KeyBoard_Update_Tool_for_68F83.exe):
  * ✔ Restores exact `Left Ctrl` vs `Fn` physical keycap positions;
  * ✔ Synchronizes mouse pointer movements (up/down/left/right 100% true);
  * ✔ Retains `Fn + Esc` P3.1 GPIO hardware backlight toggling;
  * ✔ Flashed directly into MCU Flash — works permanently on both Linux and Windows.

*Firmware guide & flashing steps: [firmware/README_EN.md](firmware/README_EN.md) and [docs/en/keyboard-and-ofn-firmware.md](docs/en/keyboard-and-ofn-firmware.md) ([中文](docs/keyboard-and-ofn-firmware.md))*

---

### 4. FocalTech FT9536W Fingerprint Driver

On modern Linux distributions (Ubuntu 24.04/26.04), upstream `libfprint` crashes on claim with `NoReply` due to:
1. `LIBGUSB_0.1.0` symbol deprecation in modern `libgusb2a` (resolved via `focaltech-shim.so`);
2. Missing FT9536W chip ID (`0x9536`) in the proprietary algorithm branch, causing a NULL-pointer segfault (resolved via binary patch and NULL guard);
3. Automated `apt-mark hold` to prevent package overwriting.

#### Apply Fix:
```bash
sudo bash scripts/03-install-fingerprint.sh
```
Enroll fingers with `fprintd-enroll` to enable instant fingerprint unlocking for lockscreen, SDDM login, and `sudo` authentication!
*Driver disassembly & fix report: [docs/en/fingerprint-ft9201-driver.md](docs/en/fingerprint-ft9201-driver.md) ([中文](docs/fingerprint-ft9201-driver.md))*

---

### 5. Intel m3-8100Y Power & Thermal Tuning

Switch between customizable TDP / energy-performance-preference (EPP) profiles:
* **Battery / Quiet**: PL1=4.5W, PL2=7W (Silent fan, low heat, long battery life)
* **Balanced (Recommended)**: PL1=7W, PL2=10W (Snappy 3.4GHz turbo burst with good efficiency)
* **Performance**: PL1=9W, PL2=12W (Sustained multi-threaded performance)

#### Apply Tuning:
```bash
sudo bash scripts/04-tune-m3-power-thermal.sh
```

---

### 6. Sleep Mode & Lid Power-Cut Fix (s2idle Modern Standby)

* **Symptom**: Closing the lid or clicking suspend results in an **abrupt hard power-cut / shutdown ~3 seconds later** (power LED turns off, machine is unresponsive to keypresses, requiring a cold power-button boot).
* **Root Cause**: The OneMix 1S+ Intel Core m3-8100Y (Amber Lake-Y) motherboard power rails and Embedded Controller (EC) are architected for Microsoft "Modern Standby" (S0ix / `s2idle`). The Linux kernel default of traditional ACPI S3 `[deep]` sleep drops main power planes without the expected S0ix handshake. The EC hardware watchdog detects this power drop, times out after ~3 seconds, and triggers an emergency hard power-off.
* **Solution**:
  1. Permanently switch Linux sleep mode to hardware-native **`s2idle` (Suspend-to-Idle)** via `/etc/systemd/sleep.conf.d/` and GRUB parameter `mem_sleep_default=s2idle`, eliminating the power-cut bug;
  2. Customize lid-close policy for 7-inch UMPC form factor: choose between [Ignore / Lock Screen] (ideal for background downloads, SSH/RustDesk remote access, audio playback, or 360° tablet flip mode) or [Safe Suspend] (enters smooth s2idle sleep).

#### Run One-Click Configuration:
```bash
sudo bash scripts/05-setup-power-and-sleep.sh
```

---

## Interactive Master CLI

Launch the interactive management terminal:
```bash
sudo bash scripts/onemix-tool.sh
```

Run hardware diagnostic report:
```bash
bash scripts/onemix-hardware-diagnose.sh
```

---

## Repository Structure

```text
OneMix-1S-Plus/
├── .gitattributes                        # Git line-ending (LF) & binary attributes
├── .github/                              # GitHub Actions CI & Issue/PR Forms
│   ├── ISSUE_TEMPLATE/                   # Modern structured issue forms (YAML)
│   │   ├── config.yml
│   │   ├── bug_report.yml
│   │   └── feature_request.yml
│   ├── PULL_REQUEST_TEMPLATE/            # Standardized multi-scenario PR templates
│   │   ├── pull_request_template.md      # Default comprehensive PR template
│   │   ├── bug_fix.md                    # Bug fix specialized template
│   │   └── feature.md                    # Feature / tuning specialized template
│   └── workflows/
│       └── shellcheck.yml                # ShellCheck syntax workflow
├── docs/                                 # Technical reverse-engineering docs (Bilingual)
│   ├── en/                               # English Technical Documentation
│   │   ├── hardware-spec.md
│   │   ├── screen-and-rotation.md
│   │   ├── sensor-calibration.md
│   │   ├── keyboard-and-ofn-firmware.md
│   │   ├── fingerprint-ft9201-driver.md
│   │   └── windows-drivers-guide.md
│   ├── hardware-spec.md                  # Chinese Technical Documentation
│   ├── screen-and-rotation.md
│   ├── sensor-calibration.md
│   ├── keyboard-and-ofn-firmware.md
│   ├── fingerprint-ft9201-driver.md
│   └── windows-drivers-guide.md
├── firmware/                             # Keyboard & OFN firmware
│   ├── README.md                         # Firmware guide (Chinese)
│   ├── README_EN.md                      # Firmware guide (English)
│   ├── OFN_1S+_Perfect_Final.hex         # Verified perfect firmware
│   ├── Hailuck_KeyBoard_Update_Tool_for_68F83.exe  # Flasher tool (Windows)
│   └── originals/                        # Original firmware archive
├── packages/                             # Prebuilt deb packages & shims
│   ├── bootloader/                       # Hardware rotated GRUB standalone EFI & tools
│   │   ├── grubx64_rotated.efi           # Prebuilt standalone 2D rotated EFI
│   │   ├── 0001-grub-framebuffer-rotation.patch  # Kyle Bader source patch
│   │   └── install-rotated-grub.sh       # Non-destructive EFI installer
│   └── fingerprint/                      # Custom libfprint-2-2 deb & installer
├── scripts/                              # Linux automation scripts
│   ├── onemix-tool.sh                    # Interactive Master CLI
│   ├── 01-setup-screen-rotation.sh       # Screen rotation setup
│   ├── 02-setup-sensor-gyroscope.sh      # Gyroscope calibration
│   ├── 03-install-fingerprint.sh         # Fingerprint driver installer
│   ├── 04-tune-m3-power-thermal.sh       # Intel m3-8100Y power tuning
│   └── onemix-hardware-diagnose.sh       # Hardware diagnostic script
├── src/                                  # C source code & Makefiles
│   └── focaltech-shim/                   # libgusb compatibility shim
├── LICENSE                               # MIT License
├── README.md                             # Chinese Documentation
└── README_EN.md                          # English Documentation
```

---

## 🔗 References & Acknowledgements

During the development, reverse-engineering, and hardware optimization of this project, we drew valuable inspiration and technical foundations from the open-source community and UMPC pioneers:

* **GNU GRUB 2D Framebuffer Rotation Engine**:
  * [Rotating display output from GRUB](https://hackaday.io/project/203272-rotating-display-output-from-grub): For developing the robust 2D framebuffer rotation patch that makes landscape boot menus possible on portrait-native UMPC panels.
  * [GNU GRUB Official Project](https://www.gnu.org/software/grub/)
* **Accelerometer & IIO Sensor Calibration**:
  * [systemd / udev Hardware Database (hwdb)](https://github.com/systemd/systemd): Specification and coordinate mapping standards for `ACCEL_MOUNT_MATRIX`.
  * [iio-sensor-proxy (Freedesktop)](https://gitlab.freedesktop.org/hadess/iio-sensor-proxy): D-Bus proxy bridging Linux Industrial I/O sensor events to KDE Plasma and GNOME desktop environments.
* **Fingerprint Sensor & Driver Reverse-Engineering**:
  * [libfprint / fprintd (Freedesktop)](https://gitlab.freedesktop.org/libfprint/libfprint): Modern Linux biometric authentication framework and TOD interface specifications.
  * [libgusb](https://github.com/hughsie/libgusb): GLib async GObject USB wrapper library.
  * [Community FT9201 Reverse-Engineering Contributors (ryenyuku/libfprint-ft9201)](https://github.com/ryenyuku/libfprint-ft9201): For their pioneering protocol analysis and driver work on FocalTech 2808 devices under Linux.
* **Power Management & Thermal Tuning**:
  * [georgewhewell/undervolt](https://github.com/georgewhewell/undervolt): Reference for Intel CPU RAPL package power clamping and voltage control under Linux.
  * [Linux Kernel DRM KMS Documentation](https://www.kernel.org/doc/html/latest/gpu/drm-kms.html): Display panel orientation specifications (`video=...:panel_orientation=...`).
* **Vendor Resources & Firmware**:
  * [One-Netbook Official](https://www.one-netbook.com/) & [Download Server](https://download.one-netbook.com/): Official 2nd-generation driver packages.
  * [Sino Wealth](https://www.sinowealth.com/) & [Hailuck](http://www.hailuck.com/): SH68F83 8051-core USB Flash Microcontroller specifications and firmware updating tool.

---

## Disclaimer & License

* This repository contains reverse-engineering research and patches intended for device maintenance, academic study, and personal use.
* All code and documentation are released under the [MIT License](LICENSE).
