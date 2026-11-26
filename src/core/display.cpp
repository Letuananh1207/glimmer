#include "display.h"
#include "xp.h"
#include "theme.h"
#include "utf8.h"
#include "xp_core.h"
#include <LittleFS.h>
TFT_eSPI tft = TFT_eSPI();

// ── Typography — design-true VLW bitmap fonts ────────────────────────────
//
// Design Principle 01: pixel honest, antialiasing OFF.
// Our VLW files were rasterized with FT_LOAD_TARGET_MONO so each glyph cell is
// either 0 or 255 — TFT_eSPI's smooth-font path then renders without softening.
//
// Mapping:
//   HUGE       → VT323-86    big digits  (clock, %, temp)
//   HUGE_TEXT  → VT323-32    medium VT323 with full ASCII (headlines)
//   TITLE      → JBMono-16B  status-bar titles + section labels
//   TITLE_SM   → JBMono-12B  tighter heading
//   BODY       → JBMono-11   small tabular data
//
// 1-slot in-RAM cache: switching fonts takes ~50 ms (LittleFS read of ≤17 KB).
// Channels switch fonts max 3 × per draw → ~150 ms per channel transition.
// Acceptable since channels change every 8 s.

static const char* s_loadedFont = nullptr;

static const char* nameFor(Display::FontTier t) {
    switch (t) {
        case Display::HUGE:  return "VT323-86";   // VT323-64 is no longer shipped
        case Display::TITLE: return "JBMono-16B";
        case Display::BODY:  return "JBMono-11";
    }
    return "JBMono-11";
}

void Display::useFont(const char* name) {
    if (s_loadedFont && strcmp(s_loadedFont, name) == 0) return;
    if (s_loadedFont) tft.unloadFont();
    // VLW files live at /fonts/<name>.vlw on LittleFS. TFT_eSPI prepends '/'
    // and appends '.vlw', so pass "fonts/<name>". Also must pass LittleFS
    // explicitly because TFT_eSPI defaults to SPIFFS.
    String path = String("fonts/") + name;
    tft.loadFont(path, LittleFS);
    s_loadedFont = name;
}

// Drop the loaded VLW glyph cache to free heap before memory-hungry ops (TLS).
void Display::releaseFont() {
    if (s_loadedFont) { tft.unloadFont(); s_loadedFont = nullptr; }
}

// ── glimmer logo — 16×16 spark, direct-blit ──
//   ................
//   ................
//   ....#......#....
//   .....#....#.....
//   ......#..#......
//   .......##.......
//   .######..######.
//   .######..######.
//   .......##.......
//   ......#..#......
//   .....#....#.....
//   ....#......#....
//   ................
//   ................
//   ................
//   ................
static const uint16_t LOGO_ROWS[16] = {
    0x0000, 0x0000,
    0x0810, 0x0420, 0x0240, 0x0180,
    0x7E7E, 0x7E7E,
    0x0180, 0x0240, 0x0420, 0x0810,
    0x0000, 0x0000, 0x0000, 0x0000,
};

void Display::drawGlyph16(const uint16_t rows[16], int x, int y, uint16_t color, int scale) {
    for (int row = 0; row < 16; row++) {
        uint16_t bits = rows[row];
        if (!bits) continue;
        for (int col = 0; col < 16; col++) {
            if (!(bits & (1 << (15 - col)))) continue;
            if (scale <= 1) tft.drawPixel(x + col, y + row, color);
            else tft.fillRect(x + col * scale, y + row * scale, scale, scale, color);
        }
    }
}

void Display::drawLogo(int x, int y, uint16_t color) {
    drawGlyph16(LOGO_ROWS, x, y, color);
}

// ── key — ring on the left, shaft + two teeth to the right ──
//   ................
//   ................
//   ................
//   ..####..........
//   .#....#.........
//   #......#........
//   #......########.
//   #......########.
//   #......#...##.#.
//   .#....#....##.#.
//   ..####..........
static const uint16_t KEY_ROWS[16] = {
    0x0000, 0x0000, 0x0000, 0x3C00,
    0x4200, 0x8100, 0x81FE, 0x81FE,
    0x811A, 0x421A, 0x3C00, 0x0000,
    0x0000, 0x0000, 0x0000, 0x0000,
};

// ── Clawd — the Claude Code mascot ──
// The terminal sprite " ▐▛███▜▌ / ▝▜█████▛▘ /   ▘▘ ▝▝ " (quarter blocks in 2:1
// cells) as an 18×10 square-pixel grid; bit 17 = leftmost column.
static const uint32_t kClawd[10] = {
    0x07FF8, 0x07FF8,                // head
    0x06FD8, 0x06FD8,                // eyes: 1×2 holes at columns 5 and 12
    0x1FFFE, 0x1FFFE,                // arms
    0x07FF8, 0x07FF8,                // body
    0x02850, 0x02850,                // legs (standing)
};
static constexpr uint32_t kEyeBits   = (1u << 12) | (1u << 5);   // columns 5, 12
static constexpr uint32_t kInnerBits = (1u << 11) | (1u << 6);   // columns 6, 11
static constexpr uint32_t kWalkLegs  = 0x04848;                  // mid-stride
// Asleep: lid row filled, the row below cut as a 2-cell slit per eye (columns 4–5, 12–13).
static constexpr uint32_t kSleepSlits = (1u << 13) | (1u << 12) | (1u << 5) | (1u << 4);

void Display::drawClawd(int x, int y, int s, uint16_t color, uint8_t eyes, bool walking, uint16_t bg) {
    uint32_t rows[10];
    memcpy(rows, kClawd, sizeof(rows));
    switch (eyes) {
        case CLAWD_WIDE:  rows[1] &= ~kEyeBits; break;                       // 1×3 eyes
        case CLAWD_HAPPY: rows[2] |= kEyeBits; rows[3] |= kEyeBits; break;   // filled; holes below
        case CLAWD_SAD:   rows[2] = (rows[2] | kEyeBits) & ~kInnerBits; break; // "\ /" droop
        case CLAWD_SHUT:  rows[2] |= kEyeBits; rows[3] |= kEyeBits; break;   // blink
        case CLAWD_SLEEP: rows[2] |= kEyeBits;                                // "- -" asleep
                          rows[3] = (rows[3] | kEyeBits) & ~kSleepSlits; break;
        default: break;
    }
    if (walking) rows[8] = rows[9] = kWalkLegs;
    // Eye holes are always black, on any background (P-2026-11-26.11, token
    // themeXP.rules.clawdEyes): an off cell inside the head (rows 1–3, columns
    // 3–14) is an eye, not background.
    auto cellColor = [&](int j, int i) -> uint16_t {
        const uint32_t bit = 1u << (17 - i);
        if (rows[j] & bit) return color;
        return (j >= 1 && j <= 3 && (kClawd[0] & bit)) ? (uint16_t)0x0000 : bg;
    };
    for (int j = 0; j < 10; j++) {
        // Runs of equal cells as single rects: few SPI transactions.
        int i = 0;
        while (i < 18) {
            const uint16_t c = cellColor(j, i);
            int k = i;
            while (k < 18 && cellColor(j, k) == c) k++;
            tft.fillRect(x + i * s, y + j * s, (k - i) * s, s, c);
            i = k;
        }
    }
    if (eyes == CLAWD_HAPPY) {
        // "^ ^" + smile cut on a half-cell grid (P-2026-11-25.5, token
        // component.clawd.happyHoles): hole s/2 px at x + hx·s/2 (floored).
        static const uint8_t kHappyHoles[][2] = {
            {10, 5}, {9, 6}, {11, 6}, {25, 5}, {24, 6}, {26, 6},   // eyes
            {16, 9}, {19, 9}, {17, 10}, {18, 10},                  // mouth
        };
        const int h = s / 2 > 0 ? s / 2 : 1;
        for (const auto& c : kHappyHoles)
            tft.fillRect(x + c[0] * s / 2, y + c[1] * s / 2, h, h, 0x0000);   // black, like the eyes
    }
}

// 7×7 state symbols beside Clawd's head; bit 6 = leftmost column.
void Display::drawBadge(int x, int y, int s, char kind, uint16_t color) {
    static const uint8_t kBang[7]  = {0x3E, 0x6F, 0x6F, 0x6F, 0x7F, 0x6F, 0x3E};   // !
    static const uint8_t kTalk[7]  = {0x3E, 0x7F, 0x7F, 0x55, 0x7F, 0x30, 0x20};   // …
    static const uint8_t kCheck[7] = {0x01, 0x03, 0x46, 0x6C, 0x38, 0x10, 0x00};   // ✓
    static const uint8_t kCross[7] = {0x41, 0x22, 0x14, 0x08, 0x14, 0x22, 0x41};   // ✗
    const uint8_t* m = kind == '!' ? kBang : kind == '.' ? kTalk : kind == 'v' ? kCheck : kCross;
    for (int j = 0; j < 7; j++)
        for (int i = 0; i < 7; i++)
            if (m[j] & (0x40 >> i)) tft.fillRect(x + i * s, y + j * s, s, s, color);
}

// Small "+" twinkle (9×9 px) for the done card.
void Display::drawSparkle(int cx, int cy, uint16_t color) {
    tft.fillRect(cx - 4, cy, 10, 2, color);
    tft.fillRect(cx, cy - 4, 2, 10, color);
}

// ── Claude spark — 12 rays of uneven length meeting at the centre ──
// Pixel-honest (no anti-aliasing): each ray is stepped in half-pixel
// increments and stamped as a 2×2 block, so strokes stay 2 px wide.
void Display::drawClaudeMark(int cx, int cy, int r, uint16_t color) {
    static const struct { int16_t deg; uint8_t pct; } kRays[] = {
        {0, 100}, {31, 78}, {58, 95}, {92, 82}, {121, 100}, {150, 74},
        {182, 96}, {209, 80}, {241, 100}, {268, 76}, {299, 93}, {329, 84},
    };
    for (const auto& ray : kRays) {
        const float a = ray.deg * 0.0174533f;
        const float ux = cosf(a), uy = sinf(a);
        const float len = r * ray.pct / 100.0f;
        for (float s = 0; s <= len; s += 0.5f)
            tft.fillRect((int)lroundf(cx + ux * s) - 1, (int)lroundf(cy + uy * s) - 1, 2, 2, color);
    }
}

void Display::drawKeyGlyph(int x, int y, uint16_t color, int scale) {
    drawGlyph16(KEY_ROWS, x, y, color, scale);
}

// Circle with a diagonal slash, ~30 px across, 2 px stroke.
void Display::drawBlockedGlyph(int cx, int cy, uint16_t color) {
    tft.drawCircle(cx, cy, 14, color);
    tft.drawCircle(cx, cy, 13, color);
    for (int d = -1; d <= 1; d++)
        tft.drawLine(cx - 9 + d, cy + 9, cx + 9 + d, cy - 9, color);
}

void Display::setFont(FontTier t) { useFont(nameFor(t)); }

void Display::drawText(const char* s, int x, int y, uint16_t color, FontTier t,
                       uint8_t datum, uint16_t bg) {
    useFont(nameFor(t));
    tft.setTextDatum(datum);
    tft.setTextColor(color, bg);
    tft.drawString(s, x, y);
}

int Display::textWidth(const char* s, FontTier t) {
    useFont(nameFor(t));
    return tft.textWidth(s);
}

int Display::fontHeight(FontTier t) {
    useFont(nameFor(t));
    return tft.fontHeight();
}

static bool s_initialized = false;

void Display::begin() {
    if (s_initialized) return;
    tft.init();
    tft.setRotation(0);
    // Display inversion — default true (matches this panel's color tuning).
    // User can override via Settings.invertDisplay (applied in Display::setInvert()).
    tft.invertDisplay(true);
    tft.fillScreen(Theme::BG);

    pinMode(TFT_BL, OUTPUT);
    analogWriteFreq(1000);
    analogWriteRange(1023);
    analogWrite(TFT_BL, BL_FULL);                  // full bright on boot

    tft.setTextDatum(MC_DATUM);
    s_initialized = true;
}

void Display::setBrightness(uint8_t pct) {
    if (pct > 100) pct = 100;
    // Inverted PWM: 0 = full bright, 1023 = off
    uint16_t pwm = 1023 - (uint16_t)((uint32_t)pct * 1023 / 100);
    analogWrite(TFT_BL, pwm);
}

void Display::backlightOn()  { analogWrite(TFT_BL, BL_FULL); }
void Display::backlightOff() { analogWrite(TFT_BL, BL_OFF);  }
void Display::setInvert(bool on) { tft.invertDisplay(on); }

void Display::clear() {
    tft.fillScreen(Theme::BG);
}

uint16_t Display::usageColor(float pct) {
    if (pct < 0)       return Theme::MUTED;
    if (pct <= 20.0f)  return Theme::CORAL;
    if (pct <= 50.0f)  return Theme::AMBER;
    return Theme::MINT;
}

// ── System screens (P-2026-11-26.9, screen_specs §17, token themeXP.boot /
// themeXP.welcome) — drawn after real XP: boot, welcome, log-on, "updating".
// No information lines (version, network name, attempt, %): the web page has
// them. Partial-redraw: each screen paints its chrome once (s_sysScreen);
// only the boot box animates. resetSystemScreens() re-arms all of them.

// Italic words: 1-bit bitmaps generated from JBMono (slant 1 px / 3 rows),
// taken from design/panel/source/XP-{Connecting,SetupMode,OtaProgress}.
// kCornerBits: "Clawdsoft" italic 69×8, boot screen bottom-right — right edge
// x 231, top y 226 (P-2026-11-26.10, token themeXP.boot.corner), 9 bytes/row.
static const uint8_t kCornerBits[72] PROGMEM = {
    0x07, 0x38, 0x00, 0x00, 0x08, 0x00, 0x01, 0xC4, 0x00, 0x08, 0x88, 0x00, 0x00, 0x08, 0x00, 0x02,
    0x04, 0x00, 0x10, 0x10, 0x79, 0x28, 0xD3, 0xC3, 0x84, 0x1F, 0x00, 0x10, 0x10, 0x05, 0x29, 0x32,
    0x24, 0x4F, 0x88, 0x00, 0x10, 0x10, 0x7C, 0xE9, 0x13, 0x84, 0x44, 0x08, 0x00, 0x20, 0x20, 0x89,
    0xB2, 0x20, 0xC8, 0x88, 0x10, 0x00, 0x22, 0x20, 0x99, 0xA2, 0x64, 0x48, 0x88, 0x10, 0x00, 0x1C,
    0x1C, 0xE9, 0xA1, 0xA7, 0x87, 0x08, 0x0E, 0x00,
};

// kWelcomeBits: 71×12 at (70, 106), 9 bytes/row
static const uint8_t kWelcomeBits[108] PROGMEM = {
    0x00, 0x00, 0x00, 0x7C, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0xF8, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x0C, 0xC8, 0x78, 0x18, 0x07, 0x81, 0xE1, 0x6C, 0x1E,
    0x19, 0x91, 0xF8, 0x30, 0x1F, 0x87, 0xE3, 0xFC, 0x7E,
    0x09, 0xB3, 0x18, 0x30, 0x31, 0xCC, 0x63, 0x6C, 0xC6,
    0x0B, 0xB3, 0xF8, 0x30, 0x30, 0x0C, 0x63, 0x6C, 0xFE,
    0x15, 0x67, 0xF0, 0x60, 0x60, 0x18, 0xC6, 0xD9, 0xFC,
    0x1D, 0xC6, 0x00, 0x60, 0x60, 0x18, 0xC6, 0xD9, 0x80,
    0x1C, 0xC6, 0x30, 0x60, 0x63, 0x98, 0xC6, 0xD9, 0x8C,
    0x39, 0x87, 0xE0, 0x7C, 0x7E, 0x1F, 0x8D, 0xB1, 0xF8,
    0x19, 0x83, 0xC0, 0x7C, 0x3C, 0x0F, 0x0D, 0xB0, 0xF0,
};
// kWindowBits: 63×12 at (12, 102), 8 bytes/row
static const uint8_t kWindowBits[96] PROGMEM = {
    0x06, 0x64, 0x18, 0x00, 0x00, 0x60, 0x00, 0x00,
    0x0C, 0xC8, 0x30, 0x00, 0x00, 0xC0, 0x00, 0x00,
    0x0C, 0xC8, 0x00, 0x00, 0x00, 0xC0, 0x00, 0x00,
    0x04, 0xD8, 0xF0, 0x6E, 0x0F, 0xC1, 0xE3, 0x32,
    0x0B, 0xB1, 0xE0, 0xFE, 0x1F, 0x87, 0xE6, 0x64,
    0x0A, 0xB0, 0x60, 0xC6, 0x31, 0x8C, 0x62, 0x6C,
    0x0A, 0xB0, 0x60, 0xC6, 0x31, 0x8C, 0x62, 0xEC,
    0x1D, 0xE0, 0xC1, 0x8C, 0x63, 0x18, 0xC5, 0x58,
    0x1C, 0xC0, 0xC1, 0x8C, 0x63, 0x18, 0xC7, 0x70,
    0x1C, 0xC0, 0xC1, 0x8C, 0x63, 0x18, 0xC7, 0x30,
    0x39, 0x8F, 0xF3, 0x18, 0x7E, 0x1F, 0x8E, 0x60,
    0x39, 0x8F, 0xF3, 0x18, 0x7E, 0x0F, 0x06, 0x60,
};
// kUpdatingBits: 158×17 at (20, 96), 20 bytes/row
static const uint8_t kUpdatingBits[340] PROGMEM = {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x80, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0F, 0x00, 0x00, 0x00, 0x00, 0x30, 0x03, 0xC0, 0xC0, 0x00, 0x00, 0x00,
    0x00, 0xFC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x33, 0x00, 0x00, 0x00, 0x00, 0x60, 0x0C, 0xC1, 0x80, 0x00, 0x00, 0x00,
    0x00, 0xFC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x60, 0x00, 0x01, 0x80, 0x00, 0x00, 0x00,
    0x00, 0x30, 0x78, 0x6E, 0x0F, 0xC0, 0x00, 0x78, 0x1E, 0x1B, 0x80, 0x01, 0xB8, 0x6E, 0x07, 0x87, 0xF8, 0x00, 0x00, 0x00,
    0x07, 0xE1, 0xF8, 0xFE, 0x1F, 0x80, 0x01, 0xF8, 0x7E, 0x3F, 0x80, 0x03, 0xF8, 0xFE, 0x1F, 0x8F, 0xF0, 0x00, 0x00, 0x00,
    0x07, 0xE3, 0x18, 0xC6, 0x31, 0x80, 0x03, 0x1C, 0xC6, 0x31, 0x80, 0x03, 0x18, 0xC6, 0x31, 0x83, 0x00, 0x00, 0x00, 0x00,
    0x0C, 0x60, 0xF8, 0xC6, 0x31, 0x80, 0x03, 0x00, 0x3E, 0x31, 0x80, 0x03, 0x18, 0xC6, 0x0F, 0x83, 0x00, 0x00, 0x00, 0x00,
    0x18, 0xC7, 0xF1, 0x8C, 0x63, 0x00, 0x06, 0x01, 0xFC, 0x63, 0x00, 0x06, 0x31, 0x8C, 0x7F, 0x06, 0x00, 0x00, 0x00, 0x00,
    0x18, 0xC6, 0x31, 0x8C, 0x63, 0x00, 0x06, 0x01, 0x8C, 0x63, 0x00, 0x06, 0x31, 0x8C, 0x63, 0x06, 0x00, 0x00, 0x00, 0x00,
    0x18, 0xC6, 0x31, 0x8C, 0x73, 0x00, 0x06, 0x39, 0x8C, 0x63, 0x00, 0x06, 0x31, 0x8C, 0x63, 0x06, 0x00, 0xC0, 0x30, 0x0C,
    0x1F, 0x8F, 0xE3, 0x18, 0x7E, 0x00, 0x07, 0xE3, 0xF8, 0xFE, 0x00, 0x0C, 0x63, 0x18, 0xFE, 0x0F, 0x83, 0x80, 0xE0, 0x38,
    0x1F, 0x87, 0xE3, 0x18, 0x36, 0x00, 0x03, 0xC1, 0xF8, 0xDC, 0x00, 0x0C, 0x63, 0x18, 0x7E, 0x07, 0x81, 0x80, 0x60, 0x18,
    0x00, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x00, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0xFC, 0x00, 0x00, 0x00, 0x01, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0xF8, 0x00, 0x00, 0x00, 0xC1, 0x80, 0x00, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00,
};

enum SysScreen : uint8_t { SYS_NONE, SYS_SPLASH, SYS_WELCOME, SYS_SETUP, SYS_OTA };
static SysScreen s_sysScreen = SYS_NONE;
static int s_bootStep = -1;

bool Display::systemScreenShown() { return s_sysScreen != SYS_NONE; }

void Display::resetSystemScreens() {
    s_sysScreen = SYS_NONE;
    s_bootStep = -1;
}

// Text on a flat system-screen background.
static void sysText(const char* font, const char* s, int x, int y, uint16_t fg, uint16_t bg,
                    uint8_t datum = TL_DATUM) {
    Display::useFont(font);
    tft.setTextDatum(datum);
    tft.setTextColor(fg, bg);
    tft.drawString(s, x, y);
}

// Boot box (XP-Splash): 56×11 at (92, 152), xpBootGrey border with cut
// corners; 3 blue blocks 6×5 on 6 lanes from x 96, 8 apart (XPCore::bootLit).
static constexpr int kBootX = 92, kBootY = 152;
static void paintBootBlocks(uint32_t step) {
    using namespace Theme::XP;
    tft.fillRect(kBootX + 1, kBootY + 1, 54, 9, Theme::BG);
    for (int i = 0; i < XPCore::kBootLanes; i++) {
        if (!XPCore::bootLit(step, i)) continue;
        const int x = kBootX + 4 + 8 * i, y = kBootY + 3;
        tft.fillRect(x, y, 6, 5, BOOT_BLOCK);
        tft.drawFastHLine(x, y, 6, BOOT_BLOCK_HI);
        tft.drawFastHLine(x, y + 4, 6, BOOT_BLOCK_LO);
    }
}

void Display::drawSplash(const char*) {
    using namespace Theme::XP;
    if (s_sysScreen != SYS_SPLASH) {
        clear();
        // Wordmark centred as a block: x0 = (240 − (w(Window) + 16)) / 2.
        useFont("JBMono-16B");
        const int w = tft.textWidth("Window");
        const int x0 = (SCREEN_W - (w + 16)) / 2;
        XP::drawFlag(x0 + w - 26, 50, 3);
        sysText("JBMono-11", "Clawdsoft", x0, 89, WHITE, Theme::BG);
        sysText("JBMono-16B", "Window", x0, 103, WHITE, Theme::BG);
        sysText("JBMono-11", "xp", x0 + w + 2, 104, WELCOME_ORANGE, Theme::BG);
        sysText("JBMono-11", "Professional", x0 + 2, 122, WELCOME_ORANGE, Theme::BG);
        tft.drawRect(kBootX, kBootY, 56, 11, BOOT_GREY);
        tft.drawPixel(kBootX, kBootY, Theme::BG);
        tft.drawPixel(kBootX + 55, kBootY, Theme::BG);
        tft.drawPixel(kBootX, kBootY + 10, Theme::BG);
        tft.drawPixel(kBootX + 55, kBootY + 10, Theme::BG);
        XP::drawBits(kCornerBits, 69, 8, 163, 226, WHITE);   // maker's name, like XP's boot screen
        s_sysScreen = SYS_SPLASH;
        s_bootStep = -1;
    }
    splashStep(millis() / 200);
}

void Display::splashStep(uint32_t step) {
    if (s_sysScreen != SYS_SPLASH || (int)step == s_bootStep) return;
    paintBootBlocks(step);
    s_bootStep = (int)step;
}

void Display::splashWait(uint32_t ms) {
    const uint32_t t0 = millis();
    while (millis() - t0 < ms) {
        splashStep(millis() / 200);
        delay(20);
    }
}

// Welcome background (XP-Connecting / -SetupMode / -OtaProgress): xpWelcome,
// dark bands y 0–29 and 206–239, light line y 30, orange edge y 205–206
// fading to the sides.
static void welcomeChrome() {
    using namespace Theme::XP;
    tft.fillRect(0, 31, SCREEN_W, 174, WELCOME);
    tft.fillRect(0, 0, SCREEN_W, 30, WELCOME_BAND);
    tft.drawFastHLine(0, 30, SCREEN_W, WELCOME_LINE);
    tft.fillRect(0, 207, SCREEN_W, 33, WELCOME_BAND);
    static const struct { uint8_t x, w; uint16_t c; } kEdge[] = {
        {0, 40, BAND_EDGE}, {40, 40, BAND_EDGE_WARM}, {80, 80, WELCOME_ORANGE},
        {160, 40, BAND_EDGE_WARM}, {200, 40, BAND_EDGE},
    };
    for (const auto& e : kEdge) tft.fillRect(e.x, 205, e.w, 2, e.c);
}

// Italic word with its shadow (+1, +1).
static void italic(const uint8_t* bits, int w, int h, int x, int y) {
    XP::drawBits(bits, w, h, x + 1, y + 1, Theme::XP::WELCOME_SHADOW);
    XP::drawBits(bits, w, h, x, y, Theme::XP::WHITE);
}

// Log-on screen (XP-SetupMode): flag + "Window xp" + hint on the left, the
// selected "user" tile (= the setup network) on the right, power button.
void Display::drawSetupMode(const char* ap, const char* ip) {
    using namespace Theme::XP;
    resetSystemScreens();
    welcomeChrome();
    XP::drawFlag(70, 74, 2);
    italic(kWindowBits, 63, 12, 12, 102);
    sysText("JBMono-11", "xp", 81, 103, WELCOME_ORANGE, WELCOME);
    sysText("JBMono-11", "Để bắt đầu,", 14, 126, WHITE, WELCOME);
    sysText("JBMono-11", "kết nối Wi-Fi", 14, 140, WHITE, WELCOME);
    tft.drawFastVLine(116, 40, 30, DIVIDER_FADE);
    tft.drawFastVLine(116, 70, 100, DIVIDER);
    tft.drawFastVLine(116, 170, 30, DIVIDER_FADE);
    tft.fillRect(124, 86, 112, 50, USER_SEL);
    tft.drawFastHLine(124, 86, 112, USER_SEL_HI);
    tft.fillRect(130, 92, 24, 24, WHITE);
    tft.fillRect(132, 94, 20, 20, USER_PIC);
    drawClawd(133, 99, 1, CLAWD_ORANGE, CLAWD_OPEN, false, USER_PIC);
    // Theo XP thật a long user name wraps under itself: "glimmer-" / "setup".
    char l1[24], l2[24];
    const char* dash = strchr(ap, '-');
    if (dash && dash[1]) {
        size_t n = (size_t)(dash - ap) + 1;
        if (n >= sizeof(l1)) n = sizeof(l1) - 1;
        memcpy(l1, ap, n); l1[n] = '\0';
        Utf8::copy(l2, sizeof(l2), dash + 1);
    } else {
        Utf8::copy(l1, sizeof(l1), ap); l2[0] = '\0';
    }
    sysText("JBMono-12B", l1, 158, 92, WHITE, USER_SEL);
    if (l2[0]) sysText("JBMono-12B", l2, 158, 106, WHITE, USER_SEL);
    sysText("JBMono-11", ip, 158, 121, WELCOME_SUB, USER_SEL);
    tft.fillRect(8, 218, 14, 14, WHITE);
    tft.fillRect(9, 219, 12, 12, CLOSE);
    tft.fillRect(14, 221, 2, 5, WHITE);
    tft.fillRect(11, 223, 1, 5, WHITE);
    tft.fillRect(18, 223, 1, 5, WHITE);
    tft.fillRect(12, 228, 6, 1, WHITE);
    sysText("JBMono-11", "Cài đặt Wi-Fi", 28, 219, WHITE, WELCOME_BAND);
    s_sysScreen = SYS_SETUP;
}

// Welcome (XP-Connecting): only the italic "welcome" — ssid / attempt are
// no longer shown (P-2026-11-26.9); painted once, later calls are no-ops.
void Display::drawConnecting(const char*, int) {
    if (s_sysScreen == SYS_WELCOME) return;
    welcomeChrome();
    italic(kWelcomeBits, 71, 12, 70, 106);
    s_sysScreen = SYS_WELCOME;
}

void Display::drawError(const char* title, const char* msg) {
    resetSystemScreens();
    clear();
    Display::useFont("JBMono-16B");
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(Theme::CORAL, Theme::BG);
    tft.drawString(title, SCREEN_W/2, 90);
    Display::useFont("JBMono-11");
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString(msg, SCREEN_W/2, 135);
}

// Updating (XP-OtaProgress): italic "đang cập nhật..." + one warning line,
// no bar or % (P-2026-11-26.9) — painted once per flash.
void Display::drawOtaProgress(uint8_t) {
    if (s_sysScreen == SYS_OTA) return;
    welcomeChrome();
    italic(kUpdatingBits, 158, 17, 20, 96);
    sysText("JBMono-11", "Đừng tắt hay rút điện máy.", SCREEN_W / 2, 130,
            Theme::XP::WHITE, Theme::XP::WELCOME, TC_DATUM);
    s_sysScreen = SYS_OTA;
}

// ── Design-system primitives (v0.8) ─────────────────────────────────────────

// Legacy status bar → XP title bar (P-2026-11-26.8). Kept so channels not
// yet rewritten against XP:: (xp.h) still build: the title bar shows
// "<title> · <meta>" with XP::defaultIcon() (set by main.cpp per channel);
// accent / meta colours are ignored (XP title text is always white).
// Phase 2 replaces these calls with XP::window / XP::titleMeta.
void Display::statusBar(const char* title,
                        const char* rightMeta, uint16_t, uint16_t) {
    XP::titleBar(title, XP::defaultIcon());
    if (rightMeta && *rightMeta) XP::titleMeta(rightMeta);
}

// Legacy meta repaint → XP::titleMeta (title slot only, tick-safe).
void Display::statusMeta(const char* rightMeta, uint16_t, uint16_t) {
    XP::titleMeta(rightMeta);
}

void Display::pixelBar(int x, int y, int w, int h, float pct, uint16_t color) {
    if (pct < 0) pct = 0;
    if (pct > 100) pct = 100;
    // Discrete 9-segment meter — each cell is fully on or fully off.
    // 9 segments (not 10) so that any value ≥ 89% lights every cell.
    // Two bars at 92% and 99% then BOTH render as 9-of-9 full — no visual
    // "crossing" at the right edge between bars stacked on the same screen.
    // The hero text next to / above the bar carries the precise %.
    // Threshold: segment i lights when pct > i * (100/SEGS) = i * 11.11.
    //   pct=12 -> 1 lit        pct=89 -> all 9 lit
    //   pct=50 -> 4 lit        pct=99 -> all 9 lit
    //   pct=78 -> 7 lit        pct=100 -> all 9 lit
    constexpr int SEGS = 9;
    constexpr int GAP  = 1;
    tft.drawRect(x, y, w, h, Theme::LINE);
    int innerX = x + 1, innerY = y + 1;
    int innerW = w - 2, innerH = h - 2;
    int totalGaps = (SEGS - 1) * GAP;
    int segW = (innerW - totalGaps) / SEGS;
    int leftover = innerW - (segW * SEGS + totalGaps);
    const float segPct = 100.0f / (float)SEGS;     // 11.11% per segment
    int cx = innerX;
    for (int i = 0; i < SEGS; i++) {
        int sw = segW + (i < leftover ? 1 : 0);
        bool lit = (pct > (float)i * segPct);
        tft.fillRect(cx, innerY, sw, innerH, lit ? color : Theme::PANEL);
        cx += sw + GAP;
    }
}

void Display::dotsDivider(int x, int y, int w) {
    for (int i = 0; i < w; i += 4) tft.drawPixel(x + i, y, Theme::LINE);
}

void Display::loadingDots(int x, int y, int litIndex, uint16_t accent, int count) {
    int lit = ((litIndex % count) + count) % count;   // safe for negatives
    for (int i = 0; i < count; i++)
        tft.fillRect(x + i * 9, y, 6, 6, i == lit ? accent : Theme::LINE);
}

// Channel theme color — defined here (alongside Display because that's where it's
// used most) but declared in theme.h so other modules can call it.
uint16_t Theme::channelColor(const char* name) {
    if (!name) return MUTED;
    if (!strcmp(name, "Claude"))  return CORAL;
    if (!strcmp(name, "Codex"))   return LILAC;
    if (!strcmp(name, "Weather")) return SKY;
    if (!strcmp(name, "Forecast"))return SKY;
    if (!strcmp(name, "Clock"))   return AMBER;
    if (!strcmp(name, "Home"))    return AMBER;
    if (!strcmp(name, "AI"))      return INK_DIM;
    if (!strcmp(name, "Trend"))   return MINT;
    if (!strcmp(name, "Info"))    return MINT;
    if (!strcmp(name, "Photo"))   return MINT;
    if (!strcmp(name, "Push"))    return CORAL;  // overridden per-card
    return MUTED;
}
