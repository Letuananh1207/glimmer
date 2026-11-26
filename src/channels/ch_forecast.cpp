// Forecast — the "Dự báo" tab of the Weather window (P-2026-11-26.17,
// screen_specs §17 XP-Real, source XP-Forecast-Details.dc.html): one window,
// one taskbar button with Weather (XPCore::progOf("Forecast") = PROG_WEATHER).
//
//   title      "Thời tiết"; tabs "Hiện tại" · "Dự báo" (selected)
//   list       XP ListView "Details" (10, 48, 220×157), white, FIELD_BORDER
//   header     (11, 49, 218×15) xpBody; y 64 xpGroup, y 65 xpDim; dividers
//              x 95 / 160 / 193, y 52–61 xpDim; JBMono-11 black: "Ngày" TL (17, 50),
//              "Trời" TL (101, 50), "Thấp" TR (189, 50), "Cao" TR (224, 50)
//   rows       24 tall from y 66 (Hôm nay, Mai, Kia): icon 16×16 (15, y+4), day TL
//              (35, y+3), condition TL (101, y+3), low TR (189, y+3), high TR
//              (224, y+3), JBMono-13 black; today's row xpSelect, white text
// No status bar. No data: the empty list + "Chưa có dự báo" xpDim TL (17, 70).

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

static constexpr int kRows = 3, kRowY = 66, kRowH = 24;
static float   s_fcMin[kRows]  = {-999, -999, -999};
static float   s_fcMax[kRows]  = {-999, -999, -999};
static uint8_t s_fcCode[kRows] = {255, 255, 255};
static bool    s_fcF = false;

bool chForecastEnabled(const ChannelCtx& ctx) {
    if (!ctx.settings || !ctx.settings->showForecast) return false;
    if (ctx.settings->weatherLat == 0.0f && ctx.settings->weatherLon == 0.0f) return false;
    return Weather::snapshot().valid;
}

static void paintHeader() {
    tft.fillRect(11, 49, 218, 15, C::BODY);
    tft.drawFastHLine(11, 64, 218, C::GROUP);
    tft.drawFastHLine(11, 65, 218, C::DIM);
    for (int x : {95, 160, 193}) tft.drawFastVLine(x, 52, 10, C::DIM);
    Display::useFont("JBMono-11");
    tft.setTextColor(C::BLACK, C::BODY);
    tft.setTextDatum(TL_DATUM);
    tft.drawString("Ngày", 17, 50);
    tft.drawString("Trời", 101, 50);
    tft.setTextDatum(TR_DATUM);
    tft.drawString("Thấp", 189, 50);
    tft.drawString("Cao", 224, 50);
}

static void paintRow(int i, const WeatherDay& day, bool f) {
    static const char* const kDay[kRows] = {"Hôm nay", "Mai", "Kia"};
    const int y = kRowY + i * kRowH;
    const bool sel = i == 0;
    const uint16_t bg = sel ? C::SELECT : C::WHITE, ink = sel ? C::WHITE : C::BLACK;
    tft.fillRect(11, y, 218, kRowH, bg);
    XP::weatherIcon(day.code, 15, y + 4, false);
    Display::useFont("JBMono-13");
    tft.setTextColor(ink, bg);
    tft.setTextDatum(TL_DATUM);
    tft.drawString(kDay[i], 35, y + 3);
    char cond[24]; Utf8::copy(cond, sizeof(cond), Weather::describe(day.code));
    XP::fitText(cond, 189 - 24 - 4 - 101);
    tft.drawString(cond, 101, y + 3);
    char b[8];
    tft.setTextDatum(TR_DATUM);
    if (day.tmin > -900) snprintf_P(b, sizeof(b), PSTR("%.0f°"), Weather::toDisplay(day.tmin, f));
    else                 snprintf_P(b, sizeof(b), PSTR("--"));
    tft.drawString(b, 189, y + 3);
    if (day.tmax > -900) snprintf_P(b, sizeof(b), PSTR("%.0f°"), Weather::toDisplay(day.tmax, f));
    else                 snprintf_P(b, sizeof(b), PSTR("--"));
    tft.drawString(b, 224, y + 3);
}

static void paintRows(const WeatherData& w, bool f) {
    for (int i = 0; i < kRows; i++) {
        paintRow(i, w.forecast[i], f);
        s_fcMin[i] = w.forecast[i].tmin;
        s_fcMax[i] = w.forecast[i].tmax;
        s_fcCode[i] = w.forecast[i].code;
    }
    s_fcF = f;
}

void chForecastDraw(const ChannelCtx& ctx) {
    XP::window("Thời tiết", XPCore::ICON_WEATHER, false);
    static const char* const kTabs[2] = {"Hiện tại", "Dự báo"};
    XP::tabs(kTabs, 2, 1);
    XP::field(10, 48, 220, 157);
    paintHeader();
    const WeatherData& w = Weather::snapshot();
    if (!w.valid) {
        Display::useFont("JBMono-11");
        tft.setTextDatum(TL_DATUM);
        tft.setTextColor(C::DIM, C::WHITE);
        tft.drawString("Chưa có dự báo", 17, 70);
        for (int i = 0; i < kRows; i++) { s_fcMin[i] = -999; s_fcMax[i] = -999; s_fcCode[i] = 255; }
        return;
    }
    paintRows(w, ctx.settings && ctx.settings->useFahrenheit);
}

void chForecastTick(const ChannelCtx& ctx) {
    const WeatherData& w = Weather::snapshot();
    if (!w.valid) return;
    const bool f = ctx.settings && ctx.settings->useFahrenheit;
    bool dirty = f != s_fcF;
    for (int i = 0; i < kRows && !dirty; i++)
        dirty = w.forecast[i].tmin != s_fcMin[i] || w.forecast[i].tmax != s_fcMax[i] || w.forecast[i].code != s_fcCode[i];
    if (dirty) paintRows(w, f);
}
