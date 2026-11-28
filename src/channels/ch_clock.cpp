// Clock — XP "Date and Time Properties" (P-2026-11-26.17, touched from the app
// P-2026-11-26.22; screen_specs §17 XP-Real, sources XP-Clock-Props / -Month /
// -Zone / -Net.dc.html). Partial-redraw tick(). What the app touched comes as a
// ClockCore::View (POST /api/clock, main.cpp keeps it); no OK / Cancel: a
// change applies at once.
//
//   window      "Ngày và Giờ", no status bar
//   tabs        "Ngày và giờ" (6, 87) · "Múi giờ" (93, 59) · "Internet" (152, 66)
//   Ngày và giờ groupbox Ngày (10, 54, 122×128): month field (14, 62, 67×16)
//               "Thg 11" + drop button (66, 63); year field (85, 62, 44×16)
//               "2026" + spin (116, 63, 12×14); weekdays y 82, rule y 96, 7 × 6
//               days 16×13 from (13, 98), weeks from Monday, other months xpDim;
//               today xpSelect / white unless another day is chosen (that one
//               then). Month list open: (14, 78, 67×119) black border, 9 rows
//               of 13 from y 79, viewed month xpSelect, scroll bar x 70–79.
//               Groupbox Giờ (136, 54, 94×128): analog face centre (183, 106);
//               time field (145, 152, 76×18) READ-ONLY (xpBody, spin arrows
//               xpDim — the time comes from the Internet). y 189 zone line.
//   Múi giờ     zone field (12, 50, 216×18) "(GMT+07:00) Hà Nội" + drop
//               button (213, 52); map (12, 74, 218×90): 27 × 11 cells of 8 px
//               from (13, 75), sea #3C7FD8 / land #5E9E36, the zone's column
//               #7FB0EE / #8FCF5A; "Tự chỉnh giờ mùa hè" dim (12, 172). Zone
//               list open: (12, 68, 216×119), same style as the month list.
//   Internet    ☑ (12, 52) "Tự đồng bộ với máy chủ"; "Máy chủ:" (12, 77) +
//               field (72, 74, 156×18) "pool.ntp.org"; button (125, 98, 103×21)
//               "Cập nhật ngay"; "Đã đồng bộ lúc hh:mm" (12, 130), "ngày
//               dd/mm/yyyy." (12, 144), "Lần tới: hh:mm." xpLabel (12, 166).
//
// tick(): tab Ngày và giờ — every second the face (147..219, 70..142) and the
// time text, a new day redraws the calendar; tab Internet — the status lines
// when a sync lands. Tab Múi giờ: nothing moves.

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "clockfmt.h"
#include "layout.h"
#include "utf8.h"
#include "xp.h"
#include "clock_core.h"
#include <time.h>

namespace C = Theme::XP;
using namespace ClockCore;

extern const ClockCore::View& mainClockView();
extern uint32_t mainNtpLast();          // epoch of the last SNTP sync, 0 = none yet

static int  s_lastSec = -1, s_lastYday = -1;
static uint32_t s_lastSync = 0;
static char s_lastTime[16] = "";
static uint8_t s_tab = TAB_DATE;

static constexpr int kCx = 183, kCy = 106;
static constexpr int kFaceX = 147, kFaceY = 70, kFaceW = 73, kFaceH = 73;
static constexpr int kCalX = 13, kCalY = 98, kCellW = 16, kCellH = 13;

// Colours of the zone map and the XP push button (from the sources).
static constexpr uint16_t kSea = 0x3BFB, kLandC = 0x5CE6, kSeaSel = 0x7D9D, kLandSel = 0x8E6B;   // #3C7FD8 #5E9E36 #7FB0EE #8FCF5A
static constexpr uint16_t kBtnLine = 0x01EE, kBtnFace = 0xF79D, kBtnFoot = 0xD698;               // #003C74 #F4F3EE #D6D0C5

// Zone names (flash), the order of ClockCore::kZoneMin.
static const char kZ0[] PROGMEM = "Los Angeles";
static const char kZ1[] PROGMEM = "New York";
static const char kZ2[] PROGMEM = "Brasília";
static const char kZ3[] PROGMEM = "London";
static const char kZ4[] PROGMEM = "Paris, Berlin";
static const char kZ5[] PROGMEM = "Moskva";
static const char kZ6[] PROGMEM = "Dubai";
static const char kZ7[] PROGMEM = "New Delhi";
static const char kZ8[] PROGMEM = "Hà Nội";
static const char kZ9[] PROGMEM = "Singapore";
static const char kZ10[] PROGMEM = "Tokyo, Seoul";
static const char kZ11[] PROGMEM = "Sydney";
static const char* const kZoneName[kZoneCount] PROGMEM = {kZ0, kZ1, kZ2, kZ3, kZ4, kZ5, kZ6, kZ7, kZ8, kZ9, kZ10, kZ11};

bool chClockEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showClock
        && time(nullptr) > 1000000000L;
}

static void text(const char* t, int x, int y, uint16_t fg, uint16_t bg, const char* font = "JBMono-11") {
    Display::useFont(font);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(fg, bg);
    tft.drawString(t, x, y);
}

// Fixed text from flash (PSTR), copied to the stack to draw.
static void textP(PGM_P p, int x, int y, uint16_t fg, uint16_t bg, const char* font = "JBMono-11") {
    char t[48];
    strncpy_P(t, p, sizeof(t));
    t[sizeof(t) - 1] = 0;
    text(t, x, y, fg, bg, font);
}

// "(GMT+07:00) Hà Nội" for row / offset [tzMin]; an unlisted offset → "(GMT+07:00)".
static void zoneLabel(int tzMin, char* out, size_t n) {
    char g[12]; gmtParen(tzMin, g);
    const int i = zoneIndex(tzMin);
    if (i < 0) { Utf8::copy(out, n, g); return; }
    char name[24];
    strncpy_P(name, (const char*)pgm_read_ptr(&kZoneName[i]), sizeof(name));
    name[sizeof(name) - 1] = 0;
    snprintf_P(out, n, PSTR("%s %s"), g, name);
}

// White drop-down button 14×14 xpBtn + white triangle 5×3.
static void dropButton(int x, int y) {
    tft.fillRect(x, y, 14, 14, C::BTN);
    for (int r = 0; r < 3; r++) tft.drawFastHLine(x + 3 + r, y + 6 + r, 5 - 2 * r, C::WHITE);
}

// Spin buttons 12×h, xpBody, middle rule, triangles 5×3 up / down in [c].
static void spin(int x, int y, int h, uint16_t c) {
    tft.fillRect(x, y, 12, h, C::BODY);
    const int mid = y + h / 2;
    tft.drawFastHLine(x, mid, 12, C::FIELD_BORDER);
    for (int r = 0; r < 3; r++) {
        tft.drawFastHLine(x + 6 - r, y + 2 + r, 1 + 2 * r, c);
        tft.drawFastHLine(x + 4 + r, mid + 3 + r, 5 - 2 * r, c);
    }
}

// The month / year on view (the app's, else today's).
static void viewed(const struct tm& now, int& year, int& month) {
    const View& v = mainClockView();
    year = v.year ? v.year : now.tm_year + 1900;
    month = v.month ? v.month : now.tm_mon + 1;
}

// ── Tab Ngày và giờ ──

static void paintMonthYear(const struct tm& tmv) {
    int year, month; viewed(tmv, year, month);
    XP::field(14, 62, 67, 16);
    char b[8]; monthShort(month, b);
    text(b, 17, 63, C::BLACK, C::WHITE);
    dropButton(66, 63);
    XP::field(85, 62, 44, 16);
    char y[6]; snprintf_P(y, sizeof(y), PSTR("%d"), year);
    text(y, 87, 63, C::BLACK, C::WHITE);
    spin(116, 63, 14, C::BLACK);
}

static void paintCalendar(const struct tm& tmv) {
    static const char* const kHead[7] = {"T2", "T3", "T4", "T5", "T6", "T7", "CN"};
    tft.fillRect(kCalX, 80, 7 * kCellW, kCalY + 6 * kCellH - 80, C::WHITE);
    Display::useFont("JBMono-11");
    tft.setTextDatum(TC_DATUM);
    tft.setTextColor(C::GROUP_LABEL, C::WHITE);
    for (int i = 0; i < 7; i++) tft.drawString(kHead[i], kCalX + kCellW * i + kCellW / 2, 82);
    tft.drawFastHLine(kCalX, 96, 112, C::GROUP);

    int year, month; viewed(tmv, year, month);
    const View& v = mainClockView();
    const bool thisMonth = year == tmv.tm_year + 1900 && month == tmv.tm_mon + 1;
    const int hi = v.day ? v.day : (thisMonth ? tmv.tm_mday : 0);   // a chosen day, else today
    const int wdayFirst = wdayOf(year, month, 1);
    for (int i = 0; i < 42; i++) {
        const XPCore::CalCell c = XPCore::calCell(i, year, month, wdayFirst);
        const int x = kCalX + kCellW * (i % 7), y = kCalY + kCellH * (i / 7);
        const bool lit = c.inMonth && c.day == hi;
        if (lit) tft.fillRect(x, y, kCellW, kCellH, C::SELECT);
        char d[4]; snprintf(d, sizeof(d), "%d", c.day);
        tft.setTextColor(lit ? C::WHITE : c.inMonth ? C::BLACK : C::DIM, lit ? C::SELECT : C::WHITE);
        tft.drawString(d, x + kCellW / 2, y);
    }
}

// Drop-down list box (x, y, w, 119): black border, 9 rows of 13, row [sel] xpSelect, scroll bar.
template <typename Label>
static void paintList(int x, int y, int w, uint8_t list, int top, int sel, Label label) {
    const int h = 2 + kListRows * kListRowH;                       // 119
    tft.drawRect(x, y, w, h, C::BLACK);
    tft.fillRect(x + 1, y + 1, w - 2, h - 2, C::WHITE);
    const int sbx = x + w - 11;                                     // scroll bar 10 wide
    for (int r = 0; r < kListRows && top + r < listCount(list); r++) {
        const int ry = y + 1 + r * kListRowH, i = top + r;
        char t[40]; label(i, t, sizeof(t));
        Display::useFont("JBMono-11");
        XP::fitText(t, sbx - x - 6);
        if (i == sel) tft.fillRect(x + 1, ry, sbx - x - 1, kListRowH, C::SELECT);
        text(t, x + 3, ry, i == sel ? C::WHITE : C::BLACK, i == sel ? C::SELECT : C::WHITE);
    }
    // Scroll bar: track #F4F3EE, ▲ / ▼ 10×10 xpBtnEdge / xpBtn + white arrow 3×2, thumb xpBtn.
    tft.fillRect(sbx, y + 1, 10, h - 2, kBtnFace);
    for (int k = 0; k < 2; k++) {
        const int by = k ? y + h - 11 : y + 1;
        tft.fillRect(sbx, by, 10, 10, C::BTN_EDGE);
        tft.fillRect(sbx + 1, by + 1, 8, 8, C::BTN);
        if (!k) { tft.drawPixel(sbx + 4, by + 4, C::WHITE); tft.drawFastHLine(sbx + 3, by + 5, 3, C::WHITE); }
        else    { tft.drawFastHLine(sbx + 3, by + 4, 3, C::WHITE); tft.drawPixel(sbx + 4, by + 5, C::WHITE); }
    }
    int ty, th; thumb(list, top, y + 11, h - 22, ty, th);
    tft.fillRect(sbx, ty, 10, th, C::BTN_EDGE);
    tft.fillRect(sbx + 1, ty + 1, 8, th - 2, C::BTN);
}

static void paintMonthList(const struct tm& tmv) {
    int year, month; viewed(tmv, year, month);
    paintList(14, 78, 67, LIST_MONTH, mainClockView().top, month - 1, [](int i, char* t, size_t) { monthShort(i + 1, t); });
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

// ── Time field (read-only: the time comes from the Internet) ──

static void timeText(const struct tm& tmv, bool h24, char* b, size_t n) {
    if (h24) snprintf_P(b, n, PSTR("%02d:%02d:%02d"), tmv.tm_hour, tmv.tm_min, tmv.tm_sec);
    else {
        int h = tmv.tm_hour % 12; if (!h) h = 12;
        snprintf_P(b, n, PSTR("%d:%02d %s"), h, tmv.tm_min, ClockFmt::ampm(tmv.tm_hour));
    }
}

static void paintTimeText(const char* t) {
    tft.fillRect(146, 153, 61, 16, C::BODY);
    text(t, 148, 153, C::BLACK, C::BODY, "JBMono-12B");
}

static void paintTimeField() {
    tft.drawRect(145, 152, 76, 18, C::FIELD_BORDER);
    tft.fillRect(146, 153, 74, 16, C::BODY);
    spin(208, 153, 16, C::DIM);
}

static void paintZoneLine(const Settings& s) {
    char gmt[16]; ClockFmt::gmtLabel(s.tzMinutes, gmt, sizeof(gmt));
    char line[80];
    if (s.weatherPlace.length()) snprintf_P(line, sizeof(line), PSTR("Múi giờ: %s · %s"), gmt, s.weatherPlace.c_str());
    else                         snprintf_P(line, sizeof(line), PSTR("Múi giờ: %s"), gmt);
    Display::useFont("JBMono-11");
    XP::fitText(line, 216);
    text(line, 12, 189, C::BLACK, C::WHITE);
}

static void pageDate(const ChannelCtx& ctx, const struct tm& tmv) {
    XP::groupBox(10, 54, 122, 128, "Ngày", C::WHITE);
    XP::groupBox(136, 54, 94, 128, "Giờ", C::WHITE);
    // A clipped repaint (cursor moving) paints only the blocks it reaches.
    if (Display::clipHits(14, 62, 117, 17)) paintMonthYear(tmv);
    if (Display::clipHits(kCalX, 80, 7 * kCellW, kCalY + 6 * kCellH - 80)) paintCalendar(tmv);
    if (Display::clipHits(kFaceX, kFaceY, kFaceW, kFaceH)) paintFace(tmv);
    if (Display::clipHits(145, 152, 76, 18)) {
        paintTimeField();
        timeText(tmv, ctx.settings->clock24h, s_lastTime, sizeof(s_lastTime));
        paintTimeText(s_lastTime);
    }
    if (Display::clipHits(12, 189, 216, 14)) paintZoneLine(*ctx.settings);
    if (mainClockView().list == LIST_MONTH) paintMonthList(tmv);    // over the calendar, as XP's drop-down
}

// ── Tab Múi giờ ──

static void pageZone(const ChannelCtx& ctx) {
    const int tz = ctx.settings->tzMinutes;
    XP::field(12, 50, 216, 18);
    char z[48]; zoneLabel(tz, z, sizeof(z));
    Display::useFont("JBMono-11");
    XP::fitText(z, 196);
    text(z, 15, 52, C::BLACK, C::WHITE);
    dropButton(213, 52);
    // World map: 27 × 11 cells of 8 px, the zone's column lighter.
    tft.drawRect(12, 74, 218, 90, C::FIELD_BORDER);
    const int col = mapColumn(tz);
    for (int r = 0; r < kMapRows; r++)
        for (int c = 0; c < kMapCols; c++) {
            const bool land = isLand(r, c), sel = c == col;
            tft.fillRect(13 + 8 * c, 75 + 8 * r, 8, 8, land ? (sel ? kLandSel : kLandC) : (sel ? kSeaSel : kSea));
        }
    // Daylight saving: off and dim (no listed zone keeps it on the device).
    tft.drawRect(12, 172, 13, 13, C::DIM);
    tft.fillRect(13, 173, 11, 11, C::BODY);
    textP(PSTR("Tự chỉnh giờ mùa hè"), 30, 172, C::DIM, C::WHITE);
    if (mainClockView().list == LIST_ZONE) {
        paintList(12, 68, 216, LIST_ZONE, mainClockView().top, zoneIndex(tz),
                  [](int i, char* t, size_t n) { zoneLabel(kZoneMin[i], t, n); });
    }
}

// ── Tab Internet ──

static void paintSyncLines() {
    tft.fillRect(7, 128, 226, 52, C::WHITE);
    const uint32_t last = mainNtpLast();
    if (!last) { textP(PSTR("Chưa đồng bộ."), 12, 130, C::BLACK, C::WHITE); return; }
    const time_t l = (time_t)last, n = (time_t)(last + kSyncEveryS);
    struct tm a; localtime_r(&l, &a);
    struct tm b; localtime_r(&n, &b);
    char t[40];
    snprintf_P(t, sizeof(t), PSTR("Đã đồng bộ lúc %02d:%02d"), a.tm_hour, a.tm_min);
    text(t, 12, 130, C::BLACK, C::WHITE);
    snprintf_P(t, sizeof(t), PSTR("ngày %02d/%02d/%d."), a.tm_mday, a.tm_mon + 1, a.tm_year + 1900);
    text(t, 12, 144, C::BLACK, C::WHITE);
    snprintf_P(t, sizeof(t), PSTR("Lần tới: %02d:%02d."), b.tm_hour, b.tm_min);
    text(t, 12, 166, C::LABEL, C::WHITE);
}

static void pageNet() {
    // ☑ auto sync (always on: the device keeps SNTP running).
    tft.drawRect(12, 52, 13, 13, C::FIELD_BORDER);
    tft.fillRect(13, 53, 11, 11, C::WHITE);
    static const int8_t kTickY[7] = {6, 7, 8, 7, 6, 5, 4};
    for (int i = 0; i < 7; i++) tft.fillRect(12 + 3 + i, 52 + kTickY[i] - 1, 1, 3, C::CHECK);
    textP(PSTR("Tự đồng bộ với máy chủ"), 30, 52, C::BLACK, C::WHITE);
    textP(PSTR("Máy chủ:"), 12, 77, C::BLACK, C::WHITE);
    XP::field(72, 74, 156, 18);
    textP(PSTR("pool.ntp.org"), 75, 76, C::BLACK, C::WHITE);
    dropButton(213, 76);
    // XP push button: #003C74 edge with 1-px cut corners, #F4F3EE face, 2 foot rows #D6D0C5.
    tft.drawRect(125, 98, 103, 21, kBtnLine);
    tft.drawPixel(125, 98, C::WHITE); tft.drawPixel(227, 98, C::WHITE);
    tft.drawPixel(125, 118, C::WHITE); tft.drawPixel(227, 118, C::WHITE);
    tft.fillRect(126, 99, 101, 19, kBtnFace);
    tft.fillRect(126, 116, 101, 2, kBtnFoot);
    Display::useFont("JBMono-11");
    tft.setTextDatum(TC_DATUM);
    tft.setTextColor(C::BLACK, kBtnFace);
    char b[24]; strncpy_P(b, PSTR("Cập nhật ngay"), sizeof(b)); b[sizeof(b) - 1] = 0;
    tft.drawString(b, 176, 102);
    paintSyncLines();
}

// ── Draw / tick ──

void chClockDraw(const ChannelCtx& ctx) {
    time_t now = time(nullptr);
    struct tm tmv; localtime_r(&now, &tmv);
    const View& v = mainClockView();
    s_tab = v.tab < TAB_COUNT ? v.tab : TAB_DATE;

    XP::window("Ngày và Giờ", XPCore::ICON_CLOCK, false);
    static const char* const kTabs[3] = {"Ngày và giờ", "Múi giờ", "Internet"};
    XP::tabs(kTabs, 3, s_tab);
    if (s_tab == TAB_DATE) pageDate(ctx, tmv);
    else if (s_tab == TAB_ZONE) pageZone(ctx);
    else pageNet();
    s_lastSec = tmv.tm_sec; s_lastYday = tmv.tm_yday; s_lastSync = mainNtpLast();
}

void chClockTick(const ChannelCtx& ctx) {
    if (s_tab == TAB_NET) {
        if (mainNtpLast() != s_lastSync) { s_lastSync = mainNtpLast(); paintSyncLines(); }
        return;
    }
    if (s_tab != TAB_DATE) return;
    time_t now = time(nullptr);
    struct tm tmv; localtime_r(&now, &tmv);
    if (tmv.tm_sec == s_lastSec) return;
    s_lastSec = tmv.tm_sec;
    const bool listOpen = mainClockView().list != LIST_NONE;
    if (tmv.tm_yday != s_lastYday && !listOpen) {     // past midnight: new day, maybe a new month
        paintMonthYear(tmv);
        paintCalendar(tmv);
        s_lastYday = tmv.tm_yday;
    }
    paintFace(tmv);
    char t[16]; timeText(tmv, ctx.settings->clock24h, t, sizeof(t));
    if (strcmp(t, s_lastTime)) { paintTimeText(t); Utf8::copy(s_lastTime, sizeof(s_lastTime), t); }
}
