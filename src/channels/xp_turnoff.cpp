// Tắt máy tính — see xp_turnoff.h. Geometry and colours: design/panel/source/XP-TurnOff.dc.html.

#include "xp_turnoff.h"
#include "display.h"
#include "theme.h"
#include "pointer_core.h"

using namespace Theme::XP;
using namespace PointerCore;

namespace {

const char kTitle[] PROGMEM   = "Tắt máy tính";
const char kStandby[] PROGMEM = "Chờ";
const char kOff[] PROGMEM     = "Tắt";
const char kRestart1[] PROGMEM = "Khởi động";
const char kRestart2[] PROGMEM = "lại";
const char kCancel[] PROGMEM  = "Hủy";

constexpr uint16_t kHotEdge = 0xFD86;   // #F8B330 XP push button hot (inner edge)

// White symbols 10×12, bit 9 = column 0 (source XP-TurnOff.dc.html): stand by (moon-ring),
// power, restart.
const uint16_t kSymbols[3][12] PROGMEM = {
    {0x030, 0x048, 0x084, 0x102, 0x231, 0x249, 0x249, 0x231, 0x102, 0x084, 0x048, 0x030},
    {0x030, 0x132, 0x231, 0x231, 0x231, 0x201, 0x201, 0x201, 0x102, 0x084, 0x078, 0x000},
    {0x07A, 0x086, 0x10E, 0x200, 0x200, 0x201, 0x201, 0x001, 0x1C2, 0x184, 0x178, 0x000},
};
// Face and its lighter colour (normal: top row lighter; lit: the face lighter, top row white).
const uint16_t kFace[3]  = {ICON_WARN, ICON_ERROR, GREEN};
const uint16_t kLight[3] = {STANDBY_HI, CLOSE_HOT, START_HI};

void text(const char* p, const char* font, int x, int y, uint16_t fg, uint16_t bg) {
    char t[24];
    strncpy_P(t, p, sizeof(t));
    t[sizeof(t) - 1] = 0;
    Display::useFont(font);
    tft.setTextDatum(TC_DATUM);
    tft.setTextColor(fg, bg);
    tft.drawString(t, x, y);
}

// The dotted shade over what is on screen — only inside the clip of a clipped repaint.
void shade() {
    int cx, cy, cw, ch;
    Display::clipRect(cx, cy, cw, ch);
    for (int y = cy; y < cy + ch; y++)
        for (int x = cx + ((cx + y) & 1); x < cx + cw; x += 2) tft.drawPixel(x, y, BLACK);
}

void button(int i, bool lit) {
    const Rect r = turnOffButton(i);
    const int x = r.x, y = r.y;
    tft.fillRect(x + 1, y, 22, 24, BLACK);
    tft.fillRect(x, y + 1, 24, 22, BLACK);
    tft.fillRect(x + 1, y + 1, 22, 22, WHITE);
    tft.fillRect(x + 2, y + 2, 20, 20, lit ? kLight[i] : kFace[i]);
    tft.drawFastHLine(x + 2, y + 2, 20, lit ? WHITE : kLight[i]);
    for (int row = 0; row < 12; row++) {
        const uint16_t bits = pgm_read_word(&kSymbols[i][row]);
        for (int c = 0; c < 10; c++)
            if (bits >> (9 - c) & 1) tft.drawPixel(x + 7 + c, y + 6 + row, WHITE);
    }
}

void cancel(bool lit) {
    tft.fillRect(165, 151, 52, 21, PUSH_EDGE);
    tft.fillRect(164, 152, 54, 19, PUSH_EDGE);
    tft.fillRect(165, 152, 52, 19, PUSH_FACE);
    tft.fillRect(165, 169, 52, 2, PUSH_SHADE);
    if (lit) tft.drawRect(165, 152, 52, 19, kHotEdge);
    text(kCancel, "JBMono-11", 191, 155, BLACK, PUSH_FACE);
}

void paint(int i, bool lit) {
    if (i == TO_CANCEL) cancel(lit);
    else if (i >= 0 && i < TO_CANCEL) button(i, lit);
}

}  // namespace

namespace XPTurnOff {

void draw(int8_t lit) {
    shade();
    // A clipped repaint (the cursor moved) outside the box: the shade was all.
    if (!Display::clipHits(13, 49, 214, 130)) return;
    tft.fillRect(13, 49, 214, 130, BLACK);
    tft.fillRect(14, 50, 212, 28, WELCOME_BAND);
    if (Display::clipHits(22, 57, 90, 15)) {
        char t[24];
        strncpy_P(t, kTitle, sizeof(t));
        t[sizeof(t) - 1] = 0;
        Display::useFont("JBMono-12B");
        tft.setTextDatum(TL_DATUM);
        tft.setTextColor(WHITE, WELCOME_BAND);
        tft.drawString(t, 22, 57);
    }
    tft.fillRect(204, 58, 6, 5, FLAG_RED);     // the flag, 4 squares 6×5 (source)
    tft.fillRect(211, 58, 6, 5, FLAG_GREEN);
    tft.fillRect(204, 64, 6, 5, FLAG_BLUE);
    tft.fillRect(211, 64, 6, 5, FLAG_YELLOW);
    tft.drawFastHLine(14, 78, 212, WELCOME_LINE);
    tft.fillRect(14, 79, 212, 66, WELCOME);
    tft.fillRect(14, 145, 212, 33, WELCOME_BAND);
    for (int i = 0; i < TO_COUNT; i++) {
        const Rect r = turnOffButton(i);
        if (Display::clipHits(r.x, r.y, r.w, r.h)) paint(i, i == lit);
    }
    if (Display::clipHits(14, 117, 212, 26)) {
        text(kStandby, "JBMono-11", 50, 117, WHITE, WELCOME);
        text(kOff, "JBMono-11", 120, 117, WHITE, WELCOME);
        text(kRestart1, "JBMono-11", 190, 117, WHITE, WELCOME);
        text(kRestart2, "JBMono-11", 190, 129, WHITE, WELCOME);
    }
}

void relight(int8_t was, int8_t now) {
    if (was == now) return;
    paint(was, false);
    paint(now, true);
}

}  // namespace XPTurnOff
