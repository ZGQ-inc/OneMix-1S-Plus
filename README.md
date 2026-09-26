# OneMix 1S+ 专属优化与避坑工具箱 (OneMix-1S-Plus Toolkit)

[简体中文](README.md) | [English](README_EN.md)

---

本仓库是针对 **壹号本 OneMix 1S+ (One-Netbook OneMix 1S Plus)** 超便携笔记本 (UMPC) 的开源优化方案、定制固件、现代 Linux 驱动及避坑工具集合。

针对 1S+ 在日常使用中遇到的 **屏幕物理竖屏开机旋转错位**、**重力感应方向颠倒**、**键盘 Fn/Ctrl 颠倒与光学触控板镜像**、**现代 Linux 下指纹驱动崩溃** 等问题，提供了经过底层反汇编逆向与真机实测的完整修复。

---

## 目录

- [硬件本质与规格](#-硬件本质与规格)
- [Windows 驱动指南 (二代内核真相)](#-windows-驱动指南-二代内核真相)
- [核心优化功能与解决方案](#-核心优化功能与解决方案)
  - [1. 屏幕开机全链路横屏修复 (含关键操作前提)](#1-屏幕开机全链路横屏修复)
  - [2. 重力感应校准与自动旋转 (Bosch BMA2x)](#2-重力感应校准与自动旋转)
  - [3. 键盘与 OFN 触控板专属修复固件 (SH68F83)](#3-键盘与-ofn-光学触控板修复固件)
  - [4. FocalTech FT9536W (2808:9338) Linux 现代指纹驱动](#4-focaltech-ft9536w-指纹驱动)
  - [5. Intel Core m3-8100Y 功耗与温控优化](#5-intel-core-m3-8100y-功耗与温控优化)
- [Linux 一键综合管理工具 (`onemix-tool.sh`)](#-linux-一键综合管理工具)
- [仓库目录结构](#-仓库目录结构)
- [免责声明与许可证](#-免责声明与许可证)

---

## 🔍 硬件本质与规格

OneMix 1S+ 虽然外壳沿用了 1S 的模具，但**其主板内核实际上升级为了与壹号本二代 (OneMix 2/2S) 完全一致的 Intel Core m3-8100Y 平台**：

| 组件 | 详细硬件规格 | 识别标识 |
| :--- | :--- | :--- |
| **处理器 (CPU)** | Intel Core m3-8100Y (2核4线程, 3.4GHz 睿频, 14nm) | `Amber Lake-Y` |
| **显卡 (GPU)** | Intel UHD Graphics 615 (24 EU) | 核显 |
| **内存 (RAM)** | 8GB LPDDR3-1866 双通道 | 板载 |
| **固态硬盘 (SSD)** | PCIe 3.0 NVMe 固态硬盘 | M.2 / BGA |
| **屏幕 (Display)**| 7.0 英寸 1920×1200 IPS 视网膜电容触控屏 (原生物理竖屏) | 内部接口: `eDP-1` |
| **键盘控制器 (MCU)**| 中颖 Sinowealth SH68F83 (增强型 8051 内核) | USB ID: `258a:0021` |
| **光学指点杆 (OFN)**| 海栎创 Hynitron OFN 光学手指导航芯片 | I2C 地址: `0x33` |
| **指纹传感器** | 敦泰 / 迈瑞微 FocalTech FT9536W (64×128 像素) | USB ID: `2808:9338` |
| **重力感应器** | 博世 Bosch Sensortec BMA2x 加速度传感器 | ACPI ID: `BOSC0200` |
| **无线与蓝牙** | Intel Dual Band Wireless-AC 3165 (802.11ac + BT 4.2) | USB ID: `8087:0a2a` |

详细拓扑结构请参阅：[docs/hardware-spec.md](docs/hardware-spec.md)。

---

## 🪟 Windows 驱动指南 (二代内核真相)

由于 1S+ 的核心硬件是二代平台，在安装 Windows 10/11 驱动时：
* ❌ **切勿安装官方一代 1S 的驱动**（一代为 Atom/3965Y 架构，驱动完全不匹配）；
* ✔ **必须安装壹号本官方二代 (OneMix 2/2S) 完整驱动包**！

### 官方二代驱动包高速下载：
* 📥 **官方直链**：[`https://download.one-netbook.com/驱动/二代驱动/二代完整驱动包.rar`](https://download.one-netbook.com/驱动/二代驱动/二代完整驱动包.rar)

> [!WARNING]
> 官方驱动包中的所有外围驱动（主板芯片组、显卡、声卡、网卡、指纹等）均完美适用，**但请勿刷写官方驱动包自带的键盘固件**！官方二代键盘固件会导致 1S+ 数字键错乱且触控点旋转 90 度。键盘固件请务必使用本仓库提供的专属固件。详见：[docs/windows-drivers-guide.md](docs/windows-drivers-guide.md)。

---

## 🚀 核心优化功能与解决方案

### 1. 屏幕开机全链路横屏修复 (含硬件级 GRUB 旋转)

OneMix 1S+ 的液晶面板物理扫描方向为竖屏 (`eDP-1`)。本仓库提供从通电开机到桌面进入的**真正全链路横屏方案**：
* **硬件级横屏 GRUB 引导器**：突破 GNU GRUB 缺乏 GOP 旋转的限制，集成 Kyle Bader 2D Framebuffer 补丁并预编译自包含独立 EFI (`packages/bootloader/grubx64_rotated.efi`)。开机引导菜单即为 1920×1200 正向横屏，100% 不破坏原机 Ubuntu 与 Windows 双系统引导。
* **Plymouth 开机动画与控制台**：注入内核参数 `video=eDP-1:panel_orientation=right_side_up fbcon=rotate:1`。
* **登录管理器 (SDDM)**：同步桌面旋转配置文件至 SDDM 运行空间。

> [!IMPORTANT]
> **【重要前提操作】**  
> 在运行脚本将配置固化至系统之前，用户必须先在桌面图形界面完成一次手动设置：
> 1. 打开桌面 **【系统设置 (System Settings)】 -> 【显示和监视器 (Display and Monitor)】**；
> 2. 在 **【方向 (Orientation)】** 下拉菜单中，**手动选择第 4 个选项：【逆时针转 90° (Counterclockwise 90°)】**；
> 3. 点击右下角 **【应用 (Apply)】**，确认此时桌面显示方向完全正常（正向横屏）。
> 
> *原因：只有完成此步，KDE Plasma 才会生成正确的当前用户屏幕配置 (`~/.config/kwinoutputconfig.json`)。随后执行脚本方能正确同步给 SDDM 登录器与内核引导参数！*

#### 执行一键配置：
```bash
sudo bash scripts/01-setup-screen-rotation.sh
```
*技术原理与安全测试指南：[docs/screen-and-rotation.md](docs/screen-and-rotation.md)*

---

### 2. 重力感应校准与自动旋转

OneMix 1S+ 搭载 Bosch BMA2x (`BOSC0200`) 重力传感器。Linux 原生驱动因主板贴片引脚相位偏差，会导致左右颠倒或 90 度倒置。

通过部署经过几何推导的硬件安装矩阵：
```ini
sensor:modalias:acpi:BOSC0200*:dmi:*
 ACCEL_MOUNT_MATRIX=0, 1, 0; 1, 0, 0; 0, 0, 1
```

#### 执行一键配置：
```bash
sudo bash scripts/02-setup-sensor-gyroscope.sh
```
配置完成后，在系统设置中开启“根据方向传感器自动旋转”，即可实现 360 度四向姿态精准自适应。  
*技术原理详解：[docs/sensor-calibration.md](docs/sensor-calibration.md)*

---

### 3. 键盘与 OFN 光学触控板修复固件

* **问题背景**：1S+ 物理键盘走线是一代矩阵，但搭配二代主板。官方 FW1 存在 `Fn` 与 `Left Ctrl` 键位互反；官方 FW2 则导致按键平移错位（Tab 变 1，0 变退格）且触控板旋转 90 度。
* **终极固件**：本仓库提供逆向反汇编修正后的最终固件：
  * 📁 **固件路径**：[`firmware/OFN_1S+_Perfect_Final.hex`](firmware/OFN_1S+_Perfect_Final.hex)
  * 🛠 **刷写工具**：[`firmware/Hailuck_KeyBoard_Update_Tool_for_68F83.exe`](firmware/Hailuck_KeyBoard_Update_Tool_for_68F83.exe)
* **修复效果**：
  * ✔ `Ctrl` 与 `Fn` 键位完全归位，与物理键帽印刷 100% 对应；
  * ✔ 触控板上下左右方向精准同步鼠标指针；
  * ✔ 原生支持 `Fn + Esc` 切换单片机 P3.1 引脚背光状态；
  * ✔ 一次刷入单片机 Flash，跨系统终身生效！

*逆向分析与刷写步骤：[docs/keyboard-and-ofn-firmware.md](docs/keyboard-and-ofn-firmware.md)*

---

### 4. FocalTech FT9536W 指纹驱动

在 Ubuntu 24.04 / 26.04 / Kubuntu 26.04 等现代 Linux 发行版中，官方驱动在调用 `fprintd-enroll` 时会报 `NoReply` 崩溃。本仓库彻底定位并解决了此问题：
1. **符号层 Shim (`focaltech-shim.so`)**：桥接现代 `libgusb2a` 缺少的 `LIBGUSB_0.1.0` 符号；
2. **芯片 ID 算法映射与空指针修复**：修补闭源特征算法库，将 FT9536W (类型 7) 映射至 64×128 比对算法分支，并注入空指针防护杜绝 `SIGSEGV`。
3. **防覆盖锁定**：安装后自动执行 `apt-mark hold`。

#### 执行一键安装：
```bash
sudo bash scripts/03-install-fingerprint.sh
```
安装后直接运行 `fprintd-enroll` 录入指纹，即可在锁屏、开机登录及终端 `sudo` 提权时享受刷指纹秒进体验！  
*逆向报告与 C 源码：[docs/fingerprint-ft9201-driver.md](docs/fingerprint-ft9201-driver.md) 与 [src/focaltech-shim/](src/focaltech-shim/)*

---

### 5. Intel Core m3-8100Y 功耗与温控优化

m3-8100Y 在轻薄 7 寸机身内默认功耗释放较为保守。通过调节 Intel RAPL 能耗墙与调频偏好，可在不同场景下自如切换：
* **省电静音模式 (Battery / Quiet)**：PL1=4.5W, PL2=7W (低发热、风扇静音、电池续航长)
* **日常均衡模式 (Balanced - 推荐)**：PL1=7W, PL2=10W (兼顾单核 3.4GHz 爆发与日常流畅)
* **极致性能模式 (Performance)**：PL1=9W, PL2=12W (插电编译或满载运算)

#### 执行调优：
```bash
sudo bash scripts/04-tune-m3-power-thermal.sh
```

---

## 🧰 Linux 一键综合管理工具

为了便于管理，仓库提供了交互式终端综合管理工具，可一站式运行上述所有功能及硬件全景体检：

```bash
git clone https://github.com/ZGQ-inc/OneMix-1S-Plus.git
cd OneMix-1S-Plus
sudo bash scripts/onemix-tool.sh
```

也可以直接执行硬件全景体检：
```bash
bash scripts/onemix-hardware-diagnose.sh
```

---

## 📂 仓库目录结构

```text
OneMix-1S-Plus/
├── .gitattributes                        # Git 行尾 (LF) 与二进制属性规范
├── .github/                              # GitHub Actions CI 与 Issue/PR 模板
│   ├── ISSUE_TEMPLATE/                   # 规范结构化 Issue 表单 (YAML Forms)
│   │   ├── config.yml
│   │   ├── bug_report.yml
│   │   └── feature_request.yml
│   ├── PULL_REQUEST_TEMPLATE/            # 规范化多场景 PR 模板体系
│   │   ├── pull_request_template.md      # 默认通用 PR 模板
│   │   ├── bug_fix.md                    # 缺陷修复专项模板
│   │   └── feature.md                    # 新特性/硬件调优专项模板
│   └── workflows/
│       └── shellcheck.yml                # CI ShellCheck 检查工作流
├── docs/                                 # 深度技术文档与逆向原理 (中英双语)
│   ├── en/                               # 英文技术文档 (English Docs)
│   │   ├── hardware-spec.md
│   │   ├── screen-and-rotation.md
│   │   ├── sensor-calibration.md
│   │   ├── keyboard-and-ofn-firmware.md
│   │   ├── fingerprint-ft9201-driver.md
│   │   └── windows-drivers-guide.md
│   ├── hardware-spec.md                  # OneMix 1S+ 详细硬件规格与总线拓扑
│   ├── screen-and-rotation.md            # 屏幕旋转全链路深度解析与手动配置
│   ├── sensor-calibration.md             # 陀螺仪矩阵校准与 iio 调试
│   ├── keyboard-and-ofn-firmware.md      # SH68F83 逆向工程与固件修复分析
│   ├── fingerprint-ft9201-driver.md      # FT9536W 指纹驱动逆向与修复报告
│   └── windows-drivers-guide.md          # Windows 驱动与固件避坑指南
├── firmware/                             # 键盘与 OFN 触控板固件
│   ├── README.md                         # 固件说明与刷写安全警告 (中文)
│   ├── README_EN.md                      # 固件说明与刷写安全警告 (英文)
│   ├── OFN_1S+_Perfect_Final.hex         # 完美修复版固件
│   ├── Hailuck_KeyBoard_Update_Tool_for_68F83.exe  # 官方刷写工具 (Windows)
│   └── originals/                        # 官方原始固件归档
├── packages/                             # 预编译驱动与补丁分发包
│   ├── bootloader/                       # 硬件级横屏 GRUB 独立 EFI 与部署工具
│   │   ├── grubx64_rotated.efi           # 预编译自包含 2D Framebuffer 旋转 EFI
│   │   ├── 0001-grub-framebuffer-rotation.patch  # Kyle Bader 源码补丁
│   │   └── install-rotated-grub.sh       # 独立 EFI 安全安装脚本
│   └── fingerprint/                      # 定制 libfprint-2-2 驱动套件
├── scripts/                              # Linux 端各类一键运维与优化脚本
│   ├── onemix-tool.sh                    # ★ 交互式多功能综合管理 CLI
│   ├── 01-setup-screen-rotation.sh       # 屏幕开机与登录横屏一键配置
│   ├── 02-setup-sensor-gyroscope.sh      # 重力感应校准一键配置
│   ├── 03-install-fingerprint.sh         # 指纹驱动一键安装
│   ├── 04-tune-m3-power-thermal.sh       # Intel m3-8100Y 功耗墙与温控调节
│   └── onemix-hardware-diagnose.sh       # 硬件状态全景诊断脚本
├── src/                                  # 兼容层 C 语言源代码与 Makefile
│   └── focaltech-shim/                   # libgusb 符号兼容层
├── LICENSE                               # MIT 开源许可证
└── README.md                             # 中文完整指南
```

---

## 🔗 参考项目与致谢 (References & Acknowledgements)

本项目在开发、逆向与硬件调优过程中，参考并吸纳了开源社区与 UMPC 领域先驱者的卓越成果，在此表达诚挚感谢：

* **GNU GRUB 2D Framebuffer 旋转引擎**：
  * [Rotating display output from GRUB](https://hackaday.io/project/203272-rotating-display-output-from-grub)：提供了经过实战检验的 GRUB 2D Framebuffer 显存旋转补丁，彻底突破了小屏 UMPC 引导阶段物理竖屏的限制。
  * [GNU GRUB 官方项目](https://www.gnu.org/software/grub/)
* **重力感应器与姿态校准**：
  * [systemd / udev 硬件数据库 (hwdb)](https://github.com/systemd/systemd)：`ACCEL_MOUNT_MATRIX` 坐标系规范与定义。
  * [iio-sensor-proxy (Freedesktop)](https://gitlab.freedesktop.org/hadess/iio-sensor-proxy)：Linux 工业 I/O 传感器向 D-Bus / 桌面环境的姿态事件桥接服务。
* **指纹识别与驱动逆向**：
  * [libfprint / fprintd (Freedesktop)](https://gitlab.freedesktop.org/libfprint/libfprint)：现代 Linux 统一指纹识别框架与 TOD 接口规范。
  * [libgusb](https://github.com/hughsie/libgusb)：GLib 的异步 GObject USB 包装库。
  * [社区 FT9201 逆向工程贡献者 (ryenyuku/libfprint-ft9201)](https://github.com/ryenyuku/libfprint-ft9201)：为 FocalTech 2808 系列传感器在 Linux 下的逆向适配与协议解析奠定了宝贵基础。
* **处理器能耗与性能调优**：
  * [georgewhewell/undervolt](https://github.com/georgewhewell/undervolt)：Linux 下 Intel CPU RAPL 功耗墙与电压调节参考。
  * [Linux Kernel DRM KMS Documentation](https://www.kernel.org/doc/html/latest/gpu/drm-kms.html)：内核显示驱动屏幕旋转参数规范 (`video=...:panel_orientation=...`)。
* **官方资源与固件**：
  * [壹号本官网 (One-Netbook)](https://www.one-netbook.com/) & [官方下载服务](https://download.one-netbook.com/)：提供官方二代完整驱动包。
  * [中颖电子 (Sino Wealth)](https://www.sinowealth.com/) & [海栎创 (Hailuck)](http://www.hailuck.com/)：SH68F83 8051 架构 USB 微控制器规范与固件升级工具。

---

## 📜 免责声明与许可证

* 本项目包含对设备固件与驱动的逆向工程研究成果，仅供个人技术研究、设备维护与学习交流使用。
* 刷写固件操作虽然安全可逆，但仍请务必在操作前阅读相关文档并保持设备电量充足。
* 本项目代码与文档采用 [MIT 许可证](LICENSE) 开源。
