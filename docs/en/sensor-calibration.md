# OneMix 1S+ Accelerometer Calibration & Auto-Rotation Guide

[简体中文](../sensor-calibration.md) | [English](sensor-calibration.md)

---

## 1. Hardware Sensor & Bus Specifications

The OneMix 1S+ embeds a Bosch Sensortec 3-axis ultra-low-power accelerometer:
* **Sensor Series**: Bosch BMA250 / BMA2x Family
* **ACPI Hardware ID**: `BOSC0200`
* **Linux Driver Subsystem**: Industrial I/O (IIO) Subsystem
* **Device Node**: `/sys/bus/iio/devices/iio:device0`
* **Communication Protocol**: Internal I2C bus via ACPI table; kernel driver `bmc150_accel`.

---

## 2. Why Screen Auto-Rotation is Inverted by Default

In modern Linux desktop environments, sensor orientation events follow this data flow:
```text
Hardware Sensor (Bosch BMA2x)
  --> Kernel IIO Driver (/sys/bus/iio/devices/iio:deviceX)
    --> systemd-udevd (Reads ACCEL_MOUNT_MATRIX from hwdb to translate coordinate space)
      --> iio-sensor-proxy (Exposes org.freedesktop.SensorProxy over D-Bus)
        --> Desktop Compositor (KWin / Mutter consumes orientation events and rotates display)
```

Because the sensor chip is soldered onto the OneMix 1S+ motherboard with a 90-degree phase offset relative to standard PC tablet orientations, and its X and Y axes are transposed, the default identity matrix (`1, 0, 0; 0, 1, 0; 0, 0, 1`) causes:
* Tilting the laptop right is reported as left;
* Inverting the screen is reported as normal;
* 360-degree rotation behaves completely backwards.

---

## 3. Mathematical Derivation of the Mounting Matrix

By measuring physical gravity vectors against Euler rotation coordinates, the exact mounting matrix for the OneMix 1S+ is:

$$\begin{bmatrix} X_{screen} \\ Y_{screen} \\ Z_{screen} \end{bmatrix} = \begin{bmatrix} 0 & 1 & 0 \\ 1 & 0 & 0 \\ 0 & 0 & 1 \end{bmatrix} \begin{bmatrix} X_{sensor} \\ Y_{sensor} \\ Z_{sensor} \end{bmatrix}$$

Defined in `/etc/udev/hwdb.d/61-sensor-onemix.hwdb`:
```ini
sensor:modalias:acpi:BOSC0200*:dmi:*
 ACCEL_MOUNT_MATRIX=0, 1, 0; 1, 0, 0; 0, 0, 1
```

> [!WARNING]
> In udev hwdb syntax, the line beginning with `ACCEL_MOUNT_MATRIX=` **must start with exactly one leading whitespace**. Otherwise, `systemd-hwdb` parser will discard the rule as a syntax error!

---

## 4. Activation & Verification Steps

### 1. Compile and reload hwdb
```bash
sudo systemd-hwdb update
sudo udevadm trigger -v --sysname-match=iio:device*
sudo systemctl restart iio-sensor-proxy
```

### 2. Verify matrix property
```bash
cat /sys/bus/iio/devices/iio:device0/in_accel_mount_matrix
```
Expected output:
```text
0, 1, 0; 1, 0, 0; 0, 0, 1
```

### 3. Real-time orientation monitoring
Run the sensor monitor in a terminal:
```bash
monitor-sensor
```
Rotate the OneMix 1S+ physical body; the terminal will report accurate transitions:
* **Normal flat landscape**: `Accelerometer orientation changed: normal`
* **Right edge up (90° CCW)**: `Accelerometer orientation changed: right-up`
* **Left edge up (90° CW)**: `Accelerometer orientation changed: left-up`
* **Upside down (180°)**: `Accelerometer orientation changed: bottom-up`

### 4. Enable auto-rotation in desktop settings
Go to **System Settings** -> **Display and Monitor**, and check **Automatic screen rotation**.
