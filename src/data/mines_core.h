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
