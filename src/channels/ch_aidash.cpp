// AI hôm nay — combined Claude + Codex glance, XP window
// (P-2026-11-26.8/.9, screen_specs §17 XP-AI / -AI-Loading / -AI-KeyBad).
//
//   y 28      hero label JBMono-11 LABEL
//   y 40      hero "$4.20" VT323-86 black — the Codex credits left (the
//             pre-XP "$4.20" status meta); "--" xpDim when none / loading
//   y 120     two groupboxes 106×66 "Claude" (x 10) / "Codex" (x 124):
//             value VT323-44 at (+8, 128) black, bar in the usage colour ("Khóa" red when
//             the credential is bad, "--" xpDim while loading), bar 90×12 at y 164
//   y 196     status bar: advice left ("Dùng Claude"), resets right
//             ("CL 2G 14P · CX 3NG"); loading "Đang tải..." / "CL -- · CX --";
//             a bad credential "Khóa Claude bị từ chối" (no right text)

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "api.h"
#include "chrome.h"
#include "layout.h"
#include "timeutil.h"
#include "utf8.h"
#include "xp.h"
#include <math.h>
#include <time.h>

using namespace Theme::XP;

static constexpr int kL = Layout::XP_LEFT;    // 10
static constexpr int kHeroY = 40;
static constexpr int kBoxY = 120, kBoxW = 106, kBoxH = 66;
static constexpr int kBoxX[2] = {10, 124};

// tick cache
static float s_pct[2]  = {-2.f, -2.f};
static int8_t s_mode[2] = {-1, -1};          // 0 value, 1 loading, 2 bad credential, 3 stale value
static Cred  s_credSeen[2] = {Cred::NOT_SET, Cred::NOT_SET};
static float s_credits = -3.f;
static char  s_left[64]  = "";
static char  s_right[48] = "";
static MetaSlot s_meta;

bool chAiDashEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showAiDash
        && !ctx.settings->claudeKey.isEmpty()
        && !ctx.settings->codexToken.isEmpty();
}

struct Side { float pct; bool loading; Cred cred; bool stale; time_t reset; };
static Side sideOf(const ChannelCtx& ctx, int i) {
    if (i == 0) {
        const ClaudeData& d = *ctx.claude;
        const bool w = ctx.settings->claudeWeeklyHero;
        return { Api::claudeHeroPct(*ctx.settings, d), claudeLoading(d), d.cred,
                 d.valid && Api::isStale(d.lastOk, *ctx.settings), w ? d.weeklyReset : d.sessionReset };
    }
    const CodexData& d = *ctx.codex;
    const bool realSecondary = d.secondaryPct >= 0 && d.secondaryTag[0] == '\0';
    const bool sw = realSecondary && ctx.settings->codexWeeklyHero;
    return { Api::codexHeroPct(*ctx.settings, d), codexLoading(d), d.cred,
             d.valid && Api::isStale(d.lastOk, *ctx.settings), sw ? d.secondaryReset : d.primaryReset };
}
static int8_t modeOf(const Side& s) {
    if (CredState::bad(s.cred)) return 2;
    if (s.loading) return 1;
    return s.stale ? 3 : 0;
}

// Value + bar inside one groupbox (interior only; the outline stays).
static void paintBlock(int i, const Side& s) {
    const int bx = kBoxX[i];
    tft.fillRect(bx + 2, 127, kBoxW - 4, 37, BODY);          // y 127..163
    const int8_t mode = modeOf(s);
    char buf[12];
    uint16_t c;
    if (mode == 2) {
        // The number isn't live: say why (XP-AI-KeyBad).
        snprintf_P(buf, sizeof(buf), s.cred == Cred::BLOCKED ? PSTR("Chặn") : PSTR("Khóa"));
        c = xpCredColor(s.cred);
    } else if (mode == 1 || s.pct < 0) {
        snprintf_P(buf, sizeof(buf), PSTR("--"));
        c = DIM;
    } else {
        snprintf_P(buf, sizeof(buf), PSTR("%.0f%%"), Api::shownPct(s.pct));
        c = mode == 3 ? DIM : BLACK;   // black number, level colour in the bar (P-2026-11-26.11)
    }
    Display::useFont("VT323-44");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(c, BODY);
    tft.drawString(buf, bx + 8, 128);
    const bool lit = mode == 0 || mode == 3;
    XP::progress(bx + 8, 164, 90, 12, (lit && s.pct >= 0) ? Api::shownPct(s.pct) : 0,
                 mode == 3 ? DIM : xpUsageColor(s.pct, GREEN), 1);
    s_pct[i] = s.pct < 0 ? -2.f : s.pct;
    s_mode[i] = mode;
    s_credSeen[i] = s.cred;
}

// Hero: the Codex credits left. "$123.45" is wider than the body at 86 px →
// VT323-44 (theo XP thật: text shrinks to its box rather than clipping).
static void paintHero(const ChannelCtx& ctx) {
    const CodexData& d = *ctx.codex;
    const float credits = d.creditsRemain;
    tft.fillRect(kL, kHeroY, Layout::XP_RIGHT + 1 - kL, kBoxY - 6 - kHeroY, BODY);   // y 40..113
    char buf[16];
    uint16_t c = BLACK;
    if (credits >= 0) snprintf_P(buf, sizeof(buf), PSTR("$%.2f"), credits);
    else { snprintf_P(buf, sizeof(buf), PSTR("--")); c = DIM; }
    if (credits >= 0 && d.valid && Api::isStale(d.lastOk, *ctx.settings)) c = DIM;
    Display::useFont("VT323-86");
    int y = kHeroY;
    if (tft.textWidth(buf) > Layout::XP_RIGHT + 1 - kL) { Display::useFont("VT323-44"); y = kHeroY + 24; }
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(c, BODY);
    tft.drawString(buf, kL, y);
    s_credits = credits;
}

// "Dùng Claude" — which weekly allowance to spend next (the XP wording of
// Api::adviceText, sentence case and short enough for the status bar).
static void adviceText(const ClaudeData& cl, const CodexData& cx, char* buf, size_t n) {
    if (n) buf[0] = '\0';
    if (!cl.valid || !cx.valid || cl.weeklyPct < 0 || cx.primaryPct < 0) return;
    time_t now = time(nullptr);
    if (now < 1000000000L) return;
    struct Cand { const char* name; float pct; time_t reset; const ResetGrant* g; } c[2] = {
        {"Claude", cl.weeklyPct, cl.weeklyReset, &cl.resets},
        {"Codex",  cx.primaryPct, cx.primaryReset, &cx.resets},
    };
    // Nearly out, but a limit-reset credit can be spent right now.
    for (auto& k : c) {
        if (k.pct < 15.0f && k.g->left && k.g->usable) {
            snprintf_P(buf, n, PSTR("%s có %u lượt đặt lại"), k.name, k.g->left);
            return;
        }
    }
    // Use-it-or-lose-it: resets within 48 h with ≥ 25% unused; else most room.
    int pick = -1;
    for (int i = 0; i < 2; i++) {
        long left = (long)(c[i].reset - now);
        if (c[i].reset <= now || left > 48L * 3600L || c[i].pct < 25.0f) continue;
        if (pick < 0 || c[i].reset < c[pick].reset) pick = i;
    }
    if (pick < 0) {
        pick = c[0].pct >= c[1].pct ? 0 : 1;
        if (c[pick].pct < 15.0f) { snprintf_P(buf, n, PSTR("Cả hai sắp hết")); return; }
    }
    snprintf_P(buf, n, PSTR("Dùng %s"), c[pick].name);
}

static void statusTexts(const ChannelCtx& ctx, const Side s[2], char* left, size_t ln,
                        char* right, size_t rn, uint16_t& leftColor) {
    left[0] = right[0] = '\0';
    leftColor = BLACK;
    for (int i = 0; i < 2; i++) {
        if (CredState::bad(s[i].cred)) {          // XP-AI-KeyBad: the reason, no right text
            Chrome::credStatus(i == 0, s[i].cred, left, ln);
            return;
        }
    }
    char r[2][12];
    for (int i = 0; i < 2; i++) {
        if (s[i].loading || s[i].reset <= 0) snprintf_P(r[i], sizeof(r[i]), PSTR("--"));
        else Utf8::copy(r[i], sizeof(r[i]), Api::formatCountdown(s[i].reset).c_str());
    }
    snprintf_P(right, rn, PSTR("CL %s \xC2\xB7 CX %s"), r[0], r[1]);
    if (s[0].loading || s[1].loading) { snprintf_P(left, ln, PSTR("Đang tải...")); return; }
    adviceText(*ctx.claude, *ctx.codex, left, ln);
}

static void paintStatus(const ChannelCtx& ctx, const Side s[2], bool force) {
    char left[64], right[48]; uint16_t lc;
    statusTexts(ctx, s, left, sizeof(left), right, sizeof(right), lc);
    if (!force && !strcmp(left, s_left) && !strcmp(right, s_right)) return;
    Utf8::copy(s_left, sizeof(s_left), left);
    Utf8::copy(s_right, sizeof(s_right), right);
    // A long left text keeps its words: the right text goes instead of
    // clipping the advice ("Claude có 2 lượt đặt lại").
    Display::useFont("JBMono-11");
    if (right[0] && left[0] &&
        8 + tft.textWidth(left) + 4 > XPCore::statusDividerX(tft.textWidth(right)) - 4)
        right[0] = '\0';
    XP::statusBar(left, right, lc, BLACK);
}

static MetaSlot metaFor(const ChannelCtx& ctx) {
    // Stale numbers: "AI hôm nay · cũ 14P" from the older of the two.
    MetaSlot m;
    const ClaudeData& cl = *ctx.claude;
    const CodexData& cx = *ctx.codex;
    const bool a = cl.valid && Api::isStale(cl.lastOk, *ctx.settings);
    const bool b = cx.valid && Api::isStale(cx.lastOk, *ctx.settings);
    if (a || b) {
        time_t oldest = (a && b) ? (cl.lastOk < cx.lastOk ? cl.lastOk : cx.lastOk) : (a ? cl.lastOk : cx.lastOk);
        xpStaleText(oldest, *ctx.settings, m.text, sizeof(m.text));
        m.color = DIM;
    }
    return m;
}

void chAiDashDraw(const ChannelCtx& ctx) {
    XP::window("AI hôm nay", XPCore::ICON_CLAWD, true);
    s_meta = metaFor(ctx);
    XP::titleMeta(s_meta.text);

    // "Chi phí hôm nay" in the design, but the device has no spend figure:
    // the number is the Codex credits left (the pre-XP "$4.20" meta).
    Display::useFont("JBMono-11");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(LABEL, BODY);
    tft.drawString("Tín dụng Codex còn", kL, 28);
    paintHero(ctx);

    XP::groupBox(kBoxX[0], kBoxY, kBoxW, kBoxH, "Claude");
    XP::groupBox(kBoxX[1], kBoxY, kBoxW, kBoxH, "Codex");
    Side s[2] = {sideOf(ctx, 0), sideOf(ctx, 1)};
    paintBlock(0, s[0]);
    paintBlock(1, s[1]);
    paintStatus(ctx, s, true);
}

void chAiDashTick(const ChannelCtx& ctx) {
    Side s[2] = {sideOf(ctx, 0), sideOf(ctx, 1)};
    bool changed = false;
    for (int i = 0; i < 2; i++) {
        float p = s[i].pct < 0 ? -2.f : s[i].pct;
        if (modeOf(s[i]) != s_mode[i] || s[i].cred != s_credSeen[i] || fabsf(p - s_pct[i]) > 0.4f) {
            paintBlock(i, s[i]);
            changed = true;
        }
    }
    if (fabsf(ctx.codex->creditsRemain - s_credits) > 0.005f || changed) paintHero(ctx);

    // Countdowns / advice have minute granularity: recompute (and heap-
    // allocate) the strings only when the minute rolls over or data moved.
    time_t t = time(nullptr);
    struct tm tm; localtime_r(&t, &tm);
    static int s_cdMin = -1;
    if (tm.tm_min != s_cdMin || changed) {
        s_cdMin = tm.tm_min;
        paintStatus(ctx, s, false);
        MetaSlot m = metaFor(ctx);
        if (m != s_meta) { XP::titleMeta(m.text); s_meta = m; }
    }
}
