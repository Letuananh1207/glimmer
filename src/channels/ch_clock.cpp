// Clock — design P-2026-11-25.4 §12 on the dock layout of P-2026-11-25.3
// §15 "Clock-Dock", with partial-redraw tick(). The dock (x 2..31, y 34..183)
// is painted by main.cpp; everything here is centred on x 134 and every
// clear band stays in x 40..228.
//
//   y=0..22   status bar "Đồng hồ" · meta "tuần 48"
//   y=32      "THỨ TƯ · 25/11" JBMono-11 MUTED, TC (134, 32)
//   y=50..135 huge VT323-86 HH:MM centred (HH x 49, ":" 117, MM 151 — ink
//             ends x 215), ":" CORAL between; 12-hour mode: "SA"/"CH" 12B
//             AMBER at (215, 99), ink x 216..228, right of the minutes
//   y=148     "chào buổi chiều, bạn" JBMono-13 MC (134, 148), ≤ 188 px
//   y=178     24-dot day-progress strip x 52..216

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "clockfmt.h"
#include "layout.h"
#include "utf8.h"
#include <time.h>

static int  s_lastHH = -1, s_lastMM = -1;
static char s_lastDate[32]  = "";
static char s_lastGreet[64] = "";
static int  s_lastDayHour = -1;

static constexpr int CLOCK_Y  = 50;
static constexpr int CLOCK_H  = 86;
static const char*   CLOCK_FN = "VT323-86";
static constexpr int kL   = Layout::CONTENT_LEFT;     // 40
static constexpr int kMid = Layout::CONTENT_MID;      // 134
static constexpr int kW   = Layout::CONTENT_W + 1;    // x 40..228 inclusive
// VT323-86 digits: advance 34, ink ends ≤ 31 px into the cell ("4": dx 3 + w 28),
// so the minutes' clear band stops at x 215 and "SA"/"CH" owns x 216..228.
static constexpr int kDigitInk = 31;
static constexpr int kAmPmX = 215, kAmPmY = CLOCK_Y + 49;   // 99

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

static void clockGeom(int& hhX, int& colonX, int& mmX, int& digitW, int& colonW) {
    Display::useFont(CLOCK_FN);
    digitW = tft.textWidth("0");          // monospace digit
    colonW = tft.textWidth(":");
    int total = digitW * 4 + colonW;
    hhX = kMid - total / 2;               // 49
    colonX = hhX + digitW * 2;
    mmX = colonX + colonW;
}

static void paintHH(int h, bool h24) {
    char buf[4]; ClockFmt::hourField(h, h24, buf, sizeof(buf));
    int hhX, colonX, mmX, dw, cw;
    clockGeom(hhX, colonX, mmX, dw, cw);
    tft.fillRect(hhX, CLOCK_Y, dw * 2, CLOCK_H, Theme::BG);
    Display::useFont(CLOCK_FN);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::INK, Theme::BG);
    tft.drawString(buf, hhX, CLOCK_Y);
}

static void paintMM(int m) {
    char buf[4]; snprintf(buf, sizeof(buf), "%02d", m);
    int hhX, colonX, mmX, dw, cw;
    clockGeom(hhX, colonX, mmX, dw, cw);
    tft.fillRect(mmX, CLOCK_Y, dw + kDigitInk, CLOCK_H, Theme::BG);   // x 151..215
    Display::useFont(CLOCK_FN);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::INK, Theme::BG);
    tft.drawString(buf, mmX, CLOCK_Y);
}

static void paintColon() {
    int hhX, colonX, mmX, dw, cw;
    clockGeom(hhX, colonX, mmX, dw, cw);
    Display::useFont(CLOCK_FN);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::CORAL, Theme::BG);
    tft.drawString(":", colonX, CLOCK_Y);
}

static void paintDateRow(const char* date) {
    tft.fillRect(kL, 30, kW, 14, Theme::BG);   // y 30 covers an accented capital (1 px above y 32)
    Display::useFont("JBMono-11");
    tft.setTextDatum(TC_DATUM);
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString(date, kMid, 32);
}

// "SA" / "CH" right of the minutes in 12-hour mode. Own band x 216..228
// (the glyphs' ink: S/C start 1 px in, "A" ends at x 228); the minutes'
// ink ends at x 215 at the latest.
static void paintAmPm(int hour, bool h24) {
    tft.fillRect(kAmPmX + 1, kAmPmY, Layout::CONTENT_RIGHT - kAmPmX, 16, Theme::BG);
    if (h24) return;
    Display::useFont("JBMono-12B");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::AMBER, Theme::BG);
    tft.drawString(ClockFmt::ampm(hour), kAmPmX, kAmPmY);
}

static void weekMeta(const struct tm& tmv, char* buf, size_t n) {
    char iso[8]; strftime(iso, sizeof(iso), "%V", &tmv);
    snprintf(buf, n, "tuần %s", iso);
}

// A long user name would run into the dock: cut whole characters + "..."
// until it fits x 40..228.
static void paintGreeting(const char* msg) {
    tft.fillRect(kL, 138, kW, 22, Theme::BG);
    Display::useFont("JBMono-13");
    char b[72]; Utf8::copy(b, sizeof(b), msg);
    if (tft.textWidth(b) > Layout::CONTENT_W) {
        size_t n = strlen(b);
        while (n > 1) {
            n = Utf8::prevChar(b, n);
            b[n] = '\0';
            char t[72]; snprintf(t, sizeof(t), "%s...", b);
            if (tft.textWidth(t) <= Layout::CONTENT_W) { snprintf(b, sizeof(b), "%s", t); break; }
        }
    }
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(Theme::INK_DIM, Theme::BG);
    tft.drawString(b, kMid, 148);
}

static void paintDayStrip(int hour) {
    int dotW = 4, gap = 3;
    int stripW = 24 * dotW + 23 * gap;
    int sx = kMid - stripW / 2;           // 52
    tft.fillRect(sx, 178, stripW, 4, Theme::BG);
    for (int i = 0; i < 24; i++) {
        uint16_t c = (i < hour)         ? Theme::AMBER
                    : (i == hour)        ? Theme::INK
                                         : Theme::LINE;
        tft.fillRect(sx + i * (dotW + gap), 178, dotW, 4, c);
    }
}

bool chClockEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showClock
        && time(nullptr) > 1000000000L;
}

void chClockDraw(const ChannelCtx& ctx) {
    Display::clear();
    time_t now = time(nullptr);
    struct tm tmv;
    localtime_r(&now, &tmv);

    char week[16]; weekMeta(tmv, week, sizeof(week));
    Display::statusBar("Đồng hồ", week, Theme::AMBER);

    char date[32];
    ClockFmt::date(tmv, " · ", date, sizeof(date));
    const bool h24 = ctx.settings->clock24h;
    paintDateRow(date);
    strncpy(s_lastDate, date, sizeof(s_lastDate) - 1);

    paintHH(tmv.tm_hour, h24);
    paintColon();
    paintMM(tmv.tm_min);
    paintAmPm(tmv.tm_hour, h24);
    s_lastHH = tmv.tm_hour;
    s_lastMM = tmv.tm_min;
    s_lastDayHour = tmv.tm_hour;

    const char* uname = ctx.settings ? ctx.settings->userName.c_str() : "";
    const char* g = greetingFor(tmv.tm_hour, uname);
    paintGreeting(g);
    strncpy(s_lastGreet, g, sizeof(s_lastGreet) - 1);

    paintDayStrip(tmv.tm_hour);

    // End with VT323-86 loaded so tick() doesn't need to switch
    Display::useFont(CLOCK_FN);
}

void chClockTick(const ChannelCtx& ctx) {
    time_t now = time(nullptr);
    struct tm tmv;
    localtime_r(&now, &tmv);

    if (tmv.tm_min != s_lastMM) {
        paintMM(tmv.tm_min);
        s_lastMM = tmv.tm_min;
    }
    if (tmv.tm_hour != s_lastHH) {
        const bool h24 = ctx.settings->clock24h;
        paintHH(tmv.tm_hour, h24);
        s_lastHH = tmv.tm_hour;

        char date[32];
        ClockFmt::date(tmv, " · ", date, sizeof(date));
        if (strcmp(date, s_lastDate) != 0) {
            paintDateRow(date);
            strncpy(s_lastDate, date, sizeof(s_lastDate) - 1);
            char week[16]; weekMeta(tmv, week, sizeof(week));
            Display::statusMeta(week, Theme::AMBER);
        }
        paintAmPm(tmv.tm_hour, h24);            // flips at noon / midnight
        const char* uname = ctx.settings ? ctx.settings->userName.c_str() : "";
        const char* g = greetingFor(tmv.tm_hour, uname);
        if (strcmp(g, s_lastGreet) != 0) {
            paintGreeting(g);
            strncpy(s_lastGreet, g, sizeof(s_lastGreet) - 1);
        }
        paintDayStrip(tmv.tm_hour);
        s_lastDayHour = tmv.tm_hour;
    }
}
