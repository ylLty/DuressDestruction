#!/system/bin/sh

# 模块信息
MODULE_NAME="音量键格机 | 胁迫销毁 - Duress Destruction"
MODULE_VERSION="v0.0.1 (1)"
MODULE_AUTHOR="yl_lty"
MODULE_DESCRIPTION="在开机或锁屏时以特定方式按下音量键即可销毁您的隐私数据，以保护您的隐私权。详见文档 https://github.com/ylLty/DuressDestruction/ "

# 显示模块信息
show_module_info() {
    ui_print "********************************************"
    ui_print "  $MODULE_NAME"
    ui_print "  版本: $MODULE_VERSION"
    ui_print "  作者: $MODULE_AUTHOR"
    ui_print "  描述: $MODULE_DESCRIPTION"
    ui_print "********************************************"
}


# 显示模块信息
show_module_info