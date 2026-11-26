#pragma once
// XP taskbar (y 214..239) — P-2026-11-26.8/.9, screen_specs §17, token
// themeXP.taskbar. Replaces the vertical dock and the y 230 strip.
// Painted by main.cpp only — never by a channel — after the channel's draw()
// on every screen with a window (everything except Night / system screens).
//
//   start button x 0–67 (flag + italic "start"), skill buttons 28×20 at
//   x 71 + 30k (enabled skills only), tray x 196–239 with the clock.
//   Active channel's button pressed + 2-px slide progress at (x+1, 234);
//   agents waiting = AMBER badge on the Claude button; a card that needs
//   the user = Claude button lit orange (xpFlash).
#include <stdint.h>
#include "xp_core.h"

namespace Taskbar {
    // Full paint of y 214..239. h24 = Settings::clock24h for the tray clock.
    void draw(const XPCore::BarState& s, bool h24);

    // Repaint only what changed since the last draw/update: a button whose
    // look / badge / progress moved (its 28×23 cell incl. the badge zone),
    // and the tray clock when its text changed (once a minute). No-op while
    // hidden. Call ~4 Hz.
    void update(const XPCore::BarState& s, bool h24);

    // A screen without a taskbar took over (Night): stop update() painting.
    void hide();
    bool shown();

    // Last state painted (meaningful while shown()).
    const XPCore::BarState& state();
}
