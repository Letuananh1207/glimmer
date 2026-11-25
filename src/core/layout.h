#pragma once

// SmallTV layout / safe-area constants.
//
// Every channel renderer MUST honor these. There's no compile-time enforcement
// (we don't have a real viewport on ESP8266); the discipline lives in code review.
//
// Vertical zones:
//   STATUS_TOP    .. STATUS_BOTTOM-1   universal 22-px status bar
//   STATUS_BOTTOM .. CONTENT_TOP-1     1-px accent under-line
//   CONTENT_TOP   .. CONTENT_BOTTOM-1  channel content (this is the safe area)
//   CONTENT_BOTTOM.. INDICATOR_Y-1     reserved gap (do not paint)
//   INDICATOR_Y   .. INDICATOR_Y+INDICATOR_H-1   global rotation progress strip
//
// Channels must NEVER paint outside [CONTENT_TOP, CONTENT_BOTTOM) on the Y axis.
namespace Layout {
    constexpr int STATUS_TOP     = 0;
    constexpr int STATUS_BOTTOM  = 22;
    constexpr int CONTENT_TOP    = 24;
    constexpr int CONTENT_BOTTOM = 220;   // HARD floor

    constexpr int INDICATOR_Y    = 230;
    constexpr int INDICATOR_H    = 2;

    // Vertical dock (P-2026-11-25.3) on every channel except Attention, Night
    // and system screens: x 2..31, y 34..147, painted by main.cpp. Channels
    // with a dock keep content (and every clear band) in x CONTENT_LEFT..
    // CONTENT_RIGHT; the status bar and the y 230 strip still span 240 px.
    constexpr int DOCK_X = 2;
    constexpr int DOCK_Y = 34;
    constexpr int DOCK_W = 30;
    constexpr int DOCK_H = 114;          // 3 tabs (design's 4 tabs = 150)
    constexpr int CONTENT_LEFT  = 40;
    constexpr int CONTENT_RIGHT = 228;   // last column used by TR text
    constexpr int CONTENT_W     = CONTENT_RIGHT - CONTENT_LEFT;   // 188
    constexpr int CONTENT_MID   = (CONTENT_LEFT + CONTENT_RIGHT) / 2;   // 134
}
