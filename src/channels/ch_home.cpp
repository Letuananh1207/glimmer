// Home — "vital signs" with partial-redraw discipline.
//
// chHomeDraw  → full paint, seeds cache.
// chHomeTick  → 5 Hz, diffs cache vs current, repaints only changed regions.
// Per channel.h's PARTIAL REDRAW DISCIPLINE — tick MUST NOT clear/fillScreen.
//
// Layout: design P-2026-11-25.4 §4 re-fitted to the dock layout of
// P-2026-11-25.3 §15 "Home-Dock" (design/panel/docs/screen_specs.md).
// The dock (x 2..31, y 34..147) is painted by main.cpp after draw(): content
// and every clear band stay in x 40..228. Every region below owns a clear
// band that touches no other region (fixes L-1 / L-2). The weather icon is
// gone in the dock design — weather lives in the status meta + "c.giác".
//
//   y 0..22     status bar "Trang chủ" · meta "29° Ít mây" / "--°"
//   y 30..103   VT323-86 HH ink (x 40), ":" coral (x 108), MM amber (x 142) — ends x 210
//   y 104..117  date 12B INK_DIM (40, 104) · "c.giác 33°" 11 MUTED TR (228, 105)
//   y 122       dots divider x 40, w 188
//   y 128 / 146 CL / CX meter rows (tag x 40, pixelBar 66..185, value TR 228)
//   y 166       dots divider
//   y 170       "HÔM NAY" (40) + "CÒN 9G" TR
//   y 188..198  24-hour strip, baseline y 198, x 40..227
//   y 204..217  footer: message TL (40, 204) · IP MUTED TR (228, 204)

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "weather.h"
#include "clockfmt.h"
#include "chrome.h"
#include "layout.h"
#include "utf8.h"
#include <ESP8266WiFi.h>
#include <time.h>
#include <math.h>

namespace {
constexpr int kClockY = 30, kClockH = 74;        // 30..103, date starts at 104
constexpr int kL = Layout::CONTENT_LEFT;         // 40
constexpr int kR = Layout::CONTENT_RIGHT;        // 228 (TR datum x)
constexpr int kHhX = kL;
constexpr int kDateY = 104, kFeelsY = 105, kFeelsX = 140;   // feels clears x 140..227; longest date ends x 138
constexpr int kClY = 128, kCxY = 146;
constexpr int kBarX = 66, kBarW = 120;           // pixelBar x 66..185
constexpr int kNoteX = 62;                       // credential note slot x 62..228 (tag ends x 54)
constexpr int kTodayY = 170;
constexpr int kStripX = kL, kStripY = 198, kStripW = kR - kL;   // 188
constexpr int kFootY = 204;
constexpr int kFootGap = 8;                      // footer message → IP
constexpr int kMetaMaxW = 72;                    // status-bar meta slot
}

// ── File-static cache so tick() can diff vs last paint ──
static int     s_hh = -1, s_mm = -1, s_dayHour = -1, s_mday = -1;
static float   s_cl = -2.f, s_cx = -2.f;
static int     s_loadDot = -1;
static char    s_foot[48] = "";   // footer-left text on screen
static Cred    s_clCred = Cred::NOT_SET, s_cxCred = Cred::NOT_SET;
static int     s_footMin = -1;
static float   s_tempC = -999.f;
static uint8_t s_code = 255;
static bool    s_wValid = false, s_isDay = true;
static float   s_feelsC = -999.f;
// Clock x-geometry cached on first paint
static bool    s_geomReady = false;
static int     s_colonX = 0, s_mmX = 0, s_digitW = 0;
static int     s_ipX = Layout::CONTENT_RIGHT;   // left edge of the IP, set by draw()

bool chHomeEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showHome
        && time(nullptr) > 1000000000L;
}

static void clockGeom() {
    if (s_geomReady) return;
    Display::useFont("VT323-86");
    s_digitW = tft.textWidth("0");               // 34
    s_colonX = kHhX + s_digitW * 2;              // 108
    s_mmX = s_colonX + tft.textWidth(":");       // 142
    s_geomReady = true;
}

// ── Per-region paint helpers ──

static void paintHH(int hh, bool h24) {
    clockGeom();
    char b[4]; ClockFmt::hourField(hh, h24, b, sizeof(b));
    tft.fillRect(kHhX, kClockY, s_digitW * 2, kClockH, Theme::BG);
    Display::useFont("VT323-86");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::INK, Theme::BG);
    tft.drawString(b, kHhX, kClockY);
}

static void paintColon() {
    clockGeom();
    Display::useFont("VT323-86");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::CORAL, Theme::BG);
    tft.drawString(":", s_colonX, kClockY);
}

static void paintMM(int mm) {
    clockGeom();
    char b[4]; snprintf_P(b, sizeof(b), PSTR("%02d"), mm);
    tft.fillRect(s_mmX, kClockY, s_digitW * 2, kClockH, Theme::BG);   // x 142..209
    Display::useFont("VT323-86");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::AMBER, Theme::BG);
    tft.drawString(b, s_mmX, kClockY);
}

// Status-bar meta: "29° Ít mây"; temperature only when that overflows the
// slot (e.g. "-10° Nhiều mây"); "--°" before any weather.
static void weatherMeta(const WeatherData* w, bool f, char* buf, size_t n) {
    if (!(w && w->valid)) { snprintf_P(buf, n, PSTR("--\xC2\xB0")); return; }
    snprintf_P(buf, n, PSTR("%.0f\xC2\xB0 %s"), Weather::toDisplay(w->tempC, f), Weather::describe(w->code));
    Display::useFont("JBMono-11");
    if (tft.textWidth(buf) > kMetaMaxW)
        snprintf_P(buf, n, PSTR("%.0f\xC2\xB0"), Weather::toDisplay(w->tempC, f));
}

static void paintWeatherFeels(const WeatherData* w, bool f) {
    char b[16];
    if (w && w->valid) {
        float fl = w->feelsC > -900 ? w->feelsC : w->tempC;
        snprintf_P(b, sizeof(b), PSTR("c.giác %.0f\xC2\xB0"), Weather::toDisplay(fl, f));
    } else {
        snprintf_P(b, sizeof(b), PSTR("c.giác --"));
    }
    tft.fillRect(kFeelsX, kFeelsY, kR - kFeelsX, 14, Theme::BG);   // x 140..227
    Display::useFont("JBMono-11");
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString(b, kR, kFeelsY);
}

static void paintDate(const struct tm& tmv) {
    char dateBuf[32];
    ClockFmt::date(tmv, " ", dateBuf, sizeof(dateBuf));
    tft.fillRect(kL, kDateY, kFeelsX - kL, 16, Theme::BG);   // x 40..139 — feels-like starts at 140
    Display::useFont("JBMono-12B");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::INK_DIM, Theme::BG);
    tft.drawString(dateBuf, kL, kDateY);
}

static void paintWeather(const WeatherData* w, bool f) {
    char meta[32]; weatherMeta(w, f, meta, sizeof(meta));
    Display::statusMeta(meta, Theme::AMBER);
    paintWeatherFeels(w, f);
}

static void meterTag(int y, const char* tag, uint16_t tagColor) {
    tft.fillRect(kL, y, SCREEN_W - kL, 16, Theme::BG);   // x 40..239 — never the dock
    Display::useFont("JBMono-12B");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(tagColor, Theme::BG);
    tft.drawString(tag, kL, y);
}

static void paintMeter(int y, const char* tag, uint16_t tagColor,
                       float pct, uint16_t barColor, const char* val) {
    meterTag(y, tag, tagColor);
    Display::pixelBar(kBarX, y + 3, kBarW, 7, pct, barColor);
    Display::useFont("JBMono-11");
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(barColor, Theme::BG);
    tft.drawString(val, kR, y);
}

// Loading variant: tag on the left, a compact 3-dot chaser at x 206/215/224
// where the value would be. No bar — reads clearly as "not here yet".
static void paintMeterLoading(int y, const char* tag, uint16_t tagColor,
                              int lit, uint16_t accent) {
    meterTag(y, tag, tagColor);
    Display::loadingDots(SCREEN_W - 10 - 24, y + 4, lit, accent, 3);
}

// Credential variant: tag on the left, a short note where the bar and value
// would be ("khóa bị từ chối · cập nhật"). The slot is x 62..228 (166 px):
// a note longer than that ("… · cập nhật", 182–189 px) drops its " · hint"
// tail, then whole characters.
static void paintMeterNote(int y, const char* tag, uint16_t tagColor,
                           const char* note, uint16_t noteColor) {
    meterTag(y, tag, tagColor);
    Display::useFont("JBMono-11");
    char b[64]; Utf8::copy(b, sizeof(b), note);
    const int maxW = kR - kNoteX;
    if (tft.textWidth(b) > maxW) {
        char* sep = strstr(b, " \xC2\xB7 ");
        if (sep) *sep = '\0';
    }
    size_t n = strlen(b);
    while (n > 1 && tft.textWidth(b) > maxW) { n = Utf8::prevChar(b, n); b[n] = '\0'; }
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(noteColor, Theme::BG);
    tft.drawString(b, kR, y);
}

static void paintUsageRow(int y, const char* tag, uint16_t tagColor, bool isClaude,
                          Cred cred, float pct, bool loading, int lit) {
    char note[64]; Chrome::credLine(isClaude, cred, note, sizeof(note));
    if (note[0]) {
        uint16_t c = cred == Cred::NOT_SET ? Theme::MUTED : credColor(cred);
        paintMeterNote(y, tag, cred == Cred::NOT_SET ? Theme::MUTED : tagColor, note, c);
        return;
    }
    if (loading) { paintMeterLoading(y, tag, tagColor, lit, tagColor); return; }
    char buf[8];
    if (pct >= 0) snprintf_P(buf, sizeof(buf), PSTR("%.0f%%"), Api::shownPct(pct));
    else          snprintf_P(buf, sizeof(buf), PSTR("--"));
    paintMeter(y, tag, tagColor, pct < 0 ? 0 : Api::shownPct(pct), Display::usageColor(pct), buf);
}

static void paintCL(const ChannelCtx& ctx, float cl, bool loading, int lit) {
    paintUsageRow(kClY, "CL", Theme::CORAL, true, ctx.claude->cred, cl, loading, lit);
}

static void paintCX(const ChannelCtx& ctx, float cx, bool loading, int lit) {
    paintUsageRow(kCxY, "CX", Theme::LILAC, false, ctx.codex->cred, cx, loading, lit);
}

// Footer-left message, by priority: a credential problem (coral/amber) >
// a token expiring soon (amber) > the rain hint (sky) > nothing (IP only).
// Written with the meter tags ("CL BỊ TỪ CHỐI", "CX CÒN 2NG"); ≤ 91 px.
static uint16_t footerText(const ChannelCtx& ctx, char* buf, size_t n) {
    struct P { const char* tag; Cred cred; time_t exp; } ps[2] = {
        {"CL", ctx.claude->cred, 0},
        {"CX", ctx.codex->cred,  ctx.codex->jwtExp},
    };
    for (const auto& p : ps) {
        if (!CredState::bad(p.cred)) continue;
        snprintf_P(buf, n, PSTR("%s %s"), p.tag, p.cred == Cred::BLOCKED ? "BỊ CHẶN" :
                                          p.cred == Cred::EXPIRED ? "HẾT HẠN" : "BỊ TỪ CHỐI");
        return credColor(p.cred);
    }
    for (const auto& p : ps) {
        if (p.cred != Cred::EXPIRING) continue;
        char d[8]; TimeUtil::shortDuration((long)(p.exp - time(nullptr)), d, sizeof(d));
        snprintf_P(buf, n, PSTR("%s CÒN %s"), p.tag, d);
        return Theme::AMBER;
    }
    Weather::rainHint(*ctx.settings, buf, n);
    return Theme::SKY;                               // "" → IP only
}

static void paintHourStrip(int curHour) {
    tft.fillRect(kStripX - 1, kStripY - 10, kStripW + 2, 11, Theme::BG);   // x 39..228, y 188..198 (marker at h 0 reaches x 39)
    tft.drawFastHLine(kStripX, kStripY, kStripW, Theme::LINE);
    for (int h = 0; h < 24; h++) {
        int tx = kStripX + (kStripW * h) / 24;
        uint16_t c = (h == curHour) ? Theme::CORAL
                   : (h % 6 == 0)   ? Theme::INK_DIM
                                    : Theme::LINE;
        int th = (h == curHour) ? 6 : (h % 6 == 0 ? 3 : 2);
        tft.drawFastVLine(tx, kStripY - th, th, c);
    }
    int curX = kStripX + (kStripW * curHour) / 24;
    tft.fillRect(curX - 1, kStripY - 8, 3, 3, Theme::AMBER);

    // "CÒN 9G" right, on the HÔM NAY line
    char leftBuf[16];
    snprintf_P(leftBuf, sizeof(leftBuf), PSTR("CÒN %dG"), 23 - curHour);
    tft.fillRect(kR - 70, kTodayY - 1, 70, 15, Theme::BG);   // x 158..227; accents draw 1 px above y
    Display::useFont("JBMono-11");
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(Theme::INK_DIM, Theme::BG);
    tft.drawString(leftBuf, kR, kTodayY);
}

// Footer-left slot runs x 40 .. (IP left edge − 8): 96 px beside a 12-char
// IP, 82 px beside the 14-char one in the design. Too long → a credential
// notice drops its "BỊ " ("CL BỊ TỪ CHỐI" → "CL TỪ CHỐI", 70 px), then
// whole trailing words go ("MƯA 60% 16:00" → "MƯA 60%").
static void paintFooterLeft(const char* text, uint16_t color) {
    const int slotW = s_ipX - kFootGap - kL;
    tft.fillRect(kL, kFootY - 1, slotW, 15, Theme::BG);   // y 203 (accents) .. 217; stops kFootGap short of the IP
    strncpy(s_foot, text, sizeof(s_foot) - 1);
    Display::useFont("JBMono-11");
    char b[48]; Utf8::copy(b, sizeof(b), text);
    if (tft.textWidth(b) > slotW) {
        char* bi = strstr(b, " BỊ TỪ ");
        if (bi) memmove(bi, bi + strlen(" BỊ"), strlen(bi + strlen(" BỊ")) + 1);
    }
    while (tft.textWidth(b) > slotW) {
        char* sp = strrchr(b, ' ');
        if (!sp) break;
        *sp = '\0';
    }
    size_t n = strlen(b);
    while (n > 1 && tft.textWidth(b) > slotW) { n = Utf8::prevChar(b, n); b[n] = '\0'; }
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(color, Theme::BG);
    tft.drawString(b, kL, kFootY);
}

// ── Full repaint ──

void chHomeDraw(const ChannelCtx& ctx) {
    Display::clear();

    const WeatherData* w = &Weather::snapshot();
    bool f = ctx.settings && ctx.settings->useFahrenheit;
    char meta[32]; weatherMeta(w, f, meta, sizeof(meta));
    Display::statusBar("Trang chủ", meta, Theme::AMBER);

    time_t now = time(nullptr);
    struct tm tmv; localtime_r(&now, &tmv);

    // Hero clock (the dock design has no weather icon beside it)
    paintHH(tmv.tm_hour, ctx.settings->clock24h);
    paintColon();
    paintMM(tmv.tm_min);

    // Date row (static-ish, only changes day-over-day) + feels-like
    paintDate(tmv);
    paintWeatherFeels(w, f);

    Display::dotsDivider(kL, 122, kR - kL);

    // AI meters — "loading" only for a *configured* side (an unconfigured slot
    // stays valid=false/err="" and must read as "--", not a perpetual loader).
    const bool clLoading = ctx.claude && !ctx.settings->claudeKey.isEmpty()   && claudeLoading(*ctx.claude);
    const bool cxLoading = ctx.codex  && !ctx.settings->codexToken.isEmpty()  && codexLoading(*ctx.codex);
    float cl = ctx.claude ? Api::claudeHeroPct(*ctx.settings, *ctx.claude) : -1.f;
    float cx = ctx.codex  ? Api::codexHeroPct(*ctx.settings, *ctx.codex) : -1.f;
    const int lit = (ctx.now_ms / 150) % 3;
    paintCL(ctx, cl, clLoading, lit);
    paintCX(ctx, cx, cxLoading, lit);
    s_clCred = ctx.claude->cred; s_cxCred = ctx.codex->cred;
    s_loadDot = (clLoading || cxLoading) ? lit : -1;

    Display::dotsDivider(kL, 166, kR - kL);

    Display::useFont("JBMono-12B");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString("HÔM NAY", kL, kTodayY);
    paintHourStrip(tmv.tm_hour);

    // Footer — the IP first: its width sets the left message's slot
    String ip = WiFi.localIP().toString();
    Display::useFont("JBMono-11");
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString(ip, kR, kFootY);
    s_ipX = kR - tft.textWidth(ip);
    char foot[48]; uint16_t fc = footerText(ctx, foot, sizeof(foot));
    paintFooterLeft(foot, fc);

    // ── Seed cache ──
    s_hh = tmv.tm_hour; s_mm = tmv.tm_min; s_dayHour = tmv.tm_hour; s_footMin = tmv.tm_min;
    s_mday = tmv.tm_mday;
    s_cl = (cl < 0) ? -2.f : cl;
    s_cx = (cx < 0) ? -2.f : cx;
    s_wValid = w && w->valid;
    if (s_wValid) { s_tempC = w->tempC; s_code = w->code; s_isDay = w->isDay; s_feelsC = w->feelsC; }
    else          { s_tempC = -999.f; s_code = 255; }
}

// ── Tick: 5 Hz, region-only repaints ──

void chHomeTick(const ChannelCtx& ctx) {
    time_t now = time(nullptr);
    if (now < 1000000000L) return;
    struct tm tmv; localtime_r(&now, &tmv);

    // Clock
    if (tmv.tm_min != s_mm) { paintMM(tmv.tm_min); s_mm = tmv.tm_min; }
    if (tmv.tm_hour != s_hh) { paintHH(tmv.tm_hour, ctx.settings->clock24h); s_hh = tmv.tm_hour; }
    if (tmv.tm_min != s_footMin) {
        char foot[48]; uint16_t fc = footerText(ctx, foot, sizeof(foot));
        if (strcmp(foot, s_foot) != 0) paintFooterLeft(foot, fc);
        s_footMin = tmv.tm_min;
    }
    if (tmv.tm_hour != s_dayHour) {
        paintHourStrip(tmv.tm_hour);
        s_dayHour = tmv.tm_hour;
    }
    if (tmv.tm_mday != s_mday) { paintDate(tmv); s_mday = tmv.tm_mday; }

    // Weather (only repaint on meaningful change, or when it first lands)
    const WeatherData* w = &Weather::snapshot();
    bool f = ctx.settings && ctx.settings->useFahrenheit;
    const bool valid = w && w->valid;
    if (valid != s_wValid
        || (valid && (fabsf(w->tempC - s_tempC) > 0.4f || w->code != s_code
                      || w->isDay != s_isDay || fabsf(w->feelsC - s_feelsC) > 0.4f))) {
        paintWeather(w, f);
        s_wValid = valid;
        s_tempC  = valid ? w->tempC  : -999.f;
        s_code   = valid ? w->code   : 255;
        s_isDay  = valid ? w->isDay  : true;
        s_feelsC = valid ? w->feelsC : -999.f;
    }

    // AI meters — chase dots while a side is still loading; else hysteresis on
    // ±0.4% so noise doesn't thrash.
    const bool clLoading = ctx.claude && !ctx.settings->claudeKey.isEmpty()  && claudeLoading(*ctx.claude);
    const bool cxLoading = ctx.codex  && !ctx.settings->codexToken.isEmpty() && codexLoading(*ctx.codex);
    const float cl = ctx.claude ? Api::claudeHeroPct(*ctx.settings, *ctx.claude) : -1.f;
    const float cx = ctx.codex  ? Api::codexHeroPct(*ctx.settings, *ctx.codex) : -1.f;
    const int lit = (ctx.now_ms / 150) % 3;

    // A credential change swaps the bar for a note (or back).
    if (ctx.claude->cred != s_clCred) { s_cl = -3.f; s_clCred = ctx.claude->cred; }
    if (ctx.codex->cred  != s_cxCred) { s_cx = -3.f; s_cxCred = ctx.codex->cred; }
    if (clLoading) {
        if (lit != s_loadDot) paintCL(ctx, cl, true, lit);
        s_cl = -2.f;                                  // force repaint when data lands
    } else {
        float cl_eff = (cl < 0) ? -2.f : cl;
        if (fabsf(cl_eff - s_cl) > 0.4f) { paintCL(ctx, cl, false, lit); s_cl = cl_eff; }
    }
    if (cxLoading) {
        if (lit != s_loadDot) paintCX(ctx, cx, true, lit);
        s_cx = -2.f;
    } else {
        float cx_eff = (cx < 0) ? -2.f : cx;
        if (fabsf(cx_eff - s_cx) > 0.4f) { paintCX(ctx, cx, false, lit); s_cx = cx_eff; }
    }
    if (clLoading || cxLoading) s_loadDot = lit;
}
