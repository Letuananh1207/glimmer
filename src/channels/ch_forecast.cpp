// Weather Forecast — XP window, design P-2026-11-26.8 §17 XP-Forecast
// (+ -Empty). A white list box (10, 28) 220×162 with three 53-px rows:
//
//   row i: base = 28 + 53·i; today's row filled xpRowHi (y base+2..base+52),
//          ruled xpRowLine at base+53 between rows
//          label JBMono-12B TL (18, base+8) — today xpSky, else black
//          condition JBMono-11 TL (18, base+28) muted
//          lo TR (112, base+20) xpSky · track 74×4 at (118, base+25) xpRowLine
//          · span 6 high at base+24 (today xpSky, else muted) · hi TR (222) xpRed
//   status bar "3 ngày tới"
// Empty: the list box with the sun icon ×2 (104, 70) xpGroup and
// "Chưa có dự báo" JBMono-12B TC (120, 110) muted.

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "weather.h"
#include "layout.h"
#include "utf8.h"
#include "xp.h"
#include <time.h>

namespace C = Theme::XP;

// tick cache: 3 days × (tmin, tmax, code)
static float   s_fcMin[3]  = {-999, -999, -999};
static float   s_fcMax[3]  = {-999, -999, -999};
static uint8_t s_fcCode[3] = {255, 255, 255};

static constexpr int kBoxX = 10, kBoxY = 28, kBoxW = 220, kBoxH = 162;
static constexpr int kRowH = 53;
// Track x 118..191; the span maps [gMin, gMax] onto x 125..183 (7 px inset
// each side — measured from the design's three spans).
static constexpr int kTrackX = 118, kTrackW = 74, kSpanX = 125, kSpanW = 59;

bool chForecastEnabled(const ChannelCtx& ctx) {
    if (!ctx.settings || !ctx.settings->showForecast) return false;
    if (ctx.settings->weatherLat == 0.0f && ctx.settings->weatherLon == 0.0f) return false;
    const WeatherData* w = &Weather::snapshot();
    return w && w->valid;
}

static void paintRow(int i, const WeatherDay& day, float gMin, float range, bool f) {
    static const char* const kLabels[3] = { "Nay", "Mai", "Kia" };
    const int base = kBoxY + i * kRowH;
    const bool today = (i == 0);
    const uint16_t bg = today ? C::ROW_HI : C::WHITE;

    // Row band y base+1..base+52 inside the box (the rule at base+53 stays).
    tft.fillRect(kBoxX + 1, base + 1, kBoxW - 2, kRowH - 1, C::WHITE);
    if (today) tft.fillRect(kBoxX + 1, base + 2, kBoxW - 2, kRowH - 2, C::ROW_HI);

    tft.setTextDatum(TL_DATUM);
    Display::useFont("JBMono-12B");
    tft.setTextColor(today ? C::SKY : C::BLACK, bg);
    tft.drawString(kLabels[i], 18, base + 8);

    Display::useFont("JBMono-11");
    tft.setTextColor(C::MUTED, bg);
    char cond[24]; Utf8::copy(cond, sizeof(cond), Weather::describe(day.code));
    XP::fitText(cond, 112 - 21 - 18 - 4);   // stops left of the lo column
    tft.drawString(cond, 18, base + 28);

    const float dMin = day.tmin, dMax = day.tmax;
    tft.fillRect(kTrackX, base + 25, kTrackW, 4, C::ROW_LINE);
    if (dMin > -900 && dMax > -900) {
        int x0 = kSpanX + (int)((dMin - gMin) / range * kSpanW + 0.5f);
        int x1 = kSpanX + (int)((dMax - gMin) / range * kSpanW + 0.5f);   // exclusive
        if (x1 < x0 + 4) x1 = x0 + 4;
        if (x1 > kTrackX + kTrackW) { x1 = kTrackX + kTrackW; if (x0 > x1 - 4) x0 = x1 - 4; }
        if (x0 < kTrackX) x0 = kTrackX;
        tft.fillRect(x0, base + 24, x1 - x0, 6, today ? C::SKY : C::MUTED);
    }

    char minBuf[8], maxBuf[8];
    if (dMin > -900) snprintf_P(minBuf, sizeof(minBuf), PSTR("%.0f°"), Weather::toDisplay(dMin, f));
    else             snprintf_P(minBuf, sizeof(minBuf), PSTR("--"));
    if (dMax > -900) snprintf_P(maxBuf, sizeof(maxBuf), PSTR("%.0f°"), Weather::toDisplay(dMax, f));
    else             snprintf_P(maxBuf, sizeof(maxBuf), PSTR("--"));
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(C::SKY, bg);
    tft.drawString(minBuf, 112, base + 20);
    tft.setTextColor(C::RED, bg);
    tft.drawString(maxBuf, 222, base + 20);
}

static void computeRange(const WeatherData* w, float& gMin, float& range) {
    gMin = 999; float gMax = -999;
    for (int i = 0; i < 3; i++) {
        if (w->forecast[i].tmin > -900 && w->forecast[i].tmin < gMin) gMin = w->forecast[i].tmin;
        if (w->forecast[i].tmax > -900 && w->forecast[i].tmax > gMax) gMax = w->forecast[i].tmax;
    }
    if (gMin >= gMax) { gMin = 0; gMax = 30; }
    range = gMax - gMin;
    if (range < 1) range = 1;
}

void chForecastDraw(const ChannelCtx& ctx) {
    XP::window("Dự báo", XPCore::ICON_WEATHER, true);
    XP::statusBar("3 ngày tới", "");
    XP::field(kBoxX, kBoxY, kBoxW, kBoxH);

    const WeatherData* w = &Weather::snapshot();
    if (!w || !w->valid) {
        XP::drawIcon(XPCore::ICON_WEATHER, 104, 70, 2, C::GROUP);
        Display::useFont("JBMono-12B");
        tft.setTextDatum(TC_DATUM);
        tft.setTextColor(C::MUTED, C::WHITE);
        tft.drawString("Chưa có dự báo", Layout::XP_MID, 110);
        for (int i = 0; i < 3; i++) { s_fcMin[i] = -999; s_fcMax[i] = -999; s_fcCode[i] = 255; }
        return;
    }

    // Rules between the rows (y 81, 134).
    for (int i = 1; i < 3; i++)
        tft.fillRect(kBoxX + 1, kBoxY + i * kRowH, kBoxW - 2, 1, C::ROW_LINE);

    bool f = ctx.settings && ctx.settings->useFahrenheit;
    float gMin, range;
    computeRange(w, gMin, range);
    for (int i = 0; i < 3; i++) {
        paintRow(i, w->forecast[i], gMin, range, f);
        s_fcMin[i]  = w->forecast[i].tmin;
        s_fcMax[i]  = w->forecast[i].tmax;
        s_fcCode[i] = w->forecast[i].code;
    }
}

void chForecastTick(const ChannelCtx& ctx) {
    const WeatherData* w = &Weather::snapshot();
    if (!w || !w->valid) return;
    bool f = ctx.settings && ctx.settings->useFahrenheit;

    bool anyDirty = false;
    for (int i = 0; i < 3; i++) {
        if (w->forecast[i].tmin != s_fcMin[i]
         || w->forecast[i].tmax != s_fcMax[i]
         || w->forecast[i].code != s_fcCode[i]) { anyDirty = true; break; }
    }
    if (!anyDirty) return;

    // The global range moves every span — repaint all 3 rows.
    float gMin, range;
    computeRange(w, gMin, range);
    for (int i = 0; i < 3; i++) {
        paintRow(i, w->forecast[i], gMin, range, f);
        s_fcMin[i]  = w->forecast[i].tmin;
        s_fcMax[i]  = w->forecast[i].tmax;
        s_fcCode[i] = w->forecast[i].code;
    }
}
