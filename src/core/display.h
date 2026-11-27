#pragma once
#include <TFT_eSPI.h>
#include "config.h"
#include "layout.h"

extern TFT_eSPI tft;

namespace Display {
    void begin();                                  // tft.init + invertDisplay + backlight
    void setBrightness(uint8_t pct);               // 0-100, maps to inverted PWM
    void backlightOn();                            // full bright
    void backlightOff();
    void setInvert(bool on);                       // toggle ST7789 INVON/INVOFF at runtime

    // System screens, drawn after real XP (P-2026-11-26.9, screen_specs §17).
    // None shows an information line any more: the line / ssid / attempt /
    // pct arguments are accepted and ignored (the web page has them).
    void drawSplash(const char* line);             // boot: black, flag, logo, running box
    void splashStep(uint32_t step);                // boot box at step (= ms / 200); no-op off the boot screen
    void splashWait(uint32_t ms);                  // delay(ms) that keeps the boot box running
    void drawSetupMode(const char* ap, const char* ip);   // log-on screen: tile ap (split at '-') + ip
    void drawConnecting(const char* ssid, int attempt);   // welcome: painted once
    void drawError(const char* title, const char* msg);
    void drawOtaProgress(uint8_t pct);             // "đang cập nhật...": painted once

    // 16×16 glimmer spark logo — direct-blit, no FS dependency.
    void drawLogo(int x, int y, uint16_t color);

    // 16-row bitmap glyph (row bitmasks, MSB = leftmost pixel), each pixel
    // drawn as a scale×scale block. Shared by the logo, weather icons and
    // the status glyphs.
    void drawGlyph16(const uint16_t rows[16], int x, int y, uint16_t color, int scale = 1);

    // 16×16 key (credential problems) and 32-px circle-slash (blocked).
    void drawKeyGlyph(int x, int y, uint16_t color, int scale = 1);
    // Claude spark (12 rays), radius r px around (cx, cy).
    void drawClaudeMark(int cx, int cy, int r, uint16_t color);

    // Clawd, the Claude Code mascot: 18×10 cells of s px (s=3 → 54×30,
    // s=5 → 90×50). Paints every cell (body or bg), so redrawing it for a
    // blink or a step needs no separate clear.
    constexpr uint16_t CLAWD_ORANGE = 0xDBAA;   // #D97757
    // SHUT = a blink (eye holes filled); SLEEP = asleep (2-cell slits under a filled lid).
    enum ClawdEyes : uint8_t { CLAWD_OPEN, CLAWD_WIDE, CLAWD_HAPPY, CLAWD_SAD, CLAWD_SHUT, CLAWD_SLEEP };
    void drawClawd(int x, int y, int s, uint16_t color, uint8_t eyes = CLAWD_OPEN,
                   bool walking = false, uint16_t bg = 0x0000);
    // 7×7 symbol, cells of s px: '!' alert, '.' speech bubble, 'v' check, 'x' cross.
    void drawBadge(int x, int y, int s, char kind, uint16_t color);
    void drawSparkle(int cx, int cy, uint16_t color);
    void drawBlockedGlyph(int cx, int cy, uint16_t color);

    // Re-arm partial-redraw state for boot/system screens so the next
    // drawSplash/drawConnecting/drawOtaProgress paints chrome from scratch
    // (each also repaints when a different system screen was last up).
    // Call this whenever a channel takes over the screen or a different
    // system screen activates.
    void resetSystemScreens();
    // A system screen (boot, welcome, log-on, update) painted since the last
    // resetSystemScreens(): the taskbar pixels are gone, repaint it whole.
    bool systemScreenShown();

    // Clipped repaint (the mouse cursor moved; the panel can't be read back):
    // every drawing call is limited to (x, y, w, h) by the TFT viewport, in
    // screen coordinates. A channel's draw() checks repainting() to skip side
    // effects (stepping a slideshow, restarting an animation) and may use
    // clipRect() to skip work outside it (a JPEG decode stops early).
    void beginRepaint(int x, int y, int w, int h);
    void endRepaint();
    bool repainting();
    void clipRect(int& x, int& y, int& w, int& h);   // the whole panel when not repainting
    // (x, y, w, h) reaches into the clip — always true outside a clipped
    // repaint. Blocks that miss skip their work (and their font load, ~30 ms).
    bool clipHits(int x, int y, int w, int h);

    // Primitives reused by channels
    void clear();
    uint16_t usageColor(float pct);

    // ── Typography (VLW bitmap fonts from LittleFS) ──
    // Available VLW fonts:
    //   "VT323-86"        clock digits, hero numerics
    //   "VT323-44"        medium numerics (Claude/Codex %)
    //   "VT323-32"        small numerics + retro headlines
    //   "JBMono-16B"      headlines, card titles (TITLE)   JetBrains Mono Bold
    //   "JBMono-12B"      status-bar titles, labels        JetBrains Mono Bold
    //   "JBMono-13"       greeting, weather condition       JetBrains Mono
    //   "JBMono-11"       tabular data, detail lines (BODY) JetBrains Mono
    // VT323 and JetBrains Mono both ship every Vietnamese letter natively.
    // The JBMono files keep the line boxes of the fonts they replaced
    // (Silkscreen-16/12, PixelifySans-14, DMMono-11) — see tools/genfonts.py.
    //
    // FontTier shortcuts (Display::drawText uses these). For per-screen tuning,
    // call useFont() directly with a name from the list above.
    enum FontTier { HUGE, TITLE, BODY };
    void useFont(const char* name);          // 1-slot cache; ~50ms switch
    void releaseFont();                      // drop the loaded font (~2-5 KB free)
    void setFont(FontTier t);
    void drawText(const char* s, int x, int y, uint16_t color, FontTier t,
                  uint8_t datum = MC_DATUM, uint16_t bg = 0x1062);   // bg = Theme::BG
    int  textWidth(const char* s, FontTier t);
    int  fontHeight(FontTier t);

    // ── Design-system primitives (added v0.8) ──
    //
    // LEGACY (pre-XP) — forwards to the XP title bar (xp.h): title bar shows
    // "<title> · <meta>"; accent/metaColor are ignored. New code: XP::window,
    // XP::titleMeta. Removed once every channel is on XP (phase 2).
    void statusBar(const char* title, const char* rightMeta, uint16_t accent,
                   uint16_t metaColor = 0x8BF2 /* Theme::MUTED */);
    // Repaint only the status bar's right-meta slot (safe from tick()).
    void statusMeta(const char* rightMeta, uint16_t accent,
                    uint16_t metaColor = 0x8BF2 /* Theme::MUTED */);

    // Flat colored fill bar with 1-px frame. The design language.
    //   x, y, w, h:  full bar rectangle
    //   pct:         0..100 → fill width
    //   color:       fill color (track is PANEL, frame is LINE)
    void pixelBar(int x, int y, int w, int h, float pct, uint16_t color);

    // 1-px dotted divider line (4 px on, 1 px off).
    void dotsDivider(int x, int y, int w);

    // Animated "loading" chase dots (mirrors the WiFi-connecting screen).
    //   x, y:      top-left of the dot row (6-px dots on a 9-px pitch)
    //   litIndex:  which dot is lit; caller advances it (e.g. now_ms/150).
    //              Reduced mod `count` internally.
    //   accent:    lit-dot color; unlit dots use Theme::LINE.
    //   count:     number of dots (default 5).
    void loadingDots(int x, int y, int litIndex, uint16_t accent, int count = 5);
}
