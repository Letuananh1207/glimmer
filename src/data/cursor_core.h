#pragma once
// Mouse cursor (app = mouse / keyboard / power, device = screen; app plan
// docs/tasks/2026-11-27-app-la-chuot-ban-phim-nguon.md, R-DK-17) — pure
// logic, host-tested.
//
// The app owns the pointer: it sends the hotspot position (device pixels) and
// the shape in a tiny UDP datagram, ~30 / s, only on change; a lost packet is
// fixed by the next one. The device only draws it.
//
// The panel has no MISO: pixels can't be read back, so there is no
// save-under. Moving the cursor repaints the screen clipped to the old box
// (main.cpp repaintRect, TFT viewport), then draws the glyph at the new spot.
//
// Glyphs (P-2026-11-27.24, screen_specs §17 XP-Pointer): XP's Normal Select
// arrow 12×19 and Link Select hand 16×19 at real pixels, 'B' black, 'W' white,
// '.' transparent; Working in Background = the arrow + XP-Open's hourglass
// (9×12 at +10, +9; on its side 12×9 at +8, +11; sand xpAmber), a 21×22 box
// with the hotspot at the tip, 4 frames × 200 ms (cursor.cpp draws the glass).
#include <stdint.h>
#include <stddef.h>
#ifndef PROGMEM
#define PROGMEM
#endif

namespace CursorCore {

enum Shape : uint8_t { SHAPE_NONE = 0, SHAPE_ARROW, SHAPE_HAND, SHAPE_WAIT, SHAPE_COUNT };

constexpr uint16_t kPort       = 4210;   // UDP, reported in /api/state "cursor"
constexpr size_t   kPacketLen  = 8;      // 'G' 'C' ver shape seqHi seqLo x y
constexpr uint8_t  kVersion    = 1;
constexpr int      kScreen     = 240;
constexpr int      kMaxW       = 16;
constexpr int      kMaxH       = 22;
constexpr uint32_t kMinMoveMs  = 40;     // repaint + redraw at most ~25 / s

struct Packet {
    uint16_t seq = 0;
    uint8_t  x = 120, y = 120;
    Shape    shape = SHAPE_ARROW;
};

// A datagram from the app; false = not ours / malformed / out of range.
inline bool parse(const uint8_t* p, size_t n, Packet& out) {
    if (!p || n != kPacketLen || p[0] != 'G' || p[1] != 'C' || p[2] != kVersion) return false;
    if (p[3] >= SHAPE_COUNT || p[6] >= kScreen || p[7] >= kScreen) return false;
    out.shape = (Shape)p[3];
    out.seq   = (uint16_t)(p[4] << 8 | p[5]);
    out.x     = p[6];
    out.y     = p[7];
    return true;
}

// The app's encoder, shared by the tests (and mirrored in Dart).
inline void encode(const Packet& k, uint8_t out[kPacketLen]) {
    out[0] = 'G'; out[1] = 'C'; out[2] = kVersion; out[3] = (uint8_t)k.shape;
    out[4] = (uint8_t)(k.seq >> 8); out[5] = (uint8_t)k.seq; out[6] = k.x; out[7] = k.y;
}

// [a] is a later packet than [b] (16-bit sequence, wraps). UDP may reorder:
// an older packet after a newer one is dropped.
inline bool newer(uint16_t a, uint16_t b) { return (int16_t)(a - b) > 0; }

// Packet [seq] should replace the one at [last]: newer, or so far behind that
// it can't be a late packet — the app reopened and counts from 0 again.
constexpr uint16_t kRestartGap = 256;
inline bool stillCurrent(uint16_t seq, uint16_t last) {
    return newer(seq, last) || (uint16_t)(last - seq) >= kRestartGap;
}

// ── Glyphs ──────────────────────────────────────────────────────────────────

struct Glyph {
    uint8_t  w, h, hx, hy;          // size, hotspot
    uint16_t blk[kMaxH];            // bit 15 = column 0
    uint16_t wht[kMaxH];
};

constexpr uint16_t rowMask(const char* row, char c) {
    uint16_t m = 0;
    for (int i = 0; i < kMaxW && row[i]; i++)
        if (row[i] == c) m = (uint16_t)(m | (0x8000u >> i));
    return m;
}

template <int H>
constexpr Glyph makeGlyph(uint8_t w, uint8_t hx, uint8_t hy, const char* const (&rows)[H]) {
    Glyph g{w, (uint8_t)H, hx, hy, {}, {}};
    for (int r = 0; r < H; r++) {
        g.blk[r] = rowMask(rows[r], 'B');
        g.wht[r] = rowMask(rows[r], 'W');
    }
    return g;
}

// XP arrow 12 × 19, hotspot at the tip.
constexpr const char* kArrowRows[] = {
    "B...........",
    "BB..........",
    "BWB.........",
    "BWWB........",
    "BWWWB.......",
    "BWWWWB......",
    "BWWWWWB.....",
    "BWWWWWWB....",
    "BWWWWWWWB...",
    "BWWWWWWWWB..",
    "BWWWWWWWWWB.",
    "BWWWWWWBBBBB",
    "BWWWBWWB....",
    "BWWBBWWB....",
    "BWB..BWWB...",
    "BB...BWWB...",
    "B.....BWWB..",
    "......BWWB..",
    ".......BB...",
};

// XP link hand 16 × 19, hotspot at the fingertip.
constexpr const char* kHandRows[] = {
    ".....BB.........",
    "....BWWB........",
    "....BWWB........",
    "....BWWB........",
    "....BWWB........",
    "....BWWBBB......",
    "....BWWBWWBBB...",
    "....BWWBWWBWWBB.",
    ".BB.BWWBWWBWWBWB",
    "BWWBBWWWWWWWWBWB",
    "BWWWBWWWWWWWWWWB",
    ".BWWBWWWWWWWWWWB",
    "..BWWWWWWWWWWWWB",
    "..BWWWWWWWWWWWB.",
    "...BWWWWWWWWWWB.",
    "...BWWWWWWWWWB..",
    "....BWWWWWWWWB..",
    "....BWWWWWWWWB..",
    "....BBBBBBBBBB..",
};

// Working in Background: the arrow in a 21 × 22 box (the hourglass beside it
// is drawn on top, see kGlass*).
constexpr int kWaitW = 21, kWaitH = 22;
constexpr Glyph boxed(Glyph g, uint8_t w, uint8_t h) { g.w = w; g.h = h; return g; }

// The hourglass frame shown at [ms] (4 × 200 ms, as XP-Open's wait cursor).
constexpr uint32_t kWaitFrameMs = 200;
inline int waitFrame(uint32_t ms) { return (int)(ms / kWaitFrameMs % 4); }

// Indexed by Shape (SHAPE_NONE has no glyph: an empty one).
static const Glyph kGlyphs[SHAPE_COUNT] PROGMEM = {
    Glyph{0, 0, 0, 0, {}, {}},
    makeGlyph(12, 0, 0, kArrowRows),
    makeGlyph(16, 5, 0, kHandRows),
    boxed(makeGlyph(12, 0, 0, kArrowRows), kWaitW, kWaitH),
};

// ── Box on screen ───────────────────────────────────────────────────────────

struct Box {
    int16_t x = 0, y = 0, w = 0, h = 0;
    bool empty() const { return w <= 0 || h <= 0; }
};

// Screen rectangle the glyph covers with its hotspot at (x, y), clipped to
// the panel.
inline Box boxOf(int x, int y, const Glyph& g) {
    int x0 = x - g.hx, y0 = y - g.hy, x1 = x0 + g.w, y1 = y0 + g.h;
    if (x0 < 0) x0 = 0;
    if (y0 < 0) y0 = 0;
    if (x1 > kScreen) x1 = kScreen;
    if (y1 > kScreen) y1 = kScreen;
    Box b;
    if (x1 <= x0 || y1 <= y0) return b;
    b.x = (int16_t)x0; b.y = (int16_t)y0; b.w = (int16_t)(x1 - x0); b.h = (int16_t)(y1 - y0);
    return b;
}

inline bool overlaps(const Box& a, const Box& b) {
    return !a.empty() && !b.empty() && a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
}

}  // namespace CursorCore
