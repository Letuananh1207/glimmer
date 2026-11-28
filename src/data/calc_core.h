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

// ── The arithmetic on the device (plan thiet-bi-la-may-tinh stage 5; R-DK-27, was the app's calc_rules.dart) ──
// XP Standard: left to right, = repeats the last operation, % = a × b / 100, sqrt / 1/x / +/- on the number shown,
// memory. No libm (its tables cost RAM): square root by Newton, the display by integer digits.
enum Op : int8_t { OP_NONE = -1, OP_ADD, OP_SUB, OP_MUL, OP_DIV };
struct State {
    char   entry[kDisplayMax + 2] = "";   // the number being typed ("12", "0.", "-3.5"); typing = entry[0] != 0
    double value = 0, acc = 0, lastOperand = 0, memory = 0;
    int8_t op = OP_NONE, lastOp = OP_NONE;
    bool   error = false;
};

inline double parseNum(const char* s) {
    double v = 0, f = 0.1;
    bool neg = *s == '-', frac = false;
    if (neg) s++;
    for (; *s; s++) {
        if (*s == '.') { frac = true; continue; }
        if (!frac) v = v * 10 + (*s - '0');
        else { v += (*s - '0') * f; f /= 10; }
    }
    return neg ? -v : v;
}
inline double shownOf(const State& s) { return s.entry[0] ? parseNum(s.entry) : s.value; }

inline double sqrtN(double a) {
    if (a <= 0) return 0;
    double x = a > 1 ? a : 1;
    for (int i = 0; i < 60; i++) { const double y = 0.5 * (x + a / x); if (y == x) break; x = y; }
    return x;
}

// [v] in ≤ 16 characters as XP shows it: whole numbers "12.", others with up to 15 significant digits trimmed,
// huge / tiny ones "1.5e+20".
inline void format(double v, char* out) {
    if (v != v || v > 1e300 || v < -1e300 || v == 0) { strcpy(out, "0."); return; }
    const bool neg = v < 0;
    const double a = neg ? -v : v;
    if (a < 1e15) {
        const int64_t w = (int64_t)a;
        if ((double)w == a) {
            char t[24]; int n = 0;
            int64_t q = w;
            do { t[n++] = (char)('0' + q % 10); q /= 10; } while (q);
            int k = 0;
            if (neg) out[k++] = '-';
            while (n) out[k++] = t[--n];
            out[k++] = '.'; out[k] = 0;
            return;
        }
    }
    int e = 0;
    double m = a;
    while (m >= 10) { m /= 10; e++; }
    while (m < 1) { m *= 10; e--; }
    for (int p = 15; p >= 1; p--) {
        double sc = m;
        for (int i = 1; i < p; i++) sc *= 10;
        uint64_t d = (uint64_t)(sc + 0.5);
        uint64_t lim = 1;
        for (int i = 0; i < p; i++) lim *= 10;
        int ee = e;
        if (d >= lim) { d /= 10; ee++; }
        char dg[16]; int n = p;
        for (int i = p - 1; i >= 0; i--) { dg[i] = (char)('0' + d % 10); d /= 10; }
        while (n > 1 && dg[n - 1] == '0') n--;
        char t[40]; int k = 0;
        if (neg) t[k++] = '-';
        if (ee >= 0 && ee < 15) {
            for (int i = 0; i <= ee; i++) t[k++] = i < n ? dg[i] : '0';
            t[k++] = '.';
            for (int i = ee + 1; i < n; i++) t[k++] = dg[i];
        } else if (ee < 0 && ee >= -5) {
            t[k++] = '0'; t[k++] = '.';
            for (int i = 0; i < -ee - 1; i++) t[k++] = '0';
            for (int i = 0; i < n; i++) t[k++] = dg[i];
        } else {
            t[k++] = dg[0]; t[k++] = '.';
            for (int i = 1; i < n; i++) t[k++] = dg[i];
            t[k++] = 'e'; t[k++] = ee < 0 ? '-' : '+';
            const int ae = ee < 0 ? -ee : ee;
            if (ae >= 100) t[k++] = (char)('0' + ae / 100);
            if (ae >= 10) t[k++] = (char)('0' + ae / 10 % 10);
            t[k++] = (char)('0' + ae % 10);
        }
        t[k] = 0;
        if (k <= kDisplayMax || p == 1) { memcpy(out, t, (size_t)(k <= kDisplayMax ? k : kDisplayMax)); out[k <= kDisplayMax ? k : kDisplayMax] = 0; return; }
    }
}

inline bool applyOp(int8_t op, double a, double b, double& r) {
    switch (op) {
        case OP_ADD: r = a + b; return true;
        case OP_SUB: r = a - b; return true;
        case OP_MUL: r = a * b; return true;
        case OP_DIV: if (b == 0) return false; r = a / b; return true;
        default: r = b; return true;
    }
}
inline void setError(State& s) { const double m = s.memory; s = State(); s.memory = m; s.error = true; }
// A function result (%, sqrt, 1/x, MR) on screen: it counts as a typed number for the next operation.
inline void showResult(State& s, double v) {
    char t[kDisplayMax + 2];
    format(v, t);
    const size_t n = strlen(t);
    if (n && t[n - 1] == '.') t[n - 1] = 0;
    strcpy(s.entry, t);
    s.value = v;
}

inline void press(State& s, int k) {
    if (s.error) { if (k == KEY_C || k == KEY_CE) { const double m = s.memory; s = State(); s.memory = m; } return; }
    const int c = k < kGrid ? k % kCols : -1, r = k < kGrid ? k / kCols : -1;
    // Digits: columns 1–3 of rows 0–2, and 0 at (3, 1).
    int digit = -1;
    if (c >= 1 && c <= 3 && r <= 2) digit = (2 - r) * 3 + c;
    if (r == 3 && c == 1) digit = 0;
    if (digit >= 0) {
        size_t n = strlen(s.entry);
        if (!n || !strcmp(s.entry, "0")) { s.entry[0] = (char)('0' + digit); s.entry[1] = 0; return; }
        if (!strcmp(s.entry, "-0")) { s.entry[1] = (char)('0' + digit); return; }
        const size_t shown = n + (strchr(s.entry, '.') ? 0 : 1);
        if (shown >= (size_t)kDisplayMax) return;
        s.entry[n] = (char)('0' + digit); s.entry[n + 1] = 0;
        return;
    }
    int8_t op = OP_NONE;
    if (c == 4) op = r == 0 ? OP_DIV : r == 1 ? OP_MUL : r == 2 ? OP_SUB : OP_ADD;
    if (op != OP_NONE) {
        const double x = shownOf(s);
        if (s.op != OP_NONE && !s.entry[0]) { s.op = op; return; }   // pressed twice: only the operation changes
        if (s.op != OP_NONE) {
            double res;
            if (!applyOp(s.op, s.acc, x, res)) { setError(s); return; }
            s.entry[0] = 0; s.value = res; s.acc = res; s.op = op;
            return;
        }
        s.entry[0] = 0; s.value = x; s.acc = x; s.op = op;
        return;
    }
    if (k == 21) {                                          // .
        size_t n = strlen(s.entry);
        if (!n) { strcpy(s.entry, "0."); return; }
        if (!strchr(s.entry, '.') && n < (size_t)kDisplayMax) { s.entry[n] = '.'; s.entry[n + 1] = 0; }
        return;
    }
    if (k == 23) {                                          // =
        const double x = shownOf(s);
        double res;
        if (s.op != OP_NONE) {
            if (!applyOp(s.op, s.acc, x, res)) { setError(s); return; }
            s.lastOp = s.op; s.lastOperand = x; s.op = OP_NONE;
        } else if (s.lastOp != OP_NONE) {
            if (!applyOp(s.lastOp, x, s.lastOperand, res)) { setError(s); return; }
        } else {
            res = x;
        }
        s.entry[0] = 0; s.value = res; s.acc = res;
        return;
    }
    switch (k) {
        case 11: showResult(s, s.op == OP_NONE ? 0 : s.acc * shownOf(s) / 100); return;     // %
        case 5:  if (shownOf(s) >= 0) showResult(s, sqrtN(shownOf(s))); return;              // sqrt
        case 17: if (shownOf(s) == 0) setError(s); else showResult(s, 1 / shownOf(s)); return;   // 1/x
        case 20: {                                                                           // +/-
            if (!s.entry[0]) { s.value = -s.value; return; }
            if (!strcmp(s.entry, "0")) return;
            if (s.entry[0] == '-') memmove(s.entry, s.entry + 1, strlen(s.entry));
            else { memmove(s.entry + 1, s.entry, strlen(s.entry) + 1); s.entry[0] = '-'; }
            return;
        }
        case KEY_BACK: {
            size_t n = strlen(s.entry);
            if (!n) return;
            s.entry[n - 1] = 0;
            if (!s.entry[0] || !strcmp(s.entry, "-")) strcpy(s.entry, "0");
            return;
        }
        case KEY_CE: s.entry[0] = 0; s.value = 0; return;
        case KEY_C:  { const double m = s.memory; s = State(); s.memory = m; return; }
        case 0:  s.memory = 0; return;                                                       // MC
        case 6:  showResult(s, s.memory); return;                                            // MR
        case 12: s.memory = shownOf(s); return;                                              // MS
        case 18: s.memory += shownOf(s); return;                                             // M+
        default: return;
    }
}

// What the window shows for [s]; [down] = the key drawn pressed.
inline View viewOf(const State& s, int8_t down) {
    View v;
    if (s.entry[0]) {
        char t[kDisplayMax + 3];
        strcpy(t, s.entry);
        if (!strchr(t, '.')) strcat(t, ".");
        setDisplay(v, t);
    } else {
        char t[kDisplayMax + 2];
        format(s.value, t);
        setDisplay(v, t);
    }
    v.error = s.error;
    v.mem = s.memory != 0;
    v.down = down;
    return v;
}

}  // namespace CalcCore
