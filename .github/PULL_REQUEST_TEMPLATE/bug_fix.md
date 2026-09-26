<!--
  OneMix 1S+ Bug Fix Pull Request Template
-->

## Bug Description / 缺陷描述
<!--
  A clear and concise description of what the bug was.
  清晰描述所修复的缺陷表现与根本原因。
-->

Fixes #(issue)

## Root Cause / 根因分析
<!--
  Explain what caused the bug (e.g., udev rule syntax, DMI string mismatch, libfprint ABI change).
  说明缺陷产生的深层原因（如 DMI 匹配错误、udev 语法问题、ABI 兼容性等）。
-->

## Solution / 修复方案
<!--
  Describe the changes made to solve the bug.
  详细说明本次修复的具体改动与技术手段。
-->

## Verification on Hardware / 真机测试验证
* **OS / Kernel**:
* **Affected Subsystem**: [ ] Display/GRUB [ ] Sensor/Gyro [ ] Fingerprint [ ] Keyboard/OFN [ ] Power/Thermal
* **Test Steps & Results**:
  - [ ] Reproduced bug before fix
  - [ ] Confirmed resolved after fix on OneMix 1S+ hardware
  - [ ] No regressions or side effects introduced
  - [ ] `bash -n` check passed for all modified shell scripts

## Checklist / 自查清单
- [ ] My code follows the style guidelines and uses Linux LF line endings
- [ ] Original bootloader (`Boot0001`/`Boot0000`) and dual-boot safety preserved
- [ ] Updated corresponding documentation if behavior changed
