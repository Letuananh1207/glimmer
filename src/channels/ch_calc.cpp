// Calc — XP "Calculator", Standard (P-2026-11-28.31, screen_specs §17 XP-Calc, sources
// XP-Calc|XP-Calc-Down|XP-Calc-Hover|XP-Calc-Error.dc.html). Skill Giải trí (`fun`), with Dò mìn: a Start
// row, no desktop icon. The app keeps the arithmetic and sends what to show (POST /api/calc, calc_core.h).
//
//   window    "Máy tính bỏ túi", icon 16, no menu bar, no status bar
//   display   (8, 27, 224×24) white, the number JBMono-16B TR (227, 30) / the error 12B TR (227, 31)
//   memory    (8, 56, 34×24) sunken, "M" 12B when something is in memory
//   keys      Backspace / CE / C (y 56) + the grid 6 × 4 of 34×26 — XP push buttons, labels 12B blue
//             (digits, ".", "+/-") or red; held = pressed look, under the mouse = hot ring
//
// A new view repaints only the display / memory cell / the keys whose look changed.

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "xp.h"
#include "xp_core.h"
#include "calc_core.h"

namespace C = Theme::XP;
using namespace CalcCore;

extern const CalcCore::View& mainCalcView();

static View   s_view;               // on screen
static int8_t s_hot = KEY_NONE;     // key under the mouse

bool chCalcEnabled(const ChannelCtx&) { return true; }   // the skill toggle decides

static void paintDisplay() {
    if (!Display::clipHits(8, 27, 224, 24)) return;
    tft.drawRect(8, 27, 224, 24, C::FIELD_BORDER);
    tft.fillRect(9, 28, 222, 22, C::WHITE);
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(C::BLACK, C::WHITE);
    if (s_view.error) {
        char b[32]; strncpy_P(b, PSTR("Không thể chia cho 0."), sizeof(b)); b[sizeof(b) - 1] = 0;
        Display::useFont("JBMono-12B");
        tft.drawString(b, 227, 31);
    } else {
        Display::useFont("JBMono-16B");
        tft.drawString(s_view.display, 227, 30);
    }
}

static void paintMemory() {
    if (!Display::clipHits(8, 56, 34, 24)) return;
    tft.drawRect(8, 56, 34, 24, C::DIM);
    tft.fillRect(9, 57, 32, 22, C::BODY);
    tft.drawFastHLine(9, 57, 32, C::LABEL);
    tft.drawFastVLine(9, 57, 22, C::LABEL);
    if (!s_view.mem) return;
    Display::useFont("JBMono-12B");
    tft.setTextDatum(TC_DATUM);
    tft.setTextColor(C::BLACK, C::BODY);
    tft.drawString("M", 25, 59);
}

static XP::BtnLook lookOf(int k) {
    if (s_view.down == k) return XP::BTN_DOWN;
    if (s_hot == k) return XP::BTN_HOT;
    return XP::BTN_UP;
}

static void paintKey(int k) {
    if (k < 0 || k >= KEY_COUNT) return;
    const Rect r = key(k);
    char t[12];
    label(k, t, sizeof(t));
    XP::pushButton(r.x, r.y, r.w, r.h, t, lookOf(k), blueKey(k) ? C::GROUP_LABEL : C::RED,
                   "JBMono-12B", k >= kGrid ? 3 : 4);
}

void chCalcDraw(const ChannelCtx&) {
    if (!Display::repainting()) s_view = mainCalcView();
    char t[24]; strncpy_P(t, PSTR("Máy tính bỏ túi"), sizeof(t)); t[sizeof(t) - 1] = 0;
    XP::window(t, XPCore::ICON_CALC, false);
    paintDisplay();
    paintMemory();
    for (int k = 0; k < KEY_COUNT; k++) paintKey(k);
}

// A new view from the app (on screen): the display / memory cell / the keys whose look changed.
void chCalcSet(const View& v) {
    const View was = s_view;
    s_view = v;
    if (strcmp(was.display, v.display) || was.error != v.error) paintDisplay();
    if (was.mem != v.mem) paintMemory();
    if (was.down != v.down) { paintKey(was.down); paintKey(v.down); }
}

// The mouse over a key: XP's hot ring on that key only. x < 0 = no cursor.
bool chCalcPointer(int x, int y) {
    const int8_t hot = x < 0 ? KEY_NONE : keyAt(x, y);
    if (hot == s_hot) return false;
    const int8_t was = s_hot;
    s_hot = hot;
    paintKey(was);
    paintKey(hot);
    return true;
}
