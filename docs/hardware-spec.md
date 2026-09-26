# OneMix 1S+ 详细硬件规格与总线拓扑 (Hardware Specification)

[简体中文](hardware-spec.md) | [English](en/hardware-spec.md)

---

虽然其型号命名延续了“1S”，但其内部核心硬件架构经过了全方位升级，实际上采用了与**壹号本二代 (OneMix 2/2S)** 相同的高性能低功耗酷睿平台。

---

## 一、 核心硬件配置清单

| 核心组件 | 硬件型号 / 芯片方案 | 规格参数 | 总线 / 接口 | 驱动状态 (Linux) |
| :--- | :--- | :--- | :--- | :--- |
| **处理器 (CPU)** | Intel Core m3-8100Y | 2核/4线程, 1.10~3.40 GHz, 14nm Amber Lake-Y | LGA 整合封装 | 内核原生免驱 |
| **显卡 (GPU)** | Intel UHD Graphics 615 | 24 Execution Units (EU), 最大 900 MHz | PCIe / 核显 | i915 内核原生免驱 |
| **内存 (RAM)** | 8GB LPDDR3-1866 | 双通道板载颗粒 | 内存总线 | 原生支持 |
| **固态硬盘 (SSD)** | PCIe NVMe 固态硬盘 | 128GB / 256GB / 512GB (BGA/M.2) | PCIe 3.0 x2/x4 (NVMe) | 内核原生免驱 |
| **显示屏幕** | 7.0 英寸 IPS 视网膜屏 | 1920 × 1200 分辨率, 324 PPI, 原生物理竖屏 | `eDP-1` (嵌入式 DP) | 需配置旋转参数 |
| **触控与手写** | 10点电容触控 + 2048级压感笔 | 适配 Surface Pen / 壹号本原厂手写笔 | I2C HID | 内核 HID 免驱 |
| **键盘主控 (MCU)**| 中颖 Sinowealth SH68F83 | 增强型 8051 内核, 内置 16KB Flash | USB (`258a:0021`) | 建议刷写本库固件 |
| **触控指点杆 (OFN)**| 海栎创 Hynitron OFN 光学传感器 | 光学手指导航触控板, I2C 地址 `0x33` | I2C (经由键盘 MCU 桥接) | 键盘固件管理 |
| **指纹传感器** | 敦泰 / 迈瑞微 FocalTech FT9536W | 64 × 128 分辨率, 电容式按压传感器 | USB (`2808:9338`) | 需本仓库定制驱动 |
| **重力感应器** | 博世 Bosch Sensortec BMA2x | 3轴加速度计 (ACPI ID: `BOSC0200`) | I2C / ACPI 总线 | 需本仓库 hwdb 矩阵校准 |
| **无线网卡** | Intel Dual Band Wireless-AC 3165 | 802.11ac 1x1 Wi-Fi (最高 433 Mbps) | PCIe / M.2 | `iwlwifi` 原生免驱 |
| **蓝牙模块** | Intel Wireless-AC 3165 Bluetooth | 蓝牙 4.2 LE 规范 | USB (`8087:0a2a`) | `btusb` 原生免驱 |
| **电池容量** | 6500 mAh (3.7V) / 约 24.05 Wh | 支持 5V/9V/12V PD 快充 | 智能电池总线 | 内核 ACPI 原生支持 |

---

## 二、 关键总线拓扑与设备识别

### 1. USB 设备树 (`lsusb`)
```text
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 001 Device 002: ID 258a:0021 HAILUCK CO.,LTD USB KEYBOARD (键盘+OFN鼠标主控)
Bus 001 Device 003: ID 8087:0a2a Intel Corp. Bluetooth wireless interface (蓝牙)
Bus 001 Device 004: ID 2808:9338 Focal-systems.Corp FT9201Fingerprint (指纹传感器)
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
```

### 2. ACPI / I2C 传感器设备
```text
/sys/bus/acpi/devices/BOSC0200:00 (Bosch BMA250 / BMA2x 加速度传感器)
```

### 3. 显示接口
```text
/sys/class/drm/card0-eDP-1 (Intel Gen9 核显嵌入式 DisplayPort)
```

---

## 三、 Windows 官方驱动说明

由于 OneMix 1S+ 本质上是二代主板（Intel Core m3-8100Y 平台），**在 Windows 系统下切勿安装一代 (Atom / 3965Y) 的驱动程序**，否则会导致芯片组与显卡不兼容。

- **官方二代完整驱动包直链下载**：  
  [`https://download.one-netbook.com/驱动/二代驱动/二代完整驱动包.rar`](https://download.one-netbook.com/驱动/二代驱动/二代完整驱动包.rar)
- 驱动包中包含了主板芯片组、集成显卡、音频、无线网卡、蓝牙、串行 IO 和指纹驱动。
- **唯一例外**：键盘与 OFN 光学触控板固件请使用本仓库 `firmware/` 目录下的专用修复固件 `OFN_1S+_Perfect_Final.hex`。
