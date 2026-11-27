#pragma once
// XP (Luna) chrome — pure logic, host-testable. P-2026-11-26.8/.9,
// screen_specs §17, token themeXP. Drawing lives in channels/xp.cpp and
// channels/taskbar.cpp; this header only decides geometry and state.
//
// Replaces the vertical dock (P-2026-11-25.3, dock_core.h): the dock's tabs
// became the taskbar's skill buttons, the y 230 strip became the 2-px slide
// progress at the bottom of the active button, and "an agent waits" became
// the badge on the Claude button (or the button lit orange on a card that
// needs the user).
#include <string.h>
#include <stdint.h>
#include "skill_core.h"
#include "attention_core.h"

namespace XPCore {

// ── Taskbar buttons ──
enum Btn : int8_t {
    BTN_NO_BAR  = -2,   // no window, no taskbar: Night (and system screens)
    BTN_NONE    = -1,   // taskbar shown, no button pressed (Info, no channels)
    BTN_CLAUDE  = 0,
    BTN_PHOTO   = 1,
    BTN_WEATHER = 2,
    BTN_CLOCK   = 3,
};
constexpr int kBtnCount = 4;

// Title-bar / taskbar icons.
enum Icon : uint8_t { ICON_NONE, ICON_CLAWD, ICON_PHOTO, ICON_WEATHER, ICON_CLOCK, ICON_INFO };

// Which button a channel presses (by kChannels[] name). Attention cards are
// Claude windows (their button lights orange instead when the card needs you).
inline Btn buttonFor(const char* name) {
    if (!name || !strcmp(name, "Night")) return BTN_NO_BAR;
    if (!strcmp(name, "Weather") || !strcmp(name, "Forecast")) return BTN_WEATHER;
    if (!strcmp(name, "Clock")) return BTN_CLOCK;
    if (!strcmp(name, "Photo")) return BTN_PHOTO;
    // Info and the desktop (Home, P-2026-11-26.12) press no button.
    if (!strcmp(name, "Info") || !strcmp(name, "Home")) return BTN_NONE;
    return BTN_CLAUDE;   // Attention, Agents, Claude, Codex, AI, Trend, Setup
}

// Title-bar icon of a channel's window (sources XP-*.dc.html): Clawd on every
// agent window, the skill icon on Photo / Weather / Forecast / Clock, "i" on Info.
inline Icon iconFor(const char* name) {
    switch (buttonFor(name)) {
        case BTN_NO_BAR:  return ICON_NONE;
        case BTN_NONE:    return ICON_INFO;
        case BTN_PHOTO:   return ICON_PHOTO;
        case BTN_WEATHER: return ICON_WEATHER;
        case BTN_CLOCK:   return ICON_CLOCK;
        default:          return ICON_CLAWD;
    }
}

inline Icon iconOf(Btn b) {
    switch (b) {
        case BTN_CLAUDE:  return ICON_CLAWD;
        case BTN_PHOTO:   return ICON_PHOTO;
        case BTN_WEATHER: return ICON_WEATHER;
        case BTN_CLOCK:   return ICON_CLOCK;
        default:          return ICON_NONE;
    }
}

// ── Programs (P-2026-11-26.14): the channels that open as a window ──
// The app keeps the open windows (design 2026-11-26.7) and sends them down
// (POST /api/windows); the taskbar shows one button per open window.
enum Prog : int8_t {
    PROG_NONE = -1,
    PROG_CLAUDE, PROG_CODEX, PROG_AI, PROG_TREND, PROG_AGENTS,
    PROG_PHOTO, PROG_WEATHER, PROG_FORECAST, PROG_CLOCK, PROG_INFO,
    PROG_COUNT
};
inline const char* progName(int p) {
    static const char* const kName[PROG_COUNT] = {"Claude", "Codex", "AI", "Trend", "Agents",
                                                  "Photo", "Weather", "Forecast", "Clock", "Info"};
    return p >= 0 && p < PROG_COUNT ? kName[p] : nullptr;
}
// kChannels[] name → program (case-insensitive like /api/channel); PROG_NONE
// for the desktop, cards, the night face, setup. Forecast is the "Dự báo" tab
// of the Weather window (P-2026-11-26.17): one program, one taskbar button.
inline Prog progOf(const char* name) {
    if (!name) return PROG_NONE;
    for (int p = 0; p < PROG_COUNT; p++) {
        const char* a = progName(p); const char* b = name;
        while (*a && *b && ((*a | 0x20) == (*b | 0x20))) { a++; b++; }
        if (!*a && !*b) return p == PROG_FORECAST ? PROG_WEATHER : (Prog)p;
    }
    return PROG_NONE;
}
// Taskbar icon of a window: Clawd for agent programs, the skill icon, "i" on Info.
inline Icon progIcon(int p) {
    switch (p) {
        case PROG_PHOTO:                    return ICON_PHOTO;
        case PROG_WEATHER: case PROG_FORECAST: return ICON_WEATHER;
        case PROG_CLOCK:                    return ICON_CLOCK;
        case PROG_INFO:                     return ICON_INFO;
        case PROG_NONE:                     return ICON_NONE;
        default:                            return ICON_CLAWD;
    }
}

// Button geometry (token themeXP.taskbar.buttons): 28×20 at x 71 + 30k, y 217.
constexpr int kBtnX0 = 71, kBtnStep = 30, kBtnW = 28, kBtnH = 20, kBtnY = 217;
inline int buttonX(int slot) { return kBtnX0 + kBtnStep * slot; }

// Badge glyph: 0 → none (-1), 1..9 → that digit, > 9 → 10 ('+').
inline int badgeGlyph(int count) {
    if (count <= 0) return -1;
    return count > 9 ? 10 : count;
}

// A card that needs the user lights the Claude button orange (xpFlash):
// approval, question, error (XP-Attention / -Input / -Error).
inline bool flashes(Attention::Kind k) {
    return k == Attention::K_APPROVAL || k == Attention::K_INPUT || k == Attention::K_ERROR;
}

// How a button looks.
enum Look : uint8_t { LOOK_NORMAL, LOOK_PRESSED, LOOK_FLASH };

// Everything the taskbar shows besides the clock (P-2026-11-26.14): one
// button per open window (the last kSlots in opening order), the top
// window's pressed while it is on screen, no slide progress. The badge and
// the orange "needs you" look sit on the Claude window's button.
constexpr int kSlots = 4;
struct BarState {
    int8_t prog[kSlots] = {PROG_NONE, PROG_NONE, PROG_NONE, PROG_NONE};
    int8_t pressed = -1;           // slot of the top window, -1 = none
    bool   flash   = false;        // a card that needs the user holds the screen
    int8_t badge   = -1;           // badgeGlyph of the agents waiting
    bool   trayWeather = false;    // weather icon in the tray (weather skill on, P-2026-11-26.15)
    bool   startDown   = false;    // the Start menu is open: start button pressed (P-2026-11-26.20)
};

// ── Tray (P-2026-11-26.15, XP-Desk-Tray): x 196–239 with the clock; with the
// weather skill on it grows 20 px left (x 176) for the weather icon 16×14 at
// (180, 220), and the taskbar keeps only 3 window buttons (x 71 / 101 / 131).
constexpr int kTrayX = 196, kTrayXWeather = 176;
constexpr int kTrayIconX = 180, kTrayIconY = 220;
inline int trayX(bool weather) { return weather ? kTrayXWeather : kTrayX; }
inline int slotsFor(bool weather) { return weather ? 3 : kSlots; }

// Slots from the open windows [open] (opening order, [n] of them): the last
// [slots] (≤ kSlots); [top] pressed when it is the program on screen ([shown]).
inline void fillBar(BarState& s, const int8_t* open, int n, int top, int shown, int slots = kSlots) {
    if (slots > kSlots) slots = kSlots;
    const int first = n > slots ? n - slots : 0;
    for (int i = 0; i < kSlots; i++) s.prog[i] = i < slots && first + i < n ? open[first + i] : PROG_NONE;
    s.pressed = -1;
    for (int i = 0; i < kSlots; i++)
        if (top >= 0 && s.prog[i] == top && top == shown) s.pressed = (int8_t)i;
}

inline Look lookOfSlot(int i, const BarState& s) {
    if (s.prog[i] == PROG_CLAUDE && s.flash) return LOOK_FLASH;
    return i == s.pressed ? LOOK_PRESSED : LOOK_NORMAL;
}
// The badge sits on the Claude button unless it is lit orange (the card says it all).
inline int badgeOnSlot(int i, const BarState& s) {
    return s.prog[i] == PROG_CLAUDE && !s.flash ? s.badge : -1;
}
// Does slot i need a repaint going from a to b?
inline bool slotChanged(int i, const BarState& a, const BarState& b) {
    return a.prog[i] != b.prog[i] || lookOfSlot(i, a) != lookOfSlot(i, b) || badgeOnSlot(i, a) != badgeOnSlot(i, b);
}

inline bool hits(int ax, int ay, int aw, int ah, int bx, int by, int bw, int bh) {
    return ax < bx + bw && bx < ax + aw && ay < by + bh && by < ay + ah;
}

// ── Opening a window (P-2026-11-26.16, XP-Open: XP "Animate windows when
// minimizing and maximizing", "Working in Background" cursor, File Download box) ──
// Order when a window comes up: its taskbar button presses first (only the
// changed buttons repaint) → restoring a minimized window: the title bar zooms
// from its button (4 steps × 40 ms; minimizing: the reverse, then the desktop)
// → the empty frame + wait cursor for 200 ms → the content.
struct Rect { int16_t x, y, w, h; };
constexpr int kZoomSteps = 4, kZoomStepMs = 40, kEmptyFrameMs = 200;
// round(a + (b − a)·i/5) for non-negative values (t = 0.2·i, i = 1..4).
inline int lerp5(int a, int b, int i) { return (2 * (a * (5 - i) + b * i) + 5) / 10; }
// Zoom step i (1..4) between the button of taskbar slot [slot] (x 71 + 30·slot,
// y 217, 28×20) and the title bar (0, 0, 240×22).
inline Rect zoomRect(int slot, int i) {
    const int bx = buttonX(slot);
    return {(int16_t)lerp5(bx, 0, i), (int16_t)lerp5(kBtnY, 0, i),
            (int16_t)lerp5(kBtnW, 240, i), (int16_t)lerp5(kBtnH, 22, i)};
}
// The window comes up through the empty frame (every window but the desktop,
// the night face and cards; system screens are not channels).
inline bool framesFirst(const char* name) {
    return name && strcmp(name, "Home") && strcmp(name, "Attention") && buttonFor(name) != BTN_NO_BAR;
}
// Title, icon and status bar of a channel's window — the empty frame drawn
// before its content (each channel's XP::window call).
struct WinFrame { const char* title; Icon icon; bool status; };
inline WinFrame frameOf(const char* name) {
    struct Row { const char* name; WinFrame f; };
    static const Row kRows[] = {
        {"Claude", {"Claude", ICON_CLAWD, false}},      {"Codex", {"Codex", ICON_CLAWD, false}},
        {"AI", {"AI hôm nay", ICON_CLAWD, true}},       {"Trend", {"Xu hướng", ICON_CLAWD, true}},
        {"Agents", {"Tác tử", ICON_CLAWD, true}},       {"Photo", {"Ảnh", ICON_PHOTO, false}},
        {"Weather", {"Thời tiết", ICON_WEATHER, false}}, {"Forecast", {"Thời tiết", ICON_WEATHER, false}},
        {"Clock", {"Ngày và Giờ", ICON_CLOCK, false}},       {"Info", {"Thông tin", ICON_INFO, false}},
        {"Setup", {"Cài đặt", ICON_CLAWD, false}},
    };
    for (const Row& r : kRows) if (name && !strcmp(r.name, name)) return r.f;
    return {name ? name : "", iconFor(name), false};
}
// Taskbar slot of program [p] among the open windows [open] ([n], opening
// order) when the bar shows the last [slots]; -1 = no button.
inline int slotOf(const int8_t* open, int n, int p, int slots) {
    const int first = n > slots ? n - slots : 0;
    for (int i = first; i < n; i++) if (open[i] == p) return i - first;
    return -1;
}
// Wait cursor: 4 hourglass frames, one per 200 ms step. File Download paper:
// 6 positions, one per step.
inline int hourglassFrame(uint32_t step) { return (int)(step % 4); }
constexpr int kPaperN = 6;
inline int paperX(int i) { return 60 + 20 * i; }
inline int paperY(int i) { static const uint8_t kY[kPaperN] = {48, 43, 40, 40, 43, 48}; return kY[i]; }

// ── Date and Time Properties calendar (P-2026-11-26.17, XP-Real) ──
// Month grid 7 × 6, weeks from Monday. [month] 1..12.
inline bool leapYear(int y) { return (y % 4 == 0 && y % 100 != 0) || y % 400 == 0; }
inline int daysIn(int year, int month) {
    static const uint8_t kD[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    if (month < 1 || month > 12) return 30;
    return month == 2 && leapYear(year) ? 29 : kD[month - 1];
}
// Cells before day 1 (days of the previous month) when day 1 falls on
// [wdayOfFirst] (tm_wday: 0 = Sunday).
inline int leadingDays(int wdayOfFirst) { return (wdayOfFirst + 6) % 7; }
// Day number shown in grid cell [i] (0..41) and whether it is in [month].
struct CalCell { int day; bool inMonth; };
inline CalCell calCell(int i, int year, int month, int wdayOfFirst) {
    const int lead = leadingDays(wdayOfFirst);
    const int n = daysIn(year, month);
    if (i < lead) {
        const int pm = month == 1 ? 12 : month - 1, py = month == 1 ? year - 1 : year;
        return {daysIn(py, pm) - lead + 1 + i, false};
    }
    if (i - lead < n) return {i - lead + 1, true};
    return {i - lead - n + 1, false};
}

// ── Screen saver (Night, P-2026-11-26.17): the time block (170×100) jumps
// every minute inside x 6..64, y 6..134, at least 30 px from where it was.
// [r1], [r2] = random numbers; tries the next spots until one is far enough.
inline void saverSpot(int oldX, int oldY, uint32_t r1, uint32_t r2, int& x, int& y) {
    for (int k = 0; k < 16; k++) {
        x = 6 + (int)((r1 + 17u * k) % 59u);
        y = 6 + (int)((r2 + 31u * k) % 129u);
        const int dx = x - oldX, dy = y - oldY;
        if (dx * dx + dy * dy >= 30 * 30) return;
    }
    x = oldX < 35 ? 64 : 6;                       // fall back: the far corner
    y = oldY < 70 ? 134 : 6;
}

// ── Desktop icons (P-2026-11-26.17 XP-Desk-OneCol: as XP, only installed
// programs) ── one column, centre x 40: Claude, Codex (agent), Ảnh (photo),
// then the trash; cells 48 tall from y 8. Weather opens from the tray icon,
// the clock from the tray clock (no desktop icons).
constexpr int kDeskMax = 6;
constexpr int kDeskTrash = -2;              // DeskIcon::prog of the trash
struct DeskIcon { int8_t prog; int16_t cx, y; };
inline int deskIcons(const char* skillsOn, DeskIcon* out) {
    int n = 0;
    auto add = [&](int8_t p) { out[n] = {p, 40, (int16_t)(8 + 48 * n)}; n++; };
    if (Skill::inList(skillsOn, "agent")) { add(PROG_CLAUDE); add(PROG_CODEX); }
    if (Skill::inList(skillsOn, "photo")) add(PROG_PHOTO);
    add(kDeskTrash);
    return n;
}

// ── Context menus (P-2026-11-26.14, XP-Menu) ──
// XP Luna menu: 1-px border, 1-px pad, items 17 tall, separators 7 tall.
// Placed by the app (top-left), kept inside x 0..239, y 0..213.
// MENU_START (P-2026-11-26.20): the XP Start menu, (0, 0)–(239, 213), never moved.
// MENU_TURNOFF (P-2026-11-27.24): XP's Turn off computer box over the whole screen (dotted shade
// included), never moved — opened like a menu, closed like one.
enum MenuKind : uint8_t { MENU_NONE, MENU_DESKTOP, MENU_WINDOW, MENU_START, MENU_TURNOFF };
constexpr int kMenuItemH = 17, kMenuSepH = 7, kMenuPad = 2;
constexpr int kMenuDeskW = 166, kMenuWinW = 128;
// Desktop: 6 items, 3 separators → 127; window: 6 items, 1 separator → 113.
inline int menuW(MenuKind k) {
    return k == MENU_START || k == MENU_TURNOFF ? 240 : k == MENU_DESKTOP ? kMenuDeskW : kMenuWinW;
}
inline int menuH(MenuKind k) {
    if (k == MENU_TURNOFF) return 240;
    if (k == MENU_START) return 214;
    return k == MENU_DESKTOP ? 2 * kMenuPad + 6 * kMenuItemH + 3 * kMenuSepH
                             : 2 * kMenuPad + 6 * kMenuItemH + 1 * kMenuSepH;
}
inline void menuClamp(MenuKind k, int& x, int& y) {
    const int maxX = 240 - menuW(k), maxY = 214 - menuH(k);
    if (x > maxX) x = maxX;
    if (y > maxY) y = maxY;
    if (x < 0) x = 0;
    if (y < 0) y = 0;
}

// Start button (x 0–67) right edge: inset per row y 214..239 (token
// themeXP.taskbar.start.round: 5,3,2,1,1, 0×16, 1,1,2,3,5).
inline int startInset(int row) {
    static const uint8_t kIn[26] = {5, 3, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
                                    0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 2, 3, 5};
    return row < 0 || row > 25 ? 0 : kIn[row];
}

// ── XP block progress bar (§17 "Thanh tiến độ XP") ──
// Border 1 px, white field, 9 separate blocks. Gap 2 px, or 1 px when the
// field inside the border is ≤ 6 px tall (XP-Claude-A session bar); blocks
// start gap px in from the border; vertical inset padY (default 1 — XP-Home,
// -AI, -Codex, attention progress; XP-Claude-A weekly + loading box pass 2);
// the last block takes the remainder. Block i lights when pct > i·11.11.
struct Blocks { int x0, y0, w, h, gap, lastW; };
inline Blocks blocks(int x, int y, int w, int h, int padY = -1) {
    const int iw = w - 2, ih = h - 2;
    const int gap = ih > 6 ? 2 : 1;
    const int py = padY >= 0 ? padY : 1;
    Blocks b;
    b.gap = gap;
    b.x0 = x + 1 + gap;
    b.y0 = y + 1 + py;
    b.h = ih - 2 * py;
    const int avail = iw - 2 * gap - 8 * gap;
    b.w = avail / 9;
    b.lastW = b.w + avail % 9;
    return b;
}
inline bool blockLit(float pct, int i) { return pct > (float)i * (100.0f / 9.0f); }

// ── "Đang tải" marquee: 9 cells, 3 lit, one cell per 0.2 s (step = ms / 200).
// Like XP's marquee the lit run enters on the left and leaves on the right.
constexpr int kMarqueeCells = 9, kMarqueeLit = 3;
inline bool marqueeLit(uint32_t step, int cell) {
    int p = (int)(step % (kMarqueeCells + kMarqueeLit - 1));   // head position 0..10
    return cell <= p && cell > p - kMarqueeLit;
}

// Window status bar: right text TR at x 231; its divider 8 px left of it.
inline int statusDividerX(int rightW) { return 231 - rightW - 8; }
// Widest right text: everything the left text leaves (left TL x 8, 4 px
// before the divider), never squeezed below 120 px while the left can give.
inline int statusRightMax(int leftW) {
    const int all = statusDividerX(0) - 8;            // 215: no left text
    if (leftW <= 0) return all;
    const int room = all - leftW - 4;
    return room > 120 ? room : 120;
}

// ── Boot screen running box (XP-Splash): 3 blocks on 6 lanes 8 px apart
// inside the 56×11 box. Theo XP thật the run enters on the left and leaves
// on the right, then starts over (period 8 steps of 0.2 s).
constexpr int kBootLanes = 6, kBootLit = 3;
inline bool bootLit(uint32_t step, int lane) {
    int p = (int)(step % (kBootLanes + kBootLit - 1));
    return lane <= p && lane > p - kBootLit;
}

}  // namespace XPCore
