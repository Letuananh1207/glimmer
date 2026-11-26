// Home — XP window "Trang chủ" (P-2026-11-26.8, screen_specs §17 XP-Home,
// XP-Home-KeyBad, XP-Home-NoWeather; source/XP-Home*.dc.html).
//
// chHomeDraw  → full paint (XP::window), seeds the cache.
// chHomeTick  → 5 Hz, diffs the cache, repaints only changed regions; every
//               clear is BODY and stays inside its own band (never y ≥ 214).
//
//   y 0..21     title "Trang chủ" (Clawd)
//   y 30..89    VT323-86 "14:32" black TL (10, 30): HH x 10, ":" x 78, MM x 112
//   x 186 y 32  weather icon 16×14 ×2, xpAmber (only with weather)
//   y 66        temperature JBMono-12B TR (229, 66) xpSky / "--°" xpDim
//   y 100       date JBMono-11 xpLabel TL (10, 100) · condition TR (229, 100)
//               xpSky / "chưa có thời tiết" xpDim
//   y 124..187  groupbox "Hạn mức" (10, 124, 220×64)
//   y 135 / 159 Claude / Codex: label (18) · XP bar (70, y−1, 120×14) · value
//               TR (222, y) in the bar colour; a credential note replaces bar +
//               value (TL 70, xpRed — "Khóa bị từ chối"); loading = marquee
//   y 196..213  status bar: IP · "Còn 9G hôm nay"

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "weather.h"
#include "clockfmt.h"
#include "chrome.h"
#include "layout.h"
#include "utf8.h"
#include "xp.h"
#include <ESP8266WiFi.h>
#include <time.h>
#include <math.h>

namespace {
using namespace Theme::XP;
constexpr int kClockX = 10, kClockY = 30, kClockH = 60;   // digits ink y 37..85
constexpr int kIconX = 186, kIconY = 32;                  // 32×28
constexpr int kTempY = 66, kTempL = 184;                  // temp clear x 184..229
constexpr int kR = Layout::XP_RIGHT;                      // 229
constexpr int kDateY = 100, kCondX = 110;                 // date x 10..109 · condition x 110..229
constexpr int kGroupX = 10, kGroupY = 124, kGroupW = 220, kGroupH = 64;
constexpr int kClY = 135, kCxY = 159;
constexpr int kLabelX = 18, kBarX = 70, kBarW = 120, kBarH = 14, kValR = 222;
constexpr int kRowL = kGroupX + 1, kRowW = kGroupW - 2;   // row clears x 11..228 (inside the groupbox)
constexpr float kLoading = -4.f;                          // cache sentinel: row shows the marquee
}

// ── File-static cache so tick() can diff vs last paint ──
static int     s_hh = -1, s_mm = -1, s_hour = -1, s_mday = -1;
static float   s_cl = -2.f, s_cx = -2.f;
static int     s_loadStep = -1;
static Cred    s_clCred = Cred::NOT_SET, s_cxCred = Cred::NOT_SET;
static float   s_tempC = -999.f;
static uint8_t s_code = 255;
static bool    s_wValid = false;

bool chHomeEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showHome
        && time(nullptr) > 1000000000L;
}

// ── Per-region paint helpers ──

static int digitW() {
    Display::useFont("VT323-86");
    return tft.textWidth("0");                    // 34
}

static void paintHH(int hh, bool h24) {
    const int dw = digitW();
    char b[4]; ClockFmt::hourField(hh, h24, b, sizeof(b));
    tft.fillRect(kClockX, kClockY, dw * 2, kClockH, BODY);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(BLACK, BODY);
    tft.drawString(b, kClockX, kClockY);
}

static void paintColon() {
    const int dw = digitW();
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(BLACK, BODY);
    tft.drawString(":", kClockX + dw * 2, kClockY);
}

static void paintMM(int mm) {
    const int dw = digitW();
    const int x = kClockX + dw * 3;               // 112
    char b[4]; snprintf_P(b, sizeof(b), PSTR("%02d"), mm);
    tft.fillRect(x, kClockY, dw * 2, kClockH, BODY);   // x 112..179
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(BLACK, BODY);
    tft.drawString(b, x, kClockY);
}

static void paintDate(const struct tm& tmv) {
    char b[32]; ClockFmt::dateTitle(tmv, " ", b, sizeof(b));   // "Thứ Tư 25/11"
    tft.fillRect(kClockX, kDateY - 1, kCondX - kClockX, 15, BODY);
    Display::useFont("JBMono-11");
    XP::fitText(b, kCondX - kClockX - 2);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(LABEL, BODY);
    tft.drawString(b, kClockX, kDateY);
}

// Icon + temperature + condition. No weather yet → no icon, "--°" and
// "chưa có thời tiết" in xpDim (XP-Home-NoWeather).
static void paintWeather(const WeatherData* w, bool f) {
    const bool valid = w && w->valid;
    tft.fillRect(kIconX, kIconY, 32, 28, BODY);
    if (valid) XP::drawIcon(XPCore::ICON_WEATHER, kIconX, kIconY, 2, AMBER);

    char t[12];
    if (valid) snprintf_P(t, sizeof(t), PSTR("%.0f\xC2\xB0"), Weather::toDisplay(w->tempC, f));
    else       snprintf_P(t, sizeof(t), PSTR("--\xC2\xB0"));
    tft.fillRect(kTempL, kTempY - 1, kR + 1 - kTempL, 16, BODY);
    Display::useFont("JBMono-12B");
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(valid ? SKY : DIM, BODY);
    tft.drawString(t, kR, kTempY);

    char c[48];
    Utf8::copy(c, sizeof(c), valid ? Weather::describe(w->code) : "chưa có thời tiết");
    tft.fillRect(kCondX, kDateY - 1, kR + 1 - kCondX, 15, BODY);
    Display::useFont("JBMono-11");
    XP::fitText(c, kR + 1 - kCondX);
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(valid ? SKY : DIM, BODY);
    tft.drawString(c, kR, kDateY);
}

// Credential note colour: chrome.h's xpCredColor, muted for "not set".
static uint16_t noteColor(Cred c) {
    return c == Cred::NOT_SET ? MUTED : xpCredColor(c);
}

// Row band y−2 .. y+13 (x 11..228): label + whatever sits right of it.
static void rowLabel(int y, const char* label) {
    tft.fillRect(kRowL, y - 2, kRowW, 16, BODY);
    Display::useFont("JBMono-11");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(BLACK, BODY);
    tft.drawString(label, kLabelX, y);
}

static bool hasNote(bool isClaude, Cred cred) {
    char note[64]; Chrome::credLine(isClaude, cred, note, sizeof(note));
    return note[0] != '\0';
}

// Loading: label + a marquee where the bar goes (theo XP thật: XP shows a
// marquee progress bar while the amount is unknown). withLabel = first frame.
static void paintRowLoading(int y, const char* label, uint32_t step, bool withLabel) {
    if (withLabel) rowLabel(y, label);
    XP::marquee(kBarX, y - 1, kBarW, kBarH, step);
}

// Healthy colours as drawn in XP-Home: Claude xpGreen, Codex xpAmber.
static void paintUsageRow(int y, const char* label, bool isClaude, Cred cred, float pct) {
    rowLabel(y, label);
    char note[64]; Chrome::credLine(isClaude, cred, note, sizeof(note));
    if (note[0]) {
        // "khóa bị từ chối · cập nhật" → "Khóa bị từ chối" (XP-Home-KeyBad):
        // sentence case; the " · hint" tail goes when it does not fit.
        Utf8::sentence(note);
        Display::useFont("JBMono-11");
        const int maxW = kValR - kBarX;
        if (tft.textWidth(note) > maxW) {
            char* sep = strstr(note, " · ");
            if (sep) *sep = '\0';
        }
        XP::fitText(note, maxW);
        tft.setTextDatum(TL_DATUM);
        tft.setTextColor(noteColor(cred), BODY);
        tft.drawString(note, kBarX, y);
        return;
    }
    const float shown = pct < 0 ? 0.f : Api::shownPct(pct);
    const uint16_t c = xpUsageColor(pct, isClaude ? GREEN : AMBER);
    XP::progress(kBarX, y - 1, kBarW, kBarH, shown, c, 1);
    char v[8];
    if (pct >= 0) snprintf_P(v, sizeof(v), PSTR("%.0f%%"), shown);
    else          snprintf_P(v, sizeof(v), PSTR("--"));
    Display::useFont("JBMono-11");
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(c, BODY);
    tft.drawString(v, kValR, y);
}

static void paintStatus(int hour) {
    char right[24]; snprintf_P(right, sizeof(right), PSTR("Còn %dG hôm nay"), 23 - hour);
    XP::statusBar(WiFi.localIP().toString().c_str(), right);
}

// "loading" only for a *configured* side without a credential note (an
// unconfigured one stays valid=false/err="" and must read as a note or "--",
// not a perpetual loader).
static bool clLoadingNow(const ChannelCtx& ctx) {
    return ctx.claude && !ctx.settings->claudeKey.isEmpty() && claudeLoading(*ctx.claude)
        && !hasNote(true, ctx.claude->cred);
}
static bool cxLoadingNow(const ChannelCtx& ctx) {
    return ctx.codex && !ctx.settings->codexToken.isEmpty() && codexLoading(*ctx.codex)
        && !hasNote(false, ctx.codex->cred);
}

// ── Full repaint ──

void chHomeDraw(const ChannelCtx& ctx) {
    XP::window("Trang chủ", XPCore::ICON_CLAWD, true);

    time_t now = time(nullptr);
    struct tm tmv; localtime_r(&now, &tmv);
    const bool f = ctx.settings && ctx.settings->useFahrenheit;
    const WeatherData* w = &Weather::snapshot();

    paintHH(tmv.tm_hour, ctx.settings->clock24h);
    paintColon();
    paintMM(tmv.tm_min);
    paintWeather(w, f);
    paintDate(tmv);

    XP::groupBox(kGroupX, kGroupY, kGroupW, kGroupH, "Hạn mức");
    const bool clL = clLoadingNow(ctx), cxL = cxLoadingNow(ctx);
    const float cl = ctx.claude ? Api::claudeHeroPct(*ctx.settings, *ctx.claude) : -1.f;
    const float cx = ctx.codex  ? Api::codexHeroPct(*ctx.settings, *ctx.codex) : -1.f;
    const uint32_t step = ctx.now_ms / 200;
    if (clL) paintRowLoading(kClY, "Claude", step, true);
    else     paintUsageRow(kClY, "Claude", true, ctx.claude->cred, cl);
    if (cxL) paintRowLoading(kCxY, "Codex", step, true);
    else     paintUsageRow(kCxY, "Codex", false, ctx.codex->cred, cx);

    paintStatus(tmv.tm_hour);

    // ── Seed cache ──
    s_hh = tmv.tm_hour; s_mm = tmv.tm_min; s_hour = tmv.tm_hour; s_mday = tmv.tm_mday;
    s_cl = clL ? kLoading : (cl < 0 ? -2.f : cl);
    s_cx = cxL ? kLoading : (cx < 0 ? -2.f : cx);
    s_clCred = ctx.claude->cred; s_cxCred = ctx.codex->cred;
    s_loadStep = (int)step;
    s_wValid = w && w->valid;
    s_tempC = s_wValid ? w->tempC : -999.f;
    s_code  = s_wValid ? w->code  : 255;
}

// ── Tick: 5 Hz, region-only repaints ──

void chHomeTick(const ChannelCtx& ctx) {
    time_t now = time(nullptr);
    if (now < 1000000000L) return;
    struct tm tmv; localtime_r(&now, &tmv);

    if (tmv.tm_min != s_mm)  { paintMM(tmv.tm_min); s_mm = tmv.tm_min; }
    if (tmv.tm_hour != s_hh) { paintHH(tmv.tm_hour, ctx.settings->clock24h); s_hh = tmv.tm_hour; }
    if (tmv.tm_hour != s_hour) { paintStatus(tmv.tm_hour); s_hour = tmv.tm_hour; }
    if (tmv.tm_mday != s_mday) { paintDate(tmv); s_mday = tmv.tm_mday; }

    // Weather: only on a meaningful change, or when it first lands.
    const WeatherData* w = &Weather::snapshot();
    const bool f = ctx.settings && ctx.settings->useFahrenheit;
    const bool valid = w && w->valid;
    if (valid != s_wValid || (valid && (fabsf(w->tempC - s_tempC) > 0.4f || w->code != s_code))) {
        paintWeather(w, f);
        s_wValid = valid;
        s_tempC = valid ? w->tempC : -999.f;
        s_code  = valid ? w->code  : 255;
    }

    // Usage rows — marquee while loading; else ±0.4 % hysteresis.
    const bool clL = clLoadingNow(ctx), cxL = cxLoadingNow(ctx);
    const float cl = ctx.claude ? Api::claudeHeroPct(*ctx.settings, *ctx.claude) : -1.f;
    const float cx = ctx.codex  ? Api::codexHeroPct(*ctx.settings, *ctx.codex) : -1.f;
    const int step = (int)(ctx.now_ms / 200);

    // A credential change swaps the bar for a note (or back).
    if (ctx.claude->cred != s_clCred) { s_cl = -3.f; s_clCred = ctx.claude->cred; }
    if (ctx.codex->cred  != s_cxCred) { s_cx = -3.f; s_cxCred = ctx.codex->cred; }
    if (clL) {
        if (s_cl != kLoading || step != s_loadStep) paintRowLoading(kClY, "Claude", step, s_cl != kLoading);
        s_cl = kLoading;                              // data landing repaints the row
    } else {
        const float e = cl < 0 ? -2.f : cl;
        if (fabsf(e - s_cl) > 0.4f) { paintUsageRow(kClY, "Claude", true, ctx.claude->cred, cl); s_cl = e; }
    }
    if (cxL) {
        if (s_cx != kLoading || step != s_loadStep) paintRowLoading(kCxY, "Codex", step, s_cx != kLoading);
        s_cx = kLoading;
    } else {
        const float e = cx < 0 ? -2.f : cx;
        if (fabsf(e - s_cx) > 0.4f) { paintUsageRow(kCxY, "Codex", false, ctx.codex->cred, cx); s_cx = e; }
    }
    s_loadStep = step;
}
