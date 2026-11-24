#!/usr/bin/env python3
"""
vlwpreview.py — render text with a VLW font the way TFT_eSPI does, to a PNG.

Mirrors Smooth_font.cpp: the line box is header ascent + recomputed
maxDescent; each glyph is drawn at y = cursorY + ascent - dY; a missing
codepoint is skipped silently (exactly what the device does — so a hole in
the preview is a hole on the panel).

  python tools/vlwpreview.py out.png data/fonts/Silkscreen-12.vlw "ĐANG CHỜ" ...
  python tools/vlwpreview.py out.png --all          # every shipped font, VN sample

Rows are scaled ×3 with a faint line-box band so overflow above/below shows.
"""
import struct
import sys
from pathlib import Path
from PIL import Image, ImageDraw

FONTS = Path(__file__).resolve().parent.parent / "data" / "fonts"
SAMPLE = [
    "ĐANG CHỜ BẠN · CẦN DUYỆT",
    "Hôm nay trời nắng ấm 24°",
    "ắ ằ ẳ ẵ ặ ấ ầ ẩ ẫ ậ ế ề ể ễ ệ",
    "ố ồ ổ ỗ ộ ớ ờ ở ỡ ợ ứ ừ ử ữ ự",
    "ả ạ ẻ ẹ ỉ ị ỏ ọ ủ ụ ỷ ỵ ỳ ỹ đ",
    "ẤẦẨẪẬẮẰẲẴẶẾỀỂỄỆ ỐỒỔỖỘ ỚỜỞỠỢ",
    "ỨỪỬỮỰ ẢẠẺẸỈỊỎỌỦỤỶỴ Đ Ơ Ư Ă",
]


def load(path):
    b = Path(path).read_bytes()
    n, _, _, _, asc, desc = struct.unpack_from(">IIIIII", b, 0)
    glyphs, off = {}, 24 + n * 28
    max_desc = desc
    for i in range(n):
        cp, h, w, adv, dy, dx, _ = struct.unpack_from(">IIIIiiI", b, 24 + i * 28)
        glyphs[cp] = (w, h, adv, dy, dx, b[off:off + w * h])
        off += w * h
        if (0x20 < cp < 0xA0 and cp != 0x7F) or cp > 0xFF:
            max_desc = max(max_desc, h - dy)
    return glyphs, asc, max_desc


def render(path, lines, scale=3, pad=6):
    glyphs, asc, desc = load(path)
    line_h = asc + desc
    space = line_h // 4
    rows = []
    for text in lines:
        x, ink = 0, []
        for ch in text:
            g = glyphs.get(ord(ch))
            if g is None:
                x += space if ch == " " else 0
                continue
            w, h, adv, dy, dx, px = g
            for j in range(h):
                for i in range(w):
                    if px[j * w + i] >= 128:
                        ink.append((x + dx + i, asc - dy + j))
            x += adv
        rows.append((x, ink))
    top = pad * 2                    # room for marks above the line box
    W = max(x for x, _ in rows) + 2 * pad
    H = len(rows) * (line_h + top + pad) + pad
    img = Image.new("RGB", (W * scale, H * scale), (14, 13, 18))
    d = ImageDraw.Draw(img)
    for k, (_, ink) in enumerate(rows):
        oy = pad + top + k * (line_h + top + pad)
        d.rectangle([pad * scale, oy * scale, (W - pad) * scale - 1,
                     (oy + line_h) * scale - 1], fill=(30, 30, 44))
        for x, y in ink:
            X, Y = (pad + x) * scale, (oy + y) * scale
            d.rectangle([X, Y, X + scale - 1, Y + scale - 1], fill=(240, 236, 228))
    return img


def main():
    out = sys.argv[1]
    if len(sys.argv) > 2 and sys.argv[2] == "--all":
        paths = sorted(p for p in FONTS.glob("*.vlw") if "VT323-86" not in p.name)
        imgs = [render(p, SAMPLE, scale=2 if "64" in p.name or "44" in p.name else 3)
                for p in paths]
        W = max(i.width for i in imgs)
        sheet = Image.new("RGB", (W, sum(i.height for i in imgs)), (0, 0, 0))
        y = 0
        for i in imgs:
            sheet.paste(i, (0, y)); y += i.height
        sheet.save(out)
    else:
        render(sys.argv[2], sys.argv[3:] or SAMPLE).save(out)


if __name__ == "__main__":
    main()
