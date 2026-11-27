#!/usr/bin/env python3
"""Generate the bitmaps of P-2026-11-27.25 (Start đủ chương trình, Dò mìn) → src/ui/mines_icons.h.

The P-.25 sources draw a whole 240×240 artboard as one <svg>: each <path fill="#RRGGBB"> is one colour made of
`M x y h w v1 h-w z` runs, and only the pixels that differ from the screen under it are there (unset = "as below").
This cuts pieces out of those artboards:

- Mines window (source/XP-Mines*.dc.html, §17 XP-Mines): the 4 faces 26×26 at (107, 29) (smile / wow / cool / dead),
  the mine 13×13 (cell + 2, 2; grey = transparent), the flag 9×9 (cell + 4, 3), the title-bar mine 13×13 at (6, 5)
  (only black / white kept), and the 7 segments of an LED digit 13×23 (connected pieces of the lit + unlit segments of
  the mines-left LED at (52, 31)).
- Desktop icon Dò mìn 32×23 at (104, 8) (source/XP-Desk-Fun.dc.html).
- Start All Programs icons 16×16 at (147, row + 2) (source/XP-Start-All-Full.dc.html): AI hôm nay, Xu hướng, Agents,
  Dò mìn. White (or unset) reached from the edge is transparent; white inside an outline stays.

Output per piece: a palette (RGB565), runs {x, y, w, colour index}, its size — in flash, like desk_icons.h.

    python tools/minesicons.py
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "design/panel/source"
OUT = ROOT / "src/ui/mines_icons.h"
CODE = "P-2026-11-27.25"


def rgb565(h):
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return (r >> 3) << 11 | (g >> 2) << 5 | b >> 3


def artboard(name):
    html = (SRC / f"{name}.dc.html").read_text(encoding="utf-8")
    px = {}
    for fill, d in re.findall(r'<path fill="#([0-9A-Fa-f]{6})" d="([^"]*)"', html):
        for x, y, w in re.findall(r"M(\d+) (\d+)h(\d+)v1h-\d+z", d):
            for i in range(int(w)):
                px[(int(x) + i, int(y))] = fill.upper()
    return px


def crop(px, x0, y0, w, h, keep=lambda c: True, unset=None, flood_white=False):
    """{(x, y): colour} of the piece, local coordinates; dropped = transparent."""
    cells = {}
    for y in range(h):
        for x in range(w):
            c = px.get((x0 + x, y0 + y), unset)
            if c is not None and keep(c):
                cells[(x, y)] = c
    if flood_white:
        seen, stack = set(), [(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)]
        while stack:
            p = stack.pop()
            if p in seen or not (0 <= p[0] < w and 0 <= p[1] < h):
                continue
            seen.add(p)
            if cells.get(p, "FFFFFF") != "FFFFFF":
                continue
            cells.pop(p, None)
            x, y = p
            stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    return cells


def runs_of(cells):
    pal, runs = [], []
    for (x, y) in sorted(cells, key=lambda p: (p[1], p[0])):
        c = cells[(x, y)]
        if c not in pal:
            pal.append(c)
        i = pal.index(c)
        if runs and runs[-1][1] == y and runs[-1][3] == i and runs[-1][0] + runs[-1][2] == x:
            runs[-1][2] += 1
        else:
            runs.append([x, y, 1, i])
    return pal, runs


def led_segments():
    """The 7 segments a..g of a 13×23 digit, as run lists (from the mines-left LED, digits '0' and '1')."""
    px = artboard("XP-Mines")
    seg = set()
    for k in range(2):                          # digit '0' (g off) and '1' (a, d, e, f, g off): all 7 drawn
        for y in range(23):
            for x in range(13):
                if px.get((52 + 13 * k + x, 31 + y)) in ("FF0000", "480000"):
                    seg.add((x, y))
    comps, seen = [], set()
    for p in sorted(seg):
        if p in seen:
            continue
        comp, stack = set(), [p]
        while stack:
            q = stack.pop()
            if q in seen or q not in seg:
                continue
            seen.add(q)
            comp.add(q)
            x, y = q
            stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
        comps.append(comp)
    assert len(comps) == 7, f"{len(comps)} LED segments"

    def centre(c):
        return (sum(x for x, _ in c) / len(c), sum(y for _, y in c) / len(c))

    named = {}
    for c in comps:
        cx, cy = centre(c)
        if cx > 4 and cx < 8:
            named["a" if cy < 6 else "g" if cy < 16 else "d"] = c
        elif cx <= 4:
            named["f" if cy < 11 else "e"] = c
        else:
            named["b" if cy < 11 else "c"] = c
    assert sorted(named) == list("abcdefg"), sorted(named)
    out = []
    for k in "abcdefg":
        _, r = runs_of({p: "FF0000" for p in named[k]})
        out.append(r)
    return out


def pieces():
    mines, play, win, lose = (artboard(n) for n in ("XP-Mines", "XP-Mines-Play", "XP-Mines-Win", "XP-Mines-Lose"))
    desk, start = artboard("XP-Desk-Fun"), artboard("XP-Start-All-Full")
    grey = lambda c: c != "C0C0C0"
    p = [
        ("FaceSmile", 26, 26, crop(mines, 107, 29, 26, 26)),
        ("FaceWow", 26, 26, crop(play, 107, 29, 26, 26)),
        ("FaceCool", 26, 26, crop(win, 107, 29, 26, 26)),
        ("FaceDead", 26, 26, crop(lose, 107, 29, 26, 26)),
        # Lose: a mine on cell (7, 0) (not the one clicked); Win: a flag on cell (7, 0).
        ("Mine", 13, 13, crop(lose, 48 + 16 * 7 + 2, 64 + 2, 13, 13, keep=grey)),
        ("Flag", 9, 9, crop(win, 48 + 16 * 7 + 4, 64 + 3, 9, 9, keep=grey)),
        ("TitleMine", 13, 13, crop(mines, 6, 5, 13, 13, keep=lambda c: c in ("000000", "FFFFFF"))),
        ("DeskMines", 32, 23, crop(desk, 104, 8, 32, 23)),
    ]
    for name, y in (("StartAi", 46), ("StartTrend", 66), ("StartAgents", 86), ("StartMines", 166)):
        p.append((name, 16, 16, crop(start, 147, y, 16, 16, unset="FFFFFF", flood_white=True)))
    return p


def main():
    lines = [
        f"// GENERATED by tools/minesicons.py from design/panel/source/XP-Mines*.dc.html, XP-Desk-Fun.dc.html,",
        f"// XP-Start-All-Full.dc.html ({CODE}) — do not edit by hand. Runs of one palette colour at real pixels; cells",
        "// with no run are transparent.",
        "#pragma once",
        "#include <stdint.h>",
        "#ifndef PROGMEM",
        "#define PROGMEM",
        "#endif",
        "",
        "namespace MinesIcons {",
        "struct Run { uint8_t x, y, w, c; };",
        "",
    ]
    for name, w, h, cells in pieces():
        pal, runs = runs_of(cells)
        lines.append(f"// {name}: {w}×{h}, {len(pal)} colours, {len(runs)} runs")
        lines.append(f"constexpr uint8_t k{name}W = {w}, k{name}H = {h};")
        lines.append(f"static const uint16_t k{name}Pal[] PROGMEM = {{")
        lines += [f"    0x{rgb565(c):04X}  /* #{c} */," for c in pal]
        lines.append("};")
        lines.append(f"static const Run k{name}Runs[] PROGMEM = {{")
        for i in range(0, len(runs), 6):
            lines.append("    " + " ".join(f"{{{x}, {y}, {rw}, {c}}}," for x, y, rw, c in runs[i:i + 6]))
        lines.append("};")
        lines.append(f"constexpr int k{name}RunCount = {len(runs)};")
        lines.append("")
    # 1-bit mask of the title mine (black pixels) for XP::drawIcon (the white taskbar mine, ICON_MINES).
    title = dict(next(c for n, _, _, c in pieces() if n == "TitleMine"))
    lines.append("// ICON_MINES: the title mine's black pixels, 13 wide, bit 12 = column 0 (XP::drawIcon rows).")
    lines.append("static const uint32_t kMineMask[13] PROGMEM = {")
    rows = []
    for y in range(13):
        v = 0
        for x in range(13):
            if title.get((x, y)) == "000000":
                v |= 1 << (12 - x)
        rows.append(f"0x{v:04X}")
    lines.append("    " + ", ".join(rows) + ",")
    lines.append("};")
    lines.append("")
    lines.append("// LED digit 13×23: segments a (top), b (top right), c (bottom right), d (bottom), e (bottom left),")
    lines.append("// f (top left), g (middle); runs {x, y, w, 0}. Digit d lights kLedDigits[d] bit (6 - segment).")
    for i, r in enumerate(led_segments()):
        lines.append(f"static const Run kSeg{'ABCDEFG'[i]}[] PROGMEM = {{")
        for k in range(0, len(r), 6):
            lines.append("    " + " ".join(f"{{{x}, {y}, {rw}, 0}}," for x, y, rw, _ in r[k:k + 6]))
        lines.append("};")
    lines.append("static const Run* const kSegs[7] = {kSegA, kSegB, kSegC, kSegD, kSegE, kSegF, kSegG};")
    lines.append("static const uint8_t kSegRuns[7] = {" + ", ".join(str(len(r)) for r in led_segments()) + "};")
    lines.append("//                             abcdefg")
    lines.append("static const uint8_t kLedDigits[10] = {0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B};")
    lines.append("constexpr uint8_t kLedMinus = 0x01;   // g only")
    lines.append("}  // namespace MinesIcons")
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
