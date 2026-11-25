// Vertical dock — see dock.h. Geometry from design/panel/source/Dock.dc.html:
// children are placed from the inside of the 1-px border, so the inner origin
// is (DOCK_X + 1, DOCK_Y + 1). Only enabled skills' tabs are shown, stacked
// from the top; the frame is 36 px per tab + 6 (design's 4 tabs = 150).

#include "dock.h"
#include "display.h"
#include "theme.h"
#include "layout.h"

namespace {

constexpr int kOx = Layout::DOCK_X + 1;   // inner origin
constexpr int kOy = Layout::DOCK_Y + 1;

struct Icon { uint8_t w, h; const uint32_t* rows; };

// Bit (w-1-x) of row y = pixel (x, y). Grids from tokens component.dock.icon.
const uint32_t kClaude[10] PROGMEM = {
    0x07FF8, 0x07FF8, 0x06FD8, 0x06FD8, 0x1FFFE,
    0x1FFFE, 0x07FF8, 0x07FF8, 0x02850, 0x02850,
};
const uint32_t kWeather[14] PROGMEM = {
    0x0180, 0x2184, 0x1008, 0x07E0, 0x0FF0, 0x0FF0, 0xCFF3,
    0xCFF3, 0x0FF0, 0x0FF0, 0x07E0, 0x1008, 0x2184, 0x0180,
};
const uint32_t kClock[14] PROGMEM = {
    0x07E0, 0x1FF8, 0x381C, 0x60C6, 0x60C6, 0xC0C3, 0xC0C3,
    0xC0FB, 0xC003, 0x6006, 0x6006, 0x381C, 0x1FF8, 0x07E0,
};
const Icon kIcons[Dock::kTabCount] = {
    {18, 10, kClaude}, {16, 14, kWeather}, {16, 14, kClock},
};

// 3×5 digits 0–9 then '+'; bit (2-x) of row y.
const uint8_t kDigits[11][5] PROGMEM = {
    {7,5,5,5,7}, {2,6,2,2,7}, {6,1,2,4,7}, {6,1,2,1,6}, {5,5,7,1,1}, {7,4,6,1,6},
    {3,4,7,5,7}, {7,1,2,2,2}, {7,5,7,5,7}, {7,5,7,1,6}, {0,2,7,2,0},
};

int s_waiting = -1;   // last badge count painted; -1 = dock not on screen
uint8_t s_mask = 0;   // tabs shown (Dock::tabMask)
Dock::Tab s_active = Dock::TAB_NONE;

int slotCy(int slot) { return kOy + 19 + 36 * slot; }

void paintIcon(int k, int slot) {
    const Icon& ic = kIcons[k];
    int x0 = kOx + 14 - ic.w / 2, y0 = slotCy(slot) - ic.h / 2;
    uint16_t c = k == Dock::TAB_CLAUDE ? Display::CLAWD_ORANGE : Theme::INK_DIM;
    for (int y = 0; y < ic.h; y++) {
        uint32_t row = pgm_read_dword(&ic.rows[y]);
        for (int x = 0; x < ic.w;) {
            if (!(row >> (ic.w - 1 - x) & 1)) { x++; continue; }
            int run = 0;
            while (x + run < ic.w && (row >> (ic.w - 1 - x - run) & 1)) run++;
            tft.fillRect(x0 + x, y0 + y, run, 1, c);
            x += run;
        }
    }
}

// Badge 9×9 with 1-px cut corners at (19, cy − 14) inside the frame, on the
// Claude tab. under = what lies beneath (active tile or frame fill).
void paintBadge(int count, uint16_t under) {
    int slot = Dock::slotOf(Dock::TAB_CLAUDE, s_mask);
    if (slot < 0) return;
    int cy = slotCy(slot);
    int bx = kOx + 19, by = cy - 14;
    int g = Dock::badgeGlyph(count);
    if (g < 0) {
        tft.fillRect(bx, by, 9, 9, Theme::PANEL);
        if (under != Theme::PANEL) {
            // The active tile (x 2..25, y cy−12..cy+11) overlaps the badge box.
            int tx0 = kOx + 2, ty0 = cy - 12;
            int x0 = bx > tx0 ? bx : tx0, y0 = by > ty0 ? by : ty0;
            int x1 = bx + 9 < tx0 + 24 ? bx + 9 : tx0 + 24;
            if (x1 > x0) tft.fillRect(x0, y0, x1 - x0, by + 9 - y0, under);
            paintIcon(Dock::TAB_CLAUDE, slot);   // the clear may nick the icon
        }
        return;
    }
    tft.fillRect(bx + 1, by, 7, 9, Theme::AMBER);
    tft.fillRect(bx, by + 1, 9, 7, Theme::AMBER);
    int dx = kOx + 22, dy = cy - 12;
    for (int y = 0; y < 5; y++) {
        uint8_t row = pgm_read_byte(&kDigits[g][y]);
        for (int x = 0; x < 3; x++)
            if (row >> (2 - x) & 1) tft.drawPixel(dx + x, dy + y, Theme::BG);
    }
}

}  // namespace

namespace Dock {

void draw(uint8_t mask, Tab active, uint16_t accent, int waiting) {
    using namespace Layout;
    s_mask = mask;
    s_active = active;
    int h = frameH(mask);
    tft.fillRect(DOCK_X, DOCK_Y, DOCK_W, h, Theme::PANEL);
    tft.drawRect(DOCK_X, DOCK_Y, DOCK_W, h, Theme::LINE);
    int as = slotOf(active, mask);
    if (as >= 0) {
        int cy = slotCy(as);
        tft.fillRect(kOx + 2, cy - 12, 24, 24, Theme::PANEL2);
        tft.fillRect(kOx, cy - 5, 2, 10, accent);
    }
    for (int k = 0; k < kTabCount; k++) {
        int sl = slotOf((Tab)k, mask);
        if (sl >= 0) paintIcon(k, sl);
    }
    paintBadge(waiting, Theme::PANEL);
    s_waiting = waiting;
}

void tick(int waiting) {
    if (s_waiting < 0 || waiting == s_waiting) return;
    if (badgeGlyph(waiting) == badgeGlyph(s_waiting)) { s_waiting = waiting; return; }
    paintBadge(waiting, s_active == TAB_CLAUDE ? Theme::PANEL2 : Theme::PANEL);
    s_waiting = waiting;
}

void hide() { s_waiting = -1; }

bool showsBadge() { return s_waiting >= 0 && (s_mask >> TAB_CLAUDE & 1); }

}  // namespace Dock
