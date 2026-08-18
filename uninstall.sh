#!/bin/sh
# Mudi 7 汉化包 - 完全卸载,恢复出厂英文
set -e
SCREEN_DIR="/etc/gl_screen/language"
TEXT="$SCREEN_DIR/text/default"
FONT="$SCREEN_DIR/ttf/default_cn_medium.ttf"

echo "=== 卸载汉化包 ==="
[ -f "$TEXT.bak" ] && cp "$TEXT.bak" "$TEXT" && echo "✓ 已恢复原始文本" || echo "· 无文本备份"
[ -f "$FONT.bak" ] && cp "$FONT.bak" "$FONT" && echo "✓ 已恢复原始字体" || echo "· 无字体备份"
/etc/init.d/gl_screen restart >/dev/null 2>&1
sleep 3
pgrep -f gl_screen >/dev/null && echo "✓ 屏幕服务已重启" || echo "⚠ 服务异常"
echo "=== 已恢复出厂英文界面 ==="
