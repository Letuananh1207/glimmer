#pragma once
// XP's Turn off computer box on the device (P-2026-11-27.24, screen_specs §17 XP-Pointer, source
// XP-TurnOff.dc.html). Opened by the app (POST /api/menu {"kind":"turnoff","hover"}: Start › Tắt máy,
// or Alt+F4 on the desktop) and drawn by main.cpp like a menu, over the whole screen; closing it
// repaints the screen with draw(). The device only draws: Chờ / Tắt / Khởi động lại / Hủy are the
// app's commands (/api/screen off, /api/power off, /api/power restart, /api/menu none).
//
//   shade      every pixel with (x + y) even black, all 240×240 (XP greys the screen; the panel
//              can't be read back, so a dot pattern)
//   box        (13, 49, 214×130) black frame; title band (14, 50, 212×28) xpWelcomeBand with
//              "Tắt máy tính" JBMono-12B white (22, 57) + flag 13×11 at (204, 58); line y 78
//              xpWelcomeLine; buttons area (14, 79, 212×66) xpWelcome; bottom band (14, 145, 212×33)
//   buttons    24×24, 1-px cut corners, centred x 50 / 120 / 190, y 90: black edge, white inner
//              edge, face 20×20 (top row lighter), white symbol 10×12 at (+7, +6); labels JBMono-11
//              white TC y 117 (Khởi động / lại on two lines). Lit (PointerCore::TurnOffButton):
//              face lighter, top row white.
//   Hủy        XP push button (164, 151, 54×21), JBMono-11 black TC (191, 155); lit = XP's hot
//              orange inner edge
#include <stdint.h>

namespace XPTurnOff {
    void draw(int8_t lit);
    // Another button lit: only those two repaint.
    void relight(int8_t was, int8_t now);
}
