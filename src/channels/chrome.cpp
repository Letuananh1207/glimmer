#include "chrome.h"
#include "display.h"
#include "config.h"
#include "layout.h"
#include <ESP8266WiFi.h>

namespace Chrome {

static const char* host(bool isClaude) { return isClaude ? "claude.ai" : "chatgpt.com"; }

//   y≈36   32×32 glyph (key = credential, circle-slash = blocked/offline)
//   y≈84   headline, JBMono-16B
//   y≈110  1–2 reason lines, JBMono-11 muted
//   y≈150  what to do: glimmer.local in SKY (+ IP muted) — or retry note
void credCard(bool isClaude, Cred cred, time_t jwtExp, const char* err) {
    using namespace Layout;
    tft.fillRect(0, CONTENT_TOP, SCREEN_W, CONTENT_BOTTOM - CONTENT_TOP, Theme::BG);

    const bool credIssue = CredState::bad(cred);
    const uint16_t accent = credIssue ? credColor(cred) : Theme::AMBER;
    if (cred == Cred::BLOCKED || !credIssue) Display::drawBlockedGlyph(SCREEN_W / 2, 54, accent);
    else                                     Display::drawKeyGlyph(SCREEN_W / 2 - 16, 34, accent, 2);

    Display::useFont("JBMono-16B");
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(accent, Theme::BG);
    tft.drawString(credIssue ? CredState::headline(cred, isClaude) : (err && *err ? err : "MẤT MẠNG"),
                   SCREEN_W / 2, 92);

    char l1[64] = "", l2[64] = "";
    bool showUrl = false;
    switch (cred) {
        case Cred::REJECTED:
            snprintf_P(l1, sizeof(l1), PSTR("%s từ chối %s"), host(isClaude), isClaude ? "khóa" : "token");
            snprintf_P(l2, sizeof(l2), PSTR("nhập %s mới tại"), isClaude ? "khóa" : "token");
            showUrl = true;
            break;
        case Cred::EXPIRED: {
            char d[12] = "";
            if (jwtExp) { struct tm tm; localtime_r(&jwtExp, &tm); strftime(d, sizeof(d), "%d/%m", &tm); }
            snprintf(l1, sizeof(l1), d[0] ? "hết hạn ngày %s" : "đã hết hạn", d);
            snprintf_P(l2, sizeof(l2), PSTR("nhập %s mới tại"), isClaude ? "khóa" : "token");
            showUrl = true;
            break;
        }
        case Cred::BLOCKED:
            snprintf_P(l1, sizeof(l1), PSTR("%s đang chặn"), host(isClaude));
            snprintf_P(l2, sizeof(l2), PSTR("thiết bị này - khóa vẫn tốt"));
            break;
        default:
            snprintf_P(l1, sizeof(l1), PSTR("không tới được %s"), host(isClaude));
            snprintf_P(l2, sizeof(l2), PSTR("kiểm tra Wi-Fi"));
            break;
    }
    Display::useFont("JBMono-11");
    tft.setTextColor(Theme::MUTED, Theme::BG);
    tft.drawString(l1, SCREEN_W / 2, 116);
    tft.drawString(l2, SCREEN_W / 2, 132);

    Display::dotsDivider(30, 148, SCREEN_W - 60);
    if (showUrl) {
        Display::useFont("JBMono-12B");
        tft.setTextColor(Theme::SKY, Theme::BG);
        char url[32]; snprintf_P(url, sizeof(url), PSTR("%s.local"), MDNS_HOSTNAME);
        tft.drawString(url, SCREEN_W / 2, 166);
        Display::useFont("JBMono-11");
        tft.setTextColor(Theme::MUTED, Theme::BG);
        tft.drawString(WiFi.localIP().toString(), SCREEN_W / 2, 186);
    } else {
        Display::useFont("JBMono-11");
        tft.setTextColor(Theme::INK_DIM, Theme::BG);
        tft.drawString(cred == Cred::BLOCKED ? "thử lại mỗi 15m" : "đang tự động thử lại",
                       SCREEN_W / 2, 166);
    }
}

void credBanner(int y, bool isClaude, Cred cred) {
    char t[64];
    if (cred == Cred::BLOCKED) snprintf_P(t, sizeof(t), PSTR("BỊ CHẶN \xC2\xB7 KHÓA OK \xC2\xB7 THỬ LẠI"));
    else snprintf_P(t, sizeof(t), PSTR("%s %s \xC2\xB7 %s.local"), isClaude ? "KHÓA" : "TOKEN",
                  cred == Cred::EXPIRED ? "HẾT HẠN" : "LỖI", MDNS_HOSTNAME);   // 224 px: "BỊ TỪ CHỐI" won't fit
    tft.fillRect(8, y, SCREEN_W - 16, 14, credColor(cred));
    Display::useFont("JBMono-11");
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(Theme::BG, credColor(cred));
    tft.drawString(t, SCREEN_W / 2, y + 7);
}

void credLine(bool isClaude, Cred cred, char* buf, size_t n) {
    if (n) buf[0] = '\0';
    switch (cred) {
        case Cred::NOT_SET:  snprintf_P(buf, n, PSTR("thêm %s \xC2\xB7 %s.local"), isClaude ? "khóa" : "token", MDNS_HOSTNAME); break;
        case Cred::EXPIRED:  snprintf_P(buf, n, PSTR("%s hết hạn \xC2\xB7 cập nhật"), isClaude ? "khóa" : "token"); break;
        case Cred::REJECTED: snprintf_P(buf, n, PSTR("%s bị từ chối \xC2\xB7 cập nhật"), isClaude ? "khóa" : "token"); break;
        case Cred::BLOCKED:  snprintf_P(buf, n, PSTR("bị chặn \xC2\xB7 thử lại")); break;
        default: break;
    }
}


// "CÒN 2 · ĐẾN 12/10" (or "· 3D" inside a week); "" when no credits.
void resetsText(const ResetGrant& g, char* buf, size_t n) {
    if (n) buf[0] = '\0';
    if (!g.left) return;
    time_t now = time(nullptr);
    if (g.endsAt && now > 1000000000L && g.endsAt > now) {
        if (g.endsAt - now < 7L * 86400L) {
            char d[8]; TimeUtil::shortDuration((long)(g.endsAt - now), d, sizeof(d));
            snprintf_P(buf, n, PSTR("CÒN %u \xC2\xB7 %s"), g.left, d);
        } else {
            char d[12]; struct tm tm; localtime_r(&g.endsAt, &tm);
            strftime(d, sizeof(d), "%d/%m", &tm);
            snprintf_P(buf, n, PSTR("CÒN %u \xC2\xB7 ĐẾN %s"), g.left, d);
        }
    } else {
        snprintf_P(buf, n, PSTR("CÒN %u"), g.left);
    }
}

}  // namespace Chrome
