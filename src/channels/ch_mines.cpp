// Mines — Dò mìn, Minesweeper of Windows XP, Beginner 9×9 (P-2026-11-27.25, screen_specs §17 XP-Mines,
// sources XP-Mines*.dc.html; skill Giải trí `fun`).
//
//   window      XP::window "Dò mìn", title mine (6, 5); no menu bar (the body is 192 px) — a new game is a
//               click on the face, as XP
//   body        (2, 22, 236×192) #C0C0C0
//   counters    sunken 2 (45, 26, 150×31): LED (51, 30) mines left, face 26×26 (107, 29), LED (148, 30) seconds
//   board       sunken 3 (45, 61, 150×150), cell (c, r) 16×16 at (48 + 16c, 64 + 16r)
//
// The app keeps the game (mines_core.h) and sends the board; this draws it. A new board repaints only the
// cells that changed, the face / LEDs only when they change; tick() advances the seconds LED. draw()
// paints the game as it is (never resets it), clipped block by block under the moving cursor.

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "xp.h"
#include "mines_core.h"
#include "mines_icons.h"

using namespace Mines;
namespace C = Theme::XP::Mines;

static View     s_view;              // what the app sent last
static uint32_t s_sentMs = 0;        // millis when it came (the seconds run on from there)
static View     s_drawn;             // what is on the panel (cells, face, left)
static int      s_drawnSecs = -1;    // seconds on the right LED, -1 = not drawn

static constexpr int kLedY = 30, kLedLeftX = 51, kLedRightX = 148, kLedW = 41, kLedH = 25;
static constexpr int kFaceX = 107, kFaceY = 29, kFaceSize = 26;
// The wrong-flag cross, {row, x, width} from the cell's corner (source XP-Mines-Lose): 2-px strokes, the
// middle rows 3 wide, one step longer at the bottom left / right.
static constexpr uint8_t kCross[][3] = {
    {3, 3, 2}, {3, 12, 2}, {4, 4, 2}, {4, 11, 2}, {5, 5, 2}, {5, 10, 2}, {6, 6, 2}, {6, 9, 2},
    {7, 7, 3}, {8, 7, 3},
    {9, 6, 2}, {9, 9, 2}, {10, 5, 2}, {10, 10, 2}, {11, 4, 2}, {11, 11, 2}, {12, 3, 2}, {12, 12, 2},
    {13, 2, 2}, {13, 13, 2},
};

bool chMinesEnabled(const ChannelCtx&) { return true; }   // the skill toggle decides

// Windows 3D edge [t] px: sunken = dark top / left, white bottom / right (raised: the other way round);
// the corners split on the 45° diagonal.
static void bevel(int x, int y, int w, int h, int t, bool raised) {
    const uint16_t tl = raised ? Theme::XP::WHITE : C::SHADE, br = raised ? C::SHADE : Theme::XP::WHITE;
    for (int i = 0; i < t; i++) {
        tft.drawFastHLine(x, y + i, w - i, tl);
        tft.drawFastVLine(x + i, y, h - i, tl);
        tft.drawFastHLine(x + i + 1, y + h - 1 - i, w - i - 1, br);
        tft.drawFastVLine(x + w - 1 - i, y + i + 1, h - i - 1, br);
    }
}

template <typename Run>
static void runs(const Run* r, int n, const uint16_t* pal, int x0, int y0) {
    for (int k = 0; k < n; k++) {
        Run q;
        memcpy_P(&q, &r[k], sizeof(q));
        tft.fillRect(x0 + q.x, y0 + q.y, q.w, 1, pgm_read_word(&pal[q.c]));
    }
}

static void paintCell(int i, char c) {
    const int x = kBoardX + kCell * (i % kCols), y = kBoardY + kCell * (i / kCols);
    if (!Display::clipHits(x, y, kCell, kCell)) return;
    using namespace MinesIcons;
    if (c == '.' || c == 'F') {                                   // not opened: raised 2
        tft.fillRect(x, y, kCell, kCell, C::FACE);
        bevel(x, y, kCell, kCell, 2, true);
        if (c == 'F') runs(kFlagRuns, kFlagRunCount, kFlagPal, x + 4, y + 3);
        return;
    }
    // Opened (also 'P', pressed): flat, a #808080 rule on the top and left.
    tft.fillRect(x, y, kCell, kCell, c == 'X' ? C::BLAST : C::FACE);
    tft.drawFastHLine(x, y, kCell, C::SHADE);
    tft.drawFastVLine(x, y, kCell, C::SHADE);
    if (c >= '1' && c <= '8') {
        Display::useFont("JBMono-16B");
        tft.setTextDatum(MC_DATUM);
        tft.setTextColor(C::N[c - '0'], C::FACE);
        const char s[2] = {c, 0};
        tft.drawString(s, x + 8, y + 8);
    } else if (c == 'M' || c == 'X' || c == 'W') {
        runs(kMineRuns, kMineRunCount, kMinePal, x + 2, y + 2);
        if (c == 'W') {                                           // wrong flag: XP-Mines-Lose's red cross
            for (const auto& s : kCross) tft.fillRect(x + s[1], y + s[0], s[2], 1, C::BLAST);
        }
    }
}

// LED box sunken 1 px, black inside, 3 digits 13×23 of 7 segments (lit #FF0000, unlit #480000).
static void paintLed(int x, int value) {
    if (!Display::clipHits(x, kLedY, kLedW, kLedH)) return;
    using namespace MinesIcons;
    bevel(x, kLedY, kLedW, kLedH, 1, false);
    tft.fillRect(x + 1, kLedY + 1, kLedW - 2, kLedH - 2, Theme::XP::BLACK);
    uint8_t d[3];
    ledDigits(value, d);
    for (int k = 0; k < 3; k++) {
        const int dx = x + 1 + 13 * k, dy = kLedY + 1;
        for (int s = 0; s < 7; s++) {
            const uint16_t col = d[k] >> (6 - s) & 1 ? C::LED_ON : C::LED_OFF;
            for (int j = 0; j < kSegRuns[s]; j++) {
                Run q;
                memcpy_P(&q, &kSegs[s][j], sizeof(q));
                tft.fillRect(dx + q.x, dy + q.y, q.w, 1, col);
            }
        }
    }
}

static void paintFace(int face) {
    if (!Display::clipHits(kFaceX, kFaceY, kFaceSize, kFaceSize)) return;
    using namespace MinesIcons;
    switch (face) {
        case FACE_WOW:  runs(kFaceWowRuns, kFaceWowRunCount, kFaceWowPal, kFaceX, kFaceY); break;
        case FACE_COOL: runs(kFaceCoolRuns, kFaceCoolRunCount, kFaceCoolPal, kFaceX, kFaceY); break;
        case FACE_DEAD: runs(kFaceDeadRuns, kFaceDeadRunCount, kFaceDeadPal, kFaceX, kFaceY); break;
        default:        runs(kFaceSmileRuns, kFaceSmileRunCount, kFaceSmilePal, kFaceX, kFaceY); break;
    }
}

void chMinesDraw(const ChannelCtx& ctx) {
    XP::window("Dò mìn", XPCore::ICON_MINES, false);
    tft.fillRect(2, 22, 236, 192, C::FACE);
    if (Display::clipHits(45, 26, 150, 31)) bevel(45, 26, 150, 31, 2, false);
    const uint16_t secs = shownSecs(s_view, s_sentMs, ctx.now_ms);
    paintLed(kLedLeftX, s_view.left);
    paintFace(s_view.face);
    paintLed(kLedRightX, secs);
    if (Display::clipHits(45, 61, 150, 150)) bevel(45, 61, 150, 150, 3, false);
    for (int i = 0; i < kCells; i++) paintCell(i, s_view.cell[i]);
    if (Display::repainting()) return;                           // the caches already match the panel
    s_drawn = s_view;
    s_drawnSecs = secs;
}

void chMinesTick(const ChannelCtx& ctx) {
    const uint16_t secs = shownSecs(s_view, s_sentMs, ctx.now_ms);
    if (secs != s_drawnSecs) {
        paintLed(kLedRightX, secs);
        s_drawnSecs = secs;
    }
}

// A board from the app (POST /api/mines). On screen: only what changed repaints.
void chMinesSet(const View& v, bool onScreen) {
    s_view = v;
    s_sentMs = millis();
    if (!onScreen) return;
    for (int i = 0; i < kCells; i++)
        if (s_drawn.cell[i] != v.cell[i]) paintCell(i, v.cell[i]);
    if (s_drawn.face != v.face) paintFace(v.face);
    if (s_drawn.left != v.left) paintLed(kLedLeftX, v.left);
    s_drawn = v;
    s_drawnSecs = -1;                                            // tick() repaints the seconds now
}

const View& chMinesView() { return s_view; }
