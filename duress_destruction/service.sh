#!/system/bin/sh

# Copyright (C) 2025  yl_lty

# 初始化中的初始化(加载状态更新函数)======
# 状态变量
MODULE_STATUS=''

# 更改状态
update_module_status() {
    [ -z "$MODULE_STATUS" ] && return 0

    local MODULE_DIR="/data/adb/modules/duress_destruction"
    local PROP_FILE="$MODULE_DIR/module.prop"
    local TMP_FILE="$PROP_FILE.tmp"

    [ ! -f "$PROP_FILE" ] && return 0

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            description*=*)
                # 提取等号后的内容（去掉前后空格）
                desc="${line#*=}"
                desc="$(printf '%s' "$desc" | sed 's/^[[:space:]]*//')"

                # 去掉已有的 [状态]
                desc="$(printf '%s' "$desc" | sed 's/^\[[^][]*\][[:space:]]*//')"

                printf 'description = [%s]%s\n' "$MODULE_STATUS" "$desc"
                ;;
            *)
                printf '%s\n' "$line"
                ;;
        esac
    done < "$PROP_FILE" > "$TMP_FILE"

    mv "$TMP_FILE" "$PROP_FILE"
}
# =====
# 初始化
MODULE_STATUS='⏳ 初始化中...'
update_module_status

MODULE_DIR="/data/adb/modules/duress_destruction"
SEQ=""
DESTROY_SEQ="+-+-"
BOOT_VOLUME_HINTED=0

is_booting() {
    [ "$(getprop init.svc.bootanim)" != "stopped" ]
}

append_key() {
    SEQ="${SEQ}$1"
    [ ${#SEQ} -gt 20 ] && SEQ="${SEQ#?}"
}
run_destroy(){
    MODULE_STATUS='😈 开始销毁数据'
    update_module_status
}
# 初始化完毕
# ====
MODULE_STATUS='😋 准备就绪!'
update_module_status

# 检测逻辑
getevent -l | while read -r line; do
    case "$line" in
        *KEY_VOLUMEUP*"DOWN"*)
            key="+"
            ;;
        *KEY_VOLUMEDOWN*"DOWN"*)
            key="-"
            ;;
        *KEY_POWER*"DOWN"*)
            key="*"
            ;;
        *)
            continue
            ;;
    esac

    # 只记录音量键和电源键
    append_key "$key"

    # ===== 开机中 + 锁屏界面音量键提示逻辑 =====
    if is_booting; then
        if [ "$key" = "+" ] || [ "$key" = "-" ]; then
            if [ "$BOOT_VOLUME_HINTED" -eq 0 ]; then
                MODULE_STATUS='🤔 检测到了音量键操作，但不是销毁操作'
                update_module_status
                BOOT_VOLUME_HINTED=1
            fi
        fi
    fi
    # ============================================

    # 命中 +-+- → 无条件执行销毁
    case "$SEQ" in
        *"$DESTROY_SEQ"*)
            run_destroy
            exit 0
            ;;
    esac
done