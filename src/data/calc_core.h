#pragma once
// Máy tính bỏ túi (P-2026-11-28.31, XP-Calc) — layout + what the app sends, pure, host-tested. The app keeps
// the arithmetic (XP Standard: left to right, = repeats the last operation, Backspace / CE / C, memory);
// the device only draws (POST /api/calc {display, error, mem, down}).
#include <stdint.h>
#include <string.h>
#include <stddef.h>
#ifdef ARDUINO
#include <pgmspace.h>
#define CALC_READ(p) pgm_read_byte(p)
#else
#ifndef PROGMEM
#define PROGMEM
#endif
#define CALC_READ(p) (*(p))
#endif

namespace CalcCore {

constexpr int kCols = 6, kRows = 4, kGrid = kCols * kRows;     // 24 grid keys
enum : int8_t { KEY_NONE = -1, KEY_BACK = kGrid, KEY_CE, KEY_C, KEY_COUNT };
constexpr int kDisplayMax = 16;                                // characters on the display

struct View {
    char   display[kDisplayMax + 1] = "0.";
    bool   error = false;        // "Không thể chia cho 0." instead of the number
    bool   mem = false;          // something in memory: "M" in the memory cell
    int8_t down = KEY_NONE;      // the key held down (the app's click)
};

struct Rect { int16_t x, y, w, h; };
// Key [k]: the grid 6 × 4 of 34×26 from (8 + 38c, 86 + 30r); Backspace / CE / C along y 56, 24 tall.
inline Rect key(int k) {
    if (k == KEY_BACK) return {46, 56, 76, 24};
    if (k == KEY_CE)   return {126, 56, 52, 24};
    if (k == KEY_C)    return {182, 56, 50, 24};
    return {(int16_t)(8 + 38 * (k % kCols)), (int16_t)(86 + 30 * (k / kCols)), 34, 26};
}
// Key [k]'s label into [out] (labels packed in one flash string, '|' between them).
inline void label(int k, char* out, size_t n) {
    static const char kLabels[] PROGMEM =
        "MC|7|8|9|/|sqrt|MR|4|5|6|*|%|MS|1|2|3|-|1/x|M+|0|+/-|.|+|=|Backspace|CE|C";
    size_t o = 0;
    int i = 0;
    for (const char* p = kLabels;; p++) {
        const char c = (char)CALC_READ(p);
        if (!c || c == '|') { if (i == k || !c) break; i++; continue; }
        if (i == k && o + 1 < n) out[o++] = c;
    }
    if (n) out[o < n ? o : n - 1] = 0;
}
// Digits, "." and "+/-" are blue (xpGroupLabel); memory keys, operators and the top row red (xpRed).
inline bool blueKey(int k) {
    if (k < 0 || k >= kGrid) return false;
    const int c = k % kCols;
    return c >= 1 && c <= 3;                           // 7 8 9 · 4 5 6 · 1 2 3 · 0 +/- .
}
// The key under (x, y), else KEY_NONE.
inline int8_t keyAt(int x, int y) {
    for (int k = 0; k < KEY_COUNT; k++) {
        const Rect r = key(k);
        if (x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h) return (int8_t)k;
    }
    return KEY_NONE;
}
// The app's display text: kept as sent, cut to kDisplayMax characters (ASCII digits / '.' / '-' / 'e').
inline void setDisplay(View& v, const char* s) {
    size_t n = s ? strlen(s) : 0;
    if (n > (size_t)kDisplayMax) n = kDisplayMax;
    memcpy(v.display, s ? s : "", n);
    v.display[n] = 0;
}

}  // namespace CalcCore
