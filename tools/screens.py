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
VERSION = "v0.22.0-glimmer"

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


# ── Claude channel (ch_claude.cpp) ───────────────────────────────────────────

STATE_COLOR = {"Cần duyệt": AMBER, "Chờ bạn": SKY, "Lỗi": CORAL, "Đang chạy": LILAC, "Xong": MINT}


def fit(sc, fname, s, maxw):
    while len(s) > 1 and sc.width(fname, s) > maxw:
        s = s[:-1]
    return s


def claude(sc, *, hero_used=38, hero_label="TUẦN", reset="4d", sec_label="PHIÊN 5 GIỜ",
           sec_used=12, sec_reset="2h 14m", stale=False, meta="", meta_color=MUTED,
           rows=None, pace="", banner=None, mood="wide"):
    sc.status_bar("Claude", meta, CORAL, meta_color)
    sc.text("JBMono-11", hero_label, 12, 32, MUTED)
    # right column: Clawd (mood from the board); countdown above the bar
    clawd(sc, W - 12 - 72, 40, 4, eyes=mood)
    sc.text("JBMono-12B", reset, W - 12, 112, CORAL, "TR")
    # hero
    remaining = 100 - hero_used if hero_used >= 0 else -1
    uc = MUTED if stale else usage_color(remaining)
    hw = sc.text("VT323-86", f"{hero_used}" if hero_used >= 0 else "--", 12, 46, uc)
    g, a, d = font("VT323-86"); g2, a2, d2 = font("VT323-44")
    sc.text("VT323-44", "%", 12 + hw + 2, 46 + ((a + d) - (a2 + d2)) - 4, uc)
    sc.pixel_bar(12, 128, W - 24, 8, max(hero_used, 0), uc)
    sc.dots_divider(12, 146, W - 24)
    # secondary row
    sc.text("JBMono-11", sec_label, 12, 150, MUTED)
    sc.text("JBMono-11", f"{sec_used}% {DOT} {sec_reset}", W - 12, 150, INK_DIM, "TR")
    sc.pixel_bar(12, 164, W - 24, 4, sec_used, usage_color(100 - sec_used))
    sc.dots_divider(12, 170, W - 24)
    # bottom rows
    y0, rh, row = 176, 14, 0
    if banner:
        text, color = banner
        sc.rect(8, y0, W - 16, 14, color)
        sc.text("JBMono-11", text, W // 2, y0 + 7, BG, "MC")
        row = 1
    rows = rows or []
    for proj, state, detail, age in rows[:3 - row]:
        y = y0 + row * rh
        c = STATE_COLOR[state]
        sc.rect(12, y + 4, 5, 5, c)
        aw = sc.text("JBMono-11", age, W - 12, y, MUTED, "TR")
        right = W - 12 - aw - 8
        p = fit(sc, "JBMono-11", proj, 84)
        pw = sc.text("JBMono-11", p, 22, y, INK_DIM)
        st = f"{state} {DOT} {detail}" if detail else state
        sc.text("JBMono-11", fit(sc, "JBMono-11", st, right - (22 + pw + 8)), 22 + pw + 8, y, c)
        row += 1
    if row < 3 and pace:
        y = y0 + row * rh
        sc.text("JBMono-11", "NHỊP TUẦN", 12, y, MUTED)
        sc.text("JBMono-11", pace, W - 12, y, CORAL if pace.startswith("HẾT") else INK_DIM, "TR")
        row += 1
    if not rows and row < 3:
        sc.text("JBMono-11", "Chưa có hoạt động project", 12, y0 + row * rh, MUTED)


def cred_card(sc, *, headline, l1, l2, accent, glyph="key", url=True, retry=""):
    sc.status_bar("Claude", "KHÓA LỖI" if glyph == "key" else "", CORAL, accent)
    if glyph == "key": sc.key(W // 2 - 16, 34, accent, 2)
    else:              sc.blocked(W // 2, 54, accent)
    sc.text("JBMono-16B", headline, W // 2, 92, accent, "MC")
    sc.text("JBMono-11", l1, W // 2, 116, MUTED, "MC")
    sc.text("JBMono-11", l2, W // 2, 132, MUTED, "MC")
    sc.dots_divider(30, 148, W - 60)
    if url:
        sc.text("JBMono-12B", "glimmer.local", W // 2, 166, SKY, "MC")
        sc.text("JBMono-11", "192.168.100.40", W // 2, 186, MUTED, "MC")
    else:
        sc.text("JBMono-11", retry, W // 2, 166, INK_DIM, "MC")


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
    elif eyes == "happy":               # squint: a low 1-px slit
        g[2][5] = g[2][12] = "#"
    elif eyes == "shut":                # asleep / blink
        g[2][5] = g[2][12] = "#"; g[3][5] = g[3][12] = "#"
    elif eyes == "sad":                 # droopy "/ \" eyes: inner-high, outer-low
        g[2][5] = g[2][12] = "#"; g[3][5] = g[3][12] = "#"
        g[2][6] = g[2][11] = "."; g[3][5] = g[3][12] = "."
    if legs == "walk":                  # mid-stride
        for r in (8, 9):
            g[r] = list("...#..#....#..#...")
    return ["".join(r) for r in g]


def clawd(sc, x, y, scale, **kw):
    for j, row in enumerate(clawd_grid(**kw)):
        for i, c in enumerate(row):
            if c == "#":
                sc.rect(x + i * scale, y + j * scale, scale, scale, CLAWD_ORANGE)


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

ROWS = [("glimmer", "Cần duyệt", "Bash", "2M"), ("TieuMac3d", "Đang chạy", "Edit", "5M"),
        ("api", "Xong", "", "1H")]

SCREENS = [
    ("Claude · bình thường", "Màn chính", lambda s: claude(s, rows=ROWS)),
    ("Claude · chưa có project", "Bảng trống: Clawd ngủ",
     lambda s: claude(s, rows=[], pace="~70% KHI ĐẶT LẠI", mood="shut")),
    ("Claude · sắp hết hạn mức", "Dùng 92%, đỏ",
     lambda s: claude(s, hero_used=92, sec_used=97, reset="18h 5m", rows=ROWS[1:], pace="HẾT SAU 5H",
                      mood="open")),
    ("Claude · dữ liệu cũ", "Mất kết nối > 15 phút",
     lambda s: claude(s, stale=True, meta="CŨ 14M", meta_color=AMBER, rows=ROWS)),
    ("Claude · khóa hết hạn", "Còn số cũ + dải cảnh báo",
     lambda s: claude(s, stale=True, meta="KHÓA LỖI", meta_color=CORAL, rows=ROWS,
                      banner=("KHÓA HẾT HẠN " + DOT + " glimmer.local", CORAL))),
    ("Claude · đang tải", "Lần đầu sau khởi động",
     lambda s: (s.status_bar("Claude", "", CORAL),
                s.text("JBMono-16B", "Đang tải", W // 2, 100, MUTED, "MC"),
                s.loading_dots(W // 2 - 21, 128, 0, CORAL))),
    ("Claude · khóa bị từ chối", "Không có số liệu",
     lambda s: cred_card(s, headline="KHÓA BỊ TỪ CHỐI", l1="claude.ai từ chối khóa",
                         l2="nhập khóa mới tại", accent=CORAL)),
    ("Claude · mất mạng", "Không tới được claude.ai",
     lambda s: cred_card(s, headline="Mất mạng", l1="không tới được claude.ai", l2="kiểm tra Wi-Fi",
                         accent=AMBER, glyph="blocked", url=False, retry="đang tự động thử lại")),
    ("Thẻ · cần duyệt", "Claude Code xin quyền chạy lệnh",
     lambda s: card_v2(s, kc=AMBER, eyes="wide", mark="!", title="Cần duyệt",
                       detail=f"Bash {DOT} pio run -e nodemcuv2", status=f"chờ bạn {DOT} 2M")),
    ("Thẻ · lượt bạn", "Claude Code chờ bạn trả lời",
     lambda s: card_v2(s, kc=SKY, eyes="open", mark="...", title="Lượt bạn",
                       detail="Claude đang chờ câu trả lời", status=f"chờ bạn {DOT} 45S")),
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
