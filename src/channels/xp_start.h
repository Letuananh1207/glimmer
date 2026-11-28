#pragma once
// XP Start menu on the device (P-2026-11-26.20, screen_specs §17 XP-Start, source XP-Start-Menu /
// XP-Start-All.dc.html). Drawn by main.cpp over the screen (0, 0)–(239, 213) when the app opens Start
// (POST /api/menu {"kind":"start","all"}); the taskbar's start button is drawn pressed meanwhile. As
// with the context menus the device only draws: the app picks items and sends the command. Closing
// repaints the screen with the channel's draw().
//
//   user band   (0, 0, 240×32) 6 Luna bands, picture 24×24 at (5, 4) with Clawd, "Clawd" 16B white
//   orange line y 32–33
//   body        y 34–189: left column white x 1–151 (pinned Claude / Codex when the agent skill is on,
//               then Ảnh / Thời tiết / Đồng hồ by skill, "Tất cả chương trình" + green arrow), right
//               column #D3E5FA x 153–238 (Desktop, Số liệu, —, Cài đặt, Thêm / gỡ, Thiết bị)
//   bottom band (0, 190, 240×24): Khởi động lại (green) and Tắt máy (red, opens Tắt máy tính)
//   all         All Programs open: its row xpSelect, sub-menu (151, 62, 89×h) with the installed programs
//               + "Thêm / gỡ"
#include "control_core.h"

namespace XPStart {
    // [m].hover / [m].sub = the rows lit (pointer_core.h order).
    void draw(const Control::Menu& m, const char* skillsOn);
    // Same menu, another row lit (P-2026-11-27.24): repaints only the two rows.
    void relight(const Control::Menu& was, const Control::Menu& now, const char* skillsOn);
}
