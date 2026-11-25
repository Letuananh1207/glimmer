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
// Dock layout (P-2026-11-25.3): everything centres on x 134 inside x 40..228
// (widest line "thiết bị này - khóa vẫn tốt" 189 px → x 40..228); the clear
// starts at x 36 so the dock (x 2..31) is never touched.
void credCard(bool isClaude, Cred cred, time_t jwtExp, const char* err) {
    using namespace Layout;
    constexpr int cx = CONTENT_MID;
    tft.fillRect(36, CONTENT_TOP, SCREEN_W - 36, CONTENT_BOTTOM - CONTENT_TOP, Theme::BG);

    const bool credIssue = CredState::bad(cred);
    const uint16_t accent = credIssue ? credColor(cred) : Theme::AMBER;
    if (cred == Cred::BLOCKED || !credIssue) Display::drawBlockedGlyph(cx, 54, accent);
    else                                     Display::drawKeyGlyph(cx - 16, 34, accent, 2);

    Display::useFont("JBMono-16B");
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(accent, Theme::BG);
    tft.drawString(credIssue ? CredState::headline(cred, isClaude) : (err && *err ? err : "MẤT MẠNG"),
                   cx, 92);

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
    tft.drawString(l1, cx, 116);
    tft.drawString(l2, cx, 132);

    Display::dotsDivider(52, 148, 164);
    if (showUrl) {
        Display::useFont("JBMono-12B");
        tft.setTextColor(Theme::SKY, Theme::BG);
        char url[32]; snprintf_P(url, sizeof(url), PSTR("%s.local"), MDNS_HOSTNAME);
        tft.drawString(url, cx, 166);
        Display::useFont("JBMono-11");
        tft.setTextColor(Theme::MUTED, Theme::BG);
        tft.drawString(WiFi.localIP().toString(), cx, 186);
    } else {
        Display::useFont("JBMono-11");
        tft.setTextColor(Theme::INK_DIM, Theme::BG);
        tft.drawString(cred == Cred::BLOCKED ? "thử lại mỗi 15m" : "đang tự động thử lại",
                       cx, 166);
    }
}

void credBanner(int y, bool isClaude, Cred cred) {
    char t[64];
    // The band spans the dock layout's content (x 40..227, 188 px); the text
    // gets 184. Too wide → the short form: "BỊ CHẶN · KHÓA OK · THỬ LẠI"
    // (189) → "BỊ CHẶN · KHÓA OK", "KHÓA HẾT HẠN · glimmer.local" (196) →
    // "HẾT HẠN · glimmer.local". "BỊ TỪ CHỐI" never fits: it reads "LỖI".
    Display::useFont("JBMono-11");
    if (cred == Cred::BLOCKED) snprintf_P(t, sizeof(t), PSTR("BỊ CHẶN \xC2\xB7 KHÓA OK \xC2\xB7 THỬ LẠI"));
    else snprintf_P(t, sizeof(t), PSTR("%s %s \xC2\xB7 %s.local"), isClaude ? "KHÓA" : "TOKEN",
                  cred == Cred::EXPIRED ? "HẾT HẠN" : "LỖI", MDNS_HOSTNAME);
    if (tft.textWidth(t) > Layout::CONTENT_W - 4) {
        if (cred == Cred::BLOCKED) snprintf_P(t, sizeof(t), PSTR("BỊ CHẶN \xC2\xB7 KHÓA OK"));
        else snprintf_P(t, sizeof(t), PSTR("%s \xC2\xB7 %s.local"),
                        cred == Cred::EXPIRED ? "HẾT HẠN" : "LỖI", MDNS_HOSTNAME);
    }
    tft.fillRect(Layout::CONTENT_LEFT, y, Layout::CONTENT_W, 14, credColor(cred));
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(Theme::BG, credColor(cred));
    tft.drawString(t, Layout::CONTENT_MID, y + 7);
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
