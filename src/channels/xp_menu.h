#pragma once
// XP context menus (right-click, held ≥ 500 ms on the app) — P-2026-11-26.14,
// screen_specs §17 XP-Menu, source XP-Menu-Desktop / XP-Menu-Window.dc.html.
// Drawn by main.cpp over the current screen; closing it repaints the screen
// (the channel's draw()). While open, the channel's tick() does not run, so
// nothing paints over it. The app picks the item (it knows the layout) and
// sends the resulting command; the device never acts on a menu by itself.
//
//   frame   1-px MENU_BORDER, white inside, 1-px pad (no shadow, no hover)
//   items   17 tall: JBMono-11 TL at (x+17, item+2), dim = MENU_BORDER;
//           ▸ 4×7 at (x+w−10, item+5); separators 7 tall, line at +3
//   desktop 166 × 127: Sắp xếp biểu tượng ▸, Làm mới, —, Dán (dim),
//           Dán lối tắt (dim), —, Mới ▸ (dim), —, Thuộc tính
//   window  128 × 113, glyph 7×7 at (x+5, item+5): Khôi phục (dim unless
//           minimized), Di chuyển (dim), Kích thước (dim), Thu nhỏ (dim when
//           minimized), Phóng to (dim), —, Đóng 12B + "Alt+F4" TR (x+w−17)
#include "control_core.h"

namespace XPMenu {
    void draw(const Control::Menu& m);
}
