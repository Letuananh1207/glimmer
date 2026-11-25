#pragma once
// Dock (P-2026-11-25.3) — pure logic, host-testable.
//
// The vertical dock on the left edge says which tab the rotation is on and
// which tab has something waiting. No buttons: the tab follows the rotation.
// Tabs: Claude (the agent skill's channels), Thời tiết, Đồng hồ. The design's
// fourth tab, Tin nhắn, waits for the chat skill pack (user chose 2026-11-25:
// drop it until that pack exists).
#include <string.h>
#include <stdint.h>

namespace Dock {

enum Tab : int8_t {
    TAB_NO_DOCK = -2,   // full-screen: Attention, Night, system screens
    TAB_NONE    = -1,   // dock shown, no tab lit (Info)
    TAB_CLAUDE  = 0,
    TAB_WEATHER = 1,
    TAB_CLOCK   = 2,
};
constexpr int kTabCount = 3;

// Which tab a channel lights (by kChannels[] name).
inline Tab tabFor(const char* name) {
    if (!name) return TAB_NO_DOCK;
    if (!strcmp(name, "Attention") || !strcmp(name, "Night")) return TAB_NO_DOCK;
    if (!strcmp(name, "Weather") || !strcmp(name, "Forecast")) return TAB_WEATHER;
    if (!strcmp(name, "Clock")) return TAB_CLOCK;
    if (!strcmp(name, "Info")) return TAB_NONE;
    return TAB_CLAUDE;   // Home, Agents, Claude, Codex, AI, Trend, Setup
}

// Badge glyph: 0 → none (-1), 1..9 → that digit, > 9 → 10 ('+').
inline int badgeGlyph(int count) {
    if (count <= 0) return -1;
    return count > 9 ? 10 : count;
}

}  // namespace Dock
