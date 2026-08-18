#!/bin/sh
# Mudi 7 (GL-E5800) 触摸屏汉化包 - 一键安装
# 用法: sh install.sh
set -e

SCREEN_DIR="/etc/gl_screen/language"
TEXT="$SCREEN_DIR/text/default"
FONT="$SCREEN_DIR/ttf/default_cn_medium.ttf"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Mudi 7 触摸屏汉化包 ==="

# 1) 环境检查
[ -f "$TEXT" ] || { echo "错误: 未找到 $TEXT,请确认在 Mudi 7 上运行"; exit 1; }
[ -f "$FONT" ] || { echo "错误: 未找到中文字体 $FONT"; exit 1; }
MODEL=$(cat /proc/device-tree/compatible 2>/dev/null | tr '\0' '\n' | head -1)
echo "设备: ${MODEL:-未知}"

# 2) 备份(仅首次)
if [ ! -f "$TEXT.bak" ]; then
    cp "$TEXT" "$TEXT.bak"
    echo "✓ 已备份原始文本 -> $TEXT.bak"
else
    echo "· 文本备份已存在,跳过"
fi
if [ ! -f "$FONT.bak" ]; then
    cp "$FONT" "$FONT.bak"
    echo "✓ 已备份原始字体 -> $FONT.bak"
else
    echo "· 字体备份已存在,跳过"
fi

# 3) 修复字体 lineGap (关键: 解决中文上下被裁切)
#    中文字体 hhea.lineGap=1000 -> 行高 2.0em,而控件按 1.3em 设计 -> 单行标签被裁切。
#    置 0 后单行正常。多行文本(短信正文)的行距不受此值影响,
#    由控件属性 SMS_DETAILS_ATTRIBUTE_LABE_TEXT_LINE_SPACE 单独控制(已写在语言包内)。
CURRENT=$(od -A n -t x1 -j 412 -N 2 "$FONT" | tr -d ' ')
if [ "$CURRENT" = "0000" ]; then
    echo "· 字体 lineGap 补丁已存在,跳过"
else
    printf '\x00\x00' | dd of="$FONT" bs=1 seek=412 conv=notrunc 2>/dev/null
    echo "✓ 已修复字体 lineGap (0x03e8 -> 0x0000),单行标签不再被裁切"
fi

# 4) 安装中文文本
cp "$SRC_DIR/lang/default.zh-cn" "$TEXT"
echo "✓ 已安装中文文本 ($(grep -c '_TEXT ' "$TEXT") 条)"

# 5) 重启屏幕服务
/etc/init.d/gl_screen restart >/dev/null 2>&1
sleep 4
if pgrep -f gl_screen >/dev/null; then
    echo "✓ 屏幕服务已重启"
    echo ""
    echo "=== 安装完成,请查看设备屏幕 ==="
else
    echo "⚠ 屏幕服务未运行,正在回滚..."
    cp "$TEXT.bak" "$TEXT"
    /etc/init.d/gl_screen restart >/dev/null 2>&1
    exit 1
fi
