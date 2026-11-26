#pragma once
// Remote control from the app (design 2026-11-26.5, ControlScreen) — pure
// logic, host-tested. main.cpp owns the state; web.cpp exposes it:
//   POST /api/channel {"action":"prev"|"pause"|"resume"}, POST /api/screen {"on":bool},
//   /api/state paused, screen_on, slide_ms, slide_left_ms.
//
// R-DK-4: the pause is temporary — RAM only, gone after a reboot, the saved
// `autoRotate` setting is never touched. Screen off likewise.
#include <stdint.h>
#include <string.h>
#include "attention_core.h"

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

}  // namespace Control
