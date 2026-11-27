#pragma once
// What the mouse cursor is over (P-2026-11-27.24, screen_specs §17 XP-Pointer) — pure, host-tested.
//
// The app is the mouse; the device knows where every Start menu row, Tắt máy tính button, taskbar
// button and caption button is, so it lights the one under the cursor itself (as XP's hot tracking).
// The app may also pick a row (arrow keys): its hover wins over the cursor's.
//
//   Start menu (xp_start.cpp)   hover = left column (pinned Claude / Codex when the agent skill is on,
//                               then the 3 most frequently used (P-.25), Tất cả chương trình), then the
//                               right column (Desktop, Số liệu, Cài đặt, Thêm / gỡ, Thiết bị), then the
//                               bottom band (Khởi động lại, Tắt máy); sub = the All Programs sub-menu
//                               (every installed program, Thêm / gỡ; P-2026-11-27.25)
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
    S_CLAUDE, S_CODEX,                                                     // left column: pinned
    S_PHOTO, S_WEATHER, S_CLOCK, S_MINES, S_AI, S_TREND, S_AGENTS,         //   most frequently used (3)
    S_ALL,
    S_DESKTOP, S_STATS, S_SETTINGS, S_ADDREMOVE, S_DEVICE,                 // right column
    S_RESTART, S_TURNOFF,                                                  // bottom band
    S_ITEM_COUNT,
};

// Sub-menu rows (P-2026-11-27.25): every installed program in this order, then Thêm / gỡ.
enum SubItem : uint8_t {
    SUB_CLAUDE, SUB_CODEX, SUB_AI, SUB_TREND, SUB_AGENTS, SUB_PHOTO, SUB_WEATHER, SUB_CLOCK, SUB_MINES,
    SUB_ADDREMOVE, SUB_COUNT
};

constexpr int kStartMaxItems = S_ITEM_COUNT;

struct StartLayout {
    int n = 0;                              // items, in hover order
    uint8_t item[kStartMaxItems] = {};      // StartItem
    Rect row[kStartMaxItems];               // the lit band
    int subN = 0;
    uint8_t sub[SUB_COUNT] = {};            // SubItem
    Rect subRow[SUB_COUNT];
    Rect subBox;                            // the sub-menu's frame (144, top, 96 × h)
};

// What the Start menu shows: installed programs (XPCore::installedOf) and the 3 opened last.
struct StartInputs {
    XPCore::Installed in{};
    int8_t recent[XPCore::kRecentN] = {XPCore::PROG_NONE, XPCore::PROG_NONE, XPCore::PROG_NONE};
};

inline StartItem startItemOf(int prog) {
    switch (prog) {
        case XPCore::PROG_PHOTO:   return S_PHOTO;
        case XPCore::PROG_WEATHER: return S_WEATHER;
        case XPCore::PROG_CLOCK:   return S_CLOCK;
        case XPCore::PROG_MINES:   return S_MINES;
        case XPCore::PROG_AI:      return S_AI;
        case XPCore::PROG_TREND:   return S_TREND;
        default:                   return S_AGENTS;
    }
}

// Program a left-column / sub-menu row opens; PROG_NONE for the others.
inline int progOfItem(int item) {
    switch (item) {
        case S_CLAUDE: return XPCore::PROG_CLAUDE;   case S_CODEX: return XPCore::PROG_CODEX;
        case S_PHOTO: return XPCore::PROG_PHOTO;     case S_WEATHER: return XPCore::PROG_WEATHER;
        case S_CLOCK: return XPCore::PROG_CLOCK;     case S_MINES: return XPCore::PROG_MINES;
        case S_AI: return XPCore::PROG_AI;           case S_TREND: return XPCore::PROG_TREND;
        case S_AGENTS: return XPCore::PROG_AGENTS;
        default: return XPCore::PROG_NONE;
    }
}
inline int progOfSub(int sub) {
    static const int8_t kProg[SUB_COUNT] = {
        XPCore::PROG_CLAUDE, XPCore::PROG_CODEX, XPCore::PROG_AI, XPCore::PROG_TREND, XPCore::PROG_AGENTS,
        XPCore::PROG_PHOTO, XPCore::PROG_WEATHER, XPCore::PROG_CLOCK, XPCore::PROG_MINES, XPCore::PROG_NONE};
    return sub >= 0 && sub < SUB_COUNT ? kProg[sub] : XPCore::PROG_NONE;
}

// Rows (source XP-Start-All-Full / XP-Start-Recent / XP-Hover-Start): pinned rows 28 tall from y 36,
// the 3 most frequently used 20 tall from y 99 (38 without the pins), All Programs (2, 167); right
// column 21 tall from y 38, a separator step of 8 after Số liệu; bottom buttons 16 px + label. The
// sub-menu (144, top, 96 wide, P-2026-11-27.25): rows 20 tall from top + 2, lit band (145, row, 94×20),
// Thêm / gỡ after a 7-px separator; top y 62, moved up until its bottom is ≤ 213.
inline void startLayout(const StartInputs& si, StartLayout& L) {
    using namespace XPCore;
    L = StartLayout();
    const Installed& in = si.in;
    auto add = [&L](StartItem it, Rect r) { L.item[L.n] = it; L.row[L.n] = r; L.n++; };
    if (in.agent) {
        add(S_CLAUDE, rect(2, 36, 149, 28));
        add(S_CODEX, rect(2, 64, 149, 28));
    }
    int8_t rows[kRecentN];
    const int nr = recentRows(si.recent, in, rows);
    int y = in.agent ? 99 : 38;
    for (int i = 0; i < nr; i++, y += 20) add(startItemOf(rows[i]), rect(2, y, 149, 20));
    add(S_ALL, rect(2, 167, 149, 20));
    add(S_DESKTOP, rect(154, 38, 84, 21));
    add(S_STATS, rect(154, 59, 84, 21));
    add(S_SETTINGS, rect(154, 88, 84, 21));
    add(S_ADDREMOVE, rect(154, 109, 84, 21));
    add(S_DEVICE, rect(154, 130, 84, 21));
    add(S_RESTART, rect(4, 192, 116, 20));                 // button 16 at (8, 194) + "Khởi động lại"
    add(S_TURNOFF, rect(161, 192, 76, 20));                // button 16 at (165, 194) + "Tắt máy"
    for (int s = 0; s < SUB_ADDREMOVE; s++)
        if (installed(in, progOfSub(s))) L.sub[L.subN++] = (uint8_t)s;
    const int h = 4 + 20 * L.subN + 7 + 20;
    const int top = 213 - h < 62 ? 213 - h : 62;
    for (int i = 0; i < L.subN; i++) L.subRow[i] = rect(145, top + 2 + 20 * i, 94, 20);
    L.sub[L.subN] = SUB_ADDREMOVE;
    L.subRow[L.subN] = rect(145, top + 2 + 20 * L.subN + 7, 94, 20);
    L.subN++;
    L.subBox = rect(144, top, 96, h);
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
