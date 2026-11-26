// Clock — XP window, design P-2026-11-26.8 §17 XP-Clock, partial-redraw tick().
//
//   y 30       "Thứ Tư · 25/11" JBMono-12B black, TC (120, 30)
//   y 52..137  white field (20, 52) 200×86; VT323-86 "14:32" TC (120, 60)
//              black — 12-hour mode: " 2:32" + "CH" JBMono-12B on the
//              digits' baseline, the group re-centred inside the field
//   y 152      greeting JBMono-13 xpGroupLabel, TC (120, 152), ≤ 219 px
//   y 196..213 status bar: "Tuần 48" | "GMT+7"

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

static int  s_lastHH = -1, s_lastMM = -1;
static char s_lastDate[32]  = "";
static char s_lastGreet[64] = "";

static constexpr int kFieldX = 20, kFieldY = 52, kFieldW = 200, kFieldH = 86;
static constexpr int CLOCK_Y  = 60;
static const char*   CLOCK_FN = "VT323-86";
// VT323-86: ascent 56, digits 49 high from y+7 → ink y 67..115, baseline 116.
static constexpr int kInkY = CLOCK_Y + 7, kInkH = 49, kBaseline = CLOCK_Y + 56;
static constexpr int kAmPmGap = 2;
static constexpr int kMid = Layout::XP_MID;

static char s_greetBuf[64];
static const char* greetingFor(int hour, const char* name) {
    const char* who = (name && name[0]) ? name : "bạn";
    const char* prefix;
    if (hour < 5)       prefix = "ngủ ngon nhé";
    else if (hour < 12) prefix = "chào buổi sáng";
    else if (hour < 17) prefix = "chào buổi chiều";
    else if (hour < 21) prefix = "chào buổi tối";
    else                prefix = "nghỉ ngơi thôi";
    snprintf(s_greetBuf, sizeof(s_greetBuf), "%s, %s", prefix, who);
    Utf8::trimPartial(s_greetBuf);          // a long name may be cut mid-letter
    return s_greetBuf;
}

// HH:MM geometry; in 12-hour mode the time + gap + "CH" is centred as a group.
static void clockGeom(bool h24, int& hhX, int& colonX, int& mmX, int& digitW, int& ampmX) {
    Display::useFont("JBMono-12B");
    int apW = h24 ? 0 : tft.textWidth("CH") + kAmPmGap;
    Display::useFont(CLOCK_FN);
    digitW = tft.textWidth("0");          // monospace digit (34)
    int colonW = tft.textWidth(":");
    int total = digitW * 4 + colonW;      // 170
    hhX = kMid - (total + apW) / 2;
    colonX = hhX + digitW * 2;
    mmX = colonX + colonW;
    ampmX = mmX + digitW * 2 + kAmPmGap;
}

static void paintDigits(int x, int w, const char* s) {
    tft.fillRect(x, kInkY, w, kInkH, C::WHITE);
    Display::useFont(CLOCK_FN);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(C::BLACK, C::WHITE);
    tft.drawString(s, x, CLOCK_Y);
}

static void paintHH(int h, bool h24) {
    char buf[4]; ClockFmt::hourField(h, h24, buf, sizeof(buf));
    int hhX, colonX, mmX, dw, apX;
    clockGeom(h24, hhX, colonX, mmX, dw, apX);
    paintDigits(hhX, dw * 2, buf);
}

static void paintMM(int m, bool h24) {
    char buf[4]; snprintf(buf, sizeof(buf), "%02d", m);
    int hhX, colonX, mmX, dw, apX;
    clockGeom(h24, hhX, colonX, mmX, dw, apX);
    paintDigits(mmX, dw * 2, buf);
}

static void paintColon(bool h24) {
    int hhX, colonX, mmX, dw, apX;
    clockGeom(h24, hhX, colonX, mmX, dw, apX);
    Display::useFont(CLOCK_FN);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(C::BLACK, C::WHITE);
    tft.drawString(":", colonX, CLOCK_Y);
}

// "SA" / "CH" after the minutes, on the digits' baseline (12-hour mode).
static void paintAmPm(int hour, bool h24) {
    if (h24) return;
    int hhX, colonX, mmX, dw, apX;
    clockGeom(h24, hhX, colonX, mmX, dw, apX);
    Display::useFont("JBMono-12B");
    const int top = kBaseline - 13;       // JBMono-12B ascent 13
    tft.fillRect(apX, top, kFieldX + kFieldW - 1 - apX, 16, C::WHITE);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(C::BLACK, C::WHITE);
    tft.drawString(ClockFmt::ampm(hour), apX, top);
}

static void paintDateRow(const char* date) {
    tft.fillRect(Layout::XP_LEFT, 29, Layout::XP_RIGHT + 1 - Layout::XP_LEFT, 17, C::BODY);   // y 29..45
    Display::useFont("JBMono-12B");
    tft.setTextDatum(TC_DATUM);
    tft.setTextColor(C::BLACK, C::BODY);
    tft.drawString(date, kMid, 30);
}

static void statusText(const struct tm& tmv, const Settings& s) {
    char iso[8]; strftime(iso, sizeof(iso), "%V", &tmv);
    char week[16]; snprintf(week, sizeof(week), "Tuần %d", atoi(iso));
    char gmt[16];  ClockFmt::gmtLabel(s.tzMinutes, gmt, sizeof(gmt));
    XP::statusBar(week, gmt);
}

// JBMono-13 accented capitals reach 4 px above y; band y 148..169. A long
// user name is cut on whole characters + "..." to fit x 10..229.
static void paintGreeting(const char* msg) {
    const int maxW = Layout::XP_RIGHT + 1 - Layout::XP_LEFT;
    tft.fillRect(Layout::XP_LEFT, 148, maxW, 22, C::BODY);
    Display::useFont("JBMono-13");
    char b[72]; Utf8::copy(b, sizeof(b), msg);
    if (tft.textWidth(b) > maxW) {
        size_t n = strlen(b);
        while (n > 1) {
            n = Utf8::prevChar(b, n);
            b[n] = '\0';
            char t[76]; snprintf(t, sizeof(t), "%s...", b);
            if (tft.textWidth(t) <= maxW) { Utf8::copy(b, sizeof(b), t); break; }
        }
    }
    tft.setTextDatum(TC_DATUM);
    tft.setTextColor(C::GROUP_LABEL, C::BODY);
    tft.drawString(b, kMid, 152);
}

bool chClockEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showClock
        && time(nullptr) > 1000000000L;
}

void chClockDraw(const ChannelCtx& ctx) {
    time_t now = time(nullptr);
    struct tm tmv;
    localtime_r(&now, &tmv);
    const bool h24 = ctx.settings->clock24h;

    XP::window("Đồng hồ", XPCore::ICON_CLOCK, true);
    statusText(tmv, *ctx.settings);

    char date[32];
    ClockFmt::dateTitle(tmv, " · ", date, sizeof(date));
    paintDateRow(date);
    Utf8::copy(s_lastDate, sizeof(s_lastDate), date);

    XP::field(kFieldX, kFieldY, kFieldW, kFieldH);
    paintHH(tmv.tm_hour, h24);
    paintColon(h24);
    paintMM(tmv.tm_min, h24);
    paintAmPm(tmv.tm_hour, h24);
    s_lastHH = tmv.tm_hour;
    s_lastMM = tmv.tm_min;

    const char* uname = ctx.settings ? ctx.settings->userName.c_str() : "";
    const char* g = greetingFor(tmv.tm_hour, uname);
    paintGreeting(g);
    Utf8::copy(s_lastGreet, sizeof(s_lastGreet), g);

    Display::useFont(CLOCK_FN);   // tick() mostly repaints digits
}

void chClockTick(const ChannelCtx& ctx) {
    time_t now = time(nullptr);
    struct tm tmv;
    localtime_r(&now, &tmv);
    const bool h24 = ctx.settings->clock24h;

    if (tmv.tm_min != s_lastMM) {
        paintMM(tmv.tm_min, h24);
        s_lastMM = tmv.tm_min;
    }
    if (tmv.tm_hour != s_lastHH) {
        paintHH(tmv.tm_hour, h24);
        s_lastHH = tmv.tm_hour;

        char date[32];
        ClockFmt::dateTitle(tmv, " · ", date, sizeof(date));
        if (strcmp(date, s_lastDate) != 0) {
            paintDateRow(date);
            Utf8::copy(s_lastDate, sizeof(s_lastDate), date);
            statusText(tmv, *ctx.settings);          // the ISO week turns on Monday
        }
        paintAmPm(tmv.tm_hour, h24);                 // flips at noon / midnight
        const char* uname = ctx.settings ? ctx.settings->userName.c_str() : "";
        const char* g = greetingFor(tmv.tm_hour, uname);
        if (strcmp(g, s_lastGreet) != 0) {
            paintGreeting(g);
            Utf8::copy(s_lastGreet, sizeof(s_lastGreet), g);
        }
    }
}
