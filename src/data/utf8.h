#pragma once
// UTF-8 helpers for fixed char buffers. The UI is Vietnamese, so most
// accented letters are 2–3 bytes: a byte-wise cut can leave half a
// character, which TFT_eSPI decodes as garbage. Pure C — host-testable.
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

namespace Utf8 {

inline bool isCont(char c) { return ((uint8_t)c & 0xC0) == 0x80; }

// Drop a trailing incomplete sequence (e.g. after snprintf truncation).
inline void trimPartial(char* s) {
    size_t n = strlen(s);
    if (!n) return;
    size_t lead = n - 1;
    while (lead > 0 && isCont(s[lead])) lead--;
    uint8_t b = (uint8_t)s[lead];
    size_t want = b < 0x80 ? 1 : (b & 0xE0) == 0xC0 ? 2 : (b & 0xF0) == 0xE0 ? 3
                : (b & 0xF8) == 0xF0 ? 4 : 1;
    if (n - lead < want) s[lead] = '\0';
}

// Byte index where the code point before `n` starts (n > 0).
inline size_t prevChar(const char* s, size_t n) {
    if (!n) return 0;
    do { n--; } while (n > 0 && isCont(s[n]));
    return n;
}

// snprintf("%s") that never splits a character.
inline void copy(char* dst, size_t n, const char* src) {
    if (!n) return;
    snprintf(dst, n, "%s", src ? src : "");
    trimPartial(dst);
}

// Case mapping for ASCII + every Vietnamese letter, in place. Each pair has
// the same UTF-8 length (Latin-1 à↔À, Latin Ext-A ă đ ĩ ũ ơ ư, and the
// U+1EA0–1EF9 block where upper = even), so the buffer never grows.
inline uint32_t caseMap(uint32_t c, bool toUpper) {
    if (c < 0x80) {
        if (toUpper && c >= 'a' && c <= 'z') return c - 32;
        if (!toUpper && c >= 'A' && c <= 'Z') return c + 32;
        return c;
    }
    if (c >= 0xC0 && c <= 0xFE && c != 0xD7 && c != 0xF7 && c != 0xDF)
        return toUpper ? (c & ~0x20u) : (c | 0x20u);
    if (c == 0x102 || c == 0x103 || c == 0x110 || c == 0x111 ||     // Ă ă Đ đ
        c == 0x128 || c == 0x129 || c == 0x168 || c == 0x169 ||     // Ĩ ĩ Ũ ũ
        (c >= 0x1EA0 && c <= 0x1EF9))
        return toUpper ? (c & ~1u) : (c | 1u);
    if (c == 0x1A0 || c == 0x1A1) return toUpper ? 0x1A0 : 0x1A1;   // Ơ ơ
    if (c == 0x1AF || c == 0x1B0) return toUpper ? 0x1AF : 0x1B0;   // Ư ư
    return c;
}

inline void mapCase(char* s, bool toUpper, bool skipFirst = false) {
    uint8_t* p = (uint8_t*)s;
    bool first = true;
    while (*p) {
        uint32_t c; int len;
        if (*p < 0x80)                                         { c = *p; len = 1; }
        else if ((*p & 0xE0) == 0xC0 && isCont((char)p[1]))   { c = ((*p & 0x1Fu) << 6) | (p[1] & 0x3F); len = 2; }
        else if ((*p & 0xF0) == 0xE0 && isCont((char)p[1]) && isCont((char)p[2]))
            { c = ((*p & 0x0Fu) << 12) | ((p[1] & 0x3Fu) << 6) | (p[2] & 0x3F); len = 3; }
        else { p++; first = false; continue; }                // 4-byte / malformed: leave
        if (!(skipFirst && first)) {
            uint32_t m = caseMap(c, toUpper);
            if (len == 1)      p[0] = (uint8_t)m;
            else if (len == 2) { p[0] = (uint8_t)(0xC0 | (m >> 6)); p[1] = (uint8_t)(0x80 | (m & 0x3F)); }
            else { p[0] = (uint8_t)(0xE0 | (m >> 12)); p[1] = (uint8_t)(0x80 | ((m >> 6) & 0x3F));
                   p[2] = (uint8_t)(0x80 | (m & 0x3F)); }
        }
        first = false;
        p += len;
    }
}

inline void upper(char* s) { mapCase(s, true); }
// Sentence case: first character kept, the rest lowered.
inline void sentence(char* s) { mapCase(s, false, true); }

}  // namespace Utf8
