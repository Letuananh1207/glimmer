#pragma once
// XP taskbar (y 214..239) — P-2026-11-26.8/.9, screen_specs §17, token
// themeXP.taskbar. Replaces the vertical dock and the y 230 strip.
// Painted by main.cpp only — never by a channel — after the channel's draw()
// on every screen with a window (everything except Night / system screens).
//
//   start button x 0–67 (flag + italic "start"), one 28×20 button per open
//   window at x 71 + 30k (P-2026-11-26.14, ≤ 4, opening order), tray
//   x 196–239 with the clock — from x 176 with the weather icon, and ≤ 3
//   buttons, while the weather skill is on (P-2026-11-26.15). The top window's button pressed (no slide
//   progress); agents waiting = AMBER badge on the Claude window's button; a
//   card that needs the user = that button lit orange (xpFlash).
#include <stdint.h>
#include "xp_core.h"

namespace Taskbar {
    // Full paint of y 214..239. h24 = Settings::clock24h for the tray clock.
    void draw(const XPCore::BarState& s, bool h24);

    // Repaint only what changed since the last draw/update: a button whose
    // window / look / badge changed (its 28-px cell incl. the badge zone),
    // and the tray clock when its text changed (once a minute). No-op while
    // hidden. Call ~4 Hz.
    void update(const XPCore::BarState& s, bool h24);

    // A screen without a taskbar took over (Night): stop update() painting.
    void hide();
    bool shown();

    // Last state painted (meaningful while shown()).
    const XPCore::BarState& state();
}
