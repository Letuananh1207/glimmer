#pragma once
// Shared chrome for the usage channels (Claude, Codex) and the compact
// surfaces that summarise them (Home, AI, Trend): title meta, credential
// dialogs, credential info strips, usage colours. One place so every screen
// says the same thing.
//
// XP look (P-2026-11-26.8/.9, screen_specs §17): meta goes into the window
// title ("Claude · cũ 14P", "Codex · khóa lỗi"); a credential problem with no
// data is an XP message box (XP::dialog); one over existing data is the
// yellow info strip (XP::infoStrip).
//
// Title-meta priority: credential problem (khóa lỗi / bị chặn) > cũ 14P >
// hạn 2NG > vendor status badge > the channel's normal meta.
#include <string.h>
#include "api.h"
#include "theme.h"
#include "vendor_status.h"
#include "utf8.h"

struct MetaSlot {
    char     text[24] = "";   // UTF-8 (Vietnamese)
    uint16_t color    = Theme::MUTED;
    bool operator!=(const MetaSlot& o) const { return color != o.color || strcmp(text, o.text); }
};

// Pre-XP colours (dark theme) — still used by main.cpp's sys:* notices.
inline uint16_t credColor(Cred c) {
    return c == Cred::BLOCKED || c == Cred::EXPIRING ? Theme::AMBER : Theme::CORAL;
}
// XP colour for a credential problem: amber for blocked / expiring, red otherwise.
inline uint16_t xpCredColor(Cred c) {
    return c == Cred::BLOCKED || c == Cred::EXPIRING ? Theme::XP::AMBER : Theme::XP::RED;
}

// XP usage colour from % REMAINING: ≤ 20 red, ≤ 50 amber, else the channel's
// healthy colour (Claude xpGreen, Codex xpLilac; XP-AI, XP-Codex); unknown → dim.
inline uint16_t xpUsageColor(float remaining, uint16_t healthy) {
    if (remaining < 0)      return Theme::XP::DIM;
    if (remaining <= 20.0f) return Theme::XP::RED;
    if (remaining <= 50.0f) return Theme::XP::AMBER;
    return healthy;
}

// Pre-XP status-bar meta (uppercase badges). Kept for surfaces not yet on XP.
inline MetaSlot usageMeta(const Settings& s, time_t lastOk, VendorStatus::Vendor v,
                          const char* normal, Cred cred, time_t jwtExp) {
    MetaSlot m;
    time_t now = time(nullptr);
    if (CredState::bad(cred)) {
        CredState::meta(cred, jwtExp, now, m.text, sizeof(m.text));
        m.color = credColor(cred);
        return m;
    }
    Api::staleText(lastOk, s, m.text, sizeof(m.text));
    if (m.text[0]) { m.color = Theme::AMBER; return m; }
    if (cred == Cred::EXPIRING) {
        CredState::meta(cred, jwtExp, now, m.text, sizeof(m.text));
        m.color = Theme::AMBER;
        return m;
    }
    const char* b = s.showStatus ? VendorStatus::badge(v) : "";
    if (*b) {
        Utf8::copy(m.text, sizeof(m.text), b);
        m.color = VendorStatus::badgeColor(v);
        return m;
    }
    Utf8::copy(m.text, sizeof(m.text), normal);
    return m;
}

// XP title meta (lower case, §17 "Dữ liệu cũ"): "khóa lỗi", "bị chặn",
// "cũ 14P", "hạn 2NG", "bảo trì" / "chập chờn" / "sự cố", else `normal`.
// Show it with XP::titleMeta(m.text). Colour is informational only.
MetaSlot xpUsageMeta(const Settings& s, time_t lastOk, VendorStatus::Vendor v,
                     const char* normal, Cred cred, time_t jwtExp);

// "cũ 14P" when lastOk is stale, "" otherwise.
void xpStaleText(time_t lastOk, const Settings& s, char* buf, size_t n);

// Values on screen are not live: old data, or a credential that no longer works.
inline bool dimData(const Settings& s, time_t lastOk, Cred cred) {
    return CredState::bad(cred) || Api::isStale(lastOk, s);
}

namespace Chrome {
    // XP message box on the window body for a usage channel with no data to
    // show (XP-Claude-Rejected / -Offline, XP-Codex-Expired): error icon for
    // a rejected/expired credential, warning for blocked / offline / an
    // upstream error (err), info when no credential is set. Call right after
    // XP::window() (it does not clear the body).
    void credCard(bool isClaude, Cred cred, time_t jwtExp, const char* err);

    // Yellow info strip over existing data (XP-Claude-KeyExpired):
    // "Khóa hết hạn · glimmer.local" at (x, y, w×14). Tick-safe.
    void credBanner(int x, int y, int w, bool isClaude, Cred cred);

    // Compact one-liner for Home/AI/Trend rows: "khóa hết hạn · cập nhật",
    // "bị chặn · thử lại", "thêm khóa · glimmer.local". "" when nothing to say.
    void credLine(bool isClaude, Cred cred, char* buf, size_t n);

    // XP sentence for a status bar: "Khóa Claude bị từ chối", "Token Codex
    // hết hạn", "Claude chặn máy này". "" when the credential is fine.
    void credStatus(bool isClaude, Cred cred, char* buf, size_t n);

    // Limit-reset credits (XP-Codex group "Đặt lại tuần"): "còn 2 · 3NG"
    // inside a week, "còn 2 · đến 12/10" beyond, "còn 2" without an expiry;
    // "" when the account has none.
    void resetsText(const ResetGrant& g, char* buf, size_t n);
}
