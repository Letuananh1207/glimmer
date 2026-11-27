// Weather — XP property sheet, tab "Hiện tại" (P-2026-11-26.17, screen_specs
// §17 XP-Real, source XP-Weather-Props.dc.html). Forecast is the "Dự báo" tab
// of the same window (ch_forecast.cpp). Body x 2..237, y 22..213.
//
//   title      "Thời tiết" (stale: "Thời tiết · cũ 2G")
//   tabs       "Hiện tại" (selected) · "Dự báo"; page (6, 41, 228×169) white
//   icon       32×32 at (14, 50) by weather code (sun / partly / rain)
//   condition  JBMono-16B black TL (54, 52); place JBMono-11 xpLabel TL (54, 71)
//   temp       VT323-44 black TR (226, 52) — the design's box top 45 is an HTML
//              line box; its digits ink y 52..79, level with the condition
//   rules      (12, 90, 216×1), (12, 164, 216×1) xpGroup
//   rows       label TL (14, 96 + 16i), value TL (112, …) JBMono-11 black:
//              Cảm giác · Độ ẩm · Gió · Chỉ số UV; then (14, 171 + 16i):
//              Cao / thấp · Mặt trời lặn (or mọc, the next one)
// No status bar. No data yet: XP::loading. P-2026-11-26.23 (XP-Weather-Stale /
// -Error): stale → values xpMuted (labels stay black), last row "Cập nhật:" +
// "2 giờ trước" xpAmber; an error before any data → inside the Hiện tại tab:
// XP warning triangle 24×21 (14, 52), "Chưa có thời tiết" 12B (46, 52), the
// error (46, 72), rule y 96, "Đang tự thử lại..." xpLabel (14, 104).

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "weather.h"
#include "clockfmt.h"
#include "layout.h"
#include "timeutil.h"
#include "utf8.h"
#include "xp.h"
#include "warn_icon.h"
#include <time.h>
#include <math.h>

namespace C = Theme::XP;

static const WeatherData& s_w = Weather::snapshot();

static uint32_t s_sig  = 0;                // hash of everything the page shows
static char     s_meta[16] = "";
static uint32_t s_loadStep = 0xFFFFFFFF;

bool chWeatherEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showWeather && Weather::configured(*ctx.settings);
}

// Title meta "cũ 2G" while stale.
static void metaFor(const Settings& s, char* meta, size_t mn) {
    meta[0] = '\0';
    if (!Weather::isStale(s)) return;
    char sd[8]; TimeUtil::shortDuration((long)(time(nullptr) - s_w.lastOk), sd, sizeof(sd));
    snprintf_P(meta, mn, PSTR("cũ %s"), sd);
}

static const char* uvWord(float uv) {
    return uv < 3 ? "thấp" : uv < 6 ? "trung bình" : uv < 8 ? "cao" : uv < 11 ? "rất cao" : "cực cao";
}

// The next sun event of today: "lặn" before sunset, else tomorrow's "mọc".
static void sunRow(const Settings& s, char* label, size_t ln, char* value, size_t vn) {
    const time_t now = time(nullptr);
    const WeatherDay& d = s_w.forecast[0];
    const bool rise = (d.sunrise && now < d.sunrise) || !(d.sunset && now < d.sunset);
    const time_t at = d.sunrise && now < d.sunrise ? d.sunrise
                    : d.sunset && now < d.sunset   ? d.sunset : s_w.forecast[1].sunrise;
    snprintf_P(label, ln, rise ? PSTR("Mặt trời mọc:") : PSTR("Mặt trời lặn:"));
    if (at) ClockFmt::hm(at, s.clock24h, value, vn);
    else    snprintf_P(value, vn, PSTR("--"));
}

static uint32_t fnv(uint32_t h, const void* p, size_t n) {
    const uint8_t* b = (const uint8_t*)p;
    for (size_t i = 0; i < n; i++) h = (h ^ b[i]) * 16777619u;
    return h;
}

// Everything the page shows, so tick() repaints only when it changes.
static uint32_t sigOf(const Settings& s) {
    uint32_t h = 2166136261u;
    const int t[] = {(int)lroundf(s_w.tempC), (int)lroundf(s_w.feelsC), s_w.humidity, (int)lroundf(s_w.windKmh),
                     (int)lroundf(s_w.forecast[0].uvMax), (int)lroundf(s_w.forecast[0].tmin),
                     (int)lroundf(s_w.forecast[0].tmax), s_w.code, Weather::isStale(s) ? 1 : 0,
                     s.useFahrenheit ? 1 : 0, s.clock24h ? 1 : 0};
    h = fnv(h, t, sizeof(t));
    char sl[24], sv[12]; sunRow(s, sl, sizeof(sl), sv, sizeof(sv));
    h = fnv(h, sl, strlen(sl));
    h = fnv(h, sv, strlen(sv));
    return fnv(h, s.weatherPlace.c_str(), s.weatherPlace.length());
}

// Label black, value in [ink] (xpMuted while stale, P-2026-11-26.23).
static void row(int y, const char* label, const char* value, uint16_t ink) {
    tft.setTextColor(C::BLACK, C::WHITE);
    tft.drawString(label, 14, y);
    tft.setTextColor(ink, C::WHITE);
    tft.drawString(value, 112, y);
}

// "2 giờ trước" / "14 phút trước" — how old the last reading is (the stale last row).
static void ageText(char* v, size_t n) {
    const long age = s_w.lastOk ? (long)(time(nullptr) - s_w.lastOk) : -1;
    if (age < 0)            snprintf_P(v, n, PSTR("--"));
    else if (age < 3600)    snprintf_P(v, n, PSTR("%ld phút trước"), age / 60);
    else if (age < 172800L) snprintf_P(v, n, PSTR("%ld giờ trước"), age / 3600);
    else                    snprintf_P(v, n, PSTR("%ld ngày trước"), age / 86400);
}

// The page's content (inside the white page, x 7..232, y 42..208).
static void paintPage(const Settings& s) {
    const bool f = s.useFahrenheit, stale = Weather::isStale(s);
    const uint16_t ink = stale ? C::MUTED : C::BLACK;
    tft.fillRect(7, 42, 226, 167, C::WHITE);

    XP::weatherIcon(s_w.code, 14, 50, true);
    char cond[32]; Utf8::copy(cond, sizeof(cond), Weather::describe(s_w.code));
    Display::useFont("JBMono-16B");
    XP::fitText(cond, 226 - 54 - 60);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(ink, C::WHITE);
    tft.drawString(cond, 54, 52);
    if (s.weatherPlace.length()) {
        char place[40]; Utf8::copy(place, sizeof(place), s.weatherPlace.c_str());
        Display::useFont("JBMono-11");
        XP::fitText(place, 226 - 54 - 60);
        tft.setTextColor(C::LABEL, C::WHITE);
        tft.drawString(place, 54, 71);
    }
    if (s_w.tempC > -900.0f) {
        char t[12]; snprintf_P(t, sizeof(t), PSTR("%.0f°"), Weather::toDisplay(s_w.tempC, f));
        Display::useFont("VT323-44");
        tft.setTextDatum(TR_DATUM);
        tft.setTextColor(ink, C::WHITE);
        tft.drawString(t, 226, 52);          // ink y 52..79 like the design (HTML box top 45)
    }
    tft.drawFastHLine(12, 90, 216, C::GROUP);
    tft.drawFastHLine(12, 164, 216, C::GROUP);

    Display::useFont("JBMono-11");
    tft.setTextDatum(TL_DATUM);
    char v[24];
    if (s_w.feelsC > -900.0f) snprintf_P(v, sizeof(v), PSTR("%.0f°"), Weather::toDisplay(s_w.feelsC, f));
    else                      snprintf_P(v, sizeof(v), PSTR("--"));
    row(96, "Cảm giác:", v, ink);
    if (s_w.humidity >= 0) snprintf_P(v, sizeof(v), PSTR("%d%%"), s_w.humidity);
    else                   snprintf_P(v, sizeof(v), PSTR("--"));
    row(112, "Độ ẩm:", v, ink);
    if (s_w.windKmh >= 0) snprintf_P(v, sizeof(v), PSTR("%.0f km/h"), s_w.windKmh);
    else                  snprintf_P(v, sizeof(v), PSTR("--"));
    row(128, "Gió:", v, ink);
    const float uv = s_w.forecast[0].uvMax;
    if (uv >= 0) snprintf_P(v, sizeof(v), PSTR("%.0f · %s"), uv, uvWord(uv));
    else         snprintf_P(v, sizeof(v), PSTR("--"));
    row(144, "Chỉ số UV:", v, ink);

    const WeatherDay& d = s_w.forecast[0];
    if (d.tmax > -900.0f && d.tmin > -900.0f)
        snprintf_P(v, sizeof(v), PSTR("%.0f° / %.0f°"), Weather::toDisplay(d.tmax, f), Weather::toDisplay(d.tmin, f));
    else snprintf_P(v, sizeof(v), PSTR("--"));
    row(171, "Cao / thấp:", v, ink);
    if (stale) {
        ageText(v, sizeof(v));
        tft.setTextColor(C::BLACK, C::WHITE);
        tft.drawString("Cập nhật:", 14, 187);
        tft.setTextColor(C::AMBER, C::WHITE);
        tft.drawString(v, 112, 187);
    } else {
        char sl[24]; sunRow(s, sl, sizeof(sl), v, sizeof(v));
        row(187, sl, v, ink);
    }
    s_sig = sigOf(s);
}

// On-screen wording for a fetch error (XP-Weather-Error: a sentence with a
// period). The raw `err` stays English: it is also an /api/state value.
static void errorDetail(const char* err, char* buf, size_t n) {
    int code;
    if (sscanf(err, "HTTP %d", &code) == 1) {
        if (code >= 100) snprintf_P(buf, n, PSTR("Máy chủ trả lỗi %d."), code);
        else             snprintf_P(buf, n, PSTR("Không kết nối được."));
    } else if (!strcmp_P(err, PSTR("http begin"))) snprintf_P(buf, n, PSTR("Không mở được kết nối."));
    else if (!strncmp_P(err, PSTR("JSON"), 4))     snprintf_P(buf, n, PSTR("Dữ liệu lỗi."));
    else if (!strcmp_P(err, PSTR("no current")))   snprintf_P(buf, n, PSTR("Thiếu số liệu hiện tại."));
    else                                           snprintf_P(buf, n, PSTR("Không rõ lỗi."));
}

void chWeatherDraw(const ChannelCtx& ctx) {
    s_loadStep = 0xFFFFFFFF;
    if (!s_w.valid) {
        XP::window("Thời tiết", XPCore::ICON_WEATHER, false);
        if (!s_w.err[0]) {                           // never loaded, no error yet
            XP::loading("Đang tải...", "từ open-meteo.com");
            s_loadStep = 0;
            return;
        }
        // Error before any data: inside the Hiện tại tab (XP-Weather-Error).
        static const char* const kTabs[2] = {"Hiện tại", "Dự báo"};
        XP::tabs(kTabs, 2, 0);
        for (int k = 0; k < WarnIcon::kWarnRunCount; k++) {
            WarnIcon::Run r;
            memcpy_P(&r, &WarnIcon::kWarnRuns[k], sizeof(r));
            tft.fillRect(14 + r.x, 52 + r.y, r.w, 1, pgm_read_word(&WarnIcon::kWarnPal[r.c]));
        }
        char detail[40]; errorDetail(s_w.err, detail, sizeof(detail));
        Display::useFont("JBMono-12B");
        tft.setTextDatum(TL_DATUM);
        tft.setTextColor(C::BLACK, C::WHITE);
        tft.drawString("Chưa có thời tiết", 46, 52);
        Display::useFont("JBMono-11");
        tft.drawString(detail, 46, 72);
        tft.drawFastHLine(12, 96, 216, C::GROUP);
        tft.setTextColor(C::LABEL, C::WHITE);
        tft.drawString("Đang tự thử lại...", 14, 104);
        return;
    }
    const Settings& s = *ctx.settings;
    XP::window("Thời tiết", XPCore::ICON_WEATHER, false);
    metaFor(s, s_meta, sizeof(s_meta));
    XP::titleMeta(s_meta);
    static const char* const kTabs[2] = {"Hiện tại", "Dự báo"};
    XP::tabs(kTabs, 2, 0);
    paintPage(s);
}

void chWeatherTick(const ChannelCtx& ctx) {
    if (!s_w.valid) {
        if (s_loadStep == 0xFFFFFFFF) return;        // error dialog: static
        uint32_t step = ctx.now_ms / 200;
        if (step != s_loadStep) { XP::loadingStep(step); s_loadStep = step; }
        return;
    }
    const Settings& s = *ctx.settings;
    // Values and the sun row move at most once a minute; the page repaints only on change.
    static long s_min = -1;
    const long m = (long)(time(nullptr) / 60);
    if (m == s_min) return;
    s_min = m;
    char meta[16]; metaFor(s, meta, sizeof(meta));
    if (strcmp(meta, s_meta)) { XP::titleMeta(meta); Utf8::copy(s_meta, sizeof(s_meta), meta); }
    if (sigOf(s) != s_sig) paintPage(s);
}
