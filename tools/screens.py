#!/usr/bin/env python3
"""
screens.py — preview the device's screens on a computer (no flashing).

Re-draws each screen with the REAL VLW fonts from data/fonts/, the XP (Luna)
colours of src/core/theme.h and the coordinates from the firmware, and writes
a numbered contact sheet:

    python tools/screens.py out.png            # all screens, 2× scale
    python tools/screens.py out.png 1 8 13     # only these numbers

Look: P-2026-11-26.8/.9 "kiểu XP" (design/panel/docs/screen_specs.md §17).
It mirrors the drawing code by hand — window chrome + components
(src/channels/xp.cpp), taskbar (taskbar.cpp), system screens
(src/core/display.cpp) and each channel (src/channels/ch_*.cpp) — so after
changing a layout there, change it here too. Compare a render with
design/panel/screens/@2x/XP<Screen>.png. TFT_eSPI behaviour reproduced:
header ascent as maxAscent, maxDescent recomputed from glyphs, datums
TL/TC/TR/MC/MR/ML measured from the line box, missing glyphs skipped.
"""
import math
import re
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
import vlwpreview as V  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
W = H = 240
DOT = "·"


def hx(s):
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))


# ── theme.h (design hex; the panel runs inverted, which yields these) ──
BG = (0, 0, 0)
INK, INK_DIM, MUTED_DARK = hx("FFF8E8"), hx("D8CDB8"), hx("8A7F96")
CORAL, T_AMBER, MINT, T_SKY, T_LILAC = hx("FF5247"), hx("FFD23F"), hx("8FE574"), hx("54B6FF"), hx("C385FF")
CLAWD_ORANGE = hx("D97757")

# Theme::XP::* (token themeXP.color)
X = {k: hx(v) for k, v in dict(
    WELCOME_BAND="00309C", LINK="0033CC", TITLE_EDGE="003DB5", GROUP_LABEL="0046D5", FRAME="0047D3",
    TITLE_DARK="0049D6", TITLE="0058EE", FLAG_BLUE="05A6F0", TITLE_SHADOW="0A246A", SKY="0A6ACF",
    TRAY="0F8BE8", TRAY_EDGE="1042AF", BTN_PRESSED_EDGE="163E91", BOOT_BLOCK_LO="1A4DB8", BTN_EDGE="1A50C8",
    TASK_DARK="1C4FBF", CHECK_BOX="1C5180", BTN_PRESSED="1E4FB5", START_SHADOW="1E5E1E", ICON_INFO="1F6FE0",
    CHECK="21A121", TASK="245EDC", WELCOME_SHADOW="2A3F8F", TITLE_LIGHT="2B80F5", USER_SEL="2C55C4",
    START_DARK="2E7D2E", GREEN="2E8A2E", BOOT_BLOCK="2F6FE6", SELECT="316AC5", TASK_LIGHT="3A7DEB",
    START="3A9E3A", BAND_EDGE="3B4FA8", BTN="3C81F3", BAR="3CC63C", TITLE_HI="3D95FF", TRAY_HI="3FA9F5",
    LABEL="4D4D4D", WELCOME="5A7EDC", TASK_HI="5A9BF6", START_HI="5CC15C", USER_SEL_HI="5F84E3",
    MUTED="6F6F6F", LILAC="7A44C8", DIVIDER_FADE="7D9BE8", FIELD_BORDER="7F9DB9", WELCOME_LINE="7FA4F0",
    FLAG_GREEN="81BC06", BOOT_BLOCK_HI="9BC0FA", BAND_EDGE_WARM="9C6A6A", DIM="A0A0A0", STATUS_LINE="ACA899",
    BOOT_GREY="B2B2B2", FLASH_EDGE="B8661E", EMPTY_ICON="B8B4A0", DIVIDER="B9CBF5", RED="C1272D",
    AMBER="C98A00", WELCOME_SUB="C9D6F7", GROUP="D0D0BF", ICON_ERROR="D8341E", ROW_HI="DCE6F8",
    CLOSE="E0523C", ROW_LINE="E4E4E4", BODY="ECE9D8", FLASH="F0A030", WELCOME_ORANGE="F28F2E",
    ICON_WARN="F2C200", USER_PIC="F2C27A", FLAG_RED="F35325", FLAG_YELLOW="FFBA08", INFO_BAR="FFFFE1",
    WHITE="FFFFFF", BLACK="000000").items()}
globals().update({f"XP_{k}": v for k, v in X.items()})

# main.cpp slideAccent — slide-progress colour on the active taskbar button.
def slide_accent(name):
    return {"Codex": T_LILAC, "Photo": MINT, "Weather": T_SKY, "Forecast": T_SKY,
            "Clock": T_AMBER}.get(name, CORAL)


_fonts = {}


def font(name):
    if name not in _fonts:
        _fonts[name] = V.load(ROOT / "data" / "fonts" / f"{name}.vlw")
    return _fonts[name]


class Screen:
    def __init__(self, bg=BG):
        self.img = Image.new("RGB", (W, H), bg)
        self.px = self.img.load()

    def rect(self, x, y, w, h, c):
        for yy in range(max(0, y), min(H, y + h)):
            for xx in range(max(0, x), min(W, x + w)):
                self.px[xx, yy] = c

    def pixel(self, x, y, c):
        if 0 <= x < W and 0 <= y < H:
            self.px[x, y] = c

    def hline(self, x, y, w, c):
        self.rect(x, y, w, 1, c)

    def vline(self, x, y, h, c):
        self.rect(x, y, 1, h, c)

    def outline(self, x, y, w, h, c):
        self.rect(x, y, w, 1, c); self.rect(x, y + h - 1, w, 1, c)
        self.rect(x, y, 1, h, c); self.rect(x + w - 1, y, 1, h, c)

    # ── text, as TFT_eSPI smooth fonts draw it ──
    def width(self, fname, s):
        g, asc, desc = font(fname)
        return sum(g[ord(c)][2] if ord(c) in g else ((asc + desc) // 4 if c == " " else 0) for c in s)

    def line_h(self, fname):
        g, asc, desc = font(fname)
        return asc + desc

    def text(self, fname, s, x, y, color, datum="TL", bg=None):
        g, asc, desc = font(fname)
        line = asc + desc
        w = self.width(fname, s)
        if datum[1] == "C": x -= w // 2
        elif datum[1] == "R": x -= w
        if datum[0] == "M": y -= line // 2
        elif datum[0] == "B": y -= line
        if bg is not None:
            self.rect(x, y, w, line, bg)
        cx = x
        for ch in s:
            if ord(ch) not in g:
                cx += (asc + desc) // 4 if ch == " " else 0
                continue
            gw, gh, adv, dy, dx, bits = g[ord(ch)]
            for j in range(gh):
                for i in range(gw):
                    if bits[j * gw + i] >= 128:
                        self.pixel(cx + dx + i, y + asc - dy + j, color)
            cx += adv
        return w

    def bits(self, rows, w, x, y, color, scale=1):
        """Bit (w-1-i) of rows[j] = pixel (i, j)."""
        for j, row in enumerate(rows):
            for i in range(w):
                if row >> (w - 1 - i) & 1:
                    self.rect(x + i * scale, y + j * scale, scale, scale, color)


def fit(sc, fname, s, maxw):
    """XP::fitText: drop whole characters from the end."""
    while s and sc.width(fname, s) > maxw:
        s = s[:-1]
    return s


# ── Clawd (display.cpp drawClawd) ───────────────────────────────────────────
CLAWD = [
    "...############...",
    "...############...",
    "...##.######.##...",   # eyes: 1×2 holes
    "...##.######.##...",
    ".################.",   # arms
    ".################.",
    "...############...",
    "...############...",
    "....#.#....#.#....",   # legs
    "....#.#....#.#....",
]


def clawd_grid(eyes="open", legs="stand"):
    g = [list(r) for r in CLAWD]
    if eyes == "wide":
        g[1][5] = g[1][12] = "."
    elif eyes in ("happy", "shut"):
        g[2][5] = g[2][12] = "#"; g[3][5] = g[3][12] = "#"
    elif eyes == "sleep":
        g[2][5] = g[2][12] = "#"
        g[3][4] = g[3][5] = g[3][12] = g[3][13] = "."
    elif eyes == "sad":
        g[2][5] = g[2][12] = "#"; g[3][5] = g[3][12] = "#"
        g[2][6] = g[2][11] = "."; g[3][5] = g[3][12] = "."
    if legs == "walk":
        for r in (8, 9):
            g[r] = list("...#..#....#..#...")
    return ["".join(r) for r in g]


HAPPY_HOLES = [(10, 5), (9, 6), (11, 6), (25, 5), (24, 6), (26, 6), (16, 9), (19, 9), (17, 10), (18, 10)]


def clawd(sc, x, y, scale, color=CLAWD_ORANGE, bg=None, **kw):
    """drawClawd: bg=None paints set cells only; else every cell (body or bg)."""
    for j, row in enumerate(clawd_grid(**kw)):
        for i, c in enumerate(row):
            if c == "#":
                sc.rect(x + i * scale, y + j * scale, scale, scale, color)
            elif bg is not None:
                sc.rect(x + i * scale, y + j * scale, scale, scale, bg)
    if kw.get("eyes") == "happy":
        h = max(scale // 2, 1)
        for hx_, hy in HAPPY_HOLES:
            sc.rect(x + hx_ * scale // 2, y + hy * scale // 2, h, h, bg if bg is not None else X["BODY"])


BADGES = {   # display.cpp drawBadge 7×7
    "!":  [".#####.", "##.####", "##.####", "##.####", "#######", "##.####", ".#####."],
    ".":  [".#####.", "#######", "#######", "#.#.#.#", "#######", ".##....", ".#....."],
    "v":  ["......#", ".....##", "#...##.", "##.##..", ".###...", "..#....", "......."],
    "x":  ["#.....#", ".#...#.", "..#.#..", "...#...", "..#.#..", ".#...#.", "#.....#"],
}


def badge(sc, kind, x, y, scale, color):
    for j, row in enumerate(BADGES[kind]):
        for i, c in enumerate(row):
            if c == "#":
                sc.rect(x + i * scale, y + j * scale, scale, scale, color)


def sparkle(sc, cx, cy, color):
    sc.rect(cx - 4, cy, 10, 2, color)
    sc.rect(cx, cy - 4, 2, 10, color)


# ── XP chrome + components (src/channels/xp.cpp) ────────────────────────────
ICONS = {   # (w, h, rows): bit (w-1-x) of row y
    "clawd": (18, 10, [0x07FF8, 0x07FF8, 0x06FD8, 0x06FD8, 0x1FFFE,
                       0x1FFFE, 0x07FF8, 0x07FF8, 0x02850, 0x02850]),
    "photo": (16, 11, [0xFFFF, 0x8001, 0x8019, 0x803D, 0x8019, 0x8001,
                       0x8801, 0x9C21, 0xBE71, 0xFDFD, 0xFFFF]),
    "weather": (16, 14, [0x0180, 0x2184, 0x1008, 0x07E0, 0x0FF0, 0x0FF0, 0xCFF3,
                         0xCFF3, 0x0FF0, 0x0FF0, 0x07E0, 0x1008, 0x2184, 0x0180]),
    "clock": (16, 14, [0x07E0, 0x1FF8, 0x381C, 0x60C6, 0x60C6, 0xC0C3, 0xC0C3,
                       0xC0FB, 0xC003, 0x6006, 0x6006, 0x381C, 0x1FF8, 0x07E0]),
    "info": (6, 9, [0x0C, 0x0C, 0x00, 0x1C, 0x0C, 0x0C, 0x0C, 0x0C, 0x1E]),
}


def draw_icon(sc, icon, x, y, scale, color):
    w, h, rows = ICONS[icon]
    sc.bits(rows, w, x, y, color, scale)


_title = [""]


def title_text(sc, t):
    t = fit(sc, "JBMono-12B", t, 156)
    sc.text("JBMono-12B", t, 25, 5, X["TITLE_SHADOW"])
    sc.text("JBMono-12B", t, 24, 4, X["WHITE"])


def title_bands(sc, x, w):
    for y0, y1, c in ((0, 0, "TITLE_HI"), (1, 2, "TITLE_LIGHT"), (3, 18, "TITLE"),
                      (19, 20, "TITLE_DARK"), (21, 21, "TITLE_EDGE")):
        sc.rect(x, y0, w, y1 - y0 + 1, X[c])


def caption_button(sc, x, fill, kind):
    y = 3
    sc.rect(x, y, 16, 16, X["WHITE"])
    sc.rect(x + 1, y + 1, 14, 14, fill)
    if kind == "_":
        sc.rect(x + 4, y + 10, 6, 2, X["WHITE"])
    elif kind == "o":
        sc.outline(x + 4, y + 3, 8, 8, X["WHITE"])
        sc.hline(x + 4, y + 4, 8, X["WHITE"])
    else:
        for r in range(7):
            sc.rect(x + 4 + r, y + 4 + r, 2, 1, X["WHITE"])
            sc.rect(x + 10 - r, y + 4 + r, 2, 1, X["WHITE"])


def title_bar(sc, t, icon="clawd"):
    _title[0] = t
    title_bands(sc, 0, W)
    if icon == "clawd":
        draw_icon(sc, "clawd", 4, 6, 1, CLAWD_ORANGE)
    elif icon == "info":
        draw_icon(sc, "info", 8, 6, 1, X["WHITE"])
    elif icon:
        w, h, _ = ICONS[icon]
        draw_icon(sc, icon, 13 - w // 2, 11 - h // 2, 1, X["WHITE"])
    title_text(sc, t)
    caption_button(sc, 184, X["TITLE_LIGHT"], "_")
    caption_button(sc, 202, X["TITLE_LIGHT"], "o")
    caption_button(sc, 220, X["CLOSE"], "x")


def title_meta(sc, meta):
    t = f"{_title[0]} {DOT} {meta}" if meta else _title[0]
    title_bands(sc, 23, 182 - 23)
    title_text(sc, t)


def window(sc, t, icon="clawd", status=False):
    title_bar(sc, t, icon)
    sc.rect(0, 22, 2, 192, X["FRAME"])
    sc.rect(238, 22, 2, 192, X["FRAME"])
    sc.rect(2, 22, 236, 192, X["BODY"])
    if status:
        status_bar(sc, "", "")


def status_divider_x(rw):
    return 231 - rw - 8


def status_right_max(lw):
    room = status_divider_x(0) - 8
    if lw <= 0:
        return room
    return max(room - lw - 4, 120)


def status_bar(sc, left, right, lc=None, rc=None):
    lc = lc or X["BLACK"]; rc = rc or X["BLACK"]
    y = 196
    sc.rect(2, y, 236, 1, X["STATUS_LINE"])
    sc.rect(2, y + 1, 236, 1, X["WHITE"])
    sc.rect(2, y + 2, 236, 214 - y - 2, X["BODY"])
    f = "JBMono-11"
    left_max = 231 - 8
    if right:
        r = fit(sc, f, right, status_right_max(sc.width(f, left) if left else 0))
        dx = status_divider_x(sc.width(f, r))
        sc.rect(dx, y + 2, 1, 15, X["STATUS_LINE"])
        sc.text(f, r, 231, y + 3, rc, "TR")
        left_max = dx - 4 - 8
    if left:
        sc.text(f, fit(sc, f, left, left_max), 8, y + 3, lc)


def blocks(x, y, w, h, pad_y=-1):
    """XPCore::blocks → (x0, y0, bw, bh, gap, lastW)."""
    iw, ih = w - 2, h - 2
    gap = 2 if ih > 6 else 1
    py = pad_y if pad_y >= 0 else 1
    avail = iw - 2 * gap - 8 * gap
    bw = avail // 9
    return x + 1 + gap, y + 1 + py, bw, ih - 2 * py, gap, bw + avail % 9


def progress(sc, x, y, w, h, pct, on=None, pad_y=-1):
    on = on or X["BAR"]
    sc.outline(x, y, w, h, X["FIELD_BORDER"])
    sc.rect(x + 1, y + 1, w - 2, h - 2, X["WHITE"])
    x0, y0, bw, bh, gap, last = blocks(x, y, w, h, pad_y)
    bx = x0
    for i in range(9):
        if pct > i * (100 / 9):
            sc.rect(bx, y0, last if i == 8 else bw, bh, on)
        bx += bw + gap


def group_label(sc, x, y, label, clear_w=0):
    tw = sc.width("JBMono-11", label) if label else 0
    sc.rect(x + 4, y - 6, max(tw + 6, clear_w), 13, X["BODY"])
    if tw:
        sc.text("JBMono-11", label, x + 7, y - 6, X["GROUP_LABEL"])


def group_box(sc, x, y, w, h, label):
    sc.outline(x, y, w, h, X["GROUP"])
    group_label(sc, x, y, label)


def field(sc, x, y, w, h):
    sc.outline(x, y, w, h, X["FIELD_BORDER"])
    sc.rect(x + 1, y + 1, w - 2, h - 2, X["WHITE"])


CIRCLE24 = [None, 7, 6, 4, 3, 3, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 3, 4, 6, 7, None]
TRIANGLE24 = [None, None, 11, 11, 10, 10, 9, 9, 8, 8, 7, 6, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1, 0, None]


def inset_shape(sc, rows, x, y, c):
    for r, i in enumerate(rows):
        if i is not None:
            sc.rect(x + i, y + r, 24 - 2 * i, 1, c)


def dialog_icon(sc, kind, x, y):
    sc.rect(x, y, 24, 24, X["BODY"])
    if kind == "error":
        inset_shape(sc, CIRCLE24, x, y, X["ICON_ERROR"])
        for r in range(10):
            sc.rect(x + 7 + r, y + 7 + r, 2, 2, X["WHITE"])
            sc.rect(x + 15 - r, y + 7 + r, 2, 2, X["WHITE"])
    elif kind == "warn":
        inset_shape(sc, TRIANGLE24, x, y, X["ICON_WARN"])
        sc.rect(x + 11, y + 8, 3, 8, X["BLACK"])
        sc.rect(x + 11, y + 18, 3, 3, X["BLACK"])
    else:
        inset_shape(sc, CIRCLE24, x, y, X["ICON_INFO"])
        sc.rect(x + 10, y + 5, 4, 3, X["WHITE"])
        sc.rect(x + 10, y + 10, 4, 9, X["WHITE"])


def dialog(sc, kind, head, lines, link=None, sub=None):
    dialog_icon(sc, kind, 14, 36)
    if head:
        sc.text("JBMono-12B", head, 48, 38, X["BLACK"])
    y = 58
    for ln in lines:
        if ln:
            sc.text("JBMono-11", ln, 48, y, X["LABEL"])
        y += 16
    ly = y - 16 + 22 if lines else 58
    if link:
        lw = sc.text("JBMono-12B", link, 48, ly, X["LINK"])
        sc.hline(48, ly + 14, lw, X["LINK"])
        if sub:
            sc.text("JBMono-11", sub, 48, ly + 20, X["MUTED"])


def marquee_lit(step, cell, cells=9, lit=3):
    p = step % (cells + lit - 1)
    return p - lit < cell <= p


def marquee(sc, x, y, w, h, step):
    field(sc, x, y, w, h)
    x0, y0, bw, bh, gap, _ = blocks(x, y, w, h, 2)
    for i in range(9):
        if marquee_lit(step, i):
            sc.rect(x0 + i * (bw + gap), y0, bw, bh, X["BAR"])


def loading(sc, label, step=5):
    sc.text("JBMono-12B", label, 120, 92, X["BLACK"], "TC")
    marquee(sc, 50, 116, 140, 14, step)


def info_strip(sc, x, y, w, text, color=None):
    color = color or X["RED"]
    sc.rect(x, y, w, 14, X["INFO_BAR"])
    for r, row in enumerate([0x04, 0x0E, 0x0A, 0x1F, 0x1B]):
        for c in range(5):
            if row >> (4 - c) & 1:
                sc.pixel(x + 4 + c, y + 3 + r, X["AMBER"])
    if text:
        sc.text("JBMono-11", fit(sc, "JBMono-11", text, w - 15), x + 13, y + 1, color)


FLAG = ["........GGGGG.", "...RRRR.GGGGGG", ".RRRRRR.GGGGGG", ".RRRRRR.GGGGGG",
        ".RRRRRR.GGGGGG", "RRRRRRR.......", ".......YYYYYY.", "BBBBBB.YYYYYY.",
        "BBBBBB.YYYYYY.", "BBBBBB.YYYYYY.", "BBBBBB.YYYYY..", ".BBBB........."]
FLAG_C = {"R": "FLAG_RED", "G": "FLAG_GREEN", "B": "FLAG_BLUE", "Y": "FLAG_YELLOW"}


def draw_flag(sc, x, y, scale):
    for r, row in enumerate(FLAG):
        for i, ch in enumerate(row):
            if ch != ".":
                sc.rect(x + i * scale, y + r * scale, scale, scale, X[FLAG_C[ch]])


def no_channels(sc):
    """XP::drawNoChannels (main.cpp draws the taskbar after it)."""
    window(sc, "glimmer", "clawd")
    dialog(sc, "info", "Chưa có kênh", ["Bật kênh trên trang web:"], "glimmer.local")
    taskbar(sc, active=None, badge=1)


# ── Taskbar (src/channels/taskbar.cpp) ──────────────────────────────────────
START_BITS = [0x000180000C0, 0x000180000C0, 0x01EFC71F7E0, 0x02230D99180, 0x03030099980,
              0x07C61F30300, 0x00461130300, 0x04461B30300, 0x07873A60380]
START_INSET = [5, 3, 2, 1, 1] + [0] * 16 + [1, 1, 2, 3, 5]
DIGITS = [[7, 5, 5, 5, 7], [2, 6, 2, 2, 7], [6, 1, 2, 4, 7], [6, 1, 2, 1, 6], [5, 5, 7, 1, 1],
          [7, 4, 6, 1, 6], [3, 4, 7, 5, 7], [7, 1, 2, 2, 2], [7, 5, 7, 5, 7], [7, 5, 7, 1, 6],
          [0, 2, 7, 2, 0]]   # 0-9, '+'
BUTTONS = ["claude", "photo", "weather", "clock"]


def task_bands(sc, x, w, r0, r1):
    for a, z, c in ((0, 0, "TASK_HI"), (1, 2, "TASK_LIGHT"), (3, 22, "TASK"), (23, 25, "TASK_DARK")):
        a, z = max(a, r0), min(z, r1)
        if a <= z:
            sc.rect(x, 214 + a, w, z - a + 1, X[c])


def taskbar(sc, *, active="claude", mask=BUTTONS, flash=False, badge=1, progress=0.4,
            accent=CORAL, clock="14:32"):
    """Taskbar::draw. active = button name or None; progress = slide fraction."""
    task_bands(sc, 0, 196, 0, 25)
    for r in range(26):                                   # start button
        edge = 67 - START_INSET[r]
        c = X["START_HI"] if r <= 1 else X["START"] if r <= 22 else X["START_DARK"]
        sc.rect(0, 214 + r, edge, 1, c)
        sc.pixel(edge, 214 + r, X["START_DARK"])
    draw_flag(sc, 7, 221, 1)
    sc.bits(START_BITS, 41, 26, 222, X["START_SHADOW"])
    sc.bits(START_BITS, 41, 25, 221, X["WHITE"])
    slot = 0
    for b in BUTTONS:
        if b not in mask:
            continue
        x = 71 + 30 * slot
        slot += 1
        look = "flash" if b == "claude" and flash else "pressed" if b == active else "normal"
        edge, fill = {"flash": ("FLASH_EDGE", "FLASH"), "pressed": ("BTN_PRESSED_EDGE", "BTN_PRESSED"),
                      "normal": ("BTN_EDGE", "BTN")}[look]
        sc.rect(x, 217, 28, 20, X[edge])
        sc.rect(x + 1, 218, 26, 18, X[fill])
        if b == "claude":
            draw_icon(sc, "clawd", x + 5, 222, 1, X["WHITE"] if look == "flash" else CLAWD_ORANGE)
        else:
            w, h, _ = ICONS[b]
            draw_icon(sc, b, x + 14 - w // 2, 227 - h // 2, 1, X["WHITE"])
        if look == "pressed" and progress:
            sc.rect(x + 1, 234, int(26 * progress), 2, accent)
        if b == "claude" and not flash and badge > 0:
            sc.rect(x + 19, 215, 7, 9, T_AMBER)
            sc.rect(x + 18, 216, 9, 7, T_AMBER)
            for r, row in enumerate(DIGITS[min(badge, 10)]):
                for c in range(3):
                    if row >> (2 - c) & 1:
                        sc.pixel(x + 21 + c, 217 + r, BG)
    sc.rect(196, 214, 44, 26, X["TRAY"])
    sc.vline(196, 214, 26, X["TRAY_EDGE"])
    sc.hline(197, 214, 43, X["TRAY_HI"])
    sc.text("JBMono-11", clock, 218, 221, X["WHITE"], "TC")


# ── System screens (src/core/display.cpp) ───────────────────────────────────
_SRC_DISPLAY = (ROOT / "src" / "core" / "display.cpp").read_text(encoding="utf-8")


def c_bitmap(name):
    """A PROGMEM 1-bit bitmap from display.cpp → (bytes, bytes per row)."""
    m = re.search(name + r"\[(\d+)\] PROGMEM = \{(.*?)\};", _SRC_DISPLAY, re.S)
    data = [int(v, 16) for v in re.findall(r"0x([0-9A-Fa-f]{2})", m.group(2))]
    return data


def draw_c_bits(sc, data, w, h, x, y, color):
    nb = (w + 7) // 8
    for r in range(h):
        for i in range(w):
            if data[r * nb + i // 8] & (0x80 >> (i % 8)):
                sc.pixel(x + i, y + r, color)


def italic(sc, name, w, h, x, y):
    d = c_bitmap(name)
    draw_c_bits(sc, d, w, h, x + 1, y + 1, X["WELCOME_SHADOW"])
    draw_c_bits(sc, d, w, h, x, y, X["WHITE"])


def boot_lit(step, lane, lanes=6, lit=3):
    p = step % (lanes + lit - 1)
    return p - lit < lane <= p


def splash(sc, step=3):
    sc.rect(0, 0, W, H, BG)
    w = sc.width("JBMono-16B", "Window")
    x0 = (W - (w + 16)) // 2
    draw_flag(sc, x0 + w - 26, 50, 3)
    sc.text("JBMono-11", "Clawdsoft", x0, 89, X["WHITE"])
    sc.text("JBMono-16B", "Window", x0, 103, X["WHITE"])
    sc.text("JBMono-11", "xp", x0 + w + 2, 104, X["WELCOME_ORANGE"])
    sc.text("JBMono-11", "Professional", x0 + 2, 122, X["WELCOME_ORANGE"])
    bx, by = 92, 152
    sc.outline(bx, by, 56, 11, X["BOOT_GREY"])
    for px_, py_ in ((bx, by), (bx + 55, by), (bx, by + 10), (bx + 55, by + 10)):
        sc.pixel(px_, py_, BG)
    for i in range(6):
        if boot_lit(step, i):
            x, y = bx + 4 + 8 * i, by + 3
            sc.rect(x, y, 6, 5, X["BOOT_BLOCK"])
            sc.hline(x, y, 6, X["BOOT_BLOCK_HI"])
            sc.hline(x, y + 4, 6, X["BOOT_BLOCK_LO"])
    draw_c_bits(sc, c_bitmap("kCornerBits"), 69, 8, 163, 226, X["WHITE"])   # "Clawdsoft" (P-2026-11-26.10)


def welcome_chrome(sc):
    sc.rect(0, 31, W, 174, X["WELCOME"])
    sc.rect(0, 0, W, 30, X["WELCOME_BAND"])
    sc.hline(0, 30, W, X["WELCOME_LINE"])
    sc.rect(0, 207, W, 33, X["WELCOME_BAND"])
    for x, w, c in ((0, 40, "BAND_EDGE"), (40, 40, "BAND_EDGE_WARM"), (80, 80, "WELCOME_ORANGE"),
                    (160, 40, "BAND_EDGE_WARM"), (200, 40, "BAND_EDGE")):
        sc.rect(x, 205, w, 2, X[c])


def connecting(sc):
    welcome_chrome(sc)
    italic(sc, "kWelcomeBits", 71, 12, 70, 106)


def setup_ap(sc, ap="glimmer-setup", ip="192.168.4.1"):
    welcome_chrome(sc)
    draw_flag(sc, 70, 74, 2)
    italic(sc, "kWindowBits", 63, 12, 12, 102)
    sc.text("JBMono-11", "xp", 81, 103, X["WELCOME_ORANGE"])
    sc.text("JBMono-11", "Để bắt đầu,", 14, 126, X["WHITE"])
    sc.text("JBMono-11", "kết nối Wi-Fi", 14, 140, X["WHITE"])
    sc.vline(116, 40, 30, X["DIVIDER_FADE"])
    sc.vline(116, 70, 100, X["DIVIDER"])
    sc.vline(116, 170, 30, X["DIVIDER_FADE"])
    sc.rect(124, 86, 112, 50, X["USER_SEL"])
    sc.hline(124, 86, 112, X["USER_SEL_HI"])
    sc.rect(130, 92, 24, 24, X["WHITE"])
    sc.rect(132, 94, 20, 20, X["USER_PIC"])
    clawd(sc, 133, 99, 1, CLAWD_ORANGE, bg=X["USER_PIC"])
    l1, _, l2 = ap.partition("-")
    if l2:
        l1 += "-"
    sc.text("JBMono-12B", l1, 158, 92, X["WHITE"])
    if l2:
        sc.text("JBMono-12B", l2, 158, 106, X["WHITE"])
    sc.text("JBMono-11", ip, 158, 121, X["WELCOME_SUB"])
    sc.rect(8, 218, 14, 14, X["WHITE"])
    sc.rect(9, 219, 12, 12, X["CLOSE"])
    sc.rect(14, 221, 2, 5, X["WHITE"])
    sc.rect(11, 223, 1, 5, X["WHITE"])
    sc.rect(18, 223, 1, 5, X["WHITE"])
    sc.rect(12, 228, 6, 1, X["WHITE"])
    sc.text("JBMono-11", "Cài đặt Wi-Fi", 28, 219, X["WHITE"])


def ota(sc):
    welcome_chrome(sc)
    italic(sc, "kUpdatingBits", 158, 17, 20, 96)
    sc.text("JBMono-11", "Đừng tắt hay rút điện máy.", 120, 130, X["WHITE"], "TC")


# ══ Channels (src/channels/ch_*.cpp) ═════════════════════════════════════════
# ── Claude (ch_claude.cpp) ──────────────────────────────────────────────────
STATE_LABEL = {"approval": "Cần duyệt", "input": "Chờ bạn", "error": "Lỗi", "working": "Đang chạy", "done": "Xong"}
STATE_XP = {"approval": "AMBER", "input": "SKY", "error": "RED", "working": "LILAC", "done": "GREEN"}

CLAUDE_ROWS = [("glimmer", "approval", "Bash", "2P"), ("TieuMac3d", "working", "Edit", "5P"),
               ("api", "done", "", "1G")]
ZZ_Z4 = [0x0F, 0x02, 0x04, 0x0F]


def xp_usage_color(pct, healthy):
    """chrome.h xpUsageColor: remaining ≤ 20 % red, ≤ 50 % amber, else healthy."""
    if pct < 0:
        return X["DIM"]
    rem = 100 - pct
    return X["RED"] if rem <= 20 else X["AMBER"] if rem <= 50 else healthy


def hero(sc, pct, color, bar_color, pad_y, clear_r, asleep=False):
    """paintHero (Claude / Codex): VT323-86 digits + VT323-44 "%" + 220×14 bar."""
    s = f"{pct}" if pct >= 0 else "--"
    sc.rect(10, 40, clear_r - 10, 102 - 40, X["BODY"])
    hw = sc.text("VT323-86", s, 10, 40, color)
    if len(s) < 3 or not asleep:
        sc.text("VT323-44", "%", 10 + hw + 2, 70, color)
    progress(sc, 10, 102, 220, 14, max(pct, 0), bar_color, pad_y)


def project_row(sc, proj, state, detail, age, y, dim):
    c = X["DIM"] if dim else X[STATE_XP[state]]
    sc.rect(14, y + 4, 5, 5, c)
    aw = sc.text("JBMono-11", age, 225, y, X["MUTED"], "TR")
    right = 225 - aw - 7
    p = fit(sc, "JBMono-11", proj, 84)
    pw = sc.text("JBMono-11", p, 23, y, X["DIM"] if dim else X["BLACK"])
    sx = 23 + pw + 7
    st = f"{STATE_LABEL[state]} {DOT} {detail}" if detail else STATE_LABEL[state]
    if detail and sc.width("JBMono-11", st) > right - sx:
        st = STATE_LABEL[state]
    sc.text("JBMono-11", fit(sc, "JBMono-11", st, right - sx), sx, y, c)


def cred_banner_xp(sc, x, y, w, is_claude, cred):
    """Chrome::credBanner."""
    cw = "Khóa" if is_claude else "Token"
    if cred == "blocked":
        t = f"Bị chặn {DOT} {cw.lower()} vẫn tốt {DOT} thử lại"
    else:
        t = f"{cw} {'hết hạn' if cred == 'expired' else 'bị từ chối'} {DOT} glimmer.local"
    if sc.width("JBMono-11", t) > w - 17:
        if cred == "blocked":
            t = f"Bị chặn {DOT} {cw.lower()} vẫn tốt"
        else:
            t = f"{'Hết hạn' if cred == 'expired' else 'Bị từ chối'} {DOT} glimmer.local"
    info_strip(sc, x, y, w, t, X["BLACK"] if cred == "blocked" else X["RED"])


def claude_xp(sc, *, pct=38, reset="4NG", sec="12% · 2G 14P", sec_pct=12, rows=CLAUDE_ROWS,
              eyes="wide", stale=False, meta="", cred=None, badge=1):
    window(sc, "Claude", "clawd")
    if meta:
        title_meta(sc, meta)
    dim = stale
    asleep = eyes == "sleep"
    sc.text("JBMono-11", "Hạn mức tuần", 10, 28, X["LABEL"])
    hc = X["DIM"] if dim else xp_usage_color(pct, X["GREEN"])
    bc = X["BAR"] if hc == X["GREEN"] else hc
    hero(sc, pct, hc, bc, 2, 155, asleep)
    clawd(sc, 156, 52 if asleep else 36, 4, bg=X["BODY"], eyes=eyes)
    if asleep:   # Zz frame 6 (kZz[6] = z4 at (202,38) shifted (−6,−6))
        for j, row in enumerate(ZZ_Z4):
            for i in range(4):
                if row & (1 << (3 - i)):
                    sc.rect(196 + i * 2, 32 + j * 2, 2, 2, X["MUTED"])
    sc.text("JBMono-12B", reset, 150 if asleep else 229, 84, X["DIM"] if dim else X["RED"], "TR")
    group_box(sc, 10, 128, 220, 34, "Phiên 5 giờ")
    sc.text("JBMono-11", sec, 224, 135, X["DIM"] if dim else X["BLACK"], "TR")
    progress(sc, 16, 151, 208, 7, sec_pct, X["DIM"] if dim else X["BAR"])
    field(sc, 10, 166, 220, 44)
    y, n = 168, 3
    if cred:
        cred_banner_xp(sc, 11, 167, 218, True, cred)
        sc.hline(11, 181, 218, X["STATUS_LINE"])
        y, n = 182, 2
    for i, r in enumerate(rows[:n]):
        project_row(sc, *r, y + i * 13, dim)
    if not rows:
        sc.text("JBMono-11", "Chưa có hoạt động project", 120, 182 if n == 3 else y + 7, X["MUTED"], "TC")
    taskbar(sc, active="claude", badge=badge, accent=slide_accent("Claude"))


def cred_card_xp(sc, title, meta, kind, head, lines, link=None, sub=None, badge=1, accent="Claude"):
    """Chrome::credCard inside the window."""
    window(sc, title, "clawd")
    if meta:
        title_meta(sc, meta)
    dialog(sc, kind, head, lines, link, sub)
    taskbar(sc, active="claude", badge=badge, accent=slide_accent(accent))


def loading_xp(sc, title, badge=1):
    window(sc, title, "clawd")
    loading(sc, "Đang tải...", step=5)
    taskbar(sc, active="claude", badge=badge, accent=slide_accent(title))


# ── Codex (ch_codex.cpp) ───────────────────────────────────────────────────
def codex_xp(sc, *, pct=41, reset="3NG", tag="Spark", sec="2G 14P", resets="còn 2 · 3NG",
             pace="~70% khi đặt lại", pace_red=False, credits=None, stale=False, meta="", cred=None, badge=1):
    window(sc, "Codex", "clawd")
    if meta:
        title_meta(sc, meta)
    sc.text("JBMono-11", "Hạn mức tuần", 10, 28, X["LABEL"])
    hc = X["DIM"] if stale else xp_usage_color(pct, X["LILAC"])
    hero(sc, pct, hc, hc, 1, 150)
    if credits:
        sc.text("JBMono-11", "tín dụng", 229, 28, X["MUTED"], "TR")
        sc.text("JBMono-12B", credits, 229, 42, X["DIM"] if stale else X["BLACK"], "TR")
    sc.text("JBMono-11", "đặt lại sau", 229, 68, X["MUTED"], "TR")
    sc.text("JBMono-12B", reset, 229, 84, X["DIM"] if stale else X["RED"], "TR")
    group_box(sc, 10, 128, 220, 30, "Phiên 5 giờ")
    rw = sc.text("JBMono-11", sec, 222, 137, X["DIM"] if stale else X["BLACK"], "TR")
    sc.text("JBMono-11", fit(sc, "JBMono-11", tag, 222 - rw - 8 - 18), 18, 137, X["BLACK"])   # label: black even stale
    group_box(sc, 10, 170, 220, 24, "Đặt lại tuần")
    room = 222 - 18
    if pace:
        pw = sc.text("JBMono-11", pace, 222, 177, X["RED"] if pace_red else X["MUTED"], "TR")
        room = 222 - pw - 8 - 18
    sc.text("JBMono-11", fit(sc, "JBMono-11", resets, room), 18, 177, X["BLACK"])
    if cred:
        cred_banner_xp(sc, 10, 198, 220, False, cred)
    taskbar(sc, active="claude", badge=badge, accent=slide_accent("Codex"))


# ── Group B: Home, AI, Trend, Agents, Attention cards ───────────────────────


def xp_usage_color_left(remaining, healthy):
    """chrome.h xpUsageColor: colour from % REMAINING."""
    if remaining < 0:
        return X["DIM"]
    if remaining <= 20:
        return X["RED"]
    if remaining <= 50:
        return X["AMBER"]
    return healthy


# ── Home (ch_home.cpp) ──
def _home_row(sc, y, label, used, healthy, note=None, note_color=None):
    sc.text("JBMono-11", label, 18, y, X["BLACK"])
    if note:
        sc.text("JBMono-11", fit(sc, "JBMono-11", note, 222 - 70), 70, y, note_color or X["RED"])
        return
    rem = 100 - used if used >= 0 else -1
    c = xp_usage_color_left(rem, healthy)
    progress(sc, 70, y - 1, 120, 14, max(used, 0), c, 1)
    sc.text("JBMono-11", f"{used}%" if used >= 0 else "--", 222, y, c, "TR")


# Home, AI and Trend press the Claude button: slide accent CORAL (main.cpp slideAccent).
def home(sc, *, weather=True, cl_note=None, cl=38, cx=71, badge=1):
    window(sc, "Trang chủ", "clawd", True)
    sc.text("VT323-86", "14", 10, 30, X["BLACK"])
    dw = sc.width("VT323-86", "0")
    sc.text("VT323-86", ":", 10 + dw * 2, 30, X["BLACK"])
    sc.text("VT323-86", "32", 10 + dw * 3, 30, X["BLACK"])
    if weather:
        draw_icon(sc, "weather", 186, 32, 2, X["AMBER"])
    sc.text("JBMono-12B", "29°" if weather else "--°", 229, 66, X["SKY"] if weather else X["DIM"], "TR")
    sc.text("JBMono-11", "Thứ Tư 25/11", 10, 100, X["LABEL"])
    sc.text("JBMono-11", "Ít mây" if weather else "chưa có thời tiết", 229, 100,
            X["SKY"] if weather else X["DIM"], "TR")
    group_box(sc, 10, 124, 220, 64, "Hạn mức")
    _home_row(sc, 135, "Claude", cl, X["GREEN"], cl_note)
    _home_row(sc, 159, "Codex", cx, X["AMBER"])
    status_bar(sc, "192.168.100.40", "Còn 9G hôm nay")
    taskbar(sc, active="claude", badge=badge, accent=CORAL)


# ── AI hôm nay (ch_aidash.cpp) ──
def _ai_block(sc, i, mode, used):
    """mode 0 value, 1 loading, 2 bad credential ('Khóa'), 3 stale."""
    bx = (10, 124)[i]
    healthy = X["GREEN"]
    rem = 100 - used if used >= 0 else -1
    if mode == 2:
        s, c = "Khóa", X["RED"]
    elif mode == 1 or used < 0:
        s, c = "--", X["DIM"]
    else:
        s, c = f"{used}%", X["DIM"] if mode == 3 else xp_usage_color_left(rem, healthy)
    sc.text("VT323-44", s, bx + 8, 128, c)
    lit = mode in (0, 3)
    progress(sc, bx + 8, 164, 90, 12, used if lit and used >= 0 else 0,
             X["DIM"] if mode == 3 else xp_usage_color_left(rem, healthy), 1)


def aidash(sc, *, modes=(0, 0), used=(38, 71), credits="$4.20", left="Dùng Claude",
           right="CL 2G 14P · CX 3NG", left_color=None):
    window(sc, "AI hôm nay", "clawd", True)
    sc.text("JBMono-11", "Tín dụng Codex còn", 10, 28, X["LABEL"])
    sc.text("VT323-86", credits or "--", 10, 40, X["BLACK"] if credits else X["DIM"])
    group_box(sc, 10, 120, 106, 66, "Claude")
    group_box(sc, 124, 120, 106, 66, "Codex")
    for i in range(2):
        _ai_block(sc, i, modes[i], used[i])
    status_bar(sc, left, right, left_color)
    taskbar(sc, active="claude", badge=1, accent=CORAL)


# ── Xu hướng (ch_trend.cpp) ──
TREND_DAYS = ("T5", "T6", "T7", "CN", "T2", "T3", "T4")


def trend(sc, *, burn=((5.9, 10, 4, 1.9, 15, 7.9, 4.4), (2.5, 4.4, 6.9, 9, 3.4, 1.5, 1.9)),
          have_days=7):
    window(sc, "Xu hướng", "clawd", True)
    sc.text("JBMono-11", f"7 ngày {DOT} % hạn mức tuần", 10, 28, X["LABEL"])
    sc.outline(10, 44, 220, 130, X["FIELD_BORDER"])
    sc.rect(11, 45, 218, 128, X["WHITE"])
    colors = (X["RED"], X["LILAC"])
    if have_days >= 7:                       # legend (none while collecting — XP-Trend-Collecting)
        for k, tag in enumerate(("Claude", "Codex")):
            lx = 12 + k * 72
            sc.rect(lx, 48, 8, 8, colors[k])
            sc.text("JBMono-11", tag, lx + 12, 46, X["BLACK"])
    scale = max([10.0] + [v for b in burn for v in b if v is not None])
    for i in range(7):
        for k in range(2):
            v = burn[k][i]
            if v is None or v <= 0:
                continue
            h = min(102, max(2, int(v / scale * 102 + 0.5)))
            sc.rect(18 + i * 30 + k * 11, 164 - h, 10, h, colors[k])
    sc.hline(14, 164, 212, X["STATUS_LINE"])
    empty = 7 - have_days
    if have_days < 7 and empty >= 4:
        sc.text("JBMono-11", "Đang thu thập...", 15 + 15 * empty, 100, X["MUTED"], "TC")
    for i, d in enumerate(TREND_DAYS):
        sc.text("JBMono-11", d, 28 + i * 30, 177, X["MUTED"], "TC")
    if have_days < 7:
        status_bar(sc, f"Có {have_days} / 7 ngày", "")
    else:
        status_bar(sc, f"Hôm nay CL 9 {DOT} CX 4", "Đỉnh T2")
    taskbar(sc, active="claude", badge=1, accent=CORAL)


# ── Tác tử list (ch_attention.cpp paintList) ──
KIND_COLOR = {"approval": "AMBER", "error": "RED", "input": "SKY", "progress": "LILAC",
              "warning": "AMBER", "success": "GREEN"}


def _fit_dots(sc, fname, s, maxw):
    """ch_attention fitLine: cut whole characters, then '...'."""
    if sc.width(fname, s) <= maxw:
        return s
    while len(s) > 1:
        s = s[:-1]
        if sc.width(fname, s + "...") <= maxw:
            return s + "..."
    return s


def agents(sc, rows, right):
    """rows: (kind, title line, meta); the first row is selected when it waits on you."""
    window(sc, "Tác tử", "clawd", True)
    field(sc, 10, 28, 220, 162)
    n = len(rows)
    shown = 2 if n > 3 else n
    for i in range(shown):
        kind, line, meta = rows[i]
        y = 30 + i * 52
        sel = i == 0 and kind in ("approval", "input")
        if sel:
            sc.rect(11, y, 218, 50, X["SELECT"])
        sc.rect(18, y + 9, 8, 8, X[KIND_COLOR[kind]])
        sc.text("JBMono-12B", _fit_dots(sc, "JBMono-12B", line, 192), 32, y + 6,
                X["WHITE"] if sel else X["BLACK"])
        sc.text("JBMono-11", _fit_dots(sc, "JBMono-11", meta, 192), 32, y + 26,
                X["WHITE"] if sel else X["MUTED"])
        if i < 2 and not sel:
            sc.hline(11, y + 50, 218, X["ROW_LINE"])
    if n > shown:
        sc.text("JBMono-11", f"+ {n - shown} mục khác", 32, 30 + shown * 52 + 18, X["MUTED"])
    status_bar(sc, f"{n} mục", right)
    waiting = sum(1 for r in rows if r[0] in ("approval", "input"))
    taskbar(sc, active="claude", badge=waiting, accent=CORAL)


# ── Attention card (ch_attention.cpp paintCard) ──
CARD_EYES = {"approval": "wide", "success": "happy", "error": "sad", "warning": "wide"}
CARD_WINDOW = {"approval": "Cần duyệt", "input": "Lượt bạn", "success": "Xong", "error": "Lỗi",
               "progress": "Đang chạy"}


def card(sc, kind, *, header=f"CLAUDE {DOT} glimmer", title, detail="", status="", pct=None,
         walk=False):
    window(sc, CARD_WINDOW[kind], "clawd", False)
    kc = X[KIND_COLOR[kind]]
    sc.text("JBMono-11", header, 120, 30, X["LABEL"], "TC")
    clawd(sc, 66, 50, 6, CLAWD_ORANGE, bg=X["BODY"], eyes=CARD_EYES.get(kind, "open"),
          legs="walk" if walk else "stand")
    sc.text("JBMono-16B", _fit_dots(sc, "JBMono-16B", title, 216), 120, 120, kc, "TC")
    if detail:
        sc.text("JBMono-11", _fit_dots(sc, "JBMono-11", detail, 216), 120, 146, X["BLACK"], "TC")
    if kind in ("approval", "input"):
        sc.hline(10, 168, 220, X["STATUS_LINE"])
        sc.text("JBMono-11", status, 120, 176, kc, "TC")
    elif kind == "progress" and pct is not None:
        progress(sc, 30, 166, 180, 14, pct)
    flash = kind in ("approval", "input", "error")
    taskbar(sc, active="claude", flash=flash, badge=0 if flash else 1, accent=CORAL,
            progress=0 if flash else 0.4)


AGENT_ROWS = [("approval", f"Cần bạn {DOT} Bash", f"claude {DOT} glimmer {DOT} 2p"),
              ("progress", f"Tests {DOT} 64%", f"codex {DOT} api {DOT} 5p"),
              ("success", "Xong", f"claude {DOT} TieuMac3d {DOT} 12p")]


# ── Weather (ch_weather.cpp) ─────────────────────────────────────────────────
WEATHER_DAYS = [("30/24", "Mưa rào"), ("28/23", "Mưa")]


def weather(sc, *, stale=False, status="Mặt trời lặn 17:24", meta="", temp="29°", cond="Ít mây",
            hilo="31° / 24°", stack=("cảm giác 33°", "ẩm 74%", "gió 12km"), uv=7, days=WEATHER_DAYS):
    window(sc, "Thời tiết", "weather", True)
    for k, x in enumerate((10, 124)):
        group_box(sc, x, 144, 106, 46, "Kia" if k else "Mai")
    title_meta(sc, meta)
    status_bar(sc, status, "")
    dim = X["DIM"]
    sc.text("VT323-86", temp, 10, 28, dim if stale else X["BLACK"])
    ry = 32
    for line in stack:
        sc.text("JBMono-11", line, 229, ry, dim if stale else X["LABEL"], "TR")
        ry += 18
    if uv is not None:
        c = dim if stale else X["RED"] if uv >= 8 else X["AMBER"] if uv >= 6 else X["LABEL"]
        sc.text("JBMono-11", f"UV {uv}", 229, ry, c, "TR")
    sc.text("JBMono-13", fit(sc, "JBMono-13", cond, 142 - 12 - 2), 12, 100, dim if stale else X["SKY"])
    sc.text("JBMono-11", hilo, 12, 118, dim if stale else X["LABEL"])
    for k, (b, c) in enumerate(days):
        cx = (10, 124)[k] + 53
        sc.text("VT323-32", b, cx, 150, dim if stale else X["BLACK"], "TC")
        sc.text("JBMono-11", fit(sc, "JBMono-11", c, 100), cx, 175, dim if stale else X["MUTED"], "TC")
    taskbar(sc, active="weather", accent=T_SKY, badge=1)


def weather_loading(sc):
    window(sc, "Thời tiết", "weather", False)
    loading(sc, "Đang tải thời tiết...")
    taskbar(sc, active="weather", accent=T_SKY, badge=1)


def weather_error(sc):
    window(sc, "Thời tiết", "weather", False)
    dialog(sc, "warn", "Chưa có thời tiết", ["Máy chủ trả lỗi 500.", "", "Đang tự thử lại..."])
    taskbar(sc, active="weather", accent=T_SKY, badge=1)


# ── Forecast (ch_forecast.cpp) ───────────────────────────────────────────────
FORECAST = [("Ít mây", 24, 31), ("Mưa rào", 24, 30), ("Mưa", 23, 28)]


def forecast(sc, days=FORECAST):
    window(sc, "Dự báo", "weather", True)
    status_bar(sc, "3 ngày tới", "")
    field(sc, 10, 28, 220, 162)
    if not days:
        draw_icon(sc, "weather", 104, 70, 2, X["GROUP"])
        sc.text("JBMono-12B", "Chưa có dự báo", 120, 110, X["MUTED"], "TC")
        taskbar(sc, active="weather", accent=T_SKY, badge=1)
        return
    for i in (1, 2):
        sc.rect(11, 28 + i * 53, 218, 1, X["ROW_LINE"])
    gmin = min(d[1] for d in days); gmax = max(d[2] for d in days)
    rng = max(gmax - gmin, 1)
    for i, (cond, lo, hi) in enumerate(days):
        base = 28 + i * 53
        today = i == 0
        sc.rect(11, base + 1, 218, 52, X["WHITE"])
        if today:
            sc.rect(11, base + 2, 218, 51, X["ROW_HI"])
        sc.text("JBMono-12B", ("Nay", "Mai", "Kia")[i], 18, base + 8, X["SKY"] if today else X["BLACK"])
        sc.text("JBMono-11", fit(sc, "JBMono-11", cond, 112 - 21 - 18 - 4), 18, base + 28, X["MUTED"])
        sc.rect(118, base + 25, 74, 4, X["ROW_LINE"])
        x0 = 125 + int((lo - gmin) / rng * 59 + 0.5)
        x1 = 125 + int((hi - gmin) / rng * 59 + 0.5)
        x1 = max(x1, x0 + 4)
        if x1 > 192:
            x1 = 192; x0 = min(x0, x1 - 4)
        x0 = max(x0, 118)
        sc.rect(x0, base + 24, x1 - x0, 6, X["SKY"] if today else X["MUTED"])
        sc.text("JBMono-11", f"{lo}°", 112, base + 20, X["SKY"], "TR")
        sc.text("JBMono-11", f"{hi}°", 222, base + 20, X["RED"], "TR")
    taskbar(sc, active="weather", accent=T_SKY, badge=1)


# ── Clock (ch_clock.cpp) ─────────────────────────────────────────────────────
def clock(sc, hh="14", mm="32", ampm=None, date="Thứ Tư · 25/11", greet="chào buổi chiều, bạn"):
    window(sc, "Đồng hồ", "clock", True)
    status_bar(sc, "Tuần 48", "GMT+7")
    sc.text("JBMono-12B", date, 120, 30, X["BLACK"], "TC")
    field(sc, 20, 52, 200, 86)
    dw = sc.width("VT323-86", "0"); cw = sc.width("VT323-86", ":")
    apw = sc.width("JBMono-12B", "CH") + 2 if ampm else 0
    hhx = 120 - (dw * 4 + cw + apw) // 2
    sc.text("VT323-86", hh, hhx, 60, X["BLACK"])
    sc.text("VT323-86", ":", hhx + dw * 2, 60, X["BLACK"])
    mmx = hhx + dw * 2 + cw
    sc.text("VT323-86", mm, mmx, 60, X["BLACK"])
    if ampm:
        sc.text("JBMono-12B", ampm, mmx + dw * 2 + 2, 60 + 56 - 13, X["BLACK"])
    sc.text("JBMono-13", greet, 120, 152, X["GROUP_LABEL"], "TC")
    taskbar(sc, active="clock", accent=T_AMBER, badge=1)


# ── Night (ch_night.cpp): no window, no taskbar ──────────────────────────────
def night(sc, hh="23", mm="47", date="Thứ Tư 25/11"):
    sc.rect(0, 0, W, H, X["BLACK"])
    dw = sc.width("VT323-86", "0"); cw = sc.width("VT323-86", ":")
    hhx = (W - (dw * 4 + cw)) // 2
    ink = X["LABEL"]
    sc.text("VT323-86", hh, hhx, 70, ink)
    sc.text("VT323-86", ":", hhx + dw * 2, 70, ink)
    sc.text("VT323-86", mm, hhx + dw * 2 + cw, 70, ink)
    sc.text("JBMono-11", date, 120, 150, ink, "TC")


# ── Info (ch_info.cpp) ───────────────────────────────────────────────────────
INFO_ROWS = [("IP", "192.168.100.40"), ("SSID", "Anh Viet"), ("Sóng", "-58 dBm"), ("Đã chạy", "312P"),
             ("Bộ nhớ", "27K trống"), ("Khối lớn", "21K"), ("Firmware", "v0.23.0-glimmer"),
             ("Kênh", "9 / 13"), ("Cập nhật", "1P trước"), ("Lần tới", "sau 4P")]


def info(sc):
    window(sc, "Thông tin", "info", False)
    field(sc, 10, 28, 220, 180)
    sc.rect(82, 29, 1, 178, X["ROW_LINE"])
    for i, (lab, val) in enumerate(INFO_ROWS):
        y = 31 + (i * 35) // 2
        sc.text("JBMono-11", lab, 16, y, X["MUTED"])
        sc.text("JBMono-11", fit(sc, "JBMono-11", val, 228 - 88), 88, y, X["BLACK"])
    taskbar(sc, active=None, badge=1)


# ── Setup (ch_setup.cpp) ─────────────────────────────────────────────────────
def setup(sc, done=(False, False, True)):
    window(sc, "Cài đặt", "clawd", False)
    sc.text("JBMono-12B", "Hoàn tất cài đặt", 12, 30, X["BLACK"])
    sc.text("JBMono-11", f"Còn {3 - sum(done)} bước nữa là xong.", 12, 48, X["LABEL"])
    for y, ok, item in zip((72, 94, 116), done, ("Khóa Claude", "Token Codex", "Thời tiết, vị trí, giờ")):
        sc.outline(14, y, 13, 13, X["CHECK_BOX"])
        sc.rect(15, y + 1, 11, 11, X["WHITE"])
        if ok:
            for i, ty in enumerate((6, 7, 8, 7, 6, 5, 4)):
                sc.rect(18 + i, y + ty, 1, 3, X["CHECK"])
        sc.text("JBMono-11", item, 34, y, X["MUTED"] if ok else X["BLACK"])
    group_box(sc, 10, 150, 220, 40, "Mở trong trình duyệt")
    lw = sc.text("JBMono-12B", "glimmer.local", 18, 159, X["LINK"])
    sc.hline(18, 173, lw, X["LINK"])
    sc.text("JBMono-11", "192.168.100.40", 222, 176, X["MUTED"], "TR")
    taskbar(sc, active="claude", accent=CORAL, badge=1)


# ── Photo (ch_photo.cpp) ─────────────────────────────────────────────────────
def sample_photo():
    """Placeholder for a user photo: a 188x188 gradient with a sun and hills."""
    im = Image.new("RGB", (188, 188))
    p = im.load()
    for y in range(188):
        for x in range(188):
            p[x, y] = (40 + y * 120 // 187, 70 + x * 80 // 187, 170 - y * 90 // 187)
    d = ImageDraw.Draw(im)
    d.ellipse([120, 26, 160, 66], fill=(255, 210, 120))
    d.polygon([(0, 150), (60, 100), (120, 140), (188, 96), (188, 188), (0, 188)], fill=(40, 90, 60))
    return im


def photo(sc, i=2, n=5):
    window(sc, "Ảnh", "photo", False)
    sc.img.paste(sample_photo(), (26, 24))
    title_meta(sc, f"{i}/{n}")
    taskbar(sc, active="photo", accent=MINT, badge=1)


def photo_empty(sc):
    window(sc, "Ảnh", "photo", False)
    title_meta(sc, "")
    draw_icon(sc, "photo", 96, 52, 3, X["EMPTY_ICON"])
    sc.text("JBMono-16B", "Chưa có ảnh", 120, 100, X["MUTED"], "TC")
    sc.text("JBMono-11", "Gửi ảnh từ app glimmer", 120, 128, X["BLACK"], "TC")
    sc.text("JBMono-11", "hoặc", 120, 146, X["MUTED"], "TC")
    sc.text("JBMono-12B", "glimmer.local", 120, 162, X["LINK"], "TC")
    taskbar(sc, active="photo", accent=MINT, badge=1, progress=0)   # empty: no slide progress


SCREENS_A = [
    ("Claude", "XP-Claude-A · bình thường", lambda s: claude_xp(s), "XPClaudeA"),
    ("Claude · đang tải", "XP-Claude-Loading", lambda s: loading_xp(s, "Claude"), "XPClaudeLoading"),
    ("Claude · dữ liệu cũ", "XP-Claude-Stale · cũ 14P",
     lambda s: claude_xp(s, stale=True, meta="cũ 14P"), "XPClaudeStale"),
    ("Claude · khóa hết hạn", "XP-Claude-KeyExpired · còn số cũ",
     lambda s: claude_xp(s, meta="khóa lỗi", cred="expired"), "XPClaudeKeyExpired"),
    ("Claude · khóa bị từ chối", "XP-Claude-Rejected · chưa có số",
     lambda s: cred_card_xp(s, "Claude", "khóa lỗi", "error", "Khóa bị từ chối",
                            ["claude.ai từ chối khóa.", "Nhập khóa mới tại:"], "glimmer.local",
                            "192.168.100.40"), "XPClaudeRejected"),
    ("Claude · mất mạng", "XP-Claude-Offline",
     lambda s: cred_card_xp(s, "Claude", "", "warn", "Mất mạng",
                            ["Không tới được claude.ai.", "Kiểm tra Wi-Fi.", "", "Đang tự động thử lại..."]),
     "XPClaudeOffline"),
    ("Claude · chưa có project", "XP-Claude-NoProject · Clawd ngủ",
     lambda s: claude_xp(s, rows=[], eyes="sleep"), "XPClaudeNoProject"),
    ("Claude · đã xong hết", "XP-Claude-Done · Clawd ngủ",
     lambda s: claude_xp(s, eyes="sleep",
                         rows=[("glimmer", "done", "", "2P"), ("TieuMac3d", "done", "", "40P"),
                               ("api", "done", "", "1G")]), "XPClaudeDone"),
    ("Codex", "XP-Codex · bình thường", lambda s: codex_xp(s), "XPCodex"),
    ("Codex · đang tải", "XP-Codex-Loading", lambda s: loading_xp(s, "Codex"), "XPCodexLoading"),
    ("Codex · dữ liệu cũ", "XP-Codex-Stale · cũ 18P",
     lambda s: codex_xp(s, stale=True, meta="cũ 18P"), "XPCodexStale"),
    ("Codex · token hết hạn", "XP-Codex-Expired · chưa có số",
     lambda s: cred_card_xp(s, "Codex", "khóa lỗi", "error", "Token hết hạn",
                            ["Hết hạn ngày 20/11.", "Nhập token mới tại:"], "glimmer.local",
                            "192.168.100.40", accent="Codex"), "XPCodexExpired"),
]

SCREENS_B = [
    ("Trang chủ", "XP-Home", lambda s: home(s), "XPHome"),
    ("Trang chủ · khóa Claude lỗi", "XP-Home-KeyBad",
     lambda s: home(s, cl_note="Khóa bị từ chối"), "XPHomeKeyBad"),
    ("Trang chủ · chưa có thời tiết", "XP-Home-NoWeather", lambda s: home(s, weather=False), "XPHomeNoWeather"),
    ("AI hôm nay", "XP-AI", lambda s: aidash(s), "XPAI"),
    ("AI · đang tải", "XP-AI-Loading",
     lambda s: aidash(s, modes=(1, 1), used=(-1, -1), credits=None, left="Đang tải...",
                      right=f"CL -- {DOT} CX --"), "XPAILoading"),
    ("AI · khóa Claude lỗi", "XP-AI-KeyBad",
     lambda s: aidash(s, modes=(2, 0), left="Khóa Claude bị từ chối", right="",
                      left_color=X["BLACK"]), "XPAIKeyBad"),
    ("Xu hướng", "XP-Trend", lambda s: trend(s), "XPTrend"),
    ("Xu hướng · đang thu thập", "XP-Trend-Collecting",
     lambda s: trend(s, burn=((None,) * 5 + (3.92, 6.67), (None,) * 5 + (1.67, 2.94)), have_days=2),
     "XPTrendCollecting"),
    ("Tác tử", "XP-Agents", lambda s: agents(s, AGENT_ROWS, "1 cần duyệt"), "XPAgents"),
    ("Tác tử · không mục nào chờ", "XP-Agents-Idle",
     lambda s: agents(s, AGENT_ROWS[1:], "không mục nào chờ"), "XPAgentsIdle"),
    ("Thẻ · cần duyệt", "XP-Attention",
     lambda s: card(s, "approval", title="Cần bạn duyệt", detail=f"Bash {DOT} pio run -e nodemcuv2",
                    status=f"chờ bạn {DOT} 2P"), "XPAttention"),
    ("Thẻ · lượt bạn", "XP-Attention-Input",
     lambda s: card(s, "input", title="Lượt bạn", detail="Claude đang chờ câu trả lời",
                    status=f"chờ bạn {DOT} 45 giây"), "XPAttentionInput"),
    ("Thẻ · xong", "XP-Attention-Done",
     lambda s: card(s, "success", title="Xong rồi!", detail="Claude đã xong"), "XPAttentionDone"),
    ("Thẻ · lỗi", "XP-Attention-Error",
     lambda s: card(s, "error", title="build failed", detail=f"3 lỗi {DOT} ch_claude.cpp:120"),
     "XPAttentionError"),
    ("Thẻ · tiến độ", "XP-Attention-Progress",
     lambda s: card(s, "progress", header=f"CLAUDE {DOT} api", title="tests 64%",
                    detail=f"main {DOT} 4 phút", pct=64), "XPAttentionProgress"),
]

SCREENS_C = [
    ("Thời tiết", "XP-Weather", weather, "XPWeather"),
    ("Thời tiết · đang tải", "XP-Weather-Loading", weather_loading, "XPWeatherLoading"),
    ("Thời tiết · lỗi", "XP-Weather-Error · HTTP 500", weather_error, "XPWeatherError"),
    ("Thời tiết · cũ", "XP-Weather-Stale · 2 giờ",
     lambda s: weather(s, stale=True, meta="cũ 2G", status="Cập nhật 2 giờ trước"), "XPWeatherStale"),
    ("Dự báo", "XP-Forecast", forecast, "XPForecast"),
    ("Dự báo · chưa có", "XP-Forecast-Empty", lambda s: forecast(s, days=[]), "XPForecastEmpty"),
    ("Đồng hồ", "XP-Clock", clock, "XPClock"),
    ("Đêm", "XP-Night · không cửa sổ", night, "XPNight"),
    ("Thông tin", "XP-Info · không nút nào lõm", info, "XPInfo"),
    ("Cài đặt", "XP-Setup · chưa có khóa", setup, "XPSetup"),
    ("Ảnh", "XP-Photo · 2/5", photo, "XPPhoto"),
    ("Ảnh · chưa có ảnh", "XP-Photo-Empty", photo_empty, "XPPhotoEmpty"),
]


# ── the catalogue: (title, note, draw, design image under design/panel/screens/@2x) ──
SCREENS = [
    *SCREENS_A, *SCREENS_B, *SCREENS_C,
    ("Khởi động", "XP-Splash · ô 3 khối chạy (bước 3)", splash, "XPSplash"),
    ("Welcome", "XP-Connecting · đang kết nối Wi-Fi", connecting, "XPConnecting"),
    ("Đăng nhập", "XP-SetupMode · chế độ cài đặt Wi-Fi", setup_ap, "XPSetupMode"),
    ("Đang cập nhật", "XP-OtaProgress · nạp qua Wi-Fi", ota, "XPOtaProgress"),
    ("Chưa có kênh", "XP-NoChannels · mọi kênh tắt", no_channels, "XPNoChannels"),
]


def render(idx):
    sc = Screen()
    SCREENS[idx][2](sc)
    return sc.img


def sheet(indices, out, scale=2, cols=4, compare=False):
    """compare=True puts the design image (…/@2x/<name>.png) beside each render."""
    lab = ImageFont.truetype(str(ROOT / "tools" / "ttf" / "JetBrainsMono-Bold.ttf"), 22)
    sub = ImageFont.truetype(str(ROOT / "tools" / "ttf" / "JetBrainsMono-Regular.ttf"), 17)
    tw, th = W * scale, H * scale
    cell = tw * 2 + 8 if compare else tw
    pad, head = 24, 62
    rows = (len(indices) + cols - 1) // cols
    img = Image.new("RGB", (cols * (cell + pad) + pad, rows * (th + head + pad) + pad), (24, 22, 30))
    d = ImageDraw.Draw(img)
    for k, i in enumerate(indices):
        x = pad + (k % cols) * (cell + pad)
        y = pad + (k // cols) * (th + head + pad)
        title, note, _, design = SCREENS[i]
        d.text((x, y), f"{i + 1}. {title}", fill=(255, 210, 63), font=lab)
        d.text((x, y + 30), note, fill=(160, 150, 175), font=sub)
        frame = render(i).resize((tw, th), Image.NEAREST)
        d.rectangle([x - 3, y + head - 3, x + tw + 2, y + head + th + 2], outline=(70, 64, 84), width=3)
        img.paste(frame, (x, y + head))
        if compare and design:
            p = ROOT / "design" / "panel" / "screens" / "@2x" / f"{design}.png"
            if p.exists():
                ref = Image.open(p).convert("RGB").resize((tw, th), Image.NEAREST)
                img.paste(ref, (x + tw + 8, y + head))
    img.save(out)
    return img.size


if __name__ == "__main__":
    args = sys.argv[1:]
    compare = "--compare" in args
    args = [a for a in args if a != "--compare"]
    out = args[0] if args else "screens.png"
    pick = [int(a) - 1 for a in args[1:]] or list(range(len(SCREENS)))
    cols = (2 if compare else 4)
    print(sheet(pick, out, cols=min(cols, len(pick)), compare=compare))
