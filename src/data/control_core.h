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
    bool all = false;              // Start menu: All Programs open (P-2026-11-26.20)
    // Item lit (R-DK-18/19): under the mouse cursor or chosen with the arrow
    // keys — index among the items (separators not counted), -1 = none.
    int8_t hover = -1;
    // Start menu with All Programs open: the sub-menu row lit (pointer_core.h order), -1 = none.
    int8_t sub = -1;
};

// ── Power (R-DK-20): the app's power button ────────────────────────────────
// Off = the "computer" is off: the screen goes dark (the device itself keeps
// running, so it still takes commands and an urgent / approval card still
// wakes it, like the screen-off of /api/screen). On = boot screen, then the
// desktop with no window open (as a fresh start of the app).
// P-2026-11-27.24: shutting = XP's "đang tắt máy..." screen; booting = the boot screen, then the
// welcome screen 1 s (POWER_WELCOME, still reported "booting"), then the desktop. Restart (Tắt máy
// tính › Khởi động lại) = shutting, then booting instead of off.
enum Power : uint8_t { POWER_ON = 0, POWER_SHUTTING, POWER_OFF, POWER_BOOTING, POWER_WELCOME };

constexpr uint32_t kShutMs    = 1500;   // "đang tắt máy..." → off
constexpr uint32_t kBootMs    = 2400;   // boot screen → welcome (12 steps of the 200-ms block box)
constexpr uint32_t kWelcomeMs = 1000;   // welcome → desktop

struct PowerState {
    Power    p = POWER_ON;
    uint32_t since = 0;               // millis the state began
    bool     restart = false;         // shutting down to boot again
};

// The power button: on / off asked. True when the state changed. Pressing
// "off" while booting, or "on" while shutting down, turns around at once.
inline bool requestPower(PowerState& s, bool on, uint32_t now) {
    const bool isOn = s.p == POWER_ON || s.p == POWER_BOOTING || s.p == POWER_WELCOME;
    if (!on && s.p == POWER_SHUTTING && s.restart) { s.restart = false; return true; }   // off: no boot after
    if (on == isOn) return false;
    s.p = on ? POWER_BOOTING : POWER_SHUTTING;
    s.since = now;
    s.restart = false;
    return true;
}

// Khởi động lại: shut down, then boot again. Only from on (no-op while already going down / up).
inline bool requestRestart(PowerState& s, uint32_t now) {
    if (s.p != POWER_ON) return false;
    s.p = POWER_SHUTTING;
    s.since = now;
    s.restart = true;
    return true;
}

// Time passing: shutting → off (or booting on a restart), booting → welcome → on. True when the
// state changed.
inline bool advancePower(PowerState& s, uint32_t now) {
    if (s.p == POWER_SHUTTING && now - s.since >= kShutMs) {
        s.p = s.restart ? POWER_BOOTING : POWER_OFF;
        s.restart = false;
        s.since = now;
        return true;
    }
    if (s.p == POWER_BOOTING && now - s.since >= kBootMs) { s.p = POWER_WELCOME; s.since = now; return true; }
    if (s.p == POWER_WELCOME && now - s.since >= kWelcomeMs) { s.p = POWER_ON; s.since = now; return true; }
    return false;
}

// The power screens own the panel (no window tick, no taskbar, no cursor).
inline bool powerScreen(Power p) { return p == POWER_SHUTTING || p == POWER_BOOTING || p == POWER_WELCOME; }

inline const char* powerName(Power p) {
    switch (p) {
        case POWER_SHUTTING: return "shutting";
        case POWER_OFF:      return "off";
        case POWER_BOOTING:
        case POWER_WELCOME:  return "booting";
        default:             return "on";
    }
}

// Same menu in the same place, at most another item lit: only the menu
// repaints (no repaint of the screen under it).
inline bool sameMenu(const Menu& a, const Menu& b) {
    return a.kind == b.kind && a.x == b.x && a.y == b.y && a.minimized == b.minimized && a.all == b.all;
}

// Same as [sameMenu], with also the same item lit: nothing to repaint.
inline bool sameLit(const Menu& a, const Menu& b) {
    return sameMenu(a, b) && a.hover == b.hover && a.sub == b.sub;
}

}  // namespace Control
