// Claude — design-true layout from ClaudeUsageScreen (screens.jsx:199-234).
//
// Fonts (regenerated via tools/genfonts.py at exact em-px sizes):
//   - "PHIÊN 5 GIỜ" / "TUẦN" / labels / sub-data : JBMono-11   (~13 px)
//   - countdown "3h 2m" (right, just above the bar)    : JBMono-12B  (~12 px)
//   - Clawd mascot top-right, mood from project board : Display::drawClawd
//   - hero "%" digits                                 : VT323-86   (~70 px)
//   - inline "%" suffix on hero                       : VT323-44   (~36 px)
//
//   y=176..218  bottom rows: the project board (what each agent project is
//               doing: Cần duyệt / Chờ bạn / Lỗi / Đang chạy / Xong), then
//               the weekly pace if a row is free. Resets and per-model
//               windows (FABLE / EXTRA) are no longer shown here.

#include "channel.h"
#include "chrome.h"
#include "display.h"
#include "history.h"
#include "theme.h"
#include "config.h"
#include "layout.h"
#include "attention.h"
#include "timeutil.h"
#include "utf8.h"
#include <math.h>
#include <time.h>

// ── tick() state cache (position-based, not source-based) ──
static float  s_heroPct  = -2.f;
static float  s_secPct   = -2.f;
static bool   s_stale    = false;
static char   s_heroReset[16] = "";
static char   s_secSub[40]    = "";
static char   s_pace[40]      = "";
static Cred   s_cred          = Cred::NOT_SET;
static MetaSlot s_meta;
static int    s_loadDot = -1;

bool chClaudeEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showClaude && !ctx.settings->claudeKey.isEmpty();
}

// Right meta carries only badges (CŨ / KHÓA LỖI / SỰ CỐ…); the per-model
// label ("FABLE") was dropped — the model rows below already name it.
static MetaSlot metaFor(const ChannelCtx& ctx) {
    return usageMeta(*ctx.settings, ctx.claude->lastOk, VendorStatus::CLAUDE,
                     "", ctx.claude->cred, 0);   // no model tag: badges only
}

static void paceFor(const ClaudeData& d, char* buf, size_t n) {
    History::Pace p = History::pace(UsageHistory::ring(), History::CLAUDE_WEEK,
                                    d.weeklyPct, time(nullptr), d.weeklyReset);
    History::paceText(p, buf, n);
}

// ── Region paint helpers (also called from draw()) ──

// Right column, beside the hero %:
//   y 40..80   Clawd 72×40 — mood follows the project board (tick); its top
//              lines up with the hero digits, 18 px clear of the status bar
//   y 112      4d / 3h 14m   JBMono-12B      time left, right above the bar (tick)
// The hero repaint clears only x < kHeroRight, so this column is never wiped.
static constexpr int kHeroRight = 150;      // "100%" ends near x 138
static constexpr int kResetY    = 112;      // bottom 126; the bar starts at 128
static constexpr int kClawdS = 4;                              // 18×10 cells → 72×40
static constexpr int kClawdX = SCREEN_W - 12 - 18 * kClawdS;   // 156; "100%" ends near 138
static constexpr int kClawdY = 40;
static uint8_t s_clawdFrame = 0xFF;

// Clawd's mood from the project board: alarmed for an approval, sad for an
// error, walking while something runs, pleased when all is done, asleep
// with nothing on the board. Blinks every 4 s while awake.
static uint8_t clawdFrame() {
    const Projects::Board& b = AttentionQueue::projects();
    int ord[Projects::kMax];
    int n = Projects::ordered(b, ord, AttentionQueue::now());
    uint8_t eyes = Display::CLAWD_SHUT;          // asleep: nothing going on
    bool walk = false;
    if (n) {
        switch (b.e[ord[0]].state) {             // ordered: most urgent first
            case Projects::P_APPROVAL: eyes = Display::CLAWD_WIDE; break;
            case Projects::P_ERROR:    eyes = Display::CLAWD_SAD;  break;
            case Projects::P_DONE:     eyes = Display::CLAWD_HAPPY; break;
            case Projects::P_WORKING:  eyes = Display::CLAWD_OPEN; walk = (millis() / 400) % 2; break;
            default:                   eyes = Display::CLAWD_OPEN; break;
        }
        if ((eyes == Display::CLAWD_OPEN || eyes == Display::CLAWD_WIDE) && millis() % 4000 < 150)
            eyes = Display::CLAWD_SHUT;          // blink
    }
    return eyes | (walk ? 0x10 : 0);
}

static void paintClawd(bool force = false) {
    uint8_t f = clawdFrame();
    if (!force && f == s_clawdFrame) return;
    Display::drawClawd(kClawdX, kClawdY, kClawdS, Display::CLAWD_ORANGE, f & 0x0F, f & 0x10);
    s_clawdFrame = f;
}

static void paintRightColumn() {
    tft.fillRect(kHeroRight, 26, SCREEN_W - kHeroRight, kResetY - 27, Theme::BG);
    paintClawd(true);
}

static void paintSessReset(time_t resetEpoch) {
    String s = (resetEpoch > 0) ? Api::formatCountdown(resetEpoch) : String("--");
    tft.fillRect(kHeroRight, kResetY - 1, SCREEN_W - kHeroRight - 8, 17, Theme::BG);
    Display::useFont("JBMono-12B");
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(Theme::CORAL, Theme::BG);
    tft.drawString(s, SCREEN_W - 12, kResetY);
    strncpy(s_heroReset, s.c_str(), sizeof(s_heroReset) - 1);
}

static void paintSessHero(float pct, bool stale) {
    char pctBuf[8];
    if (pct < 0) snprintf_P(pctBuf, sizeof(pctBuf), PSTR("--"));
    else         snprintf_P(pctBuf, sizeof(pctBuf), PSTR("%.0f"), Api::shownPct(pct));
    // Clear the hero band + suffix (left of the right column only)
    tft.fillRect(10, 46, kHeroRight - 10, 76, Theme::BG);

    // Stale data stays visible but dimmed — it is not a live reading.
    uint16_t uc = stale ? Theme::MUTED : Display::usageColor(pct);
    Display::useFont("VT323-86");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(uc, Theme::BG);
    tft.drawString(pctBuf, 12, 46);
    int heroW = tft.textWidth(pctBuf);
    int heroH = tft.fontHeight();

    Display::useFont("VT323-44");
    tft.setTextColor(uc, Theme::BG);
    int pctY = 46 + (heroH - tft.fontHeight()) - 4;
    tft.drawString("%", 12 + heroW + 2, pctY);

    Display::pixelBar(12, 128, SCREEN_W - 24, 8,
                     pct < 0 ? 0 : Api::shownPct(pct), uc);
}

static void paintWeeklyCompact(const char* label, float pct, time_t weekReset) {
    tft.fillRect(0, 150, SCREEN_W, 20, Theme::BG);
    Display::useFont("JBMono-11");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString(label, 12, 150);

    String s;
    if (pct < 0) s = "--";
    else {
        s = String((int)(Api::shownPct(pct) + 0.5f)) + "%";
        if (weekReset > 0) s += " \xC2\xB7 " + Api::formatCountdown(weekReset);
    }
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(Theme::INK_DIM, Theme::BG);
    tft.drawString(s, SCREEN_W - 12, 150);
    strncpy(s_secSub, s.c_str(), sizeof(s_secSub) - 1);

    uint16_t uc = Display::usageColor(pct);
    Display::pixelBar(12, 164, SCREEN_W - 24, 4, pct < 0 ? 0 : Api::shownPct(pct), uc);
}

// ── Project board rows ──
//
//   ■ glimmer     Cần duyệt · Bash    2M     square + status in the state colour
//   ■ api         Xong                 14M
//   NHỊP TUẦN                 HẾT SAU 5H     (weekly pace, only if a row is free)

static const char* stateLabel(Projects::State s) {
    switch (s) {
        case Projects::P_APPROVAL: return "Cần duyệt";
        case Projects::P_INPUT:    return "Chờ bạn";
        case Projects::P_ERROR:    return "Lỗi";
        case Projects::P_WORKING:  return "Đang chạy";
        default:                   return "Xong";
    }
}

static uint16_t stateColor(Projects::State s) {
    switch (s) {
        case Projects::P_APPROVAL: return Theme::AMBER;
        case Projects::P_INPUT:    return Theme::SKY;
        case Projects::P_ERROR:    return Theme::CORAL;
        case Projects::P_WORKING:  return Theme::LILAC;
        default:                   return Theme::MINT;
    }
}

// Cut whole UTF-8 characters until s fits maxW (current font).
static void fitTo(char* s, int maxW) {
    size_t n = strlen(s);
    while (n > 1 && tft.textWidth(s) > maxW) { n = Utf8::prevChar(s, n); s[n] = '\0'; }
}

static void paintProjectRow(const Projects::Entry& x, int y, uint32_t now) {
    const uint16_t sc = stateColor(x.state);
    tft.fillRect(12, y + 4, 5, 5, sc);

    char age[8]; TimeUtil::shortDuration((long)(now - x.since), age, sizeof(age));
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString(age, SCREEN_W - 12, y);
    const int right = SCREEN_W - 12 - tft.textWidth(age) - 8;

    char proj[24]; Utf8::copy(proj, sizeof(proj), x.project);
    fitTo(proj, 84);                                  // ≤ 12 glyphs
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::INK_DIM, Theme::BG);
    tft.drawString(proj, 22, y);
    const int sx = 22 + tft.textWidth(proj) + 8;

    char st[48];
    if (x.detail[0]) snprintf_P(st, sizeof(st), PSTR("%s \xC2\xB7 %s"), stateLabel(x.state), x.detail);
    else             snprintf_P(st, sizeof(st), PSTR("%s"), stateLabel(x.state));
    fitTo(st, right - sx);
    tft.setTextColor(sc, Theme::BG);
    tft.drawString(st, sx, y);
}

static uint32_t s_boardRev = 0;

// Bottom rows: credential banner > project board > weekly pace (3 rows).
static void paintBottomRows(const ClaudeData& d, const char* pace) {
    const int startY = 176, rowH = 14;
    tft.fillRect(0, startY, SCREEN_W, rowH * 3, Theme::BG);
    int row = 0;
    if (CredState::bad(d.cred)) {
        Chrome::credBanner(startY, true, d.cred);
        row = 1;
    }
    s_cred = d.cred;
    Display::useFont("JBMono-11");

    const Projects::Board& b = AttentionQueue::projects();
    const uint32_t now = AttentionQueue::now();
    int ord[Projects::kMax], n = Projects::ordered(b, ord, now);
    const int room = 3 - row;
    const int show = n > room ? room : n;
    for (int i = 0; i < show; i++, row++) paintProjectRow(b.e[ord[i]], startY + row * rowH, now);

    if (row < 3 && pace[0]) {
        int y = startY + row * rowH;
        tft.setTextDatum(TL_DATUM);
        tft.setTextColor(Theme::MUTED, Theme::BG);
        tft.drawString("NHỊP TUẦN", 12, y);
        tft.setTextDatum(TR_DATUM);
        tft.setTextColor(strncmp(pace, "HẾT", strlen("HẾT")) == 0 ? Theme::CORAL : Theme::INK_DIM, Theme::BG);
        tft.drawString(pace, SCREEN_W - 12, y);
        row++;
    }
    if (n == 0 && row < 3) {
        tft.setTextDatum(TL_DATUM);
        tft.setTextColor(Theme::MUTED, Theme::BG);
        tft.drawString("Chưa có hoạt động project", 12, startY + row * rowH);
    }
    Utf8::copy(s_pace, sizeof(s_pace), pace);
    s_boardRev = AttentionQueue::projectsRevision();
}

void chClaudeDraw(const ChannelCtx& ctx) {
    Display::clear();

    const ClaudeData& d = *ctx.claude;
    s_meta = metaFor(ctx);
    Display::statusBar("Claude", s_meta.text, Theme::CORAL, s_meta.color);

    // Nothing to show yet and something is wrong: the credential/offline card.
    if (!d.valid && (CredState::bad(d.cred) || d.err[0])) {
        Chrome::credCard(true, d.cred, 0, d.err);
        s_heroPct = -2.f; s_secPct = -2.f;
        s_heroReset[0] = 0; s_secSub[0] = 0;
        return;
    }
    if (!d.valid) {
        Display::useFont("JBMono-16B");
        tft.setTextDatum(MC_DATUM);
        tft.setTextColor(Theme::MUTED, Theme::BG);
        tft.drawString("Đang tải", SCREEN_W/2, 100);
        Display::loadingDots(SCREEN_W/2 - 21, 128, 0, Theme::CORAL);
        s_loadDot = 0;
        s_heroPct = -2.f; s_secPct = -2.f;
        s_heroReset[0] = 0; s_secSub[0] = 0;
        return;
    }

    const bool swapped = ctx.settings->claudeWeeklyHero;
    const float heroPct  = swapped ? d.weeklyPct   : d.sessionPct;
    const float secPct   = swapped ? d.sessionPct  : d.weeklyPct;
    const time_t heroRst = swapped ? d.weeklyReset : d.sessionReset;
    const time_t secRst  = swapped ? d.sessionReset: d.weeklyReset;
    s_stale = dimData(*ctx.settings, d.lastOk, d.cred);

    Display::useFont("JBMono-11");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString(swapped ? "TUẦN" : "PHIÊN 5 GIỜ", 12, 32);

    paintRightColumn();
    paintSessReset(heroRst);
    paintSessHero(heroPct, s_stale);
    Display::dotsDivider(12, 146, SCREEN_W - 24);

    const char* secLabel = swapped ? "PHIÊN 5 GIỜ" : "TUẦN";
    paintWeeklyCompact(secLabel, secPct, secRst);
    Display::dotsDivider(12, 170, SCREEN_W - 24);
    char pace[40]; paceFor(d, pace, sizeof(pace));
    paintBottomRows(d, pace);

    s_heroPct = (heroPct < 0) ? -2.f : heroPct;
    s_secPct  = (secPct  < 0) ? -2.f : secPct;
}

void chClaudeTick(const ChannelCtx& ctx) {
    if (!ctx.claude) return;
    const ClaudeData& d = *ctx.claude;
    if (!d.valid && (CredState::bad(d.cred) || d.err[0])) return;   // static card
    if (!d.valid) {                       // loading — sweep the chase dots
        int lit = (ctx.now_ms / 150) % 5;
        if (lit != s_loadDot) {
            Display::loadingDots(SCREEN_W/2 - 21, 128, lit, Theme::CORAL);
            s_loadDot = lit;
        }
        return;
    }

    // Countdown / badge / pace strings only change on a minute boundary;
    // recompute (and heap-allocate) them only then, not on every 5 Hz tick.
    time_t t = time(nullptr);
    struct tm tm; localtime_r(&t, &tm);
    static int s_cdMin = -1;
    const bool minTick = (tm.tm_min != s_cdMin);

    const bool swapped = ctx.settings->claudeWeeklyHero;
    const float heroPct  = swapped ? d.weeklyPct   : d.sessionPct;
    const float secPct   = swapped ? d.sessionPct  : d.weeklyPct;
    const time_t heroRst = swapped ? d.weeklyReset : d.sessionReset;
    const time_t secRst  = swapped ? d.sessionReset: d.weeklyReset;

    paintClawd();                       // mood / blink / step — only when the frame changes

    if (minTick) {
        MetaSlot m = metaFor(ctx);
        if (m != s_meta) { Display::statusMeta(m.text, Theme::CORAL, m.color); s_meta = m; }
        String fresh = (heroRst > 0) ? Api::formatCountdown(heroRst) : String("--");
        if (strcmp(fresh.c_str(), s_heroReset) != 0) paintSessReset(heroRst);
    }

    float p = (heroPct < 0) ? -2.f : heroPct;
    bool stale = dimData(*ctx.settings, d.lastOk, d.cred);
    if (fabsf(p - s_heroPct) > 0.4f || stale != s_stale) {
        paintSessHero(heroPct, stale);
        s_heroPct = p;
        s_stale = stale;
    }

    // Secondary compact row — pct moves on refresh, countdown at minute ticks.
    float sp = (secPct < 0) ? -2.f : secPct;
    bool secDirty = fabsf(sp - s_secPct) > 0.4f;
    if (!secDirty && minTick) {
        String subFresh;
        if (secPct < 0) subFresh = "--";
        else {
            subFresh = String((int)(Api::shownPct(secPct) + 0.5f)) + "%";   // as painted
            if (secRst > 0) subFresh += " \xC2\xB7 " + Api::formatCountdown(secRst);
        }
        if (strcmp(subFresh.c_str(), s_secSub) != 0) secDirty = true;
    }
    if (secDirty) {
        const char* secLabel = swapped ? "PHIÊN 5 GIỜ" : "TUẦN";
        paintWeeklyCompact(secLabel, secPct, secRst);
        s_secPct = sp;
    }

    // Bottom rows: the project board moved, the credential changed, or a new
    // minute (ages "2M" tick, entries time out, pace may change).
    bool rowsDirty = d.cred != s_cred || AttentionQueue::projectsRevision() != s_boardRev || minTick;
    if (rowsDirty) {
        char pace[40]; paceFor(d, pace, sizeof(pace));
        paintBottomRows(d, pace);
    }

    s_cdMin = tm.tm_min;
}
