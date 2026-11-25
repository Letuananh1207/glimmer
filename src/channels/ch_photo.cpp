// Photo — the user's photos, one per slide (skill `photo`, design
// P-2026-11-25.7, screen_specs §16, source/Photo.dc.html, Photo-Empty.dc.html).
//
//   y=0..22     StatusBar [Ảnh | i/n]  (MINT accent)
//   40,28       photo i, 188×188 baseline JPEG decoded block by block (photos.cpp)
//   dock        painted by main.cpp (tab Ảnh)
//
// Every draw() — i.e. every slide — moves to the next photo; an unreadable
// one is skipped. None readable / none at all → the empty screen (icon ×3,
// "Chưa có ảnh", how to send one) and main.cpp's strip goes solid MUTED.
// tick() paints nothing: the image is static.

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "layout.h"
#include "photos.h"
#include "dock.h"

static bool s_empty = false;

bool chPhotoEnabled(const ChannelCtx&) { return true; }   // the skill toggle decides
bool chPhotoEmpty() { return s_empty; }

static void drawEmpty() {
    using namespace Layout;
    s_empty = true;
    Display::statusBar("Ảnh", "", Theme::MINT);
    Dock::drawPhotoIcon(110, 56, 3, Theme::LINE);
    tft.setTextDatum(TC_DATUM);
    Display::useFont("JBMono-16B");
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString("Chưa có ảnh", CONTENT_MID, 104);
    Display::useFont("JBMono-11");
    tft.setTextColor(Theme::INK_DIM, Theme::BG);
    tft.drawString("Gửi ảnh từ app glimmer", CONTENT_MID, 132);
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString("hoặc glimmer.local", CONTENT_MID, 148);
}

void chPhotoDraw(const ChannelCtx&) {
    using namespace Layout;
    Display::clear();
    const int n = Photos::count();
    for (int tries = 0; tries < n; tries++) {
        int i = Photos::advance();
        if (Photos::draw(i, CONTENT_LEFT, 28)) {
            s_empty = false;
            char meta[12];
            snprintf_P(meta, sizeof(meta), PSTR("%d/%d"), i + 1, n);
            Display::statusBar("Ảnh", meta, Theme::MINT);
            return;
        }
        tft.fillRect(CONTENT_LEFT, 28, Photos::kSide, Photos::kSide, Theme::BG);   // partial decode
    }
    drawEmpty();
}
