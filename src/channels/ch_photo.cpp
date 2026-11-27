// Photo — the user's photos, one per slide (skill `photo`). XP window "Ảnh"
// (P-2026-11-26.8, screen_specs §17 XP-Photo / XP-Photo-Empty, sources
// XP-Photo*.dc.html).
//
//   title       "Ảnh · 2/5" (photo icon)
//   26,24       photo i, 188×188 baseline JPEG decoded block by block
//               (photos.cpp) straight onto the beige body — y 24..211
//
// Every draw() — i.e. every slide — moves to the next photo: the user's, then
// the sample photos (s<N>.jpg, tools/samplephotos.py); an unreadable one is
// skipped. None readable / none at all → the empty window (photo icon
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
    // Clipped repaint under the moving cursor: the photo on screen, no step.
    if (Display::repainting()) {
        const int i = Photos::current();
        if (s_empty || i < 0 || !Photos::draw(i, kPhotoX, kPhotoY)) { drawEmpty(); return; }
        char meta[12];
        snprintf_P(meta, sizeof(meta), PSTR("%d/%d"), i + 1, n);
        XP::titleMeta(meta);
        return;
    }
    for (int tries = 0; tries < n; tries++) {
        int i = Photos::advance();
        if (Photos::draw(i, kPhotoX, kPhotoY)) {
            s_empty = false;
            char meta[12];
            snprintf_P(meta, sizeof(meta), PSTR("%d/%d"), i + 1, n);
            XP::titleMeta(meta);
            return;
        }
        tft.fillRect(kPhotoX, kPhotoY, Photos::kSide, Photos::kSide, Theme::XP::BODY);   // partial decode
    }
    drawEmpty();
}
