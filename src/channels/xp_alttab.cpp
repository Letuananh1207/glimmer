#include "xp_alttab.h"
#include "xp.h"
#include "display.h"
#include "theme.h"
#include "start_icons.h"
#include "desk_icons.h"
#include "mines_icons.h"
#include "weather.h"
#include "utf8.h"

extern const Control::Windows& mainWindows();

namespace {
using namespace Theme::XP;
constexpr uint16_t kEdge = 0x092D, kFill = 0xD73F;     // #0A246A #D3E5FA (the Start menu's)

template <typename Run>
void runs(const Run* r, int n, const uint16_t* pal, int x0, int y0, int scale) {
    for (int k = 0; k < n; k++) {
        Run q; memcpy_P(&q, &r[k], sizeof(q));
        tft.fillRect(x0 + q.x * scale, y0 + q.y * scale, q.w * scale, scale, pgm_read_word(&pal[q.c]));
    }
}
#define ICON(NS, N, X, Y, S) runs(NS::k##N##Runs, NS::k##N##RunCount, NS::k##N##Pal, (X), (Y), (S))

// The 32-px icon of program [p], centred in the 40×36 cell at (x, y).
void icon(int p, int x, int y) {
    switch (p) {
        case XPCore::PROG_CLAUDE: case XPCore::PROG_AI: case XPCore::PROG_TREND: case XPCore::PROG_AGENTS:
            ICON(StartIcons, PinClawd, x + 2, y + 8, 1); break;
        case XPCore::PROG_CODEX: ICON(DeskIcons, Codex, x + 4, y + 6, 1); break;
        case XPCore::PROG_PHOTO: ICON(DeskIcons, Photo, x + 4, y + 6, 1); break;
        case XPCore::PROG_MINES: ICON(MinesIcons, DeskMines, x + 4, y + 6, 1); break;
        case XPCore::PROG_WEATHER: case XPCore::PROG_FORECAST:
            XP::weatherIcon(Weather::snapshot().code, x + 4, y + 2, true); break;
        case XPCore::PROG_CLOCK: ICON(StartIcons, Clock, x + 4, y + 2, 2); break;
        case XPCore::PROG_INFO: XP::dialogIcon(XP::DLG_INFO, x + 8, y + 6); break;
        default: {
            const XPCore::Icon ic = XPCore::progIcon(p);
            if (XPCore::colorIcon(ic)) XP::drawColorIcon(ic, x + 4, y + 2, 2);
        }
    }
}

void tile(const XPCore::AltTabBox& b, int i, int p, bool chosen) {
    int x, y;
    XPCore::altTabTile(b, i, x, y);
    if (!Display::clipHits(x, y, XPCore::kAltTabTileW, XPCore::kAltTabTileH)) return;
    tft.fillRect(x, y, XPCore::kAltTabTileW, XPCore::kAltTabTileH, kFill);
    if (chosen) {
        tft.fillRect(x + 1, y, 38, 36, SELECT);
        tft.fillRect(x + 3, y + 2, 34, 32, kFill);
    }
    icon(p, x, y);
}

void name(const XPCore::AltTabBox& b, int p) {
    const int x = b.x + 8, y = b.y + 8 + XPCore::kAltTabTileH * b.rows + 4, w = b.w - 16;
    if (!Display::clipHits(x, y, w, 18)) return;
    tft.drawRect(x, y, w, 18, FIELD_BORDER);
    tft.fillRect(x + 1, y + 1, w - 2, 16, WHITE);
    char t[32];
    Utf8::copy(t, sizeof(t), XPCore::frameOf(XPCore::progName(p)).title);
    Display::useFont("JBMono-11");
    tft.setTextDatum(TC_DATUM);
    tft.setTextColor(BLACK, WHITE);
    tft.drawString(t, x + w / 2, y + 1);
}

}  // namespace

namespace XPAltTab {

int order(int8_t* out) {
    const Control::Windows& w = mainWindows();
    return XPCore::altTabOrder(w.open, w.n, w.top, out);
}

void draw(const Control::Menu& m) {
    int8_t list[XPCore::PROG_COUNT];
    const int n = order(list);
    if (!n) return;
    const XPCore::AltTabBox b = XPCore::altTabBox(n);
    const int sel = XPCore::altTabSel(m.hover, n);
    if (Display::clipHits(b.x, b.y, b.w, b.h)) {
        // Edge without its 4 corners, white inner line, fill.
        tft.drawFastHLine(b.x + 1, b.y, b.w - 2, kEdge);
        tft.drawFastHLine(b.x + 1, b.y + b.h - 1, b.w - 2, kEdge);
        tft.drawFastVLine(b.x, b.y + 1, b.h - 2, kEdge);
        tft.drawFastVLine(b.x + b.w - 1, b.y + 1, b.h - 2, kEdge);
        tft.drawRect(b.x + 1, b.y + 1, b.w - 2, b.h - 2, WHITE);
        tft.fillRect(b.x + 2, b.y + 2, b.w - 4, b.h - 4, kFill);
    }
    for (int i = 0; i < n; i++) tile(b, i, list[i], i == sel);
    name(b, list[sel]);
}

void relight(const Control::Menu& was, const Control::Menu& now) {
    int8_t list[XPCore::PROG_COUNT];
    const int n = order(list);
    if (!n) return;
    const XPCore::AltTabBox b = XPCore::altTabBox(n);
    const int a = XPCore::altTabSel(was.hover, n), z = XPCore::altTabSel(now.hover, n);
    if (a == z) return;
    tile(b, a, list[a], false);
    tile(b, z, list[z], true);
    name(b, list[z]);
}

}  // namespace XPAltTab
