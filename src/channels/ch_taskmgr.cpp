// TaskMgr — XP "Windows Task Manager" (P-2026-11-28.28, screen_specs §17 XP-TaskMgr, sources
// XP-TaskMgr-Apps|Hover|Empty|Perf|Net.dc.html). A system program: no skill, no desktop icon; the app
// opens it (Ctrl+Alt+Del) and sends the tab / the selected row (POST /api/taskmgr, main.cpp keeps it).
// "Kết thúc tác vụ" is the app sending the new window list (POST /api/windows).
//
//   window      "Trình quản lý tác vụ", icon 16 (green graph), no menu bar
//   tabs        Ứng dụng (6, w 66) · Hiệu năng (72, w 73) · Mạng (145, w 38); page (6, 41, 228×152)
//   Ứng dụng    ListView (10, 46, 220×112): header Tác vụ | Trạng thái, rows of 18 from y 64 = the open
//               windows but this one, in opening order; buttons Kết thúc tác vụ (26, 165, 117×21),
//               Chuyển tới (147, 165, 82×21) — dim with no row, hot under the mouse (device-computed)
//   Hiệu năng   CPU / Bộ nhớ gauges (14, 56 / 110, 44×36), histories (70, 56 / 110, 156×36),
//               Bộ nhớ (KB) Còn trống / Khối lớn, Đã chạy
//   Mạng        Wi-Fi · Đã kết nối, graph (40, 61, 190×72) of the signal %, ListView Mạng | Tín hiệu | IP
//   status bar  3 sunken cells: Tác vụ: N · CPU: x% · Trống: yK
//
// tick(): once a second (a new sample) the graphs / gauges / values of the tab on screen and the status
// cells that changed; the window list changing repaints the list + buttons. Repaint-safe: draw() only
// paints from the samples (main.cpp keeps them) and guards each block with clipHits.

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "layout.h"
#include "utf8.h"
#include "xp.h"
#include "xp_core.h"
#include "control_core.h"
#include "perf_core.h"
#include "start_icons.h"
#include "mines_icons.h"
#include <ESP8266WiFi.h>

namespace C = Theme::XP;

extern const Control::Windows& mainWindows();
extern const Perf::History& mainPerf();
extern uint32_t mainPerfSeq();          // +1 per sample (once a second)
extern uint32_t mainHeapTotal();        // free heap at boot = the heap's size

extern const Perf::View& mainTaskMgrView();

static constexpr uint16_t kBlack = 0x0000, kGreen = 0x07E0, kGreenOff = 0x03E0, kGrid = 0x0408;   // #00FF00 #007F00 #008040
static constexpr uint16_t kHeadRule = 0xD69A;                                                     // #D0D0BF

enum : uint8_t { TAB_APPS, TAB_PERF, TAB_NET };
static uint8_t  s_tab = TAB_APPS;
static uint32_t s_seq = 0;              // the sample on screen
static uint32_t s_winSig = 0;           // the window list on screen
static int8_t   s_hot = -1;             // 0 Kết thúc tác vụ, 1 Chuyển tới (mouse over it)
static char     s_cell[3][16];          // status cells on screen
static int      s_upMin = -1;           // Đã chạy on screen, in minutes

// ── helpers ──

static void textP(PGM_P s, int x, int y, uint16_t fg, uint16_t bg, uint8_t datum = TL_DATUM) {
    char b[40]; strncpy_P(b, s, sizeof(b)); b[sizeof(b) - 1] = 0;
    tft.setTextDatum(datum);
    tft.setTextColor(fg, bg);
    tft.drawString(b, x, y);
}
static void text(const char* s, int x, int y, uint16_t fg, uint16_t bg, uint8_t datum = TL_DATUM) {
    tft.setTextDatum(datum);
    tft.setTextColor(fg, bg);
    tft.drawString(s, x, y);
}

// The programs listed: open windows but this one, in opening order.
static int rowsOf(int8_t* out) {
    const Control::Windows& w = mainWindows();
    int n = 0;
    for (int i = 0; i < w.n && n < 6; i++)
        if (w.open[i] != XPCore::PROG_TASKMGR) out[n++] = w.open[i];
    return n;
}
static uint32_t windowsSig() {
    const Control::Windows& w = mainWindows();
    uint32_t h = 2166136261u;
    for (int i = 0; i < w.n; i++) h = (h ^ (uint8_t)w.open[i]) * 16777619u;
    return h ^ ((uint32_t)(uint8_t)mainTaskMgrView().sel << 24);
}

// 16-px program icon in a ListView row (y = row top, 18 tall): the Start menu's icons.
template <typename Run>
static void runs(const Run* r, int n, const uint16_t* pal, int x0, int y0) {
    for (int k = 0; k < n; k++) {
        Run q; memcpy_P(&q, &r[k], sizeof(q));
        tft.fillRect(x0 + q.x, y0 + q.y, q.w, 1, pgm_read_word(&pal[q.c]));
    }
}
#define ICON(NS, N, X, Y) runs(NS::k##N##Runs, NS::k##N##RunCount, NS::k##N##Pal, (X), (Y) + (18 - NS::k##N##H) / 2)

void chTaskMgrRowIcon(int p, int x, int y) {
    switch (p) {
        case XPCore::PROG_CLAUDE:   ICON(StartIcons, SmallClawd, x, y); break;
        case XPCore::PROG_CODEX:    ICON(StartIcons, SmallCodex, x, y); break;
        case XPCore::PROG_AI:       ICON(MinesIcons, StartAi, x, y); break;
        case XPCore::PROG_TREND:    ICON(MinesIcons, StartTrend, x, y); break;
        case XPCore::PROG_AGENTS:   ICON(MinesIcons, StartAgents, x, y); break;
        case XPCore::PROG_PHOTO:    ICON(StartIcons, Photo, x, y); break;
        case XPCore::PROG_WEATHER:
        case XPCore::PROG_FORECAST: ICON(StartIcons, Weather, x, y); break;
        case XPCore::PROG_CLOCK:    ICON(StartIcons, Clock, x, y); break;
        case XPCore::PROG_MINES:    ICON(MinesIcons, StartMines, x, y); break;
        default: {
            const XPCore::Icon ic = XPCore::progIcon(p);
            if (XPCore::colorIcon(ic)) XP::drawColorIcon(ic, x, y + 1);
            else if (ic == XPCore::ICON_INFO) XP::drawIcon(ic, x + 5, y + 4, 1, C::ICON_INFO);
        }
    }
}

// A white ListView frame with its header row (XP Details view): (x, y, w, h), columns at [cols].
static void listHeader(int x, int y, int w, int h) {
    tft.drawRect(x, y, w, h, C::FIELD_BORDER);
    tft.fillRect(x + 1, y + 1, w - 2, h - 2, C::WHITE);
    tft.fillRect(x + 1, y + 1, w - 2, 15, C::BODY);
    tft.drawFastHLine(x + 1, y + 16, w - 2, kHeadRule);
    tft.drawFastHLine(x + 1, y + 17, w - 2, C::DIM);
}

// Flash literals → a stack copy for the helpers that take RAM strings.
struct P { char b[40]; explicit P(PGM_P s) { strncpy_P(b, s, sizeof(b)); b[sizeof(b) - 1] = 0; } };
#define F_(s) (P(PSTR(s)).b)

// ── Ứng dụng ──

static void paintButtons(bool any) {
    XP::pushButton(26, 165, 117, 21, F_("Kết thúc tác vụ"),
                   !any ? XP::BTN_DIM : s_hot == 0 ? XP::BTN_HOT : XP::BTN_UP);
    XP::pushButton(147, 165, 82, 21, F_("Chuyển tới"),
                   !any ? XP::BTN_DIM : s_hot == 1 ? XP::BTN_HOT : XP::BTN_UP);
}

static void paintApps() {
    int8_t rows[6];
    const int n = rowsOf(rows);
    const int sel = mainTaskMgrView().sel;
    Display::useFont("JBMono-11");
    if (Display::clipHits(10, 46, 220, 112)) {
        listHeader(10, 46, 220, 112);
        tft.fillRect(150, 50, 1, 10, C::DIM);
        textP(PSTR("Tác vụ"), 16, 48, C::BLACK, C::BODY);
        textP(PSTR("Trạng thái"), 156, 48, C::BLACK, C::BODY);
        for (int i = 0; i < n && i < 5; i++) {
            const int y = 64 + 18 * i;
            if (!Display::clipHits(11, y, 218, 18)) continue;
            const bool lit = i == sel;
            const uint16_t bg = lit ? C::SELECT : C::WHITE, fg = lit ? C::WHITE : C::BLACK;
            if (lit) tft.fillRect(11, y, 218, 18, C::SELECT);
            chTaskMgrRowIcon(rows[i], 14, y);
            char name[32];
            Utf8::copy(name, sizeof(name), XPCore::frameOf(XPCore::progName(rows[i])).title);
            Display::useFont("JBMono-11");
            XP::fitText(name, 118);
            text(name, 34, y + 2, fg, bg);
            textP(PSTR("Đang chạy"), 156, y + 2, fg, bg);
        }
    }
    paintButtons(n > 0);
}

// ── Hiệu năng / Mạng: the graphs ──

static void gauge(int x, int y, uint8_t pct, const char* label) {
    if (!Display::clipHits(x, y, 44, 36)) return;
    tft.fillRect(x, y, 44, 36, kBlack);
    const int lit = Perf::ledsLit(pct);
    for (int i = 0; i < Perf::kLeds; i++) {           // i 0 = top step
        const uint16_t c = Perf::kLeds - i <= lit ? kGreen : kGreenOff;
        tft.fillRect(x + 15, y + 3 + 3 * i, 6, 2, c);
        tft.fillRect(x + 23, y + 3 + 3 * i, 6, 2, c);
    }
    Display::useFont("JBMono-11");
    text(label, x + 22, y + 23, kGreen, kBlack, TC_DATUM);
}

template <int N>
static void graph(int x, int y, int w, int h, const Perf::Ring<N>& r) {
    if (!Display::clipHits(x, y, w, h)) return;
    tft.fillRect(x, y, w, h, kBlack);
    for (int gx = x + 11; gx < x + w; gx += 12) tft.drawFastVLine(gx, y, h, kGrid);
    for (int gy = y + 11; gy < y + h; gy += 12) tft.drawFastHLine(x, gy, w, kGrid);
    int px = -1, py = -1;
    for (int i = 0; i < r.n; i++) {
        const int qx = Perf::pointX(x + w - 1, r.n, i), qy = Perf::pointY(y, h, r.at(i));
        if (px >= 0) tft.drawLine(px, py, qx, qy, kGreen);
        else tft.drawPixel(qx, qy, kGreen);
        px = qx; py = qy;
    }
}

static uint8_t lastOf(const Perf::Ring<Perf::kCpuN>& r) { return r.n ? r.at(r.n - 1) : 0; }

static void paintPerfValues() {
    const Perf::History& h = mainPerf();
    char b[16];
    snprintf_P(b, sizeof(b), PSTR("%u %%"), lastOf(h.cpu));
    gauge(14, 56, lastOf(h.cpu), b);
    const uint32_t total = mainHeapTotal(), fr = ESP.getFreeHeap();
    snprintf_P(b, sizeof(b), PSTR("%luK"), (unsigned long)((total > fr ? total - fr : 0) / 1024));
    gauge(14, 110, Perf::memPct(fr, total), b);
    graph(70, 56, 156, 36, h.cpu);
    graph(70, 110, 156, 36, h.mem);
    if (Display::clipHits(80, 162, 58, 28)) {
        Display::useFont("JBMono-11");
        tft.fillRect(80, 162, 57, 28, C::WHITE);
        snprintf_P(b, sizeof(b), PSTR("%lu"), (unsigned long)fr);
        text(b, 136, 162, C::BLACK, C::WHITE, TR_DATUM);
        snprintf_P(b, sizeof(b), PSTR("%lu"), (unsigned long)ESP.getMaxFreeBlockSize());
        text(b, 136, 176, C::BLACK, C::WHITE, TR_DATUM);
    }
}

static void paintUptime() {
    const uint32_t min = millis() / 60000UL;
    s_upMin = (int)min;
    if (!Display::clipHits(145, 166, 84, 20)) return;
    char b[20];
    Perf::uptime(min, b, sizeof(b));
    Display::useFont("JBMono-11");
    tft.fillRect(145, 166, 84, 20, C::WHITE);
    text(b, 187, 170, C::BLACK, C::WHITE, TC_DATUM);
}

static void paintPerf() {
    Display::useFont("JBMono-11");
    XP::groupBox(10, 50, 52, 46, F_("CPU"), C::WHITE);
    XP::groupBox(66, 50, 164, 46, F_("Lịch sử dùng CPU"), C::WHITE);
    XP::groupBox(10, 104, 52, 46, F_("Bộ nhớ"), C::WHITE);
    XP::groupBox(66, 104, 164, 46, F_("Lịch sử bộ nhớ"), C::WHITE);
    XP::groupBox(10, 158, 130, 34, F_("Bộ nhớ (KB)"), C::WHITE);
    XP::groupBox(144, 158, 86, 34, F_("Đã chạy"), C::WHITE);
    if (Display::clipHits(14, 162, 66, 28)) {
        Display::useFont("JBMono-11");
        textP(PSTR("Còn trống"), 14, 162, C::BLACK, C::WHITE);
        textP(PSTR("Khối lớn"), 14, 176, C::BLACK, C::WHITE);
    }
    paintPerfValues();
    paintUptime();
}

static void paintNetValues() {
    graph(40, 61, 190, 72, mainPerf().net);
    if (!Display::clipHits(11, 158, 218, 19)) return;
    Display::useFont("JBMono-11");
    tft.fillRect(11, 158, 218, 19, C::WHITE);
    const bool up = WiFi.status() == WL_CONNECTED;
    if (!up) return;
    char ssid[40];
    Utf8::copy(ssid, sizeof(ssid), WiFi.SSID().c_str());
    XP::fitText(ssid, 56);
    text(ssid, 15, 160, C::BLACK, C::WHITE);
    char b[20];
    snprintf_P(b, sizeof(b), PSTR("%d dBm"), (int)WiFi.RSSI());
    text(b, 80, 160, C::BLACK, C::WHITE);
    text(WiFi.localIP().toString().c_str(), 145, 160, C::BLACK, C::WHITE);
}

static void paintNet() {
    Display::useFont("JBMono-11");
    if (Display::clipHits(10, 45, 220, 15)) {
        const bool up = WiFi.status() == WL_CONNECTED;
        tft.fillRect(10, 45, 220, 15, C::WHITE);
        textP(up ? PSTR("Wi-Fi \xC2\xB7 Đã kết nối") : PSTR("Wi-Fi \xC2\xB7 Mất kết nối"), 10, 46, C::GROUP_LABEL, C::WHITE);
    }
    if (Display::clipHits(8, 60, 32, 76)) {
        textP(PSTR("100%"), 38, 62, C::LABEL, C::WHITE, TR_DATUM);
        textP(PSTR("0%"), 38, 120, C::LABEL, C::WHITE, TR_DATUM);
    }
    if (Display::clipHits(10, 140, 220, 38)) {
        listHeader(10, 140, 220, 38);
        tft.fillRect(75, 144, 1, 10, C::DIM);
        tft.fillRect(140, 144, 1, 10, C::DIM);
        textP(PSTR("Mạng"), 15, 142, C::BLACK, C::BODY);
        textP(PSTR("Tín hiệu"), 80, 142, C::BLACK, C::BODY);
        textP(PSTR("IP"), 145, 142, C::BLACK, C::BODY);
    }
    paintNetValues();
}

// ── status bar: 3 sunken cells ──

static void cellText(int i, char* out, size_t n) {
    int8_t rows[6];
    const Perf::History& h = mainPerf();
    switch (i) {
        case 0:  snprintf_P(out, n, PSTR("Tác vụ: %d"), rowsOf(rows)); break;
        case 1:  snprintf_P(out, n, PSTR("CPU: %u%%"), lastOf(h.cpu)); break;
        default: snprintf_P(out, n, PSTR("Trống: %luK"), (unsigned long)((ESP.getFreeHeap() + 512) / 1024)); break;
    }
}
static const uint8_t kCellX[3] = {3, 80, 150}, kCellW[3] = {76, 69, 87};

static void paintCell(int i, bool force) {
    char t[16];
    cellText(i, t, sizeof(t));
    if (!force && !strcmp(t, s_cell[i])) return;
    if (!Display::repainting()) strcpy(s_cell[i], t);
    const int x = kCellX[i], w = kCellW[i];
    if (!Display::clipHits(x, 199, w, 13)) return;
    tft.fillRect(x, 199, w - 1, 1, C::DIM);
    tft.fillRect(x, 199, 1, 13, C::DIM);
    tft.fillRect(x, 211, w - 1, 1, C::WHITE);
    tft.fillRect(x + w - 2, 199, 1, 13, C::WHITE);
    tft.fillRect(x + 1, 200, w - 3, 11, C::BODY);
    Display::useFont("JBMono-11");
    text(t, x + 4, 199, C::BLACK, C::BODY);
}

static void statusBar() {
    if (Display::clipHits(2, 196, 236, 18)) {
        tft.fillRect(2, 196, 236, 18, C::BODY);
        tft.drawFastHLine(2, 196, 236, C::DIM);
    }
    for (int i = 0; i < 3; i++) paintCell(i, true);
}

// ── channel ──

static const char kTab0[] PROGMEM = "Ứng dụng";
static const char kTab1[] PROGMEM = "Hiệu năng";
static const char kTab2[] PROGMEM = "Mạng";

bool chTaskMgrEnabled(const ChannelCtx&) { return true; }

void chTaskMgrDraw(const ChannelCtx&) {
    s_tab = mainTaskMgrView().tab > TAB_NET ? TAB_APPS : mainTaskMgrView().tab;
    XP::window(F_("Trình quản lý tác vụ"), XPCore::ICON_TASKMGR, false);
    char t0[16], t1[16], t2[16];
    strncpy_P(t0, kTab0, sizeof(t0)); strncpy_P(t1, kTab1, sizeof(t1)); strncpy_P(t2, kTab2, sizeof(t2));
    const char* labels[3] = {t0, t1, t2};
    XP::tabs(labels, 3, s_tab, 152, 10);
    switch (s_tab) {
        case TAB_PERF: paintPerf(); break;
        case TAB_NET:  paintNet(); break;
        default:       paintApps(); break;
    }
    statusBar();
    if (!Display::repainting()) { s_seq = mainPerfSeq(); s_winSig = windowsSig(); }
}

void chTaskMgrTick(const ChannelCtx&) {
    const uint32_t sig = windowsSig();
    if (sig != s_winSig) {
        s_winSig = sig;
        if (s_tab == TAB_APPS) paintApps();
        paintCell(0, false);
    }
    const uint32_t seq = mainPerfSeq();
    if (seq == s_seq) return;
    s_seq = seq;
    if (s_tab == TAB_PERF) {
        paintPerfValues();
        if ((int)(millis() / 60000UL) != s_upMin) paintUptime();
    } else if (s_tab == TAB_NET) {
        paintNetValues();
    }
    paintCell(1, false);
    paintCell(2, false);
}

// The mouse over a button (Ứng dụng tab, a row to act on): XP's hot ring; only that button repaints.
// x < 0 = no cursor. Returns true when something repainted.
bool chTaskMgrPointer(int x, int y) {
    int8_t hot = -1;
    int8_t rows[6];
    if (x >= 0 && s_tab == TAB_APPS && rowsOf(rows) > 0 && y >= 165 && y < 186) {
        if (x >= 26 && x < 143) hot = 0;
        else if (x >= 147 && x < 229) hot = 1;
    }
    if (hot == s_hot) return false;
    s_hot = hot;
    paintButtons(true);
    return true;
}
