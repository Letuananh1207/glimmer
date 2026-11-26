// Clock — XP "Date and Time Properties" (P-2026-11-26.17, screen_specs §17
// XP-Real, source XP-Clock-Props.dc.html). Partial-redraw tick().
//
//   window      "Ngày và Giờ", no status bar
//   tabs        "Ngày và giờ" (selected) · "Múi giờ"; page (6, 41, 228×169) white
//   Ngày        groupbox (10, 54, 122×128): month field (14, 62, 114×16) "11/2026"
//               + drop button; weekday row y 82 (T2 … CN, cells 16 from x 13),
//               rule (13, 96, 112×1); 7 × 6 day grid, cells 16×13 from (13, 98),
//               weeks from Monday, other months xpDim, today xpSelect / white
//   Giờ         groupbox (136, 54, 94×128): analog face centre (183, 106) —
//               hour marks r 33 (3×3 at 12/3/6/9, else 2×2) xpTitle, minute dots
//               r 34 xpDim, hands hour 18/3 · minute 27/2 black · second 30/1 xpRed,
//               pin 3×3; time field (145, 152, 76×18) "14:32:15" 12B (12 h:
//               "2:32 CH") + spin buttons (208, 153, 12×16)
//   y 189       "Múi giờ: GMT+7 · Hà Nội" JBMono-11 (place from the app's location)
//
// tick(): every second only the face (147..219, 70..142) and the time text;
// a new day redraws the calendar.

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "clockfmt.h"
#include "layout.h"
#include "utf8.h"
#include "xp.h"
#include <time.h>

namespace C = Theme::XP;

static int  s_lastSec = -1, s_lastMin = -1, s_lastYday = -1;
static char s_lastTime[16] = "";

static constexpr int kCx = 183, kCy = 106;
static constexpr int kFaceX = 147, kFaceY = 70, kFaceW = 73, kFaceH = 73;
static constexpr int kCalX = 13, kCalY = 98, kCellW = 16, kCellH = 13;

bool chClockEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showClock
        && time(nullptr) > 1000000000L;
}

// ── Calendar ──

static void paintMonthField(const struct tm& tmv) {
    XP::field(14, 62, 114, 16);
    char b[12]; snprintf_P(b, sizeof(b), PSTR("%02d/%d"), tmv.tm_mon + 1, tmv.tm_year + 1900);
    Display::useFont("JBMono-11");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(C::BLACK, C::WHITE);
    tft.drawString(b, 17, 63);
    // Drop-down button 14×14 + white triangle 5×3.
    tft.fillRect(113, 63, 14, 14, C::BTN);
    for (int r = 0; r < 3; r++) tft.drawFastHLine(116 + r, 69 + r, 5 - 2 * r, C::WHITE);
}

static void paintCalendar(const struct tm& tmv) {
    static const char* const kHead[7] = {"T2", "T3", "T4", "T5", "T6", "T7", "CN"};
    tft.fillRect(kCalX, 80, 7 * kCellW, kCalY + 6 * kCellH - 80, C::WHITE);
    Display::useFont("JBMono-11");
    tft.setTextDatum(TC_DATUM);
    tft.setTextColor(C::GROUP_LABEL, C::WHITE);
    for (int i = 0; i < 7; i++) tft.drawString(kHead[i], kCalX + kCellW * i + kCellW / 2, 82);
    tft.drawFastHLine(kCalX, 96, 112, C::GROUP);

    const int year = tmv.tm_year + 1900, month = tmv.tm_mon + 1;
    const int wdayFirst = (tmv.tm_wday - (tmv.tm_mday - 1) % 7 + 7) % 7;
    for (int i = 0; i < 42; i++) {
        const XPCore::CalCell c = XPCore::calCell(i, year, month, wdayFirst);
        const int x = kCalX + kCellW * (i % 7), y = kCalY + kCellH * (i / 7);
        const bool today = c.inMonth && c.day == tmv.tm_mday;
        if (today) tft.fillRect(x, y, kCellW, kCellH, C::SELECT);
        char d[4]; snprintf(d, sizeof(d), "%d", c.day);
        tft.setTextColor(today ? C::WHITE : c.inMonth ? C::BLACK : C::DIM, today ? C::SELECT : C::WHITE);
        tft.drawString(d, x + kCellW / 2, y);
    }
}

// ── Analog face ──

// A brush of [t]×[t] px along the line (Bresenham) — XP's thick hands, no anti-aliasing.
static void thickLine(int x0, int y0, int x1, int y1, int t, uint16_t c) {
    const int o = t / 2;
    int dx = abs(x1 - x0), sx = x0 < x1 ? 1 : -1, dy = -abs(y1 - y0), sy = y0 < y1 ? 1 : -1, e = dx + dy;
    for (;;) {
        tft.fillRect(x0 - o, y0 - o, t, t, c);
        if (x0 == x1 && y0 == y1) break;
        const int e2 = 2 * e;
        if (e2 >= dy) { e += dy; x0 += sx; }
        if (e2 <= dx) { e += dx; y0 += sy; }
    }
}

// sin(i · 6°) × 1024 for the 60 positions of the face — a flash table, not
// libm's sinf (whose reduction tables would cost ~800 B of RAM).
static const int16_t kSin60[60] PROGMEM = {0, 107, 213, 316, 416, 512, 602, 685, 761, 828, 887, 935, 974, 1002, 1018, 1024, 1018, 1002, 974, 935, 887, 828, 761, 685, 602, 512, 416, 316, 213, 107, 0, -107, -213, -316, -416, -512, -602, -685, -761, -828, -887, -935, -974, -1002, -1018, -1024, -1018, -1002, -974, -935, -887, -828, -761, -685, -602, -512, -416, -316, -213, -107};
static int sin60(int i) { return (int16_t)pgm_read_word(&kSin60[((i % 60) + 60) % 60]); }
static int cos60(int i) { return sin60(i + 15); }
// Point at position [i] (0..59, 0 = 12 o'clock) on radius [r] around the centre.
static int px60(int i, int r) { return kCx + (sin60(i) * r + (sin60(i) >= 0 ? 512 : -512)) / 1024; }
static int py60(int i, int r) { return kCy - (cos60(i) * r + (cos60(i) >= 0 ? 512 : -512)) / 1024; }

static void hand(int pos, int len, int t, uint16_t c) {
    thickLine(kCx, kCy, px60(pos, len), py60(pos, len), t, c);
}

static void paintFace(const struct tm& tmv) {
    tft.fillRect(kFaceX, kFaceY, kFaceW, kFaceH, C::WHITE);
    for (int m = 0; m < 60; m++) {
        if (m % 5) {                                     // minute dots r 34
            tft.drawPixel(px60(m, 34), py60(m, 34), C::DIM);
            continue;
        }
        const int x = px60(m, 33), y = py60(m, 33);
        if (m % 15 == 0) tft.fillRect(x - 1, y - 1, 3, 3, C::TITLE);
        else             tft.fillRect(x - 1, y - 1, 2, 2, C::TITLE);
    }
    // XP's hands: the hour hand steps every 12 minutes, the others every unit.
    hand((tmv.tm_hour % 12) * 5 + tmv.tm_min / 12, 18, 3, C::BLACK);
    hand(tmv.tm_min, 27, 2, C::BLACK);
    hand(tmv.tm_sec, 30, 1, C::RED);
    tft.fillRect(kCx - 1, kCy - 1, 3, 3, C::BLACK);
}

// ── Time field ──

static void timeText(const struct tm& tmv, bool h24, char* b, size_t n) {
    if (h24) snprintf_P(b, n, PSTR("%02d:%02d:%02d"), tmv.tm_hour, tmv.tm_min, tmv.tm_sec);
    else {
        int h = tmv.tm_hour % 12; if (!h) h = 12;
        snprintf_P(b, n, PSTR("%d:%02d %s"), h, tmv.tm_min, ClockFmt::ampm(tmv.tm_hour));
    }
}

static void paintTimeText(const char* t) {
    tft.fillRect(146, 153, 61, 16, C::WHITE);
    Display::useFont("JBMono-12B");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(C::BLACK, C::WHITE);
    tft.drawString(t, 148, 153);
}

static void paintTimeField() {
    XP::field(145, 152, 76, 18);
    // Spin buttons: xpBody, divider y 160, black triangles 5×3 up / down.
    tft.fillRect(208, 153, 12, 16, C::BODY);
    tft.drawFastHLine(208, 160, 12, C::FIELD_BORDER);
    for (int r = 0; r < 3; r++) {
        tft.drawFastHLine(214 - r, 155 + r, 1 + 2 * r, C::BLACK);
        tft.drawFastHLine(212 + r, 163 + r, 5 - 2 * r, C::BLACK);
    }
}

static void paintZone(const Settings& s) {
    char gmt[16]; ClockFmt::gmtLabel(s.tzMinutes, gmt, sizeof(gmt));
    char line[80];
    if (s.weatherPlace.length()) snprintf_P(line, sizeof(line), PSTR("Múi giờ: %s · %s"), gmt, s.weatherPlace.c_str());
    else                         snprintf_P(line, sizeof(line), PSTR("Múi giờ: %s"), gmt);
    Display::useFont("JBMono-11");
    XP::fitText(line, 216);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(C::BLACK, C::WHITE);
    tft.drawString(line, 12, 189);
}

void chClockDraw(const ChannelCtx& ctx) {
    time_t now = time(nullptr);
    struct tm tmv; localtime_r(&now, &tmv);
    const bool h24 = ctx.settings->clock24h;

    XP::window("Ngày và Giờ", XPCore::ICON_CLOCK, false);
    static const char* const kTabs[2] = {"Ngày và giờ", "Múi giờ"};
    XP::tabs(kTabs, 2, 0);
    XP::groupBox(10, 54, 122, 128, "Ngày", C::WHITE);
    XP::groupBox(136, 54, 94, 128, "Giờ", C::WHITE);
    paintMonthField(tmv);
    paintCalendar(tmv);
    paintFace(tmv);
    paintTimeField();
    timeText(tmv, h24, s_lastTime, sizeof(s_lastTime));
    paintTimeText(s_lastTime);
    paintZone(*ctx.settings);
    s_lastSec = tmv.tm_sec; s_lastMin = tmv.tm_min; s_lastYday = tmv.tm_yday;
}

void chClockTick(const ChannelCtx& ctx) {
    time_t now = time(nullptr);
    struct tm tmv; localtime_r(&now, &tmv);
    if (tmv.tm_sec == s_lastSec) return;
    s_lastSec = tmv.tm_sec;
    if (tmv.tm_yday != s_lastYday) {                   // past midnight: new day, maybe a new month
        paintMonthField(tmv);
        paintCalendar(tmv);
        s_lastYday = tmv.tm_yday;
    }
    paintFace(tmv);
    char t[16]; timeText(tmv, ctx.settings->clock24h, t, sizeof(t));
    if (strcmp(t, s_lastTime)) { paintTimeText(t); Utf8::copy(s_lastTime, sizeof(s_lastTime), t); }
}
