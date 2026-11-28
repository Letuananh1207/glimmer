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
// What the device acts on so far (`/api/state` `input.stage`): 1 = desktop, taskbar, _ / ×, Start, Tắt máy tính.
constexpr uint8_t kStage = 1;
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
    ACT_MENU_CLOSE,    // a click outside a context menu (stage 3; menus are still the app's)
};

struct Action {
    Act kind = ACT_NONE;
    int8_t prog = XPCore::PROG_NONE;
    int8_t arg = -1;
};
inline Action act(Act k, int prog = XPCore::PROG_NONE, int arg = -1) {
    Action a; a.kind = k; a.prog = (int8_t)prog; a.arg = (int8_t)arg; return a;
}

constexpr int8_t kPlaceComputer = 0, kPlaceTrash = 2;

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
    // Context menus / the Alt+Tab box: still the app's until stage 3 (it picks the item) — the device leaves them.
    if (s.menu != XPCore::MENU_NONE) return Action();
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
        return Action();                              // the window's inside: later stages
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

// The cursor over (x, y): XP's hand on what a click acts on (taskbar buttons, start, the tray, _ / ×, Start rows,
// Tắt máy tính's buttons); the arrow elsewhere (XP keeps the arrow over desktop icons).
inline CursorCore::Shape shapeAt(const Scene& s, int x, int y) {
    using namespace PointerCore;
    if (s.menu == XPCore::MENU_TURNOFF) return turnOffHit(x, y) >= 0 ? CursorCore::SHAPE_HAND : CursorCore::SHAPE_ARROW;
    if (s.menu == XPCore::MENU_START) {
        const bool row = subHit(s.start, s.all, x, y) >= 0 || startHit(s.start, s.all, x, y) >= 0;
        return row || (y >= kBarY && x < kStartRight) ? CursorCore::SHAPE_HAND : CursorCore::SHAPE_ARROW;
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
