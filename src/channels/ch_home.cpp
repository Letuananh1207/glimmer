// Home — the XP desktop (P-2026-11-26.12, screen_specs §17 XP-Desktop, token
// themeXP.desktop, source/XP-Desktop.dc.html). Replaces the "Trang chủ" window.
//
// chHomeDraw  → wallpaper (user JPEG /wallpaper.jpg, else the fallback pixel
//               wallpaper), desktop icons + labels, tray balloon; seeds the cache.
// chHomeTick  → 5 Hz: repaints only a label whose text changed (the wallpaper
//               under it restored from the JPEG / fallback first) and the
//               balloon's two text lines (solid INFO_BAR, no wallpaper).
//
//   y 0..213   wallpaper 240×214 at (0, 0) — no window, no title bar
//   icons      column centre x 40, cells 48 tall from y 8:
//                Clawd 18×10 ×2 (22, 9) · terminal 16×10 ×2 (24, 56)
//                photo 16×11 ×2 (24, 104) · trash 14×10 ×2 (26, 152)
//   labels     JBMono-11 white TC (40, cell + 24), black shadow (+1, +1):
//                "Claude 38%" · "Codex 71%" · "Ảnh" · "Thùng rác"
//   balloon    136×50 at (100, 150), black border, INFO_BAR, tail 8→1 px at
//              x 206 down to the tray clock (y 199..205); weather icon ×1
//              xpAmber (106, 155), "Thời tiết" 12B TL (126, 155), lines
//              JBMono-11 TL (106, 172) black and (106, 185) xpLabel.
//   taskbar    main.cpp's; no button pressed (XPCore::buttonFor("Home")).

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "weather.h"
#include "chrome.h"
#include "utf8.h"
#include "xp.h"
#include "wallpaper.h"
#include "desk_wallpaper.h"
#include <time.h>
#include <math.h>

namespace {
using namespace Theme::XP;

constexpr int kColX = 40;                    // icon column centre
constexpr int kCellY0 = 8, kCellH = 48;      // cell i: y 8 + 48 i
constexpr int kLabels = 4;                   // Claude, Codex, Ảnh, Thùng rác
constexpr int kLabelH = 16;                  // band y−1 .. y+14 (line box 13 + shadow + accents)
constexpr int kLabelMaxW = 80;               // column x 0..79
constexpr uint16_t kTrash = 0xDF3D;          // #DDE6EE xpDesk_DDE6EE

constexpr int kBalX = 100, kBalY = 150, kBalW = 136, kBalH = 50;
constexpr int kTailX = 206, kTailY = 199, kTailRows = 7;
constexpr int kLineX = 106, kLine1Y = 172, kLine2Y = 185;
constexpr int kLineW = kBalX + kBalW - 2 - kLineX;   // text up to x 233

// Terminal 16×10 and trash 14×10 (source XP-Desktop.dc.html), bit (w-1-x) = pixel x.
const uint16_t kTermBits[10] PROGMEM = {
    0xFFFF, 0x8001, 0xFFFF, 0x8001, 0xA001, 0x9001, 0xA701, 0x8001, 0x8001, 0xFFFF,
};
const uint16_t kPromptBits[3] PROGMEM = {0x20, 0x10, 0x27};   // 6×3 ">_"
const uint16_t kTrashBits[10] PROGMEM = {
    0x07F8, 0x0FFC, 0x1FFE, 0x0AA8, 0x0AA8, 0x0AA8, 0x0AA8, 0x0AA8, 0x0AA8, 0x07FC,
};

void drawCells(const uint16_t* rows, int w, int h, int x, int y, int scale, uint16_t color) {
    for (int r = 0; r < h; r++) {
        const uint16_t row = pgm_read_word(&rows[r]);
        for (int c = 0; c < w;) {
            if (!(row >> (w - 1 - c) & 1)) { c++; continue; }
            int run = 0;
            while (c + run < w && (row >> (w - 1 - c - run) & 1)) run++;
            tft.fillRect(x + c * scale, y + r * scale, run * scale, scale, color);
            c += run;
        }
    }
}

int labelY(int i) { return kCellY0 + kCellH * i + 24; }

// Label band of a text tw px wide (+1 shadow), centred on the column.
struct Band { int x, y, w, h; };
Band bandFor(int i, int tw) {
    int w = tw + 3;
    if (w > kLabelMaxW + 4) w = kLabelMaxW + 4;
    int x = kColX - w / 2;
    if (x < 0) x = 0;
    return {x, labelY(i) - 1, w, kLabelH};
}
Band unite(const Band& a, const Band& b) {
    const int x0 = a.x < b.x ? a.x : b.x, x1 = (a.x + a.w > b.x + b.w) ? a.x + a.w : b.x + b.w;
    return {x0, a.y, x1 - x0, a.h};
}

// The capture the label text blends its anti-aliased edges against.
const Wallpaper::Cap* s_bg = nullptr;
uint16_t bgAt(uint16_t x, uint16_t y) {
    const Wallpaper::Cap* c = s_bg;
    if (c && c->buf && x >= c->x && y >= c->y && x < c->x + c->w && y < c->y + c->h)
        return c->buf[(y - c->y) * c->w + (x - c->x)];
    return Wallpaper::present() ? BLACK : Wallpaper::fallbackAt(x, y);
}
uint16_t shadowAt(uint16_t, uint16_t) { return BLACK; }

}  // namespace

// ── File-static cache so tick() can diff vs last paint ──
static char     s_label[2][16];            // Claude / Codex label as drawn ("Claude 100%")
static int16_t  s_labelW[kLabels];         // drawn band width (0 = none)
static bool     s_balloon = false;         // balloon shown (weather configured)
static uint32_t s_balloonSig = 0;          // hash of the two lines + dim flag

static uint32_t sigOf(const char* a, const char* b, bool dim) {
    uint32_t h = dim ? 0x9E3779B9u : 2166136261u;   // FNV-1a
    for (const char* p = a; *p; p++) h = (h ^ (uint8_t)*p) * 16777619u;
    h = (h ^ 0xFFu) * 16777619u;
    for (const char* p = b; *p; p++) h = (h ^ (uint8_t)*p) * 16777619u;
    return h;
}

bool chHomeEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showHome
        && time(nullptr) > 1000000000L;
}

// ── Text of the moving parts ──

// "Claude 38%" while a usage % is known; the bare name otherwise (no key,
// loading, a credential problem) — theo XP thật a desktop icon is its name.
static void usageLabel(char* out, size_t n, const char* name, bool isClaude, Cred cred, float pct) {
    char note[64]; Chrome::credLine(isClaude, cred, note, sizeof(note));
    if (pct < 0 || note[0]) { snprintf_P(out, n, PSTR("%s"), name); return; }
    snprintf_P(out, n, PSTR("%s %.0f%%"), name, Api::shownPct(pct));
}

static void labelText(int i, const ChannelCtx& ctx, char* out, size_t n) {
    switch (i) {
        case 0: usageLabel(out, n, "Claude", true, ctx.claude->cred,
                           Api::claudeHeroPct(*ctx.settings, *ctx.claude)); break;
        case 1: usageLabel(out, n, "Codex", false, ctx.codex->cred,
                           Api::codexHeroPct(*ctx.settings, *ctx.codex)); break;
        case 2: Utf8::copy(out, n, "Ảnh"); break;
        default: Utf8::copy(out, n, "Thùng rác"); break;
    }
}

// Balloon lines: "29° · Ít mây" / "cảm giác 33°"; no reading yet →
// "chưa có thời tiết" in xpDim (as the old Home's NoWeather).
static void balloonText(const ChannelCtx& ctx, char* l1, size_t n1, char* l2, size_t n2, bool& dim) {
    const WeatherData& w = Weather::snapshot();
    const bool f = ctx.settings->useFahrenheit;
    dim = !w.valid;
    if (!w.valid) {
        Utf8::copy(l1, n1, "chưa có thời tiết");
        l2[0] = '\0';
        return;
    }
    char d[40]; Utf8::copy(d, sizeof(d), Weather::describe(w.code));
    snprintf_P(l1, n1, PSTR("%.0f\xC2\xB0 \xC2\xB7 %s"), Weather::toDisplay(w.tempC, f), d);
    if (w.feelsC > -900.f) snprintf_P(l2, n2, PSTR("cảm giác %.0f\xC2\xB0"), Weather::toDisplay(w.feelsC, f));
    else l2[0] = '\0';
}

// ── Painting ──

// Label text over the band already holding the wallpaper (cap = its pixels).
static void drawLabelText(int i, const char* text, const Wallpaper::Cap* cap) {
    Display::useFont("JBMono-11");
    tft.setTextDatum(TC_DATUM);
    const int y = labelY(i);
    s_bg = cap;
    tft.setCallback(bgAt);                   // shadow edges blend into the wallpaper
    tft.setTextColor(BLACK, WHITE);          // bg unused: the callback decides
    tft.drawString(text, kColX + 1, y + 1);
    tft.setCallback(shadowAt);               // text edges blend into the shadow
    tft.setTextColor(WHITE, BLACK);
    tft.drawString(text, kColX, y);
    tft.setCallback(nullptr);
    s_bg = nullptr;
}

static int measure(const char* text) {
    Display::useFont("JBMono-11");
    int w = tft.textWidth(text);
    return w > kLabelMaxW ? kLabelMaxW : w;
}

// One label from tick(): restore the wallpaper under the old ∪ new text, then
// draw. The capture buffer (≤ 84×16×2 B) is malloc'd for the call.
static void paintLabel(int i, const char* text) {
    char t[24]; Utf8::copy(t, sizeof(t), text);
    Display::useFont("JBMono-11");
    XP::fitText(t, kLabelMaxW);
    Band b = bandFor(i, measure(t));
    if (s_labelW[i]) b = unite(b, bandFor(i, s_labelW[i] - 3));
    Wallpaper::Cap cap{(int16_t)b.x, (int16_t)b.y, (int16_t)b.w, (int16_t)b.h, nullptr};
    cap.buf = (uint16_t*)malloc((size_t)b.w * b.h * 2);
    Wallpaper::paint(b.x, b.y, b.w, b.h, &cap, 1);
    drawLabelText(i, t, cap.buf ? &cap : nullptr);
    free(cap.buf);
    s_labelW[i] = (int16_t)(measure(t) + 3);
    if (i < 2) Utf8::copy(s_label[i], sizeof(s_label[i]), text);
}

static void paintBalloonLines(const char* line1, const char* line2, bool dim) {
    tft.fillRect(kLineX, kLine1Y - 1, kLineW, 27, INFO_BAR);   // y 171..197 (border at 199)
    Display::useFont("JBMono-11");
    tft.setTextDatum(TL_DATUM);
    char a[48]; Utf8::copy(a, sizeof(a), line1);
    XP::fitText(a, kLineW);
    tft.setTextColor(dim ? DIM : BLACK, INFO_BAR);
    tft.drawString(a, kLineX, kLine1Y);
    if (line2[0]) {
        char b[32]; Utf8::copy(b, sizeof(b), line2);
        XP::fitText(b, kLineW);
        tft.setTextColor(LABEL, INFO_BAR);
        tft.drawString(b, kLineX, kLine2Y);
    }
}

static void paintBalloon(const char* line1, const char* line2, bool dim) {
    tft.fillRect(kBalX, kBalY, kBalW, kBalH, BLACK);
    tft.fillRect(kBalX + 1, kBalY + 1, kBalW - 2, kBalH - 2, INFO_BAR);
    // Tail: 8 → 2 px wide, black edges, opening the bottom border at x 207..212.
    for (int k = 0; k < kTailRows; k++) {
        const int w = 8 - k;
        tft.drawFastHLine(kTailX, kTailY + k, w, INFO_BAR);
        tft.drawPixel(kTailX, kTailY + k, BLACK);
        tft.drawPixel(kTailX + w - 1, kTailY + k, BLACK);
    }
    XP::drawIcon(XPCore::ICON_WEATHER, 106, 155, 1, AMBER);
    Display::useFont("JBMono-12B");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(BLACK, INFO_BAR);
    tft.drawString("Thời tiết", 126, 155);
    paintBalloonLines(line1, line2, dim);
}

static void drawIcons() {
    XP::drawIcon(XPCore::ICON_CLAWD, 22, 9, 2, 0);            // Clawd orange, black eyes
    drawCells(kTermBits, 16, 10, 24, 56, 2, WHITE);           // command window
    tft.fillRect(26, 62, 28, 12, BLACK);
    drawCells(kPromptBits, 6, 3, 28, 64, 2, BAR);
    XP::drawIcon(XPCore::ICON_PHOTO, 24, 104, 2, WHITE);
    drawCells(kTrashBits, 14, 10, 26, 152, 2, kTrash);
}

// ── Full repaint ──

void chHomeDraw(const ChannelCtx& ctx) {
    // Label texts and bands first (the font is needed to measure them).
    char text[kLabels][24];
    Wallpaper::Cap caps[kLabels];
    for (int i = 0; i < kLabels; i++) {
        labelText(i, ctx, text[i], sizeof(text[i]));
        Display::useFont("JBMono-11");
        XP::fitText(text[i], kLabelMaxW);
        Band b = bandFor(i, measure(text[i]));
        caps[i] = {(int16_t)b.x, (int16_t)b.y, (int16_t)b.w, (int16_t)b.h, nullptr};
        s_labelW[i] = (int16_t)b.w;
    }
    // One decode paints the whole wallpaper and keeps the four label bands
    // for the text's anti-aliasing (~2 KB each; a failed malloc just means
    // that label blends against black).
    if (Wallpaper::present()) Display::releaseFont();
    for (int i = 0; i < kLabels; i++) caps[i].buf = (uint16_t*)malloc((size_t)caps[i].w * caps[i].h * 2);
    Wallpaper::paint(0, 0, Wallpaper::kW, Wallpaper::kH, caps, kLabels);

    drawIcons();
    for (int i = 0; i < kLabels; i++) {
        drawLabelText(i, text[i], caps[i].buf ? &caps[i] : nullptr);
        free(caps[i].buf);
        if (i < 2) labelText(i, ctx, s_label[i], sizeof(s_label[i]));
    }

    // Tray balloon — weather, when a location is set.
    s_balloon = Weather::configured(*ctx.settings);
    if (s_balloon) {
        char l1[48], l2[32]; bool dim;
        balloonText(ctx, l1, sizeof(l1), l2, sizeof(l2), dim);
        paintBalloon(l1, l2, dim);
        s_balloonSig = sigOf(l1, l2, dim);
    }
}

// ── Tick: 5 Hz, region-only repaints ──

void chHomeTick(const ChannelCtx& ctx) {
    char t[16];
    for (int i = 0; i < 2; i++) {             // Ảnh / Thùng rác never change
        labelText(i, ctx, t, sizeof(t));
        if (strcmp(t, s_label[i])) paintLabel(i, t);
    }
    if (s_balloon) {
        char l1[48], l2[32]; bool dim;
        balloonText(ctx, l1, sizeof(l1), l2, sizeof(l2), dim);
        const uint32_t sig = sigOf(l1, l2, dim);
        if (sig != s_balloonSig) { paintBalloonLines(l1, l2, dim); s_balloonSig = sig; }
    }
}
