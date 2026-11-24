#!/usr/bin/env python3
"""
genfonts.py — generate TFT_eSPI-compatible VLW font files from TTF sources.

Pixel-honest sizing: set_pixel_sizes(0, N) sets the EM square to N device px.
Glyphs are rendered 1-bit (FT_LOAD_TARGET_MONO) by default: every cell is 0
or 255, so TFT_eSPI's smooth-font path draws them without softening.

Families (all OFL, sources in tools/ttf/):
  VT323           digits and hero words (32/44/64/86)
  JetBrains Mono  every small string — body, labels, status-bar titles

The UI is Vietnamese. Only fonts drawn WITH Vietnamese are used: accents
synthesized onto a Latin-only pixel font never looked as tidy as the
original English UI. build_vlw() refuses a font that lacks a letter.

VLW format (big-endian, verified against TFT_eSPI Extensions/Smooth_font.cpp):
  Header (24 bytes):
    u32 glyph_count
    u32 version       (11)
    u32 font_size_px  (informational; we store the EM px size here)
    u32 reserved      (0)
    u32 ascent        TFT_eSPI uses this as maxAscent — every TL/MC datum
    u32 descent       is measured from it. maxDescent is recomputed from
                      glyphs 0x21–0x9F and > 0xFF, so it can only grow.
  Per glyph (28 bytes), sorted by codepoint:
    u32 codepoint
    u32 bitmap_height
    u32 bitmap_width
    u32 xAdvance
    i32 dY            (offset from baseline UP to top edge of bitmap)
    i32 dX            (offset from cursor right to left edge of bitmap)
    u32 reserved      (0)
  Then concatenated bitmap data: each glyph w*h bytes, grayscale 0..255.
"""
import struct
import sys
import argparse
import unicodedata
from pathlib import Path
import freetype

HERE = Path(__file__).resolve().parent
TTF_DIR = HERE / "ttf"
OUT_DIR = HERE.parent / "data" / "fonts"

ASCII = list(range(0x20, 0x7F))     # ! .. ~ (printable ASCII incl. space)
EXTRA = [0x00B0, 0x00B7]            # ° middle dot · — used by Codex / weather


def _vietnamese():
    """Every Vietnamese letter outside ASCII: 12 vowels × 6 tones × 2 cases
    (minus the 12 plain ASCII vowels) + đ/Đ = 134 codepoints."""
    vowels = "aăâeêioôơuưy"
    tones = ["", "̀", "́", "̉", "̃", "̣"]
    out = {0x0110, 0x0111}
    for v in vowels:
        for t in tones:
            for c in (v, v.upper()):
                ch = unicodedata.normalize("NFC", c + t)
                if len(ch) == 1 and ord(ch) > 0x7F:
                    out.add(ord(ch))
    return sorted(out)


VIET = _vietnamese()

# (vlw_name, ttf_filename, em_px, codepoints, line_box)
#
# line_box = (ascent, descent) for the header, or None for the font's own
# (max over ASCII + EXTRA). The JBMono files replaced DM Mono / Silkscreen /
# Pixelify Sans and every layout was tuned on THEIR line boxes, so each keeps
# its predecessor's box and nothing on screen moves.
# VT323-86/110 only ever draw digits, so they stay ASCII (LittleFS is 1 MB).
FONT_MATRIX = [
    ("VT323-32",   "VT323-Regular.ttf",          32, ASCII + EXTRA + VIET, None),
    ("VT323-44",   "VT323-Regular.ttf",          44, ASCII + EXTRA + VIET, None),
    ("VT323-64",   "VT323-Regular.ttf",          64, ASCII + EXTRA + VIET, None),
    ("VT323-86",   "VT323-Regular.ttf",          86, ASCII + EXTRA,        None),
    ("VT323-110",  "VT323-Regular.ttf",         110, ASCII + EXTRA,        None),
    ("JBMono-11",  "JetBrainsMono-Regular.ttf",  11, ASCII + EXTRA + VIET, (10, 3)),  # was DMMono-11
    ("JBMono-13",  "JetBrainsMono-Regular.ttf",  13, ASCII + EXTRA + VIET, (11, 3)),  # was PixelifySans-14
    ("JBMono-12B", "JetBrainsMono-Bold.ttf",     12, ASCII + EXTRA + VIET, (13, 2)),  # was Silkscreen-12
    ("JBMono-16B", "JetBrainsMono-Bold.ttf",     16, ASCII + EXTRA + VIET, (16, 4)),  # was Silkscreen-16 (16, 2); dot-below needs 4 → MC text 1 px higher
]


def render_glyph(face, codepoint, mono):
    """Render one glyph. Returns (w, h, advance_px, bearing_x, bearing_y, pixels_bytes)
    where bitmap is row-major grayscale 0..255.
    """
    flags = freetype.FT_LOAD_RENDER
    if mono:
        flags |= freetype.FT_LOAD_TARGET_MONO
    face.load_char(chr(codepoint), flags)
    g = face.glyph
    bm = g.bitmap
    w, h = bm.width, bm.rows
    advance = g.advance.x >> 6
    bearing_x = g.bitmap_left
    bearing_y = g.bitmap_top  # distance from baseline UP to top of bitmap
    if w == 0 or h == 0:
        return (0, 0, advance, bearing_x, bearing_y, b"")
    if mono:
        # 1-bpp packed: convert to grayscale 0/255
        out = bytearray(w * h)
        pitch = bm.pitch
        buf = bm.buffer
        for y in range(h):
            row = buf[y * pitch:(y + 1) * pitch]
            for x in range(w):
                byte = row[x >> 3]
                bit = byte & (0x80 >> (x & 7))
                out[y * w + x] = 0xFF if bit else 0x00
        return (w, h, advance, bearing_x, bearing_y, bytes(out))
    else:
        # 8-bpp grayscale
        pitch = bm.pitch
        if pitch == w:
            return (w, h, advance, bearing_x, bearing_y, bytes(bm.buffer))
        out = bytearray(w * h)
        for y in range(h):
            out[y * w:(y + 1) * w] = bytes(bm.buffer[y * pitch:y * pitch + w])
        return (w, h, advance, bearing_x, bearing_y, bytes(out))


def build_vlw(ttf_path, em_px, codepoints, mono=True, line_box=None):
    face = freetype.Face(str(ttf_path))
    face.set_pixel_sizes(0, em_px)

    missing = [cp for cp in codepoints if cp in VIET and face.get_char_index(cp) == 0]
    if missing:
        raise SystemExit(f"{Path(ttf_path).name} lacks {len(missing)} Vietnamese "
                         f"letters (e.g. {chr(missing[0])}) — pick a font drawn for them")

    glyphs = []
    max_ascent = 0
    max_descent = 0
    for cp in sorted(set(codepoints)):
        if face.get_char_index(cp) == 0:
            continue  # codepoint not present in this font (non-Vietnamese only)
        w, h, advance, bx, by, pixels = render_glyph(face, cp, mono)
        if cp not in VIET:  # line box = ASCII + EXTRA
            max_ascent = max(max_ascent, by)
            max_descent = max(max_descent, h - by)
        glyphs.append({"cp": cp, "w": w, "h": h, "advance": advance,
                       "dY": by, "dX": bx, "pixels": pixels})
    if line_box:
        max_ascent, max_descent = line_box

    # TFT_eSPI recomputes maxDescent from glyphs 0x21–0x9F and > 0xFF; one
    # deeper than the header would change the line height of every string.
    for g in glyphs:
        cp = g["cp"]
        counted = (0x20 < cp < 0xA0 and cp != 0x7F) or cp > 0xFF
        if counted and g["h"] - g["dY"] > max_descent:
            print(f"  WARN U+{cp:04X} descends {g['h'] - g['dY']} > {max_descent} "
                  f"in {Path(ttf_path).name}@{em_px}", file=sys.stderr)

    out = bytearray()
    out += struct.pack(">IIIIII", len(glyphs), 11, em_px, 0, max_ascent, max_descent)
    for g in glyphs:
        out += struct.pack(">IIIIiiI", g["cp"], g["h"], g["w"], g["advance"],
                           g["dY"], g["dX"], 0)
    for g in glyphs:
        out += g["pixels"]
    return bytes(out), glyphs, max_ascent, max_descent


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mono", action="store_true", default=True,
                    help="Render 1-bit (pixel-honest, default)")
    ap.add_argument("--gray", dest="mono", action="store_false",
                    help="Render 8-bit grayscale (smoother)")
    ap.add_argument("--out", default=str(OUT_DIR))
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    for vlw_name, ttf_name, em, cps, box in FONT_MATRIX:
        ttf_path = TTF_DIR / ttf_name
        if not ttf_path.exists():
            print(f"  MISSING TTF: {ttf_path}", file=sys.stderr)
            continue
        data, glyphs, asc, desc = build_vlw(ttf_path, em, cps, args.mono, box)
        (out_dir / f"{vlw_name}.vlw").write_bytes(data)
        if not args.quiet:
            print(f"  {vlw_name:12s}  em={em:>3}  glyphs={len(glyphs):>3}  "
                  f"ascent={asc}  descent={desc}  size={len(data)}")


if __name__ == "__main__":
    main()
