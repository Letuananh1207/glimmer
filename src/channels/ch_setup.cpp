// Setup — first-run checklist, in rotation only while neither usage
// credential is set AND the user still wants a usage channel (turning both
// Claude and Codex off means "I don't use these", so it never nags).
//
// XP window "Cài đặt" (P-2026-11-26.8, screen_specs §17 XP-Setup,
// source/XP-Setup.dc.html):
//
//   y 30      "Hoàn tất cài đặt"            JBMono-12B black TL (12, 30)
//   y 48      "Còn 2 bước nữa là xong."     JBMono-11 xpLabel TL (12, 48)
//   y 72..    checklist every 22 px: XP checkbox 13×13 at (14, y) (xpCheckBox
//             border, white, green tick when done) + item TL (34, y) — black,
//             xpMuted once done
//   y 150     groupbox "Mở trong trình duyệt" (10, 150, 220×40):
//             glimmer.local JBMono-12B xpLink TL (18, 159) underlined at y 173,
//             IP JBMono-11 xpMuted TR (222, 176)
// Static: tick() paints nothing.

#include "channel.h"
#include "display.h"
#include "theme.h"
#include "config.h"
#include "host.h"
#include "weather.h"
#include "layout.h"
#include "xp.h"
#include <ESP8266WiFi.h>

using namespace Theme::XP;

bool chSetupEnabled(const ChannelCtx& ctx) {
    const Settings* s = ctx.settings;
    return s && s->claudeKey.isEmpty() && s->codexToken.isEmpty()
        && (s->showClaude || s->showCodex);
}

// XP checkbox: 13×13, 1-px xpCheckBox border, white inside; the tick is
// 7 columns of 1×3 px (offsets from the box: (4,6) (5,7) (6,8) (7,7) (8,6)
// (9,5) (10,4)) in xpCheck.
static void checkRow(int y, bool done, const char* item) {
    const int bx = 14;
    tft.drawRect(bx, y, 13, 13, CHECK_BOX);
    tft.fillRect(bx + 1, y + 1, 11, 11, WHITE);
    if (done) {
        static const int8_t kTickY[7] = {6, 7, 8, 7, 6, 5, 4};
        for (int i = 0; i < 7; i++) tft.fillRect(bx + 4 + i, y + kTickY[i], 1, 3, CHECK);
    }
    Display::useFont("JBMono-11");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(done ? MUTED : BLACK, BODY);
    tft.drawString(item, 34, y);
}

void chSetupDraw(const ChannelCtx& ctx) {
    XP::window("Cài đặt", XPCore::ICON_CLAWD, false);
    const Settings& s = *ctx.settings;
    const bool done[3] = {!s.claudeKey.isEmpty(), !s.codexToken.isEmpty(), Weather::configured(s)};
    const int left = !done[0] + !done[1] + !done[2];

    Display::useFont("JBMono-12B");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(BLACK, BODY);
    tft.drawString("Hoàn tất cài đặt", 12, 30);

    char sub[48];
    snprintf_P(sub, sizeof(sub), PSTR("Còn %d bước nữa là xong."), left);
    Display::useFont("JBMono-11");
    tft.setTextColor(LABEL, BODY);
    tft.drawString(sub, 12, 48);

    checkRow(72,  done[0], "Khóa Claude");
    checkRow(94,  done[1], "Token Codex");
    checkRow(116, done[2], "Thời tiết, vị trí, giờ");

    XP::groupBox(10, 150, 220, 40, "Mở trong trình duyệt");
    char url[32]; snprintf_P(url, sizeof(url), PSTR("%s.local"), deviceHost());
    Display::useFont("JBMono-12B");
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(LINK, BODY);
    tft.drawString(url, 18, 159);
    tft.drawFastHLine(18, 173, tft.textWidth(url), LINK);
    Display::useFont("JBMono-11");
    tft.setTextDatum(TR_DATUM);
    tft.setTextColor(MUTED, BODY);
    tft.drawString(WiFi.localIP().toString(), 222, 176);
}
