#pragma once
// XP (Luna) window chrome + components — P-2026-11-26.8/.9, screen_specs §17,
// token themeXP. Colours: Theme::XP::*; zones: Layout::XP_* (layout.h); pure
// geometry/state: XPCore (xp_core.h).
//
// Every helper paints only its own rectangle and paints every pixel of it, so
// each is safe from tick() (repaint the same call with new values). Text is
// drawn with the VLW font named in the spec; helpers leave that font loaded.
//
// A channel's draw():   XP::window("Claude", XPCore::ICON_CLAWD, hasStatus);
//                       … content in x 10..229, y 22..195 (or ..213) …
// The taskbar (y 214..239) is main.cpp's (taskbar.h) — never paint it.
#include <stdint.h>
#include "xp_core.h"
#include "theme.h"

namespace XP {
    using XPCore::Icon;

    // ── Window ──
    // Full window: title bar (y 0..21), frame (x 0–1 / 238–239, y 22..213),
    // body fill BODY (x 2..237, y 22..213), and — when statusBar — the empty
    // status bar (y 196..213; fill it with XP::statusBar). Replaces
    // Display::clear() + Display::statusBar() at the top of draw().
    void window(const char* title, Icon icon, bool statusBar = false);

    // Title bar only (y 0..21, x 0..239): 5 bands, icon, title (TL 24,4,
    // JBMono-12B white, shadow 25,5 TITLE_SHADOW, ≤ 156 px), 3 buttons.
    void titleBar(const char* title, Icon icon);

    // Repaint only the title text slot (x 23..181, y 0..21) — from tick().
    // Shows "<title> · <meta>" (e.g. meta "cũ 14P", "khóa lỗi"), or the bare
    // title when meta is empty/null. Uses the title of the last titleBar().
    void titleMeta(const char* meta);

    // Text of the last titleBar() (without meta).
    const char* title();

    // Default icon for Display::statusBar() (legacy forwarder); main.cpp sets
    // it from XPCore::iconFor(channel) before each draw().
    void setDefaultIcon(Icon icon);
    Icon defaultIcon();

    // Window status bar (y 196..213, x 2..237): line 196 STATUS_LINE, 197
    // WHITE, rest BODY; left text TL (8,199), right text TR (231,199) with a
    // 1×15 STATUS_LINE divider at XPCore::statusDividerX(w) (y 198..212).
    // JBMono-11, BLACK unless coloured. Call again to update (tick-safe).
    // The right text keeps all the room the left leaves (XPCore::statusRightMax,
    // ≥ 120 px); the left is trimmed to end 4 px before the divider.
    void statusBar(const char* left, const char* right,
                   uint16_t leftColor = Theme::XP::BLACK, uint16_t rightColor = Theme::XP::BLACK);

    // ── Icons ──
    // Four-colour flag 14×12 cells (token themeXP.taskbar.start.flag) at
    // (x, y), cells of scale px: taskbar ×1, setup/login ×2, boot ×3.
    void drawFlag(int x, int y, int scale);
    // 1-bit PROGMEM bitmap, rows of (w+7)/8 bytes, MSB = leftmost pixel; set
    // pixels only (the italic words of the system screens).
    void drawBits(const uint8_t* bits, int w, int h, int x, int y, uint16_t color);
    // Title/taskbar icon with its top-left at (x, y), cells of scale px.
    // CLAWD 18×10 (CLAWD_ORANGE unless color given ≠ 0 — pass WHITE for the
    // lit button); PHOTO 16×11; WEATHER / CLOCK 16×14; INFO 6×9. Paints set
    // pixels only (no background).
    void drawIcon(Icon icon, int x, int y, int scale, uint16_t color);
    // Icon size in cells (w, h).
    void iconSize(Icon icon, int& w, int& h);

    // ── Components (§17 "Thành phần") ──

    // XP block progress bar: FIELD_BORDER 1 px, WHITE field, 9 blocks of
    // `on` (BAR green by default; xpGreen/xpAmber/xpDim on the design's
    // usage bars) lit when pct > i·11.11; geometry XPCore::blocks (padY -1 =
    // 1: blocks from y+2 — XP-Home/-AI/-Codex/cards; XP-Claude-A weekly bar
    // passes 2). Paints x..x+w-1, y..y+h-1.
    void progress(int x, int y, int w, int h, float pct, uint16_t on = Theme::XP::BAR, int padY = -1);

    // Groupbox: 1-px GROUP rectangle (x, y, w, h) — interior NOT filled —
    // and the caption JBMono-11 GROUP_LABEL at (x+7, y−6) on a BODY patch
    // (x+4, y−6, textW+6, 13). Paints the outline + caption patch only.
    void groupBox(int x, int y, int w, int h, const char* label);
    // Repaint the caption only (patch width = max(old, new) so a shorter one clears).
    void groupLabel(int x, int y, const char* label, int clearW = 0);

    // White field / list box: FIELD_BORDER 1 px + WHITE fill. Rows inside:
    // selected ROW = fillRect SELECT + WHITE text, ruled ROW_LINE, today ROW_HI.
    void field(int x, int y, int w, int h);

    // Message box ("hộp thoại", no buttons) on the body: icon 24×24 at (14,36),
    // head JBMono-12B BLACK TL (48,38), lines JBMono-11 LABEL TL (48, 58 + 16i)
    // ("" = blank row), then optional link JBMono-12B LINK underlined at
    // (48, lastLineY + 22) and an optional MUTED sub line 20 px below it
    // (XP-Claude-Rejected: glimmer.local + IP). Does not clear the body.
    enum Dialog : uint8_t { DLG_ERROR, DLG_WARN, DLG_INFO };
    void dialog(Dialog kind, const char* head, const char* const* lines, int n,
                const char* link = nullptr, const char* sub = nullptr);
    // Just the 24×24 icon (round ICON_ERROR + white X / triangle ICON_WARN +
    // black ! / round ICON_INFO + white i) at (x, y); corners painted BODY.
    void dialogIcon(Dialog kind, int x, int y);

    // "Đang tải" screen — XP File Download (P-2026-11-26.16 XP-Load): globe
    // 24×24 (30, 36) → paper flying over 6 spots → folder 24×20 (186, 38);
    // label JBMono-12B BLACK TC (120, 92); 140×14 running box at (50, 116);
    // optional source "từ claude.ai" JBMono-11 MUTED TC (120, 140); wait
    // cursor. Then loadingStep(now_ms / 200) from tick() advances the 3 lit
    // cells, moves the paper (old spot cleared to BODY) and the hourglass.
    void loading(const char* label, const char* source = nullptr);
    void loadingStep(uint32_t step);

    // ── Opening a window (P-2026-11-26.16 XP-Open) ──
    // "Working in Background" cursor: arrow 12×19 tip (132, 160) + hourglass
    // frame step % 4 at (142, 169) (frame 3 lies flat at (140, 171)); repaints
    // its 21×22 cell on BODY.
    void waitCursor(uint32_t step);
    // The window's empty frame (title bar, frame, empty BODY, empty status
    // bar) + the wait cursor — held 200 ms before the content.
    void emptyFrame(const char* title, XPCore::Icon icon, bool status);
    // XP "animate windows": the title bar zooms between taskbar slot [slot]'s
    // button and (0, 0, 240×22) — restore: up, else down — 4 steps × 40 ms
    // (blocks ~160 ms, delay() yields to Wi-Fi). No buffer: earlier steps
    // stay until the window / desktop paints over them.
    void zoom(int slot, bool restore);
    // Generic marquee box anywhere (x, y, w, h) — same look.
    void marquee(int x, int y, int w, int h, uint32_t step);

    // Yellow notification strip (XP-Claude-KeyExpired): INFO_BAR fill
    // (x, y, w, 14), 5×5 AMBER "!" triangle at (x+4, y+3), text JBMono-11
    // RED TL (x+13, y+1), truncated to fit. Tick-safe.
    void infoStrip(int x, int y, int w, const char* text, uint16_t textColor = Theme::XP::RED);

    // "No channels" window (XP-NoChannels): window "glimmer" + info dialog.
    void drawNoChannels();

    // Fit s (UTF-8, in place) to maxW px in the loaded font by dropping whole
    // characters from the end.
    void fitText(char* s, int maxW);
}
