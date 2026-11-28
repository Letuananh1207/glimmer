#pragma once
// Display Properties (P-2026-11-28.30, XP-Display) — what the app touched in the window, pure, host-tested.
// As XP, changes wait in the dialog until OK / Áp dụng: the app keeps the pending values and sends them
// (POST /api/display); OK / Áp dụng = the app saving them (POST /api/settings, one place with the app's
// settings screen). A value the app did not send (−1) = the saved setting.
#include <stdint.h>

namespace DisplayCore {

enum Tab : uint8_t { TAB_DESKTOP, TAB_SAVER, TAB_SETTINGS, TAB_COUNT };
enum Btn : int8_t { BTN_NONE = -1, BTN_OK, BTN_CANCEL, BTN_APPLY, BTN_BROWSE };

struct View {
    uint8_t tab = TAB_DESKTOP;
    int8_t  wall = -1;        // Wallpaper::Mode pending (0 (Không), 1 Đồi xanh, 2 Ảnh của bạn)
    int8_t  saver = -1;       // nightMode pending (0..3)
    bool    list = false;     // Bảo vệ màn hình: the mode list is open
    int8_t  bright = -1;      // brightness % pending (5..100)
    int8_t  invert = -1;      // invertDisplay pending (0 / 1)
    int8_t  idle = -1;        // idleDim pending (0 / 1)
    int8_t  down = BTN_NONE;  // a button held down (the app's click)
};

// The saved values the window starts from.
struct Saved { uint8_t wall, saver, bright; bool invert, idle; };

// What the window shows: pending when sent, else saved.
struct Shown { uint8_t wall, saver, bright; bool invert, idle; };
inline Shown shown(const View& v, const Saved& s) {
    Shown o;
    o.wall   = v.wall   >= 0 ? (uint8_t)v.wall   : s.wall;
    o.saver  = v.saver  >= 0 ? (uint8_t)v.saver  : s.saver;
    o.bright = v.bright >= 0 ? (uint8_t)v.bright : s.bright;
    o.invert = v.invert >= 0 ? v.invert != 0 : s.invert;
    o.idle   = v.idle   >= 0 ? v.idle != 0   : s.idle;
    return o;
}
// Áp dụng lights only with a change not saved yet (XP).
inline bool dirty(const View& v, const Saved& s) {
    const Shown o = shown(v, s);
    return o.wall != s.wall || o.saver != s.saver || o.bright != s.bright || o.invert != s.invert
        || o.idle != s.idle;
}

// Màn nền list rows: (Không), Đồi xanh, and Ảnh của bạn only when a wallpaper photo is set.
inline int wallRows(bool photo) { return photo ? 3 : 2; }

// Brightness slider (Cài đặt): track x 20..127; the thumb's centre for [pct] and the 11 ticks.
constexpr int kSlideX = 20, kSlideW = 107;
inline int thumbX(uint8_t pct) { return kSlideX + (pct * kSlideW + 50) / 100; }
inline int tickX(int i) { return kSlideX + (i * kSlideW + 5) / 10; }

// The buttons along the bottom (y 187, 21 tall): OK, Hủy, Áp dụng; Duyệt... on Màn nền.
struct Rect { int16_t x, y, w, h; };
inline Rect button(int b) {
    switch (b) {
        case BTN_OK:     return {53, 187, 49, 21};
        case BTN_CANCEL: return {106, 187, 49, 21};
        case BTN_APPLY:  return {159, 187, 70, 21};
        default:         return {163, 120, 65, 21};
    }
}
// The button under (x, y) that can light (Áp dụng only when [applyOn]; Duyệt... never — dim), else BTN_NONE.
inline int8_t hotAt(int x, int y, bool applyOn) {
    for (int b = BTN_OK; b <= BTN_APPLY; b++) {
        if (b == BTN_APPLY && !applyOn) continue;
        const Rect r = button(b);
        if (x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h) return (int8_t)b;
    }
    return BTN_NONE;
}

}  // namespace DisplayCore
