# OneMix 1S+ 键盘与 OFN 光学触控板固件目录

[简体中文](README.md) | [English](README_EN.md)

---

本目录包含针对壹号本 OneMix 1S+ 的键盘与 OFN (Optical Finger Navigation) 光学指点杆鼠标的专属修复固件及原厂工具。

---

## 一、 文件清单

| 文件名 | 说明 | 适用场景 |
| :--- | :--- | :--- |
| **`OFN_1S+_Perfect_Final.hex`** | **⭐【推荐刷写】完美修复版固件** | 纠正 Fn/Ctrl 互反、纠正触控板左右/上下方向、匹配物理键帽、支持 Fn+Esc 背光 |
| **`Hailuck_KeyBoard_Update_Tool_for_68F83.exe`** | 中颖 SH68F83 官方 USB 固件刷写工具 (Windows) | 在 Windows 下扫描 HEX 固件并一键烧录至单片机 Flash |
| `originals/OFN_794202_WIN10_US_del_bs.hex` | 官方一代 1S 原厂固件 (`794202`) | 备份归档。在 1S+ 上使用时 Fn 与 Ctrl 颠倒 |
| `originals/OFN_794210_WIN10_US_new_pcb_v06.hex` | 官方二代 2/2S 原厂固件 (`794210`) | 备份归档。在 1S+ 上使用时键位错乱且触控板旋转 90 度 |

---

## 二、 刷写方法 (Windows 快速上手)

1. 双击运行 `Hailuck_KeyBoard_Update_Tool_for_68F83.exe`。
2. 点击 **start** 开始刷写。
3. 进度条跑完显示 **PASS** 即表示刷写完成。

> [!TIP]
> 固件直接烧录至键盘主控 MCU（中颖 SH68F83）内部的 16KB Flash 存储区，断电或重装系统不丢失。无论后续使用 Windows 还是 Linux，均终身生效！

详细逆向分析与按键矩阵说明请参阅技术文档：[docs/keyboard-and-ofn-firmware.md](../docs/keyboard-and-ofn-firmware.md)。
