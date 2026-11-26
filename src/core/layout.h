#pragma once

// SmallTV layout / safe-area constants.
//
// XP (Luna) look — P-2026-11-26.8/.9, screen_specs §17, token themeXP.zone.
// Every channel except Night is a window; main.cpp paints the taskbar.
//
//   y   0..21   title bar (XP::window / XP::titleBar)       — XP chrome
//   y  22..213  window: frame x 0–1 / 238–239, body x 2–237  — the channel's
//               content x XP_LEFT..XP_RIGHT (10..229)
//   y 196..213  optional window status bar (XP::statusBar)  — part of the body
//   y 214..239  taskbar — painted by main.cpp (Taskbar::), NEVER by a channel
//
// Channels never paint y ≥ TASKBAR_Y and keep every tick() clear band inside
// the body (filled with Theme::XP::BODY, not BG). Night + system screens have
// no window (black / welcome backgrounds).
namespace Layout {
    // ── XP window ──
    constexpr int XP_TITLE_H   = 22;    // y 0..21, 5 bands
    constexpr int XP_FRAME_W   = 2;     // x 0..1 and 238..239, y 22..213
    constexpr int XP_BODY_X    = 2;
    constexpr int XP_BODY_Y    = 22;
    constexpr int XP_BODY_W    = 236;   // x 2..237
    constexpr int XP_BODY_H    = 192;   // y 22..213
    constexpr int XP_LEFT      = 10;    // content columns x 10..229
    constexpr int XP_RIGHT     = 229;   // last column (TR text datum x)
    constexpr int XP_MID       = 120;
    constexpr int XP_TOP       = 22;    // first body row (content usually from y 28)
    constexpr int XP_BOTTOM    = 214;   // exclusive: first taskbar row
    constexpr int XP_STATUS_Y  = 196;   // status bar y 196..213 when the channel has one
    constexpr int TASKBAR_Y    = 214;   // taskbar y 214..239
    constexpr int TASKBAR_H    = 26;

    // ── Pre-XP names, kept only so phase-2 channels compile until rewritten ──
    // (dark look: 22-px status bar, content y 24..). CONTENT_BOTTOM now stops
    // at the taskbar so legacy clears never touch it. The dock and the y 230
    // indicator strip are gone (P-2026-11-26.8).
    constexpr int STATUS_TOP     = 0;
    constexpr int STATUS_BOTTOM  = 22;
    constexpr int CONTENT_TOP    = 24;
    constexpr int CONTENT_BOTTOM = TASKBAR_Y;   // HARD floor
    constexpr int CONTENT_LEFT   = 40;          // legacy dock layout; use XP_LEFT
    constexpr int CONTENT_RIGHT  = 228;         // legacy; use XP_RIGHT
    constexpr int CONTENT_W      = CONTENT_RIGHT - CONTENT_LEFT;   // 188
    constexpr int CONTENT_MID    = (CONTENT_LEFT + CONTENT_RIGHT) / 2;   // 134
}
