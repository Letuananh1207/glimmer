#pragma once
// Vertical dock (design P-2026-11-25.3, screen_specs §15, token component.dock).
// Drawn by main.cpp — never by a channel — after the channel's draw(), on every
// channel whose Dock::tabFor() is not TAB_NO_DOCK. Channels keep their content
// in x CONTENT_LEFT..CONTENT_RIGHT so neither draw() nor tick() touches it.
#include <stdint.h>
#include "dock_core.h"

namespace Dock {
    // Full paint: frame, the tabs in [mask] (tabMask of the enabled skills),
    // the active tab, the badge. accent = the channel's colour (the active
    // tab's 2-px bar).
    void draw(uint8_t mask, Tab active, uint16_t accent, int waiting);

    // Repaint only the Claude badge when the waiting count changed.
    void tick(int waiting);

    // A full-screen channel took over: stop tick() painting a dock.
    void hide();

    // The dock on screen carries the Claude tab, so its badge shows agents
    // waiting (otherwise the y 230 strip has to).
    bool showsBadge();

    // The photo-frame tab icon (16×11 grid) with cells of [scale] px, for the
    // Photo channel's empty screen (×3 → 48×33).
    void drawPhotoIcon(int x, int y, int scale, uint16_t color);
}
