// Night face — the XP screen saver (P-2026-11-26.17, screen_specs §17
// XP-Real, source XP-Night-Saver.dc.html). Shown alone during the night
// window when the night mode is "clock" or "dark": no window, no taskbar,
// black screen, dark-grey (#4D4D4D xpLabel) text so a desk display at night
// reads the time without lighting the room.
//
//   block      170×100 at (x, y): "23:47" VT323-86 TL (x, y + 13) (170 px; the
//              design's HTML line box puts the digits there), date
//              "Thứ Năm 26/11" JBMono-11 TC (x + 85, y + 86) (12 h: "11:47"
//              and "… CH" after the date)
//   every minute the block jumps (XPCore::saverSpot): x ∈ [6, 64], y ∈ [6, 134],
//   ≥ 30 px from the old spot; the old block is cleared to black first.

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "clockfmt.h"
#include "xp_core.h"
#include <time.h>

extern bool mainNightFace();

static constexpr uint16_t kInk = Theme::XP::LABEL;   // #4D4D4D
static constexpr uint16_t kBg  = Theme::XP::BLACK;
static constexpr int kBlockW = 170, kBlockH = 100;
static int s_x = 14, s_y = 22, s_mm = -1;

bool chNightEnabled(const ChannelCtx&) {
    return mainNightFace();
}

static void paintBlock(const struct tm& tmv, bool h24) {
    char t[8], hh[4];
    ClockFmt::hourField(tmv.tm_hour, h24, hh, sizeof(hh));
    snprintf(t, sizeof(t), "%s:%02d", hh, tmv.tm_min);
    Display::useFont("VT323-86");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(kInk, kBg);
    tft.drawString(t, s_x, s_y + 13);   // digits ink y+20..y+68, as the design image
    char date[40];
    ClockFmt::dateTitle(tmv, " ", date, sizeof(date));
    if (!h24) { strncat(date, " ", sizeof(date) - strlen(date) - 1);
                strncat(date, ClockFmt::ampm(tmv.tm_hour), sizeof(date) - strlen(date) - 1); }
    Display::useFont("JBMono-11");
    tft.setTextDatum(TC_DATUM);
    tft.drawString(date, s_x + kBlockW / 2, s_y + 86);
}

void chNightDraw(const ChannelCtx& ctx) {
    tft.fillScreen(kBg);              // no window, no taskbar
    time_t now = time(nullptr);
    struct tm tmv; localtime_r(&now, &tmv);
    paintBlock(tmv, ctx.settings->clock24h);
    s_mm = tmv.tm_min;
}

void chNightTick(const ChannelCtx& ctx) {
    time_t now = time(nullptr);
    struct tm tmv; localtime_r(&now, &tmv);
    if (tmv.tm_min == s_mm) return;
    s_mm = tmv.tm_min;
    // A new minute: the block jumps (XP's screen saver never burns one spot).
    tft.fillRect(s_x, s_y, kBlockW, kBlockH, kBg);
    int x, y;
    XPCore::saverSpot(s_x, s_y, (uint32_t)random(0x7FFFFFFF), (uint32_t)random(0x7FFFFFFF), x, y);
    s_x = x; s_y = y;
    paintBlock(tmv, ctx.settings->clock24h);
}
