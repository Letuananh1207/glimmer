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
// ×3 xpEmptyIcon, "Chưa có ảnh", how to send one). tick() paints nothing: the
// image is static.

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "layout.h"
#include "photos.h"
#include "xp.h"

static bool s_empty = false;
static bool s_step = true;     // the next draw() moves to the next photo

void chPhotoRequestStep() { s_step = true; }

// Title meta "3/40": place in the app's library, or in the cache.
static void metaRemote() {
    const PhotoSource::Source& s = Photos::source();
    char meta[16];
    if (s.count) snprintf_P(meta, sizeof(meta), PSTR("%u/%u"), s.index, s.count);
    else meta[0] = 0;
    XP::titleMeta(meta);
}
static void metaCache(int i) {
    char meta[12];
    snprintf_P(meta, sizeof(meta), PSTR("%d/%d"), i + 1, Photos::total());
    XP::titleMeta(meta);
}
static constexpr int kPhotoX = 26, kPhotoY = 24;   // 188×188 → x 26..213, y 24..211

bool chPhotoEnabled(const ChannelCtx&) { return true; }   // the skill toggle decides
bool chPhotoEmpty() { return s_empty; }

// XP-Photo-Empty: icon 16×11 ×3 at (96, 52); text centred on x 120.
static void drawEmpty() {
    using namespace Theme::XP;
    s_empty = true;
    XP::titleMeta("");
    XP::drawIcon(XPCore::ICON_PHOTO, 96, 52, 3, EMPTY_ICON);
    tft.setTextDatum(TC_DATUM);
    Display::useFont("JBMono-16B");
    tft.setTextColor(MUTED, BODY);
    tft.drawString("Chưa có ảnh", Layout::XP_MID, 100);
    Display::useFont("JBMono-11");
    tft.setTextColor(BLACK, BODY);
    tft.drawString("Gửi ảnh từ app glimmer", Layout::XP_MID, 128);
    tft.setTextColor(MUTED, BODY);
    tft.drawString("hoặc", Layout::XP_MID, 146);
    char url[32]; snprintf_P(url, sizeof(url), PSTR("%s.local"), MDNS_HOSTNAME);
    Display::useFont("JBMono-12B");
    tft.setTextColor(LINK, BODY);
    tft.drawString(url, Layout::XP_MID, 162);
}

void chPhotoDraw(const ChannelCtx&) {
    XP::window("Ảnh", XPCore::ICON_PHOTO, false);
    const int n = Photos::total();
    PhotoSource::Source& src = Photos::source();
    // Clipped repaint under the moving cursor / the same slide again: the photo on screen, no step.
    const bool step = s_step && !Display::repainting();
    if (!step) {
        if (src.remote && Photos::drawCurrent(kPhotoX, kPhotoY)) { s_empty = false; metaRemote(); return; }
        const int i = Photos::current();
        if (!src.remote && !s_empty && i >= 0 && Photos::draw(i, kPhotoX, kPhotoY)) { metaCache(i); return; }
        if (Display::repainting()) { drawEmpty(); return; }
    }
    s_step = false;
    // The app's library first (it is the memory); away / empty → the cache.
    if (PhotoSource::wantRemote(src, millis())) {
        const Photos::Fetch r = Photos::fetchNext(millis());
        if (r == Photos::FETCH_OK) {
            if (Photos::drawCurrent(kPhotoX, kPhotoY)) { s_empty = false; metaRemote(); return; }
            tft.fillRect(kPhotoX, kPhotoY, Photos::kSide, Photos::kSide, Theme::XP::BODY);   // partial decode
        }
    }
    PhotoSource::showingCache(src);
    for (int tries = 0; tries < n; tries++) {
        int i = Photos::advance();
        if (Photos::draw(i, kPhotoX, kPhotoY)) {
            s_empty = false;
            metaCache(i);
            return;
        }
        tft.fillRect(kPhotoX, kPhotoY, Photos::kSide, Photos::kSide, Theme::XP::BODY);   // partial decode
    }
    drawEmpty();
}
