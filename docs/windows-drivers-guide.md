# OneMix 1S+ Windows 驱动安装与键盘固件避坑全指南

[简体中文](windows-drivers-guide.md) | [English](en/windows-drivers-guide.md)

---

壹号本（One-Netbook）的机型命名容易让初次接触的用户产生误解：
* **OneMix 1S 原版**：搭载低功耗 Intel Celeron 3965Y 或 Atom 系列，主板外围总线设计为一代架构。
* **OneMix 1S+ (升级版)**：主板架构全面升级为 **Intel Core m3-8100Y（Amber Lake-Y 平台）**，其主板芯片组、PCIe 通道、电源管理方案与 **壹号本二代 (OneMix 2 / 2S)** 保持完全一致！

> [!CAUTION]
> 在重装 Windows 系统时，**绝对不要安装官方网站上标为“1S 一代”的驱动**，否则会出现大量设备管理器感叹号、显卡无法加载硬件加速、芯片组功能缺失等严重问题！

---

## 二、 官方二代完整驱动包 (直链高速下载)

壹号本官方服务器保留了完整的二代硬件驱动归档包，包含芯片组、显卡、声卡、无线网卡、蓝牙、串行 IO 和指纹驱动：

* **官方直链下载**：  
  [`https://download.one-netbook.com/驱动/二代驱动/二代完整驱动包.rar`](https://download.one-netbook.com/驱动/二代驱动/二代完整驱动包.rar)

### 推荐安装顺序：
1. **主板芯片组驱动 (Intel Chipset Device Software)**
2. **英特尔串行 IO 驱动 (Intel Serial IO Driver)**（触控屏与传感器底层依赖）
3. **动态调优与能耗驱动 (Intel DPTF / IPF)**
4. **集成显卡驱动 (Intel UHD Graphics 615 Driver)**
5. **高清音频驱动 (Realtek High Definition Audio Driver)**
6. **无线网卡与蓝牙驱动 (Intel Wireless-AC 3165 Wi-Fi & BT)**
7. **指纹识别驱动 (FocalTech Fingerprint Driver)**

---

## 三、 为什么官方二代驱动包里的键盘固件不能用？

在官方二代驱动包中，附带了键盘固件刷写程序。**但在 1S+ 上切勿直接刷写二代原厂固件！**

* **原因**：
  * OneMix 1S+ 虽然采用了二代主板，但其外部键盘物理结构和内部按键走线沿用了 1S 的矩阵。
  * 刷写二代固件会导致：
    1. 键盘顶部数字与符号键严重平移（Tab 变成 1，1 变成 2，0 变成退格，退格变成删除等）；
    2. 触控板触控板坐标轴顺时针旋转 90 度（向左滑变成向下，向右滑变成向上）。
  * 若刷写一代 1S 固件，则键盘 `Fn` 与 `Ctrl` 物理键位颠倒，且快捷键失灵。

---

## 四、 键盘与 OFN 触控板终极解决方案

必须且只需刷写本仓库专门针对 1S+ 逆向修复并验证的定制固件：

### 刷写步骤：
1. 下载或克隆本仓库到设备，进入 `firmware/` 目录。
2. 运行刷写工具：
   ```text
   firmware/Hailuck_KeyBoard_Update_Tool_for_68F83.exe
   ```
3. 在工具窗口的固件下拉列表中选择：
   ```text
   OFN_1S+_Perfect_Final.hex
   ```
4. 点击 **start** 按钮，等待进度条满格并显示绿色 **PASS**。
5. 刷写完成！此时：
   * `Ctrl` 与 `Fn` 键位完全恢复正常；
   * 所有按键与键帽物理印刷 100% 对应；
   * 触控板上下左右方向精准对齐；
   * `Fn + Esc` 正常响应单片机背光引脚翻转。
