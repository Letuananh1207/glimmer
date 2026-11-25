// Weather — design P-2026-11-25.3 §15 Weather-Dock (content x 40..228; the
// dock at x 2..31 is main.cpp's — no band here starts left of x 36).
//
//   y=0..22    StatusBar [Thời tiết | LẶN 17:24]
//   y=32..113  big VT323-86 temp ° (x 38..141) | right stack TR 228 (x 142..229)
//   y=116..133 icon + condition JBMono-13, today hi/lo TR 228
//   y=140      dotted divider
//   y=150..213 2 day cards 92×64 (MAI, KIA)

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "weather.h"
#include "weather_icons.h"
#include "clockfmt.h"
#include "layout.h"
#include <time.h>
#include <math.h>

static const WeatherData& s_w = Weather::snapshot();

// tick cache
static float   s_tickTemp = -999.f;
static uint8_t s_tickCode = 255;
static bool    s_tickDay  = true;
static int     s_tickHum  = -2;
static float   s_tickWind = -1.f;
static float   s_tickFeels = -999.f;
static float   s_tickUv   = -2.f;
static float   s_dayTmin[3] = {-999.f, -999.f, -999.f};
static float   s_dayTmax[3] = {-999.f, -999.f, -999.f};
static uint8_t s_dayCode[3] = {255, 255, 255};   // [0] = today's hi/lo line
static char    s_meta[24] = "";

using Layout::CONTENT_LEFT;
using Layout::CONTENT_RIGHT;
using Layout::CONTENT_MID;
// Day cards MAI / KIA, 92×64 at x 40 and 136 (the design dropped today's
// card: today's hi/lo sits beside the condition instead).
static constexpr int kCardW = 92, kCardGap = 4, kCardY = 150;
static constexpr int kStackX = 142;   // right stack band x 142..229

bool chWeatherEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showWeather && Weather::configured(*ctx.settings);
}

// Status-bar meta: CŨ badge, else the next sun event ("LẶN 17:48").
static uint16_t metaFor(const Settings& s, char* buf, size_t n) {
    if (Weather::isStale(s)) {
        char d[8]; TimeUtil::shortDuration((long)(time(nullptr) - s_w.lastOk), d, sizeof(d));
        snprintf_P(buf, n, PSTR("CŨ %s"), d);
        return Theme::AMBER;
    }
    time_t now = time(nullptr);
    const WeatherDay& today = s_w.forecast[0];
    const char* tag; time_t at;
    if (today.sunrise && now < today.sunrise)    { tag = "MỌC"; at = today.sunrise; }
    else if (today.sunset && now < today.sunset) { tag = "LẶN"; at = today.sunset; }
    else                                         { tag = "MỌC"; at = s_w.forecast[1].sunrise; }
    if (!at) { snprintf_P(buf, n, PSTR("--")); return Theme::MUTED; }
    char hm[10]; ClockFmt::hm(at, s.clock24h, hm, sizeof(hm));
    snprintf_P(buf, n, PSTR("%s %s"), tag, hm);
    return Theme::MUTED;
}

static void paintRightStack(bool f) {
    Display::useFont("JBMono-11");
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(Theme::MUTED, Theme::BG);
    char line[32];
    int ry = 36;
    if (s_w.feelsC > -900.0f) {
        snprintf_P(line, sizeof(line), PSTR("cảm giác %.0f°"), Weather::toDisplay(s_w.feelsC, f));
        tft.drawString(line, CONTENT_RIGHT, ry); ry += 18;
    }
    if (s_w.humidity >= 0) {
        snprintf_P(line, sizeof(line), PSTR("ẩm %d%%"), s_w.humidity);
        tft.drawString(line, CONTENT_RIGHT, ry); ry += 18;
    }
    if (s_w.windKmh >= 0) {
        snprintf_P(line, sizeof(line), PSTR("gió %.0fkm"), s_w.windKmh);
        tft.drawString(line, CONTENT_RIGHT, ry); ry += 18;
    }
    if (s_w.forecast[0].uvMax >= 0) {
        float uv = s_w.forecast[0].uvMax;
        tft.setTextColor(uv >= 8 ? Theme::CORAL : uv >= 6 ? Theme::AMBER : Theme::MUTED, Theme::BG);
        snprintf_P(line, sizeof(line), PSTR("UV %.0f"), uv);
        tft.drawString(line, CONTENT_RIGHT, ry);
    }
}

static void miniDay(int x, int y, int w, const WeatherDay& d, const char* label, bool fahrenheit) {
    tft.fillRect(x, y, w, 64, Theme::PANEL);
    tft.drawRect(x, y, w, 64, Theme::LINE);

    Display::useFont("JBMono-12B");
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(Theme::MUTED, Theme::PANEL);
    tft.drawString(label, x + w/2, y + 10);

    if (d.tmax > -900.0f && d.tmin > -900.0f) {
        Display::useFont("VT323-32");
        float mx = Weather::toDisplay(d.tmax, fahrenheit);
        float mn = Weather::toDisplay(d.tmin, fahrenheit);
        char buf[16];
        snprintf_P(buf, sizeof(buf), PSTR("%.0f/%.0f"), mx, mn);
        tft.setTextColor(Theme::INK, Theme::PANEL);
        tft.drawString(buf, x + w/2, y + 30);
    }

    Display::useFont("JBMono-11");
    tft.setTextColor(Theme::MUTED, Theme::PANEL);
    tft.drawString(Weather::describe(d.code), x + w/2, y + 52);
}


// Band x 38..141, y 32..113 — stops left of the right stack's band.
static void paintTemp(bool f, bool stale) {
    char tBuf[8];
    snprintf_P(tBuf, sizeof(tBuf), PSTR("%.0f"), Weather::toDisplay(s_w.tempC, f));
    tft.fillRect(CONTENT_LEFT - 2, 32, kStackX - (CONTENT_LEFT - 2), 82, Theme::BG);
    Display::useFont("VT323-86");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(stale ? Theme::MUTED : Theme::INK, Theme::BG);
    tft.drawString(tBuf, CONTENT_LEFT, 32);
    int tW = tft.textWidth(tBuf);
    Display::useFont("VT323-32");
    tft.setTextColor(Theme::SKY, Theme::BG);
    tft.drawString("°", CONTENT_LEFT + tW + 2, 42);
}

// Band x 38..229, y 116..133: icon (40,117), condition JBMono-13 TL (60,118)
// — accented capitals reach y 117 — and today's hi/lo JBMono-11 TR (228,119).
static void paintCondition(bool f) {
    tft.fillRect(CONTENT_LEFT - 2, 116, CONTENT_RIGHT + 2 - (CONTENT_LEFT - 2), 18, Theme::BG);
    WeatherIcon::draw(CONTENT_LEFT, 117, s_w.code, Theme::SKY, 1, !s_w.isDay);
    Display::useFont("JBMono-13");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::INK_DIM, Theme::BG);
    tft.drawString(Weather::describe(s_w.code), CONTENT_LEFT + 20, 118);

    const WeatherDay& d = s_w.forecast[0];
    if (d.tmax > -900.0f && d.tmin > -900.0f) {
        char hl[24];
        snprintf_P(hl, sizeof(hl), PSTR("%.0f°/%.0f°"),
                   Weather::toDisplay(d.tmax, f), Weather::toDisplay(d.tmin, f));
        Display::useFont("JBMono-11");
        tft.setTextDatum(TR_DATUM);
        tft.drawString(hl, CONTENT_RIGHT, 119);
    }
}

// On-screen wording for a fetch error (design token text.weatherError). The
// raw `err` stays English: it is also an /api/state value.
static void errorDetail(const char* err, char* buf, size_t n) {
    int code;
    if (sscanf(err, "HTTP %d", &code) == 1) {
        if (code >= 100) snprintf_P(buf, n, PSTR("máy chủ trả lỗi %d"), code);
        else             snprintf_P(buf, n, PSTR("không kết nối được"));
    } else if (!strcmp_P(err, PSTR("http begin"))) snprintf_P(buf, n, PSTR("không mở được kết nối"));
    else if (!strncmp_P(err, PSTR("JSON"), 4))     snprintf_P(buf, n, PSTR("dữ liệu lỗi"));
    else if (!strcmp_P(err, PSTR("no current")))   snprintf_P(buf, n, PSTR("thiếu số liệu hiện tại"));
    else                                           snprintf_P(buf, n, PSTR("không rõ lỗi"));
}

void chWeatherDraw(const ChannelCtx& ctx) {
    Display::clear();
    uint16_t mc = metaFor(*ctx.settings, s_meta, sizeof(s_meta));
    Display::statusBar("Thời tiết", s_meta, Theme::SKY, mc);

    if (!s_w.valid) {
        Display::useFont("JBMono-16B");
        tft.setTextDatum(MC_DATUM);
        tft.setTextColor(Theme::MUTED, Theme::BG);
        if (!s_w.err[0]) {                           // never loaded, no error yet
            tft.drawString("đang tải...", CONTENT_MID, 110);
            return;
        }
        // Error before any data (design P-2026-11-25.4 §10 Weather-Error,
        // centred on the dock layout's content column).
        tft.drawString("Chưa có thời tiết", CONTENT_MID, 100);
        char detail[40]; errorDetail(s_w.err, detail, sizeof(detail));
        Display::useFont("JBMono-11");
        tft.drawString(detail, CONTENT_MID, 124);
        Display::dotsDivider(CONTENT_MID - 90, 140, 180);
        tft.setTextColor(Theme::INK_DIM, Theme::BG);
        tft.drawString("đang tự thử lại", CONTENT_MID, 158);
        return;
    }

    bool f = ctx.settings && ctx.settings->useFahrenheit;
    bool stale = Weather::isStale(*ctx.settings);
    paintTemp(f, stale);
    paintCondition(f);
    paintRightStack(f);

    Display::dotsDivider(CONTENT_LEFT, 140, Layout::CONTENT_W);

    // 2 day cards (MAI, KIA); slot 0 only seeds today's hi/lo cache.
    const char* labels[3] = { nullptr, "MAI", "KIA" };
    for (int i = 0; i < 3; i++) {
        if (i > 0) miniDay(CONTENT_LEFT + (i - 1) * (kCardW + kCardGap), kCardY, kCardW,
                           s_w.forecast[i], labels[i], f);
        s_dayTmin[i] = s_w.forecast[i].tmin;
        s_dayTmax[i] = s_w.forecast[i].tmax;
        s_dayCode[i] = s_w.forecast[i].code;
    }

    // Seed cache for tick()
    s_tickTemp  = stale ? -998.f : s_w.tempC;    // stale ↔ live repaints the temp
    s_tickFeels = s_w.feelsC;
    s_tickHum   = s_w.humidity;
    s_tickWind  = s_w.windKmh;
    s_tickUv    = s_w.forecast[0].uvMax;
    s_tickCode  = s_w.code;
    s_tickDay   = s_w.isDay;
}

void chWeatherTick(const ChannelCtx& ctx) {
    if (!s_w.valid) return;
    bool f = ctx.settings && ctx.settings->useFahrenheit;

    // Meta (sun event / stale badge) moves at most once a minute.
    static int s_metaMin = -1;
    time_t now = time(nullptr);
    if (now / 60 != s_metaMin) {
        s_metaMin = now / 60;
        char m[16]; uint16_t mc = metaFor(*ctx.settings, m, sizeof(m));
        if (strcmp(m, s_meta) != 0) {
            Display::statusMeta(m, Theme::SKY, mc);
            strncpy(s_meta, m, sizeof(s_meta) - 1);
        }
    }

    bool stale = Weather::isStale(*ctx.settings);
    float tempKey = stale ? -998.f : s_w.tempC;
    if (fabsf(tempKey - s_tickTemp) > 0.4f) {
        paintTemp(f, stale);
        s_tickTemp = tempKey;
    }

    // The condition line also carries today's hi/lo.
    if (s_w.code != s_tickCode || s_w.isDay != s_tickDay
        || s_w.forecast[0].tmin != s_dayTmin[0] || s_w.forecast[0].tmax != s_dayTmax[0]) {
        paintCondition(f);
        s_tickCode   = s_w.code;
        s_tickDay    = s_w.isDay;
        s_dayTmin[0] = s_w.forecast[0].tmin;
        s_dayTmax[0] = s_w.forecast[0].tmax;
        s_dayCode[0] = s_w.forecast[0].code;
    }

    // Right stack — repaint whole block if any value changed (cheap, small)
    if (fabsf(s_w.feelsC - s_tickFeels) > 0.4f || s_w.humidity != s_tickHum
        || fabsf(s_w.windKmh - s_tickWind) > 0.4f
        || fabsf(s_w.forecast[0].uvMax - s_tickUv) > 0.4f) {
        tft.fillRect(kStackX, 32, CONTENT_RIGHT + 2 - kStackX, 78, Theme::BG);   // x 142..229
        paintRightStack(f);
        s_tickFeels = s_w.feelsC;
        s_tickHum   = s_w.humidity;
        s_tickWind  = s_w.windKmh;
        s_tickUv    = s_w.forecast[0].uvMax;
    }

    // Day cards (MAI, KIA) — repaint any day whose data changed
    const char* labels[3] = { nullptr, "MAI", "KIA" };
    for (int i = 1; i < 3; i++) {
        if (s_w.forecast[i].tmin != s_dayTmin[i] ||
            s_w.forecast[i].tmax != s_dayTmax[i] ||
            s_w.forecast[i].code != s_dayCode[i]) {
            miniDay(CONTENT_LEFT + (i - 1) * (kCardW + kCardGap), kCardY, kCardW,
                    s_w.forecast[i], labels[i], f);
            s_dayTmin[i] = s_w.forecast[i].tmin;
            s_dayTmax[i] = s_w.forecast[i].tmax;
            s_dayCode[i] = s_w.forecast[i].code;
        }
    }
}
