#!/bin/sh
# 远程截取 Mudi 7 屏幕 (无需拆机/拍照)
# 用法: sh tools/screenshot.sh [输出文件名]
# 原理: 直接 dump framebuffer (240x320 RGB565) 并转为 PNG
OUT="${1:-screen}"
HOST="${MUDI_HOST:-192.168.8.1}"

ssh root@"$HOST" 'echo 0 > /sys/class/graphics/fb0/blank 2>/dev/null; dd if=/dev/fb0 bs=153600 count=1 2>/dev/null | gzip -1' > "$OUT.gz"

python3 - "$OUT" <<'PYEOF'
import gzip, struct, sys
n = sys.argv[1]
d = gzip.open(n + '.gz', 'rb').read()
W, H = 240, 320
rows = []
for y in range(H):
    r = []
    for x in range(W):
        o = (y * W + x) * 2
        px = struct.unpack("<H", d[o:o+2])[0]
        r.append(bytes((((px >> 11) & 0x1F) << 3,
                        ((px >> 5) & 0x3F) << 2,
                        (px & 0x1F) << 3)))
    rows.append(b''.join(r))
open(n + '.ppm', 'wb').write(b'P6\n%d %d\n255\n' % (W, H) + b''.join(rows))
print(f"已生成 {n}.ppm")
PYEOF

# macOS 转 PNG;Linux 可用 ImageMagick: convert "$OUT.ppm" "$OUT.png"
command -v sips >/dev/null && sips -s format png "$OUT.ppm" --out "$OUT.png" >/dev/null 2>&1 && echo "已生成 $OUT.png"
rm -f "$OUT.gz"
