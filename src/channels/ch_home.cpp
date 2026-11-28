// Home — the XP desktop (P-2026-11-26.12, screen_specs §17 XP-Desktop, token
// themeXP.desktop, source/XP-Desktop.dc.html). Replaces the "Trang chủ" window.
//
// chHomeDraw  → wallpaper (user JPEG /wallpaper.jpg, else the fallback pixel
//               wallpaper), desktop icons + labels; seeds the cache.
// chHomeTick  → nothing moves (P-2026-11-26.18: labels are plain names;
//               P-2026-11-26.21: no tray balloon). The selection changing
//               repaints the desktop from main.cpp.
//
//   y 0..213   wallpaper 240×214 at (0, 0) — no window, no title bar
//   icons      one per program of the enabled skills (XPCore::deskIcons, one
//              column x 40, cells 48 tall from y 8): Clawd ×2 (22, cell+1);
//              Codex / Ảnh / Thùng rác = XP colour bitmaps 32×23 at (24, cell)
//              (P-2026-11-26.19, desk_icons.h, tools/deskicons.py)
//   labels     JBMono-11 white TC (40, cell + 24), black shadow (+1, +1):
//                "Claude" · "Codex" · "Ảnh" · "Thùng rác" (P-2026-11-26.18)
//   selected   (the app's `sel`): Clawd xpSelectClawd, bitmaps xpSelectIcon on
//              (x+y)-even cells; label white on xpSelect (text + 1 px each
//              side, 13 tall), no shadow, 1-px dotted white border — as XP.
//   (P-2026-11-26.21: no weather balloon — the Thời tiết window and the tray
//   icon say it.)
//   taskbar    main.cpp's; no button pressed (XPCore::buttonFor("Home")).

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "weather.h"
#include "chrome.h"
#include "utf8.h"
#include "xp.h"
#include "trash.h"
#include "xp_icons.h"
#include "wallpaper.h"
#include "desk_wallpaper.h"
#include "desk_icons.h"
#include "mines_icons.h"
#include <time.h>
#include <math.h>

namespace {
using namespace Theme::XP;

constexpr int kLabels = XPCore::kDeskMax;    // icons on the desktop at most
constexpr int kLabelH = 16;                  // band y−1 .. y+14 (line box 13 + shadow + accents)
constexpr int kLabelMaxW = 80;               // column x 0..79

// The icons of the current paint (seeded by draw()).
XPCore::DeskIcon s_icons[kLabels];
int s_iconN = 0;
int8_t s_sel = XPCore::PROG_NONE;

int labelY(int i) { return s_icons[i].y + 24; }

// Label band of a text tw px wide (+1 shadow), centred on the icon's column.
struct Band { int x, y, w, h; };
Band bandFor(int i, int tw) {
    int w = tw + 3;
    if (w > kLabelMaxW + 4) w = kLabelMaxW + 4;
    int x = s_icons[i].cx - w / 2;
    if (x < 0) x = 0;
    return {x, labelY(i) - 1, w, kLabelH};
}

// The capture the label text blends its anti-aliased edges against.
const Wallpaper::Cap* s_bg = nullptr;
uint16_t bgAt(uint16_t x, uint16_t y) {
    const Wallpaper::Cap* c = s_bg;
    if (c && c->buf && x >= c->x && y >= c->y && x < c->x + c->w && y < c->y + c->h)
        return c->buf[(y - c->y) * c->w + (x - c->x)];
    return Wallpaper::present() ? BLACK : Wallpaper::fallbackAt(x, y);
}
uint16_t shadowAt(uint16_t, uint16_t) { return BLACK; }

}  // namespace

// ── File-static cache so tick() can diff vs last paint ──
static char     s_label[kLabels][16];      // label as drawn ("Claude 100%")
static int16_t  s_labelW[kLabels];         // drawn band width (0 = none)

extern int8_t mainSelectedIcon();   // the app's selected desktop icon (Control::Windows::sel)

bool chHomeEnabled(const ChannelCtx& ctx) {
    return ctx.settings && ctx.settings->showHome
        && time(nullptr) > 1000000000L;
}

// ── Text of the moving parts ──

static void labelText(int i, const ChannelCtx& ctx, char* out, size_t n) {
    switch (s_icons[i].prog) {
        // P-2026-11-26.18: the program's name only, as XP (no usage % on a desktop icon).
        case XPCore::PROG_CLAUDE:  Utf8::copy(out, n, "Claude"); break;
        case XPCore::PROG_CODEX:   Utf8::copy(out, n, "Codex"); break;
        case XPCore::PROG_PHOTO:   Utf8::copy(out, n, "Ảnh"); break;
        case XPCore::PROG_WEATHER: Utf8::copy(out, n, "Thời tiết"); break;
        case XPCore::PROG_CLOCK:   Utf8::copy(out, n, "Đồng hồ"); break;
        case XPCore::PROG_MINES:   Utf8::copy(out, n, "Dò mìn"); break;
        default:                   Utf8::copy(out, n, "Thùng rác"); break;
    }
}

static bool selected(int i) { return s_sel >= 0 && s_icons[i].prog == s_sel; }

// ── Painting ──

// Label text over the band already holding the wallpaper (cap = its pixels).
static void drawLabelText(int i, const char* text, const Wallpaper::Cap* cap) {
    Display::useFont("JBMono-11");
    tft.setTextDatum(TC_DATUM);
    const int y = labelY(i);
    const int kColX = s_icons[i].cx;
    if (selected(i)) {
        // XP selection: xpSelect behind the text (+1 px each side, 13 tall), no
        // shadow, 1-px dotted white border around it.
        const int tw = tft.textWidth(text);
        const int bx = kColX - tw / 2 - 1, bw = tw + 2, bh = 13;
        tft.fillRect(bx, y, bw, bh, SELECT);
        for (int k = 0; k < bw + 2; k += 2) {
            tft.drawPixel(bx - 1 + k, y - 1, WHITE);
            tft.drawPixel(bx - 1 + k, y + bh, WHITE);
        }
        for (int k = 0; k < bh + 2; k += 2) {
            tft.drawPixel(bx - 1, y - 1 + k, WHITE);
            tft.drawPixel(bx + bw, y - 1 + k, WHITE);
        }
        tft.setTextColor(WHITE, SELECT);
        tft.drawString(text, kColX, y);
        return;
    }
    s_bg = cap;
    tft.setCallback(bgAt);                   // shadow edges blend into the wallpaper
    tft.setTextColor(BLACK, WHITE);          // bg unused: the callback decides
    tft.drawString(text, kColX + 1, y + 1);
    tft.setCallback(shadowAt);               // text edges blend into the shadow
    tft.setTextColor(WHITE, BLACK);
    tft.drawString(text, kColX, y);
    tft.setCallback(nullptr);
    s_bg = nullptr;
}

static int measure(const char* text) {
    Display::useFont("JBMono-11");
    int w = tft.textWidth(text);
    return w > kLabelMaxW ? kLabelMaxW : w;
}


// An XP colour icon (P-2026-11-26.19, desk_icons.h) at real pixels; transparent cells keep the wallpaper.
// Selected: every colour → xpSelectIcon on the (x+y)-even cells (dither for XP's 50 % select tint).
template <typename Run>
static void drawRuns(const Run* runs, int n, const uint16_t* pal, int x0, int y0, bool sel) {
    for (int k = 0; k < n; k++) {
        Run r;
        memcpy_P(&r, &runs[k], sizeof(r));
        const int x = x0 + r.x, y = y0 + r.y;
        tft.fillRect(x, y, r.w, 1, pgm_read_word(&pal[r.c]));
        if (!sel) continue;
        for (int i = (x + y) & 1; i < r.w; i += 2) tft.drawPixel(x + i, y, SELECT_ICON);
    }
}

static void drawIcon(int i) {
    const XPCore::DeskIcon& ic = s_icons[i];
    const bool sel = selected(i);
    const int cx = ic.cx, y = ic.y;
    using namespace DeskIcons;
    switch (ic.prog) {
        case XPCore::PROG_CLAUDE:                              // Clawd orange, black eyes
            XP::drawIcon(XPCore::ICON_CLAWD, cx - 18, y + 1, 2, sel ? SELECT_CLAWD : Display::CLAWD_ORANGE);
            break;
        case XPCore::PROG_CODEX: drawRuns(kCodexRuns, kCodexRunCount, kCodexPal, cx - 16, y, sel); break;   // Command Prompt
        case XPCore::PROG_PHOTO: drawRuns(kPhotoRuns, kPhotoRunCount, kPhotoPal, cx - 16, y, sel); break;   // My Pictures
        case XPCore::PROG_MINES:                                                                        // P-2026-11-27.25
            drawRuns(MinesIcons::kDeskMinesRuns, MinesIcons::kDeskMinesRunCount, MinesIcons::kDeskMinesPal, cx - 16, y, sel);
            break;
        default:                                                                                        // Recycle Bin
            if (Trash::count())                                    // P-2026-11-28.32: papers in it (XP-Desk-TrashFull)
                drawRuns(XpIcons::kTrashFullRuns, XpIcons::kTrashFullRunCount, XpIcons::kTrashFullPal, cx - 16, y, sel);
            else
                drawRuns(kTrashRuns, kTrashRunCount, kTrashPal, cx - 16, y, sel);
            break;
    }
}

// ── Full repaint ──

void chHomeDraw(const ChannelCtx& ctx) {
    s_iconN = XPCore::deskIcons(ctx.settings->skillsOn.c_str(), s_icons);
    s_sel = mainSelectedIcon();
    // Label texts and bands first (the font is needed to measure them).
    char text[kLabels][24];
    Wallpaper::Cap caps[kLabels];
    for (int i = 0; i < s_iconN; i++) {
        labelText(i, ctx, text[i], sizeof(text[i]));
        Display::useFont("JBMono-11");
        XP::fitText(text[i], kLabelMaxW);
        Band b = bandFor(i, measure(text[i]));
        caps[i] = {(int16_t)b.x, (int16_t)b.y, (int16_t)b.w, (int16_t)b.h, nullptr};
        s_labelW[i] = (int16_t)b.w;
    }
    // One decode paints the whole wallpaper and keeps the four label bands
    // for the text's anti-aliasing (~2 KB each; a failed malloc just means
    // that label blends against black).
    // A clipped repaint (cursor moving) decodes only down to the clip and
    // keeps the bands of the labels it touches.
    int cx, cy, cw, ch;
    Display::clipRect(cx, cy, cw, ch);
    auto touches = [&](const Wallpaper::Cap& c) {
        return c.x < cx + cw && cx < c.x + c.w && c.y < cy + ch && cy < c.y + c.h;
    };
    if (Wallpaper::present()) Display::releaseFont();
    for (int i = 0; i < s_iconN; i++)
        if (touches(caps[i])) caps[i].buf = (uint16_t*)malloc((size_t)caps[i].w * caps[i].h * 2);
    Wallpaper::paint(cx, cy, cw, ch, caps, s_iconN);

    for (int i = 0; i < s_iconN; i++) {
        drawIcon(i);
        drawLabelText(i, text[i], caps[i].buf ? &caps[i] : nullptr);
        free(caps[i].buf);
        labelText(i, ctx, s_label[i], sizeof(s_label[i]));
    }
}

// ── Tick: 5 Hz, region-only repaints ──

void chHomeTick(const ChannelCtx&) {}   // nothing on the desktop changes by itself
