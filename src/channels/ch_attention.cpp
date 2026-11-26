// Attention — what agents (and the device) want the user to see now.
// XP look: P-2026-11-26.8, screen_specs §17 "Thẻ agent", XP-Attention(-Input,
// -Done, -Error, -Progress), XP-Agents(-Idle).
//
// Two channels share the queue in src/data/attention.{h,cpp}:
//
//   Attention  the interrupt card, an XP window named after the kind ("Cần
//              duyệt", "Lượt bạn", "Xong", "Lỗi", "Đang chạy"). Takes the
//              screen when a card arrives (up to 30 s, or a legacy push's whole
//              duration) and — with pinApprovals — for as long as an agent is
//              blocked on an approval or a question. Several holders cycle
//              every 6 s ("· 1/2" in the title). A card that needs the user
//              lights the taskbar's Claude button orange (chAttentionNeedsYou).
//
//   Agents     the queue as an XP list box (window "Tác tử", status bar
//              "3 mục" · "1 cần duyệt"), in rotation while it holds anything.

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "layout.h"
#include "attention.h"
#include "timeutil.h"
#include "utf8.h"
#include "xp_core.h"
#include "xp.h"
#include "control_core.h"

using namespace Attention;

extern bool mainNightFace();
extern bool mainPinApprovals();
extern bool mainAgentNightShow();

// Dark-theme kind colours (pre-XP API, kept for any outside caller).
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

// XP kind colours on the beige body (sources XP-Attention*, XP-Agents).
static uint16_t xpKindColor(Kind k) {
    switch (k) {
        case K_APPROVAL: return Theme::XP::AMBER;
        case K_ERROR:    return Theme::XP::RED;
        case K_INPUT:    return Theme::XP::SKY;
        case K_PROGRESS: return Theme::XP::LILAC;
        case K_WARNING:  return Theme::XP::AMBER;
        case K_SUCCESS:  return Theme::XP::GREEN;
        default:         return Theme::XP::BLACK;
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

// A card holding the screen that lights a panel the app turned off
// (Control::wakesScreen: urgent, approval / question, a user's error card).
bool chAttentionWakesScreen() {
    int h[kMax], n = holders(h);
    const Queue& q = AttentionQueue::get();
    for (int i = 0; i < n; i++)
        if (Control::wakesScreen(q.items[h[i]])) return true;
    return false;
}

// ── card ────────────────────────────────────────────────────────────────────

static char     s_shownId[24] = "";
static uint32_t s_shownRev = 0;
static uint32_t s_cycleMs = 0;
static int      s_cycleIdx = 0;
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

// Window title by kind (sources XP-Attention*: "Cần duyệt", "Lượt bạn",
// "Xong", "Lỗi", "Đang chạy").
static const char* windowTitle(Kind k) {
    switch (k) {
        case K_APPROVAL: return "Cần duyệt";
        case K_INPUT:    return "Lượt bạn";
        case K_SUCCESS:  return "Xong";
        case K_ERROR:    return "Lỗi";
        case K_PROGRESS: return "Đang chạy";
        case K_WARNING:  return "Cảnh báo";
        default:         return "Thông tin";
    }
}

static const char* agentTitle(Agent a) {
    return a == AGENT_CLAUDE ? "Claude" : a == AGENT_CODEX ? "Codex" : "Tác tử";
}

// "Claude finished" → "Claude đã xong"; a question's notification ("Claude is
// waiting for your input") → "Claude đang chờ câu trả lời"; else as sent.
static const char* bodyText(const Item& it, char* buf, size_t n) {
    const char* f = strstr(it.body, " finished");
    if (f && !f[9] && f - it.body < 12) {
        snprintf(buf, n, "%.*s đã xong", (int)(f - it.body), it.body);
        return buf;
    }
    if (it.kind == K_INPUT && (!it.body[0] || strstr(it.body, "waiting for your input"))) {
        snprintf(buf, n, "%s đang chờ câu trả lời", agentTitle(it.agent));
        return buf;
    }
    return it.body;
}

static void centerText(const char* font, const char* text, int y, uint16_t color, int maxW = 216,
                       int cx = Layout::XP_MID) {
    Display::useFont(font);
    char buf[kLine]; Utf8::copy(buf, sizeof(buf), text);
    fitLine(buf, maxW);
    tft.setTextDatum(TC_DATUM);
    tft.setTextColor(color, Theme::XP::BODY);
    tft.drawString(buf, cx, y);
}

// "CLAUDE · glimmer", xpLabel, TC (120, 30).
static void paintHeader(const Item& it) {
    char line[64];
    const char* a = agentName2(it.agent);
    if (a && it.project[0]) snprintf_P(line, sizeof(line), PSTR("%s \xC2\xB7 %s"), a, it.project);
    else if (a)             snprintf_P(line, sizeof(line), PSTR("%s"), a);
    else                    snprintf_P(line, sizeof(line), PSTR("%s"), it.project[0] ? it.project : "glimmer");
    centerText("JBMono-11", line, 30, Theme::XP::LABEL);
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

// ── card body (§17 "Thẻ agent") ──
//
//   y 30        CLAUDE · glimmer                      JBMono-11 xpLabel TC
//   y 50..109   Clawd, cells of 6 (108×60) at (66, 50)
//   y 120       Cần bạn duyệt / Lượt bạn / Xong rồi!   JBMono-16B kind colour TC
//   y 146       detail                                 JBMono-11 black TC
//   approval / input:  line (10, 168, 220) xpStatusLine + "chờ bạn · 2P" TC
//                      (120, 176) kind colour (ticks)
//   progress:          XP bar (30, 166, 180×14)
//
// Animated from tick(): waiting cards blink, progress cards walk; only the
// 108×60 Clawd box is repainted.

static constexpr int kClawdX = 66, kClawdY = 50, kClawdS = 6;
static constexpr int kTitleY = 120, kDetailY = 146, kRuleY = 168, kStatusY = 176;
static constexpr int kBarX = 30, kBarY = 166, kBarW = 180, kBarH = 14;
static uint8_t  s_clawdFrame = 0xFF;     // last painted eyes | walking<<4

static uint8_t eyesFor(Kind k) {
    switch (k) {
        case K_APPROVAL: return Display::CLAWD_WIDE;
        case K_SUCCESS:  return Display::CLAWD_HAPPY;
        case K_ERROR:    return Display::CLAWD_SAD;
        case K_WARNING:  return Display::CLAWD_WIDE;
        default:         return Display::CLAWD_OPEN;
    }
}

static uint16_t clawdColor(const Item& it) {
    return it.agent == AGENT_CODEX ? Theme::XP::LILAC : Display::CLAWD_ORANGE;
}

// Eyes/legs for this instant: a 150 ms blink every 4 s while waiting on you,
// a step every 400 ms while working.
static uint8_t frameFor(const Item& it) {
    uint8_t eyes = eyesFor(it.kind);
    if (waitsOnUser(it.kind) && millis() % 4000 < 150) eyes = Display::CLAWD_SHUT;
    bool step = it.kind == K_PROGRESS && (millis() / 400) % 2;
    return eyes | (step ? 0x10 : 0);
}

static void paintClawd(const Item& it) {
    uint8_t f = frameFor(it);
    if (f == s_clawdFrame) return;
    Display::drawClawd(kClawdX, kClawdY, kClawdS, clawdColor(it), f & 0x0F, f & 0x10, Theme::XP::BODY);
    s_clawdFrame = f;
}

// "chờ bạn · 45 giây" under a minute, then "chờ bạn · 2P".
static void statusText(const Item& it, char* buf, size_t n) {
    uint32_t secs = AttentionQueue::now() - it.created;
    char d[16];
    if (secs < 60) snprintf_P(d, sizeof(d), PSTR("%lu giây"), (unsigned long)secs);
    else           TimeUtil::shortDuration((long)secs, d, sizeof(d));
    snprintf_P(buf, n, PSTR("chờ bạn \xC2\xB7 %s"), d);
}

static void paintStatus(const Item& it) {
    char s[40]; statusText(it, s, sizeof(s));
    tft.fillRect(Layout::XP_LEFT, kStatusY - 1, Layout::XP_RIGHT + 1 - Layout::XP_LEFT, 15, Theme::XP::BODY);
    centerText("JBMono-11", s, kStatusY, xpKindColor(it.kind));
    snprintf(s_status, sizeof(s_status), "%s", s);
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
        case K_APPROVAL: Utf8::copy(buf, n, "Cần bạn duyệt"); break;
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

// Whole window: a different card (or the queue changed) is a new window.
// Several holders: "· 1/2" after the title (theo XP thật: the window says
// which of several it is; there are no dots in XP).
static void paintCard(const Item& it, int n) {
    XP::window(windowTitle(it.kind), XPCore::ICON_CLAWD, false);
    if (n > 1) {
        char m[8]; snprintf_P(m, sizeof(m), PSTR("%d/%d"), s_cycleIdx + 1, n);
        XP::titleMeta(m);
    }
    paintHeader(it);
    s_clawdFrame = 0xFF;
    paintClawd(it);
    char title[kLine]; cardTitle(it, title, sizeof(title));
    centerText("JBMono-16B", title, kTitleY, xpKindColor(it.kind));
    char detail[kLine]; cardDetail(it, detail, sizeof(detail));
    if (detail[0]) centerText("JBMono-11", detail, kDetailY, Theme::XP::BLACK);
    if (waitsOnUser(it.kind)) {
        tft.drawFastHLine(Layout::XP_LEFT, kRuleY, Layout::XP_RIGHT + 1 - Layout::XP_LEFT, Theme::XP::STATUS_LINE);
        paintStatus(it);
    } else if (it.kind == K_PROGRESS && it.progress >= 0) {
        XP::progress(kBarX, kBarY, kBarW, kBarH, (float)it.progress);
    }
    snprintf(s_shownId, sizeof(s_shownId), "%s", it.id);
}

static int pickHolder(int h[kMax], int n) {
    if (s_cycleIdx >= n) s_cycleIdx = 0;
    return h[s_cycleIdx];
}

void chAttentionDraw(const ChannelCtx&) {
    int h[kMax], n = holders(h);
    if (!n) { XP::window("Tác tử", XPCore::ICON_CLAWD, false); return; }
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
    }
}

// XP taskbar (P-2026-11-26.8): the Claude button lights orange while the card
// on screen needs the user (approval / question / error) — main.cpp asks.
bool chAttentionNeedsYou() {
    const Queue& q = AttentionQueue::get();
    for (int i = 0; i < kMax; i++)
        if (q.items[i].used && !strcmp(q.items[i].id, s_shownId)) return XPCore::flashes(q.items[i].kind);
    return false;
}

// ── Agents list (XP-Agents, XP-Agents-Idle) ─────────────────────────────────
//
//   list box (10, 28, 220×162) — white, xpFieldBorder
//   rows every 52 px from y 30 (x 11..228, 50 tall):
//     ■ 8×8 kind colour at (18, y+9)
//     title JBMono-12B black TL (32, y+6)     "Cần bạn · Bash", "Tests · 64%"
//     meta  JBMono-11 xpMuted TL (32, y+26)   "claude · glimmer · 2p"
//   the first row is selected (xpSelect, white text) when it waits on you;
//   xpRowLine at y+50 under rows 1–2 unless selected
//   > 3 items: 2 rows + "+ N mục khác" in the third
//   status bar: "3 mục" · "1 cần duyệt" / "không mục nào chờ"

static uint32_t s_listRev = 0;
static uint32_t s_listMin = 0xFFFFFFFF;

static constexpr int kListX = 10, kListY = 28, kListW = 220, kListH = 162;
static constexpr int kRowX = kListX + 1, kRowW = kListW - 2, kRow0 = 30, kRowPitch = 52, kRowH = 50;
static constexpr int kSqX = 18, kTextX = 32;
static constexpr int kTextW = kRowX + kRowW - 4 - kTextX;    // 192

bool chAgentsEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showAgents && !mainNightFace() && countVisible(AttentionQueue::get(), AttentionQueue::now()) > 0;
}

static void listRow(const Item& it, int y, uint32_t now, bool selected) {
    const uint16_t bg = selected ? Theme::XP::SELECT : Theme::XP::WHITE;
    if (selected) tft.fillRect(kRowX, y, kRowW, kRowH, bg);
    tft.fillRect(kSqX, y + 9, 8, 8, xpKindColor(it.kind));
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
    Display::useFont("JBMono-12B");
    fitLine(line, kTextW);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(selected ? Theme::XP::WHITE : Theme::XP::BLACK, bg);
    tft.drawString(line, kTextX, y + 6);

    char age[8]; TimeUtil::shortDuration((long)(now - it.created), age, sizeof(age));
    for (char* p = age; *p; p++) if (*p >= 'A' && *p <= 'Z') *p += 32;
    char meta[kLine];
    const char* a = it.agent == AGENT_CLAUDE ? "claude" : it.agent == AGENT_CODEX ? "codex" : nullptr;
    if (a && it.project[0]) snprintf_P(meta, sizeof(meta), PSTR("%s \xC2\xB7 %s \xC2\xB7 %s"), a, it.project, age);
    else if (a)             snprintf_P(meta, sizeof(meta), PSTR("%s \xC2\xB7 %s"), a, age);
    else if (it.project[0]) snprintf_P(meta, sizeof(meta), PSTR("%s \xC2\xB7 %s"), it.project, age);
    else                    snprintf_P(meta, sizeof(meta), PSTR("%s"), age);
    Display::useFont("JBMono-11");
    fitLine(meta, kTextW);
    tft.setTextColor(selected ? Theme::XP::WHITE : Theme::XP::MUTED, bg);
    tft.drawString(meta, kTextX, y + 26);
}

// Repaints the list box and the status bar (both inside the window body).
static void paintList() {
    const Queue& q = AttentionQueue::get();
    uint32_t now = AttentionQueue::now();
    int ord[kMax], n = ordered(q, ord, now);

    XP::field(kListX, kListY, kListW, kListH);
    const int shown = n > 3 ? 2 : n;
    int approvals = 0, inputs = 0;
    for (int i = 0; i < n; i++) {
        const Kind k = q.items[ord[i]].kind;
        approvals += k == K_APPROVAL;
        inputs += k == K_INPUT;
    }
    for (int i = 0; i < shown; i++) {
        const int y = kRow0 + i * kRowPitch;
        const Item& it = q.items[ord[i]];
        const bool sel = i == 0 && waitsOnUser(it.kind);
        listRow(it, y, now, sel);
        if (i < 2 && !sel) tft.drawFastHLine(kRowX, y + kRowH, kRowW, Theme::XP::ROW_LINE);
    }
    if (n > shown) {
        char more[32]; snprintf_P(more, sizeof(more), PSTR("+ %d mục khác"), n - shown);
        Display::useFont("JBMono-11");
        tft.setTextDatum(TL_DATUM);
        tft.setTextColor(Theme::XP::MUTED, Theme::XP::WHITE);
        tft.drawString(more, kTextX, kRow0 + shown * kRowPitch + 18);
    }

    char left[16]; snprintf_P(left, sizeof(left), PSTR("%d mục"), n);
    char right[24];
    if (approvals)   snprintf_P(right, sizeof(right), PSTR("%d cần duyệt"), approvals);
    else if (inputs) snprintf_P(right, sizeof(right), PSTR("%d lượt bạn"), inputs);
    else             snprintf_P(right, sizeof(right), PSTR("không mục nào chờ"));
    XP::statusBar(left, right);

    s_listRev = AttentionQueue::revision();
    s_listMin = now / 60;
}

void chAgentsDraw(const ChannelCtx&) {
    XP::window("Tác tử", XPCore::ICON_CLAWD, true);
    paintList();
}

void chAgentsTick(const ChannelCtx&) {
    if (AttentionQueue::revision() != s_listRev || AttentionQueue::now() / 60 != s_listMin) paintList();
}
