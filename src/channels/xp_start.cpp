// XP Start menu — see xp_start.h. Geometry and colours: design/panel/source/XP-Start-All.dc.html.

#include "xp_start.h"
#include "display.h"
#include "theme.h"
#include "start_icons.h"
#include "desk_icons.h"
#include "skill_core.h"

using namespace Theme::XP;

namespace {

// Colours of the Start menu (themeXP.startMenu, from the source).
constexpr uint16_t kBand[6]    = {0x3CBF, 0x2C1E, 0x1B5D, 0x0ADB, 0x0A9A, 0x0A79};   // #3D95FF … #0B4CC8
constexpr uint8_t  kBandY[7]   = {0, 6, 11, 16, 22, 27, 32};
constexpr uint16_t kBandHi     = 0x5CDE;   // #5A9BF6
constexpr uint16_t kPicSky     = 0x961E;   // #93C0F3
constexpr uint16_t kPicGrass   = 0x75E6;   // #76BE37
constexpr uint16_t kOrange     = 0xF506;   // #F0A030
constexpr uint16_t kOrangeEnd  = 0xF64F;   // #F7C97A
constexpr uint16_t kOrangeDark = 0xBB23;   // #B8661E
constexpr uint16_t kColEdge    = 0x95FD;   // #95BDEE
constexpr uint16_t kRight      = 0xD73F;   // #D3E5FA
constexpr uint16_t kBottom[5]  = {0x443E, 0x2B9D, 0x1B3B, 0x12DA, 0x1278};   // #4285F4 … #134CC2

// Labels in flash, copied to the stack to draw.
const char kClawd[] PROGMEM = "Clawd";
const char kClaude[] PROGMEM = "Claude";
const char kCodex[] PROGMEM = "Codex";
const char kUsage[] PROGMEM = "mức dùng";
const char kPhoto[] PROGMEM = "Ảnh";
const char kWeather[] PROGMEM = "Thời tiết";
const char kClock[] PROGMEM = "Đồng hồ";
const char kAll[] PROGMEM = "Tất cả chương trình";
const char kDesktop[] PROGMEM = "Desktop";
const char kStats[] PROGMEM = "Số liệu";
const char kSettings[] PROGMEM = "Cài đặt";
const char kAddRemove[] PROGMEM = "Thêm / gỡ";
const char kDevice[] PROGMEM = "Thiết bị";
const char kRestart[] PROGMEM = "Khởi động lại";
const char kTurnOff[] PROGMEM = "Tắt màn";

void text(const char* p, const char* font, int x, int y, uint16_t fg, uint16_t bg) {
    char t[40];
    strncpy_P(t, p, sizeof(t));
    t[sizeof(t) - 1] = 0;
    Display::useFont(font);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(fg, bg);
    tft.drawString(t, x, y);
}

// A colour icon of runs (tools/deskicons.py), transparent cells left as they are.
template <typename Run>
void runs(const Run* r, int n, const uint16_t* pal, int x0, int y0) {
    for (int k = 0; k < n; k++) {
        Run q;
        memcpy_P(&q, &r[k], sizeof(q));
        tft.fillRect(x0 + q.x, y0 + q.y, q.w, 1, pgm_read_word(&pal[q.c]));
    }
}
#define ICON(NS, N, X, Y) runs(NS::k##N##Runs, NS::k##N##RunCount, NS::k##N##Pal, (X), (Y))

void userBand() {
    for (int b = 0; b < 6; b++) tft.fillRect(0, kBandY[b], 240, kBandY[b + 1] - kBandY[b], kBand[b]);
    tft.drawFastHLine(3, 0, 234, kBandHi);
    tft.fillRect(5, 4, 24, 24, WHITE);                  // picture frame
    tft.fillRect(6, 5, 22, 22, MENU_BORDER);
    tft.fillRect(7, 6, 20, 14, kPicSky);
    tft.fillRect(7, 20, 20, 6, kPicGrass);
    ICON(StartIcons, UserClawd, 9, 11);
    text(kClawd, "JBMono-16B", 36, 8, TITLE_SHADOW, kBand[1]);
    text(kClawd, "JBMono-16B", 35, 7, WHITE, kBand[1]);
    tft.drawFastHLine(0, 32, 240, kOrange);
    tft.drawFastHLine(0, 32, 20, kOrangeEnd);
    tft.drawFastHLine(220, 32, 20, kOrangeEnd);
    tft.drawFastHLine(0, 33, 240, kOrangeDark);
}

// Left column: pinned agent programs, the others by skill, All Programs.
void leftColumn(const char* on, bool all) {
    const bool agent = Skill::inList(on, "agent");
    int y = 38;
    if (agent) {
        ICON(StartIcons, PinClawd, 3, 39);
        text(kClaude, "JBMono-12B", 42, 37, BLACK, WHITE);
        text(kUsage, "JBMono-11", 42, 51, MUTED, WHITE);
        ICON(DeskIcons, Codex, 5, 65);
        text(kCodex, "JBMono-12B", 42, 66, BLACK, WHITE);
        text(kUsage, "JBMono-11", 42, 80, MUTED, WHITE);
        tft.drawFastHLine(6, 95, 140, ROW_LINE);
        y = 99;
    }
    if (Skill::inList(on, "photo"))   { ICON(StartIcons, Photo, 6, y + 3);   text(kPhoto, "JBMono-11", 28, y + 4, BLACK, WHITE);   y += 20; }
    if (Skill::inList(on, "weather")) { ICON(StartIcons, Weather, 6, y + 2); text(kWeather, "JBMono-11", 28, y + 4, BLACK, WHITE); y += 20; }
    if (Skill::inList(on, "clock"))   { ICON(StartIcons, Clock, 6, y + 2);   text(kClock, "JBMono-11", 28, y + 4, BLACK, WHITE);   y += 20; }
    tft.drawFastHLine(6, 163, 140, ROW_LINE);
    const uint16_t bg = all ? SELECT : WHITE;
    if (all) tft.fillRect(2, 167, 149, 20, SELECT);
    text(kAll, "JBMono-12B", 4, 170, all ? WHITE : BLACK, bg);
    ICON(StartIcons, AllArrow, 138, 171);
}

void rightColumn() {
    ICON(StartIcons, Desktop, 156, 40);   text(kDesktop, "JBMono-12B", 175, 41, TITLE_SHADOW, kRight);
    ICON(StartIcons, Stats, 156, 61);     text(kStats, "JBMono-12B", 175, 62, TITLE_SHADOW, kRight);
    tft.drawFastHLine(157, 83, 78, DIVIDER);
    ICON(StartIcons, Settings, 156, 90);  text(kSettings, "JBMono-11", 175, 91, TITLE_SHADOW, kRight);
    ICON(StartIcons, AddRemove, 156, 111); text(kAddRemove, "JBMono-11", 175, 112, TITLE_SHADOW, kRight);
    ICON(StartIcons, Device, 156, 132);   text(kDevice, "JBMono-11", 175, 133, TITLE_SHADOW, kRight);
}

void bottomBand() {
    for (int b = 0; b < 5; b++) tft.fillRect(0, 190 + 5 * b, 240, b == 4 ? 4 : 5, kBottom[b]);
    tft.drawFastHLine(0, 190, 240, TASK_HI);
    ICON(StartIcons, Restart, 8, 194);
    text(kRestart, "JBMono-11", 27, 196, WHITE, kBottom[1]);
    ICON(StartIcons, Power, 165, 194);
    text(kTurnOff, "JBMono-11", 184, 196, WHITE, kBottom[1]);
}

// All Programs sub-menu (151, 62, 89 wide): installed programs, —, Thêm / gỡ.
void allPrograms(const char* on) {
    const bool agent = Skill::inList(on, "agent");
    const int n = (agent ? 2 : 0) + Skill::inList(on, "photo") + Skill::inList(on, "weather") + Skill::inList(on, "clock");
    const int h = 4 + 20 * n + 7 + 20;
    tft.fillRect(151, 62, 89, h, MENU_BORDER);
    tft.fillRect(152, 63, 87, h - 2, WHITE);
    int y = 64;
    if (agent) {
        ICON(StartIcons, SmallClawd, 154, y + 5); text(kClaude, "JBMono-11", 173, y + 4, BLACK, WHITE); y += 20;
        ICON(StartIcons, SmallCodex, 154, y + 4); text(kCodex, "JBMono-11", 173, y + 4, BLACK, WHITE);  y += 20;
    }
    if (Skill::inList(on, "photo"))   { ICON(StartIcons, Photo, 154, y + 3);   text(kPhoto, "JBMono-11", 173, y + 4, BLACK, WHITE);   y += 20; }
    if (Skill::inList(on, "weather")) { ICON(StartIcons, Weather, 154, y + 2); text(kWeather, "JBMono-11", 173, y + 4, BLACK, WHITE); y += 20; }
    if (Skill::inList(on, "clock"))   { ICON(StartIcons, Clock, 154, y + 2);   text(kClock, "JBMono-11", 173, y + 4, BLACK, WHITE);   y += 20; }
    tft.drawFastHLine(155, y + 3, 81, MENU_BORDER);
    y += 7;
    ICON(StartIcons, AddRemove, 154, y + 2);
    text(kAddRemove, "JBMono-11", 173, y + 4, BLACK, WHITE);
}

}  // namespace

namespace XPStart {

void draw(const Control::Menu& m, const char* skillsOn) {
    userBand();
    tft.fillRect(0, 34, 240, 156, BTN_EDGE);            // body: blue edges x 0 / 239
    tft.fillRect(1, 34, 151, 156, WHITE);
    tft.drawFastVLine(152, 34, 156, kColEdge);
    tft.fillRect(153, 34, 86, 156, kRight);
    leftColumn(skillsOn, m.all);
    rightColumn();
    bottomBand();
    if (m.all) allPrograms(skillsOn);
}

}  // namespace XPStart
