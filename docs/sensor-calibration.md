# OneMix 1S+ 重力感应校准与自动旋转技术文档

[简体中文](sensor-calibration.md) | [English](en/sensor-calibration.md)

---

OneMix 1S+ 内部搭载了博世（Bosch Sensortec）的三轴超低功耗加速度传感器：
* **芯片系列**：Bosch BMA250 / BMA2x 系列
* **ACPI 硬件 ID**：`BOSC0200`
* **Linux 驱动子系统**：Industrial I/O (IIO) 子系统
* **设备节点**：`/sys/bus/iio/devices/iio:device0`
* **通信协议**：主板内部 I2C 总线，通过 ACPI 表由内核直接加载 `bmc150_accel` 驱动。

---

## 二、 为什么在 Linux 下屏幕自动旋转方向是错的？

在 Linux 桌面体系中，屏幕根据重力感应自动旋转的数据流向如下：
```text
硬件芯片 (Bosch BMA2x) 
  --> 内核 IIO 驱动 (/sys/bus/iio/devices/iio:deviceX)
    --> systemd-udevd (读取 hwdb 安装矩阵 ACCEL_MOUNT_MATRIX 进行坐标系转换)
      --> iio-sensor-proxy (通过 D-Bus 暴露 org.freedesktop.SensorProxy)
        --> 桌面环境合成器 (KDE KWin / GNOME Mutter 接收方向事件并翻转屏幕)
```

由于 OneMix 1S+ 将重力芯片焊接在主板内部时，其物理引脚朝向与标准 PC 平板规范存在 90 度的安装相位角偏差，且 X 轴与 Y 轴存在几何转置。
如果未在 `hwdb` 中写入校准安装矩阵，系统默认采用单位矩阵（`1, 0, 0; 0, 1, 0; 0, 0, 1`），导致：
* 屏幕向右倾斜时，系统判定为向左；
* 倒置时误判为正立；
* 上下左右方向完全错乱。

---

## 三、 安装矩阵 (Mounting Matrix) 数学推导与定义

通过实测物理姿态并比对欧拉旋转，OneMix 1S+ 的最终精准几何映射矩阵为：

$$\begin{bmatrix} X_{screen} \\ Y_{screen} \\ Z_{screen} \end{bmatrix} = \begin{bmatrix} 0 & 1 & 0 \\ 1 & 0 & 0 \\ 0 & 0 & 1 \end{bmatrix} \begin{bmatrix} X_{sensor} \\ Y_{sensor} \\ Z_{sensor} \end{bmatrix}$$

在 `/etc/udev/hwdb.d/61-sensor-onemix.hwdb` 中写入规则：
```ini
sensor:modalias:acpi:BOSC0200*:dmi:*
 ACCEL_MOUNT_MATRIX=0, 1, 0; 1, 0, 0; 0, 0, 1
```

> [!WARNING]
> udev hwdb 规则语法严格要求：`ACCEL_MOUNT_MATRIX=` 所在行的开头**必须严格保留且仅保留一个空格**，否则 systemd-hwdb 编译器会将其视为语法错误而忽略！

---

## 四、 激活与验证步骤

### 1. 编译并重载 hwdb
```bash
sudo systemd-hwdb update
sudo udevadm trigger -v --sysname-match=iio:device*
sudo systemctl restart iio-sensor-proxy
```

### 2. 检查安装矩阵是否生效
运行以下命令查看设备属性：
```bash
cat /sys/bus/iio/devices/iio:device0/in_accel_mount_matrix
```
输出应严格为：
```text
0, 1, 0; 1, 0, 0; 0, 0, 1
```

### 3. 实时姿态监控测试
在终端中启动实时姿态监控器：
```bash
monitor-sensor
```
旋转 OneMix 1S+ 机身，终端应精准报告以下四向姿态变化：
* **正常横屏平放**：`Accelerometer orientation changed: normal`
* **右侧立起（逆时针转90°）**：`Accelerometer orientation changed: right-up`
* **左侧立起（顺时针转90°）**：`Accelerometer orientation changed: left-up`
* **倒置立起（转180°）**：`Accelerometer orientation changed: bottom-up`

### 4. 桌面开启自动旋转
进入 **系统设置** -> **显示和监视器**，勾选 **【根据方向传感器自动旋转 (Automatic screen rotation)】** 即可。
