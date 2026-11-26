#pragma once
// XP (Luna) chrome — pure logic, host-testable. P-2026-11-26.8/.9,
// screen_specs §17, token themeXP. Drawing lives in channels/xp.cpp and
// channels/taskbar.cpp; this header only decides geometry and state.
//
// Replaces the vertical dock (P-2026-11-25.3, dock_core.h): the dock's tabs
// became the taskbar's skill buttons, the y 230 strip became the 2-px slide
// progress at the bottom of the active button, and "an agent waits" became
// the badge on the Claude button (or the button lit orange on a card that
// needs the user).
#include <string.h>
#include <stdint.h>
#include "skill_core.h"
#include "attention_core.h"

namespace XPCore {

// ── Taskbar buttons ──
enum Btn : int8_t {
    BTN_NO_BAR  = -2,   // no window, no taskbar: Night (and system screens)
    BTN_NONE    = -1,   // taskbar shown, no button pressed (Info, no channels)
    BTN_CLAUDE  = 0,
    BTN_PHOTO   = 1,
    BTN_WEATHER = 2,
    BTN_CLOCK   = 3,
};
constexpr int kBtnCount = 4;

// Title-bar / taskbar icons.
enum Icon : uint8_t { ICON_NONE, ICON_CLAWD, ICON_PHOTO, ICON_WEATHER, ICON_CLOCK, ICON_INFO };

// Which button a channel presses (by kChannels[] name). Attention cards are
// Claude windows (their button lights orange instead when the card needs you).
inline Btn buttonFor(const char* name) {
    if (!name || !strcmp(name, "Night")) return BTN_NO_BAR;
    if (!strcmp(name, "Weather") || !strcmp(name, "Forecast")) return BTN_WEATHER;
    if (!strcmp(name, "Clock")) return BTN_CLOCK;
    if (!strcmp(name, "Photo")) return BTN_PHOTO;
    if (!strcmp(name, "Info")) return BTN_NONE;
    return BTN_CLAUDE;   // Attention, Home, Agents, Claude, Codex, AI, Trend, Setup
}

// Title-bar icon of a channel's window (sources XP-*.dc.html): Clawd on every
// agent window, the skill icon on Photo / Weather / Forecast / Clock, "i" on Info.
inline Icon iconFor(const char* name) {
    switch (buttonFor(name)) {
        case BTN_NO_BAR:  return ICON_NONE;
        case BTN_NONE:    return ICON_INFO;
        case BTN_PHOTO:   return ICON_PHOTO;
        case BTN_WEATHER: return ICON_WEATHER;
        case BTN_CLOCK:   return ICON_CLOCK;
        default:          return ICON_CLAWD;
    }
}

inline Icon iconOf(Btn b) {
    switch (b) {
        case BTN_CLAUDE:  return ICON_CLAWD;
        case BTN_PHOTO:   return ICON_PHOTO;
        case BTN_WEATHER: return ICON_WEATHER;
        case BTN_CLOCK:   return ICON_CLOCK;
        default:          return ICON_NONE;
    }
}

// Buttons on the taskbar = enabled skills (R-SK-2), packed from x 71 in
// Skill::kAll order (agent, photo, weather, clock). Bit k = button k shown.
inline uint8_t buttonMask(const char* skillsOn) {
    static const char* const kSkillOf[kBtnCount] = {"agent", "photo", "weather", "clock"};
    uint8_t m = 0;
    for (int k = 0; k < kBtnCount; k++)
        if (Skill::inList(skillsOn, kSkillOf[k])) m |= (uint8_t)(1u << k);
    return m;
}

inline int buttonCount(uint8_t mask) {
    int n = 0;
    for (int k = 0; k < kBtnCount; k++) n += mask >> k & 1;
    return n;
}

// Slot (left = 0) of button [b] on a taskbar showing [mask]; -1 when not shown.
inline int slotOf(Btn b, uint8_t mask) {
    if (b < 0 || b >= kBtnCount || !(mask >> b & 1)) return -1;
    int s = 0;
    for (int k = 0; k < b; k++) s += mask >> k & 1;
    return s;
}

// Button geometry (token themeXP.taskbar.buttons): 28×20 at x 71 + 30k, y 217.
constexpr int kBtnX0 = 71, kBtnStep = 30, kBtnW = 28, kBtnH = 20, kBtnY = 217;
inline int buttonX(int slot) { return kBtnX0 + kBtnStep * slot; }

// Badge glyph: 0 → none (-1), 1..9 → that digit, > 9 → 10 ('+').
inline int badgeGlyph(int count) {
    if (count <= 0) return -1;
    return count > 9 ? 10 : count;
}

// A card that needs the user lights the Claude button orange (xpFlash):
// approval, question, error (XP-Attention / -Input / -Error).
inline bool flashes(Attention::Kind k) {
    return k == Attention::K_APPROVAL || k == Attention::K_INPUT || k == Attention::K_ERROR;
}

// Slide progress at the bottom of the active button: (x+1, 234), 2 high,
// 26 × elapsed / slide. 0 when not rotating.
constexpr int kProgressW = 26;
inline int progressLen(uint32_t elapsedMs, uint32_t slideMs) {
    if (!slideMs) return 0;
    if (elapsedMs >= slideMs) return kProgressW;
    return (int)((uint64_t)kProgressW * elapsedMs / slideMs);
}

// How a button looks.
enum Look : uint8_t { LOOK_NORMAL, LOOK_PRESSED, LOOK_FLASH };

// Everything the taskbar shows besides the clock; compare to repaint only what changed.
struct BarState {
    uint8_t mask     = 0;          // buttonMask
    int8_t  active   = BTN_NONE;   // pressed button
    bool    flash    = false;      // Claude button orange (card needs you)
    int8_t  badge    = -1;         // badgeGlyph of the agents waiting
    uint8_t progress = 0;          // progressLen
    uint16_t accent  = 0;          // progress colour (Theme::channelColor)
};

inline Look lookOf(Btn b, const BarState& s) {
    if (b == BTN_CLAUDE && s.flash) return LOOK_FLASH;
    return b == s.active ? LOOK_PRESSED : LOOK_NORMAL;
}
// The badge sits on the Claude button unless it is lit orange (the card says it all).
inline int badgeOn(Btn b, const BarState& s) { return b == BTN_CLAUDE && !s.flash ? s.badge : -1; }
// Progress length drawn on button b.
inline int progressOn(Btn b, const BarState& s) {
    return b == s.active && lookOf(b, s) == LOOK_PRESSED ? s.progress : 0;
}
// Does button b need a repaint going from a to b2?
inline bool buttonChanged(Btn b, const BarState& a, const BarState& b2) {
    return lookOf(b, a) != lookOf(b, b2) || badgeOn(b, a) != badgeOn(b, b2)
        || progressOn(b, a) != progressOn(b, b2)
        || (progressOn(b, b2) && a.accent != b2.accent);
}

// Start button (x 0–67) right edge: inset per row y 214..239 (token
// themeXP.taskbar.start.round: 5,3,2,1,1, 0×16, 1,1,2,3,5).
inline int startInset(int row) {
    static const uint8_t kIn[26] = {5, 3, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
                                    0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 2, 3, 5};
    return row < 0 || row > 25 ? 0 : kIn[row];
}

// ── XP block progress bar (§17 "Thanh tiến độ XP") ──
// Border 1 px, white field, 9 separate blocks. Gap 2 px, or 1 px when the
// field inside the border is ≤ 6 px tall (XP-Claude-A session bar); blocks
// start gap px in from the border; vertical inset padY (default 1 — XP-Home,
// -AI, -Codex, attention progress; XP-Claude-A weekly + loading box pass 2);
// the last block takes the remainder. Block i lights when pct > i·11.11.
struct Blocks { int x0, y0, w, h, gap, lastW; };
inline Blocks blocks(int x, int y, int w, int h, int padY = -1) {
    const int iw = w - 2, ih = h - 2;
    const int gap = ih > 6 ? 2 : 1;
    const int py = padY >= 0 ? padY : 1;
    Blocks b;
    b.gap = gap;
    b.x0 = x + 1 + gap;
    b.y0 = y + 1 + py;
    b.h = ih - 2 * py;
    const int avail = iw - 2 * gap - 8 * gap;
    b.w = avail / 9;
    b.lastW = b.w + avail % 9;
    return b;
}
inline bool blockLit(float pct, int i) { return pct > (float)i * (100.0f / 9.0f); }

// ── "Đang tải" marquee: 9 cells, 3 lit, one cell per 0.2 s (step = ms / 200).
// Like XP's marquee the lit run enters on the left and leaves on the right.
constexpr int kMarqueeCells = 9, kMarqueeLit = 3;
inline bool marqueeLit(uint32_t step, int cell) {
    int p = (int)(step % (kMarqueeCells + kMarqueeLit - 1));   // head position 0..10
    return cell <= p && cell > p - kMarqueeLit;
}

// Window status bar: right text TR at x 231; its divider 8 px left of it.
inline int statusDividerX(int rightW) { return 231 - rightW - 8; }
// Widest right text: everything the left text leaves (left TL x 8, 4 px
// before the divider), never squeezed below 120 px while the left can give.
inline int statusRightMax(int leftW) {
    const int all = statusDividerX(0) - 8;            // 215: no left text
    if (leftW <= 0) return all;
    const int room = all - leftW - 4;
    return room > 120 ? room : 120;
}

// ── Boot screen running box (XP-Splash): 3 blocks on 6 lanes 8 px apart
// inside the 56×11 box. Theo XP thật the run enters on the left and leaves
// on the right, then starts over (period 8 steps of 0.2 s).
constexpr int kBootLanes = 6, kBootLit = 3;
inline bool bootLit(uint32_t step, int lane) {
    int p = (int)(step % (kBootLanes + kBootLit - 1));
    return lane <= p && lane > p - kBootLit;
}

}  // namespace XPCore
