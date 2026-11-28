#pragma once
// Task Manager's numbers (P-2026-11-28.28, XP-TaskMgr) — pure, host-tested (test/test_logic).
//
// main.cpp samples once a second: CPU = the share of the second loop() spent outside its delay(10)
// (XP's "CPU Usage" is the share not idle), heap used, Wi-Fi strength. The histories live in RAM
// (38 + 38 + 48 bytes) and survive repaints under the cursor; a power-off does not clear them.
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>

namespace Perf {

constexpr int kCpuN = 38;                  // Lịch sử dùng CPU / bộ nhớ: 38 points × 4 px
constexpr int kNetN = 48;                  // Mạng: 48 points × 4 px
constexpr int kStepPx = 4;                 // one point a second
constexpr int kLeds = 6;                   // gauge: 6 steps × 2 columns

// A ring of the last N percentages (0..100), oldest first by at().
template <int N>
struct Ring {
    uint8_t v[N] = {};
    uint8_t n = 0, head = 0;               // head = where the next sample goes
    void push(uint8_t pct) {
        v[head] = pct > 100 ? 100 : pct;
        head = (uint8_t)((head + 1) % N);
        if (n < N) n++;
    }
    // i = 0 oldest .. n−1 newest.
    uint8_t at(int i) const { return v[(head + N - n + i) % N]; }
};

// What the app touched in the window (POST /api/taskmgr): tab 0 Ứng dụng / 1 Hiệu năng / 2 Mạng, the selected
// row of Ứng dụng (−1 none).
struct View { uint8_t tab = 0; int8_t sel = -1; };
constexpr uint8_t kTabs = 3;

struct History {
    Ring<kCpuN> cpu, mem;
    Ring<kNetN> net;
};

// Busy share of [elapsedUs] when [idleUs] of it was spent idle (delay); clamped 0..100.
inline uint8_t cpuPct(uint32_t idleUs, uint32_t elapsedUs) {
    if (!elapsedUs) return 0;
    if (idleUs >= elapsedUs) return 0;
    const uint32_t busy = elapsedUs - idleUs;
    return (uint8_t)((busy * 100ULL + elapsedUs / 2) / elapsedUs);
}

// Heap used of [total] when [free] is free, in % (total 0 → 0).
inline uint8_t memPct(uint32_t freeBytes, uint32_t total) {
    if (!total || freeBytes >= total) return 0;
    return (uint8_t)(((total - freeBytes) * 100ULL + total / 2) / total);
}

// Wi-Fi strength: −100 dBm → 0 %, −40 dBm → 100 % (linear, clamped); not connected (0 / > 0) → 0.
inline uint8_t rssiPct(int dbm) {
    if (dbm >= 0) return 0;
    if (dbm <= -100) return 0;
    if (dbm >= -40) return 100;
    return (uint8_t)(((dbm + 100) * 100 + 30) / 60);
}

// Gauge steps lit from the bottom (0..6): any load lights one, 100 % all six.
inline int ledsLit(uint8_t pct) {
    if (!pct) return 0;
    const int n = (pct * kLeds + 99) / 100;
    return n > kLeds ? kLeds : n;
}

// Point i (0 oldest) of a graph whose newest point sits at x [right]: x of the point when [n] are kept.
inline int pointX(int right, int n, int i) { return right - kStepPx * (n - 1 - i); }

// y of [pct] in a graph box (top, h): 0 % on the bottom row, 100 % on the top row.
inline int pointY(int top, int h, uint8_t pct) {
    const int span = h - 1;
    return top + span - (pct * span + 50) / 100;
}

// Đã chạy: "2NG 3G 14P", "3G 14P", "14P" from minutes since boot (short units, CLAUDE.md Vietnamese UI).
inline void uptime(uint32_t minutes, char* buf, size_t n) {
    const uint32_t d = minutes / 1440, h = minutes / 60 % 24, m = minutes % 60;
    if (d)      snprintf(buf, n, "%luNG %luG %luP", (unsigned long)d, (unsigned long)h, (unsigned long)m);
    else if (h) snprintf(buf, n, "%luG %luP", (unsigned long)h, (unsigned long)m);
    else        snprintf(buf, n, "%luP", (unsigned long)m);
}

}  // namespace Perf
