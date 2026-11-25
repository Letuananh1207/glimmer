#pragma once
// Dock (P-2026-11-25.3) — pure logic, host-testable.
//
// The vertical dock on the left edge says which tab the rotation is on and
// which tab has something waiting. No buttons: the tab follows the rotation.
// Tabs: Claude (the agent skill's channels), Ảnh (P-2026-11-25.7), Thời tiết,
// Đồng hồ. Tin nhắn takes a tab once the chat skill pack exists.
#include <string.h>
#include <stdint.h>
#include "skill_core.h"

namespace Dock {

enum Tab : int8_t {
    TAB_NO_DOCK = -2,   // full-screen: Attention, Night, system screens
    TAB_NONE    = -1,   // dock shown, no tab lit (Info)
    TAB_CLAUDE  = 0,
    TAB_PHOTO   = 1,
    TAB_WEATHER = 2,
    TAB_CLOCK   = 3,
};
constexpr int kTabCount = 4;

// Which tab a channel lights (by kChannels[] name).
inline Tab tabFor(const char* name) {
    if (!name) return TAB_NO_DOCK;
    if (!strcmp(name, "Attention") || !strcmp(name, "Night")) return TAB_NO_DOCK;
    if (!strcmp(name, "Weather") || !strcmp(name, "Forecast")) return TAB_WEATHER;
    if (!strcmp(name, "Clock")) return TAB_CLOCK;
    if (!strcmp(name, "Photo")) return TAB_PHOTO;
    if (!strcmp(name, "Info")) return TAB_NONE;
    return TAB_CLAUDE;   // Home, Agents, Claude, Codex, AI, Trend, Setup
}

// Tabs on the dock = enabled skills (R-SK-2): bit k set = tab k shown. Never 0 (at least one skill).
inline uint8_t tabMask(const char* skillsOn) {
    static const char* const kSkillOfTab[kTabCount] = {"agent", "photo", "weather", "clock"};
    uint8_t m = 0;
    for (int k = 0; k < kTabCount; k++)
        if (Skill::inList(skillsOn, kSkillOfTab[k])) m |= (uint8_t)(1u << k);
    return m;
}

// Slot (top = 0) of tab [t] on a dock showing [mask]; -1 when not shown.
inline int slotOf(Tab t, uint8_t mask) {
    if (t < 0 || t >= kTabCount || !(mask >> t & 1)) return -1;
    int s = 0;
    for (int k = 0; k < t; k++) s += mask >> k & 1;
    return s;
}

inline int tabCount(uint8_t mask) {
    int n = 0;
    for (int k = 0; k < kTabCount; k++) n += mask >> k & 1;
    return n;
}

// Frame height: 36 px per tab + 6 (the design's 4 tabs = 150).
inline int frameH(uint8_t mask) { return tabCount(mask) * 36 + 6; }

// Badge glyph: 0 → none (-1), 1..9 → that digit, > 9 → 10 ('+').
inline int badgeGlyph(int count) {
    if (count <= 0) return -1;
    return count > 9 ? 10 : count;
}

}  // namespace Dock
