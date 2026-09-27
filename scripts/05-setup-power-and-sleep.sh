#!/usr/bin/env bash
# OneMix 1S+ 睡眠模式与合盖电源策略配置脚本 (Sleep Mode & Lid Power Management)
# 解决合盖 3 秒断电 (Fix S3 deep sleep power-cut on Amber Lake-Y / m3-8100Y)
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
        --fix-sleep) ACTION="fix-sleep" ;;
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

show_status() {
    if [[ "$UI_LANG" == "en" ]]; then
        echo -e "\n${BOLD}${CYAN}OneMix 1S+ Power & Sleep Configuration Status${RESET}"
        
        # 1. mem_sleep
        if [[ -f /sys/power/mem_sleep ]]; then
            local mem_sleep
            mem_sleep=$(cat /sys/power/mem_sleep)
            echo -e "  Current Kernel Sleep Mode:  ${GREEN}${mem_sleep}${RESET}"
            if [[ "$mem_sleep" =~ \[deep\] ]]; then
                echo -e "  ${RED}⚠ WARNING: S3 [deep] sleep is active! This causes 3-second hard power-cut on OneMix 1S+.${RESET}"
            else
                echo -e "  ${GREEN}✓ Safe: [s2idle] (Modern Standby) is active.${RESET}"
            fi
        fi

        # 2. GRUB cmdline
        if [[ -f /etc/default/grub ]]; then
            if grep -q "mem_sleep_default=s2idle" /etc/default/grub; then
                echo -e "  GRUB Kernel Parameter:     ${GREEN}mem_sleep_default=s2idle configured${RESET}"
            else
                echo -e "  GRUB Kernel Parameter:     ${YELLOW}Not configured (will default to deep on boot)${RESET}"
            fi
        fi

        # 3. systemd sleep
        local sleep_cfg="/etc/systemd/sleep.conf.d/10-onemix-sleep.conf"
        if [[ -f "$sleep_cfg" ]]; then
            echo -e "  systemd Sleep Drop-in:      ${GREEN}${sleep_cfg} exists${RESET}"
        else
            echo -e "  systemd Sleep Drop-in:      ${YELLOW}None (system default)${RESET}"
        fi

        # 4. logind lid action
        local lid_cfg="/etc/systemd/logind.conf.d/10-onemix-lid.conf"
        if [[ -f "$lid_cfg" ]]; then
            local action
            action=$(grep -E "^HandleLidSwitch=" "$lid_cfg" | cut -d= -f2 || echo "unknown")
            echo -e "  Lid Close Action (logind):  ${GREEN}${action}${RESET}"
        else
            echo -e "  Lid Close Action (logind):  ${YELLOW}Default (suspend)${RESET}"
        fi
    else
        echo -e "\n${BOLD}${CYAN}OneMix 1S+ 电源与休眠配置状态${RESET}"
        
        # 1. mem_sleep
        if [[ -f /sys/power/mem_sleep ]]; then
            local mem_sleep
            mem_sleep=$(cat /sys/power/mem_sleep)
            echo -e "  当前内核挂起模式:           ${GREEN}${mem_sleep}${RESET}"
            if [[ "$mem_sleep" =~ \[deep\] ]]; then
                echo -e "  ${RED}⚠ 警告：当前处于 S3 [deep] 休眠！会导致 OneMix 1S+ 合盖/睡眠 3 秒后硬件硬关机断电。${RESET}"
            else
                echo -e "  ${GREEN}✓ 安全：已启用 [s2idle]（现代待机 / S0ix），硬件支持良好。${RESET}"
            fi
        fi

        # 2. GRUB cmdline
        if [[ -f /etc/default/grub ]]; then
            if grep -q "mem_sleep_default=s2idle" /etc/default/grub; then
                echo -e "  GRUB 内核引导参数:          ${GREEN}已配置 mem_sleep_default=s2idle${RESET}"
            else
                echo -e "  GRUB 内核引导参数:          ${YELLOW}未配置（开机可能恢复为 deep 致命模式）${RESET}"
            fi
        fi

        # 3. systemd sleep
        local sleep_cfg="/etc/systemd/sleep.conf.d/10-onemix-sleep.conf"
        if [[ -f "$sleep_cfg" ]]; then
            echo -e "  systemd 睡眠策略配置:       ${GREEN}${sleep_cfg} 已存在${RESET}"
        else
            echo -e "  systemd 睡眠策略配置:       ${YELLOW}未配置（使用系统缺省值）${RESET}"
        fi

        # 4. logind lid action
        local lid_cfg="/etc/systemd/logind.conf.d/10-onemix-lid.conf"
        if [[ -f "$lid_cfg" ]]; then
            local action
            action=$(grep -E "^HandleLidSwitch=" "$lid_cfg" | cut -d= -f2 || echo "unknown")
            echo -e "  合盖响应动作 (logind):      ${GREEN}${action}${RESET}"
        else
            echo -e "  合盖响应动作 (logind):      ${YELLOW}默认（suspend 挂起休眠）${RESET}"
        fi
    fi
    echo ""
}

apply_sleep_fix() {
    if [[ "$UI_LANG" == "en" ]]; then
        log_info "Applying s2idle sleep fix (permanent)..."
    else
        log_info "正在应用 s2idle 现代待机修复（持久化生效）..."
    fi

    # 1. 立即写入当前内核运行环境
    if [[ -f /sys/power/mem_sleep ]]; then
        echo "s2idle" > /sys/power/mem_sleep 2>/dev/null || true
    fi

    # 2. 配置 systemd sleep drop-in
    mkdir -p /etc/systemd/sleep.conf.d
    cat > /etc/systemd/sleep.conf.d/10-onemix-sleep.conf << 'EOF'
[Sleep]
MemorySleepMode=s2idle
EOF
    if [[ "$UI_LANG" == "en" ]]; then
        log_ok "Created /etc/systemd/sleep.conf.d/10-onemix-sleep.conf (MemorySleepMode=s2idle)"
    else
        log_ok "已创建 /etc/systemd/sleep.conf.d/10-onemix-sleep.conf (MemorySleepMode=s2idle)"
    fi

    # 3. 配置 GRUB 引导参数
    local grub_file="/etc/default/grub"
    if [[ -f "$grub_file" ]]; then
        if ! grep -q "mem_sleep_default=s2idle" "$grub_file"; then
            if grep -q 'GRUB_CMDLINE_LINUX_DEFAULT=".*"' "$grub_file"; then
                sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)/\1 mem_sleep_default=s2idle/' "$grub_file"
            elif grep -q "GRUB_CMDLINE_LINUX_DEFAULT='.*'" "$grub_file"; then
                sed -i "s/\(GRUB_CMDLINE_LINUX_DEFAULT='[^']*\)/\1 mem_sleep_default=s2idle/" "$grub_file"
            fi
            if [[ "$UI_LANG" == "en" ]]; then
                log_info "Updating GRUB bootloader configuration..."
            else
                log_info "正在更新 GRUB 引导器配置 (update-grub)..."
            fi
            update-grub >/dev/null 2>&1 || true
            if [[ "$UI_LANG" == "en" ]]; then
                log_ok "Added mem_sleep_default=s2idle to GRUB"
            else
                log_ok "已将 mem_sleep_default=s2idle 写入 GRUB 引导参数"
            fi
        else
            if [[ "$UI_LANG" == "en" ]]; then
                log_ok "GRUB already contains mem_sleep_default=s2idle"
            else
                log_ok "GRUB 配置中已包含 mem_sleep_default=s2idle"
            fi
        fi
    fi

    if [[ "$UI_LANG" == "en" ]]; then
        log_ok "Sleep mode fix applied successfully! S3 deep sleep is now disabled."
    else
        log_ok "睡眠模式修复完成！已禁用致命的 S3 deep 模式，切换为原生 s2idle。"
    fi
}

apply_lid_policy() {
    local policy="$1"
    mkdir -p /etc/systemd/logind.conf.d

    case "$policy" in
        ignore)
            cat > /etc/systemd/logind.conf.d/10-onemix-lid.conf << 'EOF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF
            if [[ "$UI_LANG" == "en" ]]; then
                log_ok "Lid policy set to: IGNORE (screen stays on / no sleep on lid close)"
            else
                log_ok "已设置合盖策略为：忽略 (IGNORE，合盖不断电、不休眠，程序与网络保持后台运行)"
            fi
            ;;
        lock)
            cat > /etc/systemd/logind.conf.d/10-onemix-lid.conf << 'EOF'
[Login]
HandleLidSwitch=lock
HandleLidSwitchExternalPower=lock
HandleLidSwitchDocked=ignore
EOF
            if [[ "$UI_LANG" == "en" ]]; then
                log_ok "Lid policy set to: LOCK (locks screen, maintains running background tasks)"
            else
                log_ok "已设置合盖策略为：锁屏 (LOCK，合盖自动锁定桌面，保持后台任务运行)"
            fi
            ;;
        suspend)
            cat > /etc/systemd/logind.conf.d/10-onemix-lid.conf << 'EOF'
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=ignore
EOF
            if [[ "$UI_LANG" == "en" ]]; then
                log_ok "Lid policy set to: SUSPEND (enters s2idle low-power standby on lid close)"
            else
                log_ok "已设置合盖策略为：挂起 (SUSPEND，合盖进入安全 s2idle 低功耗睡眠)"
            fi
            ;;
        *)
            log_err "Unknown policy: $policy (valid: ignore, lock, suspend)"
            exit 1
            ;;
    esac

    # 触发 systemd-logind 重新读取配置，不中断会话
    systemctl kill -s HUP systemd-logind 2>/dev/null || true
}

interactive_menu() {
    while true; do
        clear 2>/dev/null || true
        show_status
        if [[ "$UI_LANG" == "en" ]]; then
            echo -e "${BOLD}${BLUE}OneMix 1S+ Sleep & Lid Policy Manager:${RESET}"
            echo -e "  ${BOLD}[1] Fix 3-Second Power-Cut Bug${RESET} (Enable s2idle Modern Standby permanently)"
            echo -e "  ${BOLD}[2] Set Lid Action: IGNORE / Keep Running${RESET} (${GREEN}Recommended for UMPC / Background Tasks${RESET})"
            echo -e "  ${BOLD}[3] Set Lid Action: LOCK SCREEN${RESET} (Locks session, keeps running)"
            echo -e "  ${BOLD}[4] Set Lid Action: SUSPEND / SLEEP${RESET} (Enters safe s2idle sleep)"
            echo -e "  ${BOLD}[5] Restore Default logind Lid Settings${RESET}"
            echo -e "  ${BOLD}[0] Exit${RESET}"
            echo ""
            read -r -p "Enter your choice [0-5]: " c
        else
            echo -e "${BOLD}${BLUE}OneMix 1S+ 睡眠修复与合盖电源策略管理：${RESET}"
            echo -e "  ${BOLD}[1] 彻底修复合盖 3 秒断电 Bug${RESET} (永久启用原生 s2idle 现代待机，杜绝掉电)"
            echo -e "  ${BOLD}[2] 合盖动作：忽略 / 保持后台运行${RESET} (${GREEN}推荐 UMPC 掌机 / 听歌下载常驻${RESET})"
            echo -e "  ${BOLD}[3] 合盖动作：仅锁定屏幕${RESET} (锁屏保密，系统与网络保持运行)"
            echo -e "  ${BOLD}[4] 合盖动作：安全挂起睡眠${RESET} (合盖平稳进入 s2idle 待机，不再断电)"
            echo -e "  ${BOLD}[5] 恢复系统默认合盖配置${RESET}"
            echo -e "  ${BOLD}[0] 退出${RESET}"
            echo ""
            read -r -p "请输入选项 [0-5]: " c
        fi

        case "$c" in
            1)
                apply_sleep_fix
                read -r -p "$( [[ "$UI_LANG" == "en" ]] && echo "Press Enter to continue..." || echo "按回车键继续..." )"
                ;;
            2)
                apply_sleep_fix
                apply_lid_policy "ignore"
                read -r -p "$( [[ "$UI_LANG" == "en" ]] && echo "Press Enter to continue..." || echo "按回车键继续..." )"
                ;;
            3)
                apply_sleep_fix
                apply_lid_policy "lock"
                read -r -p "$( [[ "$UI_LANG" == "en" ]] && echo "Press Enter to continue..." || echo "按回车键继续..." )"
                ;;
            4)
                apply_sleep_fix
                apply_lid_policy "suspend"
                read -r -p "$( [[ "$UI_LANG" == "en" ]] && echo "Press Enter to continue..." || echo "按回车键继续..." )"
                ;;
            5)
                rm -f /etc/systemd/logind.conf.d/10-onemix-lid.conf
                systemctl kill -s HUP systemd-logind 2>/dev/null || true
                if [[ "$UI_LANG" == "en" ]]; then
                    log_ok "Removed custom lid policy drop-in."
                else
                    log_ok "已移除自定义合盖策略配置。"
                fi
                read -r -p "$( [[ "$UI_LANG" == "en" ]] && echo "Press Enter to continue..." || echo "按回车键继续..." )"
                ;;
            0|q|exit)
                break
                ;;
        esac
    done
}

main() {
    check_root "$@"
    case "$ACTION" in
        fix-sleep)
            apply_sleep_fix
            ;;
        set-lid)
            apply_sleep_fix
            apply_lid_policy "$LID_MODE"
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
