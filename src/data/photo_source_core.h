#pragma once
// Photo source (app plan app/docs/tasks/2026-11-27-kho-anh-tren-app.md, R-AK-*) — pure logic, host-tested.
//
// The app is the memory, the device the screen: the photo library lives on the phone, which serves it on the
// home network (plain HTTP). The device keeps no list — only a pointer: the id of the photo on screen. Each slide it
// asks the app for "the photo after <id>"; the app keeps the order and answers with the JPEG + its id and place:
//
//   GET http://<host>:<port>/p/<key>/next?after=<id>      (after=0: the first)
//   200  body = baseline JPEG 188×188 ≤ 40 KB; headers X-Photo-Id, X-Photo-Index (1-based), X-Photo-Count
//   204  the library is empty
//
// The app tells the device where it is (POST /api/photos/source {host, port, key}, RAM only) when it opens / comes
// back. A failed fetch (app away: out of the house, closed, other Wi-Fi) → the device shows its cache (the user
// photos in flash the app keeps = the 8 newest) and asks again after kRetryMs.
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

namespace PhotoSource {

constexpr uint32_t kRetryMs       = 60UL * 1000;  // app away → cache; ask the app again after this
constexpr uint32_t kFetchTimeoutMs = 3000;        // connect / each read (the loop is blocked meanwhile)
constexpr size_t   kHostMax       = 15;           // dotted IPv4
constexpr size_t   kKeyMin        = 8, kKeyMax = 32;

enum State : uint8_t { NONE = 0, ONLINE, OFFLINE };

struct Source {
    char     host[kHostMax + 1] = "";
    uint16_t port = 0;
    char     key[kKeyMax + 1] = "";
    bool     set = false;
    bool     failed = false;       // the last ask failed (app away)
    uint32_t failedAt = 0;
    // The photo on screen when it came from the app (remote = true): its id and place in the library.
    bool     remote = false;
    uint32_t curId = 0;
    uint16_t index = 0, count = 0;
};

// "192.168.1.20": four 0..255 parts, digits only.
inline bool validIPv4(const char* s) {
    if (!s) return false;
    int parts = 0, val = -1;
    for (const char* p = s;; p++) {
        if (*p >= '0' && *p <= '9') {
            val = (val < 0 ? 0 : val * 10) + (*p - '0');
            if (val > 255) return false;
        } else if (*p == '.' || *p == 0) {
            if (val < 0) return false;
            parts++;
            val = -1;
            if (!*p) break;
        } else {
            return false;
        }
    }
    return parts == 4;
}

// Letters and digits only (it goes into a URL path as is).
inline bool validKey(const char* k) {
    if (!k) return false;
    const size_t n = strlen(k);
    if (n < kKeyMin || n > kKeyMax) return false;
    for (size_t i = 0; i < n; i++) {
        const char c = k[i];
        if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'))) return false;
    }
    return true;
}

// The app says where its library is. A new key (the app restarted) starts the library from the first photo.
// false = refused (bad host / port / key), the source is unchanged.
inline bool setSource(Source& s, const char* host, long port, const char* key) {
    if (!validIPv4(host) || port < 1 || port > 65535 || !validKey(key)) return false;
    const bool newKey = strcmp(s.key, key) != 0;
    strncpy(s.host, host, kHostMax);
    s.host[kHostMax] = 0;
    s.port = (uint16_t)port;
    strncpy(s.key, key, kKeyMax);
    s.key[kKeyMax] = 0;
    s.set = true;
    s.failed = false;          // the app is here now: ask at once
    if (newKey) { s.curId = 0; s.index = s.count = 0; }
    return true;
}

// The app forgets the device / the user cleared it: cache only.
inline void clearSource(Source& s) { s = Source(); }

// Ask the app now? Only with a source, and not within kRetryMs of a failure.
inline bool wantRemote(const Source& s, uint32_t now) {
    return s.set && (!s.failed || now - s.failedAt >= kRetryMs);
}

// A photo came: it is on screen now.
inline void fetched(Source& s, uint32_t id, uint16_t index, uint16_t count) {
    s.failed = false;
    s.remote = true;
    s.curId = id;
    s.index = index;
    s.count = count;
}

// 204: the library is empty — the app is here, the cache shows.
inline void emptyLibrary(Source& s) {
    s.failed = false;
    s.remote = false;
    s.curId = 0;
    s.index = s.count = 0;
}

// No answer / a bad one: the cache shows until kRetryMs passed.
inline void fetchFailed(Source& s, uint32_t now) {
    s.failed = true;
    s.failedAt = now;
    s.remote = false;
}

// The screen moved to a cache photo (it does not follow the library any more until the next remote photo).
inline void showingCache(Source& s) { s.remote = false; }

inline State stateOf(const Source& s) {
    if (!s.set) return NONE;
    return s.failed ? OFFLINE : ONLINE;
}

inline const char* stateName(State st) {
    switch (st) {
        case ONLINE:  return "online";
        case OFFLINE: return "offline";
        default:      return "none";
    }
}

// The request path for the photo after the one on screen ("/p/<key>/next?after=12"); length or -1.
inline int nextPath(const Source& s, char* buf, size_t n) {
    const int r = snprintf(buf, n, "/p/%s/next?after=%lu", s.key, (unsigned long)(s.remote ? s.curId : 0));
    return r > 0 && (size_t)r < n ? r : -1;
}

// A header value as an unsigned number (X-Photo-Id / -Index / -Count); [bad] when missing or not a number.
inline uint32_t headerNumber(const char* v, uint32_t bad = 0) {
    if (!v || !*v) return bad;
    uint32_t r = 0;
    for (const char* p = v; *p; p++) {
        if (*p < '0' || *p > '9') return bad;
        r = r * 10 + (uint32_t)(*p - '0');
    }
    return r;
}

}  // namespace PhotoSource
