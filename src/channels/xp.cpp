// XP (Luna) window chrome + components — see xp.h. Geometry from
// design/panel/source/XP-*.dc.html and token themeXP (P-2026-11-26.8/.9).

#include "xp.h"
#include "display.h"
#include "layout.h"
#include "config.h"
#include "utf8.h"
#include "cursor.h"
#include "pointer_core.h"

using namespace Theme::XP;
using XPCore::Icon;

namespace {

struct IconBits { uint8_t w, h; const uint32_t* rows; };

// Bit (w-1-x) of row y = pixel (x, y). Same grids as the old dock (token
// component.dock.icon) — the XP sources reuse them; INFO from XP-Info.
const uint32_t kClawdBits[10] PROGMEM = {
    0x07FF8, 0x07FF8, 0x06FD8, 0x06FD8, 0x1FFFE,
    0x1FFFE, 0x07FF8, 0x07FF8, 0x02850, 0x02850,
};
const uint32_t kPhotoBits[11] PROGMEM = {
    0xFFFF, 0x8001, 0x8019, 0x803D, 0x8019, 0x8001,
    0x8801, 0x9C21, 0xBE71, 0xFDFD, 0xFFFF,
};
const uint32_t kWeatherBits[14] PROGMEM = {
    0x0180, 0x2184, 0x1008, 0x07E0, 0x0FF0, 0x0FF0, 0xCFF3,
    0xCFF3, 0x0FF0, 0x0FF0, 0x07E0, 0x1008, 0x2184, 0x0180,
};
const uint32_t kClockBits[14] PROGMEM = {
    0x07E0, 0x1FF8, 0x381C, 0x60C6, 0x60C6, 0xC0C3, 0xC0C3,
    0xC0FB, 0xC003, 0x6006, 0x6006, 0x381C, 0x1FF8, 0x07E0,
};
const uint32_t kInfoBits[9] PROGMEM = {
    0x0C, 0x0C, 0x00, 0x1C, 0x0C, 0x0C, 0x0C, 0x0C, 0x1E,
};

// ── P-2026-11-26.16 art (screen_specs §17 XP-Open), one char per pixel, '.' = transparent ──
const char kArrow[] PROGMEM = "X...........XX..........XWX.........XWWX........XWWWX.......XWWWWX......XWWWWWX.....XWWWWWWX....XWWWWWWWX...XWWWWWWWWX..XWWWWWWWWWX.XWWWWWWXXXXXXWWWXWWX....XWWXXWWX....XWX..XWWX...XX...XWWX...X.....XWWX........XWWX.........XX...";   // 12×19
const char kGlass0[] PROGMEM = "XXXXXXXXX.XSSSSSX..XSSSSSX...XSSSX.....XSX......XWX.....XWWWX...XWWWWWX..XWWWWWX..XWWWWWX..XWWWWWX.XXXXXXXXX";   // 9×12
const char kGlass1[] PROGMEM = "XXXXXXXXX.XWWWWWX..XWWWWWX...XSSSX.....XSX......XSX.....XWSWX...XWWSWWX..XWWWWWX..XWWSWWX..XSSSSSX.XXXXXXXXX";   // 9×12
const char kGlass2[] PROGMEM = "XXXXXXXXX.XWWWWWX..XWWWWWX...XWWWX.....XWX......XWX.....XWWWX...XWWWWWX..XWSSSWX..XSSSSSX..XSSSSSX.XXXXXXXXX";   // 9×12
const char kGlass3[] PROGMEM = "X..........XXXX....XXXXXXWWX..XWWSSXXWWWXXWWSSSXXWWWWWWWSSSXXWWWXXWWSSSXXWWX..XWWSSXXXX....XXXXXX..........X";   // 12×9
const char kGlobe[] PROGMEM = "...............................EEEEEEEEEE.............EEBBBBBBBBEE..........EELLLBBBBBBBBBEE.......EELLLLLLBBBBBBBBEE......ELLLLLLLBBBBBLLLLE.....ELLLLLLLLLBBBBLLLLBE...EELLLLLLLLLBBBBLLLLBEE..EBLLLLLLLLLBBBBBBBBBBE..EBLLLLLLLLLBBBBBBBBBBE..EBLLLLLLLLLBBBBBBBBBBE..EBBLLLLLLLBBBBBBBBBBBE..EBBLLLLLLLBBBLLLBBBBBE..EBBBBLLLBBBBLLLLLBBBBE..EBBBBBBBBBBLLLLLLLBBBE..EBBBBBBBBBBLLLLLLLBBBE..EEBBBBBBBBBLLLLLLLBBEE...EBBBBBBBBBLLLLLLLBBE.....EBBBBBBBBLLLLLLLBE......EEBBBBBBBBLLLLLBEE.......EEBBBBBBBBLLLBEE..........EEBBBBBBBBEE.............EEEEEEEEEE...............................";   // 24×24
const char kFolder[] PROGMEM = "DDDDDDDD................DFFFFFFFD...............DFFFFFFFFDDDDDDDDDDDDDD.DFFFFFFFFFFFFFFFFFFFFFFDDFFFFFFFFFFFFFFFFFFFFFFDDFFFFFFFFFFFFFFFFFFFFFFDDFFFFFFFFFFFFFFFFFFFFFFDDFFFFFFFFFFFFFFFFFFFFFFDDFFFFFFFFFFFFFFFFFFFFFFDDFFFFFFFFFFFFFFFFFFFFFFDDFFFFFFFFFFFFFFFFFFFFFFDDFFFFFFFFFFFFFFFFFFFFFFDDFFFFFFFFFFFFFFFFFFFFFFDDFFFFFFFFFFFFFFFFFFFFFFDDFFFFFFFFFFFFFFFFFFFFFFDDFFFFFFFFFFFFFFFFFFFFFFDDFFFFFFFFFFFFFFFFFFFFFFDDFFFFFFFFFFFFFFFFFFFFFFDDDDDDDDDDDDDDDDDDDDDDDDD........................";   // 24×20
const char kPaper[] PROGMEM = "BBBBBBB...BWWWWWBB..BWLLLWWBB.BWWWWWWWB.BWLLLLLWB.BWWWWWWWB.BWLLLLLWB.BWWWWWWWB.BWLLLLLWB.BWWWWWWWB.BBBBBBBBB.";   // 10×11

// P-2026-11-26.17 weather icons (screen_specs §17 XP-Real): sun / partly / rain, 16 and 32 px.
const char kWxSun16[] PROGMEM = ".......YY..............YY..........Y...YY...Y.....YYY......YYY.....Y...AA...Y........AAYYAA..........AYYYYA.....YYY.AYYYYYYA.YYYYYY.AYYYYYYA.YYY.....AYYYYA..........AAYYAA........Y...AA...Y.....YYY......YYY.....Y...YY...Y..........YY..............YY.......";   // 16×16
const char kWxSun32[] PROGMEM = "..............................................YYYY............................YYYY............................YYYY....................YY......YYYY......YY...........YYY......YYYY......YYY.........YYYYY..............YYYYY........YYYYYY............YYYYYY..........YYY..............YYY.............Y....AAAAAAAA....Y..................AAYYYYYYAA.....................AYYYYYYYYYYA...................AAYYYYYYYYYYAA..................AYYYYYYYYYYYYA..........YYYYY...AYYYYYYYYYYYYA...YYYYY..YYYYY...AYYYYYYYYYYYYA...YYYYY..YYYYY...AYYYYYYYYYYYYA...YYYYY..YYYYY...AYYYYYYYYYYYYA...YYYYY..........AYYYYYYYYYYYYA..................AAYYYYYYYYYYAA...................AYYYYYYYYYYA.....................AAYYYYYYAA..................Y....AAAAAAAA....Y.............YYY..............YYY..........YYYYYY............YYYYYY........YYYYY..............YYYYY.........YYY......YYYY......YYY...........YY......YYYY......YY....................YYYY............................YYYY............................YYYY..............................................";   // 32×32
const char kWxPartly16[] PROGMEM = ".....YY...........Y..YY..Y.......YY......YY.........AAAA...........AYYYYA.......YY.AYYYYGGGG....YY.AYYYGWWWWG......AYYGWWWWWWG......GGWWWWWWWG.....GWWWWWWWWWG.....GWWWWWWWWWWG....GWWWWWWWWWWG....GWWWWWWWWWWG....GGGGGGGGGGGG.................................";   // 16×16
const char kWxPartly32[] PROGMEM = "..........YYYY............................YYYY......................Y.....YYYY.....Y...............YYY............YYY.............YYYYY..........YYYYY.............YYY............YYY...............Y....AAAAAA....Y...................AAYYYYYYAA......................AYYYYYYYYA.....................AYYYYYYYYYYA..............YYY...AYYYYYYYYYYA.GGYYY........YYY...AYYYYYYYYYGGGWWGGG........YYY...AYYYYYYYYGWWWWWWWWG.......YYY...AYYYYYYYGWWWWWWWWWWG............AYYYYYYGWWWWWWWWWWWWG............AYYGGGWWWWWWWWWWWWWG............AGGWWWWWWWWWWWWWWWWG............GWWWWWWWWWWWWWWWWWWWG...........GWWWWWWWWWWWWWWWWWWWG..........GWWWWWWWWWWWWWWWWWWWWWG.........GWWWWWWWWWWWWWWWWWWWWWWG........GWWWWWWWWWWWWWWWWWWWWWWG........GWWWWWWWWWWWWWWWWWWWWWWWG.......GWWWWWWWWWWWWWWWWWWWWWWWG.......GWWWWWWWWWWWWWWWWWWWWWWG........GWWWWWWWWWWWWWWWWWWWWWWG........GWWWWWWWWWWWWWWWWWWWWWG.........GGGGGGGGGGGGGGGGGGGGGGG...................................................................................................................................";   // 32×32
const char kWxRain16[] PROGMEM = "........................................................GGGG...........GWWWWG.......GGGWWWWWWG.....GWWWWWWWWWG.....GWWWWWWWWWWG....GWWWWWWWWWWG....GWWWWWWWWWWG....GWWWWWWWWWWG....GGGGGGGGGGGG......B..B...B.......BB..B..B........B..B...B.......BB..B..B.....";   // 16×16
const char kWxRain32[] PROGMEM = "...................................................................................................................................................................................GG...........................GGGWWGGG.......................GWWWWWWWWG.....................GWWWWWWWWWWG...................GWWWWWWWWWWWWG...............GGGWWWWWWWWWWWWWG.............GGWWWWWWWWWWWWWWWWG............GWWWWWWWWWWWWWWWWWWWG...........GWWWWWWWWWWWWWWWWWWWG..........GWWWWWWWWWWWWWWWWWWWWWG.........GWWWWWWWWWWWWWWWWWWWWWWG........GWWWWWWWWWWWWWWWWWWWWWWG........GWWWWWWWWWWWWWWWWWWWWWWWG.......GWWWWWWWWWWWWWWWWWWWWWWWG.......GWWWWWWWWWWWWWWWWWWWWWWG........GWWWWWWWWWWWWWWWWWWWWWWG........GWWWWWWWWWWWWWWWWWWWWWG.........GGGGGGGGGGGGGGGGGGGGGGG.............................................................................BB.....BB.....BB...............BB.....BB.....BB................BB.....BB.....BB...............BB.....BB.....BB................BB.....BB.....BB...............BB.....BB.....BB................BB.....BB.....BB.........";   // 32×32

struct Ink { char key; uint16_t color; };
// Draw a char-art bitmap at (x, y): runs of one key → one fillRect; unknown keys transparent.
void drawArt(const char* art, int w, int h, int x, int y, const Ink* inks, int nInks) {
    for (int r = 0; r < h; r++) {
        for (int c = 0; c < w;) {
            const char k = (char)pgm_read_byte(&art[r * w + c]);
            int run = 1;
            while (c + run < w && (char)pgm_read_byte(&art[r * w + c + run]) == k) run++;
            for (int i = 0; i < nInks; i++)
                if (inks[i].key == k) { tft.fillRect(x + c, y + r, run, 1, inks[i].color); break; }
            c += run;
        }
    }
}

// File Download paper position shown now (-1 = none drawn).
int s_paperAt = -1;

void drawPaper(int i) {
    static const Ink kInks[] = {{'B', FIELD_BORDER}, {'W', WHITE}, {'L', DIM}};
    if (s_paperAt >= 0) tft.fillRect(XPCore::paperX(s_paperAt), XPCore::paperY(s_paperAt), 10, 11, BODY);
    drawArt(kPaper, 10, 11, XPCore::paperX(i), XPCore::paperY(i), kInks, 3);
    s_paperAt = i;
}

IconBits bitsOf(Icon i) {
    switch (i) {
        case XPCore::ICON_CLAWD:   return {18, 10, kClawdBits};
        case XPCore::ICON_PHOTO:   return {16, 11, kPhotoBits};
        case XPCore::ICON_WEATHER: return {16, 14, kWeatherBits};
        case XPCore::ICON_CLOCK:   return {16, 14, kClockBits};
        case XPCore::ICON_INFO:    return {6, 9, kInfoBits};
        default:                   return {0, 0, nullptr};
    }
}

// Title bar bands (token themeXP.titleBar.bands).
struct Band { uint8_t y0, y1; uint16_t c; };
const Band kTitleBands[5] = {
    {0, 0, TITLE_HI}, {1, 2, TITLE_LIGHT}, {3, 18, TITLE}, {19, 20, TITLE_DARK}, {21, 21, TITLE_EDGE},
};
void titleBands(int x, int w) {
    for (const Band& b : kTitleBands) tft.fillRect(x, b.y0, w, b.y1 - b.y0 + 1, b.c);
}

constexpr int kTitleX = 24, kTitleY = 4, kTitleMaxW = 156;
constexpr int kTitleSlotX = 23, kTitleSlotW = 182 - 23;   // up to the first button (x 184) − 2

char s_title[48] = "";
Icon s_defaultIcon = XPCore::ICON_CLAWD;

void paintTitleText(const char* text) {
    if (!Display::clipHits(kTitleX, kTitleY, kTitleMaxW + 2, 16)) return;
    char t[64];
    Utf8::copy(t, sizeof(t), text);
    Display::useFont("JBMono-12B");
    XP::fitText(t, kTitleMaxW);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(TITLE_SHADOW, TITLE);
    tft.drawString(t, kTitleX + 1, kTitleY + 1);
    tft.setTextColor(WHITE, TITLE);
    tft.drawString(t, kTitleX, kTitleY);
}

void titleIcon(Icon icon) {
    switch (icon) {
        case XPCore::ICON_NONE: return;
        case XPCore::ICON_CLAWD: XP::drawIcon(icon, 4, 6, 1, Display::CLAWD_ORANGE); return;
        case XPCore::ICON_INFO:  XP::drawIcon(icon, 8, 6, 1, WHITE); return;   // XP-Info
        default: {
            int w, h; XP::iconSize(icon, w, h);
            XP::drawIcon(icon, 13 - w / 2, 11 - h / 2, 1, WHITE);   // centred on (13, 11)
        }
    }
}

int8_t s_hot = -1;   // PointerCore::kHotNone

// 16×16 caption button at (x, 3): 1-px white border, fill, glyph.
void captionButton(int x, uint16_t fill, char kind) {
    const int y = 3;
    tft.fillRect(x, y, 16, 16, WHITE);
    tft.fillRect(x + 1, y + 1, 14, 14, fill);
    switch (kind) {
        case '_': tft.fillRect(x + 4, y + 10, 6, 2, WHITE); break;
        case 'o':   // maximise, off (P-2026-11-26.14): windows are full screen and
                    // never resize — XP greys the button: 8×8 box, 2-px top, xpCaptionOff
            tft.drawRect(x + 4, y + 3, 8, 8, CAPTION_OFF);
            tft.drawFastHLine(x + 4, y + 4, 8, CAPTION_OFF);
            break;
        default:    // close: X of 2×1 steps, 7 rows
            for (int r = 0; r < 7; r++) {
                tft.fillRect(x + 4 + r, y + 4 + r, 2, 1, WHITE);
                tft.fillRect(x + 10 - r, y + 4 + r, 2, 1, WHITE);
            }
    }
}

// Rows of a filled shape as left insets (width = size − 2·inset); 0xFF = empty row.
const uint8_t kCircle24[24] PROGMEM = {
    0xFF, 7, 6, 4, 3, 3, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 3, 4, 6, 7, 0xFF,
};
const uint8_t kTriangle24[24] PROGMEM = {
    0xFF, 0xFF, 11, 11, 10, 10, 9, 9, 8, 8, 7, 6, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1, 0, 0xFF,
};
void insetShape(const uint8_t* rows, int x, int y, uint16_t c) {
    for (int r = 0; r < 24; r++) {
        uint8_t in = pgm_read_byte(&rows[r]);
        if (in != 0xFF) tft.fillRect(x + in, y + r, 24 - 2 * in, 1, c);
    }
}

// Four-colour flag 14×12 (token themeXP.taskbar.start.flag): R/G/B/Y cells.
const char kFlag[12][15] PROGMEM = {
    "........GGGGG.", "...RRRR.GGGGGG", ".RRRRRR.GGGGGG", ".RRRRRR.GGGGGG",
    ".RRRRRR.GGGGGG", "RRRRRRR.......", ".......YYYYYY.", "BBBBBB.YYYYYY.",
    "BBBBBB.YYYYYY.", "BBBBBB.YYYYYY.", "BBBBBB.YYYYY..", ".BBBB.........",
};
uint16_t flagColor(char c) {
    switch (c) {
        case 'R': return FLAG_RED;
        case 'G': return FLAG_GREEN;
        case 'B': return FLAG_BLUE;
        default:  return FLAG_YELLOW;
    }
}

}  // namespace

namespace XP {

void drawFlag(int x, int y, int scale) {
    for (int r = 0; r < 12; r++)
        for (int i = 0; i < 14;) {
            char ch = (char)pgm_read_byte(&kFlag[r][i]);
            int run = 1;
            while (i + run < 14 && (char)pgm_read_byte(&kFlag[r][i + run]) == ch) run++;
            if (ch != '.') tft.fillRect(x + i * scale, y + r * scale, run * scale, scale, flagColor(ch));
            i += run;
        }
}

void drawBits(const uint8_t* bits, int w, int h, int x, int y, uint16_t color) {
    const int nb = (w + 7) / 8;
    for (int r = 0; r < h; r++) {
        const uint8_t* row = bits + r * nb;
        for (int i = 0; i < w;) {
            if (!(pgm_read_byte(&row[i >> 3]) & (0x80 >> (i & 7)))) { i++; continue; }
            int run = 1;
            while (i + run < w && (pgm_read_byte(&row[(i + run) >> 3]) & (0x80 >> ((i + run) & 7)))) run++;
            tft.fillRect(x + i, y + r, run, 1, color);
            i += run;
        }
    }
}

void fitText(char* s, int maxW) {
    size_t n = strlen(s);
    while (n && tft.textWidth(s) > maxW) {
        n = Utf8::prevChar(s, n);
        s[n] = '\0';
    }
}

void iconSize(Icon icon, int& w, int& h) {
    IconBits b = bitsOf(icon);
    w = b.w; h = b.h;
}

void drawIcon(Icon icon, int x, int y, int scale, uint16_t color) {
    IconBits ic = bitsOf(icon);
    if (!ic.rows) return;
    for (int r = 0; r < ic.h; r++) {
        uint32_t row = pgm_read_dword(&ic.rows[r]);
        for (int c = 0; c < ic.w;) {
            if (!(row >> (ic.w - 1 - c) & 1)) { c++; continue; }
            int run = 0;
            while (c + run < ic.w && (row >> (ic.w - 1 - c - run) & 1)) run++;
            tft.fillRect(x + c * scale, y + r * scale, run * scale, scale, color);
            c += run;
        }
        // Clawd's eye holes are black on every background (P-2026-11-26.11):
        // off cells inside the head (rows 1–3, columns 3–14).
        if (icon == XPCore::ICON_CLAWD && r >= 1 && r <= 3) {
            const uint32_t head = pgm_read_dword(&ic.rows[0]);
            for (int c = 0; c < ic.w; c++) {
                const uint32_t bit = 1u << (ic.w - 1 - c);
                if ((head & bit) && !(row & bit))
                    tft.fillRect(x + c * scale, y + r * scale, scale, scale, 0x0000);
            }
        }
    }
}

void setDefaultIcon(Icon icon) { s_defaultIcon = icon; }
Icon defaultIcon() { return s_defaultIcon; }
const char* title() { return s_title; }

void titleBar(const char* t, Icon icon) {
    Utf8::copy(s_title, sizeof(s_title), t);
    if (!Display::clipHits(0, 0, SCREEN_W, 22)) return;   // clipped repaint below the title bar
    titleBands(0, SCREEN_W);
    titleIcon(icon);
    paintTitleText(s_title);
    // P-2026-11-27.24: _ and × light under the mouse (XP Luna hot), □ never.
    captionButton(184, s_hot == PointerCore::kHotMin ? TITLE_HI : TITLE_LIGHT, '_');
    captionButton(202, TITLE_LIGHT, 'o');
    captionButton(220, s_hot == PointerCore::kHotClose ? CLOSE_HOT : CLOSE, 'x');
}

void setHot(int8_t hot) { s_hot = hot; }
int8_t hot() { return s_hot; }

void titleMeta(const char* meta) {
    char t[80];
    if (meta && *meta) snprintf(t, sizeof(t), "%s \xC2\xB7 %s", s_title, meta);
    else Utf8::copy(t, sizeof(t), s_title);
    titleBands(kTitleSlotX, kTitleSlotW);
    paintTitleText(t);
}

void window(const char* t, Icon icon, bool status) {
    using namespace Layout;
    titleBar(t, icon);
    tft.fillRect(0, XP_BODY_Y, XP_FRAME_W, XP_BODY_H, FRAME);
    tft.fillRect(SCREEN_W - XP_FRAME_W, XP_BODY_Y, XP_FRAME_W, XP_BODY_H, FRAME);
    tft.fillRect(XP_BODY_X, XP_BODY_Y, XP_BODY_W, XP_BODY_H, BODY);
    if (status) statusBar("", "");
}

void statusBar(const char* left, const char* right, uint16_t leftColor, uint16_t rightColor) {
    using namespace Layout;
    const int y = XP_STATUS_Y;
    if (!Display::clipHits(0, y, SCREEN_W, XP_BOTTOM - y)) return;
    tft.fillRect(XP_BODY_X, y, XP_BODY_W, 1, STATUS_LINE);
    tft.fillRect(XP_BODY_X, y + 1, XP_BODY_W, 1, WHITE);
    tft.fillRect(XP_BODY_X, y + 2, XP_BODY_W, XP_BOTTOM - y - 2, BODY);
    Display::useFont("JBMono-11");
    char l[64]; Utf8::copy(l, sizeof(l), left ? left : "");
    int leftMax = 231 - 8;
    if (right && *right) {
        char r[48]; Utf8::copy(r, sizeof(r), right);
        fitText(r, XPCore::statusRightMax(l[0] ? tft.textWidth(l) : 0));
        int dx = XPCore::statusDividerX(tft.textWidth(r));
        tft.fillRect(dx, y + 2, 1, 15, STATUS_LINE);
        tft.setTextDatum(TR_DATUM);
        tft.setTextColor(rightColor, BODY);
        tft.drawString(r, 231, y + 3);
        leftMax = dx - 4 - 8;
    }
    if (l[0]) {
        fitText(l, leftMax);
        tft.setTextDatum(TL_DATUM);
        tft.setTextColor(leftColor, BODY);
        tft.drawString(l, 8, y + 3);
    }
}

void progress(int x, int y, int w, int h, float pct, uint16_t on, int padY) {
    tft.drawRect(x, y, w, h, FIELD_BORDER);
    tft.fillRect(x + 1, y + 1, w - 2, h - 2, WHITE);
    XPCore::Blocks b = XPCore::blocks(x, y, w, h, padY);
    int bx = b.x0;
    for (int i = 0; i < 9; i++) {
        int bw = i == 8 ? b.lastW : b.w;
        if (XPCore::blockLit(pct, i)) tft.fillRect(bx, b.y0, bw, b.h, on);
        bx += b.w + b.gap;
    }
}

void groupLabel(int x, int y, const char* label, int clearW, uint16_t bg) {
    Display::useFont("JBMono-11");
    int tw = label && *label ? tft.textWidth(label) : 0;
    int pw = tw + 6 > clearW ? tw + 6 : clearW;
    tft.fillRect(x + 4, y - 6, pw, 13, bg);
    if (!tw) return;
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(GROUP_LABEL, bg);
    tft.drawString(label, x + 7, y - 6);
}

void groupBox(int x, int y, int w, int h, const char* label, uint16_t bg) {
    tft.drawRect(x, y, w, h, GROUP);
    if (Display::clipHits(x, y - 7, w, 16)) groupLabel(x, y, label, 0, bg);
}

void tabs(const char* const* labels, int n, int selected) {
    // Page: FIELD_BORDER 1 px (6, 41, 228×169), white inside.
    tft.drawRect(6, 41, 228, 169, FIELD_BORDER);
    tft.fillRect(7, 42, 226, 167, WHITE);
    tft.fillRect(6, 26, 228, 15, BODY);                    // the strip above the page
    if (!Display::clipHits(6, 26, 228, 16)) return;        // clipped repaint inside the page
    Display::useFont("JBMono-11");
    tft.setTextDatum(TL_DATUM);
    int x = 6, selX = 6, selW = 0;
    for (int i = 0; i < n; i++) {
        const int w = tft.textWidth(labels[i]) + 10;
        if (i == selected) { selX = x; selW = w; x += w; continue; }
        // Unselected: y 28–40, 1 px narrower than its slot, xpRowLine face.
        tft.drawRect(x, 28, w - 1, 14, FIELD_BORDER);
        tft.fillRect(x + 1, 29, w - 3, 12, ROW_LINE);
        tft.setTextColor(BLACK, ROW_LINE);
        tft.drawString(labels[i], x + 5, 29);
        x += w;
    }
    if (selW) {
        // Selected: y 26–41, orange / yellow hot top, white face joined to the page.
        tft.drawFastHLine(selX, 26, selW, WELCOME_ORANGE);
        tft.fillRect(selX, 27, selW, 2, FLAG_YELLOW);
        tft.drawFastVLine(selX, 27, 15, FIELD_BORDER);
        tft.drawFastVLine(selX + selW - 1, 27, 15, FIELD_BORDER);
        tft.fillRect(selX + 1, 29, selW - 2, 13, WHITE);
        tft.setTextColor(BLACK, WHITE);
        tft.drawString(labels[selected], selX + 5, 29);
    }
}

WxIcon wxIconFor(uint8_t code) {
    if (code <= 1) return WX_SUN;                          // clear, mainly clear
    if (code <= 3 || code == 45 || code == 48) return WX_PARTLY;   // cloudy, fog
    return WX_RAIN;                                        // drizzle, rain, snow, showers, storms
}

void weatherIcon(uint8_t code, int x, int y, bool big) {
    static const Ink kInks[] = {{'Y', ICON_WARN}, {'A', AMBER}, {'G', FIELD_BORDER}, {'W', WHITE}, {'B', ICON_INFO}};
    const int s = big ? 32 : 16;
    const char* art;
    switch (wxIconFor(code)) {
        case WX_SUN:    art = big ? kWxSun32 : kWxSun16; break;
        case WX_PARTLY: art = big ? kWxPartly32 : kWxPartly16; break;
        default:        art = big ? kWxRain32 : kWxRain16; break;
    }
    drawArt(art, s, s, x, y, kInks, 5);
}

void field(int x, int y, int w, int h) {
    tft.drawRect(x, y, w, h, FIELD_BORDER);
    tft.fillRect(x + 1, y + 1, w - 2, h - 2, WHITE);
}

void dialogIcon(Dialog kind, int x, int y) {
    tft.fillRect(x, y, 24, 24, BODY);
    switch (kind) {
        case DLG_ERROR:
            insetShape(kCircle24, x, y, ICON_ERROR);
            for (int r = 0; r < 10; r++) {
                tft.fillRect(x + 7 + r, y + 7 + r, 2, 2, WHITE);
                tft.fillRect(x + 15 - r, y + 7 + r, 2, 2, WHITE);
            }
            break;
        case DLG_WARN:
            insetShape(kTriangle24, x, y, ICON_WARN);
            tft.fillRect(x + 11, y + 8, 3, 8, BLACK);
            tft.fillRect(x + 11, y + 18, 3, 3, BLACK);
            break;
        default:
            insetShape(kCircle24, x, y, ICON_INFO);
            tft.fillRect(x + 10, y + 5, 4, 3, WHITE);
            tft.fillRect(x + 10, y + 10, 4, 9, WHITE);
            break;
    }
}

void dialog(Dialog kind, const char* head, const char* const* lines, int n,
            const char* link, const char* sub) {
    dialogIcon(kind, 14, 36);
    tft.setTextDatum(TL_DATUM);
    Display::useFont("JBMono-12B");
    tft.setTextColor(BLACK, BODY);
    if (head) tft.drawString(head, 48, 38);
    Display::useFont("JBMono-11");
    tft.setTextColor(LABEL, BODY);
    int y = 58;
    for (int i = 0; i < n; i++, y += 16)
        if (lines[i] && *lines[i]) tft.drawString(lines[i], 48, y);
    int ly = n ? y - 16 + 22 : 58;
    if (link && *link) {
        Display::useFont("JBMono-12B");
        tft.setTextColor(LINK, BODY);
        tft.drawString(link, 48, ly);
        tft.drawFastHLine(48, ly + 14, tft.textWidth(link), LINK);
        if (sub && *sub) {
            Display::useFont("JBMono-11");
            tft.setTextColor(MUTED, BODY);
            tft.drawString(sub, 48, ly + 20);
        }
    }
}

void marquee(int x, int y, int w, int h, uint32_t step) {
    field(x, y, w, h);
    XPCore::Blocks b = XPCore::blocks(x, y, w, h, 2);   // loading box: 13×8 cells at y+3
    for (int i = 0; i < XPCore::kMarqueeCells; i++)
        if (XPCore::marqueeLit(step, i))
            tft.fillRect(b.x0 + i * (b.w + b.gap), b.y0, b.w, b.h, BAR);
}

void hourglass(int frame, int x, int y) {
    static const Ink kGlass[] = {{'X', BLACK}, {'W', WHITE}, {'S', AMBER}};
    switch (frame & 3) {
        case 0:  drawArt(kGlass0, 9, 12, x + 10, y + 9, kGlass, 3); break;
        case 1:  drawArt(kGlass1, 9, 12, x + 10, y + 9, kGlass, 3); break;
        case 2:  drawArt(kGlass2, 9, 12, x + 10, y + 9, kGlass, 3); break;
        default: drawArt(kGlass3, 12, 9, x + 8, y + 11, kGlass, 3); break;
    }
}

// P-2026-11-27.24: in mouse mode the cursor itself turns into Working in
// Background where it is (cursor.cpp); the fixed cell (132, 160) only without.
void waitCursor(uint32_t step) {
    if (Cursor::busy(millis())) return;
    static const Ink kArrowInk[] = {{'X', BLACK}, {'W', WHITE}};
    tft.fillRect(132, 160, 21, 22, BODY);        // the cursor's cell (arrow + hourglass)
    drawArt(kArrow, 12, 19, 132, 160, kArrowInk, 2);
    hourglass(XPCore::hourglassFrame(step), 132, 160);
}

void emptyFrame(const char* title, Icon icon, bool status) {
    window(title, icon, status);
    waitCursor(0);
}

void zoom(int slot, bool restore) {
    for (int k = 1; k <= XPCore::kZoomSteps; k++) {
        const int i = restore ? k : XPCore::kZoomSteps + 1 - k;
        const XPCore::Rect r = XPCore::zoomRect(slot, i);
        tft.fillRect(r.x, r.y, r.w, r.h, TITLE);
        tft.drawFastHLine(r.x, r.y, r.w, TITLE_HI);
        tft.drawFastHLine(r.x, r.y + 1, r.w, TITLE_LIGHT);
        tft.drawFastHLine(r.x, r.y + r.h - 1, r.w, TITLE_EDGE);
        delay(XPCore::kZoomStepMs);              // yields to Wi-Fi
    }
}

void loading(const char* label, const char* source) {
    static const Ink kGlobeInk[] = {{'E', TITLE_EDGE}, {'B', ICON_INFO}, {'L', GREEN}};
    static const Ink kFolderInk[] = {{'D', AMBER}, {'F', USER_PIC}};
    drawArt(kGlobe, 24, 24, 30, 36, kGlobeInk, 3);
    drawArt(kFolder, 24, 20, 186, 38, kFolderInk, 2);
    s_paperAt = -1;
    drawPaper(0);
    Display::useFont("JBMono-12B");
    tft.setTextDatum(TC_DATUM);
    tft.setTextColor(BLACK, BODY);
    tft.drawString(label, 120, 92);
    marquee(50, 116, 140, 14, 0);
    if (source && *source) {
        Display::useFont("JBMono-11");
        tft.setTextColor(MUTED, BODY);
        tft.drawString(source, 120, 140);
    }
    waitCursor(0);
}

void loadingStep(uint32_t step) {
    marquee(50, 116, 140, 14, step);
    const int i = (int)(step % XPCore::kPaperN);
    if (i != s_paperAt) drawPaper(i);
    waitCursor(step);
}

void infoStrip(int x, int y, int w, const char* text, uint16_t textColor) {
    static const uint8_t kBang[5] = {0x04, 0x0E, 0x0A, 0x1F, 0x1B};   // 5×5, bit 4 = left
    tft.fillRect(x, y, w, 14, INFO_BAR);
    for (int r = 0; r < 5; r++)
        for (int c = 0; c < 5; c++)
            if (kBang[r] >> (4 - c) & 1) tft.drawPixel(x + 4 + c, y + 3 + r, AMBER);
    if (!text || !*text) return;
    char t[64]; Utf8::copy(t, sizeof(t), text);
    Display::useFont("JBMono-11");
    fitText(t, w - 15);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(textColor, INFO_BAR);
    tft.drawString(t, x + 13, y + 1);
}

void drawNoChannels() {
    window("glimmer", XPCore::ICON_CLAWD);
    static const char* const kLines[] = {"Bật kênh trên trang web:"};
    char url[32]; snprintf_P(url, sizeof(url), PSTR("%s.local"), MDNS_HOSTNAME);
    dialog(DLG_INFO, "Chưa có kênh", kLines, 1, url);
}

}  // namespace XP
