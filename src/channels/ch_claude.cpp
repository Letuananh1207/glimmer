// Claude — XP window (P-2026-11-26.8/.9, screen_specs §17 XP-Claude-*).
//
//   title     "Claude" (+ " · cũ 14P" / " · khóa lỗi" …)       XP::titleMeta
//   y 28      hero label "Hạn mức tuần" / "Phiên 5 giờ"         JBMono-11 LABEL
//   y 40      hero "38" VT323-86 + "%" VT323-44 at (10+w+2, 70) black (DIM stale); level colour in the bar only
//   y 36      Clawd 72×40 at x 156 (asleep: y 52 + animated Zz) — mood from the board
//   y 84      time to reset TR (229) — TR (150) while Clawd sleeps  JBMono-12B RED
//   y 102     XP progress 220×14
//   y 128     groupbox (10,128,220,34) other window: "12% · 2G 14P" TR (224,135) + bar 208×7
//   y 166     white field (10,166,220,44): the project board, 3 rows of 13 px
//             (credential info strip + 2 rows when the key is bad)
// No status bar: the field runs to y 209. Every band below is in the body
// (x 2..237, y 22..213) and cleared with XP::BODY / WHITE, never black.
//
// States: loading (XP::loading marquee), no data + bad key / offline / upstream
// error (Chrome::credCard message box), stale (title meta, values xpDim),
// key bad with data (info strip in the field), no project / all done (Clawd asleep).

#include "channel.h"
#include "chrome.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "layout.h"
#include "attention.h"
#include "timeutil.h"
#include "utf8.h"
#include "xp.h"
#include <math.h>
#include <time.h>

using namespace Theme::XP;

// ── tick() state cache (position-based, not source-based) ──
static float  s_heroPct  = -2.f;
static float  s_secPct   = -2.f;
static bool   s_stale    = false;
static char   s_heroReset[16] = "";
static char   s_secSub[40]    = "";
static Cred   s_cred          = Cred::NOT_SET;
static MetaSlot s_meta;
static bool   s_loading = false;
static uint32_t s_loadStep = 0;
static int8_t s_asleep = -1;          // Clawd layout on screen: -1 unknown, 0 awake, 1 asleep

bool chClaudeEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showClaude && !ctx.settings->claudeKey.isEmpty();
}

static MetaSlot metaFor(const ChannelCtx& ctx) {
    return xpUsageMeta(*ctx.settings, ctx.claude->lastOk, VendorStatus::CLAUDE,
                       "", ctx.claude->cred, 0);
}

// ── Geometry (XP-Claude-A source) ──
static constexpr int kL = Layout::XP_LEFT;          // 10
static constexpr int kR = Layout::XP_RIGHT;         // 229
static constexpr int kHeroY = 40, kPctY = 70;
static constexpr int kHeroClearR = 155;             // hero clears x 10..154 (Clawd from 156)
static constexpr int kBarY = 102;
static constexpr int kResetY = 84;
static constexpr int kResetXAwake = kR, kResetXAsleep = 150;
static constexpr int kClawdS = 4;                   // 18×10 cells → 72×40
static constexpr int kClawdX = 156;
static constexpr int kClawdYAwake = 36, kClawdYAsleep = 52;
static constexpr int kGroupY = 128, kGroupH = 34;
static constexpr int kFieldY = 166, kFieldH = 44;
static constexpr int kRowH = 13;
static uint8_t s_clawdFrame = 0xFF;

static uint16_t heroColor(float pct, bool dim) { return dim ? DIM : xpUsageColor(pct, GREEN); }
// Bars are the lighter xpBar while healthy (XP-Claude-A), else the text colour.
static uint16_t barColor(float pct, bool dim) {
    uint16_t c = heroColor(pct, dim);
    return c == GREEN ? BAR : c;
}

// Clawd's mood from the project board: alarmed for an approval, sad for an
// error, walking while something runs, asleep (sleep eyes + "Zz", no blink)
// when everything is done or nothing is on the board. Blinks every 4 s awake.
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
static bool frameAsleep(uint8_t f) { return (f & 0x0F) == Display::CLAWD_SLEEP; }

// ── Animated "Zz" over a sleeping Clawd (§6 table, token component.clawd.
// sleepMark), every frame moved with Clawd to y 52 (§17 "Clawd ngủ"): frame
// 6 lands at (196, 32), i.e. the §6 frames shifted (−6, −6) as drawn in
// XP-Claude-NoProject/-Done. One z drifts up and grows, 12 frames × 400 ms
// then a 1.2 s pause (6 s cycle). Each frame repaints only its box, which
// stops at the title bar: cells above y 22 are not drawn.
static constexpr int kZzDX = -6, kZzDY = -6;
static constexpr int kZzX = 196 + kZzDX, kZzY = Layout::XP_BODY_Y;   // box x 190..219, y 22..51
static constexpr int kZzW = 30, kZzH = kClawdYAsleep - Layout::XP_BODY_Y;
static constexpr uint32_t kZzFrameMs = 400, kZzCycleMs = 6000;
static constexpr int kZzFrames = 12;

struct ZzFrame { uint8_t glyph, x, y; bool faint; };   // glyph 0 = z3, 1 = z4, 2 = Z5
static const ZzFrame kZz[kZzFrames] PROGMEM = {
    {0, 198, 52, true},  {0, 200, 50, false}, {0, 202, 48, false}, {0, 203, 45, false},
    {1, 202, 42, false}, {1, 202, 40, false}, {1, 202, 38, false}, {1, 203, 36, false},
    {2, 204, 32, false}, {2, 206, 30, false}, {2, 208, 28, true},  {2, 209, 26, true},
};

static uint32_t s_zzT0    = 0;    // millis() of frame 0
static int8_t   s_zzShown = -1;   // frame on screen; kZzFrames = pause (blank); -1 = none

static void drawGlyph(const uint8_t* rows, int n, int x, int y, uint16_t color) {
    for (int j = 0; j < n; j++) {
        if (y + j * 2 < kZzY) continue;                      // never into the title bar
        for (int i = 0; i < n; i++)
            if (rows[j] & (1 << (n - 1 - i))) tft.fillRect(x + i * 2, y + j * 2, 2, 2, color);
    }
}

// k < kZzFrames: that frame; kZzFrames: blank (pause); -1: blank, Zz off.
static void paintZzFrame(int k) {
    static const uint8_t kz3[3] = {0x07, 0x02, 0x07};
    static const uint8_t kz4[4] = {0x0F, 0x02, 0x04, 0x0F};
    static const uint8_t kZ5[5] = {0x1F, 0x02, 0x04, 0x08, 0x1F};
    tft.fillRect(kZzX, kZzY, kZzW, kZzH, BODY);
    if (k >= 0 && k < kZzFrames) {
        ZzFrame f;
        memcpy_P(&f, &kZz[k], sizeof(f));
        const uint8_t* rows = f.glyph == 0 ? kz3 : f.glyph == 1 ? kz4 : kZ5;
        // Fading frames (LINE on the dark theme) are xpDim on the beige body.
        drawGlyph(rows, 3 + f.glyph, f.x + kZzDX, f.y + kZzDY, f.faint ? DIM : MUTED);
    }
    s_zzShown = (int8_t)k;
}

static void tickZz() {
    if (s_zzShown < 0) return;
    int k = (int)((millis() - s_zzT0) % kZzCycleMs / kZzFrameMs);
    if (k > kZzFrames) k = kZzFrames;
    if (k != s_zzShown) paintZzFrame(k);
}

// ── Region paint helpers (also called from draw()) ──

static bool s_dim = false;                 // values painted dimmed (stale)

static void paintReset(time_t resetEpoch) {
    String s = (resetEpoch > 0) ? Api::formatCountdown(resetEpoch) : String("--");
    const bool asleep = s_asleep == 1;
    // Awake: x 156..229 under Clawd (y 76..101). Asleep: left of Clawd, inside
    // the hero band (x 100..154) — only the countdown's own box.
    if (asleep) tft.fillRect(100, kResetY - 1, kHeroClearR - 100, 17, BODY);
    else        tft.fillRect(kClawdX, kClawdYAwake + 40, kR + 1 - kClawdX, kBarY - kClawdYAwake - 40, BODY);
    Display::useFont("JBMono-12B");
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(s_dim ? DIM : RED, BODY);
    tft.drawString(s, asleep ? kResetXAsleep : kResetXAwake, kResetY);
    Utf8::copy(s_heroReset, sizeof(s_heroReset), s.c_str());
}

static void paintHero(float pct) {
    char pctBuf[8];
    if (pct < 0) snprintf_P(pctBuf, sizeof(pctBuf), PSTR("--"));
    else         snprintf_P(pctBuf, sizeof(pctBuf), PSTR("%.0f"), Api::shownPct(pct));
    tft.fillRect(kL, kHeroY, kHeroClearR - kL, kBarY - kHeroY, BODY);   // x 10..154, y 40..101

    // Hero digits black like XP dialog text; the level colour lives in the bar
    // only (P-2026-11-26.11, token themeXP.rules.heroNumber).
    const uint16_t uc = s_dim ? DIM : BLACK;
    Display::useFont("VT323-86");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(uc, BODY);
    tft.drawString(pctBuf, kL, kHeroY);
    const int heroW = tft.textWidth(pctBuf);
    // "100" ends at x 112; its "%" would meet the sleeping-Clawd countdown.
    if (strlen(pctBuf) < 3 || s_asleep != 1) {
        Display::useFont("VT323-44");
        tft.setTextColor(uc, BODY);
        tft.drawString("%", kL + heroW + 2, kPctY);
    }
    XP::progress(kL, kBarY, kR + 1 - kL, 14, pct < 0 ? 0 : Api::shownPct(pct), barColor(pct, s_dim), 2);
}

static void paintClawd(bool force = false) {
    uint8_t f = clawdFrame();
    if (!force && f == s_clawdFrame) return;
    const bool asleep = frameAsleep(f);
    Display::drawClawd(kClawdX, asleep ? kClawdYAsleep : kClawdYAwake, kClawdS,
                       Display::CLAWD_ORANGE, f & 0x0F, f & 0x10, BODY);
    if (asleep && (s_zzShown < 0 || force)) { s_zzT0 = millis(); paintZzFrame(0); }
    s_clawdFrame = f;
}

// Clawd awake ↔ asleep moves Clawd (y 36 ↔ 52), the countdown (x 229 ↔ 150)
// and the Zz: clear the right column, then repaint the hero (its band holds
// the sleeping countdown), Clawd and the countdown.
static void paintRightColumn(float heroPct, time_t heroRst, bool asleep) {
    tft.fillRect(kHeroClearR, Layout::XP_BODY_Y, kR + 1 - kHeroClearR, kBarY - Layout::XP_BODY_Y, BODY);
    s_zzShown = -1;
    s_asleep = asleep ? 1 : 0;
    paintHero(heroPct);
    paintClawd(true);
    paintReset(heroRst);
}

// Group "Phiên 5 giờ" / "Hạn mức tuần": "12% · 2G 14P" TR (224,135) + bar (16,151,208,7).
static void secText(float pct, time_t reset, char* buf, size_t n) {
    if (pct < 0) { snprintf_P(buf, n, PSTR("--")); return; }
    if (reset > 0)
        snprintf_P(buf, n, PSTR("%d%% \xC2\xB7 %s"), (int)(Api::shownPct(pct) + 0.5f),
                   Api::formatCountdown(reset).c_str());
    else
        snprintf_P(buf, n, PSTR("%d%%"), (int)(Api::shownPct(pct) + 0.5f));
}

static void paintSecondary(float pct, time_t reset) {
    char s[40]; secText(pct, reset, s, sizeof(s));
    tft.fillRect(kL + 2, 135, 216, 14, BODY);           // inside the groupbox, y 135..148
    Display::useFont("JBMono-11");
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(s_dim ? DIM : BLACK, BODY);
    tft.drawString(s, 224, 135);
    Utf8::copy(s_secSub, sizeof(s_secSub), s);
    XP::progress(16, 151, 208, 7, pct < 0 ? 0 : Api::shownPct(pct), barColor(pct, s_dim));
}

// ── Project board rows (white field) ──
//
//   ■ glimmer Cần duyệt · Bash      2P     square + status in the state colour
// Square 5×5 at (14, y+4), name TL (23, y) black, status 7 px after the
// name, age TR (225, y) muted. The " · detail" part is dropped when it
// doesn't fit; stale data dims square, name and status (XP-Claude-Stale).

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
        case Projects::P_APPROVAL: return AMBER;
        case Projects::P_INPUT:    return SKY;
        case Projects::P_ERROR:    return RED;
        case Projects::P_WORKING:  return LILAC;
        default:                   return GREEN;
    }
}

static void paintProjectRow(const Projects::Entry& x, int y, uint32_t now) {
    const uint16_t sc = s_dim ? DIM : stateColor(x.state);
    tft.fillRect(14, y + 4, 5, 5, sc);

    char age[8]; TimeUtil::shortDuration((long)(now - x.since), age, sizeof(age));
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(MUTED, WHITE);
    tft.drawString(age, 225, y);
    const int right = 225 - tft.textWidth(age) - 7;

    char proj[24]; Utf8::copy(proj, sizeof(proj), x.project);
    XP::fitText(proj, 84);                            // ≤ 12 glyphs
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(s_dim ? DIM : BLACK, WHITE);
    tft.drawString(proj, 23, y);
    const int sx = 23 + tft.textWidth(proj) + 7;

    char st[48];
    if (x.detail[0]) snprintf_P(st, sizeof(st), PSTR("%s \xC2\xB7 %s"), stateLabel(x.state), x.detail);
    else             snprintf_P(st, sizeof(st), PSTR("%s"), stateLabel(x.state));
    if (x.detail[0] && tft.textWidth(st) > right - sx)
        snprintf_P(st, sizeof(st), PSTR("%s"), stateLabel(x.state));   // drop the detail
    XP::fitText(st, right - sx);
    tft.setTextColor(sc, WHITE);
    tft.drawString(st, sx, y);
}

static uint32_t s_boardRev = 0;

// Field interior (x 11..228, y 167..208): credential strip + rule (KeyExpired)
// then the board, or "Chưa có hoạt động project" centred.
static void paintBottomRows(const ClaudeData& d) {
    tft.fillRect(kL + 1, kFieldY + 1, kR - kL - 1, kFieldH - 2, WHITE);
    int y = kFieldY + 2, rows = 3;                      // rows at 168, 181, 194
    if (CredState::bad(d.cred)) {
        Chrome::credBanner(kL + 1, kFieldY + 1, kR - kL - 1, true, d.cred);   // y 167..180
        tft.drawFastHLine(kL + 1, kFieldY + 15, kR - kL - 1, STATUS_LINE);      // y 181
        y = kFieldY + 16;                               // rows at 182, 195
        rows = 2;
    }
    s_cred = d.cred;
    Display::useFont("JBMono-11");

    const Projects::Board& b = AttentionQueue::projects();
    const uint32_t now = AttentionQueue::now();
    int ord[Projects::kMax], n = Projects::ordered(b, ord, now);
    const int show = n > rows ? rows : n;
    for (int i = 0; i < show; i++) paintProjectRow(b.e[ord[i]], y + i * kRowH, now);

    if (n == 0) {
        tft.setTextDatum(TC_DATUM);
        tft.setTextColor(MUTED, WHITE);
        tft.drawString("Chưa có hoạt động project", Layout::XP_MID, rows == 3 ? 182 : y + 7);
    }
    s_boardRev = AttentionQueue::projectsRevision();
}

struct Windows { float heroPct, secPct; time_t heroRst, secRst; bool weeklyHero; };
static Windows windowsFor(const ChannelCtx& ctx) {
    const ClaudeData& d = *ctx.claude;
    const bool w = ctx.settings->claudeWeeklyHero;
    return { w ? d.weeklyPct : d.sessionPct, w ? d.sessionPct : d.weeklyPct,
             w ? d.weeklyReset : d.sessionReset, w ? d.sessionReset : d.weeklyReset, w };
}

void chClaudeDraw(const ChannelCtx& ctx) {
    XP::window("Claude", XPCore::ICON_CLAWD, false);
    const ClaudeData& d = *ctx.claude;
    s_meta = metaFor(ctx);
    XP::titleMeta(s_meta.text);
    s_heroPct = -2.f; s_secPct = -2.f;
    s_heroReset[0] = 0; s_secSub[0] = 0;
    s_asleep = -1; s_zzShown = -1; s_clawdFrame = 0xFF;
    s_loading = false;

    // Nothing to show yet and something is wrong: the XP message box.
    if (!d.valid && (CredState::bad(d.cred) || d.err[0])) {
        Chrome::credCard(true, d.cred, 0, d.err);
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
    s_dim = s_stale;

    Display::useFont("JBMono-11");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(LABEL, BODY);
    tft.drawString(w.weeklyHero ? "Hạn mức tuần" : "Phiên 5 giờ", kL, 28);

    paintRightColumn(w.heroPct, w.heroRst, frameAsleep(clawdFrame()));

    XP::groupBox(kL, kGroupY, kR + 1 - kL, kGroupH, w.weeklyHero ? "Phiên 5 giờ" : "Hạn mức tuần");
    paintSecondary(w.secPct, w.secRst);

    XP::field(kL, kFieldY, kR + 1 - kL, kFieldH);
    paintBottomRows(d);

    s_heroPct = (w.heroPct < 0) ? -2.f : w.heroPct;
    s_secPct  = (w.secPct  < 0) ? -2.f : w.secPct;
}

void chClaudeTick(const ChannelCtx& ctx) {
    if (!ctx.claude) return;
    const ClaudeData& d = *ctx.claude;
    if (!d.valid && (CredState::bad(d.cred) || d.err[0])) return;   // static message box
    if (!d.valid) {                       // loading — advance the marquee
        uint32_t step = ctx.now_ms / 200;
        if (s_loading && step != s_loadStep) { XP::loadingStep(step); s_loadStep = step; }
        return;
    }

    // Countdowns / meta only change on a minute boundary; recompute (and
    // heap-allocate) them only then, not on every 5 Hz tick.
    time_t t = time(nullptr);
    struct tm tm; localtime_r(&t, &tm);
    static int s_cdMin = -1;
    const bool minTick = (tm.tm_min != s_cdMin);

    const Windows w = windowsFor(ctx);
    const bool stale = Api::isStale(d.lastOk, *ctx.settings);
    const bool dimChanged = stale != s_stale;
    s_stale = stale;
    s_dim = stale;

    // Clawd: awake ↔ asleep relays the right column; otherwise only the frame.
    const bool asleep = frameAsleep(clawdFrame());
    if ((asleep ? 1 : 0) != s_asleep) {
        paintRightColumn(w.heroPct, w.heroRst, asleep);
        s_heroPct = (w.heroPct < 0) ? -2.f : w.heroPct;
    } else {
        paintClawd();                     // mood / blink / step — only when the frame changes
    }
    tickZz();                             // sleeping: next Zz frame every 400 ms

    if (minTick || dimChanged) {
        MetaSlot m = metaFor(ctx);
        if (m != s_meta) { XP::titleMeta(m.text); s_meta = m; }
    }

    float p = (w.heroPct < 0) ? -2.f : w.heroPct;
    if (fabsf(p - s_heroPct) > 0.4f || dimChanged) {
        paintHero(w.heroPct);
        if (s_asleep == 1) paintReset(w.heroRst);       // its slot is inside the hero band
        s_heroPct = p;
    }
    if (minTick || dimChanged) {
        String fresh = (w.heroRst > 0) ? Api::formatCountdown(w.heroRst) : String("--");
        if (dimChanged || strcmp(fresh.c_str(), s_heroReset) != 0) paintReset(w.heroRst);
    }

    // Secondary group — pct moves on refresh, countdown at minute ticks.
    float sp = (w.secPct < 0) ? -2.f : w.secPct;
    bool secDirty = fabsf(sp - s_secPct) > 0.4f || dimChanged;
    if (!secDirty && minTick) {
        char fresh[40]; secText(w.secPct, w.secRst, fresh, sizeof(fresh));
        if (strcmp(fresh, s_secSub) != 0) secDirty = true;
    }
    if (secDirty) {
        paintSecondary(w.secPct, w.secRst);
        s_secPct = sp;
    }

    // Field: the board moved, the credential changed, staleness flipped, or a
    // new minute (ages "2P" tick, entries time out).
    if (d.cred != s_cred || AttentionQueue::projectsRevision() != s_boardRev || minTick || dimChanged)
        paintBottomRows(d);

    s_cdMin = tm.tm_min;
}
