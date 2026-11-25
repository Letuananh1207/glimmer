#include "display.h"
#include "theme.h"
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
        case CLAWD_HAPPY: rows[2] |= kEyeBits; break;                        // low slit
        case CLAWD_SAD:   rows[2] = (rows[2] | kEyeBits) & ~kInnerBits; break; // "\ /" droop
        case CLAWD_SHUT:  rows[2] |= kEyeBits; rows[3] |= kEyeBits; break;   // blink
        case CLAWD_SLEEP: rows[2] |= kEyeBits;                                // "- -" asleep
                          rows[3] = (rows[3] | kEyeBits) & ~kSleepSlits; break;
        default: break;
    }
    if (walking) rows[8] = rows[9] = kWalkLegs;
    for (int j = 0; j < 10; j++) {
        // Runs of equal cells as single rects: few SPI transactions.
        int i = 0;
        while (i < 18) {
            const bool on = rows[j] & (1u << (17 - i));
            int k = i;
            while (k < 18 && (bool)(rows[j] & (1u << (17 - k))) == on) k++;
            tft.fillRect(x + i * s, y + j * s, (k - i) * s, s, on ? color : bg);
            i = k;
        }
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

// ── Boot/splash scenes (partial-redraw — chrome painted once per session) ───

// Session-level state shared across system screens (splash / connecting / OTA).
// resetSystemScreens() clears all of them so the next system screen paints
// from scratch.
static bool s_splashChrome     = false;
static char s_splashLine[48]   = "";
static char s_connectSsid[40]  = "";
static int  s_connectAttemptMin = -1;
static int  s_connectLitDot    = -1;
static int  s_otaChrome        = false;
static int  s_otaLastPct       = -1;

void Display::resetSystemScreens() {
    s_splashChrome      = false;
    s_splashLine[0]     = 0;
    s_connectSsid[0]    = 0;
    s_connectAttemptMin = -1;
    s_connectLitDot     = -1;
    s_otaChrome         = false;
    s_otaLastPct        = -1;
}

void Display::drawSplash(const char* line) {
    if (!s_splashChrome) {
        clear();
        // glimmer spark logo, centered
        drawLogo(SCREEN_W/2 - 8, 68, Theme::AMBER);
        // Wordmark
        useFont("JBMono-16B");
        tft.setTextDatum(MC_DATUM);
        tft.setTextColor(Theme::INK, Theme::BG);
        tft.drawString("GLIMMER", SCREEN_W/2, 104);
        // 5 loading dots
        int dotX = SCREEN_W/2 - 18;
        for (int i = 0; i < 5; i++) {
            uint16_t c = (i < 3) ? Theme::CORAL : Theme::LINE;
            tft.fillRect(dotX + i * 9, 130, 6, 6, c);
        }
        // Version (static)
        useFont("JBMono-11");
        tft.setTextColor(Theme::MUTED, Theme::BG);
        tft.drawString("v" FW_VERSION, SCREEN_W/2, 200);
        s_splashChrome = true;
        s_splashLine[0] = 0;
    }
    if (strcmp(line, s_splashLine) != 0) {
        // Repaint only the status-line band (y=148..170)
        tft.fillRect(0, 148, SCREEN_W, 18, Theme::BG);
        useFont("JBMono-11");
        tft.setTextDatum(MC_DATUM);
        tft.setTextColor(Theme::MUTED, Theme::BG);
        tft.drawString(line, SCREEN_W/2, 156);
        strncpy(s_splashLine, line, sizeof(s_splashLine) - 1);
    }
}

void Display::drawSetupMode(const char* ap, const char* ip) {
    clear();
    // Status bar: title "glimmer" + right meta "SETUP"
    statusBar("glimmer", "CÀI ĐẶT", Theme::CORAL);
    // Spark logo above the call-to-action
    drawLogo(SCREEN_W/2 - 8, 26, Theme::AMBER);

    Display::useFont("JBMono-12B");
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString("KẾT NỐI WI-FI", SCREEN_W/2, 44);

    Display::useFont("JBMono-16B");
    tft.setTextColor(Theme::INK, Theme::BG);
    tft.drawString(ap, SCREEN_W/2, 68);

    Display::dotsDivider(10, 96, SCREEN_W - 20);

    Display::useFont("JBMono-12B");
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString("RỒI MỞ", SCREEN_W/2, 116);

    Display::useFont("JBMono-16B");
    tft.setTextColor(Theme::SKY, Theme::BG);
    String url = String("http://") + ip;
    tft.drawString(url.c_str(), SCREEN_W/2, 140);

    // 5-dot heartbeat row (replaces mascot)
    int dotX = SCREEN_W/2 - 18;
    for (int i = 0; i < 5; i++) {
        uint16_t c = (i < 3) ? Theme::CORAL : Theme::LINE;
        tft.fillRect(dotX + i * 9, 176, 6, 6, c);
    }

    Display::useFont("JBMono-11");
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString("v" FW_VERSION, SCREEN_W/2, 204);
}

void Display::drawConnecting(const char* ssid, int attempt) {
    // Chrome painted once per SSID; dots + attempt counter partial-redraw.
    if (strcmp(ssid, s_connectSsid) != 0) {
        clear();
        drawLogo(SCREEN_W/2 - 8, 40, Theme::AMBER);
        useFont("JBMono-16B");
        tft.setTextDatum(MC_DATUM);
        tft.setTextColor(Theme::INK, Theme::BG);
        tft.drawString("GLIMMER", SCREEN_W/2, 68);
        useFont("JBMono-12B");
        tft.setTextColor(Theme::MUTED, Theme::BG);
        tft.drawString("Đang kết nối Wi-Fi", SCREEN_W/2, 100);
        useFont("JBMono-11");
        tft.setTextColor(Theme::INK, Theme::BG);
        tft.drawString(ssid, SCREEN_W/2, 124);
        tft.setTextColor(Theme::MUTED, Theme::BG);
        tft.drawString("v" FW_VERSION, SCREEN_W/2, 216);
        strncpy(s_connectSsid, ssid, sizeof(s_connectSsid) - 1);
        s_connectAttemptMin = -1;
        s_connectLitDot = -1;
    }

    // 5-dot loader
    int dotX = SCREEN_W/2 - 16;
    int lit = attempt % 5;
    if (lit != s_connectLitDot) {
        if (s_connectLitDot >= 0)
            tft.fillRect(dotX + s_connectLitDot * 9, 160, 6, 6, Theme::LINE);
        tft.fillRect(dotX + lit * 9, 160, 6, 6, Theme::CORAL);
        s_connectLitDot = lit;
    }

    // "attempt N" updates every ~60 s
    int attemptMin = (attempt / 120) + 1;
    if (attemptMin != s_connectAttemptMin) {
        tft.fillRect(0, 184, SCREEN_W, 16, Theme::BG);
        useFont("JBMono-11");
        tft.setTextDatum(MC_DATUM);
        tft.setTextColor(Theme::MUTED, Theme::BG);
        char msg[24]; snprintf(msg, sizeof(msg), "lần thử %d", attemptMin);
        tft.drawString(msg, SCREEN_W/2, 192);
        s_connectAttemptMin = attemptMin;
    }
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

void Display::drawOtaProgress(uint8_t pct) {
    if (!s_otaChrome) {
        clear();
        drawLogo(SCREEN_W/2 - 8, 30, Theme::AMBER);
        useFont("JBMono-16B");
        tft.setTextDatum(MC_DATUM);
        tft.setTextColor(Theme::INK, Theme::BG);
        tft.drawString("GLIMMER", SCREEN_W/2, 58);
        useFont("JBMono-12B");
        tft.setTextColor(Theme::CORAL, Theme::BG);
        tft.drawString("ĐANG CẬP NHẬT", SCREEN_W/2, 82);

        useFont("JBMono-11");
        tft.setTextColor(Theme::MUTED, Theme::BG);
        tft.drawString("đừng rút điện", SCREEN_W/2, 178);
        tft.drawString("v" FW_VERSION, SCREEN_W/2, 200);

        s_otaChrome = true;
        s_otaLastPct = -1;
    }
    if ((int)pct == s_otaLastPct) return;

    char buf[6]; snprintf(buf, sizeof(buf), "%u%%", (unsigned)pct);
    tft.fillRect(SCREEN_W/2 - 32, 100, 64, 32, Theme::BG);
    useFont("VT323-44");
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(Theme::CORAL, Theme::BG);
    tft.drawString(buf, SCREEN_W/2, 110);

    int barX = 12, barY = 148, barW = SCREEN_W - 24, barH = 12;
    tft.drawRect(barX, barY, barW, barH, Theme::LINE);
    int fillW = ((barW - 2) * pct) / 100;
    tft.fillRect(barX + 1, barY + 1, fillW, barH - 2, Theme::CORAL);
    if (fillW < barW - 2)
        tft.fillRect(barX + 1 + fillW, barY + 1, (barW - 2) - fillW, barH - 2, Theme::PANEL);

    s_otaLastPct = pct;
}

// ── Design-system primitives (v0.8) ─────────────────────────────────────────

void Display::statusBar(const char* title,
                        const char* rightMeta, uint16_t accent, uint16_t metaColor) {
    using namespace Layout;
    tft.fillRect(0, STATUS_TOP, SCREEN_W, STATUS_BOTTOM, Theme::BG);

    // Center title — JBMono-12B (design spec: .status .title { font-size: 12px })
    Display::useFont("JBMono-12B");
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(Theme::INK, Theme::BG);
    tft.drawString(title, SCREEN_W / 2, STATUS_BOTTOM / 2);

    // Right meta — JBMono-11 (design spec uses mono 9; 11 is closest VLW available)
    if (rightMeta && *rightMeta) {
        Display::useFont("JBMono-11");
        tft.setTextDatum(MR_DATUM);
        tft.setTextColor(metaColor, Theme::BG);
        tft.drawString(rightMeta, SCREEN_W - 4, STATUS_BOTTOM / 2);
    }

    // 1-px accent under-line at y=22
    tft.drawFastHLine(0, STATUS_BOTTOM, SCREEN_W, accent);
}

// Right-meta slot = the 76 px right of the centred title.
void Display::statusMeta(const char* rightMeta, uint16_t accent, uint16_t metaColor) {
    using namespace Layout;
    const int x = SCREEN_W - 76;
    tft.fillRect(x, STATUS_TOP, 76, STATUS_BOTTOM, Theme::BG);
    if (rightMeta && *rightMeta) {
        Display::useFont("JBMono-11");
        tft.setTextDatum(MR_DATUM);
        tft.setTextColor(metaColor, Theme::BG);
        tft.drawString(rightMeta, SCREEN_W - 4, STATUS_BOTTOM / 2);
    }
    tft.drawFastHLine(x, STATUS_BOTTOM, 76, accent);
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
    if (!strcmp(name, "Push"))    return CORAL;  // overridden per-card
    return MUTED;
}
