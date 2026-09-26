<!--
  OneMix 1S+ Feature / Hardware Tuning Pull Request Template
-->

## Feature Overview / 特性概述
<!--
  Describe the new feature, hardware driver, or subsystem optimization.
  描述新增的功能、驱动适配或子系统调优方案。
-->

Resolves #(issue)

## Motivation & Use Case / 应用场景与价值
<!--
  Why is this feature needed for OneMix 1S+ users?
  为什么 OneMix 1S+ 需要此特性？解决了什么痛点？
-->

## Technical Architecture / 技术架构与实现
<!--
  Explain how this feature is implemented, including any files or scripts added.
  说明实现架构、新加入的脚本、配置文件或二进制组件。
-->

## Real Hardware Verification / 真机实测数据
* **Test Device**: OneMix 1S+ (m3-8100Y)
* **OS & Kernel**:
* **Performance / Functional Measurements**:
  <!-- e.g. Thermal benchmarks before/after, sensor response time, fingerprint match rate -->

## Checklist / 自查清单
- [ ] Feature is fully opt-in or backward compatible
- [ ] All shell scripts have Linux LF line endings and executable permissions (`chmod +x`)
- [ ] Both Chinese and English documentation updated (`docs/` and `docs/en/`)
- [ ] No unrelated dependencies (e.g., fcitx, raylink) or unverified binaries
- [ ] `scripts/onemix-hardware-diagnose.sh` updated if a new subsystem is monitored
