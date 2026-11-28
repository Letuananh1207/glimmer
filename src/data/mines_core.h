#pragma once
// Dò mìn (P-2026-11-27.25, screen_specs §17 XP-Mines) — what the device draws, pure, host-tested.
//
// The app keeps the game (you chose 2026-11-27: the app is the computer): it places the mines after the
// first click, opens, flags, decides win / loss, and sends the whole board down (POST /api/mines). The
// device only draws it, repainting the cells that changed, and runs the seconds counter itself between
// two messages (the app sends the seconds and whether the clock runs).
//
// Board: 81 chars, row by row (cell (c, r) = index 9r + c):
//   '.' not opened   'F' flag            'P' pressed (left button held on it: drawn opened, empty)
//   '0'..'8' opened  'M' mine (shown on a loss)   'X' the mine clicked (red)   'W' wrong flag
#include <stdint.h>
#include <stddef.h>
#include <string.h>

namespace Mines {

constexpr int kCols = 9, kRows = 9, kCells = 81, kMines = 10;
constexpr int kBoardX = 48, kBoardY = 64, kCell = 16;    // cell (c, r) at (48 + 16c, 64 + 16r)
constexpr int kSecsMax = 999;

enum Face : uint8_t { FACE_SMILE, FACE_WOW, FACE_COOL, FACE_DEAD };

struct View {
    char     cell[kCells];
    uint8_t  face = FACE_SMILE;
    int16_t  left = kMines;     // mines left = 10 − flags (may go below 0)
    uint16_t secs = 0;          // seconds when the app sent it
    bool     run = false;       // the clock runs on from secs
    View() { memset(cell, '.', sizeof(cell)); }
};

inline bool validCell(char c) {
    return c == '.' || c == 'F' || c == 'P' || (c >= '0' && c <= '8') || c == 'M' || c == 'X' || c == 'W';
}

// A board string from the app: exactly 81 valid chars. false leaves [out] alone.
inline bool parseBoard(const char* s, char out[kCells]) {
    if (!s || strlen(s) != (size_t)kCells) return false;
    for (int i = 0; i < kCells; i++) if (!validCell(s[i])) return false;
    memcpy(out, s, kCells);
    return true;
}

inline int faceOf(const char* s) {
    if (!s) return -1;
    if (!strcmp(s, "smile")) return FACE_SMILE;
    if (!strcmp(s, "wow"))   return FACE_WOW;
    if (!strcmp(s, "cool"))  return FACE_COOL;
    if (!strcmp(s, "dead"))  return FACE_DEAD;
    return -1;
}

inline const char* faceName(int f) {
    static const char* const k[] = {"smile", "wow", "cool", "dead"};
    return f >= 0 && f < 4 ? k[f] : "smile";
}

// The cell under screen point (x, y), -1 = none (the app's hit rule mirrors this).
inline int cellAt(int x, int y) {
    if (x < kBoardX || y < kBoardY) return -1;
    const int c = (x - kBoardX) / kCell, r = (y - kBoardY) / kCell;
    return c < kCols && r < kRows ? r * kCols + c : -1;
}

// Seconds to show: what the app sent, plus the time since if the clock runs; at most 999.
inline uint16_t shownSecs(const View& v, uint32_t sentMs, uint32_t nowMs) {
    uint32_t s = v.secs + (v.run ? (nowMs - sentMs) / 1000 : 0);
    return (uint16_t)(s > (uint32_t)kSecsMax ? kSecsMax : s);
}

// 7-segment patterns (bit 6 = a … bit 0 = g) of the 3 LED digits for [v]: 000..999, a minus as
// XP shows it below 0 ("-01"; −99 at least).
// ── The game on the device (plan thiet-bi-la-may-tinh, stage 4; was the app's mines_rules.dart, R-DK-23) ──
// Minesweeper of XP at Beginner: the first click of a game never hits a mine (mines placed after it), a 0 opens its
// neighbours (flags kept), a mine = lost, every safe cell open = won (every mine flagged). Bit sets: 3 × 11 B.
enum Status : uint8_t { ST_READY, ST_PLAYING, ST_WON, ST_LOST };
struct Bits {
    uint8_t b[11] = {};
    bool has(int i) const { return b[i >> 3] >> (i & 7) & 1; }
    void set(int i, bool on) { if (on) b[i >> 3] |= (uint8_t)(1 << (i & 7)); else b[i >> 3] &= (uint8_t)~(1 << (i & 7)); }
    int count() const { int n = 0; for (int i = 0; i < kCells; i++) n += has(i); return n; }
};
struct Game {
    Bits mines, opened, flags;
    uint8_t status = ST_READY;
    int8_t blast = -1;
    uint32_t startMs = 0, endMs = 0;
};

inline int around(int i, int8_t out[8]) {
    const int c = i % kCols, r = i / kCols;
    int n = 0;
    for (int dr = -1; dr <= 1; dr++)
        for (int dc = -1; dc <= 1; dc++) {
            if (!dr && !dc) continue;
            const int cc = c + dc, rr = r + dr;
            if (cc >= 0 && cc < kCols && rr >= 0 && rr < kRows) out[n++] = (int8_t)(rr * kCols + cc);
        }
    return n;
}
inline int minesAround(const Game& g, int i) {
    int8_t nb[8];
    const int n = around(i, nb);
    int m = 0;
    for (int k = 0; k < n; k++) m += g.mines.has(nb[k]);
    return m;
}

// [rnd](n) = a random number 0 ≤ r < n (the device's hardware RNG; seeded in tests).
template <typename Rnd>
inline void placeMines(Game& g, int safe, Rnd rnd) {
    int placed = 0;
    while (placed < kMines) {
        const int k = (int)rnd(kCells);
        if (k == safe || g.mines.has(k)) continue;
        g.mines.set(k, true);
        placed++;
    }
}

template <typename Rnd>
inline void reveal(Game& g, int i, uint32_t now, Rnd rnd) {
    if (i < 0 || i >= kCells || g.status == ST_WON || g.status == ST_LOST || g.flags.has(i) || g.opened.has(i)) return;
    if (g.status == ST_READY) {
        placeMines(g, i, rnd);
        g.status = ST_PLAYING;
        g.startMs = now;
    }
    if (g.mines.has(i)) {
        g.opened.set(i, true);
        g.status = ST_LOST;
        g.blast = (int8_t)i;
        g.endMs = now;
        return;
    }
    int8_t todo[kCells];
    int n = 0;
    todo[n++] = (int8_t)i;
    while (n) {
        const int k = todo[--n];
        if (g.opened.has(k)) continue;
        g.opened.set(k, true);
        if (minesAround(g, k)) continue;
        int8_t nb[8];
        const int m = around(k, nb);
        for (int j = 0; j < m; j++)
            if (!g.opened.has(nb[j]) && !g.flags.has(nb[j]) && !g.mines.has(nb[j]) && n < kCells) todo[n++] = nb[j];
    }
    if (g.opened.count() == kCells - kMines) {
        g.flags = g.mines;
        g.status = ST_WON;
        g.endMs = now;
    }
}

inline void flag(Game& g, int i) {
    if (i < 0 || i >= kCells || g.status == ST_WON || g.status == ST_LOST || g.opened.has(i)) return;
    g.flags.set(i, !g.flags.has(i));
}

// What ch_mines draws for [g] at [now]: the board ('.', 'F', '0'..'8'; lost: 'M' mines, 'X' the blast, 'W' wrong
// flags), the face, mines left (10 − flags, 0 once won), the seconds and whether they run.
inline View viewOf(const Game& g, uint32_t now) {
    View v;
    const bool lost = g.status == ST_LOST;
    for (int i = 0; i < kCells; i++) {
        const bool mine = g.mines.has(i), fl = g.flags.has(i);
        char c = '.';
        if (lost && i == g.blast) c = 'X';
        else if (lost && fl && !mine) c = 'W';
        else if (fl) c = 'F';
        else if (lost && mine) c = 'M';
        else if (g.opened.has(i)) c = (char)('0' + minesAround(g, i));
        v.cell[i] = c;
    }
    v.face = g.status == ST_WON ? FACE_COOL : lost ? FACE_DEAD : FACE_SMILE;
    v.left = (int16_t)(g.status == ST_WON ? 0 : kMines - g.flags.count());
    const uint32_t end = g.status == ST_PLAYING ? now : g.endMs;
    const uint32_t s = g.status == ST_READY ? 0 : (end - g.startMs) / 1000;
    v.secs = (uint16_t)(s > (uint32_t)kSecsMax ? kSecsMax : s);
    v.run = g.status == ST_PLAYING;
    return v;
}

// The face button 26 × 26 at (107, 29).
inline bool faceAt(int x, int y) { return x >= 107 && x < 133 && y >= 29 && y < 55; }

constexpr uint8_t kSegDigit[10] = {0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B};
constexpr uint8_t kSegMinus = 0x01;
inline void ledDigits(int v, uint8_t out[3]) {
    if (v > kSecsMax) v = kSecsMax;
    if (v < 0) {
        int a = -v > 99 ? 99 : -v;
        out[0] = kSegMinus; out[1] = kSegDigit[a / 10]; out[2] = kSegDigit[a % 10];
        return;
    }
    out[0] = kSegDigit[v / 100]; out[1] = kSegDigit[v / 10 % 10]; out[2] = kSegDigit[v % 10];
}

}  // namespace Mines
