// XP taskbar — see taskbar.h. Geometry: design/panel/source/XP-*.dc.html,
// token themeXP.taskbar (P-2026-11-26.9 start button + 28-px buttons;
// P-2026-11-26.14: one button per open window, no slide progress).

#include "taskbar.h"
#include "xp.h"
#include "display.h"
#include "theme.h"
#include "layout.h"
#include "clockfmt.h"
#include <time.h>

using namespace Theme::XP;
using namespace XPCore;

namespace {

constexpr int kY = Layout::TASKBAR_Y;   // 214

// Taskbar bands (token themeXP.taskbar.bands), rows relative to y 214.
struct Band { uint8_t r0, r1; uint16_t c; };
const Band kBands[4] = {
    {0, 0, TASK_HI}, {1, 2, TASK_LIGHT}, {3, 22, TASK}, {23, 25, TASK_DARK},
};
void bands(int x, int w, int r0, int r1) {
    for (const Band& b : kBands) {
        int a = b.r0 > r0 ? b.r0 : r0, z = b.r1 < r1 ? b.r1 : r1;
        if (a <= z) tft.fillRect(x, kY + a, w, z - a + 1, b.c);
    }
}

// Italic "start" 41×9 (JBMono-12B slanted 1 px / 3 rows) — bit (40-x) of row y.
const uint64_t kStart[9] PROGMEM = {
    0x000180000C0ULL, 0x000180000C0ULL, 0x01EFC71F7E0ULL, 0x02230D99180ULL, 0x03030099980ULL,
    0x07C61F30300ULL, 0x00461130300ULL, 0x04461B30300ULL, 0x07873A60380ULL,
};
void startText(int x, int y, uint16_t c) {
    for (int r = 0; r < 9; r++) {
        uint64_t row;
        memcpy_P(&row, &kStart[r], sizeof(row));
        for (int i = 0; i < 41;) {
            if (!(row >> (40 - i) & 1)) { i++; continue; }
            int run = 0;
            while (i + run < 41 && (row >> (40 - i - run) & 1)) run++;
            tft.fillRect(x + i, y + r, run, 1, c);
            i += run;
        }
    }
}

// Start button; pressed while the Start menu is open (P-2026-11-26.20): its rows go
// xpStartHi → xpStartDark and xpStart → xpGreen.
void paintStart(bool down = false) {
    for (int r = 0; r < Layout::TASKBAR_H; r++) {
        int edge = 67 - startInset(r);
        uint16_t c = r <= 1 ? (down ? START_DARK : START_HI) : r <= 22 ? (down ? GREEN : START) : START_DARK;
        tft.fillRect(0, kY + r, edge, 1, c);
        tft.drawPixel(edge, kY + r, START_DARK);
    }
    XP::drawFlag(7, 221, 1);
    startText(26, 222, START_SHADOW);
    startText(25, 221, WHITE);
}

// 3×5 digits 0–9 then '+'; bit (2-x) of row y.
const uint8_t kDigits[11][5] PROGMEM = {
    {7,5,5,5,7}, {2,6,2,2,7}, {6,1,2,4,7}, {6,1,2,1,6}, {5,5,7,1,1}, {7,4,6,1,6},
    {3,4,7,5,7}, {7,1,2,2,2}, {7,5,7,5,7}, {7,5,7,1,6}, {0,2,7,2,0},
};

// Slot i: the window's button, or the bare taskbar band when the slot is empty.
void paintSlot(int i, const BarState& s) {
    const int x = buttonX(i);
    const int p = s.prog[i];
    if (p < 0) { bands(x, kBtnW, 0, Layout::TASKBAR_H - 1); return; }
    bands(x, kBtnW, 0, 2);                       // badge zone above the button
    Look look = lookOfSlot(i, s);
    uint16_t edge = look == LOOK_FLASH ? FLASH_EDGE : look == LOOK_PRESSED ? BTN_PRESSED_EDGE : BTN_EDGE;
    uint16_t fill = look == LOOK_FLASH ? FLASH      : look == LOOK_PRESSED ? BTN_PRESSED      : BTN;
    // P-2026-11-27.24: a normal button under the mouse lights (xpTaskHi); pressed / flashing keep their look.
    if (look != LOOK_FLASH && look != LOOK_PRESSED && XP::hot() == i) fill = TASK_HI;
    tft.fillRect(x, kBtnY, kBtnW, kBtnH, edge);
    tft.fillRect(x + 1, kBtnY + 1, kBtnW - 2, kBtnH - 2, fill);
    Icon ic = progIcon(p);
    if (ic == ICON_CLAWD) {
        XP::drawIcon(ic, x + 5, 222, 1, look == LOOK_FLASH ? WHITE : Display::CLAWD_ORANGE);
    } else {
        int w, h; XP::iconSize(ic, w, h);
        XP::drawIcon(ic, x + 14 - w / 2, 227 - h / 2, 1, WHITE);
    }
    int g = badgeOnSlot(i, s);
    if (g >= 0) {
        tft.fillRect(x + 19, 215, 7, 9, Theme::AMBER);
        tft.fillRect(x + 18, 216, 9, 7, Theme::AMBER);
        for (int r = 0; r < 5; r++) {
            uint8_t row = pgm_read_byte(&kDigits[g][r]);
            for (int c = 0; c < 3; c++)
                if (row >> (2 - c) & 1) tft.drawPixel(x + 21 + c, 217 + r, Theme::BG);
        }
    }
}

char s_clock[8] = "";
BarState s_state;
bool s_shown = false;

void clockText(bool h24, char* buf, size_t n) {
    time_t now = time(nullptr);
    if (now < 1000000000L) { snprintf(buf, n, "--:--"); return; }
    // 12 h: "2:32CH" (6 chars = 42 px, fits the 43-px tray) — theo XP thật
    // the tray shows h:mm + AM/PM.
    ClockFmt::hm(now, h24, buf, n);
}

void paintClock() {
    tft.fillRect(197, 219, 43, 16, TRAY);
    Display::useFont("JBMono-11");
    tft.setTextDatum(TC_DATUM);
    tft.setTextColor(WHITE, TRAY);
    tft.drawString(s_clock, 218, 221);
}

// Tray x 196..239 (clock), or from x 176 with the weather icon (P-2026-11-26.15).
void paintTray(bool weather) {
    const int x = trayX(weather);
    tft.fillRect(x, kY, 240 - x, Layout::TASKBAR_H, TRAY);
    tft.drawFastVLine(x, kY, Layout::TASKBAR_H, TRAY_EDGE);
    tft.drawFastHLine(x + 1, kY, 239 - x, TRAY_HI);
    if (weather) XP::drawIcon(ICON_WEATHER, kTrayIconX, kTrayIconY, 1, ICON_WARN);
    paintClock();
}

}  // namespace

namespace Taskbar {

void draw(const BarState& s, bool h24) {
    s_state = s;
    s_shown = true;
    bands(0, trayX(s.trayWeather), 0, 25);   // behind the start's rounded edge + gaps between buttons
    paintStart(s.startDown);
    for (int i = 0; i < slotsFor(s.trayWeather); i++) if (s.prog[i] >= 0) paintSlot(i, s);
    clockText(h24, s_clock, sizeof(s_clock));
    paintTray(s.trayWeather);
}

void update(const BarState& s, bool h24) {
    if (!s_shown) return;
    // The weather skill turned on / off: the tray moved and a slot came or went.
    if (s.trayWeather != s_state.trayWeather) { draw(s, h24); return; }
    if (s.startDown != s_state.startDown) paintStart(s.startDown);
    for (int i = 0; i < slotsFor(s.trayWeather); i++)
        if (slotChanged(i, s_state, s)) paintSlot(i, s);
    s_state = s;
    char c[8];
    clockText(h24, c, sizeof(c));
    if (strcmp(c, s_clock)) { memcpy(s_clock, c, sizeof(s_clock)); paintClock(); }
}

// Clipped repaint under the moving cursor: exactly what was last painted
// (state, clock text) — update() keeps catching up from there.
void repaint() {
    if (!s_shown) return;
    bands(0, trayX(s_state.trayWeather), 0, 25);
    paintStart(s_state.startDown);
    for (int i = 0; i < slotsFor(s_state.trayWeather); i++) if (s_state.prog[i] >= 0) paintSlot(i, s_state);
    paintTray(s_state.trayWeather);
}

void hide() { s_shown = false; }
bool shown() { return s_shown; }
const BarState& state() { return s_state; }

}  // namespace Taskbar
