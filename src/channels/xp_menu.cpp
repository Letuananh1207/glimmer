// XP context menus — see xp_menu.h.

#include "xp_menu.h"
#include "display.h"
#include "theme.h"

using namespace Theme::XP;
using namespace XPCore;

namespace {

// Labels live in flash (copied to a stack buffer to draw).
const char kArrange[] PROGMEM = "Sắp xếp biểu tượng";
const char kRefresh[] PROGMEM = "Làm mới";
const char kPaste[] PROGMEM = "Dán";
const char kPasteLink[] PROGMEM = "Dán lối tắt";
const char kNew[] PROGMEM = "Mới";
const char kProps[] PROGMEM = "Thuộc tính";
const char kRestoreL[] PROGMEM = "Khôi phục";
const char kMove[] PROGMEM = "Di chuyển";
const char kSize[] PROGMEM = "Kích thước";
const char kMinL[] PROGMEM = "Thu nhỏ";
const char kMaxL[] PROGMEM = "Phóng to";
const char kCloseL[] PROGMEM = "Đóng";
const char kAltF4[] PROGMEM = "Alt+F4";

enum Glyph : uint8_t { G_NONE, G_RESTORE, G_MIN, G_MAX, G_CLOSE };
struct Row {
    const char* label;   // PROGMEM, nullptr = separator
    bool dim, arrow, bold;
    Glyph glyph;
};

const Row kDesktop[] = {
    {kArrange, false, true, false, G_NONE},
    {kRefresh, false, false, false, G_NONE},
    {nullptr, false, false, false, G_NONE},
    {kPaste, true, false, false, G_NONE},
    {kPasteLink, true, false, false, G_NONE},
    {nullptr, false, false, false, G_NONE},
    {kNew, true, true, false, G_NONE},
    {nullptr, false, false, false, G_NONE},
    {kProps, false, false, false, G_NONE},
};

// Glyph rects (dx, dy, w, h) from the item's top-left (source XP-Menu-Window.dc.html).
struct R { int8_t x, y, w, h; };
const R kRestore[] = {{7, 5, 5, 2}, {11, 7, 1, 3}, {10, 9, 1, 1}, {5, 7, 5, 2}, {5, 9, 1, 3}, {9, 9, 1, 3}, {5, 11, 5, 1}};
const R kMin[]     = {{6, 10, 5, 2}};
const R kMax[]     = {{5, 5, 7, 2}, {5, 7, 1, 5}, {11, 7, 1, 5}, {5, 11, 7, 1}};
const R kClose[]   = {{5, 5, 2, 1}, {10, 5, 2, 1}, {6, 6, 2, 1}, {9, 6, 2, 1}, {7, 7, 3, 1}, {7, 8, 3, 1},
                      {7, 9, 3, 1}, {6, 10, 2, 1}, {9, 10, 2, 1}, {5, 11, 2, 1}, {10, 11, 2, 1}};

template <size_t N>
void rects(const R (&r)[N], int x, int y, uint16_t c) {
    for (const R& q : r) tft.fillRect(x + q.x, y + q.y, q.w, q.h, c);
}

void glyph(Glyph g, int x, int y, uint16_t c) {
    switch (g) {
        case G_RESTORE: rects(kRestore, x, y, c); break;
        case G_MIN:     rects(kMin, x, y, c); break;
        case G_MAX:     rects(kMax, x, y, c); break;
        case G_CLOSE:   rects(kClose, x, y, c); break;
        default: break;
    }
}

// ▸ 4×7: columns 7, 5, 3, 1 tall.
void arrow(int x, int y, uint16_t c) {
    for (int k = 0; k < 4; k++) tft.drawFastVLine(x + k, y + k, 7 - 2 * k, c);
}

// [hover] = the lit item (R-DK-18/19, as XP: xpSelect bar inside the frame,
// white text; a dim item keeps its grey), counted without separators.
void rows(const Row* r, int n, int x, int y, int w, int hover) {
    int iy = y + kMenuPad;
    int item = 0;
    for (int i = 0; i < n; i++) {
        if (!r[i].label) {
            tft.drawFastHLine(x + 2, iy + 3, w - 4, MENU_BORDER);
            iy += kMenuSepH;
            continue;
        }
        const bool lit = item++ == hover;
        const uint16_t bg = lit ? SELECT : WHITE;
        const uint16_t c = r[i].dim ? MENU_BORDER : lit ? WHITE : BLACK;
        tft.fillRect(x + kMenuPad, iy, w - 2 * kMenuPad, kMenuItemH, bg);
        Display::useFont(r[i].bold ? "JBMono-12B" : "JBMono-11");
        tft.setTextDatum(TL_DATUM);
        tft.setTextColor(c, bg);
        char t[32];
        strncpy_P(t, r[i].label, sizeof(t));
        t[sizeof(t) - 1] = 0;
        tft.drawString(t, x + 17, iy + (r[i].bold ? 1 : 2));
        if (r[i].arrow) arrow(x + w - 10, iy + 5, c);
        glyph(r[i].glyph, x, iy, c);
        iy += kMenuItemH;
    }
}

}  // namespace

namespace XPMenu {

void draw(const Control::Menu& m) {
    if (m.kind == MENU_NONE) return;
    int x = m.x, y = m.y;
    menuClamp(m.kind, x, y);
    const int w = menuW(m.kind), h = menuH(m.kind);
    tft.fillRect(x, y, w, h, MENU_BORDER);
    tft.fillRect(x + 1, y + 1, w - 2, h - 2, WHITE);
    if (m.kind == MENU_DESKTOP) {
        rows(kDesktop, sizeof(kDesktop) / sizeof(kDesktop[0]), x, y, w, m.hover);
        return;
    }
    const Row win[] = {
        {kRestoreL, !m.minimized, false, false, G_RESTORE},
        {kMove, true, false, false, G_NONE},
        {kSize, true, false, false, G_NONE},
        {kMinL, m.minimized, false, false, G_MIN},
        {kMaxL, true, false, false, G_MAX},
        {nullptr, false, false, false, G_NONE},
        {kCloseL, false, false, true, G_CLOSE},
    };
    rows(win, sizeof(win) / sizeof(win[0]), x, y, w, m.hover);
    // "Alt+F4" right-aligned on the Đóng row (the last item, index 5).
    const bool closeLit = m.hover == 5;
    Display::useFont("JBMono-11");
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(closeLit ? WHITE : BLACK, closeLit ? SELECT : WHITE);
    char a[8]; strncpy_P(a, kAltF4, sizeof(a)); a[sizeof(a) - 1] = 0;
    tft.drawString(a, x + w - 17, y + h - kMenuPad - kMenuItemH + 2);
}

}  // namespace XPMenu
