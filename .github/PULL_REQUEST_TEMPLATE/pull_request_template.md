<!--
  Thank you for contributing to OneMix 1S+ Linux & Windows Optimization Toolkit!
  Please review the checklist and fill out the sections below.
-->

## Description / 变更概述
<!--
  Please include a summary of the changes and the related issue.
  Please also include relevant motivation and context.
  请简要说明本次 PR 的修改内容、解决的问题或新增的特性。
-->

Fixes #(issue) / Closes #(issue)

## Motivation and Context / 修改动机与背景
<!--
  Why is this change required? What problem does it solve?
  为什么需要此修改？解决了什么具体问题或硬件缺陷？
-->

## Type of Change / 变更类型
<!-- Please mark all applicable options with an [x]. / 请在适用的选项括号内打勾 [x] -->
- [ ] 🐛 **Bug fix** (non-breaking change which fixes an issue / 修复已知缺陷)
- [ ] ✨ **New feature** (non-breaking change which adds functionality / 新增功能或硬件适配)
- [ ] 💥 **Breaking change** (fix or feature that would cause existing functionality to not work as expected / 破坏性变更)
- [ ] ⚡ **Performance / Tuning** (hardware, power, thermal, or rotation optimization / 性能、功耗或温控优化)
- [ ] 📝 **Documentation** (README, technical guides in `docs/` or `docs/en/` / 文档或翻译更新)
- [ ] 🔧 **Maintenance / CI** (code cleanup, workflows, or developer tooling / 维护、重构或 CI 工作流)

## How Has This Been Tested? / 测试与验证
<!--
  Please describe the tests that you ran to verify your changes.
  Provide instructions so others can reproduce.
  请详细说明在 OneMix 1S+ 上的测试过程与验证结果。
-->

**Test Environment / 测试环境:**
* **Hardware**: One-Netbook OneMix 1S+ (Intel Core m3-8100Y)
* **OS / Distro**:
* **Kernel Version**:
* **Desktop Environment**: (e.g., KDE Plasma 6.1 Wayland / X11)

**Verification Steps / 验证步骤:**
- [ ] Tested on physical OneMix 1S+ hardware / 已在真机上实测
- [ ] All modified shell scripts pass `bash -n` syntax check / 所有修改脚本语法检查通过
- [ ] Checked with `scripts/onemix-hardware-diagnose.sh` / 已通过硬件全景诊断脚本验证
- [ ] Bootloader safety verified: Dual-boot & original EFI entries (`Boot0001`/`Boot0000`) untouched / 双系统引导安全未受破坏

## Screenshots / Terminal Output / 截图与终端日志 (if applicable)
<!--
  Attach terminal output, logs, or photos demonstrating the fix or feature.
  若适用，请在此附上终端诊断输出、报错修复前后对比或硬件实拍截图。
-->

## Checklist / 自查清单
<!-- Please review all items before submitting. / 提交前请逐项自查并勾选 -->
- [ ] My code follows the style guidelines of this project / 代码遵循本项目的规范与风格
- [ ] All shell scripts use Linux LF (\n) line endings and have executable permissions (chmod +x) / 脚本使用 Linux LF 换行符并具备可执行权限
- [ ] I have performed a self-review of my own code / 我已完成代码的自主审查
- [ ] I have commented complex or non-obvious logic (e.g., UEFI NVRAM, ACPI, udev rules) / 针对复杂硬件逻辑（如 NVRAM、ACPI、udev 规则）添加了必要的注释
- [ ] I have updated both Chinese and English documentation (`docs/` and `docs/en/`) where appropriate / 已同步更新相应的中英文文档
- [ ] My changes generate no new warnings or lint errors / 代码未引入新的警告或语法错误
- [ ] No proprietary binaries without license, and no unrelated software (e.g., fcitx, raylink) introduced / 未引入未授权二进制文件或无关依赖
