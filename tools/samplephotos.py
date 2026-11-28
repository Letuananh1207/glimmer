#!/usr/bin/env python3
"""Sample photos of the `photo` skill → data/photos/s<N>.jpg.

Like XP's "Sample Pictures": the device ships a few pictures so the Photo
window is never empty; the user's own photos (p<N>.jpg, sent from the app)
come on top. Every picture is drawn here from shapes — original artwork, no
third-party photo — at 4× and downsampled, then saved as a baseline JPEG of
exactly 188×188 (Photos::kSide) under Photos::kMaxBytes.

    s1  Đồi xanh       rolling green hill, blue sky (XP desktop mood)
    s2  Hoa súng       water lilies on a dark pond (XP sample-picture mood)
    s3  Đèn ông sao    Mid-Autumn star lantern under the full moon (9x)
    s4  Băng cassette  a tape and the pencil to rewind it (9x)
    s5  Kiếm hiệp      two swordsmen on a cliff, pagodas in the clouds
    s6  Sàn nhảy       arrow-key dance game: stage, dancer, PERFECT
    s7  Tin nhắn       2000s messenger window shaking with a BUZZ!!!
    s8  Quán net       CRTs, partitions, 3.000đ / giờ board, trà đá

The 9x pictures recall the games / chat / net cafés of the time; none uses a
real game's or product's characters, logo or screenshot. Text uses Tahoma
(XP's UI font) when the system has it.

    python tools/samplephotos.py            # regenerate data/photos/
    python tools/samplephotos.py --sheet x.png   # + a contact sheet
"""
import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "data", "photos")
SIDE = 188                     # Photos::kSide
MAX_BYTES = 40 * 1024          # Photos::kMaxBytes
K = 4                          # supersampling
S = SIDE * K


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def vgrad(img, box, stops):
    """Vertical gradient in [box] through [(t, rgb), ...]."""
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = box
    for y in range(y0, y1):
        t = (y - y0) / max(1, y1 - y0 - 1)
        for i in range(len(stops) - 1):
            if stops[i][0] <= t <= stops[i + 1][0]:
                u = (t - stops[i][0]) / max(1e-6, stops[i + 1][0] - stops[i][0])
                d.line([(x0, y), (x1 - 1, y)], fill=lerp(stops[i][1], stops[i + 1][1], u))
                break


def layer(img, draw_fn, blur=0, alpha=255, base=(0, 0, 0)):
    """Draw into a transparent layer (optionally blurred), composite onto img.
    [base] = the layer's transparent colour: a blurred edge fades towards it,
    so a blurred shape passes its own colour (no dark halo)."""
    lay = Image.new("RGBA", img.size, base + (0,))
    draw_fn(ImageDraw.Draw(lay), lay)
    if blur:
        lay = lay.filter(ImageFilter.GaussianBlur(blur))
    if alpha < 255:
        a = lay.getchannel("A").point(lambda v: v * alpha // 255)
        lay.putalpha(a)
    img.alpha_composite(lay)


def ridge(y0, amp, waves, phase, step=8):
    pts = []
    for x in range(-step, S + 2 * step, step):
        y = y0
        for (a, f, p) in waves:
            y += amp * a * math.sin(x / S * f * 2 * math.pi + p + phase)
        pts.append((x, y))
    return pts + [(S + step, S + 10), (-step, S + 10)]


def star(cx, cy, r_out, r_in, rot=-math.pi / 2):
    pts = []
    for i in range(10):
        r = r_out if i % 2 == 0 else r_in
        a = rot + i * math.pi / 5
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def grain(img, rnd, amount=6):
    """Fine luminance noise so flat fills read as a photo, not a vector."""
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y][:3]
            n = rnd.randint(-amount, amount)
            px[x, y] = (max(0, min(255, r + n)), max(0, min(255, g + n)), max(0, min(255, b + n)))


def cloud(d, cx, cy, w, rnd, fill=(255, 255, 255, 235)):
    for _ in range(9):
        rx = rnd.uniform(0.25, 0.45) * w
        ox = rnd.uniform(-0.5, 0.5) * w
        oy = rnd.uniform(-0.18, 0.12) * w
        d.ellipse([cx + ox - rx, cy + oy - rx * 0.6, cx + ox + rx, cy + oy + rx * 0.6], fill=fill)


# ── Đồi xanh ─────────────────────────────────────────────────────────────
def hills(rnd):
    img = Image.new("RGBA", (S, S))
    vgrad(img, (0, 0, S, S), [(0, (28, 86, 196)), (0.45, (92, 154, 232)), (0.62, (176, 212, 245)), (1, (190, 220, 248))])
    layer(img, lambda d, l: [cloud(d, x * K, y * K, w * K, rnd) for x, y, w in
                             [(40, 34, 46), (120, 22, 40), (168, 52, 34), (84, 66, 30), (14, 78, 24)]], blur=5 * K, base=(255, 255, 255))
    layer(img, lambda d, l: [cloud(d, x * K, y * K, w * K, rnd, (255, 255, 255, 200)) for x, y, w in
                             [(52, 30, 28), (128, 20, 22), (160, 50, 18)]], blur=2 * K, base=(255, 255, 255))
    # far hill
    layer(img, lambda d, l: d.polygon(ridge(118 * K, 9 * K, [(1, 0.7, 2.2), (0.3, 2.1, 0.4)], 0), fill=(70, 142, 52, 255)), blur=K)

    def main_hill(d, l):
        d.ellipse([-120 * K, 112 * K, 330 * K, 420 * K], fill=(255, 255, 255, 255))
    mask = Image.new("RGBA", img.size, (0, 0, 0, 0))
    main_hill(ImageDraw.Draw(mask), mask)
    g = Image.new("RGBA", img.size)
    vgrad(g, (0, 0, S, S), [(0, (128, 196, 64)), (0.62, (122, 190, 58)), (0.8, (64, 142, 34)), (1, (36, 104, 22))])
    # sunlit left crest
    layer(g, lambda d, l: d.ellipse([-30 * K, 110 * K, 140 * K, 170 * K], fill=(180, 226, 96, 160)), blur=14 * K, base=(180, 226, 96))
    # grass streaks
    def blades(d, l):
        for _ in range(900):
            x = rnd.uniform(0, S); y = rnd.uniform(118 * K, S)
            c = rnd.choice([(150, 210, 80, 90), (60, 130, 30, 90), (110, 180, 50, 90)])
            d.line([(x, y), (x + rnd.uniform(-1, 1) * K, y - rnd.uniform(2, 5) * K)], fill=c, width=K // 2 + 1)
    layer(g, blades)
    g.putalpha(mask.getchannel("A").filter(ImageFilter.GaussianBlur(K)))
    img.alpha_composite(g)
    return img


# ── Hoa súng ─────────────────────────────────────────────────────────────
def lilies(rnd):
    img = Image.new("RGBA", (S, S))
    vgrad(img, (0, 0, S, S), [(0, (10, 40, 44)), (0.5, (14, 58, 62)), (1, (8, 34, 40))])
    def ripples(d, l):
        for _ in range(60):
            x, y = rnd.uniform(0, S), rnd.uniform(0, S)
            w = rnd.uniform(10, 30) * K
            d.arc([x - w, y - w * 0.3, x + w, y + w * 0.3], 200, 340, fill=(80, 150, 150, 90), width=K)
    layer(img, ripples, blur=K)
    pads = [(36, 44, 30, 20), (120, 30, 26, 310), (160, 100, 32, 120), (60, 132, 36, 60), (130, 160, 24, 250), (16, 110, 18, 200), (96, 92, 18, 30)]
    def pad(d, l):
        for x, y, r, notch in pads:
            x, y, r = x * K, y * K, r * K
            ry = r * 0.62
            d.ellipse([x - r, y - ry, x + r, y + ry], fill=(26, 70, 22, 255))
            d.ellipse([x - r + K, y - ry, x + r - K, y + ry - 2 * K], fill=(64, 128, 40, 255))
            d.ellipse([x - r * 0.6, y - ry * 0.7, x + r * 0.2, y + ry * 0.1], fill=(96, 160, 58, 120))
            a = math.radians(notch)
            d.polygon([(x, y), (x + r * 1.1 * math.cos(a - 0.22), y + ry * 1.1 * math.sin(a - 0.22)),
                       (x + r * 1.1 * math.cos(a + 0.22), y + ry * 1.1 * math.sin(a + 0.22))], fill=(14, 52, 56, 255))
            for k in range(6):
                b = a + 0.6 + k * 0.85
                d.line([(x, y), (x + r * 0.85 * math.cos(b), y + ry * 0.85 * math.sin(b))], fill=(40, 100, 30, 160), width=K // 2 + 1)
    layer(img, pad)
    def flower(d, l, cx, cy, r):
        cx, cy, r = cx * K, cy * K, r * K
        for ring, (rr, col) in enumerate([(1.0, (226, 120, 168)), (0.78, (244, 160, 196)), (0.5, (252, 206, 222))]):
            n = 9 - ring * 2
            for i in range(n):
                a = i / n * 2 * math.pi + ring * 0.3
                px, py = cx + math.cos(a) * r * rr * 0.55, cy + math.sin(a) * r * rr * 0.32 - r * 0.12 * ring
                pw, ph = r * 0.26 * rr + K, r * 0.5 * rr
                petal = Image.new("RGBA", (int(pw * 2 + 4), int(ph * 2 + 4)), (0, 0, 0, 0))
                ImageDraw.Draw(petal).ellipse([2, 2, pw * 2, ph * 2], fill=col + (255,), outline=(190, 80, 130, 255), width=K // 2)
                petal = petal.rotate(-math.degrees(a) - 90, expand=True, resample=Image.BICUBIC)
                l.alpha_composite(petal, (int(px - petal.width / 2), int(py - petal.height / 2)))
        d.ellipse([cx - r * 0.14, cy - r * 0.32, cx + r * 0.14, cy - r * 0.12], fill=(250, 214, 70, 255))
    layer(img, lambda d, l: [flower(d, l, *f) for f in [(70, 118, 24), (150, 86, 20), (44, 34, 14)]])
    return img


# ── Đèn ông sao ──────────────────────────────────────────────────────────
def lantern(rnd):
    img = Image.new("RGBA", (S, S))
    vgrad(img, (0, 0, S, S), [(0, (8, 12, 40)), (0.7, (24, 30, 78)), (1, (40, 34, 70))])
    def stars(d, l):
        for _ in range(70):
            x, y = rnd.uniform(0, S), rnd.uniform(0, S * 0.8)
            r = rnd.uniform(0.3, 1.0) * K
            d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 230, rnd.randint(120, 255)))
    layer(img, stars)
    mx, my = 140 * K, 42 * K
    layer(img, lambda d, l: d.ellipse([mx - 50 * K, my - 50 * K, mx + 50 * K, my + 50 * K], fill=(255, 230, 150, 90)), blur=16 * K, base=(255, 230, 150))
    layer(img, lambda d, l: d.ellipse([mx - 24 * K, my - 24 * K, mx + 24 * K, my + 24 * K], fill=(255, 238, 180, 255)))
    layer(img, lambda d, l: [d.ellipse([mx + ox * K - r * K, my + oy * K - r * K, mx + ox * K + r * K, my + oy * K + r * K], fill=(230, 200, 130, 110))
                             for ox, oy, r in [(-8, -6, 7), (6, 8, 5), (10, -10, 3), (-10, 10, 4)]], blur=K)
    # rooftops silhouette
    def roofs(d, l):
        x = 0
        while x < S:
            w = rnd.uniform(26, 44) * K
            h = rnd.uniform(150, 166) * K
            d.rectangle([x, h, x + w, S], fill=(14, 14, 30, 255))
            d.polygon([(x - 3 * K, h), (x + w / 2, h - 10 * K), (x + w + 3 * K, h)], fill=(14, 14, 30, 255))
            if rnd.random() < 0.6:
                wx = x + w * 0.35
                d.rectangle([wx, h + 6 * K, wx + 5 * K, h + 11 * K], fill=(250, 190, 90, 255))
            x += w
    layer(img, roofs)
    # stick
    cx, cy = 74 * K, 96 * K
    layer(img, lambda d, l: d.line([(cx + 8 * K, cy + 20 * K), (cx + 40 * K, S)], fill=(150, 110, 60, 255), width=3 * K))
    layer(img, lambda d, l: d.ellipse([cx - 60 * K, cy - 60 * K, cx + 60 * K, cy + 60 * K], fill=(255, 110, 40, 120)), blur=18 * K, base=(255, 110, 40))
    layer(img, lambda d, l: d.polygon(star(cx, cy, 46 * K, 19 * K), fill=(214, 24, 30, 255), outline=(255, 210, 80, 255), width=2 * K))
    # cellophane facets: inner bright star + frame lines
    layer(img, lambda d, l: d.polygon(star(cx, cy, 24 * K, 10 * K), fill=(255, 120, 70, 200)), blur=3 * K)
    def frame(d, l):
        pts = star(cx, cy, 46 * K, 19 * K)
        for i in range(0, 10, 2):
            d.line([pts[i], (cx, cy)], fill=(255, 220, 120, 200), width=K)
        for i in range(10):
            d.line([pts[i], pts[(i + 4) % 10]], fill=(120, 10, 20, 120), width=K // 2 + 1)
    layer(img, frame)
    # tassels at the two lower tips + top
    def tassels(d, l):
        pts = star(cx, cy, 46 * K, 19 * K)
        for i in (0, 2, 8):
            x, y = pts[i]
            for k in range(5):
                d.line([(x, y), (x + (k - 2) * 1.4 * K, y + 12 * K)], fill=(255, 214, 70, 255), width=K)
    layer(img, tassels)
    return img


# ── Băng cassette ────────────────────────────────────────────────────────
def cassette(rnd):
    img = Image.new("RGBA", (S, S))
    vgrad(img, (0, 0, S, S), [(0, (150, 96, 56)), (1, (110, 66, 36))])
    def wood(d, l):
        for _ in range(90):
            y = rnd.uniform(0, S)
            pts = [(x, y + 3 * K * math.sin(x / (30 * K) + y)) for x in range(0, S + 8, 8)]
            d.line(pts, fill=(80, 44, 20, rnd.randint(40, 110)), width=rnd.randint(1, 3) * K // 2 + 1)
    layer(img, wood, blur=K // 2)
    tape = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(tape)
    x0, y0, x1, y1 = 18 * K, 38 * K, 170 * K, 136 * K
    d.rounded_rectangle([x0 + 3 * K, y0 + 4 * K, x1 + 3 * K, y1 + 4 * K], 6 * K, fill=(0, 0, 0, 110))
    d.rounded_rectangle([x0, y0, x1, y1], 6 * K, fill=(44, 44, 50, 255), outline=(20, 20, 24, 255), width=K)
    # label
    lx0, ly0, lx1, ly1 = x0 + 8 * K, y0 + 7 * K, x1 - 8 * K, y0 + 66 * K
    d.rounded_rectangle([lx0, ly0, lx1, ly1], 3 * K, fill=(244, 232, 200, 255))
    for i, c in enumerate([(226, 64, 48), (246, 160, 40), (60, 140, 200)]):
        d.rectangle([lx0, ly0 + (40 + i * 5) * K, lx1, ly0 + (43 + i * 5) * K], fill=c + (255,))
    for i in range(2):     # handwritten lines
        yy = ly0 + (9 + i * 10) * K
        pts = [(lx0 + 8 * K + t * K, yy + math.sin(t * 0.7 + i) * 1.2 * K) for t in range(0, 100 - i * 30, 2)]
        d.line(pts, fill=(40, 50, 140, 255), width=K)
    # window + reels
    wx0, wy0, wx1, wy1 = x0 + 34 * K, ly0 + 18 * K, x1 - 34 * K, ly0 + 38 * K
    d.rounded_rectangle([wx0, wy0, wx1, wy1], 8 * K, fill=(60, 50, 44, 255), outline=(20, 20, 24, 255), width=K)
    d.rectangle([wx0 + 22 * K, wy0 + 3 * K, wx1 - 22 * K, wy1 - 3 * K], fill=(110, 64, 34, 255))
    for rx in (wx0 + 14 * K, wx1 - 14 * K):
        ry = (wy0 + wy1) / 2
        d.ellipse([rx - 16 * K, ry - 16 * K, rx + 16 * K, ry + 16 * K], fill=(84, 50, 28, 255)) if rx < S / 2 else None
        d.ellipse([rx - 8 * K, ry - 8 * K, rx + 8 * K, ry + 8 * K], fill=(236, 236, 236, 255))
        for k in range(6):
            a = k * math.pi / 3
            d.line([(rx, ry), (rx + 6 * K * math.cos(a), ry + 6 * K * math.sin(a))], fill=(70, 70, 70, 255), width=K)
        d.ellipse([rx - 3 * K, ry - 3 * K, rx + 3 * K, ry + 3 * K], fill=(44, 44, 50, 255))
    # trapezoid bottom + screws
    d.polygon([(x0 + 30 * K, y1), (x0 + 40 * K, y1 - 22 * K), (x1 - 40 * K, y1 - 22 * K), (x1 - 30 * K, y1)], fill=(58, 58, 64, 255))
    for hx in (x0 + 56 * K, x1 - 56 * K):
        d.ellipse([hx - 3 * K, y1 - 14 * K, hx + 3 * K, y1 - 8 * K], fill=(20, 20, 24, 255))
    for sx, sy in [(x0 + 5 * K, y0 + 5 * K), (x1 - 5 * K, y0 + 5 * K), (x0 + 5 * K, y1 - 5 * K), (x1 - 5 * K, y1 - 5 * K)]:
        d.ellipse([sx - 2 * K, sy - 2 * K, sx + 2 * K, sy + 2 * K], fill=(150, 150, 150, 255))
    tape = tape.rotate(-6, resample=Image.BICUBIC, center=(S / 2, S / 2))
    img.alpha_composite(tape)
    # the pencil, through the left reel — how every 9x rewound a tape
    p = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    pd = ImageDraw.Draw(p)
    px0, py, px1 = 20 * K, 160 * K, 172 * K
    pd.rectangle([px0 + 2 * K, py - 5 * K + 3 * K, px1 + 2 * K, py + 5 * K + 3 * K], fill=(0, 0, 0, 90))
    pd.rectangle([px0 + 20 * K, py - 5 * K, px1 - 16 * K, py + 5 * K], fill=(246, 196, 40, 255))
    pd.line([(px0 + 20 * K, py), (px1 - 16 * K, py)], fill=(214, 160, 20, 255), width=K)
    pd.polygon([(px0 + 20 * K, py - 5 * K), (px0 + 4 * K, py), (px0 + 20 * K, py + 5 * K)], fill=(236, 200, 150, 255))
    pd.polygon([(px0 + 9 * K, py - 2 * K), (px0 + 4 * K, py), (px0 + 9 * K, py + 2 * K)], fill=(50, 50, 50, 255))
    pd.rectangle([px1 - 16 * K, py - 5 * K, px1 - 8 * K, py + 5 * K], fill=(190, 190, 196, 255))
    pd.rounded_rectangle([px1 - 9 * K, py - 5 * K, px1, py + 5 * K], 2 * K, fill=(236, 120, 140, 255))
    p = p.rotate(14, resample=Image.BICUBIC, center=(S / 2, py))
    img.alpha_composite(p)
    return img


# ── Kiếm hiệp ────────────────────────────────────────────────────────────
def pagoda(d, cx, base, w, tiers, col, roof):
    """Tiered pagoda silhouette with upturned eaves, bottom at [base]."""
    y = base
    for t in range(tiers):
        tw = w * (1 - t * 0.16)
        bh = w * 0.34
        d.rectangle([cx - tw * 0.32, y - bh, cx + tw * 0.32, y], fill=col)
        y -= bh
        rh = w * 0.18
        d.polygon([(cx - tw * 0.62, y - rh * 0.9), (cx - tw * 0.5, y - rh * 0.3), (cx - tw * 0.3, y - rh),
                   (cx, y - rh * 1.8), (cx + tw * 0.3, y - rh), (cx + tw * 0.5, y - rh * 0.3),
                   (cx + tw * 0.62, y - rh * 0.9), (cx + tw * 0.4, y + rh * 0.1), (cx - tw * 0.4, y + rh * 0.1)], fill=roof)
        y -= rh * 0.9
    d.line([(cx, y), (cx, y - w * 0.5)], fill=roof, width=max(1, int(w * 0.05)))


def karst(cx, top, w, rnd, step=6):
    """A tall limestone pillar: wobbly sides, rounded top, to the bottom edge."""
    left, right = [], []
    y = top
    while y < S + step:
        t = (y - top) / max(1, S - top)
        half = w * (0.35 + 0.65 * min(1, t * 2.2)) / 2
        left.append((cx - half + rnd.uniform(-1, 1) * K * 2, y))
        right.append((cx + half + rnd.uniform(-1, 1) * K * 2, y))
        y += step * K
    return left + right[::-1]


def wuxia(rnd):
    img = Image.new("RGBA", (S, S))
    vgrad(img, (0, 0, S, S), [(0, (34, 62, 138)), (0.4, (104, 146, 206)), (0.66, (232, 196, 168)), (1, (244, 206, 170))])
    layer(img, lambda d, l: d.ellipse([112 * K, 52 * K, 196 * K, 136 * K], fill=(255, 232, 180, 190)), blur=16 * K, base=(255, 232, 180))
    layer(img, lambda d, l: [cloud(d, x * K, y * K, w * K, rnd, (255, 255, 255, 150)) for x, y, w in [(40, 26, 40), (150, 18, 34)]], blur=4 * K, base=(255, 255, 255))

    def pillar(cx, top, w, dark, lit, green, pine=0, haze=0):
        def f(d, l):
            pts = karst(cx * K, top * K, w * K, rnd)
            d.polygon(pts, fill=dark + (255,))
            # lit face: the right part of the pillar (sun on the right)
            n = len(pts) // 2
            right = pts[n:]
            mid = [((a[0] + b[0]) / 2 + w * K * 0.08, a[1]) for a, b in zip(pts[:n], pts[n:][::-1])]
            d.polygon(mid + right, fill=lit + (255,))
            # ledges of shrubs
            for _ in range(int(w * 0.9)):
                i = rnd.randrange(n)
                x = rnd.uniform(pts[i][0], pts[-1 - i][0]) if i < n else pts[i][0]
                y = pts[i][1]
                r = rnd.uniform(1.2, 3.2) * K
                d.ellipse([x - r, y - r * 0.6, x + r, y + r * 0.6], fill=green + (255,))
            d.ellipse([cx * K - w * K * 0.2, top * K - 2 * K, cx * K + w * K * 0.2, top * K + 3 * K], fill=green + (255,))
            if pine:
                px, py = cx * K, top * K
                d.line([(px, py + 2 * K), (px + pine * 6 * K, py - 6 * K), (px + pine * 16 * K, py - 9 * K)], fill=(54, 40, 30, 255), width=2 * K)
                for ox, oy, r in [(6, -8, 6), (14, -11, 7), (21, -9, 5), (0, -4, 4)]:
                    x, y = px + pine * ox * K, py + oy * K
                    d.ellipse([x - r * K, y - r * 0.45 * K, x + r * K, y + r * 0.45 * K], fill=(30, 78, 52, 255))
                    d.ellipse([x - r * 0.7 * K, y - r * 0.45 * K, x + r * 0.5 * K, y], fill=(52, 110, 70, 255))
        layer(img, f, blur=haze)

    # far layer: hazy blue pillars + pagodas on top
    pillar(150, 66, 30, (112, 128, 170), (150, 160, 196), (104, 124, 150), haze=K // 2)
    pillar(24, 78, 24, (118, 134, 174), (154, 164, 198), (108, 128, 154), haze=K // 2)
    pillar(66, 96, 20, (124, 140, 178), (158, 168, 200), (112, 132, 158), haze=K // 2)
    layer(img, lambda d, l: pagoda(d, 150 * K, 67 * K, 15 * K, 4, (86, 98, 140, 255), (70, 80, 120, 255)))
    layer(img, lambda d, l: pagoda(d, 24 * K, 79 * K, 9 * K, 3, (92, 106, 146, 255), (76, 88, 128, 255)))
    layer(img, lambda d, l: [cloud(d, x * K, y * K, w * K, rnd, (252, 238, 230, 235)) for x, y, w in
                             [(10, 128, 50), (80, 136, 64), (170, 122, 54), (124, 112, 34), (52, 110, 28)]], blur=5 * K, base=(252, 238, 230))
    # near layer: dark green-grey pillars framing the view, pines on top
    pillar(-2, 60, 42, (60, 66, 70), (96, 100, 98), (44, 92, 56), pine=1)
    pillar(192, 52, 46, (56, 62, 68), (104, 104, 100), (40, 88, 54), pine=-1)
    layer(img, lambda d, l: [cloud(d, x * K, y * K, w * K, rnd, (255, 244, 236, 210)) for x, y, w in [(26, 160, 44), (168, 156, 40)]], blur=4 * K, base=(255, 244, 236))

    def cliff(d, l):
        top = [(46, 160), (58, 151), (76, 147), (118, 146), (138, 150), (150, 160)]
        d.polygon([(38 * K, S)] + [(x * K, y * K) for x, y in top] + [(156 * K, S)], fill=(66, 58, 58, 255))
        d.polygon([(x * K, y * K) for x, y in top] + [(130 * K, 155 * K), (84 * K, 156 * K)], fill=(116, 102, 92, 255))
        for x0, y0, x1, y1 in [(66, 166, 60, 188), (112, 160, 120, 188), (92, 170, 98, 188), (138, 166, 146, 188)]:
            d.line([(x0 * K, y0 * K), (x1 * K, y1 * K)], fill=(46, 40, 42, 255), width=K)
    layer(img, cliff)

    def P(pts, ox, oy):
        return [(ox + x * K, oy + y * K) for x, y in pts]

    def figures(d, l):
        gy = 150 * K
        # ── swordswoman (left), back view, red dress, cape blown left
        ox = 74 * K
        cape = [(-6, -46), (4, -46), (-1, -32), (-8, -18), (-20, -6), (-34, 0), (-46, -6), (-38, -12), (-30, -20), (-22, -30), (-14, -40)]
        d.polygon(P(cape, ox, gy), fill=(196, 30, 38, 255))
        d.line(P([(-6, -45), (-14, -40), (-22, -30), (-30, -20), (-38, -12), (-46, -6)], ox, gy), fill=(240, 92, 84, 255), width=K)
        d.line(P([(-2, -38), (-10, -22), (-24, -8)], ox, gy), fill=(150, 18, 28, 255), width=K)
        body = [(-7, -46), (7, -46), (5, -32), (4, -28), (10, -6), (12, 0), (-12, 0), (-10, -6), (-4, -28), (-5, -32)]
        d.polygon(P(body, ox, gy), fill=(160, 24, 34, 255))
        d.polygon(P([(-4, -28), (4, -28), (10, -6), (12, 0), (2, 0), (0, -20)], ox, gy), fill=(120, 16, 28, 255))   # fold
        d.polygon(P([(-5, -31), (5, -31), (5, -28), (-5, -28)], ox, gy), fill=(226, 182, 76, 255))                  # gold belt
        d.line(P([(-2, -28), (-4, -16)], ox, gy), fill=(120, 70, 150, 255), width=K)                                 # purple sash end
        d.polygon(P([(7, -45), (10, -42), (11, -30), (9, -28), (7, -32)], ox, gy), fill=(226, 196, 170, 255))       # bare right arm
        d.rectangle(P([(8, -34), (11, -31)], ox, gy), fill=(226, 182, 76, 255))                                      # bracer
        d.line(P([(10, -29), (24, -2)], ox, gy), fill=(228, 232, 240, 255), width=K + K // 2)                        # blade
        d.line(P([(8, -32), (12, -26)], ox, gy), fill=(226, 182, 76, 255), width=2 * K)                              # guard
        d.rectangle(P([(-2, -49), (2, -46)], ox, gy), fill=(222, 190, 164, 255))                                     # neck
        d.ellipse(P([(-5, -58), (5, -48)], ox, gy), fill=(34, 24, 24, 255))                                          # hair
        d.ellipse(P([(-3, -63), (3, -57)], ox, gy), fill=(34, 24, 24, 255))                                          # bun
        d.line(P([(-6, -61), (6, -60)], ox, gy), fill=(226, 182, 76, 255), width=K)                                  # hairpin
        d.line(P([(2, -58), (8, -52), (6, -44)], ox, gy), fill=(200, 30, 40, 255), width=K)                          # ribbon
        # ── swordsman (right), back view, blue robe, sword across the back
        ox = 106 * K
        d.line(P([(-24, -30), (22, -64)], ox, gy), fill=(64, 44, 32, 255), width=3 * K)                               # scabbard
        body = [(-12, -50), (12, -50), (10, -32), (8, -28), (13, -4), (15, 0), (-15, 0), (-13, -4), (-8, -28), (-10, -32)]
        d.polygon(P(body, ox, gy), fill=(34, 62, 116, 255))
        d.polygon(P([(1, -28), (8, -28), (13, -4), (15, 0), (4, 0)], ox, gy), fill=(26, 48, 92, 255))
        d.polygon(P([(-13, -50), (-4, -51), (-6, -42), (-15, -44)], ox, gy), fill=(96, 102, 116, 255))             # pauldrons
        d.polygon(P([(13, -50), (4, -51), (6, -42), (15, -44)], ox, gy), fill=(96, 102, 116, 255))
        d.polygon(P([(-9, -31), (9, -31), (9, -27), (-9, -27)], ox, gy), fill=(198, 152, 64, 255))                 # belt
        d.polygon(P([(-14, -44), (-11, -44), (-12, -26), (-15, -27)], ox, gy), fill=(30, 54, 100, 255))            # left arm
        d.polygon(P([(14, -44), (11, -44), (12, -30), (16, -24), (18, -26)], ox, gy), fill=(30, 54, 100, 255))     # right arm
        d.line(P([(17, -25), (34, 0)], ox, gy), fill=(222, 228, 238, 255), width=K + K // 2)                       # drawn blade
        d.line(P([(14, -28), (20, -23)], ox, gy), fill=(198, 152, 64, 255), width=2 * K)
        d.line(P([(18, -60), (26, -66)], ox, gy), fill=(198, 152, 64, 255), width=3 * K)                           # hilt over shoulder
        d.rectangle(P([(-2, -53), (2, -50)], ox, gy), fill=(206, 170, 140, 255))
        d.ellipse(P([(-6, -64), (6, -51)], ox, gy), fill=(28, 20, 18, 255))
        d.line(P([(1, -63), (8, -60), (14, -56), (18, -55)], ox, gy), fill=(28, 20, 18, 255), width=2 * K)         # ponytail in the wind
        d.line(P([(-5, -60), (5, -60)], ox, gy), fill=(160, 30, 36, 255), width=K)                                 # headband
        # rim light (sun on the right)
        d.line(P([(12, -49), (15, -1)], ox, gy), fill=(255, 212, 150, 170), width=K)
        d.line(P([(7, -45), (12, 0)], 74 * K, gy), fill=(255, 170, 130, 150), width=K)
    layer(img, figures)
    layer(img, lambda d, l: [d.line([(x * K - 3 * K, y * K - 1 * K), (x * K, y * K), (x * K + 3 * K, y * K - 1 * K)], fill=(44, 56, 92, 255), width=K // 2 + 1)
                             for x, y in [(98, 34), (106, 30), (92, 40), (116, 38)]])
    return img


# ── text (Tahoma = XP's UI font; any TTF with Vietnamese works) ─────────────
def font(size, bold=False):
    names = ["tahomabd.ttf", "arialbd.ttf"] if bold else ["tahoma.ttf", "arial.ttf"]
    for d in [os.environ.get("WINDIR", "C:/Windows") + "/Fonts", "/usr/share/fonts/truetype/msttcorefonts",
              "/Library/Fonts", "/System/Library/Fonts/Supplementary"]:
        for n in names:
            p = os.path.join(d, n)
            if os.path.exists(p):
                return ImageFont.truetype(p, size)
    return ImageFont.load_default(size)


def arrow(d, cx, cy, r, direction, fill, outline=None):
    """Chunky arrow key glyph pointing left/up/right/down."""
    base = [(-1, 0), (0, -1), (0, -0.45), (1, -0.45), (1, 0.45), (0, 0.45), (0, 1)]   # points left
    a = {"left": 0, "up": math.pi / 2, "right": math.pi, "down": -math.pi / 2}[direction]
    pts = [(cx + r * (x * math.cos(a) - y * math.sin(a)), cy + r * (x * math.sin(a) + y * math.cos(a))) for x, y in base]
    d.polygon(pts, fill=fill, outline=outline, width=K if outline else 0)


# ── Sàn nhảy (9x online dance games) ───────────────────────────────────────
def dance(rnd):
    img = Image.new("RGBA", (S, S))
    vgrad(img, (0, 0, S, S), [(0, (20, 8, 48)), (0.55, (56, 18, 96)), (1, (24, 10, 50))])
    # spotlight beams from the rig
    def beams(d, l):
        for x0, x1, c in [(20, 70, (255, 80, 200)), (94, 94, (120, 200, 255)), (168, 120, (255, 220, 90))]:
            d.polygon([(x0 * K - 3 * K, 0), (x0 * K + 3 * K, 0), (x1 * K + 30 * K, 130 * K), (x1 * K - 30 * K, 130 * K)], fill=c + (70,))
    layer(img, beams, blur=4 * K, base=(200, 160, 255))
    # glowing floor tiles in perspective
    def floor(d, l):
        top, bot = 104 * K, 150 * K
        cols = [(255, 70, 180), (80, 200, 255), (255, 210, 80), (130, 255, 160)]
        rows = 4
        for r in range(rows):
            y0 = top + (bot - top) * (r / rows) ** 1.2
            y1 = top + (bot - top) * ((r + 1) / rows) ** 1.2
            def xat(t, y):
                spread = 0.55 + 0.45 * (y - top) / (bot - top)
                return S / 2 + (t - 0.5) * S * 1.2 * spread
            for c in range(6):
                pts = [(xat(c / 6, y0), y0), (xat((c + 1) / 6, y0), y0), (xat((c + 1) / 6, y1), y1), (xat(c / 6, y1), y1)]
                on = rnd.random() < 0.45
                col = rnd.choice(cols) if on else (60, 30, 90)
                d.polygon(pts, fill=col + (255 if on else 255,), outline=(20, 8, 40, 255), width=K)
    layer(img, floor)
    layer(img, lambda d, l: d.rectangle([0, 104 * K, S, 150 * K], fill=(255, 255, 255, 30)), blur=6 * K, base=(255, 255, 255))
    # a dancer silhouette mid-move, lit from behind
    def dancer(d, l):
        cx, gy = 94 * K, 120 * K
        col = (16, 6, 30, 255)
        def limb(pts, w):
            pts = [(cx + x * K, gy + y * K) for x, y in pts]
            d.line(pts, fill=col, width=int(w * K), joint="curve")
            for x, y in pts:
                r = w * K / 2
                d.ellipse([x - r, y - r, x + r, y + r], fill=col)
        d.ellipse([cx - 6 * K, gy - 78 * K, cx + 6 * K, gy - 64 * K], fill=col)                       # head
        d.polygon([(cx - 7 * K, gy - 74 * K), (cx - 2 * K, gy - 82 * K), (cx + 7 * K, gy - 76 * K),
                   (cx + 12 * K, gy - 70 * K), (cx + 5 * K, gy - 72 * K)], fill=col)                 # spiky hair
        d.polygon([(cx - 11 * K, gy - 62 * K), (cx + 11 * K, gy - 62 * K), (cx + 9 * K, gy - 36 * K), (cx - 9 * K, gy - 36 * K)], fill=col)  # hoodie
        limb([(-9, -59), (-20, -48), (-26, -66)], 6)        # arm up
        limb([(9, -59), (22, -52), (32, -58)], 6)           # arm out
        d.polygon([(cx - 9 * K, gy - 38 * K), (cx + 1 * K, gy - 38 * K), (cx - 6 * K, gy - 18 * K),
                   (cx - 4 * K, gy - 2 * K), (cx - 18 * K, gy - 2 * K), (cx - 18 * K, gy - 18 * K)], fill=col)   # baggy leg
        d.polygon([(cx - 1 * K, gy - 38 * K), (cx + 9 * K, gy - 38 * K), (cx + 24 * K, gy - 26 * K),
                   (cx + 30 * K, gy - 10 * K), (cx + 20 * K, gy - 8 * K), (cx + 12 * K, gy - 22 * K)], fill=col)   # kicking leg
        d.ellipse([cx - 22 * K, gy - 4 * K, cx - 4 * K, gy + 3 * K], fill=col)                       # sneakers
        d.ellipse([cx + 20 * K, gy - 13 * K, cx + 36 * K, gy - 5 * K], fill=col)
        d.line([(cx - 8 * K, gy - 60 * K), (cx + 8 * K, gy - 40 * K)], fill=(255, 120, 220, 120), width=K)   # rim light
    layer(img, lambda d, l: d.ellipse([60 * K, 30 * K, 130 * K, 126 * K], fill=(255, 200, 255, 120)), blur=12 * K, base=(255, 200, 255))
    layer(img, dancer)
    # the arrow-key sequence bar + beat bar at the bottom
    def hud(d, l):
        d.rounded_rectangle([6 * K, 152 * K, 182 * K, 182 * K], 5 * K, fill=(10, 4, 24, 220), outline=(150, 110, 255, 255), width=K)
        seq = ["left", "up", "right", "down", "up", "left", "right"]
        for i, dr in enumerate(seq):
            cx = 20 * K + i * 22 * K
            done = i < 3
            d.rounded_rectangle([cx - 9 * K, 155 * K, cx + 9 * K, 171 * K], 3 * K,
                                fill=(70, 40, 140, 255) if not done else (40, 20, 70, 255))
            arrow(d, cx, 163 * K, 6 * K, dr, (255, 230, 90, 255) if done else (255, 255, 255, 255), (40, 20, 70, 255))
        d.rectangle([12 * K, 174 * K, 176 * K, 178 * K], fill=(60, 40, 110, 255))
        d.rectangle([12 * K, 174 * K, 120 * K, 178 * K], fill=(90, 220, 255, 255))
        d.rectangle([118 * K, 172 * K, 122 * K, 180 * K], fill=(255, 255, 255, 255))
    layer(img, hud)
    # "PERFECT" flash
    def perfect(d, l):
        f = font(20 * K, True)
        d.text((94 * K, 24 * K), "PERFECT", font=f, anchor="mm", fill=(255, 240, 120, 255), stroke_width=2 * K, stroke_fill=(200, 40, 140, 255))
        d.text((152 * K, 44 * K), "x12", font=font(11 * K, True), anchor="mm", fill=(255, 255, 255, 255), stroke_width=K, stroke_fill=(90, 40, 200, 255))
    layer(img, perfect)
    return img


# ── Tin nhắn nhanh (the 2000s messenger window, BUZZ!!!) ────────────────────
def smiley(d, cx, cy, r, mood="grin"):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 214, 40, 255), outline=(170, 110, 0, 255), width=K)
    e = r * 0.32
    d.ellipse([cx - e - r * 0.15, cy - r * 0.42, cx - r * 0.15, cy - r * 0.05], fill=(40, 30, 10, 255))
    d.ellipse([cx + r * 0.15, cy - r * 0.42, cx + r * 0.15 + e, cy - r * 0.05], fill=(40, 30, 10, 255))
    if mood == "grin":
        d.chord([cx - r * 0.6, cy - r * 0.3, cx + r * 0.6, cy + r * 0.65], 0, 180, fill=(120, 30, 20, 255))
    else:   # blush / shy
        d.arc([cx - r * 0.4, cy, cx + r * 0.4, cy + r * 0.5], 20, 160, fill=(40, 30, 10, 255), width=K)
        for sx in (-1, 1):
            d.ellipse([cx + sx * r * 0.55 - r * 0.2, cy + r * 0.05, cx + sx * r * 0.55 + r * 0.2, cy + r * 0.3], fill=(255, 120, 120, 200))


def messenger(rnd):
    img = Image.new("RGBA", (S, S))
    # a teal XP-era desktop behind the window
    vgrad(img, (0, 0, S, S), [(0, (60, 120, 200)), (1, (40, 90, 170))])
    win = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(win)
    x0, y0, x1, y1 = 10 * K, 10 * K, 178 * K, 178 * K
    d.rounded_rectangle([x0 + 3 * K, y0 + 4 * K, x1 + 3 * K, y1 + 4 * K], 6 * K, fill=(0, 0, 0, 90))
    d.rounded_rectangle([x0, y0, x1, y1], 6 * K, fill=(96, 40, 150, 255))
    # title bar (purple, glossy)
    tb = Image.new("RGBA", (x1 - x0, 20 * K))
    vgrad(tb, (0, 0, tb.width, tb.height), [(0, (170, 110, 230)), (0.5, (120, 50, 190)), (1, (96, 34, 160))])
    m = Image.new("L", tb.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, tb.width - 1, tb.height + 8 * K], 6 * K, fill=255)
    tb.putalpha(m)
    win.alpha_composite(tb, (x0, y0))
    smiley(d, x0 + 10 * K, y0 + 10 * K, 6 * K)
    d.text((x0 + 20 * K, y0 + 10 * K), "be_iu_9x - Tin nhắn", font=font(9 * K, True), anchor="lm", fill=(255, 255, 255, 255))
    for i, c in enumerate([(70, 120, 230), (70, 120, 230), (220, 70, 50)]):
        bx = x1 - (12 + (2 - i) * 13) * K
        d.rounded_rectangle([bx - 5 * K, y0 + 4 * K, bx + 5 * K, y0 + 15 * K], 2 * K, fill=c + (255,), outline=(255, 255, 255, 255), width=K // 2 + 1)
    d.line([(x1 - 15 * K, y0 + 7 * K), (x1 - 9 * K, y0 + 12 * K)], fill=(255, 255, 255, 255), width=K)
    d.line([(x1 - 9 * K, y0 + 7 * K), (x1 - 15 * K, y0 + 12 * K)], fill=(255, 255, 255, 255), width=K)
    # conversation pane
    cx0, cy0, cx1, cy1 = x0 + 4 * K, y0 + 22 * K, x1 - 4 * K, y0 + 116 * K
    d.rectangle([cx0, cy0, cx1, cy1], fill=(255, 255, 255, 255), outline=(130, 90, 170, 255), width=K)
    f, fb = font(9 * K), font(9 * K, True)
    lines = [
        ("be_iu_9x:", (40, 80, 200), "pe oi on chua?", (0, 0, 0)),
        ("cun_con_ham_an:", (200, 40, 40), "o quan net nek", (0, 0, 0)),
        ("be_iu_9x:", (40, 80, 200), "ra choi Au ko :))", (0, 0, 0)),
    ]
    y = cy0 + 6 * K
    for who, wc, msg, mc in lines:
        d.text((cx0 + 4 * K, y), who, font=fb, fill=wc + (255,))
        w = d.textlength(who, font=fb)
        d.text((cx0 + 6 * K + w, y), msg, font=f, fill=mc + (255,))
        y += 14 * K
    d.text((cx0 + 4 * K, y), "be_iu_9x:", font=fb, fill=(40, 80, 200, 255))
    d.text((cx0 + 6 * K + d.textlength("be_iu_9x:", font=fb), y - 2 * K), "BUZZ!!!", font=font(14 * K, True), fill=(220, 20, 30, 255))
    smiley(d, cx1 - 16 * K, cy1 - 14 * K, 9 * K, "shy")
    smiley(d, cx1 - 38 * K, cy1 - 12 * K, 7 * K, "grin")
    # toolbar + input box + send button
    ty = cy1 + 4 * K
    d.rectangle([cx0, ty, cx1, ty + 12 * K], fill=(236, 228, 246, 255))
    for i in range(5):
        smiley(d, cx0 + 8 * K + i * 14 * K, ty + 6 * K, 4 * K, "grin" if i % 2 == 0 else "shy")
    d.text((cx1 - 4 * K, ty + 6 * K), "BUZZ!", font=font(8 * K, True), anchor="rm", fill=(200, 30, 40, 255))
    iy = ty + 15 * K
    d.rectangle([cx0, iy, cx1 - 34 * K, y1 - 6 * K], fill=(255, 255, 255, 255), outline=(130, 90, 170, 255), width=K)
    d.text((cx0 + 4 * K, iy + 4 * K), "on roi nek, cho 5p|", font=f, fill=(60, 60, 60, 255))
    d.rounded_rectangle([cx1 - 30 * K, iy, cx1, y1 - 6 * K], 3 * K, fill=(240, 236, 226, 255), outline=(90, 90, 90, 255), width=K)
    d.text(((cx1 - 15 * K), (iy + y1 - 6 * K) / 2), "Gửi", font=font(9 * K, True), anchor="mm", fill=(0, 0, 0, 255))
    # the window shakes: rotate a touch and draw a ghost copy
    ghost = win.rotate(3, resample=Image.BICUBIC, center=(S / 2, S / 2))
    ga = ghost.getchannel("A").point(lambda v: v * 70 // 255)
    ghost.putalpha(ga)
    img.alpha_composite(ghost, (5 * K, 0))
    img.alpha_composite(win.rotate(-2, resample=Image.BICUBIC, center=(S / 2, S / 2)))
    return img


# ── Quán net (the corner internet café) ─────────────────────────────────────
def netcafe(rnd):
    img = Image.new("RGBA", (S, S))
    vgrad(img, (0, 0, S, S), [(0, (34, 40, 50)), (0.6, (50, 56, 66)), (1, (30, 30, 36))])
    # tiled wall + price board
    layer(img, lambda d, l: [d.line([(0, y * K), (S, y * K)], fill=(60, 66, 78, 255), width=K // 2 + 1) for y in range(0, 90, 10)])
    def board(d, l):
        d.rectangle([28 * K, 8 * K, 160 * K, 40 * K], fill=(250, 246, 230, 255), outline=(200, 30, 30, 255), width=2 * K)
        d.text((94 * K, 18 * K), "INTERNET - GAME", font=font(12 * K, True), anchor="mm", fill=(200, 20, 30, 255))
        d.text((94 * K, 32 * K), "3.000đ / 1 giờ", font=font(10 * K, True), anchor="mm", fill=(20, 40, 140, 255))
    layer(img, board)
    # ceiling fan blur
    layer(img, lambda d, l: d.ellipse([150 * K, -6 * K, 200 * K, 8 * K], fill=(120, 120, 130, 140)), blur=2 * K, base=(120, 120, 130))
    # desk
    vgrad(img, (0, 120 * K, S, S), [(0, (120, 80, 48)), (1, (80, 50, 30))])
    layer(img, lambda d, l: d.rectangle([0, 118 * K, S, 124 * K], fill=(150, 104, 64, 255)))

    def crt(d, l, cx, base, w, screen):
        h = w * 0.82
        x0, x1 = cx - w / 2, cx + w / 2
        y1 = base
        y0 = base - h
        d.rectangle([cx - w * 0.3, y1, cx + w * 0.3, y1 + w * 0.08], fill=(196, 190, 170, 255))      # foot
        d.rounded_rectangle([x0, y0, x1, y1], w * 0.06, fill=(220, 214, 196, 255), outline=(150, 146, 130, 255), width=K)
        sx0, sy0, sx1, sy1 = x0 + w * 0.09, y0 + w * 0.08, x1 - w * 0.09, y1 - w * 0.16
        d.rounded_rectangle([sx0, sy0, sx1, sy1], w * 0.05, fill=screen[0])
        screen[1](d, sx0, sy0, sx1, sy1)
        d.ellipse([x1 - w * 0.16, y1 - w * 0.11, x1 - w * 0.1, y1 - w * 0.05], fill=(90, 200, 90, 255))
        return (sx0, sy0, sx1, sy1)

    def game_scr(d, x0, y0, x1, y1):           # a top-down RPG map
        w, h = x1 - x0, y1 - y0
        d.rectangle([x0 + K, y0 + K, x1 - K, y1 - K], fill=(70, 120, 60, 255))
        d.polygon([(x0 + w * 0.1, y1 - K), (x0 + w * 0.45, y0 + h * 0.4), (x0 + w * 0.6, y1 - K)], fill=(160, 140, 100, 255))
        for _ in range(8):
            px, py = x0 + rnd.uniform(0.05, 0.95) * w, y0 + rnd.uniform(0.1, 0.8) * h
            d.ellipse([px - 2 * K, py - 2 * K, px + 2 * K, py + 2 * K], fill=(30, 80, 40, 255))
        d.rectangle([x0 + K, y1 - h * 0.18, x1 - K, y1 - K], fill=(30, 30, 50, 255))
        d.rectangle([x0 + 3 * K, y1 - h * 0.13, x0 + w * 0.4, y1 - h * 0.07], fill=(220, 40, 40, 255))

    def chat_scr(d, x0, y0, x1, y1):           # a messenger window on a blue desktop
        w, h = x1 - x0, y1 - y0
        d.rectangle([x0 + K, y0 + K, x1 - K, y1 - K], fill=(50, 100, 190, 255))
        d.rectangle([x0 + w * 0.3, y0 + h * 0.1, x1 - w * 0.08, y1 - h * 0.15], fill=(255, 255, 255, 255))
        d.rectangle([x0 + w * 0.3, y0 + h * 0.1, x1 - w * 0.08, y0 + h * 0.22], fill=(120, 50, 190, 255))
        for i in range(3):
            yy = y0 + h * (0.32 + i * 0.13)
            d.line([(x0 + w * 0.35, yy), (x1 - w * 0.2 - i * 4 * K, yy)], fill=(80, 80, 80, 255), width=K)
        d.rectangle([x0 + K, y1 - h * 0.1, x1 - K, y1 - K], fill=(40, 120, 40, 255))   # taskbar
        d.rectangle([x0 + K, y1 - h * 0.1, x0 + w * 0.18, y1 - K], fill=(60, 170, 60, 255))

    def dance_scr(d, x0, y0, x1, y1):
        w, h = x1 - x0, y1 - y0
        d.rectangle([x0 + K, y0 + K, x1 - K, y1 - K], fill=(60, 20, 100, 255))
        for i, dr in enumerate(["left", "up", "right", "down"]):
            arrow(d, x0 + w * (0.2 + i * 0.2), y1 - h * 0.2, w * 0.07, dr, (255, 230, 90, 255))
        d.ellipse([x0 + w * 0.42, y0 + h * 0.2, x0 + w * 0.58, y0 + h * 0.5], fill=(255, 120, 200, 255))

    def row(d, l):
        for x in (64, 124):
            d.polygon([(x * K - 3 * K, 70 * K), (x * K + 3 * K, 70 * K), (x * K + 5 * K, 120 * K), (x * K - 5 * K, 120 * K)], fill=(70, 50, 34, 255))
        crt(d, l, 34 * K, 112 * K, 54 * K, ((30, 30, 40, 255), chat_scr))
        crt(d, l, 154 * K, 112 * K, 54 * K, ((30, 30, 40, 255), dance_scr))
        crt(d, l, 94 * K, 124 * K, 70 * K, ((30, 30, 40, 255), game_scr))
    layer(img, row)
    # screen glow
    layer(img, lambda d, l: [d.ellipse([x * K - 40 * K, 60 * K, x * K + 40 * K, 140 * K], fill=c + (60,)) for x, c in
                             [(34, (90, 140, 255)), (94, (110, 200, 110)), (154, (200, 90, 255))]], blur=12 * K, base=(150, 150, 255))
    # partitions, keyboard, headset, iced tea
    def front(d, l):
        d.polygon([(60 * K, 150 * K), (128 * K, 150 * K), (136 * K, 168 * K), (52 * K, 168 * K)], fill=(214, 208, 190, 255), outline=(140, 136, 120, 255), width=K)
        for r in range(3):
            for c in range(10):
                x = 58 * K + c * 7.6 * K + r * 1.5 * K
                y = 153 * K + r * 5 * K
                d.rectangle([x + K, y, x + 6 * K, y + 3.5 * K], fill=(240, 236, 222, 255))
        # headset on the desk
        d.arc([140 * K, 136 * K, 176 * K, 172 * K], 190, 350, fill=(30, 30, 34, 255), width=3 * K)
        d.ellipse([136 * K, 150 * K, 148 * K, 166 * K], fill=(30, 30, 34, 255))
        d.ellipse([168 * K, 150 * K, 180 * K, 166 * K], fill=(30, 30, 34, 255))
        # trà đá
        d.polygon([(12 * K, 142 * K), (32 * K, 142 * K), (29 * K, 172 * K), (15 * K, 172 * K)], fill=(196, 130, 50, 220))
        d.polygon([(12 * K, 142 * K), (32 * K, 142 * K), (31 * K, 150 * K), (13 * K, 150 * K)], fill=(236, 220, 190, 200))
        d.rectangle([16 * K, 152 * K, 21 * K, 157 * K], fill=(240, 240, 255, 200))
        d.rectangle([22 * K, 158 * K, 27 * K, 163 * K], fill=(240, 240, 255, 200))
        d.line([(24 * K, 132 * K), (21 * K, 168 * K)], fill=(230, 60, 60, 255), width=K + 1)   # straw
    layer(img, front)
    return img


SCENES = [hills, lilies, lantern, cassette, wuxia, dance, messenger, netcafe]


def save(img, path):
    rgb = img.convert("RGB").resize((SIDE, SIDE), Image.LANCZOS)
    rnd = random.Random(path)
    grain(rgb, rnd, 3)
    for q in (88, 82, 75, 68, 60):
        rgb.save(path, "JPEG", quality=q, progressive=False, optimize=False, subsampling=2)
        if os.path.getsize(path) <= MAX_BYTES:
            return q, os.path.getsize(path)
    sys.exit(f"{path}: over {MAX_BYTES} B")


def main():
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):                  # a removed scene leaves no stale file
        if f.startswith("s") and f.endswith(".jpg"):
            os.remove(os.path.join(OUT, f))
    shots = []
    total = 0
    for i, scene in enumerate(SCENES, 1):
        img = scene(random.Random(i * 7919))
        path = os.path.join(OUT, f"s{i}.jpg")
        q, n = save(img, path)
        total += n
        shots.append(path)
        print(f"s{i}.jpg  {scene.__name__:10s} q{q}  {n} B")
    print(f"total {total} B")
    if "--sheet" in sys.argv:
        out = sys.argv[sys.argv.index("--sheet") + 1]
        sheet = Image.new("RGB", (4 * (SIDE * 2 + 8), 2 * (SIDE * 2 + 8)), (40, 40, 40))
        for k, p in enumerate(shots):
            im = Image.open(p).resize((SIDE * 2, SIDE * 2), Image.NEAREST)
            sheet.paste(im, ((k % 4) * (SIDE * 2 + 8), (k // 4) * (SIDE * 2 + 8)))
        sheet.save(out)


if __name__ == "__main__":
    main()
