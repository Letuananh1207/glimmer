// Info — XP window, design P-2026-11-26.8 §17 XP-Info: a white list box
// (10, 28) 220×180 (y 28..207, no status bar) split by a xpRowLine column
// rule at x 82; ten rows, y 31 + 17.5·i (31, 48, 66, 83 … 188):
//   label JBMono-11 muted TL (16, y) · value JBMono-11 black TL (88, y)
// tick() repaints a value in its band x 88..228, y-1..y+13 (white).

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "layout.h"
#include "utf8.h"
#include "xp.h"
#include <ESP8266WiFi.h>

namespace C = Theme::XP;

extern int      mainEnabledCount();
extern int      mainTotalCount();
extern uint32_t mainLastRefreshMs();
extern uint32_t mainNextFetchInMs();

// tick cache
static int    s_rssi    = 1;          // RSSI is negative; 1 = sentinel "unset"
static int    s_upMin   = -1;
static int    s_heapKB  = -1;
static int    s_blkKB   = -1;
static int    s_enabled = -1;
static int    s_refreshAgo = -1;
static int    s_nextMin = -1;

enum Row { R_IP, R_SSID, R_RSSI, R_UP, R_HEAP, R_BLK, R_FW, R_CH, R_UPD, R_NEXT, R_COUNT };
static const char* const kLabels[R_COUNT] = {
    "IP", "SSID", "Sóng", "Đã chạy", "Bộ nhớ", "Khối lớn", "Firmware", "Kênh", "Cập nhật", "Lần tới",
};

static constexpr int kBoxX = 10, kBoxY = 28, kBoxW = 220, kBoxH = 180;
static constexpr int kRuleX = 82, kLabelX = 16, kValX = 88;
static constexpr int kValRight = kBoxX + kBoxW - 2;   // 228, last white column

static inline int rowY(int i) { return 31 + (i * 35) / 2; }

bool chInfoEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showInfo;
}

// Value only; long values (an SSID can be 32 bytes) are cut on a character
// boundary to stay inside x 88..228.
static void paintValue(int i, const String& v) {
    const int y = rowY(i);
    tft.fillRect(kValX, y - 1, kValRight + 1 - kValX, 15, C::WHITE);
    Display::useFont("JBMono-11");
    char buf[48]; Utf8::copy(buf, sizeof(buf), v.c_str());
    XP::fitText(buf, kValRight - kValX);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(C::BLACK, C::WHITE);
    tft.drawString(buf, kValX, y);
}

static String rssiText(int rssi)  { return String(rssi) + " dBm"; }
static String agoText(uint32_t m) { return String(m) + "P trước"; }
static String nextText(int m)     { return "sau " + String(m) + "P"; }

void chInfoDraw(const ChannelCtx& ctx) {
    XP::window("Thông tin", XPCore::ICON_INFO, false);
    XP::field(kBoxX, kBoxY, kBoxW, kBoxH);
    tft.fillRect(kRuleX, kBoxY + 1, 1, kBoxH - 2, C::ROW_LINE);

    Display::useFont("JBMono-11");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(C::MUTED, C::WHITE);
    for (int i = 0; i < R_COUNT; i++) tft.drawString(kLabels[i], kLabelX, rowY(i));

    int rssi = WiFi.RSSI();
    int en = mainEnabledCount(), tot = mainTotalCount();
    uint32_t ago = (ctx.now_ms - mainLastRefreshMs()) / 60000UL;
    int nextMin = (int)(mainNextFetchInMs() / 60000UL);

    paintValue(R_IP,   WiFi.localIP().toString());
    paintValue(R_SSID, WiFi.SSID());
    paintValue(R_RSSI, rssiText(rssi));
    paintValue(R_UP,   String(ctx.now_ms / 60000UL) + "P");
    paintValue(R_HEAP, String(ESP.getFreeHeap() / 1024) + "K trống");
    paintValue(R_BLK,  String(ESP.getMaxFreeBlockSize() / 1024) + "K");
    paintValue(R_FW,   "v" FW_VERSION);
    paintValue(R_CH,   String(en) + " / " + String(tot));
    paintValue(R_UPD,  agoText(ago));
    paintValue(R_NEXT, nextText(nextMin));

    // Seed cache
    s_rssi       = rssi;
    s_upMin      = ctx.now_ms / 60000UL;
    s_heapKB     = ESP.getFreeHeap() / 1024;
    s_blkKB      = ESP.getMaxFreeBlockSize() / 1024;
    s_refreshAgo = ago;
    s_nextMin    = nextMin;
    s_enabled    = en;
}

void chInfoTick(const ChannelCtx& ctx) {
    int rssi = WiFi.RSSI();
    if (rssi != s_rssi) { paintValue(R_RSSI, rssiText(rssi)); s_rssi = rssi; }

    int upMin = ctx.now_ms / 60000UL;
    if (upMin != s_upMin) { paintValue(R_UP, String(upMin) + "P"); s_upMin = upMin; }

    int heapKB = ESP.getFreeHeap() / 1024;
    if (heapKB != s_heapKB) { paintValue(R_HEAP, String(heapKB) + "K trống"); s_heapKB = heapKB; }

    int blkKB = ESP.getMaxFreeBlockSize() / 1024;
    if (blkKB != s_blkKB) { paintValue(R_BLK, String(blkKB) + "K"); s_blkKB = blkKB; }

    int en = mainEnabledCount();
    if (en != s_enabled) {
        paintValue(R_CH, String(en) + " / " + String(mainTotalCount()));
        s_enabled = en;
    }

    int ago = (int)((ctx.now_ms - mainLastRefreshMs()) / 60000UL);
    if (ago != s_refreshAgo) { paintValue(R_UPD, agoText(ago)); s_refreshAgo = ago; }

    int nextMin = (int)(mainNextFetchInMs() / 60000UL);
    if (nextMin != s_nextMin) { paintValue(R_NEXT, nextText(nextMin)); s_nextMin = nextMin; }
}
