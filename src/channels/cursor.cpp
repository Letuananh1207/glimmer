#include <Arduino.h>
#include "cursor.h"
#include <WiFiUdp.h>
#include "display.h"
#include "xp.h"

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
uint32_t s_busyUntil = 0;        // Working in Background until then (XP::waitCursor)
bool     s_busy = false;
int8_t   s_drawnFrame = -1;      // hourglass frame on the panel (shape wait)

constexpr uint32_t kBusyHoldMs = 300;   // > one 200-ms tick of a loading screen

// Mouse v2: buttons held, the device's shape, presses waiting for main.cpp (a short queue: a click is 1 press).
bool     s_v2 = false;
uint8_t  s_buttons = 0;
Shape    s_devShape = SHAPE_ARROW;
constexpr int kPressQ = 4;
Cursor::PressAt s_press[kPressQ];
int      s_pressN = 0;
// Keys (stage 3): own seq (the 3 copies of a key are taken once).
InputCore::KeyPress s_keys[kPressQ];
int      s_keyN = 0;
bool     s_keySeen = false;
uint16_t s_keySeq = 0;

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

// The glyph, and for Working in Background the hourglass beside the arrow.
void paintCursor(const Packet& p, int frame) {
    paintGlyph(p.x, p.y, glyphOf(p.shape));
    if (p.shape == SHAPE_WAIT) XP::hourglass(frame, p.x, p.y);
}

// What to draw now: the app's shape, or wait while a window is busy.
Shape shapeNow(uint32_t now) {
    if (s_busy && (int32_t)(now - s_busyUntil) >= 0) s_busy = false;
    if (s_want.shape == SHAPE_NONE) return SHAPE_NONE;
    return s_busy ? SHAPE_WAIT : s_want.shape;
}

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
        if (got != len) continue;
        InputCore::KeyPress kp;
        if (InputCore::parseKey(buf, (size_t)got, kp)) {
            if (s_keySeen && !stillCurrent(kp.seq, s_keySeq)) continue;
            s_keySeen = true;
            s_keySeq = kp.seq;
            if (s_keyN < kPressQ) s_keys[s_keyN++] = kp;
            changed = true;
            continue;
        }
        InputCore::Mouse m;
        if (InputCore::parseMouse(buf, (size_t)got, m)) {
            // v2: every new seq counts in order (a press must not be lost to a later move).
            if (s_seen && !stillCurrent(m.seq, s_want.seq)) continue;   // late / one of the 3 copies
            InputCore::Press pr[2];
            const int np = InputCore::pressesOf(s_buttons, m.buttons, pr);
            for (int i = 0; i < np && s_pressN < kPressQ; i++) s_press[s_pressN++] = {pr[i], m.x, m.y, millis()};
            s_buttons = m.buttons;
            s_v2 = true;
            s_want.seq = m.seq;
            s_want.x = m.x;
            s_want.y = m.y;
            s_want.shape = s_devShape;
            s_seen = true;
            changed = true;
            continue;
        }
        Packet p;
        if (!parse(buf, (size_t)got, p)) continue;
        s_v2 = false;
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
    Packet want = s_want;
    want.shape = shapeNow(now);
    const int frame = want.shape == SHAPE_WAIT ? waitFrame(now) : -1;
    const bool same = s_shown && s_drawn.x == want.x && s_drawn.y == want.y && s_drawn.shape == want.shape
                   && s_drawnFrame == frame;
    if (same) return;
    if (s_shown && now - s_lastMove < kMinMoveMs) return;      // paced; the next pass catches up
    s_lastMove = now;
    erase(repaint);
    s_drawn = want;
    s_drawnFrame = (int8_t)frame;
    if (s_drawn.shape == SHAPE_NONE) return;
    paintCursor(s_drawn, frame);
    s_shown = true;
}

void overlay() {
    if (!s_shown || !s_allowed) return;
    paintCursor(s_drawn, s_drawnFrame);
}

bool mouseMode() { return s_seen && s_allowed && s_want.shape != SHAPE_NONE; }

bool busy(uint32_t now) {
    if (!mouseMode()) return false;
    s_busy = true;
    s_busyUntil = now + kBusyHoldMs;
    return true;
}

bool showBusyNow(uint32_t now) {
    if (!busy(now)) return false;
    if (!s_shown) return true;                   // step() draws it once the cursor shows
    s_drawn.shape = SHAPE_WAIT;                  // wait = arrow + hourglass: covers the arrow
    s_drawnFrame = (int8_t)waitFrame(now);
    paintCursor(s_drawn, s_drawnFrame);
    return true;
}

int drawnX() { return s_drawn.x; }
int drawnY() { return s_drawn.y; }

void screenRepainted() {
    // Whatever was under the old glyph is fresh now; draw it again on top.
    overlay();
}

bool deviceDriven() { return s_v2; }

void setShape(Shape s) {
    s_devShape = s;
    if (s_v2) s_want.shape = s;
}

int takeKeys(InputCore::KeyPress* out, int max) {
    const int n = s_keyN < max ? s_keyN : max;
    for (int i = 0; i < n; i++) out[i] = s_keys[i];
    for (int i = n; i < s_keyN; i++) s_keys[i - n] = s_keys[i];
    s_keyN -= n;
    return n;
}

int takePresses(PressAt* out, int max) {
    const int n = s_pressN < max ? s_pressN : max;
    for (int i = 0; i < n; i++) out[i] = s_press[i];
    for (int i = n; i < s_pressN; i++) s_press[i - n] = s_press[i];
    s_pressN -= n;
    return n;
}

bool    seen()  { return s_seen; }
uint8_t x()     { return s_want.x; }
uint8_t y()     { return s_want.y; }
uint8_t shape() { return s_want.shape; }
bool    shown() { return s_shown; }
uint16_t repaintMs()  { return s_repaintMs; }
uint16_t repaintMax() { return s_repaintMax; }

}  // namespace Cursor
