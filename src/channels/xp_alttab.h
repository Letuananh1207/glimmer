#pragma once
// XP's Alt+Tab task switcher (P-2026-11-28.29, screen_specs §17 XP-AltTab, sources XP-AltTab-3|1|6.dc.html).
// Drawn by main.cpp over the window like a menu (menu kind "alttab", hover = the tile chosen); the channel's
// tick() is paused under it; the taskbar is not covered. The app holds Alt and steps Tab / Shift+Tab (it
// sends the tile), releasing Alt closes it (kind none) and opens the window chosen (/api/channel).
//
//   box    centred in y 0..213 (XPCore::altTabBox): edge #0A246A with cut corners, white inner line,
//          #D3E5FA inside
//   tiles  40×38, a 32-px icon centred in 40×36: Claude = Clawd ×2 (36×20), Codex / Ảnh / Dò mìn = the
//          desktop bitmaps 32×23, Thời tiết = XP::weatherIcon 32, the others their 16-px icon ×2
//   chosen xpSelect frame 2 px (tile.x + 1, tile.y, 38×36)
//   name   white field (x + 8, …, W − 16 × 18), the window's title JBMono-11 black centred (y + 1)
#include "control_core.h"

namespace XPAltTab {
    // The windows the box shows (XPCore::altTabOrder of the open windows); returns how many.
    int order(int8_t* out);
    void draw(const Control::Menu& m);
    // Only the tile chosen moved: the two tiles + the name repaint.
    void relight(const Control::Menu& was, const Control::Menu& now);
}
