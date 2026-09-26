# OneMix 1S+ Keyboard & OFN Optical Mouse Firmware Directory

[简体中文](README.md) | [English](README_EN.md)

---

This directory contains verified custom firmware and original manufacturer flashing tools for the keyboard and OFN (Optical Finger Navigation) pointing device on the One-Netbook OneMix 1S+.

---

## 1. File Listing

| File | Description | Recommended Usage |
| :--- | :--- | :--- |
| **`OFN_1S+_Perfect_Final.hex`** | **⭐ [Recommended] Verified Custom Firmware** | Fixes swapped Fn/Ctrl, fixes mouse left/right/up/down tracking, matches physical keycaps 100%, preserves `Fn+Esc` backlight toggle. |
| **`Hailuck_KeyBoard_Update_Tool_for_68F83.exe`** | Sinowealth SH68F83 USB ISP Flasher Tool (Windows) | Official GUI tool to flash HEX microcode into the keyboard MCU Flash memory. |
| `originals/OFN_794202_WIN10_US_del_bs.hex` | Official 1st-Gen 1S Factory Firmware (`794202`) | Archive backup. When used on 1S+, Fn and Ctrl are swapped. |
| `originals/OFN_794210_WIN10_US_new_pcb_v06.hex` | Official 2nd-Gen 2/2S Factory Firmware (`794210`) | Archive backup. When used on 1S+, keys are scrambled and mouse rotates 90 degrees. |

---

## 2. Flashing Guide (Windows Quickstart)

1. Double click `Hailuck_KeyBoard_Update_Tool_for_68F83.exe`.
2. Click **start** to begin flashing.
3. When the progress bar completes and displays green **PASS**, flashing is finished!

> [!TIP]
> The firmware is written directly into the keyboard microcontroller's (Sinowealth SH68F83) internal 16KB Flash memory. It survives power cycles, OS reinstalls, and functions permanently under both Windows and Linux!

For deep reverse-engineering details, disassemblies, and key matrix analysis, see the technical document: [docs/en/keyboard-and-ofn-firmware.md](../docs/en/keyboard-and-ofn-firmware.md).
