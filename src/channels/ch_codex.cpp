// Codex — XP window (P-2026-11-26.8/.9, screen_specs §17 XP-Codex-*).
//
//   title     "Codex" (+ " · <model label>" / " · cũ 18P" / " · khóa lỗi")
//   y 28      hero label from the window length ("Hạn mức tuần")  JBMono-11 LABEL
//   y 40      hero "41" VT323-86 + "%" VT323-44 at (10+w+2, 70)  black (DIM stale); bar xpLilac / usage colour
//   y 28..54  limit credits "tín dụng" + "$4.20" TR 229 (only when the account has some)
//   y 68/84   "đặt lại sau" TR (229,68) muted + countdown TR (229,84) JBMono-12B RED
//   y 102     XP progress 220×14 (blocks 1 px from the field edge)
//   y 128     groupbox (10,128,220,30) secondary window: tag/"Đã dùng" TL (18,137),
//             "12% · 2G 14P" TR (222,137)
//   y 170     groupbox (10,170,220,24) "Đặt lại tuần": reset credits TL (18,177),
//             weekly pace TR (222,177) ("~70% khi đặt lại" / "hết sau 6G")
//   y 198     credential info strip when the token is bad but data is shown
// The pre-XP 24-h spark strip is gone (not in the design).

#include "channel.h"
#include "chrome.h"
#include "display.h"
#include "history.h"
#include "timeutil.h"
#include "theme.h"
#include "config.h"
#include "layout.h"
#include "utf8.h"
#include "xp.h"
#include <math.h>
#include <time.h>

using namespace Theme::XP;

static constexpr int kL = Layout::XP_LEFT;    // 10
static constexpr int kR = Layout::XP_RIGHT;   // 229
static constexpr int kHeroY = 40, kPctY = 70, kBarY = 102;
static constexpr int kHeroClearR = 150;       // hero clears x 10..149; right column x 150..229
static constexpr int kSecY = 128, kSecH = 30;
static constexpr int kRstY = 170, kRstH = 24;
static constexpr int kStripY = 198;

// ── tick cache (position-based) ──
static float s_heroPct = -2.f;
static float s_secPct  = -2.f;
static float s_credits = -2.f;
static bool  s_stale   = false;
static char  s_rightLine[16] = "";
static char  s_secSub[40] = "";
static char  s_pace[40]   = "";
static char  s_resets[40] = "";
static Cred  s_cred = Cred::NOT_SET;
static MetaSlot s_meta;
static bool  s_loading = false;
static uint32_t s_loadStep = 0;

static MetaSlot metaFor(const ChannelCtx& ctx) {
    return xpUsageMeta(*ctx.settings, ctx.codex->lastOk, VendorStatus::OPENAI,
                       ctx.settings->codexModelLabel.c_str(), ctx.codex->cred, ctx.codex->jwtExp);
}

bool chCodexEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showCodex && !ctx.settings->codexToken.isEmpty();
}

// Label for a rate-limit window from its length in seconds.
static void windowLabel(long sec, char* buf, size_t n) {
    if      (sec >= 6L * 24 * 3600 - 3600) snprintf_P(buf, n, PSTR("Hạn mức tuần"));
    else if (sec >= 20L * 3600)            snprintf_P(buf, n, PSTR("Hạn mức ngày"));
    else if (sec >= 3600)                  snprintf_P(buf, n, PSTR("Phiên %ld giờ"), sec / 3600);
    else if (sec > 0)                      snprintf_P(buf, n, PSTR("Phiên %ld phút"), sec / 60);
    else                                   snprintf_P(buf, n, PSTR("Hạn mức"));
}

static uint16_t heroColor(float pct, bool dim) { return dim ? DIM : xpUsageColor(pct, LILAC); }

struct Windows {
    float heroPct, secPct; time_t heroRst, secRst; long heroWin, secWin;
};
static Windows windowsFor(const ChannelCtx& ctx) {
    const CodexData& d = *ctx.codex;
    // Only swap hero/secondary when there are two *real* rate-limit windows; a
    // per-model additional limit (secondaryTag set) never takes the hero slot.
    const bool realSecondary = d.secondaryPct >= 0 && d.secondaryTag[0] == '\0';
    const bool sw = realSecondary && ctx.settings->codexWeeklyHero;
    return { sw ? d.secondaryPct : d.primaryPct,   sw ? d.primaryPct : d.secondaryPct,
             sw ? d.secondaryReset : d.primaryReset, sw ? d.primaryReset : d.secondaryReset,
             sw ? d.secondaryWinSec : d.primaryWinSec, sw ? d.primaryWinSec : d.secondaryWinSec };
}

// Right column x 150..229, y 28..101: credits (when any) + "đặt lại sau" + countdown.
static void paintRightColumn(const CodexData& d, time_t heroReset) {
    tft.fillRect(kHeroClearR, 28, kR + 1 - kHeroClearR, kBarY - 28, BODY);
    if (d.creditsRemain >= 0) {
        char credits[16]; snprintf_P(credits, sizeof(credits), PSTR("$%.2f"), d.creditsRemain);
        Display::useFont("JBMono-11");
        tft.setTextDatum(TR_DATUM);
        tft.setTextColor(MUTED, BODY);
        tft.drawString("tín dụng", kR, 28);
        Display::useFont("JBMono-12B");
        tft.setTextColor(s_stale ? DIM : BLACK, BODY);
        tft.drawString(credits, kR, 42);
    }
    String r = heroReset > 0 ? Api::formatCountdown(heroReset) : String("--");
    Display::useFont("JBMono-11");
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(MUTED, BODY);
    tft.drawString("đặt lại sau", kR, 68);
    Display::useFont("JBMono-12B");
    tft.setTextColor(s_stale ? DIM : RED, BODY);
    tft.drawString(r, kR, 84);
    Utf8::copy(s_rightLine, sizeof(s_rightLine), r.c_str());
}

static void paintHero(float pct) {
    char pctBuf[8];
    if (pct < 0) snprintf_P(pctBuf, sizeof(pctBuf), PSTR("--"));
    else         snprintf_P(pctBuf, sizeof(pctBuf), PSTR("%.0f"), Api::shownPct(pct));
    tft.fillRect(kL, kHeroY, kHeroClearR - kL, kBarY - kHeroY, BODY);   // x 10..149, y 40..101

    // Hero digits black (P-2026-11-26.11); the level colour is the bar's only.
    const uint16_t uc = s_stale ? DIM : BLACK;
    Display::useFont("VT323-86");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(uc, BODY);
    tft.drawString(pctBuf, kL, kHeroY);
    const int heroW = tft.textWidth(pctBuf);
    Display::useFont("VT323-44");
    tft.setTextColor(uc, BODY);
    tft.drawString("%", kL + heroW + 2, kPctY);           // "100%" ends at x 132

    XP::progress(kL, kBarY, kR + 1 - kL, 14, pct < 0 ? 0 : Api::shownPct(pct), heroColor(pct, s_stale), 1);
}

// Secondary text: "12% · 2G 14P", "12%", the countdown alone, or "--".
static void secText(float pct, time_t reset, char* buf, size_t n) {
    if (pct >= 0 && reset > 0)
        snprintf_P(buf, n, PSTR("%d%% \xC2\xB7 %s"), (int)(Api::shownPct(pct) + 0.5f),
                   Api::formatCountdown(reset).c_str());
    else if (pct >= 0) snprintf_P(buf, n, PSTR("%d%%"), (int)(Api::shownPct(pct) + 0.5f));
    else if (reset > 0) Utf8::copy(buf, n, Api::formatCountdown(reset).c_str());
    else snprintf_P(buf, n, PSTR("--"));
}

// Groupbox interior: left TL (18,137) — the per-model tag ("Spark") or
// "Đã dùng"; right TR (222,137). No secondary window at all: "Không có".
static void paintSecondary(const CodexData& d, float pct, time_t reset) {
    tft.fillRect(kL + 2, 135, kR - kL - 3, 15, BODY);       // y 135..149, inside the box
    Display::useFont("JBMono-11");
    char right[40]; secText(pct, reset, right, sizeof(right));
    Utf8::copy(s_secSub, sizeof(s_secSub), right);
    if (pct < 0 && reset <= 0 && !d.secondaryTag[0]) {
        tft.setTextDatum(TL_DATUM);
        tft.setTextColor(MUTED, BODY);
        tft.drawString("Không có", 18, 137);
        return;
    }
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(s_stale ? DIM : BLACK, BODY);
    tft.drawString(right, 222, 137);
    const int room = 222 - tft.textWidth(right) - 8 - 18;

    char left[24];
    if (d.secondaryTag[0]) { Utf8::copy(left, sizeof(left), d.secondaryTag); Utf8::sentence(left); }
    else                   snprintf_P(left, sizeof(left), PSTR("Đã dùng"));
    XP::fitText(left, room);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(BLACK, BODY);                 // a label: stays black when stale (XP-Codex-Stale)
    tft.drawString(left, 18, 137);
}

// Weekly pace, lower case (history_core's paceText is the pre-XP upper case).
static uint16_t paceFor(const CodexData& d, char* buf, size_t n) {
    if (n) buf[0] = '\0';
    History::Pace p = History::pace(UsageHistory::ring(), History::CODEX_WEEK,
                                    d.primaryPct, time(nullptr), d.primaryReset);
    if (p.kind == History::Pace::EMPTY) {
        char t[8]; TimeUtil::shortDuration(p.sec, t, sizeof(t));
        snprintf_P(buf, n, PSTR("hết sau %s"), t);
        return RED;
    }
    if (p.kind == History::Pace::AT_RESET) snprintf_P(buf, n, PSTR("~%d%% khi đặt lại"), p.pct);
    return MUTED;
}

// "Đặt lại tuần" interior: credits left TL (18,177), pace TR (222,177).
static void paintResets(const CodexData& d) {
    tft.fillRect(kL + 2, 176, kR - kL - 3, 16, BODY);       // y 176..191, inside the box
    char pace[40]; uint16_t pc = paceFor(d, pace, sizeof(pace));
    char resets[40]; Chrome::resetsText(d.resets, resets, sizeof(resets));
    Utf8::copy(s_pace, sizeof(s_pace), pace);
    Utf8::copy(s_resets, sizeof(s_resets), resets);

    Display::useFont("JBMono-11");
    int room = 222 - 18;
    if (pace[0]) {
        tft.setTextDatum(TR_DATUM);
        tft.setTextColor(pc, BODY);
        tft.drawString(pace, 222, 177);
        room = 222 - tft.textWidth(pace) - 8 - 18;
    }
    // Too wide beside the pace: "còn 2 · đến 12/10" → "còn 2".
    if (resets[0] && tft.textWidth(resets) > room) {
        char* cut = strstr(resets, " \xC2\xB7 ");
        if (cut) *cut = '\0';
    }
    const bool none = !resets[0];
    if (none) snprintf_P(resets, sizeof(resets), PSTR("Chưa có lượt"));
    XP::fitText(resets, room);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(none ? MUTED : BLACK, BODY);
    tft.drawString(resets, 18, 177);
}

// Token bad but data shown: the yellow strip under the groups (y 198..211).
static void paintStrip(const CodexData& d) {
    tft.fillRect(Layout::XP_BODY_X, kStripY - 2, Layout::XP_BODY_W, Layout::XP_BOTTOM - kStripY + 2, BODY);
    if (CredState::bad(d.cred)) Chrome::credBanner(kL, kStripY, kR + 1 - kL, false, d.cred);
    s_cred = d.cred;
}

void chCodexDraw(const ChannelCtx& ctx) {
    XP::window("Codex", XPCore::ICON_CLAWD, false);
    s_meta = metaFor(ctx);
    XP::titleMeta(s_meta.text);
    s_heroPct = -2.f; s_secPct = -2.f; s_credits = -2.f;
    s_rightLine[0] = 0; s_secSub[0] = 0;
    s_loading = false;

    const CodexData& d = *ctx.codex;
    // Nothing to show yet and something is wrong: the XP message box.
    if (!d.valid && (CredState::bad(d.cred) || d.err[0])) {
        Chrome::credCard(false, d.cred, d.jwtExp, d.err);
        return;
    }
    if (!d.valid) {
        XP::loading("Đang tải...");
        s_loading = true;
        s_loadStep = ctx.now_ms / 200;
        XP::loadingStep(s_loadStep);
        return;
    }

    const Windows w = windowsFor(ctx);
    s_stale = Api::isStale(d.lastOk, *ctx.settings);

    char heroLbl[24]; windowLabel(w.heroWin, heroLbl, sizeof(heroLbl));
    Display::useFont("JBMono-11");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(LABEL, BODY);
    tft.drawString(heroLbl, kL, 28);

    paintHero(w.heroPct);
    paintRightColumn(d, w.heroRst);

    char secLbl[24]; windowLabel(w.secWin, secLbl, sizeof(secLbl));
    XP::groupBox(kL, kSecY, kR + 1 - kL, kSecH, secLbl);
    paintSecondary(d, w.secPct, w.secRst);

    XP::groupBox(kL, kRstY, kR + 1 - kL, kRstH, "Đặt lại tuần");
    paintResets(d);
    paintStrip(d);

    s_heroPct = (w.heroPct < 0) ? -2.f : w.heroPct;
    s_secPct  = (w.secPct  < 0) ? -2.f : w.secPct;
    s_credits = d.creditsRemain;
}

void chCodexTick(const ChannelCtx& ctx) {
    if (!ctx.codex) return;
    const CodexData& d = *ctx.codex;
    if (!d.valid && (CredState::bad(d.cred) || d.err[0])) return;   // static message box
    if (!d.valid) {                       // loading — advance the marquee
        uint32_t step = ctx.now_ms / 200;
        if (s_loading && step != s_loadStep) { XP::loadingStep(step); s_loadStep = step; }
        return;
    }

    // formatCountdown() has minute granularity, so only re-derive (and heap-
    // allocate) the countdown strings when the wall-clock minute rolls over.
    time_t t = time(nullptr);
    struct tm tm; localtime_r(&t, &tm);
    static int s_cdMin = -1;
    const bool minTick = (tm.tm_min != s_cdMin);

    const Windows w = windowsFor(ctx);
    const bool stale = Api::isStale(d.lastOk, *ctx.settings);
    const bool dimChanged = stale != s_stale;
    s_stale = stale;

    if (minTick || dimChanged) {
        MetaSlot m = metaFor(ctx);
        if (m != s_meta) { XP::titleMeta(m.text); s_meta = m; }
    }

    float p = (w.heroPct < 0) ? -2.f : w.heroPct;
    if (fabsf(p - s_heroPct) > 0.4f || dimChanged) {
        paintHero(w.heroPct);
        s_heroPct = p;
    }

    bool rightDirty = dimChanged || fabsf(d.creditsRemain - s_credits) > 0.005f;
    if (!rightDirty && minTick) {
        String r = w.heroRst > 0 ? Api::formatCountdown(w.heroRst) : String("--");
        if (strcmp(r.c_str(), s_rightLine) != 0) rightDirty = true;
    }
    if (rightDirty) { paintRightColumn(d, w.heroRst); s_credits = d.creditsRemain; }

    float sp = (w.secPct < 0) ? -2.f : w.secPct;
    bool secDirty = fabsf(sp - s_secPct) > 0.4f || dimChanged;
    if (!secDirty && minTick) {
        char fresh[40]; secText(w.secPct, w.secRst, fresh, sizeof(fresh));
        if (strcmp(fresh, s_secSub) != 0) secDirty = true;
    }
    if (secDirty) { paintSecondary(d, w.secPct, w.secRst); s_secPct = sp; }

    // Pace and credits move with each fetch; their texts at minute ticks.
    if (minTick) {
        char pace[40]; paceFor(d, pace, sizeof(pace));
        char resets[40]; Chrome::resetsText(d.resets, resets, sizeof(resets));
        if (strcmp(pace, s_pace) != 0 || strcmp(resets, s_resets) != 0) paintResets(d);
    }
    if (d.cred != s_cred) paintStrip(d);
    s_cdMin = tm.tm_min;
}
