#pragma once
// Remote control from the app (design 2026-11-26.5 / .6 / .7, ControlScreen;
// panel P-2026-11-26.14) — pure logic, host-tested. main.cpp owns the state;
// web.cpp exposes it:
//   POST /api/channel {"name"} | {"action":"prev"|"pause"|"resume"}, POST /api/screen {"on":bool},
//   POST /api/windows {open, top, min, sel}, POST /api/menu {kind, x, y, minimized},
//   /api/state paused, screen_on, windows, menu.
//
// All RAM only, gone after a reboot. The device never rotates channels on its
// own (P-2026-11-26.14): it shows the window the app opened.
#include <stdint.h>
#include <string.h>
#include "attention_core.h"
#include "xp_core.h"

namespace Control {

// Channel before [ptr] among [count] (wraps); -1 when there is none.
inline int prevIndex(int ptr, int count) {
    if (count <= 0) return -1;
    if (ptr <= 0 || ptr >= count) return count - 1;
    return ptr - 1;
}

// Rotation clock with a pause. While paused, the slide's elapsed time is
// frozen (the taskbar progress stops where it was); resume continues from
// there, so the slide gets only what it had left.
struct Rotation {
    bool     paused = false;
    uint32_t frozen = 0;          // elapsed ms at pause time
};

inline uint32_t elapsed(const Rotation& r, uint32_t now, uint32_t lastSlide) {
    return r.paused ? r.frozen : now - lastSlide;
}

// Pause: freeze what had elapsed (capped at the slide). Idempotent.
inline void pause(Rotation& r, uint32_t now, uint32_t lastSlide, uint32_t slideMs) {
    if (r.paused) return;
    uint32_t e = now - lastSlide;
    r.frozen = e > slideMs ? slideMs : e;
    r.paused = true;
}

// Resume: returns the new lastSlide (now − frozen). Not paused → lastSlide.
inline uint32_t resume(Rotation& r, uint32_t now, uint32_t lastSlide) {
    if (!r.paused) return lastSlide;
    r.paused = false;
    return now - r.frozen;
}

// A new slide started (manual next / prev / show, a recompute): a paused
// rotation stays paused at the start of the new slide.
inline void restart(Rotation& r) { r.frozen = 0; }

// What remains of the slide (0 when it is over or there is no slide).
inline uint32_t slideLeft(uint32_t elapsedMs, uint32_t slideMs) {
    return elapsedMs >= slideMs ? 0 : slideMs - elapsedMs;
}

// Screen turned off from the app: which cards light it again while they hold
// the screen — like a dark night (CLAUDE.md "Stale data & night modes"),
// except that an agent waiting on the user always wakes it (the app user
// asked for the screen off, not for agents to be hidden): urgent, an
// approval / question, a user's own error card (agent other, not sys:*).
inline bool wakesScreen(const Attention::Item& it) {
    if (it.urgent) return true;
    if (it.kind == Attention::K_APPROVAL || it.kind == Attention::K_INPUT) return true;
    return it.kind == Attention::K_ERROR && it.agent == Attention::AGENT_OTHER
        && strncmp(it.id, "sys:", 4) != 0;
}

// Backlight % with the app's screen-off applied on top of the night / idle rules.
inline int brightness(int pct, bool screenOff, bool wake) {
    return screenOff && !wake ? 0 : pct;
}

// ── Open windows (the app is the computer, the device its screen) ──
// Opening order (= taskbar order), the top window (PROG_NONE = the desktop),
// minimized ones, and the selected desktop icon. Sent whole by the app;
// [adopt] covers a channel opened without it (web UI, MCP).
struct Windows {
    int8_t   open[XPCore::PROG_COUNT];
    uint8_t  n       = 0;
    int8_t   top     = XPCore::PROG_NONE;
    uint16_t minMask = 0;
    int8_t   sel     = XPCore::PROG_NONE;
};

inline bool isOpen(const Windows& w, int p) {
    for (int i = 0; i < w.n; i++) if (w.open[i] == p) return true;
    return false;
}

// [p] shows on its own: open it (at the end) if it is not, put it on top.
inline void adopt(Windows& w, int p) {
    if (p < 0 || p >= XPCore::PROG_COUNT) return;
    if (!isOpen(w, p) && w.n < XPCore::PROG_COUNT) w.open[w.n++] = (int8_t)p;
    w.top = (int8_t)p;
    w.minMask &= (uint16_t)~(1u << p);
    w.sel = XPCore::PROG_NONE;
}

// Add [p] to a list being rebuilt from the app (no duplicates, unknown names skipped).
inline void addOpen(Windows& w, int p) {
    if (p >= 0 && p < XPCore::PROG_COUNT && !isOpen(w, p)) w.open[w.n++] = (int8_t)p;
}

// Windows of programs that are no longer installed go (a skill turned off).
template <typename Keep>
inline void prune(Windows& w, Keep keep) {
    uint8_t k = 0;
    for (int i = 0; i < w.n; i++) if (keep(w.open[i])) w.open[k++] = w.open[i];
    w.n = k;
    if (w.top >= 0 && !keep(w.top)) w.top = XPCore::PROG_NONE;
}

// A context menu on screen (drawn over the current window / desktop).
struct Menu {
    XPCore::MenuKind kind = XPCore::MENU_NONE;
    int16_t x = 0, y = 0;          // top-left, clamped inside y ≤ 213
    bool minimized = false;        // window menu of a minimized window: Khôi phục lit, Thu nhỏ dim
};

}  // namespace Control
