#include <Arduino.h>
#include "cursor.h"
#include <WiFiUdp.h>
#include "display.h"

using namespace CursorCore;

namespace {

WiFiUDP  s_udp;
bool     s_listening = false;
bool     s_seen = false;
bool     s_allowed = false;

Packet   s_want;                 // what the app asked for
Packet   s_drawn;                // what is on the panel (valid while s_shown)
bool     s_shown = false;
uint32_t s_lastMove = 0;
uint16_t s_repaintMs = 0, s_repaintMax = 0;   // cost of the last / worst erase

Glyph glyphOf(uint8_t shape) {
    Glyph g;
    memcpy_P(&g, &kGlyphs[shape < SHAPE_COUNT ? shape : 0], sizeof(g));
    return g;
}

// Runs of one colour per row → drawFastHLine (≈ 40 calls for the arrow).
void paintGlyph(int x, int y, const Glyph& g) {
    const int x0 = x - g.hx, y0 = y - g.hy;
    for (int r = 0; r < g.h; r++) {
        const int py = y0 + r;
        if (py < 0 || py >= kScreen) continue;
        int c = 0;
        while (c < g.w) {
            const uint16_t bit = (uint16_t)(0x8000u >> c);
            const bool b = g.blk[r] & bit, w = g.wht[r] & bit;
            if (!b && !w) { c++; continue; }
            int k = c + 1;
            while (k < g.w) {
                const uint16_t kb = (uint16_t)(0x8000u >> k);
                if (((g.blk[r] & kb) != 0) != b || ((g.wht[r] & kb) != 0) != w) break;
                k++;
            }
            int a = x0 + c, e = x0 + k;              // [a, e)
            if (a < 0) a = 0;
            if (e > kScreen) e = kScreen;
            if (a < e) tft.drawFastHLine(a, py, e - a, b ? TFT_BLACK : TFT_WHITE);
            c = k;
        }
    }
}

Box boxOfDrawn() { return boxOf(s_drawn.x, s_drawn.y, glyphOf(s_drawn.shape)); }

void erase(Cursor::Repaint repaint) {
    if (!s_shown) return;
    s_shown = false;
    const Box b = boxOfDrawn();
    if (b.empty() || !repaint) return;
    const uint32_t t0 = millis();
    repaint(b.x, b.y, b.w, b.h);
    s_repaintMs = (uint16_t)(millis() - t0);
    if (s_repaintMs > s_repaintMax) s_repaintMax = s_repaintMs;
}

}  // namespace

namespace Cursor {

void begin() {
    if (s_listening) return;
    s_listening = s_udp.begin(kPort) == 1;
    Serial.printf_P(PSTR("[cursor] udp %u %s\n"), (unsigned)kPort, s_listening ? "ok" : "FAILED");
}

bool poll(uint32_t) {
    if (!s_listening) return false;
    bool changed = false;
    uint8_t buf[16];
    // Drain: only the newest packet matters.
    for (int n = 0; n < 8; n++) {
        const int len = s_udp.parsePacket();
        if (len <= 0) break;
        const int got = s_udp.read(buf, sizeof(buf));
        Packet p;
        if (got != len || !parse(buf, (size_t)got, p)) continue;
        if (s_seen && !stillCurrent(p.seq, s_want.seq)) continue;   // late / duplicate
        s_want = p;
        s_seen = true;
        changed = true;
    }
    return changed;
}

void setAllowed(bool allowed, Repaint repaint) {
    if (allowed == s_allowed) return;
    s_allowed = allowed;
    if (!allowed) erase(repaint);
}

void step(uint32_t now, Repaint repaint) {
    if (!s_allowed || !s_seen) return;
    const bool same = s_shown && s_drawn.x == s_want.x && s_drawn.y == s_want.y && s_drawn.shape == s_want.shape;
    if (same) return;
    if (s_shown && now - s_lastMove < kMinMoveMs) return;      // paced; the next pass catches up
    s_lastMove = now;
    erase(repaint);
    s_drawn = s_want;
    if (s_drawn.shape == SHAPE_NONE) return;
    paintGlyph(s_drawn.x, s_drawn.y, glyphOf(s_drawn.shape));
    s_shown = true;
}

void overlay() {
    if (!s_shown || !s_allowed) return;
    paintGlyph(s_drawn.x, s_drawn.y, glyphOf(s_drawn.shape));
}

void screenRepainted() {
    // Whatever was under the old glyph is fresh now; draw it again on top.
    overlay();
}

bool    seen()  { return s_seen; }
uint8_t x()     { return s_want.x; }
uint8_t y()     { return s_want.y; }
uint8_t shape() { return s_want.shape; }
bool    shown() { return s_shown; }
uint16_t repaintMs()  { return s_repaintMs; }
uint16_t repaintMax() { return s_repaintMax; }

}  // namespace Cursor
