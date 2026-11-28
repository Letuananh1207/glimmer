// Explorer — XP "Windows Explorer" for Máy tính / Ảnh của tôi / Thùng rác (P-2026-11-28.32, screen_specs §17
// XP-Explorer, sources XP-Explorer-Computer|Photos|Confirm|Trash|TrashEmpty.dc.html). A system program: one
// window, three places (the title = the place); no toolbar / address bar / task pane (no room). The app opens
// it (Start › Thiết bị = Máy tính, the desktop Thùng rác icon = Thùng rác) and sends the place, the selected
// item, the scroll row and the confirm box (POST /api/explorer); deleting / restoring / emptying are its
// commands too ("do"), carried out by trash.cpp.
//
//   body        white (2, 22, 236×174); status bar 2 sunken cells x 3–150 / 152–236
//   Máy tính    Ổ đĩa: drive 32×23, Bộ nhớ (C:) + bar + "trống 412 KB / 1 MB"; Thư mục: Ảnh của tôi
//               (My Pictures 32×23, "8 tệp · 214 KB"), Hình nền (folder, "wallpaper.jpg")
//   Ảnh của tôi thumbnails 1/4 (47×47) in 51×51 frames, 4 a row, names under them; selected = xpSelect
//   Thùng rác   Dọn sạch Thùng rác / Khôi phục (dim when empty) + Details list Tên | Cỡ | Đã xoá
//   confirm     XP's Confirm File Delete box over the window (Có preselected, Không)
//
// Repaint-safe: each thumbnail decodes only when the clip covers it.

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "utf8.h"
#include "xp.h"
#include "xp_core.h"
#include "explorer_core.h"
#include "photos.h"
#include "trash.h"
#include "wallpaper.h"
#include "desk_icons.h"
#include "xp_icons.h"
#include "start_icons.h"
#include <time.h>

namespace C = Theme::XP;
using namespace ExplorerCore;

extern const ExplorerCore::View& mainExplorerView();

static constexpr uint16_t kFrame = 0xAD53, kRule = 0xD69A;            // #ACA899 #D0D0BF
static View   s_view;
static int8_t s_hot = -1;                                             // 0 Dọn sạch, 1 Khôi phục, 2 Không

struct P { char b[48]; explicit P(PGM_P s) { strncpy_P(b, s, sizeof(b)); b[sizeof(b) - 1] = 0; } };
#define F_(s) (P(PSTR(s)).b)

template <typename Run>
static void runs(const Run* r, int n, const uint16_t* pal, int x0, int y0) {
    for (int k = 0; k < n; k++) {
        Run q; memcpy_P(&q, &r[k], sizeof(q));
        tft.fillRect(x0 + q.x, y0 + q.y, q.w, 1, pgm_read_word(&pal[q.c]));
    }
}
#define ICON(NS, N, X, Y) runs(NS::k##N##Runs, NS::k##N##RunCount, NS::k##N##Pal, (X), (Y))

static void text(const char* t, int x, int y, uint16_t fg, uint16_t bg, const char* font = "JBMono-11",
                 uint8_t datum = TL_DATUM) {
    Display::useFont(font);
    tft.setTextDatum(datum);
    tft.setTextColor(fg, bg);
    tft.drawString(t, x, y);
}

static XPCore::Icon placeIcon(uint8_t place) {
    if (place == PLACE_PHOTOS) return XPCore::ICON_PICTURES;
    if (place == PLACE_TRASH) return Trash::count() ? XPCore::ICON_TRASH_FULL : XPCore::ICON_TRASH;
    return XPCore::ICON_COMPUTER;
}

// ── status bar: 2 sunken cells ──
static void statusCells(const char* left, const char* right) {
    if (!Display::clipHits(2, 196, 236, 18)) return;
    tft.fillRect(2, 196, 236, 18, C::BODY);
    tft.drawFastHLine(2, 196, 236, C::DIM);
    const int xs[2] = {3, 152}, ws[2] = {148, 85};
    const char* ts[2] = {left, right};
    for (int i = 0; i < 2; i++) {
        const int x = xs[i], w = ws[i];
        tft.drawFastHLine(x, 199, w - 1, C::DIM);
        tft.drawFastVLine(x, 199, 13, C::DIM);
        tft.drawFastHLine(x, 211, w - 1, C::WHITE);
        tft.drawFastVLine(x + w - 2, 199, 13, C::WHITE);
        text(ts[i], x + 4, 199, C::BLACK, C::BODY);
    }
}

// ── Máy tính ──
static void groupHead(const char* t, int y) {
    text(t, 8, y, C::GROUP_LABEL, C::WHITE, "JBMono-12B");
    tft.drawFastHLine(8, y + 15, 140, C::DIVIDER_FADE);
    tft.drawFastHLine(148, y + 15, 40, C::DIVIDER);
}

static uint32_t photosBytes() {
    uint32_t b = 0;
    for (int i = 0; i < Photos::total(); i++) b += Photos::size(i);
    return b;
}

static void placeComputer() {
    char b[40];
    if (Display::clipHits(2, 22, 236, 76)) {
        groupHead(F_("Ổ đĩa"), 26);
        ICON(XpIcons, Drive, 10, 50);
        text(F_("Bộ nhớ (C:)"), 48, 47, C::BLACK, C::WHITE);
        const uint32_t fr = Photos::fsFree(), tot = Photos::fsTotal();
        tft.drawRect(48, 62, 122, 10, C::FIELD_BORDER);
        tft.fillRect(49, 63, 120, 8, C::WHITE);
        tft.fillRect(49, 63, driveUsedW(fr, tot), 8, C::USER_SEL);
        driveText(fr, tot, b, sizeof(b));
        text(b, 48, 75, C::LABEL, C::WHITE);
    }
    if (Display::clipHits(2, 98, 236, 98)) {
        groupHead(F_("Thư mục"), 98);
        ICON(DeskIcons, Photo, 10, 122);
        text(F_("Ảnh của tôi"), 48, 121, C::BLACK, C::WHITE);
        snprintf_P(b, sizeof(b), PSTR("%d tệp \xC2\xB7 %lu KB"), Photos::total(),
                   (unsigned long)((photosBytes() + 1023) / 1024));
        text(b, 48, 135, C::LABEL, C::WHITE);
        ICON(XpIcons, Folder, 10, 160);
        text(F_("Hình nền"), 48, 159, C::BLACK, C::WHITE);
        text(Wallpaper::present() ? "wallpaper.jpg" : F_("(trống)"), 48, 173, C::LABEL, C::WHITE);
    }
    statusCells(F_("3 đối tượng"), F_("Máy tính"));
}

// ── Ảnh của tôi ──
static void thumb(int i) {
    int x, y;
    if (!thumbCell(i, s_view.top, x, y) || !Display::clipHits(x, y, kCellW, kCellH)) return;
    const bool lit = i == s_view.sel;
    tft.fillRect(x, y, kCellW, kCellH, C::WHITE);
    tft.drawRect(x + 3, y, 51, 51, lit ? C::SELECT : kFrame);
    tft.fillRect(x + 4, y + 1, 49, 49, C::WHITE);
    Photos::drawThumb(i, x + 5, y + 2);
    char file[16], shown[20];
    Photos::name(i, file, sizeof(file));
    shownName(file, shown, sizeof(shown));
    Display::useFont("JBMono-11");
    XP::fitText(shown, kCellW);
    if (lit) tft.fillRect(x + 1, y + 53, 55, 14, C::SELECT);
    text(shown, x + kCellW / 2, y + 53, lit ? C::WHITE : C::BLACK, lit ? C::SELECT : C::WHITE, "JBMono-11", TC_DATUM);
}

static void placePhotos() {
    for (int i = 0; i < Photos::total(); i++) thumb(i);
    char b[40];
    objectsText(Photos::total(), photosBytes(), true, b, sizeof(b));
    statusCells(b, F_("Ảnh của tôi"));
}

// ── Thùng rác ──
static void trashButtons() {
    const bool any = Trash::count() > 0;
    XP::pushButton(kEmptyBtn.x, kEmptyBtn.y, kEmptyBtn.w, kEmptyBtn.h, F_("Dọn sạch Thùng rác"),
                   !any ? XP::BTN_DIM : s_hot == 0 ? XP::BTN_HOT : XP::BTN_UP);
    XP::pushButton(kRestoreBtn.x, kRestoreBtn.y, kRestoreBtn.w, kRestoreBtn.h, F_("Khôi phục"),
                   !any ? XP::BTN_DIM : s_hot == 1 ? XP::BTN_HOT : XP::BTN_UP);
}

static void trashRow(int i, const Entry& e) {
    const int y = kRowY + kRowH * i;
    if (!Display::clipHits(7, y, 226, kRowH)) return;
    const bool lit = i == s_view.sel;
    const uint16_t bg = lit ? C::SELECT : C::WHITE, fg = lit ? C::WHITE : C::BLACK;
    tft.fillRect(7, y, 226, kRowH, bg);
    ICON(StartIcons, Photo, 10, y + 2);
    char b[20];
    shownName(e.name, b, sizeof(b));
    text(b, 30, y + 2, fg, bg);
    sizeText(e.size, b, sizeof(b));
    text(b, 110, y + 2, fg, bg);
    const time_t at = (time_t)e.at, now = time(nullptr);
    struct tm ta, tn;
    localtime_r(&at, &ta);
    localtime_r(&now, &tn);
    const long dayAt = ta.tm_year * 400L + ta.tm_yday, dayNow = tn.tm_year * 400L + tn.tm_yday;
    deletedText(e.at, dayAt, dayNow, ta.tm_hour * 60 + ta.tm_min, ta.tm_mday, ta.tm_mon + 1, b, sizeof(b));
    text(b, 168, y + 2, fg, bg);
}

static void placeTrash() {
    if (Display::clipHits(2, 22, 236, 28)) tft.fillRect(2, 22, 236, 28, C::BODY);
    trashButtons();
    if (Display::clipHits(6, 52, 228, 140)) {
        tft.drawRect(6, 52, 228, 140, C::FIELD_BORDER);
        tft.fillRect(7, 53, 226, 138, C::WHITE);
        tft.fillRect(7, 53, 226, 15, C::BODY);
        tft.drawFastHLine(7, 68, 226, kRule);
        tft.drawFastHLine(7, 69, 226, C::DIM);
        tft.fillRect(104, 56, 1, 10, C::DIM);
        tft.fillRect(162, 56, 1, 10, C::DIM);
        text(F_("Tên"), 12, 54, C::BLACK, C::BODY);
        text(F_("Cỡ"), 110, 54, C::BLACK, C::BODY);
        text(F_("Đã xoá"), 168, 54, C::BLACK, C::BODY);
    }
    Entry e;
    for (int i = 0; i < Trash::count() && i < kRowsShown; i++)
        if (Trash::at(i, e)) trashRow(i, e);
    char b[40];
    objectsText(Trash::count(), Trash::bytes(), true, b, sizeof(b));
    statusCells(b, F_("Thùng rác"));
}

// ── Confirm File Delete ──
static void confirmBox() {
    if (!Display::clipHits(18, 60, 204, 104)) return;
    tft.fillRect(18, 60, 204, 104, C::FRAME);
    static const uint16_t kBand[4] = {0x3CBF, 0x2C1E, 0x1B5D, 0x0ADB};   // #3D95FF #2B80F5 #1C6BE8 #0F5BDC
    for (int i = 0; i < 4; i++) tft.fillRect(18, 60 + 5 * i, 204, 5, kBand[i]);
    tft.fillRect(20, 80, 200, 82, C::BODY);
    char t[40];
    strncpy_P(t, PSTR("Xác nhận xoá tệp"), sizeof(t)); t[sizeof(t) - 1] = 0;
    Display::useFont("JBMono-12B");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(C::WHITE, kBand[1]);   // anti-aliased against the middle band (no pixel read-back)
    tft.drawString(t, 24, 63);
    tft.fillRect(204, 63, 14, 14, C::CLOSE);
    for (int i = 0; i < 8; i++) {
        tft.drawPixel(207 + i, 66 + i, C::WHITE);
        tft.drawPixel(214 - i, 66 + i, C::WHITE);
    }
    ICON(XpIcons, TrashFull, 28, 92);
    char a[40];
    if (s_view.confirm == CONFIRM_EMPTY) {
        snprintf_P(a, sizeof(a), PSTR("Xoá hẳn %d mục?"), Trash::count());
        text(a, 68, 97, C::BLACK, C::BODY);
    } else {
        char file[16], shown[20];
        Photos::name(s_view.sel, file, sizeof(file));
        shownName(file, shown, sizeof(shown));
        snprintf_P(a, sizeof(a), PSTR("Chuyển '%s'"), shown);
        text(a, 68, 90, C::BLACK, C::BODY);
        text(F_("vào Thùng rác?"), 68, 104, C::BLACK, C::BODY);
    }
    XP::pushButton(kYesBtn.x, kYesBtn.y, kYesBtn.w, kYesBtn.h, F_("Có"), XP::BTN_HOT);   // the default button
    XP::pushButton(kNoBtn.x, kNoBtn.y, kNoBtn.w, kNoBtn.h, F_("Không"), s_hot == 2 ? XP::BTN_HOT : XP::BTN_UP);
}

// ── channel ──

bool chExplorerEnabled(const ChannelCtx&) { return true; }

void chExplorerDraw(const ChannelCtx&) {
    if (!Display::repainting()) {
        s_view = mainExplorerView();
        if (s_view.place >= PLACE_COUNT) s_view.place = PLACE_COMPUTER;
    }
    XPCore::explorerIcon() = placeIcon(s_view.place);
    const XPCore::WinFrame f = XPCore::frameOf("Explorer");
    XP::window(f.title, f.icon, false);
    if (Display::clipHits(2, 22, 236, 174)) tft.fillRect(2, 22, 236, 174, C::WHITE);
    switch (s_view.place) {
        case PLACE_PHOTOS: placePhotos(); break;
        case PLACE_TRASH:  placeTrash(); break;
        default:           placeComputer(); break;
    }
    if (s_view.confirm != CONFIRM_NONE) confirmBox();
}

// A new view from the app, on screen: only the selection moved in the same place without a box → those
// items repaint; anything else → the caller repaints the window (false).
bool chExplorerSet(const View& v) {
    if (v.place != s_view.place || v.top != s_view.top || v.confirm != s_view.confirm
        || v.place == PLACE_COMPUTER) return false;
    const int8_t was = s_view.sel;
    s_view = v;
    if (was == v.sel) return true;
    if (v.place == PLACE_PHOTOS) {
        if (was >= 0) thumb(was);
        if (v.sel >= 0) thumb(v.sel);
    } else {
        Entry e;
        if (was >= 0 && was < kRowsShown && Trash::at(was, e)) trashRow(was, e);
        if (v.sel >= 0 && v.sel < kRowsShown && Trash::at(v.sel, e)) trashRow(v.sel, e);
    }
    return true;
}

// The mouse over Dọn sạch / Khôi phục (Thùng rác) or Không (the box): XP's hot ring.
bool chExplorerPointer(int x, int y) {
    int8_t hot = -1;
    if (x >= 0) {
        if (s_view.confirm != CONFIRM_NONE) { if (in(kNoBtn, x, y)) hot = 2; }
        else if (s_view.place == PLACE_TRASH && Trash::count()) {
            if (in(kEmptyBtn, x, y)) hot = 0;
            else if (in(kRestoreBtn, x, y)) hot = 1;
        }
    }
    if (hot == s_hot) return false;
    s_hot = hot;
    if (s_view.confirm != CONFIRM_NONE) {
        XP::pushButton(kNoBtn.x, kNoBtn.y, kNoBtn.w, kNoBtn.h, F_("Không"), s_hot == 2 ? XP::BTN_HOT : XP::BTN_UP);
    } else if (s_view.place == PLACE_TRASH) {
        trashButtons();
    }
    return true;
}
