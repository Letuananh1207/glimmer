#pragma once
// What the mouse cursor is over (P-2026-11-27.24, screen_specs §17 XP-Pointer) — pure, host-tested.
//
// The app is the mouse; the device knows where every Start menu row, Tắt máy tính button, taskbar
// button and caption button is, so it lights the one under the cursor itself (as XP's hot tracking).
// The app may also pick a row (arrow keys): its hover wins over the cursor's.
//
//   Start menu (xp_start.cpp)   hover = left column (pinned Claude / Codex when the agent skill is on,
//                               then Ảnh / Thời tiết / Đồng hồ by skill, Tất cả chương trình), then the
//                               right column (Desktop, Số liệu, Cài đặt, Thêm / gỡ, Thiết bị), then the
//                               bottom band (Khởi động lại, Tắt máy); sub = the All Programs sub-menu
//                               (installed programs, Thêm / gỡ)
//   Tắt máy tính (xp_turnoff)   0 Chờ, 1 Tắt, 2 Khởi động lại, 3 Hủy
//   hot (taskbar, title bar)    a taskbar slot, the _ or × caption button
#include <stdint.h>
#include "xp_core.h"

namespace PointerCore {

struct Rect {
    int16_t x = 0, y = 0, w = 0, h = 0;
    bool has(int px, int py) const { return w > 0 && px >= x && px < x + w && py >= y && py < y + h; }
};

inline Rect rect(int x, int y, int w, int h) {
    Rect r; r.x = (int16_t)x; r.y = (int16_t)y; r.w = (int16_t)w; r.h = (int16_t)h; return r;
}

// ── Start menu ──────────────────────────────────────────────────────────────

enum StartItem : uint8_t {
    S_CLAUDE, S_CODEX, S_PHOTO, S_WEATHER, S_CLOCK, S_ALL,                 // left column
    S_DESKTOP, S_STATS, S_SETTINGS, S_ADDREMOVE, S_DEVICE,                 // right column
    S_RESTART, S_TURNOFF,                                                  // bottom band
    S_ITEM_COUNT,
};

// Sub-menu rows: the programs (Claude, Codex, Ảnh, Thời tiết, Đồng hồ by skill) then Thêm / gỡ.
enum SubItem : uint8_t { SUB_CLAUDE, SUB_CODEX, SUB_PHOTO, SUB_WEATHER, SUB_CLOCK, SUB_ADDREMOVE, SUB_COUNT };

constexpr int kStartMaxItems = S_ITEM_COUNT;

struct StartLayout {
    int n = 0;                              // items, in hover order
    uint8_t item[kStartMaxItems] = {};      // StartItem
    Rect row[kStartMaxItems];               // the lit band
    int subN = 0;
    uint8_t sub[SUB_COUNT] = {};            // SubItem
    Rect subRow[SUB_COUNT];
    Rect subBox;                            // the sub-menu's frame (151, 62, 89 × h)
};

// Rows by skill (source XP-Start-All / XP-Hover-Start): pinned rows 28 tall from y 36, others 20 tall
// from y 99, All Programs (2, 167); right column 21 tall from y 38, a separator step of 8 after Số liệu;
// bottom buttons 16 px + label; the sub-menu rows 20 tall from y 64, Thêm / gỡ after a 7-px separator.
inline void startLayout(bool agent, bool photo, bool weather, bool clock, StartLayout& L) {
    L = StartLayout();
    auto add = [&L](StartItem it, Rect r) { L.item[L.n] = it; L.row[L.n] = r; L.n++; };
    if (agent) {
        add(S_CLAUDE, rect(2, 36, 149, 28));
        add(S_CODEX, rect(2, 64, 149, 28));
    }
    int y = agent ? 99 : 38;
    if (photo)   { add(S_PHOTO, rect(2, y, 149, 20));   y += 20; }
    if (weather) { add(S_WEATHER, rect(2, y, 149, 20)); y += 20; }
    if (clock)   { add(S_CLOCK, rect(2, y, 149, 20));   y += 20; }
    add(S_ALL, rect(2, 167, 149, 20));
    add(S_DESKTOP, rect(154, 38, 84, 21));
    add(S_STATS, rect(154, 59, 84, 21));
    add(S_SETTINGS, rect(154, 88, 84, 21));
    add(S_ADDREMOVE, rect(154, 109, 84, 21));
    add(S_DEVICE, rect(154, 130, 84, 21));
    add(S_RESTART, rect(4, 192, 116, 20));                 // button 16 at (8, 194) + "Khởi động lại"
    add(S_TURNOFF, rect(161, 192, 76, 20));                // button 16 at (165, 194) + "Tắt máy"
    auto sub = [&L](SubItem it, Rect r) { L.sub[L.subN] = it; L.subRow[L.subN] = r; L.subN++; };
    y = 64;
    if (agent)   { sub(SUB_CLAUDE, rect(152, y, 87, 20)); y += 20; sub(SUB_CODEX, rect(152, y, 87, 20)); y += 20; }
    if (photo)   { sub(SUB_PHOTO, rect(152, y, 87, 20));   y += 20; }
    if (weather) { sub(SUB_WEATHER, rect(152, y, 87, 20)); y += 20; }
    if (clock)   { sub(SUB_CLOCK, rect(152, y, 87, 20));   y += 20; }
    y += 7;
    sub(SUB_ADDREMOVE, rect(152, y, 87, 20));
    L.subBox = rect(151, 62, 89, y + 20 + 2 - 62);
}

// The item under (x, y): its index in hover order, -1 = none. With All Programs open the sub-menu lies
// over the right column, so the right column is not under it there.
inline int startHit(const StartLayout& L, bool all, int x, int y) {
    if (all && L.subBox.has(x, y)) return -1;
    for (int i = 0; i < L.n; i++) if (L.row[i].has(x, y)) return i;
    return -1;
}

inline int subHit(const StartLayout& L, bool all, int x, int y) {
    if (!all) return -1;
    for (int i = 0; i < L.subN; i++) if (L.subRow[i].has(x, y)) return i;
    return -1;
}

inline int startIndexOf(const StartLayout& L, StartItem it) {
    for (int i = 0; i < L.n; i++) if (L.item[i] == it) return i;
    return -1;
}

// ── Tắt máy tính (XP Turn off computer) ─────────────────────────────────────

enum TurnOffButton : int8_t { TO_STANDBY = 0, TO_OFF, TO_RESTART, TO_CANCEL, TO_COUNT };

// The three round-cornered buttons 24×24 centred on x 50 / 120 / 190, y 90; Hủy (164, 151, 54×21).
inline Rect turnOffButton(int i) {
    if (i == TO_CANCEL) return rect(164, 151, 54, 21);
    if (i < 0 || i > TO_CANCEL) return Rect();
    return rect(38 + 70 * i, 90, 24, 24);
}

inline int turnOffHit(int x, int y) {
    for (int i = 0; i < TO_COUNT; i++) if (turnOffButton(i).has(x, y)) return i;
    return -1;
}

// ── Hot buttons (XP Luna hot tracking) ──────────────────────────────────────

constexpr int8_t kHotNone = -1, kHotMin = 10, kHotClose = 11;   // 0.. = taskbar slot

inline Rect captionRect(int8_t hot) {
    if (hot == kHotMin) return rect(184, 3, 16, 16);
    if (hot == kHotClose) return rect(220, 3, 16, 16);
    return Rect();
}

inline Rect hotRect(int8_t hot) {
    if (hot >= 0 && hot < XPCore::kSlots) return rect(XPCore::buttonX(hot), XPCore::kBtnY, XPCore::kBtnW, XPCore::kBtnH);
    return captionRect(hot);
}

// What is hot under (x, y): a taskbar button holding a window ([bar]), or — on a screen with a title
// bar ([caption]) — its _ / × button. The □ button is always off and never lights; neither does start.
inline int8_t hotAt(const XPCore::BarState& bar, bool caption, int x, int y) {
    for (int i = 0; i < XPCore::slotsFor(bar.trayWeather); i++)
        if (bar.prog[i] >= 0 && hotRect((int8_t)i).has(x, y)) return (int8_t)i;
    if (caption) {
        if (captionRect(kHotMin).has(x, y)) return kHotMin;
        if (captionRect(kHotClose).has(x, y)) return kHotClose;
    }
    return kHotNone;
}

}  // namespace PointerCore
