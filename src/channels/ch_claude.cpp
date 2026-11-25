// Claude — design-true layout from ClaudeUsageScreen (screens.jsx:199-234).
//
// Fonts (regenerated via tools/genfonts.py at exact em-px sizes):
//   - "PHIÊN 5 GIỜ" / "TUẦN" / labels / sub-data : JBMono-11   (~13 px)
//   - countdown "3h 2m" (right, just above the bar)    : JBMono-12B  (~12 px)
//   - Clawd mascot top-right, mood from project board : Display::drawClawd
//   - hero "%" digits                                 : VT323-86   (~70 px)
//   - inline "%" suffix on hero                       : VT323-44   (~36 px)
//
// Dock layout (P-2026-11-25.3): content in x 40..228 (Layout::CONTENT_*);
// main.cpp paints the dock at x 2..31 — no band here starts left of x 40.
//
//   y=176..218  bottom rows: the project board (what each agent project is
//               doing: Cần duyệt / Chờ bạn / Lỗi / Đang chạy / Xong). Resets,
//               per-model windows and the weekly pace are not shown here.

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

// ── Region paint helpers (also called from draw()) ──

// Right column, beside the hero %:
//   y 58..98   Clawd 72×40 — mood follows the project board (tick); centred
//              on the hero digits' ink (y 53..102, VT323-86 drawn at y 46)
//   y 112      4d / 3h 14m   JBMono-12B      time left, right above the bar (tick)
// The hero repaint clears only x < kHeroRight, so this column is never wiped.
static constexpr int kL = Layout::CONTENT_LEFT;    // 40
static constexpr int kR = Layout::CONTENT_RIGHT;   // 228
static constexpr int kW = Layout::CONTENT_W;       // 188
static constexpr int kHeroRight = 150;      // "38%" ends at 128; "100" at 142 (no "%")
static constexpr int kResetY    = 112;      // bottom 126; the bar starts at 128
static constexpr int kClawdS = 4;                              // 18×10 cells → 72×40
static constexpr int kClawdX = kR - 18 * kClawdS;              // 156
static constexpr int kClawdY = 58;
static uint8_t s_clawdFrame = 0xFF;

// Clawd's mood from the project board: alarmed for an approval, sad for an
// error, walking while something runs, asleep (sleep eyes + "Zz", no blink)
// when everything is done or nothing is on the board (P-2026-11-25.5). Blinks
// every 4 s while awake.
static uint8_t clawdFrame() {
    const Projects::Board& b = AttentionQueue::projects();
    int ord[Projects::kMax];
    int n = Projects::ordered(b, ord, AttentionQueue::now());
    uint8_t eyes = Display::CLAWD_SLEEP;         // asleep: nothing going on
    bool walk = false;
    if (n) {
        switch (b.e[ord[0]].state) {             // ordered: most urgent first
            case Projects::P_APPROVAL: eyes = Display::CLAWD_WIDE; break;
            case Projects::P_ERROR:    eyes = Display::CLAWD_SAD;  break;
            case Projects::P_DONE:     eyes = Display::CLAWD_SLEEP; break;   // all done
            case Projects::P_WORKING:  eyes = Display::CLAWD_OPEN; walk = (millis() / 400) % 2; break;
            default:                   eyes = Display::CLAWD_OPEN; break;
        }
        if ((eyes == Display::CLAWD_OPEN || eyes == Display::CLAWD_WIDE) && millis() % 4000 < 150)
            eyes = Display::CLAWD_SHUT;          // blink
    }
    return eyes | (walk ? 0x10 : 0);
}

// "Zz" over a sleeping Clawd (design P-2026-11-25.2): bitmap glyphs, 2-px cells,
// MUTED — z 4×4 at (202,46), Z 5×5 at (214,30). Band 202..223 × 30..53.
static constexpr int kZzX = 202, kZzY = 30, kZzW = 22, kZzH = 24;

static void drawGlyph(const uint8_t* rows, int n, int x, int y, uint16_t color) {
    for (int j = 0; j < n; j++)
        for (int i = 0; i < n; i++)
            if (rows[j] & (1 << (n - 1 - i))) tft.fillRect(x + i * 2, y + j * 2, 2, 2, color);
}

static void paintZz(bool on) {
    static const uint8_t kz[4] = {0x0F, 0x02, 0x04, 0x0F};
    static const uint8_t kZ[5] = {0x1F, 0x02, 0x04, 0x08, 0x1F};
    tft.fillRect(kZzX, kZzY, kZzW, kZzH, Theme::BG);
    if (!on) return;
    drawGlyph(kz, 4, 202, 46, Theme::MUTED);
    drawGlyph(kZ, 5, 214, 30, Theme::MUTED);
}

static void paintClawd(bool force = false) {
    uint8_t f = clawdFrame();
    if (!force && f == s_clawdFrame) return;
    const bool asleep    = (f & 0x0F) == Display::CLAWD_SLEEP;
    const bool wasAsleep = s_clawdFrame != 0xFF && (s_clawdFrame & 0x0F) == Display::CLAWD_SLEEP;
    Display::drawClawd(kClawdX, kClawdY, kClawdS, Display::CLAWD_ORANGE, f & 0x0F, f & 0x10);
    if (asleep != wasAsleep || force) paintZz(asleep);
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
    tft.drawString(s, kR, kResetY);
    strncpy(s_heroReset, s.c_str(), sizeof(s_heroReset) - 1);
}

static void paintSessHero(float pct, bool stale) {
    char pctBuf[8];
    if (pct < 0) snprintf_P(pctBuf, sizeof(pctBuf), PSTR("--"));
    else         snprintf_P(pctBuf, sizeof(pctBuf), PSTR("%.0f"), Api::shownPct(pct));
    // Clear the hero band + suffix (left of the right column only)
    tft.fillRect(kL, 46, kHeroRight - kL, 76, Theme::BG);

    // Stale data stays visible but dimmed — it is not a live reading.
    uint16_t uc = stale ? Theme::MUTED : Display::usageColor(pct);
    Display::useFont("VT323-86");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(uc, Theme::BG);
    tft.drawString(pctBuf, kL, 46);
    int heroW = tft.textWidth(pctBuf);
    int heroH = tft.fontHeight();

    // "100" fills the column up to x 142; its "%" would run into Clawd (x 156).
    if (strlen(pctBuf) < 3) {
        Display::useFont("VT323-44");
        tft.setTextColor(uc, Theme::BG);
        int pctY = 46 + (heroH - tft.fontHeight()) - 4;
        tft.drawString("%", kL + heroW + 2, pctY);
    }

    Display::pixelBar(kL, 128, kW, 8,
                     pct < 0 ? 0 : Api::shownPct(pct), uc);
}

static void paintWeeklyCompact(const char* label, float pct, time_t weekReset) {
    tft.fillRect(kL, 150, SCREEN_W - kL, 20, Theme::BG);
    Display::useFont("JBMono-11");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString(label, kL, 150);

    String s;
    if (pct < 0) s = "--";
    else {
        s = String((int)(Api::shownPct(pct) + 0.5f)) + "%";
        if (weekReset > 0) s += " \xC2\xB7 " + Api::formatCountdown(weekReset);
    }
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(Theme::INK_DIM, Theme::BG);
    tft.drawString(s, kR, 150);
    strncpy(s_secSub, s.c_str(), sizeof(s_secSub) - 1);

    uint16_t uc = Display::usageColor(pct);
    Display::pixelBar(kL, 164, kW, 4, pct < 0 ? 0 : Api::shownPct(pct), uc);
}

// ── Project board rows ──
//
//   ■ glimmer Cần duyệt · Bash      2P     square + status in the state colour
//   ■ api     Xong                  14P
// The " · detail" part is dropped when it doesn't fit (the dock layout is
// 188 px wide): "Cần duyệt" rather than "Cần duyệt · Ba".

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
    tft.fillRect(kL, y + 4, 5, 5, sc);

    char age[8]; TimeUtil::shortDuration((long)(now - x.since), age, sizeof(age));
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString(age, kR, y);
    const int right = kR - tft.textWidth(age) - 8;

    char proj[24]; Utf8::copy(proj, sizeof(proj), x.project);
    fitTo(proj, 84);                                  // ≤ 12 glyphs
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::INK_DIM, Theme::BG);
    tft.drawString(proj, kL + 10, y);
    const int sx = kL + 10 + tft.textWidth(proj) + 8;

    char st[48];
    if (x.detail[0]) snprintf_P(st, sizeof(st), PSTR("%s \xC2\xB7 %s"), stateLabel(x.state), x.detail);
    else             snprintf_P(st, sizeof(st), PSTR("%s"), stateLabel(x.state));
    if (x.detail[0] && tft.textWidth(st) > right - sx)
        snprintf_P(st, sizeof(st), PSTR("%s"), stateLabel(x.state));   // drop the detail
    fitTo(st, right - sx);
    tft.setTextColor(sc, Theme::BG);
    tft.drawString(st, sx, y);
}

static uint32_t s_boardRev = 0;

// Bottom rows: credential banner > project board (3 rows).
static void paintBottomRows(const ClaudeData& d) {
    const int startY = 176, rowH = 14;
    tft.fillRect(kL, startY, SCREEN_W - kL, rowH * 3, Theme::BG);
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

    if (n == 0 && row < 3) {
        tft.setTextDatum(TL_DATUM);
        tft.setTextColor(Theme::MUTED, Theme::BG);
        tft.drawString("Chưa có hoạt động project", kL, startY + row * rowH);
    }
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
        tft.drawString("Đang tải", Layout::CONTENT_MID, 100);
        Display::loadingDots(Layout::CONTENT_MID - 21, 128, 0, Theme::CORAL);
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
    tft.drawString(swapped ? "TUẦN" : "PHIÊN 5 GIỜ", kL, 32);

    paintRightColumn();
    paintSessReset(heroRst);
    paintSessHero(heroPct, s_stale);
    Display::dotsDivider(kL, 146, kW);

    const char* secLabel = swapped ? "PHIÊN 5 GIỜ" : "TUẦN";
    paintWeeklyCompact(secLabel, secPct, secRst);
    Display::dotsDivider(kL, 170, kW);
    paintBottomRows(d);

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
            Display::loadingDots(Layout::CONTENT_MID - 21, 128, lit, Theme::CORAL);
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
    // minute (ages "2M" tick, entries time out).
    bool rowsDirty = d.cred != s_cred || AttentionQueue::projectsRevision() != s_boardRev || minTick;
    if (rowsDirty) {
        paintBottomRows(d);
    }

    s_cdMin = tm.tm_min;
}
