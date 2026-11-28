// Photo — the user's photos, one per slide (skill `photo`). XP window "Ảnh"
// (P-2026-11-26.8, screen_specs §17 XP-Photo / XP-Photo-Empty, sources
// XP-Photo*.dc.html).
//
//   title       "Ảnh · 2/5" (photo icon)
//   26,24       photo i, 188×188 baseline JPEG decoded block by block
//               (photos.cpp) straight onto the beige body — y 24..211
//
// A slide (main.cpp calls chPhotoRequestStep() before the slideshow's draw())
// moves to the next photo: from the app's library when the app is here
// (photos.h fetchNext — the device points at it, app plan 2026-11-27 kho ảnh
// trên app), else the cache — the user's photos in flash (the app keeps its 8
// newest), then the sample photos (s<N>.jpg, tools/samplephotos.py); an
// unreadable one is skipped. Any other draw() (menu closed, back from a card)
// shows the photo on screen again. None readable / none at all → the empty window (photo icon
// ×3 xpEmptyIcon, "Chưa có ảnh", "Thêm ảnh trong app glimmer").
//
// P-2026-11-28.27 (XP-Photo-Phone / -Asking / -Offline, as Windows Picture and Fax Viewer):
// asking the app for the next slide keeps the old photo up with the XP-Open wait cursor (mouse
// mode: the app's cursor turns into wait where it is); the new photo is drawn over it. Showing
// the cache because the phone is away → title "Ảnh · 3/8 · đã lưu". tick() repaints only the
// title when the source goes online ↔ offline.

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "layout.h"
#include "photos.h"
#include "xp.h"

#include "cursor.h"

static bool s_empty = false;
static bool s_step = true;      // the next draw() moves to the next photo
static bool s_slide = false;    // ...and it is the slideshow's: the window is on screen as it was
static bool s_shown = false;    // a photo is on the panel (last draw)
static int8_t s_metaState = -1; // PhotoSource::State the title was written for (tick)

void chPhotoRequestStep() { s_step = true; s_slide = true; }

// Explorer › open (P-2026-11-28.32): the Photo window shows photo [i] of the device next, no step.
void chPhotoShowIndex(int i) {
    Photos::setCurrent(i);
    PhotoSource::showingCache(Photos::source());
    s_step = false;
    s_empty = false;
}

// Title meta "3/40": place in the app's library, or in the cache.
static void metaRemote() {
    const PhotoSource::Source& s = Photos::source();
    char meta[16];
    if (s.count) snprintf_P(meta, sizeof(meta), PSTR("%u/%u"), s.index, s.count);
    else meta[0] = 0;
    XP::titleMeta(meta);
    s_metaState = (int8_t)PhotoSource::stateOf(s);
}
static void metaCache(int i) {
    const PhotoSource::State st = PhotoSource::stateOf(Photos::source());
    char meta[32];
    if (st == PhotoSource::OFFLINE)
        snprintf_P(meta, sizeof(meta), PSTR("%d/%d \xC2\xB7 đã lưu"), i + 1, Photos::total());
    else
        snprintf_P(meta, sizeof(meta), PSTR("%d/%d"), i + 1, Photos::total());
    XP::titleMeta(meta);
    s_metaState = (int8_t)st;
}
static constexpr int kPhotoX = 26, kPhotoY = 24;   // 188×188 → x 26..213, y 24..211

bool chPhotoEnabled(const ChannelCtx&) { return true; }   // the skill toggle decides
bool chPhotoEmpty() { return s_empty; }

// XP-Photo-Empty: icon 16×11 ×3 at (96, 52); text centred on x 120.
static void drawEmpty() {
    using namespace Theme::XP;
    s_empty = true;
    s_shown = false;
    XP::titleMeta("");
    XP::drawIcon(XPCore::ICON_PHOTO, 96, 52, 3, EMPTY_ICON);
    tft.setTextDatum(TC_DATUM);
    Display::useFont("JBMono-16B");
    tft.setTextColor(MUTED, BODY);
    tft.drawString("Chưa có ảnh", Layout::XP_MID, 100);
    Display::useFont("JBMono-11");
    tft.setTextColor(BLACK, BODY);
    tft.drawString("Thêm ảnh trong app glimmer", Layout::XP_MID, 128);
}

void chPhotoDraw(const ChannelCtx&) {
    const int n = Photos::total();
    PhotoSource::Source& src = Photos::source();
    // Clipped repaint under the moving cursor / the same slide again: the photo on screen, no step.
    const bool step = s_step && !Display::repainting();
    // XP-Photo-Asking: the slideshow asks the app with the old photo still up (no frame repaint).
    const bool asking = step && s_slide && s_shown && PhotoSource::wantRemote(src, millis());
    if (!Display::repainting()) s_slide = false;
    if (!asking) XP::window("Ảnh", XPCore::ICON_PHOTO, false);
    if (!step) {
        if (src.remote && Photos::drawCurrent(kPhotoX, kPhotoY)) {
            s_empty = false; s_shown = true; metaRemote(); return;
        }
        const int i = Photos::current();
        if (!src.remote && !s_empty && i >= 0 && Photos::draw(i, kPhotoX, kPhotoY)) {
            s_shown = true; metaCache(i); return;
        }
        if (Display::repainting()) { drawEmpty(); return; }
    }
    s_step = false;
    // The app's library first (it is the memory); away / empty → the cache.
    if (PhotoSource::wantRemote(src, millis())) {
        if (asking && !Cursor::showBusyNow(millis())) XP::waitCursor(0, true);
        const Photos::Fetch r = Photos::fetchNext(millis());
        if (r == Photos::FETCH_OK) {
            if (Photos::drawCurrent(kPhotoX, kPhotoY)) { s_empty = false; s_shown = true; metaRemote(); return; }
            tft.fillRect(kPhotoX, kPhotoY, Photos::kSide, Photos::kSide, Theme::XP::BODY);   // partial decode
        }
    }
    PhotoSource::showingCache(src);
    for (int tries = 0; tries < n; tries++) {
        int i = Photos::advance();
        if (Photos::draw(i, kPhotoX, kPhotoY)) {
            s_empty = false;
            s_shown = true;
            metaCache(i);
            return;
        }
        tft.fillRect(kPhotoX, kPhotoY, Photos::kSide, Photos::kSide, Theme::XP::BODY);   // partial decode
    }
    if (asking) XP::window("Ảnh", XPCore::ICON_PHOTO, false);   // the old photo goes: nothing to show
    drawEmpty();
}

// Online <-> offline (the app answered / went away): only the title (x 22..181, y 2..19).
void chPhotoTick(const ChannelCtx&) {
    if (s_empty || !s_shown || s_metaState < 0) return;
    const PhotoSource::Source& src = Photos::source();
    const int8_t st = (int8_t)PhotoSource::stateOf(src);
    if (st == s_metaState) return;
    if (src.remote) metaRemote();
    else if (Photos::current() >= 0) metaCache(Photos::current());
}
