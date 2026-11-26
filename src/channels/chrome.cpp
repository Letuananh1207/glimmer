#include "chrome.h"
#include "display.h"
#include "config.h"
#include "layout.h"
#include "xp.h"
#include "timeutil.h"
#include <ESP8266WiFi.h>

void xpStaleText(time_t lastOk, const Settings& s, char* buf, size_t n) {
    if (n) buf[0] = '\0';
    if (!Api::isStale(lastOk, s)) return;
    char d[8]; TimeUtil::shortDuration((long)(time(nullptr) - lastOk), d, sizeof(d));
    snprintf_P(buf, n, PSTR("cũ %s"), d);
}

MetaSlot xpUsageMeta(const Settings& s, time_t lastOk, VendorStatus::Vendor v,
                     const char* normal, Cred cred, time_t jwtExp) {
    MetaSlot m;
    m.color = Theme::XP::BLACK;
    const time_t now = time(nullptr);
    if (CredState::bad(cred)) {
        snprintf_P(m.text, sizeof(m.text), cred == Cred::BLOCKED ? PSTR("bị chặn") : PSTR("khóa lỗi"));
        m.color = xpCredColor(cred);
        return m;
    }
    xpStaleText(lastOk, s, m.text, sizeof(m.text));
    if (m.text[0]) { m.color = Theme::XP::DIM; return m; }
    if (cred == Cred::EXPIRING && jwtExp > now) {
        char d[8]; TimeUtil::shortDuration((long)(jwtExp - now), d, sizeof(d));
        snprintf_P(m.text, sizeof(m.text), PSTR("hạn %s"), d);
        m.color = Theme::XP::AMBER;
        return m;
    }
    const char* b = s.showStatus ? VendorStatus::badge(v) : "";
    if (*b) {
        Utf8::copy(m.text, sizeof(m.text), b);
        Utf8::mapCase(m.text, false);                   // "SỰ CỐ" → "sự cố"
        m.color = Theme::XP::AMBER;
        return m;
    }
    Utf8::copy(m.text, sizeof(m.text), normal);
    return m;
}

namespace Chrome {

static const char* host(bool isClaude) { return isClaude ? "claude.ai" : "chatgpt.com"; }
static const char* credWord(bool isClaude) { return isClaude ? "khóa" : "token"; }

// XP message box (§17 "Hộp thoại"; XP-Claude-Rejected / -Offline,
// XP-Codex-Expired): icon (14,36), head 12B (48,38), lines 11 from (48,58)
// step 16, link glimmer.local + the IP below it. Lines are ≤ 25 glyphs
// (JBMono-11 is 7 px: x 48..229 = 181 px).
void credCard(bool isClaude, Cred cred, time_t jwtExp, const char* err) {
    char head[32] = "", l1[40] = "", l2[40] = "";
    const char* lines[4];
    int n = 0;
    XP::Dialog kind = XP::DLG_WARN;
    bool showUrl = false;
    const char* cw = credWord(isClaude);

    switch (cred) {
        case Cred::REJECTED:
            kind = XP::DLG_ERROR;
            snprintf_P(head, sizeof(head), PSTR("%s bị từ chối"), isClaude ? "Khóa" : "Token");
            snprintf_P(l1, sizeof(l1), PSTR("%s từ chối %s."), host(isClaude), cw);
            snprintf_P(l2, sizeof(l2), PSTR("Nhập %s mới tại:"), cw);
            lines[n++] = l1; lines[n++] = l2;
            showUrl = true;
            break;
        case Cred::EXPIRED: {
            kind = XP::DLG_ERROR;
            snprintf_P(head, sizeof(head), PSTR("%s hết hạn"), isClaude ? "Khóa" : "Token");
            char d[12] = "";
            if (jwtExp) { struct tm tm; localtime_r(&jwtExp, &tm); strftime(d, sizeof(d), "%d/%m", &tm); }
            if (d[0]) snprintf_P(l1, sizeof(l1), PSTR("Hết hạn ngày %s."), d);
            else      snprintf_P(l1, sizeof(l1), PSTR("Đã hết hạn."));
            snprintf_P(l2, sizeof(l2), PSTR("Nhập %s mới tại:"), cw);
            lines[n++] = l1; lines[n++] = l2;
            showUrl = true;
            break;
        }
        case Cred::BLOCKED:
            // "chatgpt.com chặn máy này." = 25 glyphs, the widest that fits.
            snprintf_P(head, sizeof(head), PSTR("Bị chặn"));
            snprintf_P(l1, sizeof(l1), PSTR("%s chặn máy này."), host(isClaude));
            snprintf_P(l2, sizeof(l2), PSTR("%s vẫn tốt."), isClaude ? "Khóa" : "Token");
            lines[n++] = l1; lines[n++] = l2; lines[n++] = "";
            lines[n++] = "Thử lại mỗi 15 phút.";
            break;
        case Cred::NOT_SET:
            kind = XP::DLG_INFO;
            snprintf_P(head, sizeof(head), PSTR("Chưa có %s"), cw);
            snprintf_P(l1, sizeof(l1), PSTR("Nhập %s tại:"), cw);
            lines[n++] = l1;
            showUrl = true;
            break;
        default:
            if (!err || !*err || strcmp(err, "Mất mạng") == 0) {
                // XP-Claude-Offline. "Không tới được chatgpt.com." is 27
                // glyphs: Codex says "Không tới chatgpt.com.".
                snprintf_P(head, sizeof(head), PSTR("Mất mạng"));
                snprintf_P(l1, sizeof(l1), isClaude ? PSTR("Không tới được %s.") : PSTR("Không tới %s."),
                           host(isClaude));
                lines[n++] = l1;
                lines[n++] = "Kiểm tra Wi-Fi.";
            } else {
                // Upstream answered but not with usable data ("HTTP 503", "JSON …").
                snprintf_P(head, sizeof(head), PSTR("Không đọc được"));
                snprintf_P(l1, sizeof(l1), PSTR("%s trả lỗi:"), host(isClaude));
                Utf8::copy(l2, sizeof(l2), err);
                lines[n++] = l1; lines[n++] = l2;
            }
            lines[n++] = "";
            lines[n++] = "Đang tự động thử lại...";
            break;
    }

    char url[32] = "", ip[20] = "";
    if (showUrl) {
        snprintf_P(url, sizeof(url), PSTR("%s.local"), MDNS_HOSTNAME);
        Utf8::copy(ip, sizeof(ip), WiFi.localIP().toString().c_str());
    }
    XP::dialog(kind, head, lines, n, showUrl ? url : nullptr, showUrl ? ip : nullptr);
}

// XP-Claude-KeyExpired: INFO_BAR strip, amber "!", red text. Too wide →
// the short form ("Bị từ chối · glimmer.local", "Bị chặn · khóa vẫn tốt").
// Blocked is not the key's fault: black text (theo XP thật: the information
// bar's text is black).
void credBanner(int x, int y, int w, bool isClaude, Cred cred) {
    char t[64];
    const char* cw = isClaude ? "Khóa" : "Token";
    Display::useFont("JBMono-11");
    if (cred == Cred::BLOCKED)
        snprintf_P(t, sizeof(t), PSTR("Bị chặn \xC2\xB7 %s vẫn tốt \xC2\xB7 thử lại"), isClaude ? "khóa" : "token");
    else
        snprintf_P(t, sizeof(t), PSTR("%s %s \xC2\xB7 %s.local"), cw,
                   cred == Cred::EXPIRED ? "hết hạn" : "bị từ chối", MDNS_HOSTNAME);
    if (tft.textWidth(t) > w - 17) {
        if (cred == Cred::BLOCKED)
            snprintf_P(t, sizeof(t), PSTR("Bị chặn \xC2\xB7 %s vẫn tốt"), isClaude ? "khóa" : "token");
        else
            snprintf_P(t, sizeof(t), PSTR("%s \xC2\xB7 %s.local"),
                       cred == Cred::EXPIRED ? "Hết hạn" : "Bị từ chối", MDNS_HOSTNAME);
    }
    XP::infoStrip(x, y, w, t, cred == Cred::BLOCKED ? Theme::XP::BLACK : Theme::XP::RED);
}

void credLine(bool isClaude, Cred cred, char* buf, size_t n) {
    if (n) buf[0] = '\0';
    switch (cred) {
        case Cred::NOT_SET:  snprintf_P(buf, n, PSTR("thêm %s \xC2\xB7 %s.local"), credWord(isClaude), MDNS_HOSTNAME); break;
        case Cred::EXPIRED:  snprintf_P(buf, n, PSTR("%s hết hạn \xC2\xB7 cập nhật"), credWord(isClaude)); break;
        case Cred::REJECTED: snprintf_P(buf, n, PSTR("%s bị từ chối \xC2\xB7 cập nhật"), credWord(isClaude)); break;
        case Cred::BLOCKED:  snprintf_P(buf, n, PSTR("bị chặn \xC2\xB7 thử lại")); break;
        default: break;
    }
}

void credStatus(bool isClaude, Cred cred, char* buf, size_t n) {
    if (n) buf[0] = '\0';
    const char* who = isClaude ? "Khóa Claude" : "Token Codex";
    switch (cred) {
        case Cred::NOT_SET:  snprintf_P(buf, n, PSTR("Chưa có %s"), isClaude ? "khóa Claude" : "token Codex"); break;
        case Cred::EXPIRED:  snprintf_P(buf, n, PSTR("%s hết hạn"), who); break;
        case Cred::REJECTED: snprintf_P(buf, n, PSTR("%s bị từ chối"), who); break;
        case Cred::BLOCKED:  snprintf_P(buf, n, PSTR("%s chặn máy này"), host(isClaude)); break;
        default: break;
    }
}

// "còn 2 · 3NG" (or "· đến 12/10" beyond a week); "" when no credits.
void resetsText(const ResetGrant& g, char* buf, size_t n) {
    if (n) buf[0] = '\0';
    if (!g.left) return;
    time_t now = time(nullptr);
    if (g.endsAt && now > 1000000000L && g.endsAt > now) {
        if (g.endsAt - now < 7L * 86400L) {
            char d[8]; TimeUtil::shortDuration((long)(g.endsAt - now), d, sizeof(d));
            snprintf_P(buf, n, PSTR("còn %u \xC2\xB7 %s"), g.left, d);
        } else {
            char d[12]; struct tm tm; localtime_r(&g.endsAt, &tm);
            strftime(d, sizeof(d), "%d/%m", &tm);
            snprintf_P(buf, n, PSTR("còn %u \xC2\xB7 đến %s"), g.left, d);
        }
    } else {
        snprintf_P(buf, n, PSTR("còn %u"), g.left);
    }
}

}  // namespace Chrome
