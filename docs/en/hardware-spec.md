# OneMix 1S+ Hardware Specifications & Bus Topology

[简体中文](../hardware-spec.md) | [English](hardware-spec.md)

---

The **One-Netbook OneMix 1S+ (OneMix 1S Plus)** is a 7.0-inch pocket-sized convertible UMPC (Ultra-Mobile PC) featuring a 360-degree yoga hinge and touchscreen.

Although its marketing name inherits the "1S" branding from the original 1st-generation model, **its internal hardware platform was completely overhauled to the 2nd-generation Intel Core m3-8100Y platform**, sharing identical motherboard architecture, chipset, and power management with the **OneMix 2 / 2S**.

---

## 1. Hardware Configuration Summary

| Component | Chipset / Controller | Technical Specifications | Bus / Interface | Linux Driver Status |
| :--- | :--- | :--- | :--- | :--- |
| **Processor (CPU)** | Intel Core m3-8100Y | 2 Cores / 4 Threads, 1.10~3.40 GHz, 14nm Amber Lake-Y | Integrated BGA | Native kernel support |
| **Graphics (GPU)** | Intel UHD Graphics 615 | 24 Execution Units (EUs), up to 900 MHz | Integrated / PCIe | Native `i915` kernel driver |
| **Memory (RAM)** | 8GB LPDDR3-1866 | Dual-channel on-board LPDDR3 | Memory Bus | Native kernel support |
| **Storage (SSD)** | PCIe NVMe Solid State Drive | 128GB / 256GB / 512GB (M.2 / BGA) | PCIe 3.0 x2/x4 (NVMe) | Native kernel support |
| **Display Panel** | 7.0" Retina IPS LCD | 1920 × 1200 resolution, 324 PPI, Native Portrait | `eDP-1` (Embedded DP) | Requires rotation parameters |
| **Touchscreen & Pen** | 10-point capacitive + 2048-level stylus | Compatible with Surface Pen / OneMix Active Stylus | I2C HID | Native kernel HID driver |
| **Keyboard MCU** | Sinowealth SH68F83 | Enhanced 8051 core, integrated 16KB Flash | USB (`258a:0021`) | Use custom firmware in `firmware/` |
| **Pointing Device**| Hynitron OFN Optical Sensor | Optical Finger Navigation, I2C address `0x33` | I2C (via keyboard MCU bridge) | Handled by keyboard MCU firmware |
| **Fingerprint** | FocalTech FT9536W | 64 × 128 pixels capacitive touch sensor | USB (`2808:9338`) | Requires custom `libfprint` in `packages/` |
| **Accelerometer** | Bosch Sensortec BMA2x | 3-axis accelerometer (ACPI ID: `BOSC0200`) | I2C / ACPI | Requires hwdb matrix calibration |
| **Wi-Fi Card** | Intel Dual Band Wireless-AC 3165 | 802.11ac 1x1 Wi-Fi (up to 433 Mbps) | PCIe / M.2 | Native `iwlwifi` kernel driver |
| **Bluetooth** | Intel Wireless-AC 3165 Bluetooth | Bluetooth 4.2 LE specification | USB (`8087:0a2a`) | Native `btusb` kernel driver |
| **Battery** | 6500 mAh (3.7V) / ~24.05 Wh | Supports 5V / 9V / 12V USB Power Delivery (PD) | Smart Battery Bus | Native ACPI kernel support |

---

## 2. Bus Topology & Device Identification

### 1. USB Bus Tree (`lsusb`)
```text
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 001 Device 002: ID 258a:0021 HAILUCK CO.,LTD USB KEYBOARD (Keyboard + OFN Mouse Controller)
Bus 001 Device 003: ID 8087:0a2a Intel Corp. Bluetooth wireless interface (Bluetooth)
Bus 001 Device 004: ID 2808:9338 Focal-systems.Corp FT9201Fingerprint (Fingerprint Sensor)
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
```

### 2. ACPI / I2C Sensor Device
```text
/sys/bus/acpi/devices/BOSC0200:00 (Bosch BMA250 / BMA2x Accelerometer)
```

### 3. Display Interface
```text
/sys/class/drm/card0-eDP-1 (Intel Gen9 Integrated Graphics Embedded DisplayPort)
```

---

## 3. Windows Drivers Notice

Because the OneMix 1S+ motherboard is essentially a 2nd-generation Intel Core m3-8100Y platform, **never install 1st-generation (Atom / 3965Y) drivers on Windows**, as they will result in missing devices and driver incompatibilities.

- **Official 2nd-Gen Full Driver Package (Direct Link)**:  
  [`https://download.one-netbook.com/驱动/二代驱动/二代完整驱动包.rar`](https://download.one-netbook.com/驱动/二代驱动/二代完整驱动包.rar)
- This package includes drivers for Chipset, Graphics, Audio, Wi-Fi, Bluetooth, Serial IO, and Fingerprint.
- **Critical Exception**: For the keyboard and OFN mouse, do NOT flash the keyboard firmware included in the official package. Use our reverse-engineered firmware `firmware/OFN_1S+_Perfect_Final.hex`.
