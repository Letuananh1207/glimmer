// Display — XP "Display Properties" (P-2026-11-28.30, screen_specs §17 XP-Display, sources
// XP-Display-Desktop|Saver|SaverList|Settings.dc.html). A system program (no skill): the desktop menu's
// Thuộc tính opens it. The app sends the tab, the pending values and the button held (POST /api/display,
// display_core.h); OK / Áp dụng = the app saving them (POST /api/settings). Nothing here saves.
//
//   window      "Thuộc tính màn hình", icon = Start's Desktop 16
//   tabs        Màn nền (6, w 57) · Bảo vệ màn hình (63, w 113) · Cài đặt (176, w 57); page (6, 41, 228×140)
//   monitor     76×73 preview: case #8A8A8A / #D4D0C8, screen 60×54 = the wallpaper at 1/4 + a 6-px taskbar
//               (Bảo vệ màn hình: black + "23:47")
//   Màn nền     list (Không) / Đồi xanh / Ảnh của bạn (only with a photo), Duyệt... dim, note
//   Bảo vệ…     Chế độ: drop field (nightMode) + its open list, Bắt đầu / Kết thúc read-only, ☑ Tối khi rảnh
//   Cài đặt     Độ sáng slider (Ít · % · Nhiều), Màu: 240 x 240, ☑ Đảo màu
//   buttons     OK · Hủy · Áp dụng (dim until a change waits), hot under the mouse
//
// A new view repaints only what changed (+ the preview when the wallpaper changed); the preview's JPEG
// decode is guarded with clipHits so a repaint under the cursor skips it unless the cursor is over it.

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "layout.h"
#include "utf8.h"
#include "xp.h"
#include "xp_core.h"
#include "skill_core.h"
#include "display_core.h"
#include "wallpaper.h"
#include "storage.h"

namespace C = Theme::XP;
using namespace DisplayCore;

extern const DisplayCore::View& mainDisplayView();

static constexpr uint16_t kCase = 0x8C51, kCaseFace = 0xD69A, kLed = 0x2504, kNeck = 0xB596;   // #8A8A8A #D4D0C8 #21A121 #B2B2B2
static constexpr uint16_t kTaskBlue = 0x22FB, kTaskStart = 0x3CE7, kBlack = 0x0000;              // #245EDC #3A9E3A
static constexpr uint16_t kRule = 0xD69A;                                                          // #D0D0BF
static constexpr uint16_t kThumbLine = 0x01EE, kThumbCore = 0x5E0B;                               // #003C74 #5CC15C

static View  s_view;            // on screen
static Shown s_shown;
static bool  s_dirty = false;
static int8_t s_hot = BTN_NONE;
static const Settings* s_set = nullptr;

struct P { char b[40]; explicit P(PGM_P s) { strncpy_P(b, s, sizeof(b)); b[sizeof(b) - 1] = 0; } };
#define F_(s) (P(PSTR(s)).b)

static Saved savedOf(const Settings* s) {
    Saved v;
    v.wall = s ? s->wallpaperMode : 2;
    v.saver = s ? s->nightMode : 0;
    v.bright = s ? s->brightness : 80;
    v.invert = s ? s->invertDisplay : true;
    v.idle = s ? s->idleDim : true;
    return v;
}

static void text(const char* t, int x, int y, uint16_t fg, uint16_t bg, uint8_t datum = TL_DATUM) {
    Display::useFont("JBMono-11");
    tft.setTextDatum(datum);
    tft.setTextColor(fg, bg);
    tft.drawString(t, x, y);
}

// ☑ 13×13: FIELD_BORDER + white, the green tick 7×6 at (+3, +3).
static void checkBox(int x, int y, bool on) {
    if (!Display::clipHits(x, y, 13, 13)) return;
    tft.drawRect(x, y, 13, 13, C::FIELD_BORDER);
    tft.fillRect(x + 1, y + 1, 11, 11, C::WHITE);
    if (!on) return;
    static const uint8_t kTop[7] = {2, 3, 4, 3, 2, 1, 0};
    for (int i = 0; i < 7; i++) tft.fillRect(x + 3 + i, y + 3 + kTop[i], 1, 2, C::CHECK);
}

// ── the monitor preview ──

static void desktopThumb(int sx, int sy) {
    Wallpaper::thumb(s_shown.wall, sx, sy, 60, 48);
    // The desktop icons as dots (design: 4×3 in their colour, 8 apart) — not the trash.
    XPCore::DeskIcon ic[XPCore::kDeskMax];
    const int n = XPCore::deskIcons(s_set ? s_set->skillsOn.c_str() : "agent", ic);
    int k = 0;
    for (int i = 0; i < n; i++) {
        uint16_t c;
        switch (ic[i].prog) {
            case XPCore::PROG_CLAUDE: c = 0xD3AA; break;   // #D97757
            case XPCore::PROG_CODEX:  c = kBlack; break;
            case XPCore::PROG_PHOTO:  c = 0xFEAD; break;   // #F8D56A
            case XPCore::PROG_MINES:  c = 0xC618; break;   // #C0C0C0
            default: continue;
        }
        tft.fillRect(sx + 6 + (ic[i].cx > 80 ? 20 : 0), sy + 6 + 8 * (ic[i].cx > 80 ? 0 : k), 4, 3, c);
        if (ic[i].cx <= 80) k++;
    }
    tft.fillRect(sx, sy + 48, 60, 6, kTaskBlue);
    tft.fillRect(sx, sy + 48, 14, 6, kTaskStart);
}

static void monitor(int x, int y, bool saver) {
    if (!Display::clipHits(x, y, 76, 73)) return;
    tft.fillRect(x, y, 76, 64, kCase);
    tft.fillRect(x + 1, y + 1, 74, 62, kCaseFace);
    tft.drawFastHLine(x + 1, y + 1, 74, C::WHITE);
    tft.drawFastVLine(x + 1, y + 1, 62, C::WHITE);
    tft.drawRect(x + 7, y + 4, 62, 56, C::LABEL);
    tft.fillRect(x + 64, y + 61, 4, 1, kLed);
    tft.fillRect(x + 30, y + 64, 16, 5, kNeck);
    tft.fillRect(x + 22, y + 69, 32, 4, kCaseFace);
    tft.drawFastHLine(x + 22, y + 72, 32, kCase);
    const int sx = x + 8, sy = y + 5;
    if (saver) {
        tft.fillRect(sx, sy, 60, 54, kBlack);
        text("23:47", sx + 30, sy + 18, C::LABEL, kBlack, TC_DATUM);
    } else {
        desktopThumb(sx, sy);
    }
}

// ── tabs ──

static void listRows(int x, int y, int w, int rows, int sel, const char* const* labels) {
    for (int i = 0; i < rows; i++) {
        const int ry = y + 16 * i;
        if (!Display::clipHits(x, ry, w, 16)) continue;
        const bool lit = i == sel;
        tft.fillRect(x, ry, w, 16, lit ? C::SELECT : C::WHITE);
        text(labels[i], x + 3, ry + 1, lit ? C::WHITE : C::BLACK, lit ? C::SELECT : C::WHITE);
    }
}

static const char kW0[] PROGMEM = "(Không)";
static const char kW1[] PROGMEM = "Đồi xanh";
static const char kW2[] PROGMEM = "Ảnh của bạn";
static const char kS1[] PROGMEM = "Tối dần";
static const char kS2[] PROGMEM = "Đồng hồ";
static const char kS3[] PROGMEM = "Tắt màn";

static void paintWallList() {
    if (!Display::clipHits(96, 62, 132, 52)) return;
    char a[16], b[16], c[20];
    strncpy_P(a, kW0, sizeof(a)); strncpy_P(b, kW1, sizeof(b)); strncpy_P(c, kW2, sizeof(c));
    const char* labels[3] = {a, b, c};
    tft.drawRect(96, 62, 132, 52, C::FIELD_BORDER);
    tft.fillRect(97, 63, 130, 50, C::WHITE);
    listRows(97, 63, 130, wallRows(Wallpaper::present()), s_shown.wall, labels);
}

static void tabDesktop() {
    monitor(12, 48, false);
    if (Display::clipHits(96, 46, 80, 14)) text(F_("Hình nền:"), 96, 46, C::BLACK, C::WHITE);
    paintWallList();
    XP::pushButton(163, 120, 65, 21, F_("Duyệt..."), XP::BTN_DIM);
    if (Display::clipHits(12, 150, 200, 14)) text(F_("Gửi ảnh nền từ app glimmer."), 12, 150, C::LABEL, C::WHITE);
}

static void saverLabel(uint8_t m, char* out, size_t n) {
    PGM_P p = m == 1 ? kS1 : m == 2 ? kS2 : m == 3 ? kS3 : kW0;
    strncpy_P(out, p, n); out[n - 1] = 0;
}

static void paintSaverField() {
    if (!Display::clipHits(96, 61, 132, 18)) return;
    tft.drawRect(96, 61, 132, 18, C::FIELD_BORDER);
    tft.fillRect(97, 62, 130, 16, C::WHITE);
    char t[16]; saverLabel(s_shown.saver, t, sizeof(t));
    text(t, 99, 63, C::BLACK, C::WHITE);
    tft.fillRect(212, 63, 14, 14, C::BTN);                                // drop button + white ▾ 5×3
    tft.fillRect(215, 69, 5, 1, C::WHITE);
    tft.fillRect(216, 70, 3, 1, C::WHITE);
    tft.fillRect(217, 71, 1, 1, C::WHITE);
}

static void paintSaverTimes() {
    if (!Display::clipHits(96, 86, 132, 40)) return;
    text(F_("Bắt đầu"), 96, 89, C::BLACK, C::WHITE);
    text(F_("Kết thúc"), 96, 111, C::BLACK, C::WHITE);
    char b[8];
    const uint16_t t[2] = {s_set ? s_set->nightStartMin : 22 * 60, s_set ? s_set->nightEndMin : 7 * 60};
    for (int i = 0; i < 2; i++) {
        const int y = 86 + 22 * i;
        tft.drawRect(160, y, 68, 18, C::FIELD_BORDER);
        tft.fillRect(161, y + 1, 66, 16, C::BODY);
        snprintf_P(b, sizeof(b), PSTR("%02u:%02u"), t[i] / 60, t[i] % 60);
        text(b, 164, y + 2, C::BLACK, C::BODY);
    }
}

static void paintSaverList() {
    if (!Display::clipHits(96, 79, 132, 66)) return;
    char a[16], b[16], c[16], d[16];
    saverLabel(0, a, sizeof(a)); saverLabel(1, b, sizeof(b)); saverLabel(2, c, sizeof(c)); saverLabel(3, d, sizeof(d));
    const char* labels[4] = {a, b, c, d};
    tft.drawRect(96, 79, 132, 66, kBlack);
    tft.fillRect(97, 80, 130, 64, C::WHITE);
    listRows(97, 80, 130, 4, s_shown.saver, labels);
}

static void paintIdle() {
    checkBox(16, 152, s_shown.idle);
}

static void tabSaver() {
    monitor(12, 48, true);
    if (Display::clipHits(96, 46, 80, 14)) text(F_("Chế độ:"), 96, 46, C::BLACK, C::WHITE);
    paintSaverField();
    paintSaverTimes();
    XP::groupBox(10, 140, 220, 34, F_("Khi rảnh"), C::WHITE);
    paintIdle();
    if (Display::clipHits(34, 152, 150, 14)) text(F_("Tối khi rảnh 15 phút"), 34, 152, C::BLACK, C::WHITE);
    if (s_view.list) paintSaverList();     // over the times and the groupbox, as XP's drop list
}

static void paintSlider() {
    if (!Display::clipHits(14, 136, 120, 38)) return;
    tft.fillRect(14, 136, 120, 22, C::WHITE);                             // track + thumb band
    tft.fillRect(20, 142, 108, 2, C::DIM);
    tft.drawFastHLine(20, 144, 108, C::WHITE);
    for (int i = 0; i <= 10; i++) tft.fillRect(tickX(i), 156, 1, 3, C::LABEL);
    // The XP thumb 11×13 (point down): #003C74 edge, white inner line, xpStartHi core.
    const int x = thumbX(s_shown.bright) - 5, y = 137;
    tft.drawFastHLine(x, y, 11, kThumbLine);
    tft.drawFastVLine(x, y + 1, 7, kThumbLine);
    tft.drawFastVLine(x + 10, y + 1, 7, kThumbLine);
    tft.drawFastHLine(x + 1, y + 1, 9, C::WHITE);
    tft.drawFastVLine(x + 1, y + 2, 6, C::WHITE);
    tft.drawFastVLine(x + 9, y + 2, 6, C::WHITE);
    tft.fillRect(x + 2, y + 2, 7, 6, kThumbCore);
    for (int r = 0; r < 5; r++) {                                         // the point, rows 8..12
        tft.drawPixel(x + 1 + r, y + 8 + r, kThumbLine);
        tft.drawPixel(x + 9 - r, y + 8 + r, kThumbLine);
        if (r < 4) {
            tft.drawPixel(x + 2 + r, y + 8 + r, C::WHITE);
            tft.drawPixel(x + 8 - r, y + 8 + r, C::WHITE);
        }
        if (r < 3) tft.drawFastHLine(x + 3 + r, y + 8 + r, 5 - 2 * r, kThumbCore);
    }
    // Ít · % · Nhiều
    tft.fillRect(14, 160, 120, 13, C::WHITE);
    char b[8]; snprintf_P(b, sizeof(b), PSTR("%u%%"), s_shown.bright);
    text(F_("Ít"), 18, 160, C::BLACK, C::WHITE);
    text(b, 74, 160, C::BLACK, C::WHITE, TC_DATUM);
    text(F_("Nhiều"), 132, 160, C::BLACK, C::WHITE, TR_DATUM);
}

static void paintInvert() { checkBox(148, 158, s_shown.invert); }

static void tabSettings() {
    monitor(82, 46, false);
    XP::groupBox(10, 128, 128, 48, F_("Độ sáng"), C::WHITE);
    paintSlider();
    XP::groupBox(142, 128, 88, 48, F_("Màu"), C::WHITE);
    if (Display::clipHits(148, 141, 80, 14)) text(F_("240 x 240"), 148, 141, C::BLACK, C::WHITE);
    paintInvert();
    if (Display::clipHits(166, 158, 60, 14)) text(F_("Đảo màu"), 166, 158, C::BLACK, C::WHITE);
}

// ── buttons ──

static XP::BtnLook lookOf(int b) {
    if (b == BTN_APPLY && !s_dirty) return XP::BTN_DIM;
    if (s_view.down == b) return XP::BTN_DOWN;
    if (s_hot == b) return XP::BTN_HOT;
    return XP::BTN_UP;
}
static void paintButton(int b) {
    const Rect r = button(b);
    char label[16];
    strncpy_P(label, b == BTN_OK ? PSTR("OK") : b == BTN_CANCEL ? PSTR("Hủy") : PSTR("Áp dụng"), sizeof(label));
    label[sizeof(label) - 1] = 0;
    XP::pushButton(r.x, r.y, r.w, r.h, label, lookOf(b));
}

// ── channel ──

static const char kT0[] PROGMEM = "Màn nền";
static const char kT1[] PROGMEM = "Bảo vệ màn hình";
static const char kT2[] PROGMEM = "Cài đặt";

bool chDisplayEnabled(const ChannelCtx&) { return true; }

void chDisplayDraw(const ChannelCtx& ctx) {
    s_set = ctx.settings;
    if (!Display::repainting()) {
        s_view = mainDisplayView();
        if (s_view.tab >= TAB_COUNT) s_view.tab = TAB_DESKTOP;
        s_shown = shown(s_view, savedOf(s_set));
        s_dirty = dirty(s_view, savedOf(s_set));
    }
    XP::window(F_("Thuộc tính màn hình"), XPCore::ICON_DISPLAY, false);
    char a[16], b[24], c[16];
    strncpy_P(a, kT0, sizeof(a)); strncpy_P(b, kT1, sizeof(b)); strncpy_P(c, kT2, sizeof(c));
    const char* labels[3] = {a, b, c};
    XP::tabs(labels, 3, s_view.tab, 140, 8);
    switch (s_view.tab) {
        case TAB_SAVER:    tabSaver(); break;
        case TAB_SETTINGS: tabSettings(); break;
        default:           tabDesktop(); break;
    }
    for (int k = BTN_OK; k <= BTN_APPLY; k++) paintButton(k);
}

// A new view from the app (main.cpp, on screen): only what changed repaints. False = the tab changed or
// the drop list opened / closed over other things — the caller repaints the whole window.
bool chDisplaySet(const View& v, const Settings* set) {
    s_set = set;
    if (v.tab != s_view.tab || v.list != s_view.list) return false;
    const Shown was = s_shown;
    const bool wasDirty = s_dirty;
    const int8_t wasDown = s_view.down;
    s_view = v;
    s_shown = shown(v, savedOf(set));
    s_dirty = dirty(v, savedOf(set));
    switch (v.tab) {
        case TAB_DESKTOP:
            if (was.wall != s_shown.wall) { paintWallList(); monitor(12, 48, false); }
            break;
        case TAB_SAVER:
            if (was.saver != s_shown.saver) { paintSaverField(); if (v.list) paintSaverList(); }
            if (was.idle != s_shown.idle) paintIdle();
            break;
        default:
            if (was.bright != s_shown.bright) paintSlider();
            if (was.invert != s_shown.invert) paintInvert();
            break;
    }
    if (wasDirty != s_dirty || wasDown != v.down) for (int k = BTN_OK; k <= BTN_APPLY; k++) paintButton(k);
    return true;
}

// The settings were saved (OK / Áp dụng): Áp dụng dims again, the preview follows.
void chDisplaySettingsSaved(const Settings* set) { chDisplaySet(s_view, set); }

// The mouse over OK / Hủy / Áp dụng: XP's hot ring on that button only. x < 0 = no cursor.
bool chDisplayPointer(int x, int y) {
    const int8_t hot = x < 0 ? BTN_NONE : hotAt(x, y, s_dirty);
    if (hot == s_hot) return false;
    const int8_t was = s_hot;
    s_hot = hot;
    if (was >= 0) paintButton(was);
    if (hot >= 0) paintButton(hot);
    return true;
}
