#pragma once
// The device is the XP computer (app plan app/docs/tasks/2026-11-28-thiet-bi-la-may-tinh.md): the app only sends the
// mouse (position + buttons) and keys over UDP; the device works out what a click hits and what it does, as Windows XP.
// Pure, host-tested. Stage 1: the desktop, the taskbar, the title bar's _ / ×, Start and Tắt máy tính; the cursor
// shape. Menus, keys and the windows' insides come in later stages (the app still drives those).
//
// Mouse datagram v2 (8 bytes, UDP :4210, as v1 but the buttons instead of the shape — the device picks the shape):
//   'G' 'C' 2 buttons seqHi seqLo x y      buttons: bit 0 left, bit 1 right held
// The app sends a button change 3 times with one seq (UDP may drop one); the device takes each seq once and works
// out press / release in order. A press then a release = a click; two presses ≤ 500 ms and ≤ 4 px apart = a double
// click (XP's defaults). No dragging yet (windows never move): the held state only marks presses.
#include <stdint.h>
#include <stddef.h>
#include "xp_core.h"
#include "pointer_core.h"
#include "cursor_core.h"

namespace InputCore {

constexpr uint8_t kMouseVersion = 2;
// What the device acts on so far (`/api/state` `input.stage`): 1 = desktop, taskbar, _ / ×, Start, Tắt máy tính;
constexpr uint8_t kStage = 5;   // 3 = + menus, keys; 4 = + Thời tiết, Ngày và Giờ, Dò mìn; 5 = + the 4 XP programs
constexpr uint8_t kLeft = 1, kRight = 2;
constexpr uint32_t kDoubleMs = 500;
constexpr int kDoubleSlop = 4;

struct Mouse {
    uint16_t seq = 0;
    uint8_t  buttons = 0;
    uint8_t  x = 120, y = 120;
};

// A v2 mouse datagram; false = not one / malformed.
inline bool parseMouse(const uint8_t* p, size_t n, Mouse& out) {
    if (!p || n != CursorCore::kPacketLen || p[0] != 'G' || p[1] != 'C' || p[2] != kMouseVersion) return false;
    if (p[3] > (kLeft | kRight) || p[6] >= CursorCore::kScreen || p[7] >= CursorCore::kScreen) return false;
    out.buttons = p[3];
    out.seq = (uint16_t)(p[4] << 8 | p[5]);
    out.x = p[6];
    out.y = p[7];
    return true;
}

inline void encodeMouse(const Mouse& m, uint8_t out[CursorCore::kPacketLen]) {
    out[0] = 'G'; out[1] = 'C'; out[2] = kMouseVersion; out[3] = m.buttons;
    out[4] = (uint8_t)(m.seq >> 8); out[5] = (uint8_t)m.seq; out[6] = m.x; out[7] = m.y;
}

// ── presses ──
enum Press : uint8_t { PRESS_NONE = 0, PRESS_LEFT, PRESS_RIGHT };

// The presses (button going down) from [was] to [now]: left first.
inline int pressesOf(uint8_t was, uint8_t now, Press out[2]) {
    int n = 0;
    if ((now & kLeft) && !(was & kLeft)) out[n++] = PRESS_LEFT;
    if ((now & kRight) && !(was & kRight)) out[n++] = PRESS_RIGHT;
    return n;
}

// XP's double click: the second left press within kDoubleMs and kDoubleSlop px of the first. A double click ends the
// pair (a third press starts over).
struct ClickTrack {
    uint32_t at = 0;
    int16_t x = -100, y = -100;
    bool armed = false;
};
inline bool doubleClick(ClickTrack& t, uint32_t now, int x, int y) {
    const bool dbl = t.armed && now - t.at <= kDoubleMs && (x - t.x <= kDoubleSlop && t.x - x <= kDoubleSlop)
                  && (y - t.y <= kDoubleSlop && t.y - y <= kDoubleSlop);
    t.armed = !dbl;
    t.at = now;
    t.x = (int16_t)x;
    t.y = (int16_t)y;
    return dbl;
}

// ── what is on screen ──
struct Scene {
    bool desktop = false;          // the desktop (Home) shows
    bool caption = false;          // a window with its title bar shows (its _ / × work)
    int8_t shown = XPCore::PROG_NONE;   // the program of the window on screen
    XPCore::MenuKind menu = XPCore::MENU_NONE;
    bool all = false;              // Start: All Programs open
    XPCore::BarState bar;
    XPCore::DeskIcon icons[XPCore::kDeskMax];
    int nIcons = 0;
    PointerCore::StartLayout start;
    bool explorer = true;          // this firmware has Máy tính (Start › Thiết bị, the Recycle Bin)
    // Stage 3: the context menu on screen (as drawn: clamped), the item lit, the desktop's selected icon.
    int16_t menuX = 0, menuY = 0;
    bool menuMin = false;          // window menu of a minimized window
    int8_t menuProg = XPCore::PROG_NONE;   // the window a window menu belongs to
    int8_t hover = -1;             // item lit (menus: index without separators; Start: hover order; box: button)
    int8_t sel = XPCore::PROG_NONE;        // desktop icon selected (kDeskTrash = the Recycle Bin)
};

// Taskbar parts (y 214–239): start x 0–67; tray weather icon x 176–195 (weather skill); tray clock to the right.
constexpr int kBarY = 214, kStartRight = 68, kTrayIconX0 = 176, kTrayIconX1 = 196;
inline int trayClockX(bool weather) { return weather ? kTrayIconX1 : XPCore::kTrayX; }
// Desktop icon cell: 80 wide around its centre, 48 tall from its top (icon + label, as XP's selection box).
constexpr int kIconHalfW = 40, kIconCell = 48;

inline int iconAt(const Scene& s, int x, int y) {
    for (int i = 0; i < s.nIcons; i++) {
        const XPCore::DeskIcon& ic = s.icons[i];
        if (x >= ic.cx - kIconHalfW && x < ic.cx + kIconHalfW && y >= ic.y && y < ic.y + kIconCell) return i;
    }
    return -1;
}

// ── what a left click does ──
enum Act : uint8_t {
    ACT_NONE,
    ACT_SELECT,        // desktop: select icon [prog] (PROG_NONE = drop the selection); the trash = kDeskTrash
    ACT_OPEN,          // open / bring up program [prog]; [arg] = Explorer place (0 Máy tính, 2 Thùng rác)
    ACT_TASKBAR,       // a taskbar button of [prog]: down when it is on screen, else up (XP)
    ACT_MINIMIZE,      // _ of the window on screen
    ACT_CLOSE,         // × of the window on screen
    ACT_START,         // start button: Start opens / closes
    ACT_START_ALL,     // Tất cả chương trình: the sub-menu opens / closes
    ACT_START_CLOSE,   // a click outside Start: it closes
    ACT_SHOW_DESKTOP,  // Start › Desktop: every window down
    ACT_TURNOFF_BOX,   // Start › Khởi động lại / Tắt máy: XP's Tắt máy tính box
    ACT_STANDBY,       // Tắt máy tính › Chờ: the screen off
    ACT_POWER_OFF,     // › Tắt
    ACT_RESTART,       // › Khởi động lại
    ACT_TURNOFF_CLOSE, // › Hủy
    ACT_MENU_CLOSE,    // the context menu / Start / the box closes
    ACT_MENU_OPEN,     // stage 3: a context menu [arg] = MenuKind at (x, y) for window [prog] (minimized: [min])
    ACT_HOVER,         // stage 3: item [arg] lit (arrow keys)
    ACT_ALTTAB,        // stage 3: Alt+Tab — the box opens / the next tile ([arg] = 1, Shift = −1)
    ACT_ALTTAB_CANCEL, // Esc while the box is up
    ACT_INSIDE,        // stage 4: a click inside window [prog] at (x, y) — its channel works it out ([arg] 1 = right)
    ACT_INSIDE_KEY,    // stage 5: key [arg] (mods in x) for window [prog]
};

struct Action {
    Act kind = ACT_NONE;
    int8_t prog = XPCore::PROG_NONE;
    int8_t arg = -1;
    int16_t x = 0, y = 0;          // ACT_MENU_OPEN: where
    bool min = false;              // ACT_MENU_OPEN: the window is minimized
    bool dbl = false;              // ACT_INSIDE: the second click of a double click
};
inline Action act(Act k, int prog = XPCore::PROG_NONE, int arg = -1) {
    Action a; a.kind = k; a.prog = (int8_t)prog; a.arg = (int8_t)arg; return a;
}

constexpr int8_t kPlaceComputer = 0, kPlaceTrash = 2;

// ── Context menus (stage 3; rows as xp_menu.cpp draws them) ──
enum MenuItemId : uint8_t {
    MI_ARRANGE, MI_REFRESH, MI_PASTE, MI_PASTE_LINK, MI_NEW, MI_PROPS,                 // desktop
    MI_RESTORE, MI_MOVE, MI_SIZE, MI_MIN, MI_MAX, MI_CLOSE,                           // window
    MI_TOOLBARS, MI_CASCADE, MI_SHOW_DESKTOP, MI_TASKMGR, MI_LOCK, MI_BAR_PROPS,       // taskbar
    MI_SEP = 0xFF,
};
// Rows top to bottom (MI_SEP = a separator); returns the count.
inline int menuRows(XPCore::MenuKind k, uint8_t* out) {
    static const uint8_t kDesk[] = {MI_ARRANGE, MI_REFRESH, MI_SEP, MI_PASTE, MI_PASTE_LINK, MI_SEP, MI_NEW, MI_SEP,
                                    MI_PROPS};
    static const uint8_t kWin[] = {MI_RESTORE, MI_MOVE, MI_SIZE, MI_MIN, MI_MAX, MI_SEP, MI_CLOSE};
    static const uint8_t kBar[] = {MI_TOOLBARS, MI_SEP, MI_CASCADE, MI_SHOW_DESKTOP, MI_SEP, MI_TASKMGR, MI_SEP, MI_LOCK,
                                   MI_BAR_PROPS};
    const uint8_t* r = k == XPCore::MENU_DESKTOP ? kDesk : k == XPCore::MENU_TASKBAR ? kBar : kWin;
    const int n = k == XPCore::MENU_DESKTOP ? (int)sizeof(kDesk) : k == XPCore::MENU_TASKBAR ? (int)sizeof(kBar)
                                                                                              : (int)sizeof(kWin);
    for (int i = 0; i < n; i++) out[i] = r[i];
    return n;
}
// Item [i] (separators not counted) of menu [k]; MI_SEP when out of range.
inline uint8_t menuItem(XPCore::MenuKind k, int i) {
    uint8_t r[9];
    const int n = menuRows(k, r);
    for (int j = 0, c = 0; j < n; j++) {
        if (r[j] == MI_SEP) continue;
        if (c++ == i) return r[j];
    }
    return MI_SEP;
}
inline int menuItems(XPCore::MenuKind k) { return k == XPCore::MENU_DESKTOP ? 6 : 6; }
// Lit (usable) items; the others are drawn dim and do nothing (Sắp xếp biểu tượng ▸: its sub-menu is not drawn).
inline bool menuEnabled(uint8_t id, bool minimized) {
    switch (id) {
        case MI_REFRESH: case MI_PROPS: case MI_CLOSE: case MI_SHOW_DESKTOP: case MI_TASKMGR: return true;
        case MI_RESTORE: return minimized;
        case MI_MIN:     return !minimized;
        default:         return false;
    }
}
// The item under (x, y) of the menu drawn at (mx, my): index without separators; -1 = a separator / the border /
// outside ([inside] says whether (x, y) is on the menu at all).
inline int menuItemAt(XPCore::MenuKind k, int mx, int my, int x, int y, bool& inside) {
    const int w = XPCore::menuW(k), h = XPCore::menuH(k);
    inside = x >= mx && x < mx + w && y >= my && y < my + h;
    if (!inside) return -1;
    uint8_t r[9];
    const int n = menuRows(k, r);
    int top = my + XPCore::kMenuPad;
    for (int j = 0, c = 0; j < n; j++) {
        const int rh = r[j] == MI_SEP ? XPCore::kMenuSepH : XPCore::kMenuItemH;
        if (y >= top && y < top + rh) return r[j] == MI_SEP ? -1 : c;
        top += rh;
        if (r[j] != MI_SEP) c++;
    }
    return -1;
}

// What choosing item [i] of the open context menu does (a click on it / Enter on it).
inline Action menuChoose(const Scene& s, int i) {
    const uint8_t id = menuItem(s.menu, i);
    if (id == MI_SEP || !menuEnabled(id, s.menuMin)) return Action();
    switch (id) {
        case MI_REFRESH: return act(ACT_MENU_CLOSE);                       // the desktop repaints as the menu goes
        case MI_PROPS:   return act(ACT_OPEN, XPCore::PROG_DISPLAY);        // Thuộc tính = Display Properties (XP)
        case MI_RESTORE: return act(ACT_OPEN, s.menuProg);
        case MI_MIN:     return act(ACT_MINIMIZE, s.menuProg);
        case MI_CLOSE:   return act(ACT_CLOSE, s.menuProg);
        case MI_SHOW_DESKTOP: return act(ACT_SHOW_DESKTOP);
        case MI_TASKMGR:      return act(ACT_OPEN, XPCore::PROG_TASKMGR);
        default:         return Action();
    }
}

// A click while a context menu is up: an item acts; a separator / dim item does nothing; outside, the menu closes.
inline Action menuClick(const Scene& s, int x, int y) {
    bool inside = false;
    const int i = menuItemAt(s.menu, s.menuX, s.menuY, x, y, inside);
    if (!inside) return act(ACT_MENU_CLOSE);
    return i >= 0 ? menuChoose(s, i) : Action();
}

inline Action menuAt(XPCore::MenuKind k, int x, int y, int prog = XPCore::PROG_NONE, bool minimized = false) {
    Action a = act(ACT_MENU_OPEN, prog, k);
    XPCore::menuClamp(k, x, y);
    a.x = (int16_t)x;
    a.y = (int16_t)y;
    a.min = minimized;
    return a;
}

// Stage 4: a click inside the window on screen. Thời tiết's tabs (y 26–41: Hiện tại x 6–71, Dự báo 72–123) switch
// here; Ngày và Giờ and Dò mìn are worked out by their channel (ACT_INSIDE); other windows: still the app's.
// Stage 5: Trình quản lý tác vụ, Thuộc tính màn hình, Máy tính bỏ túi, Explorer are worked out by the device too.
inline bool deviceWindow(int p) {
    return p == XPCore::PROG_MINES || p == XPCore::PROG_CLOCK || p == XPCore::PROG_TASKMGR
        || p == XPCore::PROG_DISPLAY || p == XPCore::PROG_CALC || p == XPCore::PROG_EXPLORER;
}
inline Action inside(const Scene& s, int x, int y, bool right, bool dbl = false) {
    if (y < 22 || y >= kBarY) return Action();
    if (s.shown == XPCore::PROG_WEATHER && !right && y >= 26 && y < 42) {
        if (x >= 6 && x < 72) return act(ACT_OPEN, XPCore::PROG_WEATHER);
        if (x >= 72 && x < 124) return act(ACT_OPEN, XPCore::PROG_FORECAST);
        return Action();
    }
    if (s.shown == XPCore::PROG_MINES || (deviceWindow(s.shown) && !right)) {
        Action a = act(ACT_INSIDE, s.shown, right ? 1 : 0);
        a.x = (int16_t)x;
        a.y = (int16_t)y;
        a.dbl = dbl;
        return a;
    }
    return Action();
}

// Start open: what a click on (x, y) does.
inline Action startClick(const Scene& s, int x, int y) {
    using namespace PointerCore;
    const int sub = subHit(s.start, s.all, x, y);
    if (sub >= 0) {
        const int p = progOfSub(s.start.sub[sub]);
        return p >= 0 ? act(ACT_OPEN, p) : Action();         // Thêm / gỡ: no window drawn yet
    }
    if (s.all && s.start.subBox.has(x, y)) return Action();   // the sub-menu's frame / separator
    const int i = startHit(s.start, s.all, x, y);
    if (i >= 0) {
        switch (s.start.item[i]) {
            case S_ALL:       return act(ACT_START_ALL);
            case S_DESKTOP:   return act(ACT_SHOW_DESKTOP);
            case S_DEVICE:    return s.explorer ? act(ACT_OPEN, XPCore::PROG_EXPLORER, kPlaceComputer) : Action();
            case S_RESTART:
            case S_TURNOFF:   return act(ACT_TURNOFF_BOX);
            case S_STATS: case S_SETTINGS: case S_ADDREMOVE:
                return Action();                              // their windows are not drawn yet (plan Q1)
            default: {
                const int p = progOfItem(s.start.item[i]);
                return p >= 0 ? act(ACT_OPEN, p) : Action();
            }
        }
    }
    if (y >= kBarY && x < kStartRight) return act(ACT_START);   // the start button again: closes
    if (y < kBarY) return Action();                              // inside the menu's panel, between rows
    return act(ACT_START_CLOSE);
}

// A left click at (x, y) on [s]; [dbl] = it is the second of a double click.
inline Action leftClick(const Scene& s, int x, int y, bool dbl) {
    using namespace PointerCore;
    if (s.menu == XPCore::MENU_TURNOFF) {           // XP's box is modal: only its buttons
        switch (turnOffHit(x, y)) {
            case TO_STANDBY: return act(ACT_STANDBY);
            case TO_OFF:     return act(ACT_POWER_OFF);
            case TO_RESTART: return act(ACT_RESTART);
            case TO_CANCEL:  return act(ACT_TURNOFF_CLOSE);
            default:         return Action();
        }
    }
    if (s.menu == XPCore::MENU_START) return startClick(s, x, y);
    if (XPCore::contextMenu(s.menu)) return menuClick(s, x, y);
    if (s.menu != XPCore::MENU_NONE) return Action();            // the Alt+Tab box: keys only
    if (y >= kBarY) {
        if (x < kStartRight) return act(ACT_START);
        for (int i = 0; i < XPCore::slotsFor(s.bar.trayWeather); i++)
            if (s.bar.prog[i] >= 0 && hotRect((int8_t)i).has(x, y)) return act(ACT_TASKBAR, s.bar.prog[i]);
        if (s.bar.trayWeather && x >= kTrayIconX0 && x < kTrayIconX1) return act(ACT_OPEN, XPCore::PROG_WEATHER);
        if (x >= trayClockX(s.bar.trayWeather)) return act(ACT_OPEN, XPCore::PROG_CLOCK);
        return Action();
    }
    if (s.caption) {
        if (captionRect(kHotMin).has(x, y)) return act(ACT_MINIMIZE, s.shown);
        if (captionRect(kHotClose).has(x, y)) return act(ACT_CLOSE, s.shown);
        return inside(s, x, y, false, dbl);
    }
    if (s.desktop) {
        const int i = iconAt(s, x, y);
        if (i < 0) return act(ACT_SELECT);            // an empty spot drops the selection (XP)
        const int p = s.icons[i].prog;
        if (!dbl) return act(ACT_SELECT, p);
        if (p == XPCore::kDeskTrash) return s.explorer ? act(ACT_OPEN, XPCore::PROG_EXPLORER, kPlaceTrash) : Action();
        return act(ACT_OPEN, p);
    }
    return Action();
}

// A right click at (x, y) (XP): a taskbar button → its window's menu rising from the button; a title bar → the
// window's menu at the point; an empty spot of the desktop → the desktop menu there; an icon → selected (its own
// menu is not drawn). With a menu up: inside = as a left click, outside = it closes. Start / the box: nothing.
inline Action rightClick(const Scene& s, int x, int y, uint16_t minMask) {
    using namespace PointerCore;
    if (XPCore::contextMenu(s.menu)) return menuClick(s, x, y);
    if (s.menu != XPCore::MENU_NONE) return Action();
    if (y >= kBarY) {
        for (int i = 0; i < XPCore::slotsFor(s.bar.trayWeather); i++) {
            const int p = s.bar.prog[i];
            if (p >= 0 && hotRect((int8_t)i).has(x, y))
                return menuAt(XPCore::MENU_WINDOW, XPCore::buttonX(i), 213 - XPCore::menuH(XPCore::MENU_WINDOW), p,
                              (minMask >> p & 1) != 0);
        }
        // XP: the taskbar's empty part (between start and the tray) → the taskbar menu, rising from the bar.
        if (x >= kStartRight && x < XPCore::trayX(s.bar.trayWeather))
            return menuAt(XPCore::MENU_TASKBAR, x, 213 - XPCore::menuH(XPCore::MENU_TASKBAR));
        return Action();
    }
    if (s.caption && y < 22) return menuAt(XPCore::MENU_WINDOW, x, y, s.shown, false);
    if (s.caption) return inside(s, x, y, true);                 // Dò mìn: a flag
    if (s.desktop) {
        const int i = iconAt(s, x, y);
        if (i >= 0) return act(ACT_SELECT, s.icons[i].prog);
        return menuAt(XPCore::MENU_DESKTOP, x, y);
    }
    return Action();
}

// ── Keys (stage 3) ──
// Key datagram (7 bytes, UDP :4210): 'G' 'K' 1 seqHi seqLo mods key — sent 3 times with one seq.
constexpr uint8_t kKeyVersion = 1;
constexpr size_t kKeyLen = 7;
enum Mod : uint8_t { MOD_CTRL = 1, MOD_ALT = 2, MOD_SHIFT = 4 };
enum Key : uint8_t {
    KEY_NONE = 0, KEY_TAB, KEY_ENTER, KEY_ESC, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_F4, KEY_DELETE,
    KEY_BACKSPACE, KEY_WIN, KEY_COUNT
};
struct KeyPress { uint16_t seq = 0; uint8_t mods = 0; uint8_t key = KEY_NONE; };
inline bool parseKey(const uint8_t* p, size_t n, KeyPress& out) {
    if (!p || n != kKeyLen || p[0] != 'G' || p[1] != 'K' || p[2] != kKeyVersion) return false;
    if (p[5] > (MOD_CTRL | MOD_ALT | MOD_SHIFT) || p[6] == KEY_NONE || p[6] >= KEY_COUNT) return false;
    out.seq = (uint16_t)(p[3] << 8 | p[4]);
    out.mods = p[5];
    out.key = p[6];
    return true;
}
inline void encodeKey(const KeyPress& k, uint8_t out[kKeyLen]) {
    out[0] = 'G'; out[1] = 'K'; out[2] = kKeyVersion;
    out[3] = (uint8_t)(k.seq >> 8); out[4] = (uint8_t)k.seq; out[5] = k.mods; out[6] = k.key;
}

// The next item from [i] by [d] (±1) among the usable ones (XP skips dim items), wrapping; −1 = none usable.
inline int nextUsable(const Scene& s, int i, int d) {
    const int n = menuItems(s.menu);
    for (int k = 1; k <= n; k++) {
        const int start = i < 0 ? (d > 0 ? -1 : n) : i;
        const int j = ((start + d * k) % n + n) % n;
        if (menuEnabled(menuItem(s.menu, j), s.menuMin)) return j;
    }
    return -1;
}

// What key [k] with [mods] does on [s] ([shownProg] = the window on screen, [altTabUp] = the box is up).
inline Action keyAction(const Scene& s, uint8_t k, uint8_t mods, bool altTabUp) {
    using namespace PointerCore;
    if (k == KEY_TAB && (mods & MOD_ALT)) return act(ACT_ALTTAB, XPCore::PROG_NONE, (mods & MOD_SHIFT) ? -1 : 1);
    if (altTabUp) return k == KEY_ESC ? act(ACT_ALTTAB_CANCEL) : Action();
    if (k == KEY_DELETE && (mods & MOD_CTRL) && (mods & MOD_ALT)) return act(ACT_OPEN, XPCore::PROG_TASKMGR);
    if (k == KEY_WIN) return act(ACT_START);
    if (k == KEY_F4 && (mods & MOD_ALT)) {
        if (s.menu == XPCore::MENU_TURNOFF) return act(ACT_TURNOFF_CLOSE);
        if (s.shown >= 0 && !s.desktop) return act(ACT_CLOSE, s.shown);
        return s.desktop ? act(ACT_TURNOFF_BOX) : Action();          // XP: Alt+F4 on the desktop = Shut Down
    }
    // Stage 5: keys inside the XP program on screen (Esc / Enter / arrows / Delete / Backspace — the window decides).
    if (s.menu == XPCore::MENU_NONE && s.caption && !s.desktop && deviceWindow(s.shown) && s.shown != XPCore::PROG_MINES
        && s.shown != XPCore::PROG_CLOCK) {
        Action a = act(ACT_INSIDE_KEY, s.shown, k);
        a.x = mods;
        return a;
    }
    if (k == KEY_ESC) {
        if (s.menu == XPCore::MENU_TURNOFF) return act(ACT_TURNOFF_CLOSE);
        return s.menu != XPCore::MENU_NONE ? act(ACT_MENU_CLOSE) : Action();
    }
    if (XPCore::contextMenu(s.menu)) {
        switch (k) {
            case KEY_DOWN: case KEY_TAB: { const int j = nextUsable(s, s.hover, 1); return j < 0 ? Action() : act(ACT_HOVER, XPCore::PROG_NONE, j); }
            case KEY_UP: { const int j = nextUsable(s, s.hover, -1); return j < 0 ? Action() : act(ACT_HOVER, XPCore::PROG_NONE, j); }
            case KEY_ENTER: return s.hover >= 0 ? menuChoose(s, s.hover) : Action();
            default: return Action();
        }
    }
    if (s.menu == XPCore::MENU_START) {
        const int n = s.start.n;
        switch (k) {
            case KEY_DOWN: case KEY_TAB: return act(ACT_HOVER, XPCore::PROG_NONE, s.hover < 0 ? 0 : (s.hover + 1) % n);
            case KEY_UP: return act(ACT_HOVER, XPCore::PROG_NONE, s.hover <= 0 ? n - 1 : s.hover - 1);
            case KEY_ENTER: {
                if (s.hover < 0 || s.hover >= n) return Action();
                const Rect r = s.start.row[s.hover];
                Scene t = s;
                t.all = false;                                    // the row itself, not the sub-menu over it
                return startClick(t, r.x + r.w / 2, r.y + r.h / 2);
            }
            default: return Action();
        }
    }
    if (s.menu == XPCore::MENU_TURNOFF) {
        switch (k) {
            case KEY_LEFT: return act(ACT_HOVER, XPCore::PROG_NONE, s.hover <= 0 ? 2 : s.hover - 1);
            case KEY_RIGHT: case KEY_TAB: return act(ACT_HOVER, XPCore::PROG_NONE, s.hover < 0 ? 1 : (s.hover + 1) % 3);
            case KEY_ENTER: {
                const Rect r = turnOffButton(s.hover < 0 ? TO_OFF : s.hover);   // XP's default: Tắt
                Scene t = s;
                return leftClick(t, r.x + r.w / 2, r.y + r.h / 2, false);
            }
            default: return Action();
        }
    }
    if (s.desktop && s.nIcons > 0) {
        int i = -1;
        for (int j = 0; j < s.nIcons; j++) if (s.icons[j].prog == s.sel && s.sel != XPCore::PROG_NONE) i = j;
        switch (k) {
            case KEY_DOWN: case KEY_RIGHT: case KEY_TAB:
                return act(ACT_SELECT, s.icons[i < 0 ? 0 : (i + 1 < s.nIcons ? i + 1 : i)].prog);
            case KEY_UP: case KEY_LEFT:
                return act(ACT_SELECT, s.icons[i <= 0 ? 0 : i - 1].prog);
            case KEY_ENTER:
                if (i < 0) return Action();
                if (s.icons[i].prog == XPCore::kDeskTrash)
                    return s.explorer ? act(ACT_OPEN, XPCore::PROG_EXPLORER, kPlaceTrash) : Action();
                return act(ACT_OPEN, s.icons[i].prog);
            default: return Action();
        }
    }
    return Action();
}

// The cursor over (x, y): XP's hand on what a click acts on (taskbar buttons, start, the tray, _ / ×, Start rows,
// Tắt máy tính's buttons); the arrow elsewhere (XP keeps the arrow over desktop icons).
inline CursorCore::Shape shapeAt(const Scene& s, int x, int y) {
    using namespace PointerCore;
    if (s.menu == XPCore::MENU_TURNOFF) return turnOffHit(x, y) >= 0 ? CursorCore::SHAPE_HAND : CursorCore::SHAPE_ARROW;
    if (s.menu == XPCore::MENU_START) {
        const bool row = subHit(s.start, s.all, x, y) >= 0 || startHit(s.start, s.all, x, y) >= 0;
        return row || (y >= kBarY && x < kStartRight) ? CursorCore::SHAPE_HAND : CursorCore::SHAPE_ARROW;
    }
    if (XPCore::contextMenu(s.menu)) {
        bool inside = false;
        const int i = menuItemAt(s.menu, s.menuX, s.menuY, x, y, inside);
        return i >= 0 && menuEnabled(menuItem(s.menu, i), s.menuMin) ? CursorCore::SHAPE_HAND : CursorCore::SHAPE_ARROW;
    }
    if (s.menu != XPCore::MENU_NONE) return CursorCore::SHAPE_ARROW;
    const Action a = leftClick(s, x, y, false);
    switch (a.kind) {
        case ACT_START: case ACT_TASKBAR: case ACT_MINIMIZE: case ACT_CLOSE: case ACT_OPEN:
            return CursorCore::SHAPE_HAND;
        default:
            return CursorCore::SHAPE_ARROW;
    }
}

}  // namespace InputCore
