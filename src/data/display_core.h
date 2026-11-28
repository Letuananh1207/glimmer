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

// Plan thiet-bi-la-may-tinh stage 5 (R-DK-26, was the app's): what a click on the window hits and what it edits.
enum HitKind : uint8_t {
    HIT_NONE, HIT_TAB, HIT_WALL, HIT_TOGGLE_LIST, HIT_SAVER, HIT_CLOSE_LIST, HIT_IDLE, HIT_BRIGHT, HIT_INVERT,
    HIT_OK, HIT_CANCEL, HIT_APPLY,
};
struct Hit { uint8_t kind = HIT_NONE; int8_t value = 0; };
// The brightness the slider gives at [x] (track x 20…127), 5–100.
inline int8_t brightAt(int x) {
    const int v = ((x - 20) * 100 + 53) / 107;
    return (int8_t)(v < 5 ? 5 : v > 100 ? 100 : v);
}
inline Hit hitAt(const View& v, const Saved& s, bool photo, int x, int y) {
    Hit h;
    auto in = [x, y](int bx, int by, int w, int hh) { return x >= bx && x < bx + w && y >= by && y < by + hh; };
    auto mk = [&h](uint8_t k, int val = 0) { h.kind = k; h.value = (int8_t)val; return h; };
    if (v.tab == TAB_SAVER && v.list) {                  // the open mode list lies over the page
        if (in(97, 80, 130, 64)) return mk(HIT_SAVER, (y - 80) / 16);
        return mk(HIT_CLOSE_LIST);
    }
    if (y >= 26 && y <= 41) {
        static const uint8_t kX[3] = {6, 63, 176}, kW[3] = {57, 113, 57};
        for (int i = 0; i < 3; i++) if (x >= kX[i] && x < kX[i] + kW[i]) return mk(HIT_TAB, i);
        return h;
    }
    const Rect ok = button(BTN_OK), cancel = button(BTN_CANCEL), apply = button(BTN_APPLY);
    if (in(ok.x, ok.y, ok.w, ok.h)) return mk(HIT_OK);
    if (in(cancel.x, cancel.y, cancel.w, cancel.h)) return mk(HIT_CANCEL);
    if (in(apply.x, apply.y, apply.w, apply.h)) return dirty(v, s) ? mk(HIT_APPLY) : h;
    if (v.tab == TAB_DESKTOP) {
        if (in(97, 63, 130, 16 * wallRows(photo))) return mk(HIT_WALL, (y - 63) / 16);
    } else if (v.tab == TAB_SAVER) {
        if (in(96, 61, 132, 18)) return mk(HIT_TOGGLE_LIST);
        if (in(16, 152, 168, 14)) return mk(HIT_IDLE);
    } else {
        if (in(14, 136, 120, 22)) return mk(HIT_BRIGHT, brightAt(x));
        if (in(148, 158, 78, 14)) return mk(HIT_INVERT);
    }
    return h;
}
// [v] after a click on [h] that only edits (tab, values, the list); OK / Hủy / Áp dụng are the caller's.
inline View edit(View v, const Saved& s, const Hit& h) {
    const Shown o = shown(v, s);
    switch (h.kind) {
        case HIT_TAB:         v.tab = (uint8_t)h.value; v.list = false; break;
        case HIT_WALL:        v.wall = h.value; break;
        case HIT_TOGGLE_LIST: v.list = !v.list; break;
        case HIT_SAVER:       v.saver = h.value; v.list = false; break;
        case HIT_CLOSE_LIST:  v.list = false; break;
        case HIT_IDLE:        v.idle = o.idle ? 0 : 1; break;
        case HIT_BRIGHT:      v.bright = h.value; break;
        case HIT_INVERT:      v.invert = o.invert ? 0 : 1; break;
        default: break;
    }
    return v;
}

}  // namespace DisplayCore
