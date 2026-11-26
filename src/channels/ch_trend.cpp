// Xu hướng — 7-day burn per provider, from the usage history ring. XP window
// (P-2026-11-26.8/.9, screen_specs §17 XP-Trend / -Trend-Collecting).
//
//   y 28      "7 ngày · % hạn mức tuần"                     JBMono-11 LABEL
//   y 44      white field (10,44,220,130): legend ■ Claude (12,48)/(24,46),
//             ■ Codex (84,48)/(96,46) — not while collecting; paired bars 10 px wide, Claude x 18+30i,
//             Codex x 29+30i, standing on the rule y 164 (x 14..225), up to
//             102 px tall (y 62); one provider → one centred bar per day
//   y 177     weekday TC (28+30i)                           JBMono-11 MUTED
//   y 196     status bar: "Hôm nay CL 9 · CX 4" | "Đỉnh T2"; collecting:
//             "Có 2 / 7 ngày" + "Đang thu thập..." centred over the empty days
//
// A bar = percentage points of that provider's weekly allowance used that day
// (positive drops summed; a window reset never reads as negative use). A dead
// credential freezes its bars in xpDim and the status bar says why.

#include "clockfmt.h"
#include "channel.h"
#include "display.h"
#include "history.h"
#include "chrome.h"
#include "theme.h"
#include "config.h"
#include "layout.h"
#include "utf8.h"
#include "xp.h"
#include <math.h>
#include <time.h>

using namespace Theme::XP;

static constexpr int kFieldX = 10, kFieldY = 44, kFieldW = 220, kFieldH = 130;
static constexpr int kBase = 164;            // rule y 164; bars end at y 163
static constexpr int kBarMaxH = 102;         // tallest bar tops out at y 62 (legend above)
static constexpr int kStep = 30, kBarW = 10;

static float    s_today[2] = {-1.f, -1.f};
static uint32_t s_hour = 0;
static Cred     s_cred[2] = {Cred::NOT_SET, Cred::NOT_SET};   // claude, codex at last paint

struct Block { const char* tag; const char* shortTag; uint16_t color; History::Metric metric; Cred cred; bool isClaude; };

static int blocksFor(const ChannelCtx& ctx, Block out[2]) {
    int n = 0;
    if (!ctx.settings->claudeKey.isEmpty())
        out[n++] = {"Claude", "CL", RED,   History::CLAUDE_WEEK, ctx.claude->cred, true};
    if (!ctx.settings->codexToken.isEmpty())
        out[n++] = {"Codex",  "CX", LILAC, History::CODEX_WEEK,  ctx.codex->cred,  false};
    return n;
}

// Worth a slide only if some configured provider either has history to plot
// or a working credential that will produce some. All keys dead and nothing
// recorded = an empty chart; the Claude/Codex windows already explain why.
bool chTrendEnabled(const ChannelCtx& ctx) {
    if (!ctx.settings || !ctx.settings->showTrend || time(nullptr) < 1000000000L) return false;
    Block b[2];
    int n = blocksFor(ctx, b);
    for (int i = 0; i < n; i++) {
        if (!CredState::bad(b[i].cred)) return true;
        if (History::lastReading(UsageHistory::ring(), b[i].metric, time(nullptr))) return true;
    }
    return false;
}

static History::Trend trendFor(const Settings& s, History::Metric m) {
    return History::trend(UsageHistory::ring(), m, time(nullptr), (long)s.tzMinutes * 60L);
}

static const char* weekdayAgo(int back) {
    time_t d = time(nullptr) - back * 86400L;
    struct tm tm; localtime_r(&d, &tm);
    return ClockFmt::weekday(tm.tm_wday, false);   // "T2" … "CN"
}

// Field interior: legend, bars, rule, and the "collecting" note.
static void paintChart(const Block* b, int n, const History::Trend* t, int haveDays) {
    tft.fillRect(kFieldX + 1, kFieldY + 1, kFieldW - 2, kFieldH - 2, WHITE);

    Display::useFont("JBMono-11");
    tft.setTextDatum(TL_DATUM);
    // Legend only once the week is full: XP-Trend-Collecting has none (the
    // note sits where it would read).
    for (int k = 0; k < n && haveDays >= 7; k++) {
        const int lx = 12 + k * 72;
        tft.fillRect(lx, 48, 8, 8, CredState::bad(b[k].cred) ? DIM : b[k].color);
        tft.setTextColor(BLACK, WHITE);
        tft.drawString(b[k].tag, lx + 12, 46);
    }

    float scale = 10.0f;                      // floor: tiny noise never fills a bar
    for (int k = 0; k < n; k++) for (float v : t[k].burn) if (v > scale) scale = v;

    for (int i = 0; i < 7; i++) {
        const int colX = 18 + i * kStep;
        for (int k = 0; k < n; k++) {
            if (!t[k].have[i]) continue;
            if (t[k].burn[i] <= 0) continue;
            int h = (int)(t[k].burn[i] / scale * kBarMaxH + 0.5f);
            if (h < 2) h = 2;
            if (h > kBarMaxH) h = kBarMaxH;
            const int x = n == 2 ? colX + k * (kBarW + 1) : colX + 5;   // one provider: centred on 28+30i
            tft.fillRect(x, kBase - h, kBarW, h, CredState::bad(b[k].cred) ? DIM : b[k].color);
        }
    }
    tft.drawFastHLine(14, kBase, 212, STATUS_LINE);

    // XP-Trend-Collecting: the empty days on the left hold the note, centred
    // on them (5 empty days → x 90) when it fits (≥ 4 days = 120 px).
    if (haveDays < 7) {
        const int empty = 7 - haveDays;       // days before the first reading
        if (empty >= 4) {
            tft.setTextDatum(TC_DATUM);
            tft.setTextColor(MUTED, WHITE);
            tft.drawString("Đang thu thập...", 15 + 15 * empty, 100);
        }
    }
}

static void paintWeekdays() {
    tft.fillRect(kFieldX, kFieldY + kFieldH + 1, kFieldW, 18, BODY);   // y 175..192
    Display::useFont("JBMono-11");
    tft.setTextDatum(TC_DATUM);
    tft.setTextColor(MUTED, BODY);
    for (int i = 0; i < 7; i++) tft.drawString(weekdayAgo(6 - i), 28 + i * kStep, 177);
}

// Status bar: a dead credential first ("Khóa Claude hết hạn" | "cuối 3/8"),
// then collecting ("Có 2 / 7 ngày"), else "Hôm nay CL 9 · CX 4" | "Đỉnh T2".
static void paintStatus(const Block* b, int n, const History::Trend* t, int haveDays) {
    char left[64] = "", right[24] = "";
    uint16_t lc = BLACK;
    for (int k = 0; k < n; k++) {
        if (!CredState::bad(b[k].cred)) continue;
        Chrome::credStatus(b[k].isClaude, b[k].cred, left, sizeof(left));
        lc = xpCredColor(b[k].cred);
        const time_t last = History::lastReading(UsageHistory::ring(), b[k].metric, time(nullptr));
        if (last) {
            struct tm tm; localtime_r(&last, &tm);
            snprintf_P(right, sizeof(right), PSTR("cuối %d/%d"), tm.tm_mday, tm.tm_mon + 1);
        }
        XP::statusBar(left, right, lc, MUTED);
        return;
    }
    if (haveDays < 7) {
        snprintf_P(left, sizeof(left), PSTR("Có %d / 7 ngày"), haveDays);
        XP::statusBar(left, "");
        return;
    }
    int pos = snprintf_P(left, sizeof(left), PSTR("Hôm nay"));
    for (int k = 0; k < n && pos < (int)sizeof(left); k++)
        pos += snprintf_P(left + pos, sizeof(left) - pos, k ? PSTR(" \xC2\xB7 %s %.0f") : PSTR(" %s %.0f"),
                          b[k].shortTag, t[k].have[6] ? t[k].burn[6] : 0.f);
    // Peak = the day with the most combined burn.
    int peak = -1; float best = 0;
    for (int i = 0; i < 7; i++) {
        float sum = 0;
        for (int k = 0; k < n; k++) if (t[k].have[i]) sum += t[k].burn[i];
        if (sum > best) { best = sum; peak = i; }
    }
    if (peak >= 0) snprintf_P(right, sizeof(right), PSTR("Đỉnh %s"), weekdayAgo(6 - peak));
    XP::statusBar(left, right);
}

static void paintAll(const ChannelCtx& ctx) {
    Block b[2];
    int n = blocksFor(ctx, b);
    History::Trend t[2];
    for (int k = 0; k < n; k++) t[k] = trendFor(*ctx.settings, b[k].metric);
    // Days since the first reading in the window (a gap day later on is not
    // "collecting": it just has no bar).
    int haveDays = 0;
    for (int i = 0; i < 7 && !haveDays; i++)
        for (int k = 0; k < n; k++) if (t[k].have[i]) { haveDays = 7 - i; break; }
    paintChart(b, n, t, haveDays);
    paintWeekdays();
    paintStatus(b, n, t, haveDays);
    for (int k = 0; k < n; k++) s_today[k] = t[k].have[6] ? t[k].burn[6] : -1.f;
    s_cred[0] = ctx.claude->cred; s_cred[1] = ctx.codex->cred;
    s_hour = (uint32_t)(time(nullptr) / 3600);
}

void chTrendDraw(const ChannelCtx& ctx) {
    XP::window("Xu hướng", XPCore::ICON_CLAWD, true);
    Display::useFont("JBMono-11");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(LABEL, BODY);
    tft.drawString("7 ngày \xC2\xB7 % hạn mức tuần", Layout::XP_LEFT, 28);
    tft.drawRect(kFieldX, kFieldY, kFieldW, kFieldH, FIELD_BORDER);
    paintAll(ctx);
}

void chTrendTick(const ChannelCtx& ctx) {
    // Readings land every few minutes; re-derive once a minute and repaint
    // the chart only when today's total moved, a key changed or the hour rolled.
    static int s_min = -1;
    time_t now = time(nullptr);
    if (now / 60 == s_min) return;
    s_min = now / 60;
    Block b[2];
    int n = blocksFor(ctx, b);
    bool dirty = (uint32_t)(now / 3600) != s_hour;
    if (ctx.claude->cred != s_cred[0] || ctx.codex->cred != s_cred[1]) dirty = true;
    for (int i = 0; i < n && !dirty; i++) {
        History::Trend t = trendFor(*ctx.settings, b[i].metric);
        float today = t.have[6] ? t.burn[6] : -1.f;
        if (fabsf(today - s_today[i]) > 0.4f) dirty = true;
    }
    if (dirty) paintAll(ctx);
}
