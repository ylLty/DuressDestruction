#!/system/bin/sh

# 等待开机动画启动完成
while ! ps | grep -q "bootanimation"; do
    sleep 0.2 # 检测开机动画间隔时间
    echo 未进入开机动画
done

# 授权
chmod +x /data/adb/modules/duress_destruction/on_bootanimation.sh

# 执行 on_bootanimation.sh 脚本
/data/adb/modules/duress_destruction/on_bootanimation.sh