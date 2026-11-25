#!/usr/bin/env python3
"""
screens.py — preview the device's screens on a computer (no flashing).

Re-draws each screen the Claude-only setup can show with the REAL VLW fonts
from data/fonts/, the theme colours and the coordinates from the firmware,
and writes a numbered contact sheet:

    python tools/screens.py out.png            # all screens, 2× scale
    python tools/screens.py out.png 1 8 13     # only these numbers

It mirrors the drawing code by hand (src/channels/ch_claude.cpp,
ch_attention.cpp, chrome.cpp, src/core/display.cpp), so after changing a
layout there, change it here too. TFT_eSPI behaviour reproduced: header
ascent as maxAscent, maxDescent recomputed from glyphs, datums TL/TC/TR/
MC/MR/ML measured from the line box, missing glyphs skipped silently.
"""
import math
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
import vlwpreview as V  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
W = H = 240

# theme.h (design hex; the panel runs inverted, which yields these)
BG, PANEL, PANEL2, LINE = (0, 0, 0), (0x1F, 0x1A, 0x28), (0x2A, 0x22, 0x36), (0x34, 0x29, 0x3F)
INK, INK_DIM, MUTED = (0xFF, 0xF8, 0xE8), (0xD8, 0xCD, 0xB8), (0x8A, 0x7F, 0x96)
CORAL, AMBER, MINT = (0xFF, 0x52, 0x47), (0xFF, 0xD2, 0x3F), (0x8F, 0xE5, 0x74)
SKY, LILAC = (0x54, 0xB6, 0xFF), (0xC3, 0x85, 0xFF)
DOT = "·"
VERSION = "v0.23.0-glimmer"

_fonts = {}


def font(name):
    if name not in _fonts:
        _fonts[name] = V.load(ROOT / "data" / "fonts" / f"{name}.vlw")
    return _fonts[name]


def usage_color(remaining):
    if remaining < 0:
        return MUTED
    return CORAL if remaining <= 20 else AMBER if remaining <= 50 else MINT


class Screen:
    def __init__(self):
        self.img = Image.new("RGB", (W, H), BG)
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

    def outline(self, x, y, w, h, c):
        self.rect(x, y, w, 1, c); self.rect(x, y + h - 1, w, 1, c)
        self.rect(x, y, 1, h, c); self.rect(x + w - 1, y, 1, h, c)

    # ── text, as TFT_eSPI smooth fonts draw it ──
    def width(self, fname, s):
        g, asc, desc = font(fname)
        return sum(g[ord(c)][2] if ord(c) in g else ((asc + desc) // 4 if c == " " else 0) for c in s)

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

    # ── display.cpp primitives ──
    def status_bar(self, title, meta, accent, meta_color=MUTED):
        self.rect(0, 0, W, 22, BG)
        self.text("JBMono-12B", title, W // 2, 11, INK, "MC")
        if meta:
            self.text("JBMono-11", meta, W - 4, 11, meta_color, "MR")
        self.hline(0, 22, W, accent)

    def pixel_bar(self, x, y, w, h, pct, color):
        pct = max(0, min(100, pct))
        self.outline(x, y, w, h, LINE)
        segs, gap = 9, 1
        iw, ih = w - 2, h - 2
        sw = (iw - (segs - 1) * gap) // segs
        left = iw - (sw * segs + (segs - 1) * gap)
        cx = x + 1
        for i in range(segs):
            s = sw + (1 if i < left else 0)
            self.rect(cx, y + 1, s, ih, color if pct > i * (100 / segs) else PANEL)
            cx += s + gap

    def dots_divider(self, x, y, w):
        for i in range(0, w, 4):
            self.pixel(x + i, y, LINE)

    def loading_dots(self, x, y, lit, accent, count=5):
        for i in range(count):
            self.rect(x + i * 9, y, 6, 6, accent if i == lit % count else LINE)

    def glyph16(self, rows, x, y, color, scale=1):
        for r, bits in enumerate(rows):
            for c in range(16):
                if bits & (1 << (15 - c)):
                    self.rect(x + c * scale, y + r * scale, scale, scale, color)

    def logo(self, x, y, color=AMBER):
        self.glyph16([0, 0, 0x0810, 0x0420, 0x0240, 0x0180, 0x7E7E, 0x7E7E,
                      0x0180, 0x0240, 0x0420, 0x0810, 0, 0, 0, 0], x, y, color)

    def key(self, x, y, color, scale=2):
        self.glyph16([0, 0, 0, 0x3C00, 0x4200, 0x8100, 0x81FE, 0x81FE,
                      0x811A, 0x421A, 0x3C00, 0, 0, 0, 0, 0], x, y, color, scale)

    def blocked(self, cx, cy, color):
        d = ImageDraw.Draw(self.img)
        for r in (14, 13):
            d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=color)
        for o in (-1, 0, 1):
            d.line([(cx - 9 + o, cy + 9), (cx + 9 + o, cy - 9)], fill=color)

    def claude_mark(self, cx, cy, r, color):
        for deg, pct in [(0, 100), (31, 78), (58, 95), (92, 82), (121, 100), (150, 74),
                         (182, 96), (209, 80), (241, 100), (268, 76), (299, 93), (329, 84)]:
            a = math.radians(deg); s = 0.0
            while s <= r * pct / 100:
                self.rect(round(cx + math.cos(a) * s) - 1, round(cy + math.sin(a) * s) - 1, 2, 2, color)
                s += 0.5

    def indicator(self, color):
        self.rect(0, 230, W, 2, color)


# ── Dock (src/channels/dock.cpp, P-2026-11-25.3) ────────────────────────────
#
# Painted by main.cpp after each channel's draw() on every channel except
# Attention / Night. Channels with a dock keep content in x 40..228 (L..R).
L, R, CW, MID = 40, 228, 188, 134

DOCK_ICONS = [   # (w, h, rows): bit (w-1-x) of row y = pixel (x, y)
    (18, 10, [0x07FF8, 0x07FF8, 0x06FD8, 0x06FD8, 0x1FFFE,
              0x1FFFE, 0x07FF8, 0x07FF8, 0x02850, 0x02850]),
    (16, 14, [0x0180, 0x2184, 0x1008, 0x07E0, 0x0FF0, 0x0FF0, 0xCFF3,
              0xCFF3, 0x0FF0, 0x0FF0, 0x07E0, 0x1008, 0x2184, 0x0180]),
    (16, 14, [0x07E0, 0x1FF8, 0x381C, 0x60C6, 0x60C6, 0xC0C3, 0xC0C3,
              0xC0FB, 0xC003, 0x6006, 0x6006, 0x381C, 0x1FF8, 0x07E0]),
]
DOCK_DIGITS = [[7, 5, 5, 5, 7], [2, 6, 2, 2, 7], [6, 1, 2, 4, 7], [6, 1, 2, 1, 6], [5, 5, 7, 1, 1],
               [7, 4, 6, 1, 6], [3, 4, 7, 5, 7], [7, 1, 2, 2, 2], [7, 5, 7, 5, 7], [7, 5, 7, 1, 6],
               [0, 2, 7, 2, 0]]   # 0-9, '+'


def dock(sc, accent, active=0, waiting=1):
    """Dock::draw(active, accent, waiting): frame 30x114 at (2,34), 3 tabs."""
    ox, oy = 3, 35                                   # inside the 1-px border
    sc.rect(2, 34, 30, 114, PANEL)
    sc.outline(2, 34, 30, 114, LINE)

    def cy_of(k):
        return oy + 19 + 36 * k
    if active is not None and active >= 0:
        cy = cy_of(active)
        sc.rect(ox + 2, cy - 12, 24, 24, PANEL2)
        sc.rect(ox, cy - 5, 2, 10, accent)
    for k, (w, h, rows) in enumerate(DOCK_ICONS):
        x0, y0 = ox + 14 - w // 2, cy_of(k) - h // 2
        c = CLAWD_ORANGE if k == 0 else INK_DIM
        for y, row in enumerate(rows):
            for x in range(w):
                if row >> (w - 1 - x) & 1:
                    sc.pixel(x0 + x, y0 + y, c)
    if waiting > 0:
        cy = cy_of(0)
        bx, by = ox + 19, cy - 14
        sc.rect(bx + 1, by, 7, 9, AMBER)
        sc.rect(bx, by + 1, 9, 7, AMBER)
        for y, row in enumerate(DOCK_DIGITS[min(waiting, 10)]):
            for x in range(3):
                if row >> (2 - x) & 1:
                    sc.pixel(ox + 22 + x, cy - 12 + y, BG)


# ── Claude channel (ch_claude.cpp) ───────────────────────────────────────────

STATE_COLOR = {"Cần duyệt": AMBER, "Chờ bạn": SKY, "Lỗi": CORAL, "Đang chạy": LILAC, "Xong": MINT}


def fit(sc, fname, s, maxw):
    while len(s) > 1 and sc.width(fname, s) > maxw:
        s = s[:-1]
    return s


def claude(sc, *, hero_used=38, hero_label="TUẦN", reset="4NG", sec_label="PHIÊN 5 GIỜ",
           sec_used=12, sec_reset="2G 14P", stale=False, meta="", meta_color=MUTED,
           rows=None, pace="", banner=None, mood="wide", waiting=1):
    sc.status_bar("Claude", meta, CORAL, meta_color)
    sc.text("JBMono-11", hero_label, L, 32, MUTED)
    # right column: Clawd (mood from the board); countdown above the bar
    clawd(sc, R - 72, 58, 4, eyes=mood)
    if mood == "sleep":                 # animated Zz (ch_claude.cpp kZz): preview = frame 6
        glyph, gx, gy = ["####", "..#.", ".#..", "####"], 202, 38   # z4, MUTED, 2-px cells
        for j, row in enumerate(glyph):
            for i, c in enumerate(row):
                if c == "#":
                    sc.rect(gx + i * 2, gy + j * 2, 2, 2, MUTED)
    sc.text("JBMono-12B", reset, R, 112, CORAL, "TR")
    # hero ("100" drops its "%": it would run into Clawd at x 156)
    remaining = 100 - hero_used if hero_used >= 0 else -1
    uc = MUTED if stale else usage_color(remaining)
    hs = f"{hero_used}" if hero_used >= 0 else "--"
    hw = sc.text("VT323-86", hs, L, 46, uc)
    g, a, d = font("VT323-86"); g2, a2, d2 = font("VT323-44")
    if len(hs) < 3:
        sc.text("VT323-44", "%", L + hw + 2, 46 + ((a + d) - (a2 + d2)) - 4, uc)
    sc.pixel_bar(L, 128, CW, 8, max(hero_used, 0), uc)
    sc.dots_divider(L, 146, CW)
    # secondary row
    sc.text("JBMono-11", sec_label, L, 150, MUTED)
    sc.text("JBMono-11", f"{sec_used}% {DOT} {sec_reset}", R, 150, INK_DIM, "TR")
    sc.pixel_bar(L, 164, CW, 4, sec_used, usage_color(100 - sec_used))
    sc.dots_divider(L, 170, CW)
    # bottom rows
    y0, rh, row = 176, 14, 0
    if banner:
        cred_banner(sc, y0, *banner)
        row = 1
    rows = rows or []
    for proj, state, detail, age in rows[:3 - row]:
        y = y0 + row * rh
        c = STATE_COLOR[state]
        sc.rect(L, y + 4, 5, 5, c)
        aw = sc.text("JBMono-11", age, R, y, MUTED, "TR")
        right = R - aw - 8
        p = fit(sc, "JBMono-11", proj, 84)
        pw = sc.text("JBMono-11", p, L + 10, y, INK_DIM)
        sx = L + 10 + pw + 8
        st = f"{state} {DOT} {detail}" if detail else state
        if detail and sc.width("JBMono-11", st) > right - sx:
            st = state                                  # drop the detail
        sc.text("JBMono-11", fit(sc, "JBMono-11", st, right - sx), sx, y, c)
        row += 1
    if not rows and row < 3:
        sc.text("JBMono-11", "Chưa có hoạt động project", L, y0 + row * rh, MUTED)
    dock(sc, CORAL, waiting=waiting)


def cred_banner(sc, y, text, color, short=None):
    """chrome.cpp credBanner: band x 40..227, short form when > 184 px."""
    if short and sc.width("JBMono-11", text) > CW - 4:
        text = short
    sc.rect(L, y, CW, 14, color)
    sc.text("JBMono-11", text, MID, y + 7, BG, "MC")


def cred_card(sc, *, headline, l1, l2, accent, glyph="key", url=True, retry="",
              title="Claude", bar=CORAL, meta=None):
    if meta is None:
        meta = "KHÓA LỖI" if glyph == "key" else ""
    sc.status_bar(title, meta, bar, accent)
    if glyph == "key": sc.key(MID - 16, 34, accent, 2)
    else:              sc.blocked(MID, 54, accent)
    sc.text("JBMono-16B", headline, MID, 92, accent, "MC")
    sc.text("JBMono-11", l1, MID, 116, MUTED, "MC")
    sc.text("JBMono-11", l2, MID, 132, MUTED, "MC")
    sc.dots_divider(52, 148, 164)
    if url:
        sc.text("JBMono-12B", "glimmer.local", MID, 166, SKY, "MC")
        sc.text("JBMono-11", "192.168.100.40", MID, 186, MUTED, "MC")
    else:
        sc.text("JBMono-11", retry, MID, 166, INK_DIM, "MC")
    dock(sc, bar, waiting=0)


def loading(sc, title, accent):
    sc.status_bar(title, "", accent)
    sc.text("JBMono-16B", "Đang tải", MID, 100, MUTED, "MC")
    sc.loading_dots(MID - 21, 128, 0, accent)
    dock(sc, accent, waiting=0)


# ── Codex channel (ch_codex.cpp) ─────────────────────────────────────────────

# Design CodexDock: hourly % of the weekly allowance left (5 empty hours first).
SPARK = [None] * 5 + [72, 72] + [66] * 9 + [60] * 7 + [60]


def codex(sc, *, hero_used=41, hero_label="TUẦN", right="3NG", right_color=LILAC,
          sec_label="SPARK", sec_used=12, sec_right="2G 14P", pace="~70% KHI ĐẶT LẠI",
          resets="CÒN 2 · 3NG", stale=False, meta="", meta_color=MUTED, banner=None, spark=SPARK):
    sc.status_bar("Codex", meta, LILAC, meta_color)
    sc.text("JBMono-12B", hero_label, L, 32, MUTED)
    if right:
        sc.text("VT323-32", right, R, 26, right_color, "TR")
    remaining = 100 - hero_used if hero_used >= 0 else -1
    uc = MUTED if stale else usage_color(remaining)
    hw = sc.text("VT323-86", f"{hero_used}" if hero_used >= 0 else "--", L, 46, uc)
    g, a, d = font("VT323-86"); g2, a2, d2 = font("VT323-44")
    sc.text("VT323-44", "%", L + hw + 2, 46 + ((a + d) - (a2 + d2)) - 4, uc)
    sc.pixel_bar(L, 128, CW, 8, max(hero_used, 0), uc)
    sc.dots_divider(L, 146, CW)
    sc.text("JBMono-11", sec_label, L, 150, MUTED)
    sc.text("JBMono-11", sec_right, R, 150, INK_DIM, "TR")
    sc.pixel_bar(L, 164, CW, 4, sec_used, usage_color(100 - sec_used))
    sc.dots_divider(L, 170, CW)
    y = 174
    if banner:
        cred_banner(sc, y, *banner)
        y += 14
    sc.text("JBMono-11", "24H", L, y, MUTED)
    if pace:
        sc.text("JBMono-11", pace, R, y, CORAL if pace.startswith("HẾT") else INK_DIM, "TR")
    y += 14
    if resets and not banner:
        sc.text("JBMono-11", "ĐẶT LẠI", L, y, MINT)
        sc.text("JBMono-11", resets, R, y, INK_DIM, "TR")
        y += 14
    bottom, bw, sh = 219, CW // 24, 219 - y
    for i, v in enumerate(spark):
        bx = L + i * bw
        if v is None:
            sc.hline(bx, bottom, bw - 1, LINE)
            continue
        bh = max(1, v * sh // 100)
        sc.rect(bx, bottom + 1 - bh, bw - 1, bh, LILAC if i == 23 else INK_DIM)
    dock(sc, LILAC)


# ── AI channel (ch_aidash.cpp) ───────────────────────────────────────────────

def aidash(sc, *, cl=38, cx=71, cl_reset="2G 14P", cx_reset="3NG", credits="$4.20",
           advice="DÙNG CLAUDE · ĐẶT LẠI 2G", advice_color=INK):
    sc.status_bar("AI hôm nay", credits, INK_DIM)
    sc.text("JBMono-12B", "CLAUDE", L, 32, CORAL)
    sc.text("JBMono-12B", "CODEX", R, 32, LILAC, "TR")
    sc.text("VT323-32", f"{cl}%", L, 50, usage_color(100 - cl))
    sc.text("VT323-32", f"{cx}%", R, 50, usage_color(100 - cx), "TR")
    sc.pixel_bar(L, 92, CW, 10, cl, usage_color(100 - cl))
    sc.pixel_bar(L, 110, CW, 10, cx, usage_color(100 - cx))
    sc.dots_divider(L, 130, CW)
    sc.text("JBMono-11", "ĐẶT LẠI", L, 138, MUTED)
    for y, tag, c, cd in ((158, "CL", CORAL, cl_reset), (174, "CX", LILAC, cx_reset)):
        sc.text("JBMono-12B", tag, L, y, c)
        sc.text("JBMono-11", cd, R, y, INK_DIM, "TR")
    if advice:
        sc.dots_divider(L, 192, CW)
        sc.text("JBMono-11", advice, MID, 198, advice_color, "TC")
    dock(sc, INK_DIM)


# ── Trend channel (ch_trend.cpp) ─────────────────────────────────────────────

TREND_BLOCKS = [
    ("CLAUDE", CORAL, [5, 7.5, 2.5, 0, 10, 6.6, 7.5], f"HÔM NAY 9 {DOT} ĐỈNH T2", MUTED, False),
    ("CODEX", LILAC, [3.4, 1.6, 4.1, 5.9, 2.5, 5, 3.4], f"HÔM NAY 4 {DOT} ĐỈNH CN", MUTED, False),
]


def trend(sc, *, blocks=TREND_BLOCKS, days=("T5", "T6", "T7", "CN", "T2", "T3", "T4")):
    sc.status_bar("Xu hướng", "7 NGÀY", MINT)
    scale = max([10.0] + [v for b in blocks for v in b[2] if v is not None])
    for idx, (tag, color, burn, right, rc, bad) in enumerate(blocks):
        y = (30, 98)[idx]
        tw = sc.text("JBMono-12B", tag, L, y, color)
        room = R - (L + tw) - 6                     # long lines lose their " · …" tail
        while sc.width("JBMono-11", right) > room and f" {DOT} " in right:
            right = right.rsplit(f" {DOT} ", 1)[0]
        right = fit(sc, "JBMono-11", right, room)
        sc.text("JBMono-11", right, R, y + 1, rc, "TR")
        base = y + 16 + 44
        for i, v in enumerate(burn):
            x = L + i * 27
            sc.hline(x, base, 23, LINE)
            if v is None or v <= 0:
                continue
            h = min(44, max(2, int(v / scale * 44 + 0.5)))
            sc.rect(x, base - h, 23, h, LINE if bad else (color if i == 6 else INK_DIM))
    for i, wd in enumerate(days):
        sc.text("JBMono-11", wd, L + i * 27 + 11, 168, INK if i == 6 else MUTED, "TC")
    sc.text("JBMono-11", "% hạn mức tuần mỗi ngày", MID, 194, MUTED, "TC")
    dock(sc, MINT)


# ── Setup channel (ch_setup.cpp) ─────────────────────────────────────────────

def setup(sc, done=(False, False, True)):
    sc.status_bar("glimmer", "CÀI ĐẶT", AMBER, AMBER)
    sc.text("JBMono-12B", "HOÀN TẤT CÀI ĐẶT", MID, 40, AMBER, "MC")
    items = zip((62, 84, 106), done, ("Khóa Claude", "Token Codex", "Thời tiết"),
                ("Tài khoản", "Tài khoản", "Vị trí & giờ"))
    for y, ok, item, hint in items:
        sc.outline(44, y + 1, 11, 11, MINT if ok else LINE)
        if ok:
            sc.rect(47, y + 4, 5, 5, MINT)
        sc.text("JBMono-11", item, 62, y, INK_DIM if ok else INK)
        sc.text("JBMono-11", hint, R, y, MUTED, "TR")
    sc.dots_divider(52, 140, 164)
    sc.text("JBMono-11", "mở trong trình duyệt", MID, 158, MUTED, "MC")
    sc.text("JBMono-16B", "glimmer.local", MID, 180, SKY, "MC")
    sc.text("JBMono-11", "192.168.100.40", MID, 202, MUTED, "MC")
    dock(sc, MUTED, waiting=0)


# ── system screens (display.cpp) ────────────────────────────────────────────

def splash(sc, line):
    sc.logo(W // 2 - 8, 68)
    sc.text("JBMono-16B", "GLIMMER", W // 2, 104, INK, "MC")
    for i in range(5): sc.rect(W // 2 - 18 + i * 9, 130, 6, 6, CORAL if i < 3 else LINE)
    sc.text("JBMono-11", line, W // 2, 156, MUTED, "MC")
    sc.text("JBMono-11", VERSION, W // 2, 200, MUTED, "MC")


def connecting(sc):
    sc.logo(W // 2 - 8, 40)
    sc.text("JBMono-16B", "GLIMMER", W // 2, 68, INK, "MC")
    sc.text("JBMono-12B", "Đang kết nối Wi-Fi", W // 2, 100, MUTED, "MC")
    sc.text("JBMono-11", "Anh Viet", W // 2, 124, INK, "MC")
    sc.loading_dots(W // 2 - 16, 160, 2, CORAL)
    sc.text("JBMono-11", "lần thử 1", W // 2, 192, MUTED, "MC")
    sc.text("JBMono-11", VERSION, W // 2, 216, MUTED, "MC")


def setup_ap(sc):
    sc.status_bar("glimmer", "CÀI ĐẶT", CORAL)
    sc.logo(W // 2 - 8, 26)
    sc.text("JBMono-12B", "KẾT NỐI WI-FI", W // 2, 44, MUTED, "MC")
    sc.text("JBMono-16B", "glimmer-setup", W // 2, 68, INK, "MC")
    sc.dots_divider(10, 96, W - 20)
    sc.text("JBMono-12B", "RỒI MỞ", W // 2, 116, MUTED, "MC")
    sc.text("JBMono-16B", "http://192.168.4.1", W // 2, 140, SKY, "MC")
    for i in range(5): sc.rect(W // 2 - 18 + i * 9, 176, 6, 6, CORAL if i < 3 else LINE)
    sc.text("JBMono-11", VERSION, W // 2, 204, MUTED, "MC")


def ota(sc, pct=42):
    sc.logo(W // 2 - 8, 30)
    sc.text("JBMono-16B", "GLIMMER", W // 2, 58, INK, "MC")
    sc.text("JBMono-12B", "ĐANG CẬP NHẬT", W // 2, 82, CORAL, "MC")
    sc.text("VT323-44", f"{pct}%", W // 2, 110, CORAL, "MC")
    sc.outline(12, 148, W - 24, 12, LINE)
    fw = (W - 26) * pct // 100
    sc.rect(13, 149, fw, 10, CORAL); sc.rect(13 + fw, 149, (W - 26) - fw, 10, PANEL)
    sc.text("JBMono-11", "đừng rút điện", W // 2, 178, MUTED, "MC")
    sc.text("JBMono-11", VERSION, W // 2, 200, MUTED, "MC")


def no_channels(sc):
    sc.text("JBMono-16B", "CHƯA CÓ KÊNH", W // 2, 90, CORAL, "MC")
    sc.text("JBMono-11", "bật kênh trên trang web", W // 2, 135, MUTED, "MC")


# ── Clawd, the Claude Code mascot (display.cpp drawClawd; cards: ch_attention) ──
#
# The terminal sprite  " ▐▛███▜▌ / ▝▜█████▛▘ /   ▘▘ ▝▝ "  is quarter blocks in
# 2:1 cells; in square pixels that is this 18×10 grid ('#' body, '.' empty).
CLAWD_ORANGE = (0xD9, 0x77, 0x57)
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
    if eyes == "wide":                  # surprised: eyes 1×3
        g[1][5] = g[1][12] = "."
    elif eyes == "happy":               # holes filled; "^ ^" + smile cut on half cells (clawd())
        g[2][5] = g[2][12] = "#"; g[3][5] = g[3][12] = "#"
    elif eyes == "shut":                # blink
        g[2][5] = g[2][12] = "#"; g[3][5] = g[3][12] = "#"
    elif eyes == "sleep":               # asleep: lid row filled, 2-cell slits below
        g[2][5] = g[2][12] = "#"
        g[3][4] = g[3][5] = g[3][12] = g[3][13] = "."
    elif eyes == "sad":                 # droopy "/ \" eyes: inner-high, outer-low
        g[2][5] = g[2][12] = "#"; g[3][5] = g[3][12] = "#"
        g[2][6] = g[2][11] = "."; g[3][5] = g[3][12] = "."
    if legs == "walk":                  # mid-stride
        for r in (8, 9):
            g[r] = list("...#..#....#..#...")
    return ["".join(r) for r in g]


# Half-cell holes of the happy face (display.cpp kHappyHoles, P-2026-11-25.5).
HAPPY_HOLES = [(10, 5), (9, 6), (11, 6), (25, 5), (24, 6), (26, 6), (16, 9), (19, 9), (17, 10), (18, 10)]


def clawd(sc, x, y, scale, bg=None, **kw):
    for j, row in enumerate(clawd_grid(**kw)):
        for i, c in enumerate(row):
            if c == "#":
                sc.rect(x + i * scale, y + j * scale, scale, scale, CLAWD_ORANGE)
    if kw.get("eyes") == "happy":
        h = max(scale // 2, 1)
        for hx, hy in HAPPY_HOLES:
            sc.rect(x + hx * scale // 2, y + hy * scale // 2, h, h, bg if bg is not None else BG)


BADGES = {   # 7×7 symbols drawn beside Clawd's head, one per state
    "!":  [".#####.", "##.####", "##.####", "##.####", "#######", "##.####", ".#####."],
    "?":  [".#####.", "#.#.###", "####.##", "###.###", "#######", "###.###", ".#####."],
    "...": [".#####.", "#######", "#######", "#.#.#.#", "#######", ".##....", ".#....."],
    "ok": ["......#", ".....##", "#...##.", "##.##..", ".###...", "..#....", "......."],
    "x":  ["#.....#", ".#...#.", "..#.#..", "...#...", "..#.#..", ".#...#.", "#.....#"],
}


def badge(sc, kind, x, y, scale, color):
    for j, row in enumerate(BADGES[kind]):
        for i, c in enumerate(row):
            if c == "#":
                sc.rect(x + i * scale, y + j * scale, scale, scale, color)


def sparkle(sc, x, y, color):
    for dx, dy in [(0, -2), (0, -1), (0, 0), (0, 1), (0, 2), (-2, 0), (-1, 0), (1, 0), (2, 0)]:
        sc.rect(x + dx * 2, y + dy * 2, 2, 2, color)


def card_v2(sc, *, kc, eyes, legs="stand", mark, title, detail="", status="", progress=None,
            project="glimmer", spark=False):
    """Attention card (ch_attention.cpp paintBody): Clawd + badge + JBMono text."""
    line = f"CLAUDE {DOT} {project}"
    sc.text("JBMono-11", line, W // 2, 30, MUTED, "TC")
    s = 5                                            # 18×10 → 90×50 px
    cx, cy = (W - 18 * s) // 2, 62
    clawd(sc, cx, cy, s, eyes=eyes, legs=legs)
    if mark:
        badge(sc, mark, cx + 18 * s, cy - 6, 3, kc)          # 21×21, off the right shoulder
    if spark:
        sparkle(sc, cx - 12, cy + 4, kc); sparkle(sc, cx + 18 * s + 14, cy + 30, kc)
    sc.text("JBMono-16B", title, W // 2, 130, kc, "TC")
    y = 156
    if progress is not None:
        sc.rect(40, y, 160, 6, PANEL); sc.rect(40, y, 160 * progress // 100, 6, kc)
        y += 16
    if detail:
        sc.text("JBMono-11", detail, W // 2, y, INK_DIM, "TC"); y += 18
    if status:
        sc.text("JBMono-11", status, W // 2, y + 6, MUTED, "TC")
    if kc in (AMBER, SKY):
        sc.indicator(kc)


# ── the catalogue ───────────────────────────────────────────────────────────

ROWS = [("glimmer", "Cần duyệt", "Bash", "2P"), ("TieuMac3d", "Đang chạy", "Edit", "5P"),
        ("api", "Xong", "", "1G")]

SCREENS = [
    ("Claude · bình thường", "Màn chính", lambda s: claude(s, rows=ROWS)),
    ("Claude · chưa có project", "Bảng trống: Clawd ngủ",
     lambda s: claude(s, rows=[], pace="~70% KHI ĐẶT LẠI", mood="sleep", waiting=0)),
    ("Claude · sắp hết hạn mức", "Dùng 92%, đỏ",
     lambda s: claude(s, hero_used=92, sec_used=97, reset="18G 5P", rows=ROWS[1:], pace="HẾT SAU 5G",
                      mood="open")),
    ("Claude · dữ liệu cũ", "Mất kết nối > 15 phút",
     lambda s: claude(s, stale=True, meta="CŨ 14P", meta_color=AMBER, rows=ROWS)),
    ("Claude · khóa hết hạn", "Còn số cũ + dải cảnh báo",
     lambda s: claude(s, stale=True, meta="KHÓA LỖI", meta_color=CORAL, rows=ROWS,
                      banner=(f"KHÓA HẾT HẠN {DOT} glimmer.local", CORAL,
                              f"HẾT HẠN {DOT} glimmer.local"))),
    ("Claude · đang tải", "Lần đầu sau khởi động", lambda s: loading(s, "Claude", CORAL)),
    ("Claude · khóa bị từ chối", "Không có số liệu",
     lambda s: cred_card(s, headline="KHÓA BỊ TỪ CHỐI", l1="claude.ai từ chối khóa",
                         l2="nhập khóa mới tại", accent=CORAL)),
    ("Claude · mất mạng", "Không tới được claude.ai",
     lambda s: cred_card(s, headline="Mất mạng", l1="không tới được claude.ai", l2="kiểm tra Wi-Fi",
                         accent=AMBER, glyph="blocked", url=False, retry="đang tự động thử lại")),
    ("Thẻ · cần duyệt", "Claude Code xin quyền chạy lệnh",
     lambda s: card_v2(s, kc=AMBER, eyes="wide", mark="!", title="Cần duyệt",
                       detail=f"Bash {DOT} pio run -e nodemcuv2", status=f"chờ bạn {DOT} 2P")),
    ("Thẻ · lượt bạn", "Claude Code chờ bạn trả lời",
     lambda s: card_v2(s, kc=SKY, eyes="open", mark="...", title="Lượt bạn",
                       detail="Claude đang chờ câu trả lời", status=f"chờ bạn {DOT} 45 giây")),
    ("Thẻ · xong", "Phiên làm việc kết thúc",
     lambda s: card_v2(s, kc=MINT, eyes="happy", mark="ok", spark=True, title="Xong rồi!",
                       detail="Claude đã xong")),
    ("Thẻ · tiến độ", "Agent tự đẩy (MCP / push)",
     lambda s: card_v2(s, kc=LILAC, eyes="open", legs="walk", mark=None, title="tests 64%",
                       progress=64, detail=f"main {DOT} 4 min", project="api")),
    ("Thẻ · lỗi", "Agent tự đẩy (MCP / push)",
     lambda s: card_v2(s, kc=CORAL, eyes="sad", mark="x", title="build failed",
                       detail=f"3 lỗi {DOT} ch_claude.cpp:120")),
    ("Khởi động", "Vài giây sau khi cắm điện", lambda s: splash(s, "đang khởi động...")),
    ("Đang kết nối Wi-Fi", "2 lần × 30 giây", connecting),
    ("Chế độ cài đặt Wi-Fi", "Không vào được mạng đã lưu", setup_ap),
    ("Đang cập nhật", "Khi nạp firmware qua Wi-Fi", ota),
    ("Chưa có kênh", "Mọi kênh đều tắt", no_channels),
    # ── dock layout (P-2026-11-25.3): Codex, AI, Trend, Setup ──
    ("Codex · bình thường", "Màn chính", lambda s: codex(s)),
    ("Codex · token hết hạn", "Còn số cũ + dải cảnh báo",
     lambda s: codex(s, stale=True, meta="TOKEN LỖI", meta_color=CORAL,
                     banner=(f"TOKEN HẾT HẠN {DOT} glimmer.local", CORAL,
                             f"HẾT HẠN {DOT} glimmer.local"))),
    ("Codex · token hết hạn, chưa có số", "Thẻ khóa",
     lambda s: cred_card(s, headline="TOKEN HẾT HẠN", l1="hết hạn ngày 20/11", l2="nhập token mới tại",
                         accent=CORAL, title="Codex", bar=LILAC, meta="TOKEN LỖI")),
    ("Codex · bị chặn", "Cloudflare chặn thiết bị",
     lambda s: cred_card(s, headline="BỊ CHẶN", l1="chatgpt.com đang chặn",
                         l2="thiết bị này - khóa vẫn tốt", accent=AMBER, glyph="blocked", url=False,
                         retry="thử lại mỗi 15m", title="Codex", bar=LILAC, meta="")),
    ("Codex · đang tải", "Lần đầu sau khởi động", lambda s: loading(s, "Codex", LILAC)),
    ("AI · bình thường", "Claude + Codex", lambda s: aidash(s)),
    ("AI · khóa lỗi", "Khóa Claude bị từ chối",
     lambda s: aidash(s, advice="KHÓA CLAUDE BỊ TỪ CHỐI", advice_color=CORAL)),
    ("Xu hướng · bình thường", "7 ngày", lambda s: trend(s)),
    ("Xu hướng · khóa lỗi / thu thập", "Claude bị từ chối, Codex chưa có lịch sử",
     lambda s: trend(s, blocks=[
         ("CLAUDE", CORAL, [None] * 7, f"khóa bị từ chối {DOT} cập nhật", CORAL, True),
         ("CODEX", LILAC, [None] * 6 + [2], "đang thu thập", MUTED, False)])),
    ("Cài đặt", "Chưa có khóa nào", lambda s: setup(s)),
    ("Claude · đã xong hết", "Mọi project Xong: Clawd ngủ (P-2026-11-25.5)",
     lambda s: claude(s, rows=[("glimmer", "Xong", "", "2P"), ("TieuMac3d", "Xong", "", "5P"),
                               ("api", "Xong", "", "1G")], mood="sleep", waiting=0)),
]


def render(idx):
    sc = Screen()
    SCREENS[idx][2](sc)
    return sc.img


def sheet(indices, out, scale=2, cols=4):
    lab = ImageFont.truetype(str(ROOT / "tools" / "ttf" / "JetBrainsMono-Bold.ttf"), 22)
    sub = ImageFont.truetype(str(ROOT / "tools" / "ttf" / "JetBrainsMono-Regular.ttf"), 17)
    tw, th = W * scale, H * scale
    pad, head = 24, 62
    rows = (len(indices) + cols - 1) // cols
    img = Image.new("RGB", (cols * (tw + pad) + pad, rows * (th + head + pad) + pad), (24, 22, 30))
    d = ImageDraw.Draw(img)
    for k, i in enumerate(indices):
        x = pad + (k % cols) * (tw + pad)
        y = pad + (k // cols) * (th + head + pad)
        title, note, _ = SCREENS[i]
        d.text((x, y), f"{i + 1}. {title}", fill=(255, 210, 63), font=lab)
        d.text((x, y + 30), note, fill=(160, 150, 175), font=sub)
        frame = render(i).resize((tw, th), Image.NEAREST)
        d.rectangle([x - 3, y + head - 3, x + tw + 2, y + head + th + 2], outline=(70, 64, 84), width=3)
        img.paste(frame, (x, y + head))
    img.save(out)
    return img.size


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "screens.png"
    pick = [int(a) - 1 for a in sys.argv[2:]] or list(range(len(SCREENS)))
    print(sheet(pick, out, cols=min(4, len(pick))))
