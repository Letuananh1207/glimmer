// Weather — XP window, design P-2026-11-26.8 §17 XP-Weather (+ -Loading,
// -Error, -Stale). Body x 2..237, y 22..213; the taskbar is main.cpp's.
//
//   title      "Thời tiết" (stale: "Thời tiết · cũ 2G")
//   y 28..98   VT323-86 "29°" TL (10, 28) | right stack JBMono-11 TR 229,
//              y 32 / 50 / 68 / 86 (cảm giác, ẩm, gió, UV)
//   y 100      condition JBMono-13 TL (12, 100) xpSky; y 118 hi / lo LABEL
//   y 144..189 two groupboxes 106×46 at x 10 / 124 ("Mai", "Kia", captions y 138):
//              VT323-32 TC (+53, 150), condition JBMono-11 TC (+53, 175)
//   y 196..213 status bar: "Mặt trời lặn 17:24" (stale: "Cập nhật 2 giờ trước")
// Stale: every value xpDim. No data yet: XP::loading; error before any data:
// warning dialog.

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
#include <time.h>
#include <math.h>

namespace C = Theme::XP;

static const WeatherData& s_w = Weather::snapshot();

// tick cache (sentinels: never-matching values)
static float   s_tickTemp  = -999.f;
static uint8_t s_tickCode  = 255;
static int     s_tickHum   = -2;
static float   s_tickWind  = -2.f;
static float   s_tickFeels = -999.f;
static float   s_tickUv    = -2.f;
static float   s_dayTmin[3] = {-999.f, -999.f, -999.f};
static float   s_dayTmax[3] = {-999.f, -999.f, -999.f};
static uint8_t s_dayCode[3] = {255, 255, 255};
static int     s_stale  = -1;            // -1 unset, 0 live, 1 stale
static char    s_status[48] = "";
static char    s_meta[16]   = "";
static uint32_t s_loadStep  = 0xFFFFFFFF;

static constexpr int kTempX = 10, kTempY = 28;
static constexpr int kStackX = 142;        // right stack band x 142..229
static constexpr int kBoxY = 144, kBoxW = 106, kBoxH = 46;
static const int kBoxX[2] = {10, 124};

bool chWeatherEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showWeather && Weather::configured(*ctx.settings);
}

// "14 phút" / "2 giờ" / "3 ngày" — the status bar's long form.
static void longDuration(long sec, char* buf, size_t n) {
    if (sec < 0) sec = 0;
    if (sec < 3600)        snprintf_P(buf, n, PSTR("%ld phút"), sec / 60);
    else if (sec < 172800) snprintf_P(buf, n, PSTR("%ld giờ"), (sec + 1800) / 3600);
    else                   snprintf_P(buf, n, PSTR("%ld ngày"), (sec + 43200) / 86400);
}

// Status-bar text + title meta for the current state.
static void statusFor(const Settings& s, bool stale, char* status, size_t sn,
                      char* meta, size_t mn) {
    time_t now = time(nullptr);
    if (stale) {
        long age = (long)(now - s_w.lastOk);
        char d[16]; longDuration(age, d, sizeof(d));
        snprintf_P(status, sn, PSTR("Cập nhật %s trước"), d);
        char sd[8]; TimeUtil::shortDuration(age, sd, sizeof(sd));
        snprintf_P(meta, mn, PSTR("cũ %s"), sd);
        return;
    }
    meta[0] = '\0';
    const WeatherDay& today = s_w.forecast[0];
    const char* tag; time_t at;
    if (today.sunrise && now < today.sunrise)    { tag = "mọc"; at = today.sunrise; }
    else if (today.sunset && now < today.sunset) { tag = "lặn"; at = today.sunset; }
    else                                         { tag = "mọc"; at = s_w.forecast[1].sunrise; }
    if (!at) { status[0] = '\0'; return; }
    char hm[10]; ClockFmt::hm(at, s.clock24h, hm, sizeof(hm));
    snprintf_P(status, sn, PSTR("Mặt trời %s %s"), tag, hm);
}

// x 10..141, y 28..95 (digits end y 84; the condition band starts y 96).
static void paintTemp(bool f, bool stale) {
    tft.fillRect(kTempX, kTempY, kStackX - kTempX, 68, C::BODY);
    if (s_w.tempC <= -900.0f) return;
    char t[12];
    snprintf_P(t, sizeof(t), PSTR("%.0f°"), Weather::toDisplay(s_w.tempC, f));
    Display::useFont("VT323-86");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(stale ? C::DIM : C::BLACK, C::BODY);
    tft.drawString(t, kTempX, kTempY);
}

// x 142..229, y 31..99: up to four rows TR 229, step 18 from y 32.
static void paintRightStack(bool f, bool stale) {
    tft.fillRect(kStackX, 31, Layout::XP_RIGHT + 1 - kStackX, 69, C::BODY);
    Display::useFont("JBMono-11");
    tft.setTextDatum(TR_DATUM);
    const uint16_t ink = stale ? C::DIM : C::LABEL;
    tft.setTextColor(ink, C::BODY);
    char line[32];
    int ry = 32;
    if (s_w.feelsC > -900.0f) {
        snprintf_P(line, sizeof(line), PSTR("cảm giác %.0f°"), Weather::toDisplay(s_w.feelsC, f));
        tft.drawString(line, Layout::XP_RIGHT, ry); ry += 18;
    }
    if (s_w.humidity >= 0) {
        snprintf_P(line, sizeof(line), PSTR("ẩm %d%%"), s_w.humidity);
        tft.drawString(line, Layout::XP_RIGHT, ry); ry += 18;
    }
    if (s_w.windKmh >= 0) {
        snprintf_P(line, sizeof(line), PSTR("gió %.0fkm"), s_w.windKmh);
        tft.drawString(line, Layout::XP_RIGHT, ry); ry += 18;
    }
    if (s_w.forecast[0].uvMax >= 0) {
        float uv = s_w.forecast[0].uvMax;
        uint16_t c = stale ? C::DIM : uv >= 8 ? C::RED : uv >= 6 ? C::AMBER : C::LABEL;
        tft.setTextColor(c, C::BODY);
        snprintf_P(line, sizeof(line), PSTR("UV %.0f"), uv);
        tft.drawString(line, Layout::XP_RIGHT, ry);
    }
}

// x 10..141, y 96..132: condition (JBMono-13 "Í" reaches 4 px above y 100) and
// today's hi / lo.
static void paintCondition(bool f, bool stale) {
    tft.fillRect(kTempX, 96, kStackX - kTempX, 37, C::BODY);
    Display::useFont("JBMono-13");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(stale ? C::DIM : C::SKY, C::BODY);
    char cond[24]; Utf8::copy(cond, sizeof(cond), Weather::describe(s_w.code));
    XP::fitText(cond, kStackX - 12 - 2);
    tft.drawString(cond, 12, 100);

    const WeatherDay& d = s_w.forecast[0];
    if (d.tmax > -900.0f && d.tmin > -900.0f) {
        char hl[24];
        snprintf_P(hl, sizeof(hl), PSTR("%.0f° / %.0f°"),
                   Weather::toDisplay(d.tmax, f), Weather::toDisplay(d.tmin, f));
        Display::useFont("JBMono-11");
        tft.setTextColor(stale ? C::DIM : C::LABEL, C::BODY);
        tft.drawString(hl, 12, 118);
    }
}

// Groupbox k (0 = Mai, 1 = Kia): interior repaint only; the outline and
// caption are drawn once by draw().
static void paintDay(int k, bool f, bool stale) {
    const WeatherDay& d = s_w.forecast[k + 1];
    const int x = kBoxX[k], cx = x + kBoxW / 2;
    tft.fillRect(x + 1, kBoxY + 1 + 6, kBoxW - 2, kBoxH - 2 - 6, C::BODY);   // y 151..188 (caption patch ends 150)
    tft.setTextDatum(TC_DATUM);
    if (d.tmax > -900.0f && d.tmin > -900.0f) {
        char b[16];
        snprintf_P(b, sizeof(b), PSTR("%.0f/%.0f"),
                   Weather::toDisplay(d.tmax, f), Weather::toDisplay(d.tmin, f));
        Display::useFont("VT323-32");
        tft.setTextColor(stale ? C::DIM : C::BLACK, C::BODY);
        tft.drawString(b, cx, 150);
    }
    Display::useFont("JBMono-11");
    tft.setTextColor(stale ? C::DIM : C::MUTED, C::BODY);
    char cond[24]; Utf8::copy(cond, sizeof(cond), Weather::describe(d.code));
    XP::fitText(cond, kBoxW - 6);
    tft.drawString(cond, cx, 175);
}

static void paintStatus(const char* status) {
    XP::statusBar(status, "");
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

static void paintAll(const Settings& s) {
    const bool f = s.useFahrenheit;
    const bool stale = Weather::isStale(s);
    statusFor(s, stale, s_status, sizeof(s_status), s_meta, sizeof(s_meta));
    XP::titleMeta(s_meta);
    paintStatus(s_status);
    paintTemp(f, stale);
    paintRightStack(f, stale);
    paintCondition(f, stale);
    for (int k = 0; k < 2; k++) paintDay(k, f, stale);

    s_stale     = stale ? 1 : 0;
    s_tickTemp  = s_w.tempC;
    s_tickFeels = s_w.feelsC;
    s_tickHum   = s_w.humidity;
    s_tickWind  = s_w.windKmh;
    s_tickUv    = s_w.forecast[0].uvMax;
    s_tickCode  = s_w.code;
    for (int i = 0; i < 3; i++) {
        s_dayTmin[i] = s_w.forecast[i].tmin;
        s_dayTmax[i] = s_w.forecast[i].tmax;
        s_dayCode[i] = s_w.forecast[i].code;
    }
}

void chWeatherDraw(const ChannelCtx& ctx) {
    s_loadStep = 0xFFFFFFFF;
    if (!s_w.valid) {
        XP::window("Thời tiết", XPCore::ICON_WEATHER, false);
        if (!s_w.err[0]) {                           // never loaded, no error yet
            XP::loading("Đang tải thời tiết...");
            s_loadStep = 0;
            return;
        }
        char detail[40]; errorDetail(s_w.err, detail, sizeof(detail));
        const char* lines[3] = { detail, "", "Đang tự thử lại..." };
        XP::dialog(XP::DLG_WARN, "Chưa có thời tiết", lines, 3);
        return;
    }

    XP::window("Thời tiết", XPCore::ICON_WEATHER, true);
    for (int k = 0; k < 2; k++)
        XP::groupBox(kBoxX[k], kBoxY, kBoxW, kBoxH, k ? "Kia" : "Mai");
    paintAll(*ctx.settings);
}

void chWeatherTick(const ChannelCtx& ctx) {
    if (!s_w.valid) {
        if (s_loadStep == 0xFFFFFFFF) return;        // error dialog: static
        uint32_t step = ctx.now_ms / 200;
        if (step != s_loadStep) { XP::loadingStep(step); s_loadStep = step; }
        return;
    }
    const Settings& s = *ctx.settings;
    const bool f = s.useFahrenheit;
    const bool stale = Weather::isStale(s);

    // Live ↔ stale recolours every value: repaint all bands.
    if ((int)stale != s_stale) { paintAll(s); return; }

    // Status bar + title meta move at most once a minute.
    static long s_min = -1;
    time_t now = time(nullptr);
    if ((long)(now / 60) != s_min) {
        s_min = (long)(now / 60);
        char st[48], m[16];
        statusFor(s, stale, st, sizeof(st), m, sizeof(m));
        if (strcmp(st, s_status) != 0) { paintStatus(st); Utf8::copy(s_status, sizeof(s_status), st); }
        if (strcmp(m, s_meta) != 0)    { XP::titleMeta(m);  Utf8::copy(s_meta, sizeof(s_meta), m); }
    }

    if (fabsf(s_w.tempC - s_tickTemp) > 0.4f) {
        paintTemp(f, stale);
        s_tickTemp = s_w.tempC;
    }
    if (s_w.code != s_tickCode
        || s_w.forecast[0].tmin != s_dayTmin[0] || s_w.forecast[0].tmax != s_dayTmax[0]) {
        paintCondition(f, stale);
        s_tickCode   = s_w.code;
        s_dayTmin[0] = s_w.forecast[0].tmin;
        s_dayTmax[0] = s_w.forecast[0].tmax;
    }
    if (fabsf(s_w.feelsC - s_tickFeels) > 0.4f || s_w.humidity != s_tickHum
        || fabsf(s_w.windKmh - s_tickWind) > 0.4f
        || fabsf(s_w.forecast[0].uvMax - s_tickUv) > 0.4f) {
        paintRightStack(f, stale);
        s_tickFeels = s_w.feelsC;
        s_tickHum   = s_w.humidity;
        s_tickWind  = s_w.windKmh;
        s_tickUv    = s_w.forecast[0].uvMax;
    }
    for (int i = 1; i < 3; i++) {
        if (s_w.forecast[i].tmin != s_dayTmin[i] || s_w.forecast[i].tmax != s_dayTmax[i]
            || s_w.forecast[i].code != s_dayCode[i]) {
            paintDay(i - 1, f, stale);
            s_dayTmin[i] = s_w.forecast[i].tmin;
            s_dayTmax[i] = s_w.forecast[i].tmax;
            s_dayCode[i] = s_w.forecast[i].code;
        }
    }
}
