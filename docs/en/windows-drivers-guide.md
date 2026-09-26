# OneMix 1S+ Windows Drivers & Keyboard Firmware Guide

[简体中文](../windows-drivers-guide.md) | [English](windows-drivers-guide.md)

---

## 1. Hardware Architecture Truth: 1S+ is a "2nd-Gen Core Platform"

The naming convention of One-Netbook UMPCs often confuses first-time users:
* **OneMix 1S (Original / 1st Gen)**: Equipped with an Intel Celeron 3965Y or Atom processor on a 1st-generation platform.
* **OneMix 1S+ (Plus / Upgraded)**: Completely upgraded to the **Intel Core m3-8100Y (Amber Lake-Y platform)**. Its chipset, PCIe routing, thermal curves, and power management are 100% identical to the **OneMix 2 / 2S**!

> [!CAUTION]
> When reinstalling Windows 10 or 11, **never install official drivers marked for "1S 1st Gen"**. Doing so will cause Device Manager exclamation marks, disabled GPU acceleration, missing thermal management, and missing serial bus drivers.

---

## 2. Official 2nd-Gen Full Driver Package (Direct Link)

One-Netbook maintains the full driver archive for 2nd-generation models on their official servers:

* **Official Direct Download**:  
  [`https://download.one-netbook.com/驱动/二代驱动/二代完整驱动包.rar`](https://download.one-netbook.com/驱动/二代驱动/二代完整驱动包.rar)

### Recommended Installation Order:
1. **Intel Chipset Device Software**
2. **Intel Serial IO Driver** (Mandatory for touchscreen and sensors)
3. **Intel Dynamic Platform and Thermal Framework (DPTF / IPF)**
4. **Intel UHD Graphics 615 Driver**
5. **Realtek High Definition Audio Driver**
6. **Intel Wireless-AC 3165 Wi-Fi & Bluetooth Drivers**
7. **FocalTech Fingerprint Driver**

---

## 3. Why Official Keyboard Firmware Must NOT Be Flashed on 1S+

The official 2nd-generation driver package includes a keyboard firmware flasher tool. **Do NOT flash the 2nd-gen keyboard firmware onto the OneMix 1S+!**

* **Root Cause**:
  * While the 1S+ uses a 2nd-gen motherboard, its physical keyboard matrix and internal flex cable routing follow the **1st-gen 1S physical design**.
  * Flashing official 2nd-gen firmware (`FW2 794210`) causes:
    1. Severe shift in top-row number and symbol keys (`Tab` becomes `1`, `1` becomes `2`, `0` becomes `Backspace`, etc.);
    2. The OFN optical mouse coordinates rotate 90 degrees clockwise (swiping left moves the cursor down, swiping right moves it up).
  * If flashing official 1st-gen firmware (`FW1 794202`), the `Fn` and `Left Ctrl` keys are swapped, and hotkeys malfunction.

---

## 4. The Verified Keyboard & OFN Mouse Solution

Use our reverse-engineered and verified custom firmware:

### Flashing Instructions (Windows):
1. Clone or download this repository onto your machine, and navigate to the `firmware/` folder.
2. Run the update tool:
   ```text
   firmware/Hailuck_KeyBoard_Update_Tool_for_68F83.exe
   ```
3. In the dropdown list, select:
   ```text
   OFN_1S+_Perfect_Final.hex
   ```
4. Click **start** and wait for the progress bar to finish and display green **PASS**.
5. Done! Resulting improvements:
   * `Ctrl` and `Fn` keys are correctly mapped and match physical keycaps 100%;
   * All top-row numbers, symbols, and punctuation keys match their printed legends;
   * OFN optical mouse navigation aligns precisely with cursor movement (left/right/up/down);
   * `Fn + Esc` toggles the MCU backlight GPIO pin (P3.1).
