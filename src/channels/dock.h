#pragma once
// Vertical dock (design P-2026-11-25.3, screen_specs §15, token component.dock).
// Drawn by main.cpp — never by a channel — after the channel's draw(), on every
// channel whose Dock::tabFor() is not TAB_NO_DOCK. Channels keep their content
// in x CONTENT_LEFT..CONTENT_RIGHT so neither draw() nor tick() touches it.
#include <stdint.h>
#include "dock_core.h"

namespace Dock {
    // Full paint: frame, icons, the active tab, the badge. accent = the
    // channel's colour (the active tab's 2-px bar).
    void draw(Tab active, uint16_t accent, int waiting);

    // Repaint only the Claude badge when the waiting count changed.
    void tick(int waiting);

    // A full-screen channel took over: stop tick() painting a dock.
    void hide();
}
