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

is_booting() {
    [ "$(getprop init.svc.bootanim)" != "stopped" ]
}
# 输入序列缓存
KEY_SEQ=""
LAST_KEY_TIME=0

# 超时时间（秒）
SEQ_TIMEOUT=10

# 清空序列
reset_seq() {
    KEY_SEQ=""
    LAST_KEY_TIME=0
}

# 读取按键（阻塞）
read_key() {
    getevent -ql 2>/dev/null | while read -r line; do
        case "$line" in
            *"KEY_VOLUMEUP"*DOWN*)
                echo "+"
                return
                ;;
            *"KEY_VOLUMEDOWN"*DOWN*)
                echo "-"
                return
                ;;
            *"KEY_POWER"*DOWN*)
                echo "*"
                return
                ;;
        esac
    done
}

# 判断是否：亮屏 且 有锁
# shell 语义：
#   return 0 = 是（亮屏 + 有锁）
#   return 1 = 否
is_lockscreen() {
    local LINE SHOWING SCREEN

    LINE=$(dumpsys window policy 2>/dev/null \
        | tr '\n' ' ' \
        | sed 's/.*KeyguardServiceDelegate /KeyguardServiceDelegate /')

    SHOWING=$(echo "$LINE" \
        | grep -o 'showing=[^ ]*' \
        | cut -d= -f2)

    SCREEN=$(echo "$LINE" \
        | grep -o 'screenState=[^ ]*' \
        | cut -d= -f2)

    if [ "$SHOWING" = "true" ] && [ "$SCREEN" = "SCREEN_STATE_ON" ]; then
        return 0
    fi

    return 1
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
while true; do
    # ===== 总闸门 =====
    if ! is_booting && ! is_lockscreen; then
        reset_seq
        continue
    fi

    KEY=$(read_key)
    [ -z "$KEY" ] && continue
    # 电源键：强制重置序列
    if [ "$KEY" = "*" ]; then
        reset_seq
        continue
    fi

    # 再来一次，免得+-+[解锁]+依然触发
    if ! is_booting && ! is_lockscreen; then
        reset_seq
        continue
    fi

    NOW=$(date +%s)

    MODULE_STATUS='🤔 检测到了音量键操作，但不是销毁操作'
    echo '🤔 检测到了音量键操作，但不是销毁操作'
    update_module_status

    # 超时重置
    if [ "$LAST_KEY_TIME" -ne 0 ] && [ $((NOW - LAST_KEY_TIME)) -gt "$SEQ_TIMEOUT" ]; then
        reset_seq
    fi

    LAST_KEY_TIME="$NOW"
    KEY_SEQ="${KEY_SEQ}${KEY}"

    # 限制长度，防止无限增长
    KEY_SEQ=$(echo "$KEY_SEQ" | tail -c 4)

    # === 核心判断：是否包含 +-+- ===
    case "$KEY_SEQ" in
        *"+-+-"*)
            run_destroy
            reset_seq
            echo '😈 开始销毁数据'
            ;;
    esac
done