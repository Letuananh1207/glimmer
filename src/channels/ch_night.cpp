// Night face — shown alone (no rotation) during the night window when the
// night mode is "clock" or "dark". Design P-2026-11-26.8 §17 XP-Night: no
// window and no taskbar — black screen, dark-grey (#4D4D4D) text only, so a
// desk display at night reads the time without lighting the room.
//
//   y 70   VT323-86 HH:MM, TC (120, 70)
//   y 150  date "Thứ Tư 25/11" JBMono-11, TC (120, 150) (+ "SA"/"CH" in 12-hour mode)

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "clockfmt.h"
#include <time.h>

extern bool mainNightFace();

static constexpr uint16_t kInk = Theme::XP::LABEL;   // #4D4D4D
static constexpr uint16_t kBg  = Theme::XP::BLACK;
static constexpr int kClockY = 70, kDateY = 150;
// VT323-86 digits: ink y+7 .. y+55.
static constexpr int kInkY = kClockY + 7, kInkH = 49;
static int s_hh = -1, s_mm = -1, s_day = -1;

bool chNightEnabled(const ChannelCtx&) {
    return mainNightFace();
}

static void geom(int& hhX, int& colonX, int& mmX, int& digitW) {
    Display::useFont("VT323-86");
    digitW = tft.textWidth("0");
    int colonW = tft.textWidth(":");
    hhX = (SCREEN_W - (digitW * 4 + colonW)) / 2;
    colonX = hhX + digitW * 2;
    mmX = colonX + colonW;
}

static void paintTime(int hh, int mm, bool h24, bool hoursToo) {
    int hhX, colonX, mmX, dw;
    geom(hhX, colonX, mmX, dw);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(kInk, kBg);
    char b[4];
    if (hoursToo) {
        tft.fillRect(hhX, kInkY, dw * 2, kInkH, kBg);
        ClockFmt::hourField(hh, h24, b, sizeof(b));
        tft.drawString(b, hhX, kClockY);
        tft.drawString(":", colonX, kClockY);
    }
    tft.fillRect(mmX, kInkY, dw * 2, kInkH, kBg);
    snprintf(b, sizeof(b), "%02d", mm);
    tft.drawString(b, mmX, kClockY);
}

static void paintDate(const struct tm& tmv, bool h24) {
    char date[40];
    ClockFmt::dateTitle(tmv, " ", date, sizeof(date));
    if (!h24) { strncat(date, "  ", sizeof(date) - strlen(date) - 1);
                strncat(date, ClockFmt::ampm(tmv.tm_hour), sizeof(date) - strlen(date) - 1); }
    tft.fillRect(0, kDateY - 1, SCREEN_W, 15, kBg);   // y 149..163
    Display::useFont("JBMono-11");
    tft.setTextDatum(TC_DATUM);
    tft.setTextColor(kInk, kBg);
    tft.drawString(date, SCREEN_W / 2, kDateY);
}

void chNightDraw(const ChannelCtx& ctx) {
    tft.fillScreen(kBg);              // no window, no taskbar
    time_t now = time(nullptr);
    struct tm tmv; localtime_r(&now, &tmv);
    const bool h24 = ctx.settings->clock24h;
    paintTime(tmv.tm_hour, tmv.tm_min, h24, true);
    paintDate(tmv, h24);
    s_hh = tmv.tm_hour; s_mm = tmv.tm_min; s_day = tmv.tm_yday;
}

void chNightTick(const ChannelCtx& ctx) {
    time_t now = time(nullptr);
    struct tm tmv; localtime_r(&now, &tmv);
    if (tmv.tm_min == s_mm) return;
    const bool h24 = ctx.settings->clock24h;
    paintTime(tmv.tm_hour, tmv.tm_min, h24, tmv.tm_hour != s_hh);
    if (tmv.tm_yday != s_day || tmv.tm_hour != s_hh) paintDate(tmv, h24);
    s_hh = tmv.tm_hour; s_mm = tmv.tm_min; s_day = tmv.tm_yday;
}
