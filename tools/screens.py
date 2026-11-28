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
    WELCOME_BAND="00309C", LINK="0066CC", TITLE_EDGE="003DB5", GROUP_LABEL="0046D5", FRAME="0047D3",
    TITLE_DARK="0049D6", TITLE="0058EE", FLAG_BLUE="05A6F0", TITLE_SHADOW="0A246A", SKY="0A6ACF",
    TRAY="0F8BE8", TRAY_EDGE="1042AF", BTN_PRESSED_EDGE="163E91", BOOT_BLOCK_LO="1A4DB8", BTN_EDGE="1A50C8",
    TASK_DARK="1C4FBF", CHECK_BOX="1C5180", BTN_PRESSED="1E4FB5", START_SHADOW="1E5E1E", ICON_INFO="1F6FE0",
    CHECK="21A121", TASK="245EDC", WELCOME_SHADOW="2A3F8F", TITLE_LIGHT="2B80F5", USER_SEL="2C55C4",
    START_DARK="2E7D2E", GREEN="2E8A2E", BOOT_BLOCK="2F6FE6", SELECT="316AC5", TASK_LIGHT="3A7DEB",
    START="3A9E3A", BAND_EDGE="3B4FA8", BTN="3C81F3", BAR="3CC63C", TITLE_HI="3D95FF", TRAY_HI="3FA9F5",
    LABEL="4D4D4D", WELCOME="5A7EDC", TASK_HI="5A9BF6", START_HI="5CC15C", USER_SEL_HI="5F84E3",
    MUTED="6F6F6F", LILAC="7A44C8", DIVIDER_FADE="7D9BE8", FIELD_BORDER="7F9DB9", WELCOME_LINE="7FA4F0",
    FLAG_GREEN="81BC06", LAPTOP="808080", BOOT_BLOCK_HI="9BC0FA", BAND_EDGE_WARM="9C6A6A", DIM="ACA899", STATUS_LINE="ACA899",
    BOOT_GREY="B2B2B2", FLASH_EDGE="B8661E", EMPTY_ICON="B8B4A0", DIVIDER="B9CBF5", RED="C1272D",
    AMBER="C98A00", WELCOME_SUB="C9D6F7", GROUP="D0D0BF", ICON_ERROR="D8341E", ROW_HI="DCE6F8",
    CLOSE="E0523C", ROW_LINE="E4E4E4", BODY="ECE9D8", FLASH="F0A030", WELCOME_ORANGE="F28F2E",
    ICON_WARN="F2C200", USER_PIC="F2C27A", FLAG_RED="F35325", FLAG_YELLOW="FFBA08", INFO_BAR="FFFFE1",
    WHITE="FFFFFF", BLACK="000000",
    SELECT_ICON="98B4E2", SELECT_CLAWD="85719E", CAPTION_OFF="7FA4F0", MENU_BORDER="ACA899").items()}
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
            elif 1 <= j <= 3 and 3 <= i <= 14:   # eye holes: always black (P-2026-11-26.11)
                sc.rect(x + i * scale, y + j * scale, scale, scale, X["BLACK"])
            elif bg is not None:
                sc.rect(x + i * scale, y + j * scale, scale, scale, bg)
    if kw.get("eyes") == "happy":
        h = max(scale // 2, 1)
        for hx_, hy in HAPPY_HOLES:
            sc.rect(x + hx_ * scale // 2, y + hy * scale // 2, h, h, X["BLACK"])


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
    if icon == "clawd":   # eye holes black (xp.cpp drawIcon, P-2026-11-26.11)
        head = rows[0]
        for r in (1, 2, 3):
            for c in range(w):
                bit = 1 << (w - 1 - c)
                if (head & bit) and not (rows[r] & bit):
                    sc.rect(x + c * scale, y + r * scale, scale, scale, X["BLACK"])


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
    elif kind == "o":   # □ off: windows never resize (P-2026-11-26.14, xpCaptionOff)
        sc.outline(x + 4, y + 3, 8, 8, X["CAPTION_OFF"])
        sc.hline(x + 4, y + 4, 8, X["CAPTION_OFF"])
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
    elif icon == "mines":                                   # P-2026-11-27.25: black mine + glint at (6, 5)
        run_icon(sc, _mines_icon("TitleMine"), 6, 5)
    elif icon in COLOR_ICON:                                # P-2026-11-28.28–.32
        color_icon(sc, icon, 4, 3)
    elif icon:
        w, h, _ = ICONS[icon]
        draw_icon(sc, icon, 13 - w // 2, 11 - h // 2, 1, X["WHITE"])
    title_text(sc, t)
    # P-2026-11-27.24: _ / × hot under the mouse (_HOT[0] = "min" / "close" / a taskbar slot).
    caption_button(sc, 184, X["TITLE_HI"] if _HOT[0] == "min" else X["TITLE_LIGHT"], "_")
    caption_button(sc, 202, X["TITLE_LIGHT"], "o")
    caption_button(sc, 220, hx("F06A50") if _HOT[0] == "close" else X["CLOSE"], "x")


_HOT = [None]   # XP::hot(): None, "min", "close" or a taskbar slot index


# ── Mouse cursor (channels/cursor.cpp, cursor_core.h; P-2026-11-27.24 XP-Pointer) ──
def _cursor_rows(name):
    src = (Path(__file__).resolve().parent.parent / "src" / "data" / "cursor_core.h").read_text(encoding="utf-8")
    body = re.search(r"constexpr const char\* " + name + r"\[\] = \{(.*?)\};", src, re.S).group(1)
    return re.findall(r'"([BW.]+)"', body)


CURSOR = {"arrow": (_cursor_rows("kArrowRows"), 0, 0), "hand": (_cursor_rows("kHandRows"), 5, 0)}


def cursor(sc, shape, x, y, frame=0):
    """Cursor::overlay: the glyph with its hotspot at (x, y); 'wait' = arrow + hourglass."""
    rows, hx_, hy_ = CURSOR["arrow" if shape == "wait" else shape]
    for r, row in enumerate(rows):
        for c, k in enumerate(row):
            if k != ".":
                sc.pixel(x - hx_ + c, y - hy_ + r, X["BLACK"] if k == "B" else X["WHITE"])
    if shape == "wait":
        inks = {"X": X["BLACK"], "W": X["WHITE"], "S": X["AMBER"]}
        if frame % 4 == 3:
            draw_art(sc, "kGlass3", x + 8, y + 11, inks)
        else:
            draw_art(sc, f"kGlass{frame % 4}", x + 10, y + 9, inks)


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


def group_label(sc, x, y, label, clear_w=0, bg=None):
    tw = sc.width("JBMono-11", label) if label else 0
    sc.rect(x + 4, y - 6, max(tw + 6, clear_w), 13, bg or X["BODY"])
    if tw:
        sc.text("JBMono-11", label, x + 7, y - 6, X["GROUP_LABEL"])


def group_box(sc, x, y, w, h, label, bg=None):
    sc.outline(x, y, w, h, X["GROUP"])
    group_label(sc, x, y, label, bg=bg)


def tabs(sc, labels, sel, page_h=169, pad=10):
    """XP::tabs (P-2026-11-26.17 Luna tab control)."""
    sc.outline(6, 41, 228, page_h, X["FIELD_BORDER"])
    sc.rect(7, 42, 226, page_h - 2, X["WHITE"])
    sc.rect(6, 26, 228, 15, X["BODY"])
    x, sx, sw = 6, 6, 0
    for i, t in enumerate(labels):
        w = sc.width("JBMono-11", t) + pad
        if i == sel:
            sx, sw = x, w
        else:
            sc.outline(x, 28, w - 1, 14, X["FIELD_BORDER"])
            sc.rect(x + 1, 29, w - 3, 12, X["ROW_LINE"])
            sc.text("JBMono-11", t, x + pad // 2, 29, X["BLACK"])
        x += w
    sc.hline(sx, 26, sw, X["WELCOME_ORANGE"])
    sc.rect(sx, 27, sw, 2, X["FLAG_YELLOW"])
    sc.vline(sx, 27, 15, X["FIELD_BORDER"])
    sc.vline(sx + sw - 1, 27, 15, X["FIELD_BORDER"])
    sc.rect(sx + 1, 29, sw - 2, 13, X["WHITE"])
    sc.text("JBMono-11", labels[sel], sx + pad // 2, 29, X["BLACK"])


def push_button(sc, x, y, w, h, label, look="up", ink=None, fname="JBMono-11", dy=3):
    """XP::pushButton (P-2026-11-28.28–.31): up / dim / hot / down."""
    line, face, foot = hx("003C74"), hx("F4F3EE"), hx("D6D0C5")
    down = look == "down"
    if down:
        face = hx("DCD8CC")
    sc.hline(x + 1, y, w - 2, line)
    sc.hline(x + 1, y + h - 1, w - 2, line)
    sc.vline(x, y + 1, h - 2, line)
    sc.vline(x + w - 1, y + 1, h - 2, line)
    sc.rect(x + 1, y + 1, w - 2, h - 2, face)
    if down:
        sc.rect(x + 1, y + 1, w - 2, 2, hx("A7A495"))
    else:
        sc.rect(x + 1, y + h - 3, w - 2, 2, foot)
    if look == "hot":
        sc.hline(x + 1, y + 1, w - 2, hx("FFF0CF"))
        sc.hline(x + 1, y + 2, w - 2, hx("F9B348"))
        sc.hline(x + 1, y + h - 3, w - 2, hx("F9B348"))
        sc.vline(x + 1, y + 2, h - 4, hx("F9B348"))
        sc.vline(x + w - 2, y + 2, h - 4, hx("F9B348"))
        sc.hline(x + 1, y + h - 2, w - 2, hx("E59700"))
    if label:
        c = X["DIM"] if look == "dim" else (ink or X["BLACK"])
        sc.text(fname, label, x + w // 2, y + dy + (1 if down else 0), c, "TC")


def wx_icon(sc, code, x, y, big):
    """XP::weatherIcon: sun (0–1), partly (2–3, fog), rain (the rest)."""
    kind = "Sun" if code <= 1 else "Partly" if code <= 3 or code in (45, 48) else "Rain"
    inks = {"Y": X["ICON_WARN"], "A": X["AMBER"], "G": X["FIELD_BORDER"], "W": X["WHITE"], "B": X["ICON_INFO"]}
    draw_art(sc, f"kWx{kind}{32 if big else 16}", x, y, inks)


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


# ── P-2026-11-26.16 art (xp.cpp, one char per pixel, '.' = transparent) ──
def _xp_art():
    src = (Path(__file__).resolve().parent.parent / "src" / "channels" / "xp.cpp").read_text(encoding="utf-8")
    return {m[1]: (int(m[3]), int(m[4]), m[2])
            for m in re.finditer(r'const char (k\w+)\[\] PROGMEM = "([^"]+)";\s*// (\d+)×(\d+)', src)}


XP_ART = _xp_art()


def draw_art(sc, name, x, y, inks):
    w, h, a = XP_ART[name]
    for r in range(h):
        for c in range(w):
            k = a[r * w + c]
            if k in inks:
                sc.pixel(x + c, y + r, inks[k])


def wait_cursor(sc, frame=0, over=False):
    """XP::waitCursor: arrow tip (132, 160) + hourglass frame (frame 3 flat at (140, 171))."""
    if not over:
        sc.rect(132, 160, 21, 22, X["BODY"])
    draw_art(sc, "kArrow", 132, 160, {"X": X["BLACK"], "W": X["WHITE"]})
    inks = {"X": X["BLACK"], "W": X["WHITE"], "S": X["AMBER"]}
    if frame % 4 == 3:
        draw_art(sc, "kGlass3", 140, 171, inks)
    else:
        draw_art(sc, f"kGlass{frame % 4}", 142, 169, inks)


PAPER_Y = (48, 43, 40, 40, 43, 48)


def loading(sc, label, step=5, source=None, paper=None, glass=0):
    """XP::loading + loadingStep (P-2026-11-26.16 XP File Download): globe, paper, folder, label, box, source."""
    draw_art(sc, "kGlobe", 30, 36, {"E": X["TITLE_EDGE"], "B": X["ICON_INFO"], "L": X["GREEN"]})
    draw_art(sc, "kFolder", 186, 38, {"D": X["AMBER"], "F": X["USER_PIC"]})
    i = (step % 6) if paper is None else paper
    draw_art(sc, "kPaper", 60 + 20 * i, PAPER_Y[i], {"B": X["FIELD_BORDER"], "W": X["WHITE"], "L": X["DIM"]})
    sc.text("JBMono-12B", label, 120, 92, X["BLACK"], "TC")
    marquee(sc, 50, 116, 140, 14, step)
    if source:
        sc.text("JBMono-11", source, 120, 140, X["MUTED"], "TC")
    wait_cursor(sc, glass)


def zoom_bands(sc, slot, steps=(1, 2, 3, 4)):
    """XP::zoom: the title-bar bands between taskbar slot [slot]'s button and (0, 0, 240×22)."""
    bx = 71 + 30 * slot
    lerp = lambda a, b, i: (2 * (a * (5 - i) + b * i) + 5) // 10
    for i in steps:
        x, y, w, h = lerp(bx, 0, i), lerp(217, 0, i), lerp(28, 240, i), lerp(20, 22, i)
        sc.rect(x, y, w, h, X["TITLE"])
        sc.hline(x, y, w, X["TITLE_HI"])
        sc.hline(x, y + 1, w, X["TITLE_LIGHT"])
        sc.hline(x, y + h - 1, w, X["TITLE_EDGE"])


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


# main.cpp barState / XPCore::fillBar (P-2026-11-26.14): one button per open window.
PROG_ICON = {"Photo": "photo", "Weather": "weather", "Forecast": "weather", "Clock": "clock", "Info": "info",
             "Mines": "mines", "TaskMgr": "taskmgr", "Display": "display", "Calc": "calc", "Explorer": "computer",
             "Pictures": "pictures", "Trash": "trash", "TrashFull": "trash_full"}
_BTN_PROG = {"claude": "Claude", "photo": "Photo", "weather": "Weather", "clock": "Clock"}


def taskbar(sc, *, active="claude", windows=None, top=None, flash=False, badge=1, clock="14:32",
            tray_weather=False, start_down=False, **_old):
    """Taskbar::draw. windows = open programs in opening order (last 4 shown — last 3 with the
    weather tray, P-2026-11-26.15), top = the one on top (pressed while it shows). Legacy callers
    pass active = the button of the only open window."""
    if windows is None:
        windows = [_BTN_PROG[active]] if active else []
        top = windows[0] if windows else None
    tray_x = 176 if tray_weather else 196
    windows = windows[-(3 if tray_weather else 4):]
    task_bands(sc, 0, tray_x, 0, 25)
    for r in range(26):                                   # start button
        edge = 67 - START_INSET[r]
        if start_down:   # P-2026-11-26.20: pressed while the Start menu is open
            c = X["START_DARK"] if r <= 1 else X["GREEN"] if r <= 22 else X["START_DARK"]
        else:
            c = X["START_HI"] if r <= 1 else X["START"] if r <= 22 else X["START_DARK"]
        sc.rect(0, 214 + r, edge, 1, c)
        sc.pixel(edge, 214 + r, X["START_DARK"])
    draw_flag(sc, 7, 221, 1)
    sc.bits(START_BITS, 41, 26, 222, X["START_SHADOW"])
    sc.bits(START_BITS, 41, 25, 221, X["WHITE"])
    for slot, prog in enumerate(windows):
        x = 71 + 30 * slot
        claude = prog == "Claude"
        look = "flash" if claude and flash else "pressed" if prog == top else "normal"
        edge, fill = {"flash": ("FLASH_EDGE", "FLASH"), "pressed": ("BTN_PRESSED_EDGE", "BTN_PRESSED"),
                      "normal": ("BTN_EDGE", "BTN")}[look]
        sc.rect(x, 217, 28, 20, X[edge])
        sc.rect(x + 1, 218, 26, 18, X["TASK_HI"] if look == "normal" and _HOT[0] == slot else X[fill])
        icon = PROG_ICON.get(prog, "clawd")
        if icon == "clawd":
            draw_icon(sc, "clawd", x + 5, 222, 1, X["WHITE"] if look == "flash" else CLAWD_ORANGE)
        elif icon in COLOR_ICON:                            # P-2026-11-28.28–.32
            color_icon(sc, icon, x + 6, 220)
        elif icon == "mines":                               # white mine at (button + 7, 220)
            pal, runs = _mines_icon("TitleMine")
            for xx, yy, ww, c in runs:
                if pal[c] == hx("000000"):
                    sc.rect(x + 7 + xx, 220 + yy, ww, 1, X["WHITE"])
        else:
            w, h, _ = ICONS[icon]
            draw_icon(sc, icon, x + 14 - w // 2, 227 - h // 2, 1, X["WHITE"])
        if claude and not flash and badge > 0:
            sc.rect(x + 19, 215, 7, 9, T_AMBER)
            sc.rect(x + 18, 216, 9, 7, T_AMBER)
            for r, row in enumerate(DIGITS[min(badge, 10)]):
                for c in range(3):
                    if row >> (2 - c) & 1:
                        sc.pixel(x + 21 + c, 217 + r, BG)
    sc.rect(tray_x, 214, 240 - tray_x, 26, X["TRAY"])
    sc.vline(tray_x, 214, 26, X["TRAY_EDGE"])
    sc.hline(tray_x + 1, 214, 239 - tray_x, X["TRAY_HI"])
    if tray_weather:
        draw_icon(sc, "weather", 180, 220, 1, X["ICON_WARN"])
    sc.text("JBMono-11", clock, 218, 221, X["WHITE"], "TC")


# ── Context menus (channels/xp_menu.cpp, P-2026-11-26.14 XP-Menu) ──
MENU_DESK = [("Sắp xếp biểu tượng", False, True), ("Làm mới", False, False), None, ("Dán", True, False),
             ("Dán lối tắt", True, False), None, ("Mới", True, True), None, ("Thuộc tính", False, False)]
MENU_GLYPH = {
    "restore": [(7, 5, 5, 2), (11, 7, 1, 3), (10, 9, 1, 1), (5, 7, 5, 2), (5, 9, 1, 3), (9, 9, 1, 3), (5, 11, 5, 1)],
    "min": [(6, 10, 5, 2)],
    "max": [(5, 5, 7, 2), (5, 7, 1, 5), (11, 7, 1, 5), (5, 11, 7, 1)],
    "close": [(5, 5, 2, 1), (10, 5, 2, 1), (6, 6, 2, 1), (9, 6, 2, 1), (7, 7, 3, 1), (7, 8, 3, 1), (7, 9, 3, 1),
              (6, 10, 2, 1), (9, 10, 2, 1), (5, 11, 2, 1), (10, 11, 2, 1)],
}


def menu(sc, kind, x, y, minimized=False):
    """XPMenu::draw: kind 'desktop' (166×127) or 'window' (128×113), clamped inside y ≤ 213."""
    w, h = (166, 127) if kind == "desktop" else (128, 113)
    x, y = max(0, min(x, 240 - w)), max(0, min(y, 214 - h))
    sc.rect(x, y, w, h, X["MENU_BORDER"])
    sc.rect(x + 1, y + 1, w - 2, h - 2, X["WHITE"])
    rows = MENU_DESK if kind == "desktop" else [
        ("Khôi phục", not minimized, False, "restore"), ("Di chuyển", True, False, None),
        ("Kích thước", True, False, None), ("Thu nhỏ", minimized, False, "min"), ("Phóng to", True, False, "max"),
        None, ("Đóng", False, False, "close")]
    iy = y + 2
    for r in rows:
        if r is None:
            sc.hline(x + 2, iy + 3, w - 4, X["MENU_BORDER"])
            iy += 7
            continue
        label, dim, arrow = r[0], r[1], r[2]
        c = X["MENU_BORDER"] if dim else X["BLACK"]
        bold = label == "Đóng"
        sc.text("JBMono-12B" if bold else "JBMono-11", label, x + 17, iy + (1 if bold else 2), c)
        if arrow:
            for k in range(4):
                sc.vline(x + w - 10 + k, iy + 5 + k, 7 - 2 * k, c)
        if len(r) > 3 and r[3]:
            for gx, gy, gw, gh in MENU_GLYPH[r[3]]:
                sc.rect(x + gx, iy + gy, gw, gh, c)
        iy += 17
    if kind == "window":
        sc.text("JBMono-11", "Alt+F4", x + w - 17, y + h - 17, X["BLACK"], "TR")


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


def _design_qr():
    """The QR modules of design/panel/source/XP-SetupMode.dc.html (same payload; the firmware's
    library may pick another mask — same size and content)."""
    src = (ROOT / "design" / "panel" / "source" / "XP-SetupMode.dc.html").read_text(encoding="utf-8")
    m = re.search(r'viewBox="0 0 37 37"[^>]*><path fill="#000000" d="([^"]*)"', src)
    return [(int(x), int(y)) for x, y in re.findall(r"M(\d+) (\d+)h", m.group(1))] if m else []


def setup_ap(sc, ap="glimmer-setup", ip="192.168.4.1"):
    # P-2026-11-28.26: QR in the middle, logo in the top band, AP name in the bottom band.
    welcome_chrome(sc)
    draw_flag(sc, 8, 3, 2)
    italic(sc, "kWindowBits", 63, 12, 40, 9)
    sc.text("JBMono-11", "xp", 110, 8, X["WELCOME_ORANGE"])
    sc.rect(46, 35, 148, 148, X["WHITE"])
    for mx, my in _design_qr():
        sc.rect(46 + mx * 4, 35 + my * 4, 4, 4, X["BLACK"])
    sc.text("JBMono-11", "Quét mã bằng app glimmer", 120, 187, X["WHITE"], "TC")
    sc.rect(8, 218, 14, 14, X["WHITE"])
    sc.rect(9, 219, 12, 12, X["CLOSE"])
    sc.rect(14, 221, 2, 5, X["WHITE"])
    sc.rect(11, 223, 1, 5, X["WHITE"])
    sc.rect(18, 223, 1, 5, X["WHITE"])
    sc.rect(12, 228, 6, 1, X["WHITE"])
    sc.text("JBMono-11", "Cài đặt Wi-Fi", 28, 219, X["WHITE"])
    sc.text("JBMono-11", ap, 141, 219, X["WELCOME_SUB"])


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

# Clawd at work (ch_claude.cpp paintWorkFrame, src/ui/clawd_work.h, P-2026-11-26.13):
# 2 bits / cell (0 body, 1 Clawd, 2 eye, 3 laptop), 23×13 cells of 4 px at (136, 30).
_SRC_WORK = (ROOT / "src" / "ui" / "clawd_work.h").read_text(encoding="utf-8")
_WORK = [[[int(v, 16) for v in re.findall(r"0x([0-9A-Fa-f]{2})", r)]
          for r in re.findall(r"\{(0x[^}]*)\}", blk)]
         for blk in re.findall(r"// GIF frame \d+\n(.*?)\n    \}", _SRC_WORK, re.S)]
WORK_LOOP0 = 10     # clawd_work_core.h kLoopSlot[0] (GIF frame 19)


def clawd_work(sc, slot):
    cols = [X["BODY"], CLAWD_ORANGE, X["BLACK"], X["LAPTOP"]]
    for j, row in enumerate(_WORK[slot]):
        for i in range(23):
            c = (row[i >> 2] >> (6 - 2 * (i & 3))) & 3
            sc.rect(136 + i * 4, 30 + j * 4, 4, 4, cols[c])


def xp_usage_color(pct, healthy):
    """chrome.h xpUsageColor: remaining ≤ 20 % red, ≤ 50 % amber, else healthy."""
    if pct < 0:
        return X["DIM"]
    rem = 100 - pct
    return X["RED"] if rem <= 20 else X["AMBER"] if rem <= 50 else healthy


def hero(sc, pct, color, bar_color, pad_y, clear_r, drop_100=False):
    """paintHero (Claude / Codex): VT323-86 digits + VT323-44 "%" + 220×14 bar."""
    s = f"{pct}" if pct >= 0 else "--"
    sc.rect(10, 40, clear_r - 10, 102 - 40, X["BODY"])
    hw = sc.text("VT323-86", s, 10, 40, color)
    if len(s) < 3 or not drop_100:
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
    hero(sc, pct, X["DIM"] if dim else X["BLACK"], bc, 2, 132, True)   # digits black (P-2026-11-26.11)
    if eyes == "work":   # at work: first typing frame (P-2026-11-26.13)
        clawd_work(sc, WORK_LOOP0)
    else:
        clawd(sc, 156, 44 if asleep else 36, 4, bg=X["BODY"], eyes=eyes)
    if asleep:   # Zz frame 6 (kZz[6] = z4 at (200, 30), §17 P-2026-11-26.13)
        for j, row in enumerate(ZZ_Z4):
            for i in range(4):
                if row & (1 << (3 - i)):
                    sc.rect(200 + i * 2, 30 + j * 2, 2, 2, X["MUTED"])
    sc.text("JBMono-12B", reset, 229, 84, X["DIM"] if dim else X["RED"], "TR")
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


LOAD_SOURCE = {"Claude": "từ claude.ai", "Codex": "từ chatgpt.com", "Thời tiết": "từ open-meteo.com"}


def loading_xp(sc, title, badge=1, step=5, paper=None, glass=0):
    window(sc, title, "clawd")
    loading(sc, "Đang tải...", step=step, source=LOAD_SOURCE.get(title), paper=paper, glass=glass)
    taskbar(sc, active="claude", badge=badge, accent=slide_accent(title))


# ── Codex (ch_codex.cpp) ───────────────────────────────────────────────────
def codex_xp(sc, *, pct=41, reset="3NG", tag="Spark", sec="2G 14P", resets="còn 2 · 3NG",
             pace="~70% khi đặt lại", pace_red=False, credits=None, stale=False, meta="", cred=None, badge=1):
    window(sc, "Codex", "clawd")
    if meta:
        title_meta(sc, meta)
    sc.text("JBMono-11", "Hạn mức tuần", 10, 28, X["LABEL"])
    hc = X["DIM"] if stale else xp_usage_color(pct, X["LILAC"])
    hero(sc, pct, X["DIM"] if stale else X["BLACK"], hc, 1, 150)   # digits black (P-2026-11-26.11)
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


# ── Home = the XP desktop (ch_home.cpp, P-2026-11-26.12) ──
_DESK = (ROOT / "src" / "ui" / "desk_wallpaper.h").read_text(encoding="utf-8")


def _desk_wallpaper():
    """The fallback wallpaper from the generated header (tools/deskwall.py)."""
    pal_src = _DESK[_DESK.index("kDeskPal[kDeskPalN]"):_DESK.index("};")]
    pal = [hx(m) for m in re.findall(r"// #([0-9A-F]{6})", pal_src)]
    runs_src = _DESK[_DESK.index("kDeskRuns[kDeskRunCount * 2]"):]
    runs_src = runs_src[runs_src.index("{") + 1:runs_src.index("};")]
    v = [int(t) for t in re.findall(r"\d+", runs_src)]
    im = Image.new("RGB", (240, 214))
    p = im.load()
    x = y = 0
    for i in range(0, len(v), 2):
        for k in range(v[i + 1]):
            p[x + k, y] = pal[v[i]]
        x += v[i + 1]
        if x >= 240:
            x, y = 0, y + 1
    return im


DESK_TERM = [0xFFFF, 0x8001, 0xFFFF, 0x8001, 0xA001, 0x9001, 0xA701, 0x8001, 0x8001, 0xFFFF]
DESK_PROMPT = [0x20, 0x10, 0x27]
DESK_TRASH = [0x07F8, 0x0FFC, 0x1FFE, 0x0AA8, 0x0AA8, 0x0AA8, 0x0AA8, 0x0AA8, 0x0AA8, 0x07FC]


# XPCore::deskIcons (P-2026-11-26.14 XP-Desk): column 0 Claude, Codex, Ảnh, trash; column 1 Thời tiết, Đồng hồ.
def desk_icons(skills, one_col=True):
    """XPCore::deskIcons — P-2026-11-26.17: one column x 40, no Weather / Clock (older designs: one_col=False).
    P-2026-11-27.25: Dò mìn before the trash, or column 2 (120, 8) when column 1 has 4 already."""
    col0 = (["Claude", "Codex"] if "agent" in skills else []) + (["Photo"] if "photo" in skills else [])
    if "fun" in skills and len(col0) + 2 <= 4:
        col0.append("Mines")
    col0.append(None)
    if "fun" in skills and "Mines" not in col0:
        return [(p, 40, 8 + 48 * i) for i, p in enumerate(col0)] + [("Mines", 120, 8)]
    col1 = [] if one_col else (["Weather"] if "weather" in skills else []) + (["Clock"] if "clock" in skills else [])
    return [(p, 40, 8 + 48 * i) for i, p in enumerate(col0)] + [(p, 120, 8 + 48 * i) for i, p in enumerate(col1)]


def balloon_xp(sc, line1, line2):
    """ch_home.cpp paintBalloon (P-2026-11-26.15, XP notification balloon): box 140×62 at (96, 138)
    with stepped corners, tail from the bottom x 178..190 to its tip (190, 211), × button."""
    bx, by, bw, bh = 96, 138, 140, 62
    y1 = by + bh - 1
    sc.hline(bx + 2, by, bw - 4, X["BLACK"])
    sc.hline(bx + 1, by + 1, bw - 2, X["BLACK"])
    sc.hline(bx + 2, by + 1, bw - 4, X["INFO_BAR"])
    sc.rect(bx, by + 2, bw, bh - 4, X["BLACK"])
    sc.rect(bx + 1, by + 2, bw - 2, bh - 4, X["INFO_BAR"])
    sc.hline(bx + 1, y1 - 1, bw - 2, X["BLACK"])
    sc.hline(bx + 2, y1 - 1, bw - 4, X["INFO_BAR"])
    sc.hline(bx + 2, y1, bw - 4, X["BLACK"])
    sc.hline(179, y1, 11, X["INFO_BAR"])
    for y in range(y1 + 1, 212):
        x0 = 178 + (y - y1 - 1)
        sc.hline(x0, y, 190 - x0 + 1, X["INFO_BAR"])
        sc.pixel(x0, y, X["BLACK"])
        sc.pixel(190, y, X["BLACK"])
    draw_icon(sc, "weather", 102, 144, 1, X["AMBER"])
    sc.text("JBMono-12B", "Thời tiết", 122, 144, X["BLACK"])
    sc.rect(220, 143, 12, 12, X["DIM"])
    sc.rect(221, 144, 10, 10, X["WHITE"])
    for k in range(6):
        sc.pixel(223 + k, 146 + k, X["BLACK"])
        sc.pixel(228 - k, 146 + k, X["BLACK"])
    sc.text("JBMono-11", fit(sc, "JBMono-11", line1, 132), 102, 164, X["BLACK"] if line2 else X["DIM"])
    if line2:
        sc.text("JBMono-11", fit(sc, "JBMono-11", line2, 132), 102, 178, X["LABEL"])


# src/ui/desk_icons.h (tools/deskicons.py, P-2026-11-26.19): XP colour icons, runs of palette colours.
_SRC_DESKICONS = (ROOT / "src" / "ui" / "desk_icons.h").read_text(encoding="utf-8")


def _desk_icon(name):
    pal_src = re.search(rf"k{name}Pal\[\] PROGMEM = \{{(.*?)\}};", _SRC_DESKICONS, re.S).group(1)
    pal = [hx(h) for h in re.findall(r"/\* #([0-9A-F]{6}) \*/", pal_src)]
    runs_src = re.search(rf"k{name}Runs\[\] PROGMEM = \{{(.*?)\n\}};", _SRC_DESKICONS, re.S).group(1)
    runs = [tuple(int(v) for v in m) for m in re.findall(r"\{(\d+), (\d+), (\d+), (\d+)\}", runs_src)]
    return pal, runs


# src/ui/mines_icons.h (P-2026-11-27.25, tools/minesicons.py).
_SRC_MINESICONS = (ROOT / "src" / "ui" / "mines_icons.h").read_text(encoding="utf-8")


def _mines_icon(name):
    pal_src = re.search(rf"k{name}Pal\[\] PROGMEM = \{{(.*?)\}};", _SRC_MINESICONS, re.S).group(1)
    pal = [hx(h) for h in re.findall(r"/\* #([0-9A-F]{6}) \*/", pal_src)]
    runs_src = re.search(rf"k{name}Runs\[\] PROGMEM = \{{(.*?)\n\}};", _SRC_MINESICONS, re.S).group(1)
    return pal, [tuple(int(v) for v in m) for m in re.findall(r"\{(\d+), (\d+), (\d+), (\d+)\}", runs_src)]


def _mines_segs():
    out = []
    for k in "ABCDEFG":
        src = re.search(rf"kSeg{k}\[\] PROGMEM = \{{(.*?)\n\}};", _SRC_MINESICONS, re.S).group(1)
        out.append([tuple(int(v) for v in m[:3]) for m in re.findall(r"\{(\d+), (\d+), (\d+), (\d+)\}", src)])
    return out


DESK_XP = {"Codex": _desk_icon("Codex"), "Photo": _desk_icon("Photo"), None: _desk_icon("Trash"),
           "Mines": _mines_icon("DeskMines")}


def desk_icon_xp(sc, prog, x0, y0, selected=False):
    pal, runs = DESK_XP[prog]
    for x, y, w, c in runs:
        sc.rect(x0 + x, y0 + y, w, 1, pal[c])
        if selected:
            for i in range((x0 + x + y0 + y) & 1, w, 2):
                sc.pixel(x0 + x + i, y0 + y, X["SELECT_ICON"])


# src/ui/start_icons.h + channels/xp_start.cpp (P-2026-11-26.20 XP-Start).
_SRC_STARTICONS = (ROOT / "src" / "ui" / "start_icons.h").read_text(encoding="utf-8")


def _start_icon(name):
    pal_src = re.search(rf"k{name}Pal\[\] PROGMEM = \{{(.*?)\}};", _SRC_STARTICONS, re.S).group(1)
    pal = [hx(h) for h in re.findall(r"/\* #([0-9A-F]{6}) \*/", pal_src)]
    runs_src = re.search(rf"k{name}Runs\[\] PROGMEM = \{{(.*?)\n\}};", _SRC_STARTICONS, re.S).group(1)
    return pal, [tuple(int(v) for v in m) for m in re.findall(r"\{(\d+), (\d+), (\d+), (\d+)\}", runs_src)]


def run_icon(sc, icon, x0, y0, scale=1):
    pal, runs = icon
    for x, y, w, c in runs:
        sc.rect(x0 + x * scale, y0 + y * scale, w * scale, scale, pal[c])


# src/ui/xp_icons.h (P-2026-11-28.28–.32, tools/deskicons.py): XP colour icons of the new programs.
_SRC_XPICONS = (ROOT / "src" / "ui" / "xp_icons.h").read_text(encoding="utf-8")


def _xp_icon(name):
    pal_src = re.search(rf"k{name}Pal\[\] PROGMEM = \{{(.*?)\}};", _SRC_XPICONS, re.S).group(1)
    pal = [hx(h) for h in re.findall(r"/\* #([0-9A-F]{6}) \*/", pal_src)]
    runs_src = re.search(rf"k{name}Runs\[\] PROGMEM = \{{(.*?)\n\}};", _SRC_XPICONS, re.S).group(1)
    return pal, [tuple(int(v) for v in m) for m in re.findall(r"\{(\d+), (\d+), (\d+), (\d+)\}", runs_src)]


# XPCore::colorIcon: drawn in their own colours, title (4, 3), taskbar (button + 6, 220).
COLOR_ICON = {"taskmgr": ("xp", "TaskMgr"), "calc": ("xp", "Calc"), "computer": ("xp", "Computer"),
              "trash": ("xp", "TrashSmall"), "trash_full": ("xp", "TrashSmallFull"),
              "display": ("start", "Desktop"), "pictures": ("start", "Photo")}


def color_icon(sc, icon, x, y, scale=1):
    src, name = COLOR_ICON[icon]
    run_icon(sc, _xp_icon(name) if src == "xp" else _start_icon(name), x, y, scale)


START_FILL = ["Photo", "Weather", "Clock", "Mines", "AI", "Trend", "Agents"]   # XPCore::recentRows
START_ROW = {   # program → (icon source, icon name, label, icon dy) — channels/xp_start.cpp
    "Photo": ("start", "Photo", "Ảnh", 3), "Weather": ("start", "Weather", "Thời tiết", 2),
    "Clock": ("start", "Clock", "Đồng hồ", 2), "Mines": ("mines", "StartMines", "Dò mìn", 2),
    "AI": ("mines", "StartAi", "AI hôm nay", 2), "Trend": ("mines", "StartTrend", "Xu hướng", 2),
    "Agents": ("mines", "StartAgents", "Agents", 2),
    "Claude": ("start", "SmallClawd", "Claude", 5), "Codex": ("start", "SmallCodex", "Codex", 4),
}


def _installed(skills, show_agents):
    on = {"Claude": "agent", "Codex": "agent", "AI": "agent", "Trend": "agent", "Agents": "agent",
          "Photo": "photo", "Weather": "weather", "Clock": "clock", "Mines": "fun"}
    return lambda p: on[p] in skills and (p != "Agents" or show_agents)


def start_menu(sc, skills=("agent", "photo", "weather", "clock"), all_open=False, hover=None, recent=(),
               show_agents=False):
    """XPStart::draw; hover = the label of the lit row (P-2026-11-27.24); recent = programs opened last
    (P-2026-11-27.25: 3 rows, filled in START_FILL order)."""
    si = _start_icon
    sel = X["SELECT"]
    inst = _installed(skills, show_agents)
    icon = lambda src, n: si(n) if src == "start" else _mines_icon(n)
    for (y0, y1), c in zip(((0, 6), (6, 11), (11, 16), (16, 22), (22, 27), (27, 32)),
                           ("3D95FF", "2B80F5", "1C6BE8", "0F5BDC", "0A50D2", "0B4CC8")):
        sc.rect(0, y0, 240, y1 - y0, hx(c))
    sc.hline(3, 0, 234, hx("5A9BF6"))
    sc.rect(5, 4, 24, 24, X["WHITE"]); sc.rect(6, 5, 22, 22, X["MENU_BORDER"])
    sc.rect(7, 6, 20, 14, hx("93C0F3")); sc.rect(7, 20, 20, 6, hx("76BE37"))
    run_icon(sc, si("UserClawd"), 9, 11)
    sc.text("JBMono-16B", "Clawd", 36, 8, X["TITLE_SHADOW"])
    sc.text("JBMono-16B", "Clawd", 35, 7, X["WHITE"])
    sc.hline(0, 32, 240, hx("F0A030")); sc.hline(0, 32, 20, hx("F7C97A")); sc.hline(220, 32, 20, hx("F7C97A"))
    sc.hline(0, 33, 240, hx("B8661E"))
    sc.rect(0, 34, 240, 156, X["BTN_EDGE"]); sc.rect(1, 34, 151, 156, X["WHITE"])
    sc.vline(152, 34, 156, hx("95BDEE")); sc.rect(153, 34, 86, 156, hx("D3E5FA"))
    y = 38
    if "agent" in skills:
        run_icon(sc, si("PinClawd"), 3, 39)
        sc.text("JBMono-12B", "Claude", 42, 37, X["BLACK"]); sc.text("JBMono-11", "mức dùng", 42, 51, X["MUTED"])
        run_icon(sc, DESK_XP["Codex"], 5, 65)
        sc.text("JBMono-12B", "Codex", 42, 66, X["BLACK"]); sc.text("JBMono-11", "mức dùng", 42, 80, X["MUTED"])
        sc.hline(6, 95, 140, X["ROW_LINE"])
        y = 99
    rows = []
    for p in [r for r in recent if r not in ("Claude", "Codex")] + START_FILL:
        if len(rows) < 3 and inst(p) and p not in rows:
            rows.append(p)
    for p in rows:
        src, name, label, dy = START_ROW[p]
        lit = hover == label
        if lit:
            sc.rect(2, y, 149, 20, sel)
        run_icon(sc, icon(src, name), 6, y + dy)
        sc.text("JBMono-11", label, 28, y + 4, X["WHITE"] if lit else X["BLACK"]); y += 20
    sc.hline(6, 163, 140, X["ROW_LINE"])
    if all_open:
        sc.rect(2, 167, 149, 20, X["SELECT"])
    sc.text("JBMono-12B", "Tất cả chương trình", 4, 170, X["WHITE"] if all_open else X["BLACK"])
    run_icon(sc, si("AllArrow"), 138, 171)
    navy = X["TITLE_SHADOW"]
    run_icon(sc, si("Desktop"), 156, 40); sc.text("JBMono-12B", "Desktop", 175, 41, navy)
    run_icon(sc, si("Stats"), 156, 61); sc.text("JBMono-12B", "Số liệu", 175, 62, navy)
    sc.hline(157, 83, 78, X["DIVIDER"])
    run_icon(sc, si("Settings"), 156, 90); sc.text("JBMono-11", "Cài đặt", 175, 91, navy)
    run_icon(sc, si("AddRemove"), 156, 111); sc.text("JBMono-11", "Thêm / gỡ", 175, 112, navy)
    run_icon(sc, si("Device"), 156, 132); sc.text("JBMono-11", "Thiết bị", 175, 133, navy)
    for b, c in enumerate(("4285F4", "2B72E8", "1C64DC", "1758D0", "134CC2")):
        sc.rect(0, 190 + 5 * b, 240, 4 if b == 4 else 5, hx(c))
    sc.hline(0, 190, 240, X["TASK_HI"])
    run_icon(sc, si("Restart"), 8, 194); sc.text("JBMono-11", "Khởi động lại", 27, 196, X["WHITE"])
    run_icon(sc, si("Power"), 165, 194); sc.text("JBMono-11", "Tắt máy", 184, 196, X["WHITE"])
    if all_open:   # P-2026-11-27.25: every installed program, (144, top, 96 wide), moved up when tall
        progs = [p for p in ("Claude", "Codex", "AI", "Trend", "Agents", "Photo", "Weather", "Clock", "Mines")
                 if inst(p)]
        h = 4 + 20 * len(progs) + 7 + 20
        top = min(62, 213 - h)
        sc.rect(144, top, 96, h, X["MENU_BORDER"]); sc.rect(145, top + 1, 94, h - 2, X["WHITE"])
        y = top + 2
        for p in progs:
            src, name, label, dy = START_ROW[p]
            run_icon(sc, icon(src, name), 147, y + dy); sc.text("JBMono-11", label, 166, y + 4, X["BLACK"]); y += 20
        sc.hline(148, y + 3, 88, X["MENU_BORDER"])
        y += 7
        run_icon(sc, si("AddRemove"), 147, y + 2); sc.text("JBMono-11", "Thêm / gỡ", 166, y + 4, X["BLACK"])


# ── Tắt máy tính (channels/xp_turnoff.cpp, P-2026-11-27.24) ──
TURNOFF_SYM = [
    [0x030, 0x048, 0x084, 0x102, 0x231, 0x249, 0x249, 0x231, 0x102, 0x084, 0x048, 0x030],
    [0x030, 0x132, 0x231, 0x231, 0x231, 0x201, 0x201, 0x201, 0x102, 0x084, 0x078, 0x000],
    [0x07A, 0x086, 0x10E, 0x200, 0x200, 0x201, 0x201, 0x001, 0x1C2, 0x184, 0x178, 0x000],
]


def turnoff(sc, lit=None):
    """XPTurnOff::draw over what is on screen; lit = 0 Chờ, 1 Tắt, 2 Khởi động lại, 3 Hủy."""
    for y in range(240):
        for x in range(y & 1, 240, 2):
            sc.pixel(x, y, X["BLACK"])
    sc.rect(13, 49, 214, 130, X["BLACK"])
    sc.rect(14, 50, 212, 28, X["WELCOME_BAND"])
    sc.text("JBMono-12B", "Tắt máy tính", 22, 57, X["WHITE"])
    sc.rect(204, 58, 6, 5, hx("F25022")); sc.rect(211, 58, 6, 5, hx("81BC06"))
    sc.rect(204, 64, 6, 5, hx("05A6F0")); sc.rect(211, 64, 6, 5, hx("FFBA08"))
    sc.hline(14, 78, 212, X["WELCOME_LINE"])
    sc.rect(14, 79, 212, 66, X["WELCOME"])
    sc.rect(14, 145, 212, 33, X["WELCOME_BAND"])
    faces = (("F2C200", "FFE680"), ("D8341E", "F06A50"), ("2E8A2E", "5CC15C"))
    for i, (face, light) in enumerate(faces):
        x, y = 38 + 70 * i, 90
        on = lit == i
        sc.rect(x + 1, y, 22, 24, X["BLACK"]); sc.rect(x, y + 1, 24, 22, X["BLACK"])
        sc.rect(x + 1, y + 1, 22, 22, X["WHITE"])
        sc.rect(x + 2, y + 2, 20, 20, hx(light if on else face))
        sc.hline(x + 2, y + 2, 20, X["WHITE"] if on else hx(light))
        for r, bits in enumerate(TURNOFF_SYM[i]):
            for c in range(10):
                if bits >> (9 - c) & 1:
                    sc.pixel(x + 7 + c, y + 6 + r, X["WHITE"])
    sc.rect(165, 151, 52, 21, hx("003C74")); sc.rect(164, 152, 54, 19, hx("003C74"))
    sc.rect(165, 152, 52, 19, hx("F4F3EE")); sc.rect(165, 169, 52, 2, hx("D6D0C5"))
    if lit == 3:
        sc.outline(165, 152, 52, 19, hx("F8B330"))
    sc.text("JBMono-11", "Hủy", 191, 155, X["BLACK"], "TC")
    for label, x, y in (("Chờ", 50, 117), ("Tắt", 120, 117), ("Khởi động", 190, 117), ("lại", 190, 129)):
        sc.text("JBMono-11", label, x, y, X["WHITE"], "TC")


def shut_down(sc):
    """Display::drawShutDown (XP-ShutDown)."""
    welcome_chrome(sc)
    italic(sc, "kShutDownBits", 145, 18, 20, 96)


def with_hot(hot, draw):
    def f(sc):
        _HOT[0] = hot
        try:
            draw(sc)
        finally:
            _HOT[0] = None
    return f


def desktop(sc, *, cl="Claude", cx="Codex", line1=f"29° {DOT} Ít mây", line2="cảm giác 33°",
            balloon=False, badge=1, skills=("agent", "photo", "weather", "clock"), sel=None,
            windows=(), top=None, tray=None, one_col=False, xp_icons=True, trash_full=False):
    """tray=None: the weather tray icon when the weather skill is on (P-2026-11-26.15); the older
    design images (before .15) are drawn with tray=False."""
    sc.img.paste(_desk_wallpaper(), (0, 0))
    labels = {"Claude": cl, "Codex": cx, "Photo": "Ảnh", "Weather": "Thời tiết", "Clock": "Đồng hồ", None: "Thùng rác",
              "Mines": "Dò mìn"}
    for prog, x, y in desk_icons(skills, one_col):
        selected = sel is not None and prog == sel
        white = X["SELECT_ICON"] if selected else X["WHITE"]
        if prog == "Claude":
            draw_icon(sc, "clawd", x - 18, y + 1, 2, X["SELECT_CLAWD"] if selected else CLAWD_ORANGE)
        elif xp_icons and prog is None and trash_full:                  # P-2026-11-28.32
            run_icon(sc, _xp_icon("TrashFull"), x - 16, y)
        elif xp_icons and prog in ("Codex", "Photo", None, "Mines"):     # P-2026-11-26.19, .25
            desk_icon_xp(sc, prog, x - 16, y, selected)
        elif prog == "Codex":
            sc.bits(DESK_TERM, 16, x - 16, y, white, 2)
            sc.rect(x - 14, y + 6, 28, 12, X["BLACK"])
            sc.bits(DESK_PROMPT, 6, x - 12, y + 8, X["BAR"], 2)
        elif prog == "Photo":
            draw_icon(sc, "photo", x - 16, y, 2, white)
        elif prog in ("Weather", "Clock"):
            draw_icon(sc, prog.lower(), x - 16, y - 6, 2, white)
        else:
            sc.bits(DESK_TRASH, 14, x - 14, y, X["SELECT_ICON"] if selected else hx("DDE6EE"), 2)
        t = fit(sc, "JBMono-11", labels[prog], 80)
        ly = y + 24
        if selected:
            tw = sc.width("JBMono-11", t)
            bx, bw = x - tw // 2 - 1, tw + 2
            sc.rect(bx, ly, bw, 13, X["SELECT"])
            for k in range(0, bw + 2, 2):
                sc.pixel(bx - 1 + k, ly - 1, X["WHITE"])
                sc.pixel(bx - 1 + k, ly + 13, X["WHITE"])
            for k in range(0, 15, 2):
                sc.pixel(bx - 1, ly - 1 + k, X["WHITE"])
                sc.pixel(bx + bw, ly - 1 + k, X["WHITE"])
            sc.text("JBMono-11", t, x, ly, X["WHITE"], "TC")
        else:
            sc.text("JBMono-11", t, x + 1, ly + 1, X["BLACK"], "TC")
            sc.text("JBMono-11", t, x, ly, X["WHITE"], "TC")
    if balloon and "weather" in skills:
        balloon_xp(sc, line1, line2)
    # The desktop presses no button: open windows are raised (P-2026-11-26.14).
    tw = ("weather" in skills) if tray is None else tray
    taskbar(sc, windows=list(windows), top=top, badge=badge, tray_weather=tw)


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
        s, c = f"{used}%", X["DIM"] if mode == 3 else X["BLACK"]   # black number (P-2026-11-26.11)
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


def weather(sc, *, stale=False, meta="", temp="29°", cond="Ít mây", code=2, place="Hà Nội",
            rows=(("Cảm giác:", "33°"), ("Độ ẩm:", "74%"), ("Gió:", "12 km/h"), ("Chỉ số UV:", "7 · cao")),
            low=(("Cao / thấp:", "31° / 24°"), ("Mặt trời lặn:", "17:24")), **_old):
    """ch_weather.cpp (P-2026-11-26.17 XP-Weather-Props): property sheet, tab Hiện tại."""
    window(sc, "Thời tiết", "weather", False)
    title_meta(sc, meta)
    tabs(sc, ["Hiện tại", "Dự báo"], 0)
    ink = X["MUTED"] if stale else X["BLACK"]          # P-2026-11-26.23: stale values xpMuted, labels black
    wx_icon(sc, code, 14, 50, True)
    sc.text("JBMono-16B", fit(sc, "JBMono-16B", cond, 112), 54, 52, ink)
    if place:
        sc.text("JBMono-11", place, 54, 71, X["LABEL"])
    sc.text("VT323-44", temp, 226, 52, ink, "TR")
    sc.hline(12, 90, 216, X["GROUP"])
    sc.hline(12, 164, 216, X["GROUP"])
    if stale:
        low = (low[0], ("Cập nhật:", "2 giờ trước"))
    for k, (a, b) in enumerate(rows):
        sc.text("JBMono-11", a, 14, 96 + 16 * k, X["BLACK"])
        sc.text("JBMono-11", b, 112, 96 + 16 * k, ink)
    for k, (a, b) in enumerate(low):
        sc.text("JBMono-11", a, 14, 171 + 16 * k, X["BLACK"])
        sc.text("JBMono-11", b, 112, 171 + 16 * k, X["AMBER"] if stale and k == 1 else ink)
    taskbar(sc, active="weather", accent=T_SKY, badge=0)


def weather_loading(sc):
    window(sc, "Thời tiết", "weather", False)
    loading(sc, "Đang tải...", source=LOAD_SOURCE["Thời tiết"])
    taskbar(sc, active="weather", accent=T_SKY, badge=1)


_SRC_WARN = (ROOT / "src" / "ui" / "warn_icon.h").read_text(encoding="utf-8")


def weather_error(sc):
    """ch_weather.cpp error before any data, inside the Hiện tại tab (P-2026-11-26.23 XP-Weather-Error)."""
    window(sc, "Thời tiết", "weather", False)
    tabs(sc, ["Hiện tại", "Dự báo"], 0)
    pal_src = re.search(r"kWarnPal\[\] PROGMEM = \{(.*?)\};", _SRC_WARN, re.S).group(1)
    pal = [hx(h) for h in re.findall(r"/\* #([0-9A-F]{6}) \*/", pal_src)]
    runs_src = re.search(r"kWarnRuns\[\] PROGMEM = \{(.*?)\n\};", _SRC_WARN, re.S).group(1)
    for x, y, w, c in (tuple(int(v) for v in m) for m in re.findall(r"\{(\d+), (\d+), (\d+), (\d+)\}", runs_src)):
        sc.rect(14 + x, 52 + y, w, 1, pal[c])
    sc.text("JBMono-12B", "Chưa có thời tiết", 46, 52, X["BLACK"])
    sc.text("JBMono-11", "Máy chủ trả lỗi 500.", 46, 72, X["BLACK"])
    sc.hline(12, 96, 216, X["GROUP"])
    sc.text("JBMono-11", "Đang tự thử lại...", 14, 104, X["LABEL"])
    taskbar(sc, active="weather", accent=T_SKY, badge=1)


# ── Forecast (ch_forecast.cpp) ───────────────────────────────────────────────
FORECAST = [("Ít mây", 2, 24, 31), ("Mưa rào", 80, 24, 30), ("Mưa", 61, 23, 28)]


def forecast(sc, days=FORECAST):
    """ch_forecast.cpp (P-2026-11-26.17 XP-Forecast-Details): tab Dự báo of the Weather window."""
    window(sc, "Thời tiết", "weather", False)
    tabs(sc, ["Hiện tại", "Dự báo"], 1)
    field(sc, 10, 48, 220, 157)
    sc.rect(11, 49, 218, 15, X["BODY"])
    sc.hline(11, 64, 218, X["GROUP"])
    sc.hline(11, 65, 218, X["DIM"])
    for x in (95, 160, 193):
        sc.vline(x, 52, 10, X["DIM"])
    sc.text("JBMono-11", "Ngày", 17, 50, X["BLACK"])
    sc.text("JBMono-11", "Trời", 101, 50, X["BLACK"])
    sc.text("JBMono-11", "Thấp", 189, 50, X["BLACK"], "TR")
    sc.text("JBMono-11", "Cao", 224, 50, X["BLACK"], "TR")
    if not days:
        sc.text("JBMono-11", "Chưa có dự báo", 120, 74, X["MUTED"], "TC")   # P-2026-11-26.23
    for i, (cond, code, lo, hi) in enumerate(days):
        y = 66 + 24 * i
        sel = i == 0
        bg, ink = (X["SELECT"], X["WHITE"]) if sel else (X["WHITE"], X["BLACK"])
        sc.rect(11, y, 218, 24, bg)
        wx_icon(sc, code, 15, y + 4, False)
        sc.text("JBMono-13", ("Hôm nay", "Mai", "Kia")[i], 35, y + 3, ink)
        sc.text("JBMono-13", fit(sc, "JBMono-13", cond, 189 - 24 - 4 - 101), 101, y + 3, ink)
        sc.text("JBMono-13", f"{lo}°", 189, y + 3, ink, "TR")
        sc.text("JBMono-13", f"{hi}°", 224, y + 3, ink, "TR")
    taskbar(sc, active="weather", accent=T_SKY, badge=0)


# ── Clock (ch_clock.cpp) ─────────────────────────────────────────────────────
SIN60 = [0, 107, 213, 316, 416, 512, 602, 685, 761, 828, 887, 935, 974, 1002, 1018, 1024, 1018, 1002, 974, 935, 887, 828, 761, 685, 602, 512, 416, 316, 213, 107, 0, -107, -213, -316, -416, -512, -602, -685, -761, -828, -887, -935, -974, -1002, -1018, -1024, -1018, -1002, -974, -935, -887, -828, -761, -685, -602, -512, -416, -316, -213, -107]


def _p60(i, r, cx=183, cy=106):
    sn, cs = SIN60[i % 60], SIN60[(i + 15) % 60]
    rnd = lambda v: (v * r + (512 if v >= 0 else -512)) // 1024 if v * r >= 0 else -((-v * r + 512) // 1024)
    return cx + rnd(sn), cy - rnd(cs)


def _thick(sc, x0, y0, x1, y1, t, c):
    o = t // 2
    dx, sx = abs(x1 - x0), 1 if x0 < x1 else -1
    dy, sy = -abs(y1 - y0), 1 if y0 < y1 else -1
    e = dx + dy
    while True:
        sc.rect(x0 - o, y0 - o, t, t, c)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * e
        if e2 >= dy:
            e += dy; x0 += sx
        if e2 <= dx:
            e += dx; y0 += sy


CLOCK_TABS = ["Ngày và giờ", "Múi giờ", "Internet"]
ZONES = [(-480, "Los Angeles"), (-300, "New York"), (-180, "Brasília"), (0, "London"), (60, "Paris, Berlin"),
         (180, "Moskva"), (240, "Dubai"), (330, "New Delhi"), (420, "Hà Nội"), (480, "Singapore"),
         (540, "Tokyo, Seoul"), (600, "Sydney")]
LAND_ROWS = [[(4, 8), (9, 12), (18, 24)], [(1, 8), (10, 11), (14, 26)], [(3, 9), (13, 25)], [(4, 8), (13, 23), (24, 24)],
             [(5, 7), (12, 22)], [(6, 7), (12, 17), (19, 19), (21, 22)], [(8, 10), (14, 16), (21, 23)],
             [(8, 10), (15, 16), (23, 24)], [(8, 10), (15, 16), (22, 25)], [(8, 9), (24, 24), (26, 26)], [(8, 8)]]


def _gmt_paren(tz):
    a = abs(tz)
    return f"(GMT{'-' if tz < 0 else '+'}{a // 60:02d}:{a % 60:02d})"


def _drop(sc, x, y):
    sc.rect(x, y, 14, 14, X["BTN"])
    for r in range(3):
        sc.hline(x + 3 + r, y + 6 + r, 5 - 2 * r, X["WHITE"])


def _spin(sc, x, y, h, c):
    sc.rect(x, y, 12, h, X["BODY"])
    mid = y + h // 2
    sc.hline(x, mid, 12, X["FIELD_BORDER"])
    for r in range(3):
        sc.hline(x + 6 - r, y + 2 + r, 1 + 2 * r, c)
        sc.hline(x + 4 + r, mid + 3 + r, 5 - 2 * r, c)


def _drop_list(sc, x, y, w, labels, top, sel):
    h = 2 + 9 * 13
    sc.outline(x, y, w, h, X["BLACK"])
    sc.rect(x + 1, y + 1, w - 2, h - 2, X["WHITE"])
    sbx = x + w - 11
    for r in range(9):
        i = top + r
        if i >= len(labels):
            break
        ry = y + 1 + r * 13
        t = fit(sc, "JBMono-11", labels[i], sbx - x - 6)
        if i == sel:
            sc.rect(x + 1, ry, sbx - x - 1, 13, X["SELECT"])
        sc.text("JBMono-11", t, x + 3, ry, X["WHITE"] if i == sel else X["BLACK"])
    sc.rect(sbx, y + 1, 10, h - 2, hx("F4F3EE"))
    for k in range(2):
        by = y + h - 11 if k else y + 1
        sc.rect(sbx, by, 10, 10, X["BTN_EDGE"])
        sc.rect(sbx + 1, by + 1, 8, 8, X["BTN"])
        if not k:
            sc.pixel(sbx + 4, by + 4, X["WHITE"]); sc.hline(sbx + 3, by + 5, 3, X["WHITE"])
        else:
            sc.hline(sbx + 3, by + 4, 3, X["WHITE"]); sc.pixel(sbx + 4, by + 5, X["WHITE"])
    n, track_y, track_h = len(labels), y + 11, h - 22
    th = track_h * 9 // n if n > 9 else track_h
    mx = max(n - 9, 0)
    ty = track_y + ((track_h - th) * top // mx if mx else 0)
    sc.rect(sbx, ty, 10, th, X["BTN_EDGE"])
    sc.rect(sbx + 1, ty + 1, 8, th - 2, X["BTN"])


def clock(sc, h=14, m=32, sec=15, h24=True, day=26, month=11, year=2026, wday_first=0, zone="GMT+7 · Hà Nội",
          tab=0, chosen=0, month_list=False, zone_list=False, tz=420, **_old):
    """ch_clock.cpp (P-2026-11-26.22 XP-Clock-Props / -Month / -Zone / -Net): Date and Time Properties."""
    window(sc, "Ngày và Giờ", "clock", False)
    tabs(sc, CLOCK_TABS, tab)
    if tab == 1:
        _clock_zone(sc, tz, zone_list)
        taskbar(sc, active="clock", accent=T_AMBER, badge=0)
        return
    if tab == 2:
        _clock_net(sc)
        taskbar(sc, active="clock", accent=T_AMBER, badge=0)
        return
    group_box(sc, 10, 54, 122, 128, "Ngày", X["WHITE"])
    group_box(sc, 136, 54, 94, 128, "Giờ", X["WHITE"])
    field(sc, 14, 62, 67, 16)
    sc.text("JBMono-11", f"Thg {month}", 17, 63, X["BLACK"])
    _drop(sc, 66, 63)
    field(sc, 85, 62, 44, 16)
    sc.text("JBMono-11", str(year), 87, 63, X["BLACK"])
    _spin(sc, 116, 63, 14, X["BLACK"])
    for i, t in enumerate(["T2", "T3", "T4", "T5", "T6", "T7", "CN"]):
        sc.text("JBMono-11", t, 13 + 16 * i + 8, 82, X["GROUP_LABEL"], "TC")
    sc.hline(13, 96, 112, X["GROUP"])
    dim = lambda y, mo: [31, 29 if (y % 4 == 0 and y % 100) or y % 400 == 0 else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][mo - 1]
    lead = (wday_first + 6) % 7
    n = dim(year, month)
    pm, py = (12, year - 1) if month == 1 else (month - 1, year)
    for i in range(42):
        if i < lead:
            d, inm = dim(py, pm) - lead + 1 + i, False
        elif i - lead < n:
            d, inm = i - lead + 1, True
        else:
            d, inm = i - lead - n + 1, False
        x, y = 13 + 16 * (i % 7), 98 + 13 * (i // 7)
        today = inm and d == (chosen or day)
        if today:
            sc.rect(x, y, 16, 13, X["SELECT"])
        sc.text("JBMono-11", str(d), x + 8, y, X["WHITE"] if today else X["BLACK"] if inm else X["DIM"], "TC")
    sc.rect(147, 70, 73, 73, X["WHITE"])
    for k in range(60):
        if k % 5:
            x, y = _p60(k, 34)
            sc.pixel(x, y, X["DIM"])
            continue
        x, y = _p60(k, 33)
        sz = 3 if k % 15 == 0 else 2
        sc.rect(x - 1, y - 1, sz, sz, X["TITLE"])
    for pos, ln, t, c in (((h % 12) * 5 + m // 12, 18, 3, X["BLACK"]), (m, 27, 2, X["BLACK"]), (sec, 30, 1, X["RED"])):
        x, y = _p60(pos, ln)
        _thick(sc, 183, 106, x, y, t, c)
    sc.rect(182, 105, 3, 3, X["BLACK"])
    sc.outline(145, 152, 76, 18, X["FIELD_BORDER"])        # read-only: the time comes from the Internet
    sc.rect(146, 153, 74, 16, X["BODY"])
    _spin(sc, 208, 153, 16, X["DIM"])
    t = f"{h:02d}:{m:02d}:{sec:02d}" if h24 else f"{h % 12 or 12}:{m:02d} {'SA' if h < 12 else 'CH'}"
    sc.text("JBMono-12B", t, 148, 153, X["BLACK"])
    sc.text("JBMono-11", f"Múi giờ: {zone}", 12, 189, X["BLACK"])
    if month_list:
        _drop_list(sc, 14, 78, 67, [f"Thg {k}" for k in range(1, 13)], 3, month - 1)
    taskbar(sc, active="clock", accent=T_AMBER, badge=0)


def _clock_zone(sc, tz, zone_list):
    field(sc, 12, 50, 216, 18)
    name = dict(ZONES).get(tz)
    sc.text("JBMono-11", fit(sc, "JBMono-11", f"{_gmt_paren(tz)} {name}" if name else _gmt_paren(tz), 196), 15, 52,
            X["BLACK"])
    _drop(sc, 213, 52)
    sc.outline(12, 74, 218, 90, X["FIELD_BORDER"])
    col = min(26, max(0, ((tz * 10 // 4 + 1800) * 3 + 200) // 400))
    for r in range(11):
        for c in range(27):
            land = any(a <= c <= b for a, b in LAND_ROWS[r])
            sel = c == col
            colour = ("8FCF5A" if sel else "5E9E36") if land else ("7FB0EE" if sel else "3C7FD8")
            sc.rect(13 + 8 * c, 75 + 8 * r, 8, 8, hx(colour))
    sc.outline(12, 172, 13, 13, X["DIM"])
    sc.rect(13, 173, 11, 11, X["BODY"])
    sc.text("JBMono-11", "Tự chỉnh giờ mùa hè", 30, 172, X["DIM"])
    if zone_list:
        _drop_list(sc, 12, 68, 216, [f"{_gmt_paren(z)} {n}" for z, n in ZONES], 3, [z for z, _ in ZONES].index(tz))


def _clock_net(sc, last="14:00", date="26/11/2026", nxt="15:00"):
    sc.outline(12, 52, 13, 13, X["FIELD_BORDER"])
    sc.rect(13, 53, 11, 11, X["WHITE"])
    for i, ty in enumerate((6, 7, 8, 7, 6, 5, 4)):
        sc.rect(15 + i, 52 + ty - 1, 1, 3, X["CHECK"])
    sc.text("JBMono-11", "Tự đồng bộ với máy chủ", 30, 52, X["BLACK"])
    sc.text("JBMono-11", "Máy chủ:", 12, 77, X["BLACK"])
    field(sc, 72, 74, 156, 18)
    sc.text("JBMono-11", "pool.ntp.org", 75, 76, X["BLACK"])
    _drop(sc, 213, 76)
    sc.outline(125, 98, 103, 21, hx("003C74"))
    for px, py in ((125, 98), (227, 98), (125, 118), (227, 118)):
        sc.pixel(px, py, X["WHITE"])
    sc.rect(126, 99, 101, 19, hx("F4F3EE"))
    sc.rect(126, 116, 101, 2, hx("D6D0C5"))
    sc.text("JBMono-11", "Cập nhật ngay", 176, 102, X["BLACK"], "TC")
    sc.text("JBMono-11", f"Đã đồng bộ lúc {last}", 12, 130, X["BLACK"])
    sc.text("JBMono-11", f"ngày {date}.", 12, 144, X["BLACK"])
    sc.text("JBMono-11", f"Lần tới: {nxt}.", 12, 166, X["LABEL"])


# ── Night (ch_night.cpp): no window, no taskbar ──────────────────────────────
def night(sc, hh="23", mm="47", date="Thứ Năm 26/11", x=14, y=22):
    """ch_night.cpp (P-2026-11-26.17 XP-Night-Saver): the screen saver block at (x, y)."""
    sc.rect(0, 0, W, H, X["BLACK"])
    ink = X["LABEL"]
    sc.text("VT323-86", f"{hh}:{mm}", x, y + 13, ink)
    sc.text("JBMono-11", date, x + 85, y + 86, ink, "TC")


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
# ── Dò mìn (channels/ch_mines.cpp, mines_core.h; P-2026-11-27.25 XP-Mines) ──
MINES_N = {"1": "0000FF", "2": "008000", "3": "FF0000", "4": "000080", "5": "800000", "6": "008080",
           "7": "000000", "8": "808080"}
SEG_DIGIT = [0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B]
MINES_CROSS = [(3, 3, 2), (3, 12, 2), (4, 4, 2), (4, 11, 2), (5, 5, 2), (5, 10, 2), (6, 6, 2), (6, 9, 2),
               (7, 7, 3), (8, 7, 3), (9, 6, 2), (9, 9, 2), (10, 5, 2), (10, 10, 2), (11, 4, 2), (11, 11, 2),
               (12, 3, 2), (12, 12, 2), (13, 2, 2), (13, 13, 2)]


def _bevel(sc, x, y, w, h, t, raised):
    tl, br = (X["WHITE"], hx("808080")) if raised else (hx("808080"), X["WHITE"])
    for i in range(t):
        sc.hline(x, y + i, w - i, tl); sc.vline(x + i, y, h - i, tl)
        sc.hline(x + i + 1, y + h - 1 - i, w - i - 1, br); sc.vline(x + w - 1 - i, y + i + 1, h - i - 1, br)


def _led(sc, x, v):
    _bevel(sc, x, 30, 41, 25, 1, False)
    sc.rect(x + 1, 31, 39, 23, X["BLACK"])
    v = min(v, 999)
    if v < 0:
        a = min(-v, 99); d = [0x01, SEG_DIGIT[a // 10], SEG_DIGIT[a % 10]]
    else:
        d = [SEG_DIGIT[v // 100], SEG_DIGIT[v // 10 % 10], SEG_DIGIT[v % 10]]
    for k in range(3):
        for i, seg in enumerate(_mines_segs()):
            col = hx("FF0000") if d[k] >> (6 - i) & 1 else hx("480000")
            for xx, yy, ww in seg:
                sc.rect(x + 1 + 13 * k + xx, 31 + yy, ww, 1, col)


def mines(sc, board="." * 81, face="smile", left=10, secs=0, windows=("Mines",)):
    window(sc, "Dò mìn", icon="mines")
    sc.rect(2, 22, 236, 192, hx("C0C0C0"))
    _bevel(sc, 45, 26, 150, 31, 2, False)
    _led(sc, 51, left)
    run_icon(sc, _mines_icon({"smile": "FaceSmile", "wow": "FaceWow", "cool": "FaceCool", "dead": "FaceDead"}[face]),
             107, 29)
    _led(sc, 148, secs)
    _bevel(sc, 45, 61, 150, 150, 3, False)
    for i, c in enumerate(board):
        x, y = 48 + 16 * (i % 9), 64 + 16 * (i // 9)
        if c in ".F":
            sc.rect(x, y, 16, 16, hx("C0C0C0")); _bevel(sc, x, y, 16, 16, 2, True)
            if c == "F":
                run_icon(sc, _mines_icon("Flag"), x + 4, y + 3)
            continue
        sc.rect(x, y, 16, 16, hx("FF0000") if c == "X" else hx("C0C0C0"))
        sc.hline(x, y, 16, hx("808080")); sc.vline(x, y, 16, hx("808080"))
        if c in MINES_N:
            sc.text("JBMono-16B", c, x + 8, y + 8, hx(MINES_N[c]), "MC")
        elif c in "MXW":
            run_icon(sc, _mines_icon("Mine"), x + 2, y + 2)
            if c == "W":    # ch_mines.cpp kCross
                for row, cx, w in MINES_CROSS:
                    sc.rect(x + cx, y + row, w, 1, hx("FF0000"))
    taskbar(sc, windows=list(windows), top="Mines", badge=0, tray_weather=True)


def _mines_from_design(name):
    """The board / face / LEDs a design artboard shows (source/<name>.dc.html) — to draw the same game."""
    h = (ROOT / "design" / "panel" / "source" / f"{name}.dc.html").read_text(encoding="utf-8")
    px = {}
    for fill, d in re.findall(r'<path fill="#([0-9A-Fa-f]{6})" d="([^"]*)"', h):
        for x, y, w in re.findall(r"M(\d+) (\d+)h(\d+)v1h-\d+z", d):
            for i in range(int(w)):
                px[(int(x) + i, int(y))] = fill.upper()
    cells = []
    for i in range(81):
        x, y = 48 + 16 * (i % 9), 64 + 16 * (i // 9)
        inner = [px.get((x + a, y + b)) for a in range(2, 14) for b in range(2, 14)]
        if px.get((x + 1, y + 1)) == "FFFFFF":
            cells.append("F" if "FF0000" in inner else ".")
        elif px.get((x + 1, y + 1)) == "FF0000":
            cells.append("X")
        elif inner.count("000000") > 40:
            cells.append("W" if "FF0000" in inner else "M")
        else:
            cells.append(next((n for n, c in MINES_N.items() if n != "7" and c in inner), "0"))

    def led(x0):
        v = ""
        for k in range(3):
            pat = 0
            for i, seg in enumerate(_mines_segs()):
                xx, yy, ww = seg[len(seg) // 2]
                if px.get((x0 + 1 + 13 * k + xx + ww // 2, 31 + yy)) == "FF0000":
                    pat |= 1 << (6 - i)
            v += "-" if pat == 0x01 else str(SEG_DIGIT.index(pat)) if pat in SEG_DIGIT else "?"
        return -int(v[1:]) if v[0] == "-" else int(v)

    face = {"XP-Mines-Play": "wow", "XP-Mines-Win": "cool", "XP-Mines-Lose": "dead"}.get(name, "smile")
    return dict(board="".join(cells), face=face, left=led(51), secs=led(148))


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
    sc.text("JBMono-11", "Thêm ảnh trong app glimmer", 120, 128, X["BLACK"], "TC")   # P-2026-11-28.27
    taskbar(sc, active="photo", accent=MINT, badge=1, progress=0)   # empty: no slide progress


# ── Trình quản lý tác vụ (ch_taskmgr.cpp, P-2026-11-28.28) ──
TM_GREEN, TM_OFF, TM_GRID = hx("00FF00"), hx("007F00"), hx("008040")
TM_CPU = [3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 3, 4, 4, 10, 18, 9, 6, 3, 3, 3, 3, 3, 4, 4, 4, 8, 4, 3, 3, 3, 4, 4, 30,
          20, 8, 4, 3, 12]
TM_MEM = [38, 38, 39, 39, 40, 40, 40, 39, 39, 40, 41, 41, 40, 40, 40, 41, 50, 58, 50, 44, 42, 41, 41, 40, 40, 41,
          41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41]
TM_NET = [70] * 8 + [68, 66, 69, 70, 70, 62, 55, 64, 70, 71, 72, 71, 70, 70, 69, 70, 71, 70, 70, 70, 70, 70, 70, 70,
                     70, 70, 69, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70]


def _tm_graph(sc, x, y, w, h, pts):
    sc.rect(x, y, w, h, hx("000000"))
    for gx in range(x + 11, x + w, 12):
        sc.vline(gx, y, h, TM_GRID)
    for gy in range(y + 11, y + h, 12):
        sc.hline(x, gy, w, TM_GRID)
    n, right, prev = len(pts), x + w - 1, None
    for i, v in enumerate(pts):
        qx, qy = right - 4 * (n - 1 - i), y + (h - 1) - (v * (h - 1) + 50) // 100
        if prev:
            ImageDraw.Draw(sc.img).line([prev, (qx, qy)], fill=TM_GREEN)
        else:
            sc.pixel(qx, qy, TM_GREEN)
        prev = (qx, qy)


def _tm_gauge(sc, x, y, pct, label):
    sc.rect(x, y, 44, 36, hx("000000"))
    lit = 0 if not pct else min(6, (pct * 6 + 99) // 100)
    for i in range(6):
        c = TM_GREEN if 6 - i <= lit else TM_OFF
        sc.rect(x + 15, y + 3 + 3 * i, 6, 2, c)
        sc.rect(x + 23, y + 3 + 3 * i, 6, 2, c)
    sc.text("JBMono-11", label, x + 22, y + 23, TM_GREEN, "TC")


def _tm_list(sc, x, y, w, h):
    sc.outline(x, y, w, h, X["FIELD_BORDER"])
    sc.rect(x + 1, y + 1, w - 2, h - 2, X["WHITE"])
    sc.rect(x + 1, y + 1, w - 2, 15, X["BODY"])
    sc.hline(x + 1, y + 16, w - 2, hx("D0D0BF"))
    sc.hline(x + 1, y + 17, w - 2, X["DIM"])


TM_ROW_ICON = {"Claude": ("start", "SmallClawd"), "Weather": ("start", "Weather"), "Clock": ("start", "Clock"),
               "Photo": ("start", "Photo"), "Codex": ("start", "SmallCodex")}
TM_TITLE = {"Claude": "Claude", "Weather": "Thời tiết", "Clock": "Ngày và Giờ", "Photo": "Ảnh", "Codex": "Codex"}


def taskmgr(sc, tab=0, rows=("Claude", "Weather", "Clock"), sel=1, hot=None, cpu=12, free=21412, maxblk=15200,
            used_k=20, mem_pct=48, up="2NG 3G 14P", ssid="nha-tuan", rssi=-58, ip="192.168.1.23"):
    window(sc, "Trình quản lý tác vụ", "taskmgr")
    tabs(sc, ["Ứng dụng", "Hiệu năng", "Mạng"], tab, 152, 10)
    if tab == 0:
        _tm_list(sc, 10, 46, 220, 112)
        sc.rect(150, 50, 1, 10, X["DIM"])
        sc.text("JBMono-11", "Tác vụ", 16, 48, X["BLACK"])
        sc.text("JBMono-11", "Trạng thái", 156, 48, X["BLACK"])
        for i, p in enumerate(rows):
            y = 64 + 18 * i
            lit = i == sel
            fg = X["WHITE"] if lit else X["BLACK"]
            if lit:
                sc.rect(11, y, 218, 18, X["SELECT"])
            src, name = TM_ROW_ICON[p]
            pal, runs = _start_icon(name)
            ih = max(r[1] for r in runs) + 1
            ih = {"SmallClawd": 10, "SmallCodex": 12, "Photo": 14}.get(name, 16)
            run_icon(sc, (pal, runs), 14, y + (18 - ih) // 2)
            sc.text("JBMono-11", TM_TITLE[p], 34, y + 2, fg)
            sc.text("JBMono-11", "Đang chạy", 156, y + 2, fg)
        any_ = bool(rows)
        push_button(sc, 26, 165, 117, 21, "Kết thúc tác vụ", "dim" if not any_ else "hot" if hot == 0 else "up")
        push_button(sc, 147, 165, 82, 21, "Chuyển tới", "dim" if not any_ else "hot" if hot == 1 else "up")
    elif tab == 1:
        for gx, gy, gw, gh, lab in ((10, 50, 52, 46, "CPU"), (66, 50, 164, 46, "Lịch sử dùng CPU"),
                                    (10, 104, 52, 46, "Bộ nhớ"), (66, 104, 164, 46, "Lịch sử bộ nhớ"),
                                    (10, 158, 130, 34, "Bộ nhớ (KB)"), (144, 158, 86, 34, "Đã chạy")):
            group_box(sc, gx, gy, gw, gh, lab, X["WHITE"])
        sc.text("JBMono-11", "Còn trống", 14, 162, X["BLACK"])
        sc.text("JBMono-11", "Khối lớn", 14, 176, X["BLACK"])
        _tm_gauge(sc, 14, 56, cpu, f"{cpu} %")
        _tm_gauge(sc, 14, 110, mem_pct, f"{used_k}K")
        _tm_graph(sc, 70, 56, 156, 36, TM_CPU)
        _tm_graph(sc, 70, 110, 156, 36, TM_MEM)
        sc.text("JBMono-11", str(free), 136, 162, X["BLACK"], "TR")
        sc.text("JBMono-11", str(maxblk), 136, 176, X["BLACK"], "TR")
        sc.text("JBMono-11", up, 187, 170, X["BLACK"], "TC")
    else:
        sc.text("JBMono-11", "Wi-Fi · Đã kết nối", 10, 46, X["GROUP_LABEL"])
        sc.text("JBMono-11", "100%", 38, 62, X["LABEL"], "TR")
        sc.text("JBMono-11", "0%", 38, 120, X["LABEL"], "TR")
        _tm_graph(sc, 40, 61, 190, 72, TM_NET)
        _tm_list(sc, 10, 140, 220, 38)
        sc.rect(75, 144, 1, 10, X["DIM"])
        sc.rect(140, 144, 1, 10, X["DIM"])
        sc.text("JBMono-11", "Mạng", 15, 142, X["BLACK"])
        sc.text("JBMono-11", "Tín hiệu", 80, 142, X["BLACK"])
        sc.text("JBMono-11", "IP", 145, 142, X["BLACK"])
        sc.text("JBMono-11", ssid, 15, 160, X["BLACK"])
        sc.text("JBMono-11", f"{rssi} dBm", 80, 160, X["BLACK"])
        sc.text("JBMono-11", ip, 145, 160, X["BLACK"])
    sc.rect(2, 196, 236, 18, X["BODY"])
    sc.hline(2, 196, 236, X["DIM"])
    for x, w, t in ((3, 76, f"Tác vụ: {len(rows)}"), (80, 69, f"CPU: {cpu}%"), (150, 87, f"Trống: {(free + 512) // 1024}K")):
        sc.rect(x, 199, w - 1, 1, X["DIM"])
        sc.rect(x, 199, 1, 13, X["DIM"])
        sc.rect(x, 211, w - 1, 1, X["WHITE"])
        sc.rect(x + w - 2, 199, 1, 13, X["WHITE"])
        sc.text("JBMono-11", t, x + 4, 199, X["BLACK"])
    taskbar(sc, windows=["Claude", "TaskMgr"], top="TaskMgr", tray_weather=True, badge=0)


SCREENS_TM = [
    ("Trình quản lý tác vụ", "XP-TaskMgr-Apps · Ứng dụng", lambda s: taskmgr(s), "XPTaskMgrApps"),
    ("Trình quản lý · nút hot", "XP-TaskMgr-Hover · con trỏ trên Kết thúc tác vụ",
     lambda s: taskmgr(s, hot=0), "XPTaskMgrHover"),
    ("Trình quản lý · trống", "XP-TaskMgr-Empty · không cửa sổ", lambda s: taskmgr(s, rows=()), "XPTaskMgrEmpty"),
    ("Trình quản lý · Hiệu năng", "XP-TaskMgr-Perf", lambda s: taskmgr(s, tab=1), "XPTaskMgrPerf"),
    ("Trình quản lý · Mạng", "XP-TaskMgr-Net", lambda s: taskmgr(s, tab=2), "XPTaskMgrNet"),
]


# ── Alt+Tab (channels/xp_alttab.cpp, P-2026-11-28.29) ──
def alt_tab(sc, progs, sel):
    n = len(progs)
    cols = max(1, min(n, 5)); rows = max(1, (n + 4) // 5)
    w = max(12 + 40 * cols, 160); h = 8 + 38 * rows + 4 + 18 + 8
    x0, y0 = (240 - w) // 2, (214 - h) // 2
    edge, fill = hx("0A246A"), hx("D3E5FA")
    sc.hline(x0 + 1, y0, w - 2, edge); sc.hline(x0 + 1, y0 + h - 1, w - 2, edge)
    sc.vline(x0, y0 + 1, h - 2, edge); sc.vline(x0 + w - 1, y0 + 1, h - 2, edge)
    sc.outline(x0 + 1, y0 + 1, w - 2, h - 2, X["WHITE"])
    sc.rect(x0 + 2, y0 + 2, w - 4, h - 4, fill)
    for i, p in enumerate(progs):
        x = x0 + (w - 40 * cols) // 2 + 40 * (i % 5)
        y = y0 + 8 + 38 * (i // 5)
        if i == sel:
            sc.rect(x + 1, y, 38, 36, X["SELECT"])
            sc.rect(x + 3, y + 2, 34, 32, fill)
        if p == "Claude":
            run_icon(sc, _start_icon("PinClawd"), x + 2, y + 8)
        elif p in ("Codex", "Photo"):
            run_icon(sc, _desk_icon(p), x + 4, y + 6)
        elif p == "Weather":
            wx_icon(sc, 2, x + 4, y + 2, True)
        elif p == "Clock":
            run_icon(sc, _start_icon("Clock"), x + 4, y + 2, 2)
        else:
            color_icon(sc, PROG_ICON[p], x + 4, y + 2, 2)
    nx, ny, nw = x0 + 8, y0 + 8 + 38 * rows + 4, w - 16
    sc.outline(nx, ny, nw, 18, X["FIELD_BORDER"])
    sc.rect(nx + 1, ny + 1, nw - 2, 16, X["WHITE"])
    sc.text("JBMono-11", TM_TITLE.get(progs[sel], progs[sel]), nx + nw // 2, ny + 1, X["BLACK"], "TC")


SCREENS_AT = [
    ("Alt+Tab · 3 cửa sổ", "XP-AltTab-3 · chọn sẵn cửa sổ thứ hai",
     lambda s: (weather(s), alt_tab(s, ["Weather", "Claude", "Clock"], 1)), "XPAltTab3"),
    ("Alt+Tab · 1 cửa sổ", "XP-AltTab-1", lambda s: (weather(s), alt_tab(s, ["Weather"], 0)), "XPAltTab1"),
    ("Alt+Tab · 6 cửa sổ", "XP-AltTab-6 · hai hàng",
     lambda s: (weather(s), alt_tab(s, ["Weather", "Claude", "Clock", "Photo", "Codex", "TaskMgr"], 2)),
     "XPAltTab6"),
]


# ── Thuộc tính màn hình (ch_display.cpp, P-2026-11-28.30) ──
def _check(sc, x, y, on):
    sc.outline(x, y, 13, 13, X["FIELD_BORDER"])
    sc.rect(x + 1, y + 1, 11, 11, X["WHITE"])
    if on:
        for i, t in enumerate((2, 3, 4, 3, 2, 1, 0)):
            sc.rect(x + 3 + i, y + 3 + t, 1, 2, X["CHECK"])


def _monitor(sc, x, y, saver=False, wall=2):
    sc.rect(x, y, 76, 64, hx("8A8A8A"))
    sc.rect(x + 1, y + 1, 74, 62, hx("D4D0C8"))
    sc.hline(x + 1, y + 1, 74, X["WHITE"])
    sc.vline(x + 1, y + 1, 62, X["WHITE"])
    sc.outline(x + 7, y + 4, 62, 56, X["LABEL"])
    sc.rect(x + 64, y + 61, 4, 1, hx("21A121"))
    sc.rect(x + 30, y + 64, 16, 5, hx("B2B2B2"))
    sc.rect(x + 22, y + 69, 32, 4, hx("D4D0C8"))
    sc.hline(x + 22, y + 72, 32, hx("8A8A8A"))
    sx, sy = x + 8, y + 5
    if saver:
        sc.rect(sx, sy, 60, 54, hx("000000"))
        sc.text("JBMono-11", "23:47", sx + 30, sy + 18, X["LABEL"], "TC")
        return
    if wall == 0:
        sc.rect(sx, sy, 60, 48, hx("004E98"))
    else:   # Đồi xanh (and the sample "your photo": the fallback, every 4th pixel)
        im = _desk_wallpaper().load()
        for yy in range(48):
            for xx in range(60):
                sc.pixel(sx + xx, sy + yy, im[xx * 4, yy * 4])
    for k, c in enumerate(("D97757", "000000", "F8D56A")):
        sc.rect(sx + 6, sy + 6 + 8 * k, 4, 3, hx(c))
    sc.rect(sx, sy + 48, 60, 6, hx("245EDC"))
    sc.rect(sx, sy + 48, 14, 6, hx("3A9E3A"))


def _list_rows(sc, x, y, w, labels, sel):
    for i, t in enumerate(labels):
        lit = i == sel
        sc.rect(x, y + 16 * i, w, 16, X["SELECT"] if lit else X["WHITE"])
        sc.text("JBMono-11", t, x + 3, y + 16 * i + 1, X["WHITE"] if lit else X["BLACK"])


SAVER = ["(Không)", "Tối dần", "Đồng hồ", "Tắt màn"]


def display_props(sc, tab=0, wall=2, saver=2, lst=False, bright=80, invert=True, idle=True, dirty=False,
                  hot=None):
    window(sc, "Thuộc tính màn hình", "display")
    tabs(sc, ["Màn nền", "Bảo vệ màn hình", "Cài đặt"], tab, 140, 8)
    if tab == 0:
        _monitor(sc, 12, 48, wall=wall)
        sc.text("JBMono-11", "Hình nền:", 96, 46, X["BLACK"])
        sc.outline(96, 62, 132, 52, X["FIELD_BORDER"])
        sc.rect(97, 63, 130, 50, X["WHITE"])
        _list_rows(sc, 97, 63, 130, ["(Không)", "Đồi xanh", "Ảnh của bạn"], wall)
        push_button(sc, 163, 120, 65, 21, "Duyệt...", "dim")
        sc.text("JBMono-11", "Gửi ảnh nền từ app glimmer.", 12, 150, X["LABEL"])
    elif tab == 1:
        _monitor(sc, 12, 48, saver=True)
        sc.text("JBMono-11", "Chế độ:", 96, 46, X["BLACK"])
        sc.outline(96, 61, 132, 18, X["FIELD_BORDER"])
        sc.rect(97, 62, 130, 16, X["WHITE"])
        sc.text("JBMono-11", SAVER[saver], 99, 63, X["BLACK"])
        sc.rect(212, 63, 14, 14, X["BTN"])
        sc.rect(215, 69, 5, 1, X["WHITE"]); sc.rect(216, 70, 3, 1, X["WHITE"]); sc.rect(217, 71, 1, 1, X["WHITE"])
        sc.text("JBMono-11", "Bắt đầu", 96, 89, X["BLACK"])
        sc.text("JBMono-11", "Kết thúc", 96, 111, X["BLACK"])
        for i, t in enumerate(("22:00", "07:00")):
            y = 86 + 22 * i
            sc.outline(160, y, 68, 18, X["FIELD_BORDER"])
            sc.rect(161, y + 1, 66, 16, X["BODY"])
            sc.text("JBMono-11", t, 164, y + 2, X["BLACK"])
        group_box(sc, 10, 140, 220, 34, "Khi rảnh", X["WHITE"])
        _check(sc, 16, 152, idle)
        sc.text("JBMono-11", "Tối khi rảnh 15 phút", 34, 152, X["BLACK"])
        if lst:
            sc.outline(96, 79, 132, 66, hx("000000"))
            sc.rect(97, 80, 130, 64, X["WHITE"])
            _list_rows(sc, 97, 80, 130, SAVER, saver)
    else:
        _monitor(sc, 82, 46, wall=wall)
        group_box(sc, 10, 128, 128, 48, "Độ sáng", X["WHITE"])
        sc.rect(20, 142, 108, 2, X["DIM"])
        sc.hline(20, 144, 108, X["WHITE"])
        for i in range(11):
            sc.rect(20 + (i * 107 + 5) // 10, 156, 1, 3, X["LABEL"])
        x, y = 20 + (bright * 107 + 50) // 100 - 5, 137
        line, core = hx("003C74"), hx("5CC15C")
        sc.hline(x, y, 11, line); sc.vline(x, y + 1, 7, line); sc.vline(x + 10, y + 1, 7, line)
        sc.hline(x + 1, y + 1, 9, X["WHITE"]); sc.vline(x + 1, y + 2, 6, X["WHITE"]); sc.vline(x + 9, y + 2, 6, X["WHITE"])
        sc.rect(x + 2, y + 2, 7, 6, core)
        for r in range(5):
            sc.pixel(x + 1 + r, y + 8 + r, line); sc.pixel(x + 9 - r, y + 8 + r, line)
            if r < 4:
                sc.pixel(x + 2 + r, y + 8 + r, X["WHITE"]); sc.pixel(x + 8 - r, y + 8 + r, X["WHITE"])
            if r < 3:
                sc.hline(x + 3 + r, y + 8 + r, 5 - 2 * r, core)
        sc.text("JBMono-11", "Ít", 18, 160, X["BLACK"])
        sc.text("JBMono-11", f"{bright}%", 74, 160, X["BLACK"], "TC")
        sc.text("JBMono-11", "Nhiều", 132, 160, X["BLACK"], "TR")
        group_box(sc, 142, 128, 88, 48, "Màu", X["WHITE"])
        sc.text("JBMono-11", "240 x 240", 148, 141, X["BLACK"])
        _check(sc, 148, 158, invert)
        sc.text("JBMono-11", "Đảo màu", 166, 158, X["BLACK"])
    push_button(sc, 53, 187, 49, 21, "OK", "hot" if hot == 0 else "up")
    push_button(sc, 106, 187, 49, 21, "Hủy", "hot" if hot == 1 else "up")
    push_button(sc, 159, 187, 70, 21, "Áp dụng", "dim" if not dirty else "hot" if hot == 2 else "up")
    taskbar(sc, windows=["Claude", "Display"], top="Display", tray_weather=True, badge=0)


SCREENS_DP = [
    ("Thuộc tính màn hình", "XP-Display-Desktop · Màn nền", lambda s: display_props(s), "XPDisplayDesktop"),
    ("Thuộc tính · Bảo vệ màn hình", "XP-Display-Saver", lambda s: display_props(s, tab=1), "XPDisplaySaver"),
    ("Thuộc tính · danh sách chế độ", "XP-Display-SaverList",
     lambda s: display_props(s, tab=1, lst=True, dirty=True), "XPDisplaySaverList"),
    ("Thuộc tính · Cài đặt", "XP-Display-Settings · Áp dụng hot",
     lambda s: (display_props(s, tab=2, dirty=True, hot=2), cursor(s, "arrow", 196, 199)), "XPDisplaySettings"),
]


# ── Máy tính bỏ túi (ch_calc.cpp, P-2026-11-28.31) ──
CALC_KEYS = ["MC", "7", "8", "9", "/", "sqrt", "MR", "4", "5", "6", "*", "%", "MS", "1", "2", "3", "-", "1/x",
             "M+", "0", "+/-", ".", "+", "="]


def calc(sc, display="0.", error=False, mem=False, down=None, hot=None):
    window(sc, "Máy tính bỏ túi", "calc")
    sc.outline(8, 27, 224, 24, X["FIELD_BORDER"])
    sc.rect(9, 28, 222, 22, X["WHITE"])
    if error:
        sc.text("JBMono-12B", "Không thể chia cho 0.", 227, 31, X["BLACK"], "TR")
    else:
        sc.text("JBMono-16B", display, 227, 30, X["BLACK"], "TR")
    sc.outline(8, 56, 34, 24, X["DIM"])
    sc.rect(9, 57, 32, 22, X["BODY"])
    sc.hline(9, 57, 32, X["LABEL"])
    sc.vline(9, 57, 22, X["LABEL"])
    if mem:
        sc.text("JBMono-12B", "M", 25, 59, X["BLACK"], "TC")
    keys = [(k, 8 + 38 * (i % 6), 86 + 30 * (i // 6), 34, 26, 4) for i, k in enumerate(CALC_KEYS)]
    keys += [("Backspace", 46, 56, 76, 24, 3), ("CE", 126, 56, 52, 24, 3), ("C", 182, 56, 50, 24, 3)]
    for i, (k, x, y, w, h, dy) in enumerate(keys):
        blue = i < 24 and 1 <= i % 6 <= 3
        look = "down" if down == k else "hot" if hot == k else "up"
        push_button(sc, x, y, w, h, k, look, X["GROUP_LABEL"] if blue else X["RED"], "JBMono-12B", dy)
    taskbar(sc, windows=["Claude", "Calc"], top="Calc", tray_weather=True, badge=0)


SCREENS_CALC = [
    ("Máy tính bỏ túi", "XP-Calc · 0.", lambda s: calc(s), "XPCalc"),
    ("Máy tính · nút nhấn", "XP-Calc-Down · = lõm, bộ nhớ M",
     lambda s: calc(s, display="56088.", mem=True, down="="), "XPCalcDown"),
    ("Máy tính · nút hot", "XP-Calc-Hover · chuột trên 7", lambda s: calc(s, display="123.", hot="7"), "XPCalcHover"),
    ("Máy tính · lỗi", "XP-Calc-Error · chia cho 0", lambda s: calc(s, error=True), "XPCalcError"),
]


# ── Explorer (ch_explorer.cpp, P-2026-11-28.32) ──
def _ex_status(sc, left, right):
    sc.rect(2, 196, 236, 18, X["BODY"])
    sc.hline(2, 196, 236, X["DIM"])
    for x, w, t in ((3, 148, left), (152, 85, right)):
        sc.hline(x, 199, w - 1, X["DIM"]); sc.vline(x, 199, 13, X["DIM"])
        sc.hline(x, 211, w - 1, X["WHITE"]); sc.vline(x + w - 2, 199, 13, X["WHITE"])
        sc.text("JBMono-11", t, x + 4, 199, X["BLACK"])


def _ex_head(sc, t, y):
    sc.text("JBMono-12B", t, 8, y, X["GROUP_LABEL"])
    sc.hline(8, y + 15, 140, X["DIVIDER_FADE"])
    sc.hline(148, y + 15, 40, X["DIVIDER"])


EX_PHOTOS = ["p1.jpg", "p2.jpg", "p3.jpg", "p4.jpg", "mau1.jpg", "mau2.jpg", "mau3.jpg", "mau4.jpg"]


def _ex_thumb(k):
    f = ROOT / "data" / "photos" / f"s{k % 8 + 1}.jpg"
    try:
        return Image.open(f).convert("RGB").resize((47, 47), Image.BOX)
    except OSError:
        return sample_photo().resize((47, 47), Image.BOX)


def explorer(sc, place="computer", sel=-1, confirm=None, trash=(("p3.jpg", "32 KB", "14:02"),
                                                                   ("p5.jpg", "29 KB", "13:40")), hot=None):
    title, icon = {"computer": ("Máy tính", "computer"), "photos": ("Ảnh của tôi", "pictures"),
                   "trash": ("Thùng rác", "trash_full" if trash else "trash")}[place]
    window(sc, title, icon)
    sc.rect(2, 22, 236, 174, X["WHITE"])
    if place == "computer":
        _ex_head(sc, "Ổ đĩa", 26)
        run_icon(sc, _xp_icon("Drive"), 10, 50)
        sc.text("JBMono-11", "Bộ nhớ (C:)", 48, 47, X["BLACK"])
        sc.outline(48, 62, 122, 10, X["FIELD_BORDER"])
        sc.rect(49, 63, 120, 8, X["WHITE"])
        sc.rect(49, 63, 72, 8, X["USER_SEL"])
        sc.text("JBMono-11", "trống 412 KB / 1 MB", 48, 75, X["LABEL"])
        _ex_head(sc, "Thư mục", 98)
        run_icon(sc, _desk_icon("Photo"), 10, 122)
        sc.text("JBMono-11", "Ảnh của tôi", 48, 121, X["BLACK"])
        sc.text("JBMono-11", "8 tệp · 214 KB", 48, 135, X["LABEL"])
        run_icon(sc, _xp_icon("Folder"), 10, 160)
        sc.text("JBMono-11", "Hình nền", 48, 159, X["BLACK"])
        sc.text("JBMono-11", "wallpaper.jpg", 48, 173, X["LABEL"])
        _ex_status(sc, "3 đối tượng", "Máy tính")
    elif place == "photos":
        for i, nm in enumerate(EX_PHOTOS):
            x, y = 6 + 57 * (i % 4), 28 + 72 * (i // 4)
            lit = i == sel
            sc.outline(x + 3, y, 51, 51, X["SELECT"] if lit else hx("ACA899"))
            sc.img.paste(_ex_thumb(i), (x + 5, y + 2))
            if lit:
                sc.rect(x + 1, y + 53, 55, 14, X["SELECT"])
            sc.text("JBMono-11", nm, x + 28, y + 53, X["WHITE"] if lit else X["BLACK"], "TC")
        _ex_status(sc, "8 đối tượng · 214 KB", "Ảnh của tôi")
        if confirm:
            sc.rect(18, 60, 204, 104, X["FRAME"])
            for i, c in enumerate(("3D95FF", "2B80F5", "1C6BE8", "0F5BDC")):
                sc.rect(18, 60 + 5 * i, 204, 5, hx(c))
            sc.rect(20, 80, 200, 82, X["BODY"])
            sc.text("JBMono-12B", "Xác nhận xoá tệp", 24, 63, X["WHITE"])
            sc.rect(204, 63, 14, 14, X["CLOSE"])
            for i in range(8):
                sc.pixel(207 + i, 66 + i, X["WHITE"]); sc.pixel(214 - i, 66 + i, X["WHITE"])
            run_icon(sc, _xp_icon("TrashFull"), 28, 92)
            sc.text("JBMono-11", f"Chuyển '{EX_PHOTOS[sel]}'", 68, 90, X["BLACK"])
            sc.text("JBMono-11", "vào Thùng rác?", 68, 104, X["BLACK"])
            push_button(sc, 58, 134, 56, 21, "Có", "hot")
            push_button(sc, 126, 134, 56, 21, "Không", "hot" if hot == 2 else "up")
    else:
        sc.rect(2, 22, 236, 28, X["BODY"])
        any_ = bool(trash)
        push_button(sc, 6, 26, 136, 21, "Dọn sạch Thùng rác", "up" if any_ else "dim")
        push_button(sc, 146, 26, 75, 21, "Khôi phục", "up" if any_ else "dim")
        sc.outline(6, 52, 228, 140, X["FIELD_BORDER"])
        sc.rect(7, 53, 226, 138, X["WHITE"])
        sc.rect(7, 53, 226, 15, X["BODY"])
        sc.hline(7, 68, 226, hx("D0D0BF"))
        sc.hline(7, 69, 226, X["DIM"])
        sc.rect(104, 56, 1, 10, X["DIM"]); sc.rect(162, 56, 1, 10, X["DIM"])
        sc.text("JBMono-11", "Tên", 12, 54, X["BLACK"])
        sc.text("JBMono-11", "Cỡ", 110, 54, X["BLACK"])
        sc.text("JBMono-11", "Đã xoá", 168, 54, X["BLACK"])
        for i, (nm, sz, at) in enumerate(trash):
            y = 70 + 18 * i
            lit = i == sel
            fg = X["WHITE"] if lit else X["BLACK"]
            if lit:
                sc.rect(7, y, 226, 18, X["SELECT"])
            run_icon(sc, _start_icon("Photo"), 10, y + 2)
            sc.text("JBMono-11", nm, 30, y + 2, fg)
            sc.text("JBMono-11", sz, 110, y + 2, fg)
            sc.text("JBMono-11", at, 168, y + 2, fg)
        _ex_status(sc, f"{len(trash)} đối tượng · 61 KB" if trash else "0 đối tượng", "Thùng rác")
    taskbar(sc, windows=["Claude", "Explorer" if place == "computer" else "Pictures" if place == "photos"
                         else ("TrashFull" if trash else "Trash")], top=None, tray_weather=True, badge=0)


SCREENS_EX = [
    ("Máy tính", "XP-Explorer-Computer", lambda s: explorer(s), "XPExplorerComputer"),
    ("Ảnh của tôi", "XP-Explorer-Photos · p3 chọn", lambda s: explorer(s, "photos", sel=2), "XPExplorerPhotos"),
    ("Xác nhận xoá", "XP-Explorer-Confirm · Có chọn sẵn",
     lambda s: explorer(s, "photos", sel=2, confirm="delete"), "XPExplorerConfirm"),
    ("Thùng rác", "XP-Explorer-Trash · 2 mục", lambda s: explorer(s, "trash", sel=0), "XPExplorerTrash"),
    ("Thùng rác · trống", "XP-Explorer-TrashEmpty", lambda s: explorer(s, "trash", trash=()), "XPExplorerTrashEmpty"),
    ("Desktop · Thùng rác đầy", "XP-Desk-TrashFull",
     lambda s: desktop(s, one_col=True, trash_full=True), "XPDeskTrashFull"),
]


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
    ("Claude · đang chạy", "XP-Claude-Laptop · Clawd gõ laptop",
     lambda s: claude_xp(s, eyes="work",
                         rows=[("TieuMac3d", "working", "Edit", "1P"), ("glimmer", "done", "", "12P"),
                               ("api", "done", "", "1G")]), "XPClaudeLaptop"),
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
    ("Desktop", "XP-Desktop · nền dự phòng, không nút nào lõm", desktop, "XPDesktop"),
    ("Desktop · chỉ Agent", "XP-Desk-Agent · chưa mở cửa sổ nào",
     lambda s: desktop(s, skills=("agent",)), "XPDeskAgent"),
    ("Desktop · Claude thu nhỏ", "XP-Desk-All · đủ 4 skill, nút Claude nổi",
     lambda s: desktop(s, windows=["Claude"]), "XPDeskAll"),
    ("Desktop · vừa cài Đồng hồ", "XP-Desk-Selected · Đồng hồ đang chọn",
     lambda s: desktop(s, sel="Clock"), "XPDeskSelected"),
    ("Desktop · một cột", "XP-Desk-OneCol · chỉ chương trình đã cài",
     lambda s: desktop(s, one_col=True, xp_icons=False), "XPDeskOneCol"),
    ("Start menu", "XP-Start-Menu · app chạm start",
     lambda s: (desktop(s, one_col=True), start_menu(s),
                taskbar(s, windows=[], tray_weather=True, start_down=True)), "XPStartMenu"),
    ("Start · Tất cả chương trình", "XP-Start-All · menu con",
     lambda s: (desktop(s, one_col=True), start_menu(s, all_open=True),
                taskbar(s, windows=[], tray_weather=True, start_down=True)), "XPStartAll"),
    ("Desktop · biểu tượng XP", "XP-Desk-Icons · Command Prompt, My Pictures, Recycle Bin",
     lambda s: desktop(s, one_col=True), "XPDeskIcons"),
    ("Desktop · khay thời tiết", "XP-Desk-Tray · không bong bóng, icon thời tiết ở khay",
     desktop, "XPDeskTray"),
    ("Mở · nút lún trước", "XP-Open-1 · khôi phục Claude: nút lún, chưa vẽ gì khác",
     lambda s: desktop(s, windows=["Claude"], top="Claude", tray=False, balloon=True, badge=0), "XPOpen1"),
    ("Mở · thanh tiêu đề bay", "XP-Open-2 · 4 dải từ nút lên (0, 0)",
     lambda s: (desktop(s, windows=["Claude"], top="Claude", tray=False, balloon=True, badge=0), zoom_bands(s, 0)),
     "XPOpen2"),
    ("Mở · khung trước", "XP-Open-3 · khung trống + con trỏ chờ, 200 ms",
     lambda s: (window(s, "Claude", "clawd"), wait_cursor(s, 0),
                taskbar(s, windows=["Claude"], top="Claude", badge=0)), "XPOpen3"),
    ("Đang tải · hộp tải về", "XP-Load · quả địa cầu → giấy → thư mục, từ claude.ai",
     lambda s: loading_xp(s, "Claude", badge=0, step=38, paper=2, glass=0), "XPLoad"),
    ("Cửa sổ mở", "XP-Win-Open · Claude trên cùng, 3 cửa sổ",
     lambda s: (claude_xp(s), taskbar(s, windows=["Claude", "Weather", "Clock"], top="Claude")), "XPWinOpen"),
    ("Menu desktop", "XP-Menu-Desktop · giữ chỗ trống",
     lambda s: (desktop(s, windows=["Claude"]), menu(s, "desktop", 60, 30)), "XPMenuDesktop"),
    ("Menu cửa sổ", "XP-Menu-Window · giữ nút Claude",
     lambda s: (claude_xp(s), taskbar(s, windows=["Claude", "Weather", "Clock"], top="Claude"),
                menu(s, "window", 71, 213 - 113)), "XPMenuWindow"),
    ("Desktop · chưa có số / thời tiết", "XP-Desktop · tên trần, bong bóng chưa có thời tiết",
     lambda s: desktop(s, cl="Claude", cx="Codex", line1="chưa có thời tiết", line2=""), None),
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
    ("Thời tiết", "XP-Weather-Props · tab Hiện tại", weather, "XPWeatherProps"),
    ("Thời tiết · đang tải", "XP-Weather-Loading", weather_loading, "XPWeatherLoading"),
    ("Thời tiết · lỗi", "XP-Weather-Error · HTTP 500", weather_error, "XPWeatherError"),
    ("Thời tiết · cũ", "XP-Weather-Stale · 2 giờ",
     lambda s: weather(s, stale=True, meta="cũ 2G"), "XPWeatherStale"),
    ("Dự báo", "XP-Forecast-Details · tab Dự báo", forecast, "XPForecastDetails"),
    ("Dự báo · chưa có", "XP-Forecast-Empty · chưa có dữ liệu", lambda s: forecast(s, days=[]), "XPForecastEmpty"),
    ("Đồng hồ", "XP-Clock-Props · Ngày và Giờ", clock, "XPClockProps"),
    ("Đồng hồ · danh sách tháng", "XP-Clock-Month · Thg 11 đang chọn",
     lambda s: clock(s, month_list=True), "XPClockMonth"),
    ("Đồng hồ · Múi giờ", "XP-Clock-Zone · bản đồ", lambda s: clock(s, tab=1), "XPClockZone"),
    ("Đồng hồ · Internet", "XP-Clock-Net · đồng bộ giờ", lambda s: clock(s, tab=2), "XPClockNet"),
    ("Đêm", "XP-Night-Saver · khối nhảy chỗ", night, "XPNightSaver"),
    ("Thông tin", "XP-Info · không nút nào lõm", info, "XPInfo"),
    ("Cài đặt", "XP-Setup · chưa có khóa", setup, "XPSetup"),
    ("Ảnh", "XP-Photo · 2/5", photo, "XPPhoto"),
    ("Ảnh · chưa có ảnh", "XP-Photo-Empty", photo_empty, "XPPhotoEmpty"),
    # P-2026-11-28.27: from the phone / asking (old photo + XP-Open wait cursor) / phone away
    ("Ảnh · từ điện thoại", "XP-Photo-Phone · 3/40", lambda s: photo(s, 3, 40), "XPPhotoPhone"),
    ("Ảnh · đang xin ảnh", "XP-Photo-Asking · giữ ảnh cũ + con trỏ chờ",
     lambda s: (photo(s, 3, 40), wait_cursor(s, 0, over=True)), "XPPhotoAsking"),
    ("Ảnh · điện thoại vắng", "XP-Photo-Offline · 3/8 · đã lưu",
     lambda s: (photo(s, 3, 8), title_meta(s, "3/8 · đã lưu")), "XPPhotoOffline"),
]


# ── the catalogue: (title, note, draw, design image under design/panel/screens/@2x) ──
FUN5 = ("agent", "photo", "weather", "clock", "fun")
SCREENS = [
    *SCREENS_A, *SCREENS_B, *SCREENS_C,
    ("Khởi động", "XP-Splash · ô 3 khối chạy (bước 3)", splash, "XPSplash"),
    ("Welcome", "XP-Connecting · đang kết nối Wi-Fi", connecting, "XPConnecting"),
    ("Đăng nhập", "XP-SetupMode · chế độ cài đặt Wi-Fi", setup_ap, "XPSetupMode"),
    ("Đang cập nhật", "XP-OtaProgress · nạp qua Wi-Fi", ota, "XPOtaProgress"),
    ("Đang tắt máy", "XP-ShutDown · power shutting, 1,5 s", shut_down, "XPShutDown"),
    ("Start · mục sáng", "XP-Hover-Start · chuột trên Thời tiết",
     lambda s: (desktop(s, one_col=True), start_menu(s, hover="Thời tiết"),
                taskbar(s, windows=[], tray_weather=True, start_down=True), cursor(s, "arrow", 64, 125)),
     "XPHoverStart"),
    ("Nút thanh tác vụ hot", "XP-Hot-Task · chuột trên nút Thời tiết",
     with_hot(1, lambda s: (claude_xp(s), taskbar(s, windows=["Claude", "Weather", "Clock"], top="Claude", badge=0),
                            cursor(s, "arrow", 114, 228))), "XPHotTask"),
    ("Nút × hot", "XP-Hot-Close · chuột trên ×",
     with_hot("close", lambda s: (info(s), taskbar(s, windows=["Claude", "Photo", "Weather", "Clock"], top="Info"),
                                  cursor(s, "arrow", 228, 11))), "XPHotClose"),
    ("Tắt máy tính", "XP-TurnOff · chuột trên Tắt",
     lambda s: (desktop(s, one_col=True, windows=["Claude"]), turnoff(s, lit=1), cursor(s, "hand", 121, 99)),
     "XPTurnOff"),
    ("Chưa có kênh", "XP-NoChannels · mọi kênh tắt", no_channels, "XPNoChannels"),
    # P-2026-11-27.25
    ("Start · Tất cả chương trình đủ", "XP-Start-All-Full · mọi skill, Agents bật",
     lambda s: (desktop(s, one_col=True, skills=FUN5),
                start_menu(s, skills=FUN5, all_open=True, show_agents=True),
                taskbar(s, windows=[], tray_weather=True, start_down=True)), "XPStartAllFull"),
    ("Start · hay dùng", "XP-Start-Recent · Dò mìn mở gần nhất, bù Ảnh, Thời tiết",
     lambda s: (desktop(s, one_col=True, skills=FUN5),
                start_menu(s, skills=FUN5, recent=("Mines",)),
                taskbar(s, windows=[], tray_weather=True, start_down=True)), "XPStartRecent"),
    ("Desktop · Dò mìn", "XP-Desk-Fun · cột 2", lambda s: desktop(s, one_col=True, skills=FUN5), "XPDeskFun"),
    ("Dò mìn", "XP-Mines · ván mới", lambda s: mines(s, **_mines_from_design("XP-Mines")), "XPMines"),
    ("Dò mìn · đang chơi", "XP-Mines-Play", lambda s: mines(s, **_mines_from_design("XP-Mines-Play")), "XPMinesPlay"),
    ("Dò mìn · thắng", "XP-Mines-Win", lambda s: mines(s, **_mines_from_design("XP-Mines-Win")), "XPMinesWin"),
    ("Dò mìn · thua", "XP-Mines-Lose", lambda s: mines(s, **_mines_from_design("XP-Mines-Lose")), "XPMinesLose"),    *SCREENS_TM,                                                         # P-2026-11-28.28
    *SCREENS_AT,                                                         # P-2026-11-28.29
    *SCREENS_DP,                                                         # P-2026-11-28.30
    *SCREENS_CALC,                                                       # P-2026-11-28.31
    *SCREENS_EX,                                                         # P-2026-11-28.32
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
