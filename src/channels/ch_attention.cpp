// Attention — what agents (and the device) want the user to see now.
//
// Two channels share the queue in src/data/attention.{h,cpp}:
//
//   Attention  the interrupt card. Takes the screen when a card arrives (up to
//              30 s, or a legacy push's whole duration) and — with
//              pinApprovals — for as long as an agent is blocked on an
//              approval or a question. Several holders cycle every 6 s.
//
//      (layouts below, next to paintCard)
//
//   Agents     the queue as a list (status bar "Agents" / "3 ACTIVE"), in
//              rotation while there is anything in it.

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "layout.h"
#include "attention.h"
#include "timeutil.h"
#include "utf8.h"

using namespace Attention;

extern bool mainNightFace();
extern bool mainPinApprovals();
extern bool mainAgentNightShow();

uint16_t kindColor(Kind k) {
    switch (k) {
        case K_APPROVAL: return Theme::AMBER;
        case K_ERROR:    return Theme::CORAL;
        case K_INPUT:    return Theme::SKY;
        case K_PROGRESS: return Theme::LILAC;
        case K_WARNING:  return Theme::AMBER;
        case K_SUCCESS:  return Theme::MINT;
        default:         return Theme::INK;
    }
}

// At night (night face up) only these get through: anything urgent, a user's
// red card (as before), and — if the user chose so — agents waiting on them.
static bool allowedAtNight(const Item& it) {
    if (it.urgent) return true;
    if (it.kind == K_ERROR && it.agent == AGENT_OTHER && strncmp(it.id, "sys:", 4)) return true;
    return mainAgentNightShow() && waitsOnUser(it.kind);
}

// Slots that currently hold the screen, in display order.
static int holders(int out[kMax]) {
    const Queue& q = AttentionQueue::get();
    uint32_t now = AttentionQueue::now();
    int ord[kMax], n = ordered(q, ord, now), m = 0;
    bool night = mainNightFace();
    for (int i = 0; i < n; i++) {
        const Item& it = q.items[ord[i]];
        if (!holdsScreen(it, now, mainPinApprovals())) continue;
        if (night && !allowedAtNight(it)) continue;
        out[m++] = ord[i];
    }
    return m;
}

bool chAttentionEnabled(const ChannelCtx&) {
    int h[kMax];
    return holders(h) > 0;
}

// ── card ────────────────────────────────────────────────────────────────────
//
// Clawd (the Claude Code mascot) is the focal element — one expression and
// badge per kind — with the text in JetBrains Mono under it. Layout: see
// paintBody() below.

static char     s_shownId[24] = "";
static uint32_t s_shownRev = 0;
static uint32_t s_cycleMs = 0;
static int      s_cycleIdx = 0;
static int      s_lastDrain = -1;
static char     s_status[40] = "";

static const char* agentName2(Agent a) {
    return a == AGENT_CLAUDE ? "CLAUDE" : a == AGENT_CODEX ? "CODEX" : nullptr;
}

// Truncate with an ellipsis until it fits maxW (current font). Cuts whole
// UTF-8 characters — a half Vietnamese letter would draw as garbage.
static constexpr size_t kLine = 80;     // bytes; every line buffer holds kLine
static void fitLine(char* s, int maxW) {
    if (tft.textWidth(s) <= maxW) return;
    size_t n = strlen(s);
    while (n > 1) {
        n = Utf8::prevChar(s, n);
        s[n] = '\0';
        char t[kLine]; snprintf(t, sizeof(t), "%s...", s);
        if (tft.textWidth(t) <= maxW) { snprintf(s, kLine, "%s", t); return; }
    }
}

// The queue keeps the hook's English titles/bodies (the API and MCP return
// them to agents verbatim); the panel shows them in Vietnamese.
static const char* kindLabel(Kind k) {
    switch (k) {
        case K_APPROVAL: return "phê duyệt";
        case K_ERROR:    return "lỗi";
        case K_INPUT:    return "chờ bạn";
        case K_PROGRESS: return "tiến độ";
        case K_WARNING:  return "cảnh báo";
        case K_SUCCESS:  return "xong";
        default:         return "thông tin";
    }
}

static const char* titleText(const Item& it) {
    if (!it.title[0])                       return kindLabel(it.kind);
    if (!strcmp(it.title, "DONE"))          return "XONG";
    if (!strcmp(it.title, "APPROVAL NEEDED")) return "CẦN DUYỆT";
    if (!strcmp(it.title, "WAITING FOR YOU")) return "ĐANG CHỜ BẠN";
    return it.title;
}

// "Claude finished" → "Claude đã xong"; anything else as sent.
static const char* bodyText(const Item& it, char* buf, size_t n) {
    const char* f = strstr(it.body, " finished");
    if (f && !f[9] && f - it.body < 12) {
        snprintf(buf, n, "%.*s đã xong", (int)(f - it.body), it.body);
        return buf;
    }
    return it.body;
}

static void centerText(const char* font, const char* text, int y, uint16_t color, int maxW = 216,
                       int cx = SCREEN_W / 2) {
    Display::useFont(font);
    char buf[kLine]; Utf8::copy(buf, sizeof(buf), text);
    fitLine(buf, maxW);
    tft.setTextDatum(TC_DATUM);
    tft.setTextColor(color, Theme::BG);
    tft.drawString(buf, cx, y);
}

// "CLAUDE · glimmer", muted, centred at the top.
static void paintHeader(const Item& it) {
    char line[64];
    const char* a = agentName2(it.agent);
    if (a && it.project[0]) snprintf_P(line, sizeof(line), PSTR("%s \xC2\xB7 %s"), a, it.project);
    else if (a)             snprintf_P(line, sizeof(line), PSTR("%s"), a);
    else                    snprintf_P(line, sizeof(line), PSTR("%s"), it.project[0] ? it.project : "glimmer");
    centerText("JBMono-11", line, 30, Theme::MUTED);
}

// "Bash: pio run" → tool "Bash", detail "pio run"; "wants to use Bash" → "Bash".
static constexpr size_t kTool = 24, kDetail = 64;
static void toolAndDetail(const char* body, char tool[kTool], char detail[kDetail]) {
    tool[0] = detail[0] = '\0';
    const char* colon = strstr(body, ": ");
    if (colon && colon - body > 0 && colon - body < 20) {
        snprintf(tool, kTool, "%.*s", (int)(colon - body), body);
        Utf8::copy(detail, kDetail, colon + 2);
        return;
    }
    const char* use = strstr(body, "use ");
    if (use) { Utf8::copy(tool, kTool, use + 4); return; }
    Utf8::copy(detail, kDetail, body);
}

// ── card body: Clawd + state badge, then clean JetBrains Mono text ──
//
//   y 30        CLAUDE · glimmer                     JBMono-11 muted
//   y 62..112   Clawd 90×50 (+ 21×21 badge off the right shoulder)
//   y 130       Cần duyệt / Lượt bạn / Xong rồi! …   JBMono-16B, kind colour
//   y 156       [progress bar]  detail line           JBMono-11
//   …           chờ bạn · 2M                          JBMono-11 muted (waiting)
//   y 204       queue dots / time-left hairline
//
// Animated from tick(): waiting cards blink, progress cards walk; only the
// 90×50 Clawd box is repainted.

static constexpr int kClawdX = (SCREEN_W - 90) / 2, kClawdY = 62, kClawdS = 5;
static int      s_statusY = -1;          // where the waiting status line sits
static uint8_t  s_clawdFrame = 0xFF;     // last painted eyes | walking<<4

struct Look { uint8_t eyes; char badge; bool walk; bool sparkle; };

static Look lookFor(const Item& it) {
    switch (it.kind) {
        case K_APPROVAL: return {Display::CLAWD_WIDE,  '!', false, false};
        case K_INPUT:    return {Display::CLAWD_OPEN,  '.', false, false};
        case K_SUCCESS:  return {Display::CLAWD_HAPPY, 'v', false, true};
        case K_ERROR:    return {Display::CLAWD_SAD,   'x', false, false};
        case K_WARNING:  return {Display::CLAWD_WIDE,  '!', false, false};
        case K_PROGRESS: return {Display::CLAWD_OPEN,  0,   true,  false};
        default:         return {Display::CLAWD_OPEN,  0,   false, false};
    }
}

static uint16_t clawdColor(const Item& it) {
    return it.agent == AGENT_CODEX ? Theme::LILAC : Display::CLAWD_ORANGE;
}

// Eyes/legs for this instant: a 150 ms blink every 4 s while waiting on you,
// a step every 400 ms while working.
static uint8_t frameFor(const Item& it) {
    Look l = lookFor(it);
    uint8_t eyes = l.eyes;
    if (waitsOnUser(it.kind) && millis() % 4000 < 150) eyes = Display::CLAWD_SHUT;
    bool step = l.walk && (millis() / 400) % 2;
    return eyes | (step ? 0x10 : 0);
}

static void paintClawd(const Item& it) {
    uint8_t f = frameFor(it);
    if (f == s_clawdFrame) return;
    Display::drawClawd(kClawdX, kClawdY, kClawdS, clawdColor(it), f & 0x0F, f & 0x10);
    s_clawdFrame = f;
}

static void statusText(const Item& it, char* buf, size_t n) {
    uint32_t secs = AttentionQueue::now() - it.created;
    char d[16];
    if (secs < 60) snprintf_P(d, sizeof(d), PSTR("%lu giây"), (unsigned long)secs);
    else           TimeUtil::shortDuration((long)secs, d, sizeof(d));
    snprintf_P(buf, n, PSTR("chờ bạn \xC2\xB7 %s"), d);
}

static void paintStatus(const Item& it) {
    if (s_statusY < 0) return;
    char s[40]; statusText(it, s, sizeof(s));
    tft.fillRect(0, s_statusY, SCREEN_W, 14, Theme::BG);
    centerText("JBMono-11", s, s_statusY, Theme::MUTED);
    snprintf(s_status, sizeof(s_status), "%s", s);
}

static void paintDots(int n, uint16_t color) {
    if (n < 2) return;
    int x = SCREEN_W / 2 - (n * 10 - 4) / 2;
    for (int i = 0; i < n; i++) tft.fillRect(x + i * 10, 204, 6, 6, i == s_cycleIdx ? color : Theme::LINE);
}

// Hairline under result cards that shortens as the card's time runs out.
static void paintDrain(const Item& it) {
    if (!it.expires || it.expires <= it.created) return;
    uint32_t now = AttentionQueue::now();
    uint32_t total = it.expires - it.created, left = it.expires > now ? it.expires - now : 0;
    int w = (int)((uint64_t)60 * left / total);
    if (w == s_lastDrain) return;
    tft.drawFastHLine(90, 206, 60, Theme::LINE);
    if (w > 0) tft.drawFastHLine(90, 206, w, kindColor(it.kind));
    s_lastDrain = w;
}

// Title under Clawd: the hook's built-in titles become friendly Vietnamese;
// an agent's own title is kept as sent.
static void cardTitle(const Item& it, char* buf, size_t n) {
    const bool builtin = !it.title[0] || !strcmp(it.title, "APPROVAL NEEDED")
                      || !strcmp(it.title, "WAITING FOR YOU") || !strcmp(it.title, "DONE");
    if (it.kind == K_PROGRESS && it.progress >= 0) {
        if (builtin) snprintf_P(buf, n, PSTR("Đang chạy %d%%"), it.progress);
        else         snprintf_P(buf, n, PSTR("%s %d%%"), it.title, it.progress);
        return;
    }
    if (!builtin) { Utf8::copy(buf, n, it.title); return; }
    switch (it.kind) {
        case K_APPROVAL: Utf8::copy(buf, n, "Cần duyệt"); break;
        case K_INPUT:    Utf8::copy(buf, n, "Lượt bạn"); break;
        case K_SUCCESS:  Utf8::copy(buf, n, "Xong rồi!"); break;
        case K_ERROR:    Utf8::copy(buf, n, "Lỗi"); break;
        case K_WARNING:  Utf8::copy(buf, n, "Cảnh báo"); break;
        default:         Utf8::copy(buf, n, "Thông tin"); break;
    }
}

// One detail line: "Bash · pio run -e …" for approvals, else value · body.
static void cardDetail(const Item& it, char* buf, size_t n) {
    buf[0] = '\0';
    char bb[kLine]; const char* body = bodyText(it, bb, sizeof(bb));
    if (it.kind == K_APPROVAL) {
        char tool[kTool], detail[kDetail];
        toolAndDetail(it.body, tool, detail);
        if (tool[0] && detail[0]) snprintf_P(buf, n, PSTR("%s \xC2\xB7 %s"), tool, detail);
        else Utf8::copy(buf, n, tool[0] ? tool : detail);
        return;
    }
    if (it.value[0] && body[0]) snprintf_P(buf, n, PSTR("%s \xC2\xB7 %s"), it.value, body);
    else Utf8::copy(buf, n, it.value[0] ? it.value : body);
}

static void paintBody(const Item& it, int n) {
    const uint16_t kc = it.kind == K_INFO ? Theme::INK : kindColor(it.kind);
    const Look l = lookFor(it);
    s_clawdFrame = 0xFF;
    paintClawd(it);
    if (l.badge) Display::drawBadge(kClawdX + 90, kClawdY - 6, 3, l.badge, kc);
    if (l.sparkle) {
        Display::drawSparkle(kClawdX - 12, kClawdY + 4, kc);
        Display::drawSparkle(kClawdX + 90 + 14, kClawdY + 30, kc);
    }
    char title[kLine]; cardTitle(it, title, sizeof(title));
    centerText("JBMono-16B", title, 130, kc);
    int y = 156;
    if (it.kind == K_PROGRESS && it.progress >= 0) {
        tft.fillRect(40, y, 160, 6, Theme::PANEL);
        tft.fillRect(40, y, 160 * it.progress / 100, 6, kc);
        y += 16;
    }
    char detail[kLine]; cardDetail(it, detail, sizeof(detail));
    if (detail[0]) { centerText("JBMono-11", detail, y, Theme::INK_DIM); y += 18; }
    s_statusY = -1;
    if (waitsOnUser(it.kind)) { s_statusY = y + 6; paintStatus(it); }
    s_lastDrain = -1;
    if (n > 1) paintDots(n, kc);
    else if (!waitsOnUser(it.kind) && it.progress < 0) paintDrain(it);
}

static void paintCard(const Item& it, int n) {
    tft.fillRect(0, 0, SCREEN_W, Layout::CONTENT_BOTTOM, Theme::BG);
    paintHeader(it);
    paintBody(it, n);
    snprintf(s_shownId, sizeof(s_shownId), "%s", it.id);
}

static int pickHolder(int h[kMax], int n) {
    if (s_cycleIdx >= n) s_cycleIdx = 0;
    return h[s_cycleIdx];
}

void chAttentionDraw(const ChannelCtx&) {
    Display::clear();
    int h[kMax], n = holders(h);
    if (!n) return;
    s_cycleIdx = 0;                         // newest arrival: start from the top
    s_cycleMs = millis();
    paintCard(AttentionQueue::get().items[pickHolder(h, n)], n);
    s_shownRev = AttentionQueue::revision();
}

void chAttentionTick(const ChannelCtx&) {
    int h[kMax], n = holders(h);
    if (!n) return;
    bool repaint = AttentionQueue::revision() != s_shownRev;
    if (n > 1 && millis() - s_cycleMs >= 6000) {
        s_cycleIdx = (s_cycleIdx + 1) % n;
        s_cycleMs = millis();
        repaint = true;
    }
    const Item& it = AttentionQueue::get().items[pickHolder(h, n)];
    if (repaint || strcmp(it.id, s_shownId) != 0) {
        paintCard(it, n);
        s_shownRev = AttentionQueue::revision();
        return;
    }
    paintClawd(it);                          // blink / step, only when the frame changes
    if (waitsOnUser(it.kind)) {
        char s[40]; statusText(it, s, sizeof(s));
        if (strcmp(s, s_status)) paintStatus(it);
    } else if (n < 2 && it.progress < 0) {
        paintDrain(it);
    }
}

// ── Agents list ─────────────────────────────────────────────────────────────
//
//   status bar "Tác tử" · "3 MỤC"; dock at x 2..31 (painted by main.cpp)
//   ■ Cần bạn · Bash                  JBMono-11 ink   (■ x 40, text x 54)
//     claude · glimmer · 2p           JBMono-11 muted
//   ─────────────────────             hairline
//   (3 rows; a 4th+ becomes "+ N mục khác")

static uint32_t s_listRev = 0;
static uint32_t s_listMin = 0xFFFFFFFF;

bool chAgentsEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showAgents && !mainNightFace() && countVisible(AttentionQueue::get(), AttentionQueue::now()) > 0;
}

// Dock layout (P-2026-11-25.3 §15 "Agents-Dock"): kind square x 40, text
// x 54..228 (174 px), hairline x 40 w 188. The dock (x 2..31, y 34..183) is
// painted by main.cpp and the list never clears left of x 39.
static constexpr int kRowSqX = Layout::CONTENT_LEFT;                          // 40
static constexpr int kRowTextX = 54;
static constexpr int kRowTextW = Layout::CONTENT_RIGHT - kRowTextX;           // 174

static void listRow(const Item& it, int y, uint32_t now) {
    tft.fillRect(kRowSqX, y + 4, 6, 6, kindColor(it.kind));
    char line[kLine];
    if (waitsOnUser(it.kind)) {
        char tool[kTool], detail[kDetail];
        toolAndDetail(it.body, tool, detail);
        snprintf_P(line, sizeof(line), PSTR("%s%s%s"), it.kind == K_APPROVAL ? "Cần bạn" : "Lượt bạn",
                   tool[0] ? " \xC2\xB7 " : "", tool);
    } else {
        char t[48]; Utf8::copy(t, sizeof(t), titleText(it));
        // Sentence case reads calmer than shouty caps in a list.
        Utf8::sentence(t);
        if (it.progress >= 0)  snprintf_P(line, sizeof(line), PSTR("%s \xC2\xB7 %d%%"), t, it.progress);
        else if (it.value[0])  snprintf_P(line, sizeof(line), PSTR("%s \xC2\xB7 %s"), t, it.value);
        else                   snprintf_P(line, sizeof(line), PSTR("%s"), t);
    }
    Display::useFont("JBMono-11");
    fitLine(line, kRowTextW);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::INK, Theme::BG);
    tft.drawString(line, kRowTextX, y);

    char age[8]; TimeUtil::shortDuration((long)(now - it.created), age, sizeof(age));
    for (char* p = age; *p; p++) if (*p >= 'A' && *p <= 'Z') *p += 32;
    char meta[kLine];
    const char* a = it.agent == AGENT_CLAUDE ? "claude" : it.agent == AGENT_CODEX ? "codex" : nullptr;
    if (a && it.project[0]) snprintf_P(meta, sizeof(meta), PSTR("%s \xC2\xB7 %s \xC2\xB7 %s"), a, it.project, age);
    else if (a)             snprintf_P(meta, sizeof(meta), PSTR("%s \xC2\xB7 %s"), a, age);
    else if (it.project[0]) snprintf_P(meta, sizeof(meta), PSTR("%s \xC2\xB7 %s"), it.project, age);
    else                    snprintf_P(meta, sizeof(meta), PSTR("%s"), age);
    fitLine(meta, kRowTextW);
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString(meta, kRowTextX, y + 15);
}

// Design P-2026-11-25.4 §5 on the dock layout (§15 "Agents-Dock"): status
// bar "Tác tử" · meta "N MỤC", rows from y 32 every 60 px, "+ N mục khác"
// TC at (134, 152). Repaints only the content area right of the dock
// (x 39..239, y 24..219).
static void paintList(bool withMeta = true) {
    const Queue& q = AttentionQueue::get();
    uint32_t now = AttentionQueue::now();
    int ord[kMax], n = ordered(q, ord, now);
    if (withMeta) {
        char meta[16]; snprintf_P(meta, sizeof(meta), PSTR("%d MỤC"), n);
        Display::statusMeta(meta, Theme::MUTED);
    }
    tft.fillRect(Layout::CONTENT_LEFT - 1, Layout::CONTENT_TOP, SCREEN_W - (Layout::CONTENT_LEFT - 1),
                 Layout::CONTENT_BOTTOM - Layout::CONTENT_TOP, Theme::BG);
    int shown = n > 3 ? 2 : n;
    for (int i = 0; i < shown; i++) {
        int y = 32 + i * 60;
        listRow(q.items[ord[i]], y, now);
        if (i < n - 1) tft.drawFastHLine(kRowSqX, y + 44, Layout::CONTENT_W, Theme::LINE);
    }
    if (n > shown) {
        char more[32]; snprintf_P(more, sizeof(more), PSTR("+ %d mục khác"), n - shown);
        centerText("JBMono-11", more, 32 + shown * 60, Theme::MUTED, Layout::CONTENT_W, Layout::CONTENT_MID);
    }
    s_listRev = AttentionQueue::revision();
    s_listMin = now / 60;
}

void chAgentsDraw(const ChannelCtx&) {
    Display::clear();
    const Queue& q = AttentionQueue::get();
    int ord[kMax], n = ordered(q, ord, AttentionQueue::now());
    char meta[16]; snprintf_P(meta, sizeof(meta), PSTR("%d MỤC"), n);
    Display::statusBar("Tác tử", meta, Theme::MUTED);
    paintList(false);
}

void chAgentsTick(const ChannelCtx&) {
    if (AttentionQueue::revision() != s_listRev || AttentionQueue::now() / 60 != s_listMin) paintList();
}
