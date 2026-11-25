// Info channel — design-true from InfoScreen.
//
// Key-value rows with dotted-bottom dividers. All JBMono-11.

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "layout.h"
#include "utf8.h"
#include <ESP8266WiFi.h>

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

bool chInfoEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showInfo;
}

// Rows: y 30, step 19 — the last ("Lần tới") ends at y 214 (design P-2026-11-25.4 §13).
static constexpr int kY0 = 30, kStep = 19;

// Dock layout (design P-2026-11-25.3 §15 Info-Dock): labels TL x 40, values
// TR x 228, dividers x 40 w 188. Labels end by x 96 ("Cập nhật" 56 px), so a
// value repaints in the band x 100..229, y-1..y+14 (an accented capital
// draws 1 px above y; the dividers at y-4 / y+15 stay untouched).
static constexpr int kValX = 100;

static void infoRow(int y, const char* k, const String& v, uint16_t valColor,
                    bool divider = true) {
    tft.fillRect(kValX, y - 1, Layout::CONTENT_RIGHT + 2 - kValX, 15, Theme::BG);
    Display::useFont("JBMono-11");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString(k, Layout::CONTENT_LEFT, y);
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(valColor, Theme::BG);
    // Long values (an SSID can be 32 bytes) are cut on a character boundary
    // to stay inside the value band.
    const int maxW = Layout::CONTENT_RIGHT - kValX - 2;
    if (tft.textWidth(v) <= maxW) {
        tft.drawString(v, Layout::CONTENT_RIGHT, y);
    } else {
        char buf[48]; Utf8::copy(buf, sizeof(buf), v.c_str());
        size_t n = strlen(buf);
        while (n > 0 && tft.textWidth(buf) > maxW) { n = Utf8::prevChar(buf, n); buf[n] = '\0'; }
        tft.drawString(buf, Layout::CONTENT_RIGHT, y);
    }
    if (divider) Display::dotsDivider(Layout::CONTENT_LEFT, y + 15, Layout::CONTENT_W);
}

void chInfoDraw(const ChannelCtx& ctx) {
    Display::clear();
    Display::statusBar("Thông tin", "CHẨN ĐOÁN", Theme::MINT);

    int rssi = WiFi.RSSI();
    uint16_t sigCol = (rssi > -60) ? Theme::MINT
                    : (rssi > -75) ? Theme::AMBER : Theme::CORAL;

    int y = kY0, step = kStep;
    infoRow(y, "IP",       WiFi.localIP().toString(),              Theme::INK);          y += step;
    infoRow(y, "SSID",     WiFi.SSID(),                            Theme::INK);          y += step;
    infoRow(y, "Sóng",     String(rssi) + " dBm",                  sigCol);              y += step;
    infoRow(y, "Đã chạy",  String(ctx.now_ms / 60000UL) + "P",     Theme::INK_DIM);      y += step;
    infoRow(y, "Bộ nhớ",   String(ESP.getFreeHeap()/1024) + "K trống", Theme::AMBER);     y += step;
    infoRow(y, "Khối lớn", String(ESP.getMaxFreeBlockSize()/1024) + "K", Theme::INK_DIM); y += step;
    infoRow(y, "Firmware", "v" FW_VERSION,                          Theme::INK_DIM);      y += step;

    int en = mainEnabledCount(), tot = mainTotalCount();
    infoRow(y, "Kênh",     String(en) + " / " + String(tot),      Theme::INK_DIM);      y += step;
    uint32_t ago = (ctx.now_ms - mainLastRefreshMs()) / 60000UL;
    infoRow(y, "Cập nhật", String(ago) + "P trước",                     Theme::INK_DIM);      y += step;
    infoRow(y, "Lần tới",  "sau " + String(mainNextFetchInMs() / 60000UL) + "P", Theme::MINT, false);

    // Seed cache
    s_rssi      = rssi;
    s_upMin     = ctx.now_ms / 60000UL;
    s_heapKB    = ESP.getFreeHeap() / 1024;
    s_blkKB     = ESP.getMaxFreeBlockSize() / 1024;
    s_refreshAgo = ago;
    s_enabled   = en;
}

void chInfoTick(const ChannelCtx& ctx) {
    const int step = kStep;
    int rssi = WiFi.RSSI();
    int upMin = ctx.now_ms / 60000UL;
    int heapKB = ESP.getFreeHeap() / 1024;

    if (rssi != s_rssi) {
        uint16_t sigCol = (rssi > -60) ? Theme::MINT
                        : (rssi > -75) ? Theme::AMBER : Theme::CORAL;
        infoRow(kY0 + 2 * step, "Sóng", String(rssi) + " dBm", sigCol);
        s_rssi = rssi;
    }
    if (upMin != s_upMin) {
        infoRow(kY0 + 3 * step, "Đã chạy", String(upMin) + "P", Theme::INK_DIM);
        s_upMin = upMin;
    }
    if (heapKB != s_heapKB) {
        infoRow(kY0 + 4 * step, "Bộ nhớ", String(heapKB) + "K trống", Theme::AMBER);
        s_heapKB = heapKB;
    }
    int blkKB = ESP.getMaxFreeBlockSize() / 1024;
    if (blkKB != s_blkKB) {
        infoRow(kY0 + 5 * step, "Khối lớn", String(blkKB) + "K", Theme::INK_DIM);
        s_blkKB = blkKB;
    }
    int en = mainEnabledCount();
    if (en != s_enabled) {
        infoRow(kY0 + 7 * step, "Kênh", String(en) + " / " + String(mainTotalCount()), Theme::INK_DIM);
        s_enabled = en;
    }

    uint32_t ago = (ctx.now_ms - mainLastRefreshMs()) / 60000UL;
    int nextMin = (int)(mainNextFetchInMs() / 60000UL);
    if ((int)ago != s_refreshAgo || nextMin != s_nextMin) {
        infoRow(kY0 + 8 * step, "Cập nhật", String(ago) + "P trước", Theme::INK_DIM);
        infoRow(kY0 + 9 * step, "Lần tới", "sau " + String(nextMin) + "P", Theme::MINT, false);
        s_refreshAgo = ago;
        s_nextMin = nextMin;
    }
}
