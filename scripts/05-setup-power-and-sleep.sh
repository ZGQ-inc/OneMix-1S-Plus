#!/usr/bin/env bash
# OneMix 1S+ 屏幕合盖与电源策略管理脚本 (Lid Power & Screen Off Policy Manager)
# 解决合盖 3 秒断电 (Fix 3-sec EC power-cut on Amber Lake-Y / m3-8100Y)
# 提供【仅关闭屏幕】与【关闭屏幕+锁屏】两大专属模式
# Fully Internationalized (i18n): English / 简体中文

set -euo pipefail

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
BOLD='\033[1m'
RESET='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_ok() { echo -e "${GREEN}[OK]${RESET} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_err() { echo -e "${RED}[ERROR]${RESET} $1"; }

# Language Detection
UI_LANG="zh"
ACTION="menu"
LID_MODE=""

for arg in "$@"; do
    case "$arg" in
        --lang=en|-en|--en) UI_LANG="en" ;;
        --lang=zh|-zh|--zh) UI_LANG="zh" ;;
        --mask-sleep|--fix-sleep) ACTION="mask-sleep" ;;
        --lid=*) ACTION="set-lid"; LID_MODE="${arg#*=}" ;;
        --status) ACTION="status" ;;
    esac
done

if [[ -z "${UI_LANG:-}" || "$UI_LANG" == "zh" ]]; then
    if [[ "${ONEMIX_LANG:-}" == "en" || "${LANG:-}" =~ ^en || "${LC_ALL:-}" =~ ^en || "${LANGUAGE:-}" =~ ^en ]]; then
        UI_LANG="en"
    fi
fi

check_root() {
    if [[ $EUID -ne 0 ]]; then
        if [[ "$UI_LANG" == "en" ]]; then
            log_err "This script requires root privileges. Please run with sudo:"
        else
            log_err "本脚本需要 root 权限，请使用 sudo 运行："
        fi
        printf '      %ssudo bash %q' "$CYAN" "$0"
        printf ' %q' "$@"
        printf '%s\n\n' "$RESET"
        exit 1
    fi
}

get_real_user() {
    local u="${SUDO_USER:-}"
    if [[ -z "$u" || "$u" == "root" ]]; then
        u=$(logname 2>/dev/null || id -un 1000 2>/dev/null || echo "")
    fi
    echo "$u"
}

mask_sleep_targets() {
    # 彻底屏蔽硬件睡眠目标：杜绝底层意外调用挂起导致 EC 看门狗 3 秒硬断电
    systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target >/dev/null 2>&1 || true

    # 写入内核与 GRUB 默认 s2idle 参数（防止残留 deep 模式）
    if [[ -f /sys/power/mem_sleep ]]; then
        echo "s2idle" > /sys/power/mem_sleep 2>/dev/null || true
    fi
    mkdir -p /etc/systemd/sleep.conf.d
    cat > /etc/systemd/sleep.conf.d/10-onemix-sleep.conf << 'EOF'
[Sleep]
MemorySleepMode=s2idle
EOF

    local grub_file="/etc/default/grub"
    if [[ -f "$grub_file" ]] && ! grep -q "mem_sleep_default=s2idle" "$grub_file"; then
        if grep -q 'GRUB_CMDLINE_LINUX_DEFAULT=".*"' "$grub_file"; then
            sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)/\1 mem_sleep_default=s2idle/' "$grub_file"
        elif grep -q "GRUB_CMDLINE_LINUX_DEFAULT='.*'" "$grub_file"; then
            sed -i "s/\(GRUB_CMDLINE_LINUX_DEFAULT='[^']*\)/\1 mem_sleep_default=s2idle/" "$grub_file"
        fi
        update-grub >/dev/null 2>&1 || true
    fi
}

configure_kde_powerdevil() {
    local lid_action="$1"
    local locked_timeout="${2:-1}"
    local real_user
    real_user=$(get_real_user)

    if [[ -n "$real_user" && "$real_user" != "root" ]]; then
        local user_uid
        user_uid=$(id -u "$real_user" 2>/dev/null || echo "1000")
        local user_env="XDG_RUNTIME_DIR=/run/user/${user_uid} DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${user_uid}/bus"

        if command -v kwriteconfig6 &>/dev/null; then
            su - "$real_user" -c "env $user_env kwriteconfig6 --file powerdevilrc --group 'AC' --group 'SuspendAndShutdown' --key 'LidAction' ${lid_action}" 2>/dev/null || true
            su - "$real_user" -c "env $user_env kwriteconfig6 --file powerdevilrc --group 'Battery' --group 'SuspendAndShutdown' --key 'LidAction' ${lid_action}" 2>/dev/null || true
            su - "$real_user" -c "env $user_env kwriteconfig6 --file powerdevilrc --group 'AC' --group 'Display' --key 'TurnOffDisplayIdleTimeoutWhenLockedSec' ${locked_timeout}" 2>/dev/null || true
            su - "$real_user" -c "env $user_env kwriteconfig6 --file powerdevilrc --group 'Battery' --group 'Display' --key 'TurnOffDisplayIdleTimeoutWhenLockedSec' ${locked_timeout}" 2>/dev/null || true
        fi
        su - "$real_user" -c "env $user_env systemctl --user restart plasma-powerdevil.service" 2>/dev/null || true
    fi
}

show_status() {
    if [[ "$UI_LANG" == "en" ]]; then
        echo -e "\n${BOLD}${CYAN}OneMix 1S+ Power & Screen Configuration Status${RESET}"

        # 1. sleep target mask
        local mask_status
        mask_status=$(systemctl is-enabled suspend.target 2>&1 || true)
        if [[ "$mask_status" =~ masked ]]; then
            echo -e "  Hardware Sleep Target:      ${GREEN}Masked (Fatal sleep completely blocked, 0 risk of power-cut)${RESET}"
        else
            echo -e "  Hardware Sleep Target:      ${RED}Unmasked (WARNING: Suspend can trigger 3-second power-cut!)${RESET}"
        fi

        # 2. logind lid action
        local lid_cfg="/etc/systemd/logind.conf.d/10-onemix-lid.conf"
        local logind_act="default (suspend)"
        if [[ -f "$lid_cfg" ]]; then
            logind_act=$(grep -E "^HandleLidSwitch=" "$lid_cfg" | cut -d= -f2 || echo "unknown")
        fi
        echo -e "  Lid Close Action (logind):  ${GREEN}${logind_act}${RESET}"

        # 3. KDE PowerDevil Lid Action
        local real_user
        real_user=$(get_real_user)
        local pd_lid="not configured"
        local pd_locked="not configured"
        local pd_file=""
        if [[ -n "$real_user" ]]; then
            local u_home
            u_home=$(eval echo "~${real_user}")
            pd_file="${u_home}/.config/powerdevilrc"
            if [[ -f "$pd_file" ]]; then
                pd_lid=$(grep -E "^LidAction=" "$pd_file" | head -n1 | cut -d= -f2 || echo "unknown")
                pd_locked=$(grep -E "^TurnOffDisplayIdleTimeoutWhenLockedSec=" "$pd_file" | head -n1 | cut -d= -f2 || echo "default")
            fi
        fi

        local kde_desc="Unknown (${pd_lid})"
        case "$pd_lid" in
            32) kde_desc="Turn Off Screen (熄灭屏幕背光 - DPMS off)" ;;
            16) kde_desc="Lock Screen (锁定屏幕)" ;;
            0)  kde_desc="Do Nothing (忽略 / 常亮)" ;;
            1)  kde_desc="Sleep / Suspend (⚠ Fatal on 1S+)" ;;
        esac
        echo -e "  KDE PowerDevil Lid Action:  ${GREEN}${kde_desc}${RESET}"
        echo -e "  Screen Off Delay On Lock:   ${GREEN}${pd_locked} sec${RESET}"

        # 4. Summary Verdict
        echo -e "\n  ${BOLD}Active Mode Verdict:${RESET}"
        if [[ "$logind_act" == "ignore" && "$pd_lid" == "32" ]]; then
            echo -e "  ${GREEN}✓ Mode: TURN OFF SCREEN ONLY (Keeps running, instant wake, no lock, zero power loss)${RESET}"
        elif [[ "$logind_act" == "lock" ]]; then
            echo -e "  ${GREEN}✓ Mode: TURN OFF SCREEN + LOCK (Locks session & turns off display, secure & safe)${RESET}"
        elif [[ "$logind_act" == "ignore" && "$pd_lid" == "0" ]]; then
            echo -e "  ${YELLOW}! Mode: ALWAYS ON (Display stays on when lid closed)${RESET}"
        else
            echo -e "  ${YELLOW}! Mode: CUSTOM / UNOPTIMIZED (Recommend setting Option 1 or 2)${RESET}"
        fi
    else
        echo -e "\n${BOLD}${CYAN}OneMix 1S+ 屏幕与电源策略配置状态${RESET}"

        # 1. sleep target mask
        local mask_status_zh
        mask_status_zh=$(systemctl is-enabled suspend.target 2>&1 || true)
        if [[ "$mask_status_zh" =~ masked ]]; then
            echo -e "  底层硬件睡眠屏蔽状态:       ${GREEN}已彻底屏蔽 (Masked，完全杜绝 3 秒硬掉电故障)${RESET}"
        else
            echo -e "  底层硬件睡眠屏蔽状态:       ${RED}未屏蔽 (警告：触发挂起会导致主板急停断电！)${RESET}"
        fi

        # 2. logind lid action
        local lid_cfg_zh="/etc/systemd/logind.conf.d/10-onemix-lid.conf"
        local logind_act_zh="系统默认（挂起休眠）"
        if [[ -f "$lid_cfg_zh" ]]; then
            logind_act_zh=$(grep -E "^HandleLidSwitch=" "$lid_cfg_zh" | cut -d= -f2 || echo "未知")
        fi
        echo -e "  系统底座合盖策略 (logind):  ${GREEN}${logind_act_zh}${RESET}"

        # 3. KDE PowerDevil Lid Action
        local real_user_zh
        real_user_zh=$(get_real_user)
        local pd_lid_zh="未配置"
        local pd_locked_zh="默认"
        if [[ -n "$real_user_zh" ]]; then
            local u_home_zh
            u_home_zh=$(eval echo "~${real_user_zh}")
            local pd_file_zh="${u_home_zh}/.config/powerdevilrc"
            if [[ -f "$pd_file_zh" ]]; then
                pd_lid_zh=$(grep -E "^LidAction=" "$pd_file_zh" | head -n1 | cut -d= -f2 || echo "未知")
                pd_locked_zh=$(grep -E "^TurnOffDisplayIdleTimeoutWhenLockedSec=" "$pd_file_zh" | head -n1 | cut -d= -f2 || echo "默认")
            fi
        fi

        local kde_desc_zh="未知 (${pd_lid_zh})"
        case "$pd_lid_zh" in
            32) kde_desc_zh="关闭屏幕 (熄灭屏幕背光 - DPMS off)" ;;
            16) kde_desc_zh="锁定屏幕 (Lock screen)" ;;
            0)  kde_desc_zh="无作为 (屏幕常亮)" ;;
            1)  kde_desc_zh="挂起休眠 (⚠ 会触发 3 秒硬件掉电)" ;;
        esac
        echo -e "  KDE 桌面合盖动作 (桌面):    ${GREEN}${kde_desc_zh}${RESET}"
        echo -e "  锁屏后屏幕熄灭延迟:         ${GREEN}${pd_locked_zh} 秒${RESET}"

        # 4. Summary Verdict
        echo -e "\n  ${BOLD}当前策略综合判定：${RESET}"
        if [[ "$logind_act_zh" == "ignore" && "$pd_lid_zh" == "32" ]]; then
            echo -e "  ${GREEN}✓ 当前生效：【仅关闭屏幕】(合盖熄灭背光，不锁屏，开盖即用，后台程序常驻，零掉电)${RESET}"
        elif [[ "$logind_act_zh" == "lock" ]]; then
            echo -e "  ${GREEN}✓ 当前生效：【关闭屏幕 + 锁定桌面】(合盖自动锁屏并关屏，开盖指纹秒开，防误触安全)${RESET}"
        elif [[ "$logind_act_zh" == "ignore" && "$pd_lid_zh" == "0" ]]; then
            echo -e "  ${YELLOW}! 当前生效：【屏幕常亮】(合盖完全不熄屏)${RESET}"
        else
            echo -e "  ${YELLOW}! 当前生效：【系统默认 / 未优化】(建议选择选项 1 或 选项 2 进行优化)${RESET}"
        fi
    fi
    echo ""
}

apply_screen_off_policy() {
    if [[ "$UI_LANG" == "en" ]]; then
        log_info "Configuring lid action: TURN OFF SCREEN ONLY..."
    else
        log_info "正在配置合盖策略：仅关闭屏幕（熄屏不锁屏、不睡眠）..."
    fi

    # 1. 屏蔽致命硬件睡眠
    mask_sleep_targets

    # 2. 配置 logind
    mkdir -p /etc/systemd/logind.conf.d
    cat > /etc/systemd/logind.conf.d/10-onemix-lid.conf << 'EOF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
LidSwitchIgnoreInhibited=no
EOF

    # 3. 配置 KDE PowerDevil：32 = TurnOffScreen, 锁屏关屏设为 1 秒
    configure_kde_powerdevil 32 1

    # 4. 重新加载 logind
    systemctl kill -s HUP systemd-logind 2>/dev/null || true

    if [[ "$UI_LANG" == "en" ]]; then
        log_ok "Success: Lid action set to TURN OFF SCREEN ONLY!"
        echo -e "  ${GREEN}✓ Closing lid:${RESET} Display backlight turns off immediately (DPMS off)."
        echo -e "  ${GREEN}✓ Opening lid:${RESET} Display turns on instantly with 0 latency."
        echo -e "  ${GREEN}✓ System status:${RESET} Session remains unlocked, downloads/music/tasks run uninterrupted."
        echo -e "  ${GREEN}✓ Safety:${RESET} Hardware ACPI sleep is completely masked, zero risk of power loss."
    else
        log_ok "配置成功：合盖策略已设为【仅关闭屏幕】！"
        echo -e "  ${GREEN}✓ 合盖效果：${RESET} 屏幕背光立即熄灭 (DPMS off 省电)。"
        echo -e "  ${GREEN}✓ 开盖效果：${RESET} 屏幕瞬间点亮，0 秒无缝恢复工作区，无需输入密码。"
        echo -e "  ${GREEN}✓ 后台状态：${RESET} 保持解锁状态，音乐播放、文件下载、远程连接不间断运行。"
        echo -e "  ${GREEN}✓ 硬件安全：${RESET} 底层致命睡眠已全面屏蔽，彻底杜绝 3 秒硬件急停断电。"
    fi
}

apply_lock_and_screen_off_policy() {
    if [[ "$UI_LANG" == "en" ]]; then
        log_info "Configuring lid action: TURN OFF SCREEN + LOCK SESSION..."
    else
        log_info "正在配置合盖策略：关闭屏幕 + 锁定桌面（防误触安全）..."
    fi

    # 1. 屏蔽致命硬件睡眠
    mask_sleep_targets

    # 2. 配置 logind：合盖触发系统级锁定
    mkdir -p /etc/systemd/logind.conf.d
    cat > /etc/systemd/logind.conf.d/10-onemix-lid.conf << 'EOF'
[Login]
HandleLidSwitch=lock
HandleLidSwitchExternalPower=lock
HandleLidSwitchDocked=ignore
LidSwitchIgnoreInhibited=yes
EOF

    # 3. 配置 KDE PowerDevil：32 = TurnOffScreen, 锁屏熄屏延时 1 秒
    configure_kde_powerdevil 32 1

    # 4. 重新加载 logind
    systemctl kill -s HUP systemd-logind 2>/dev/null || true

    if [[ "$UI_LANG" == "en" ]]; then
        log_ok "Success: Lid action set to TURN OFF SCREEN + LOCK SESSION!"
        echo -e "  ${GREEN}✓ Closing lid:${RESET} Automatically locks session and turns off display backlight."
        echo -e "  ${GREEN}✓ Opening lid:${RESET} Display turns on to lock screen (unlock via password or fingerprint)."
        echo -e "  ${GREEN}✓ System status:${RESET} Background tasks keep running safely without keypress accidental touches."
        echo -e "  ${GREEN}✓ Safety:${RESET} Hardware ACPI sleep is completely masked, zero risk of power loss."
    else
        log_ok "配置成功：合盖策略已设为【关闭屏幕 + 锁定桌面】！"
        echo -e "  ${GREEN}✓ 合盖效果：${RESET} 自动锁定用户桌面，并同步熄灭屏幕背光 (DPMS off)。"
        echo -e "  ${GREEN}✓ 开盖效果：${RESET} 屏幕点亮并处于锁屏界面，轻触指纹或输入密码一秒解锁。"
        echo -e "  ${GREEN}✓ 防误触安全：${RESET} 放包内无论如何挤压键盘触控板均不会触发误操作，后台任务持续运行。"
        echo -e "  ${GREEN}✓ 硬件安全：${RESET} 底层致命睡眠已全面屏蔽，彻底杜绝 3 秒硬件急停断电。"
    fi
}

apply_ignore_policy() {
    if [[ "$UI_LANG" == "en" ]]; then
        log_info "Configuring lid action: KEEP DISPLAY ALWAYS ON..."
    else
        log_info "正在配置合盖策略：保持屏幕常亮（完全忽略合盖）..."
    fi

    mask_sleep_targets

    mkdir -p /etc/systemd/logind.conf.d
    cat > /etc/systemd/logind.conf.d/10-onemix-lid.conf << 'EOF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
LidSwitchIgnoreInhibited=no
EOF

    configure_kde_powerdevil 0 300
    systemctl kill -s HUP systemd-logind 2>/dev/null || true

    if [[ "$UI_LANG" == "en" ]]; then
        log_ok "Lid policy set to ALWAYS ON (display does not turn off)."
    else
        log_ok "已设置合盖策略为：保持常亮（合盖屏幕不熄灭）。"
    fi
}

restore_defaults() {
    if [[ "$UI_LANG" == "en" ]]; then
        log_info "Restoring system default lid and sleep settings..."
    else
        log_info "正在恢复系统默认合盖与睡眠配置..."
    fi

    rm -f /etc/systemd/logind.conf.d/10-onemix-lid.conf
    systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target >/dev/null 2>&1 || true
    configure_kde_powerdevil 1 300
    systemctl kill -s HUP systemd-logind 2>/dev/null || true

    if [[ "$UI_LANG" == "en" ]]; then
        log_ok "Restored system default configuration. (Notice: hardware suspend may still cause 3s power cut on 1S+)"
    else
        log_ok "已恢复系统缺省配置。（注意：原厂硬件睡眠在 OneMix 1S+ 上仍可能引发 3 秒断电）"
    fi
}

interactive_menu() {
    while true; do
        clear 2>/dev/null || true
        show_status
        if [[ "$UI_LANG" == "en" ]]; then
            echo -e "${BOLD}${BLUE}OneMix 1S+ Lid Power & Screen Off Policy Manager:${RESET}"
            echo -e "  ${BOLD}[1] Turn Off Screen Only${RESET} (${GREEN}Recommended: Keeps running, instant wake, no lock${RESET})"
            echo -e "  ${BOLD}[2] Turn Off Screen + Lock Session${RESET} (${GREEN}Recommended: Secure, prevents bag keypresses${RESET})"
            echo -e "  ${BOLD}[3] Keep Screen Always On${RESET} (Ignore lid close completely)"
            echo -e "  ${BOLD}[4] Mask Fatal Hardware Sleep Targets${RESET} (Block lethal ACPI sleep permanently)"
            echo -e "  ${BOLD}[5] Restore Default System Settings${RESET}"
            echo -e "  ${BOLD}[L] Switch Language / 切换语言${RESET} [Current: ${GREEN}English${RESET}]"
            echo -e "  ${BOLD}[0] Exit${RESET}"
            echo ""
            read -r -p "Enter your choice [0-5, L]: " c
        else
            echo -e "${BOLD}${BLUE}OneMix 1S+ 屏幕合盖与电源策略管理：${RESET}"
            echo -e "  ${BOLD}[1] 合盖仅关闭屏幕${RESET} (${GREEN}推荐掌机常驻：熄屏不断网不断电，开盖即用，不锁屏${RESET})"
            echo -e "  ${BOLD}[2] 合盖关闭屏幕 + 锁定桌面${RESET} (${GREEN}推荐移动安全：自动锁屏+熄屏，开盖指纹秒开，防误触${RESET})"
            echo -e "  ${BOLD}[3] 合盖屏幕常亮${RESET} (完全忽略合盖事件，保持原样)"
            echo -e "  ${BOLD}[4] 永久屏蔽系统硬件休眠${RESET} (彻底屏蔽致命 ACPI 睡眠，杜绝 3 秒掉电)"
            echo -e "  ${BOLD}[5] 恢复系统默认合盖配置${RESET} (移除所有优化设置)"
            echo -e "  ${BOLD}[L] 切换语言 / Switch Language${RESET} [当前: ${GREEN}简体中文${RESET}]"
            echo -e "  ${BOLD}[0] 退出${RESET}"
            echo ""
            read -r -p "请输入选项 [0-5, L]: " c
        fi

        case "$c" in
            1)
                apply_screen_off_policy
                read -r -p "$( [[ "$UI_LANG" == "en" ]] && echo "Press Enter to continue..." || echo "按回车键继续..." )"
                ;;
            2)
                apply_lock_and_screen_off_policy
                read -r -p "$( [[ "$UI_LANG" == "en" ]] && echo "Press Enter to continue..." || echo "按回车键继续..." )"
                ;;
            3)
                apply_ignore_policy
                read -r -p "$( [[ "$UI_LANG" == "en" ]] && echo "Press Enter to continue..." || echo "按回车键继续..." )"
                ;;
            4)
                mask_sleep_targets
                if [[ "$UI_LANG" == "en" ]]; then
                    log_ok "Hardware sleep targets masked successfully."
                else
                    log_ok "硬件挂起目标已成功全面屏蔽。"
                fi
                read -r -p "$( [[ "$UI_LANG" == "en" ]] && echo "Press Enter to continue..." || echo "按回车键继续..." )"
                ;;
            5)
                restore_defaults
                read -r -p "$( [[ "$UI_LANG" == "en" ]] && echo "Press Enter to continue..." || echo "按回车键继续..." )"
                ;;
            l|L)
                if [[ "$UI_LANG" == "en" ]]; then
                    UI_LANG="zh"
                else
                    UI_LANG="en"
                fi
                ;;
            0|q|exit|Q)
                break
                ;;
            *)
                if [[ "$UI_LANG" == "en" ]]; then
                    echo -e "${RED}Invalid option. Please try again.${RESET}"
                else
                    echo -e "${RED}无效选项，请重新输入。${RESET}"
                fi
                sleep 1
                ;;
        esac
    done
}

main() {
    check_root "$@"
    case "$ACTION" in
        mask-sleep)
            mask_sleep_targets
            if [[ "$UI_LANG" == "en" ]]; then
                log_ok "Hardware sleep targets masked successfully."
            else
                log_ok "硬件挂起目标已成功全面屏蔽。"
            fi
            ;;
        set-lid)
            case "$LID_MODE" in
                screen-off|turnoff)
                    apply_screen_off_policy
                    ;;
                lock|lock-and-off)
                    apply_lock_and_screen_off_policy
                    ;;
                ignore)
                    apply_ignore_policy
                    ;;
                *)
                    log_err "Unknown lid mode: $LID_MODE (supported: screen-off, lock, ignore)"
                    exit 1
                    ;;
            esac
            ;;
        status)
            show_status
            ;;
        menu)
            interactive_menu
            ;;
    esac
}

main "$@"
