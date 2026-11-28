// XP Start menu — see xp_start.h. Geometry and colours: design/panel/source/XP-Start-All.dc.html.

#include "xp_start.h"
#include "display.h"
#include "theme.h"
#include "start_icons.h"
#include "desk_icons.h"
#include "mines_icons.h"
#include "skill_core.h"
#include "pointer_core.h"

using namespace Theme::XP;

extern PointerCore::StartInputs mainStartInputs();   // main.cpp: installed programs + the 3 opened last

namespace {

// Colours of the Start menu (themeXP.startMenu, from the source).
constexpr uint16_t kBand[6]    = {0x3CBF, 0x2C1E, 0x1B5D, 0x0ADB, 0x0A9A, 0x0A79};   // #3D95FF … #0B4CC8
constexpr uint8_t  kBandY[7]   = {0, 6, 11, 16, 22, 27, 32};
constexpr uint16_t kBandHi     = 0x5CDE;   // #5A9BF6
constexpr uint16_t kPicSky     = 0x961E;   // #93C0F3
constexpr uint16_t kPicGrass   = 0x75E6;   // #76BE37
constexpr uint16_t kOrange     = 0xF506;   // #F0A030
constexpr uint16_t kOrangeEnd  = 0xF64F;   // #F7C97A
constexpr uint16_t kOrangeDark = 0xBB23;   // #B8661E
constexpr uint16_t kColEdge    = 0x95FD;   // #95BDEE
constexpr uint16_t kRight      = 0xD73F;   // #D3E5FA
constexpr uint16_t kBottom[5]  = {0x443E, 0x2B9D, 0x1B3B, 0x12DA, 0x1278};   // #4285F4 … #134CC2

// Labels in flash, copied to the stack to draw.
const char kClawd[] PROGMEM = "Clawd";
const char kClaude[] PROGMEM = "Claude";
const char kCodex[] PROGMEM = "Codex";
const char kUsage[] PROGMEM = "mức dùng";
const char kPhoto[] PROGMEM = "Ảnh";
const char kWeather[] PROGMEM = "Thời tiết";
const char kClock[] PROGMEM = "Đồng hồ";
const char kAi[] PROGMEM = "AI hôm nay";      // P-2026-11-27.25
const char kTrend[] PROGMEM = "Xu hướng";
const char kAgents[] PROGMEM = "Agents";
const char kMines[] PROGMEM = "Dò mìn";
const char kAll[] PROGMEM = "Tất cả chương trình";
const char kDesktop[] PROGMEM = "Desktop";
const char kStats[] PROGMEM = "Số liệu";
const char kSettings[] PROGMEM = "Cài đặt";
const char kAddRemove[] PROGMEM = "Thêm / gỡ";
const char kDevice[] PROGMEM = "Thiết bị";
const char kRestart[] PROGMEM = "Khởi động lại";
const char kTurnOff[] PROGMEM = "Tắt máy";   // P-2026-11-27.24: opens Tắt máy tính

void text(const char* p, const char* font, int x, int y, uint16_t fg, uint16_t bg) {
    char t[40];
    strncpy_P(t, p, sizeof(t));
    t[sizeof(t) - 1] = 0;
    Display::useFont(font);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(fg, bg);
    tft.drawString(t, x, y);
}

// A colour icon of runs (tools/deskicons.py), transparent cells left as they are.
template <typename Run>
void runs(const Run* r, int n, const uint16_t* pal, int x0, int y0) {
    for (int k = 0; k < n; k++) {
        Run q;
        memcpy_P(&q, &r[k], sizeof(q));
        tft.fillRect(x0 + q.x, y0 + q.y, q.w, 1, pgm_read_word(&pal[q.c]));
    }
}
#define ICON(NS, N, X, Y) runs(NS::k##N##Runs, NS::k##N##RunCount, NS::k##N##Pal, (X), (Y))

void userBand() {
    for (int b = 0; b < 6; b++) tft.fillRect(0, kBandY[b], 240, kBandY[b + 1] - kBandY[b], kBand[b]);
    tft.drawFastHLine(3, 0, 234, kBandHi);
    tft.fillRect(5, 4, 24, 24, WHITE);                  // picture frame
    tft.fillRect(6, 5, 22, 22, MENU_BORDER);
    tft.fillRect(7, 6, 20, 14, kPicSky);
    tft.fillRect(7, 20, 20, 6, kPicGrass);
    ICON(StartIcons, UserClawd, 9, 11);
    text(kClawd, "JBMono-16B", 36, 8, TITLE_SHADOW, kBand[1]);
    text(kClawd, "JBMono-16B", 35, 7, WHITE, kBand[1]);
    tft.drawFastHLine(0, 32, 240, kOrange);
    tft.drawFastHLine(0, 32, 20, kOrangeEnd);
    tft.drawFastHLine(220, 32, 20, kOrangeEnd);
    tft.drawFastHLine(0, 33, 240, kOrangeDark);
}

using PointerCore::StartLayout;
using namespace PointerCore;

// P-2026-11-27.25: installed programs + the 3 opened last ([on] kept for the callers' signature).
void layoutOf(const char*, StartLayout& L) { startLayout(mainStartInputs(), L); }

// A colour icon with its top highlight row white (a lit bottom-band button, as XP): runs of palette
// entry 1 on the icon's first row of that colour.
template <typename Run>
void runsLit(const Run* r, int n, const uint16_t* pal, int x0, int y0) {
    int hiY = 255;
    for (int k = 0; k < n; k++) {
        Run q; memcpy_P(&q, &r[k], sizeof(q));
        if (q.c == 1 && q.y < hiY) hiY = q.y;
    }
    for (int k = 0; k < n; k++) {
        Run q; memcpy_P(&q, &r[k], sizeof(q));
        const uint16_t c = q.c == 1 && q.y == hiY ? WHITE : pgm_read_word(&pal[q.c]);
        tft.fillRect(x0 + q.x, y0 + q.y, q.w, 1, c);
    }
}
#define ICON_LIT(NS, N, X, Y, LIT) \
    ((LIT) ? runsLit(NS::k##N##Runs, NS::k##N##RunCount, NS::k##N##Pal, (X), (Y)) \
           : runs(NS::k##N##Runs, NS::k##N##RunCount, NS::k##N##Pal, (X), (Y)))

// One Start menu row, lit (xpSelect, white text — icons keep their colours) or not.
void paintItem(const StartLayout& L, int i, bool lit) {
    if (i < 0 || i >= L.n) return;
    const Rect r = L.row[i];
    const int y = r.y;
    const uint16_t fg = lit ? WHITE : BLACK;
    switch (L.item[i]) {
        case S_CLAUDE:
        case S_CODEX:
        case S_PHOTO:
        case S_WEATHER:
        case S_CLOCK:
        case S_MINES:
        case S_AI:
        case S_TREND:
        case S_AGENTS:
        case S_ALL: {
            const uint16_t bg = lit ? SELECT : WHITE;
            tft.fillRect(r.x, r.y, r.w, r.h, bg);
            switch (L.item[i]) {
                case S_CLAUDE:
                    ICON(StartIcons, PinClawd, 3, 39);
                    text(kClaude, "JBMono-12B", 42, 37, fg, bg);
                    text(kUsage, "JBMono-11", 42, 51, lit ? WHITE : MUTED, bg);
                    break;
                case S_CODEX:
                    ICON(DeskIcons, Codex, 5, 65);
                    text(kCodex, "JBMono-12B", 42, 66, fg, bg);
                    text(kUsage, "JBMono-11", 42, 80, lit ? WHITE : MUTED, bg);
                    break;
                case S_PHOTO:   ICON(StartIcons, Photo, 6, y + 3);   text(kPhoto, "JBMono-11", 28, y + 4, fg, bg);   break;
                case S_WEATHER: ICON(StartIcons, Weather, 6, y + 2); text(kWeather, "JBMono-11", 28, y + 4, fg, bg); break;
                case S_CLOCK:   ICON(StartIcons, Clock, 6, y + 2);   text(kClock, "JBMono-11", 28, y + 4, fg, bg);   break;
                case S_MINES:   ICON(MinesIcons, StartMines, 6, y + 2);  text(kMines, "JBMono-11", 28, y + 4, fg, bg);  break;
                case S_AI:      ICON(MinesIcons, StartAi, 6, y + 2);     text(kAi, "JBMono-11", 28, y + 4, fg, bg);     break;
                case S_TREND:   ICON(MinesIcons, StartTrend, 6, y + 2);  text(kTrend, "JBMono-11", 28, y + 4, fg, bg);  break;
                case S_AGENTS:  ICON(MinesIcons, StartAgents, 6, y + 2); text(kAgents, "JBMono-11", 28, y + 4, fg, bg); break;
                default:
                    text(kAll, "JBMono-12B", 4, 170, fg, bg);
                    ICON(StartIcons, AllArrow, 138, 171);
            }
            return;
        }
        case S_DESKTOP:
        case S_STATS:
        case S_SETTINGS:
        case S_ADDREMOVE:
        case S_DEVICE: {
            const uint16_t bg = lit ? SELECT : kRight;
            const uint16_t ink = lit ? WHITE : TITLE_SHADOW;
            tft.fillRect(r.x, r.y, r.w, r.h, bg);
            switch (L.item[i]) {
                case S_DESKTOP:   ICON(StartIcons, Desktop, 156, y + 2);   text(kDesktop, "JBMono-12B", 175, y + 3, ink, bg);  break;
                case S_STATS:     ICON(StartIcons, Stats, 156, y + 2);     text(kStats, "JBMono-12B", 175, y + 3, ink, bg);    break;
                case S_SETTINGS:  ICON(StartIcons, Settings, 156, y + 2);  text(kSettings, "JBMono-11", 175, y + 3, ink, bg);  break;
                case S_ADDREMOVE: ICON(StartIcons, AddRemove, 156, y + 2); text(kAddRemove, "JBMono-11", 175, y + 3, ink, bg); break;
                default:          ICON(StartIcons, Device, 156, y + 2);    text(kDevice, "JBMono-11", 175, y + 3, ink, bg);    break;
            }
            return;
        }
        case S_RESTART: ICON_LIT(StartIcons, Restart, 8, 194, lit); return;   // the label stays white
        default:        ICON_LIT(StartIcons, Power, 165, 194, lit); return;
    }
}

// One All Programs row (lit band (145, row, 94×20); icon (147, row + 2), label (166, row + 4) — P-2026-11-27.25).
void paintSub(const StartLayout& L, int i, bool lit) {
    if (i < 0 || i >= L.subN) return;
    const Rect r = L.subRow[i];
    const int y = r.y;
    const uint16_t bg = lit ? SELECT : WHITE, fg = lit ? WHITE : BLACK;
    tft.fillRect(r.x, r.y, r.w, r.h, bg);
    switch (L.sub[i]) {
        case SUB_CLAUDE:  ICON(StartIcons, SmallClawd, 147, y + 5);  text(kClaude, "JBMono-11", 166, y + 4, fg, bg);  break;
        case SUB_CODEX:   ICON(StartIcons, SmallCodex, 147, y + 4);  text(kCodex, "JBMono-11", 166, y + 4, fg, bg);   break;
        case SUB_AI:      ICON(MinesIcons, StartAi, 147, y + 2);     text(kAi, "JBMono-11", 166, y + 4, fg, bg);      break;
        case SUB_TREND:   ICON(MinesIcons, StartTrend, 147, y + 2);  text(kTrend, "JBMono-11", 166, y + 4, fg, bg);   break;
        case SUB_AGENTS:  ICON(MinesIcons, StartAgents, 147, y + 2); text(kAgents, "JBMono-11", 166, y + 4, fg, bg);  break;
        case SUB_PHOTO:   ICON(StartIcons, Photo, 147, y + 3);       text(kPhoto, "JBMono-11", 166, y + 4, fg, bg);   break;
        case SUB_WEATHER: ICON(StartIcons, Weather, 147, y + 2);     text(kWeather, "JBMono-11", 166, y + 4, fg, bg); break;
        case SUB_CLOCK:   ICON(StartIcons, Clock, 147, y + 2);       text(kClock, "JBMono-11", 166, y + 4, fg, bg);   break;
        case SUB_MINES:   ICON(MinesIcons, StartMines, 147, y + 2);  text(kMines, "JBMono-11", 166, y + 4, fg, bg);   break;
        default:          ICON(StartIcons, AddRemove, 147, y + 2);   text(kAddRemove, "JBMono-11", 166, y + 4, fg, bg);
    }
}

bool litItem(const StartLayout& L, const Control::Menu& m, int i) {
    return i == m.hover || (m.all && i >= 0 && i < L.n && L.item[i] == S_ALL);
}

void columns(const StartLayout& L, const Control::Menu& m) {
    if (L.n && L.item[0] == S_CLAUDE) tft.drawFastHLine(6, 95, 140, ROW_LINE);
    tft.drawFastHLine(6, 163, 140, ROW_LINE);
    tft.drawFastHLine(157, 83, 78, DIVIDER);
    for (int i = 0; i < L.n; i++)
        if (L.item[i] != S_RESTART && L.item[i] != S_TURNOFF) paintItem(L, i, litItem(L, m, i));
}

void bottomBand(const StartLayout& L, const Control::Menu& m) {
    for (int b = 0; b < 5; b++) tft.fillRect(0, 190 + 5 * b, 240, b == 4 ? 4 : 5, kBottom[b]);
    tft.drawFastHLine(0, 190, 240, TASK_HI);
    text(kRestart, "JBMono-11", 27, 196, WHITE, kBottom[1]);
    text(kTurnOff, "JBMono-11", 184, 196, WHITE, kBottom[1]);
    const int r = startIndexOf(L, S_RESTART), t = startIndexOf(L, S_TURNOFF);
    paintItem(L, r, m.hover == r);
    paintItem(L, t, m.hover == t);
}

// All Programs sub-menu (144, top, 96 wide — P-2026-11-27.25): every installed program, separator, Thêm / gỡ.
void allPrograms(const StartLayout& L, const Control::Menu& m) {
    const Rect b = L.subBox;
    tft.fillRect(b.x, b.y, b.w, b.h, MENU_BORDER);
    tft.fillRect(b.x + 1, b.y + 1, b.w - 2, b.h - 2, WHITE);
    for (int i = 0; i < L.subN; i++) paintSub(L, i, i == m.sub);
    const Rect add = L.subRow[L.subN - 1];
    tft.drawFastHLine(148, add.y - 4, 88, MENU_BORDER);
}

}  // namespace

namespace XPStart {

void draw(const Control::Menu& m, const char* skillsOn) {
    StartLayout L;
    layoutOf(skillsOn, L);
    userBand();
    tft.fillRect(0, 34, 240, 156, BTN_EDGE);            // body: blue edges x 0 / 239
    tft.fillRect(1, 34, 151, 156, WHITE);
    tft.drawFastVLine(152, 34, 156, kColEdge);
    tft.fillRect(153, 34, 86, 156, kRight);
    columns(L, m);
    bottomBand(L, m);
    if (m.all) allPrograms(L, m);
}

// P-2026-11-27.24: another row lit — only the two rows repaint (the one that was lit, the new one).
void relight(const Control::Menu& was, const Control::Menu& now, const char* skillsOn) {
    StartLayout L;
    layoutOf(skillsOn, L);
    // Under the open sub-menu the right column is hidden: leave it.
    auto hidden = [&](int i) {
        return now.all && i >= 0 && i < L.n && L.item[i] >= S_DESKTOP && L.item[i] <= S_DEVICE;
    };
    // The open sub-menu also lies over x 144..151 of the left column: paint those rows clipped.
    auto paint = [&](int i, bool lit) {
        if (hidden(i)) return;
        const bool clip = now.all && i >= 0 && i < L.n && L.item[i] <= S_ALL;
        if (clip) tft.setViewport(0, 0, L.subBox.x, 240, false);
        paintItem(L, i, lit);
        if (clip) tft.resetViewport();
    };
    if (was.hover != now.hover) {
        paint(was.hover, litItem(L, now, was.hover));
        paint(now.hover, true);
    }
    if (now.all && was.sub != now.sub) {
        paintSub(L, was.sub, false);
        paintSub(L, now.sub, true);
    }
}

}  // namespace XPStart
