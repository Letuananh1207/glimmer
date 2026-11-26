// XP (Luna) window chrome + components — see xp.h. Geometry from
// design/panel/source/XP-*.dc.html and token themeXP (P-2026-11-26.8/.9).

#include "xp.h"
#include "display.h"
#include "layout.h"
#include "config.h"
#include "utf8.h"

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

// 16×16 caption button at (x, 3): 1-px white border, fill, glyph.
void captionButton(int x, uint16_t fill, char kind) {
    const int y = 3;
    tft.fillRect(x, y, 16, 16, WHITE);
    tft.fillRect(x + 1, y + 1, 14, 14, fill);
    switch (kind) {
        case '_': tft.fillRect(x + 4, y + 10, 6, 2, WHITE); break;
        case 'o':   // maximise: 8×8 box with a 2-px top
            tft.drawRect(x + 4, y + 3, 8, 8, WHITE);
            tft.drawFastHLine(x + 4, y + 4, 8, WHITE);
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
    titleBands(0, SCREEN_W);
    titleIcon(icon);
    paintTitleText(s_title);
    captionButton(184, TITLE_LIGHT, '_');
    captionButton(202, TITLE_LIGHT, 'o');
    captionButton(220, CLOSE, 'x');
}

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

void groupLabel(int x, int y, const char* label, int clearW) {
    Display::useFont("JBMono-11");
    int tw = label && *label ? tft.textWidth(label) : 0;
    int pw = tw + 6 > clearW ? tw + 6 : clearW;
    tft.fillRect(x + 4, y - 6, pw, 13, BODY);
    if (!tw) return;
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(GROUP_LABEL, BODY);
    tft.drawString(label, x + 7, y - 6);
}

void groupBox(int x, int y, int w, int h, const char* label) {
    tft.drawRect(x, y, w, h, GROUP);
    groupLabel(x, y, label);
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

void loading(const char* label) {
    Display::useFont("JBMono-12B");
    tft.setTextDatum(TC_DATUM);
    tft.setTextColor(BLACK, BODY);
    tft.drawString(label, 120, 92);
    marquee(50, 116, 140, 14, 0);
}

void loadingStep(uint32_t step) { marquee(50, 116, 140, 14, step); }

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
