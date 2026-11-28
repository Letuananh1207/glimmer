#pragma once
// Explorer (P-2026-11-28.32, XP-Explorer): Máy tính / Ảnh của tôi / Thùng rác — what the app touched, the
// Recycle Bin's index format and the text / geometry rules. Pure, host-tested.
//
// Thùng rác (as XP's Recycle Bin): deleting a photo moves its file to /trash/<name> and appends an Entry to
// /trash/index.bin (name, size, when). Khôi phục moves it back; Dọn sạch deletes the files for good. The
// index lives on flash only — nothing in RAM but its count.
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stddef.h>
#ifdef ARDUINO
#include <pgmspace.h>
#define EX_PRINTF(out, n, fmt, ...) snprintf_P(out, n, PSTR(fmt), ##__VA_ARGS__)   // formats in flash
#else
#define EX_PRINTF(out, n, fmt, ...) snprintf(out, n, fmt, ##__VA_ARGS__)
#endif

namespace ExplorerCore {

enum Place : uint8_t { PLACE_COMPUTER, PLACE_PHOTOS, PLACE_TRASH, PLACE_COUNT };
enum Confirm : uint8_t { CONFIRM_NONE, CONFIRM_DELETE, CONFIRM_EMPTY };

struct View {
    uint8_t place = PLACE_COMPUTER;
    int8_t  sel = -1;          // selected item of the place (photo index / trash row), −1 none
    uint8_t top = 0;           // Ảnh của tôi: first row shown (4 photos a row, 2 rows on screen)
    uint8_t confirm = CONFIRM_NONE;
};

// ── Recycle Bin index ──
constexpr int kTrashMax = 16;              // 8 user photos + 8 samples
struct Entry {
    char     name[14];                     // "p3.jpg" / "s2.jpg"
    uint32_t size;                         // bytes
    uint32_t at;                           // epoch deleted (0 = clock not set)
};

// What the user sees for a file: sample photos s<N>.jpg are "mau<N>.jpg" (Vietnamese "mẫu"), others as is.
inline void shownName(const char* file, char* out, size_t n) {
    if (file && file[0] == 's' && file[1] >= '1' && file[1] <= '9') EX_PRINTF(out, n, "mau%s", file + 1);
    else EX_PRINTF(out, n, "%s", file ? file : "");
}

// "32 KB" (rounded up, as Explorer: a 1-byte file is 1 KB; 0 → "0 KB").
inline void sizeText(uint32_t bytes, char* out, size_t n) {
    EX_PRINTF(out, n, "%lu KB", (unsigned long)((bytes + 1023) / 1024));
}

// Máy tính › Bộ nhớ (C:): "trống 412 KB / 1 MB" — free KB, total in MB (rounded) once ≥ 1 MB.
inline void driveText(uint32_t freeB, uint32_t totalB, char* out, size_t n) {
    if (totalB >= 1000000UL)
        EX_PRINTF(out, n, "trống %lu KB / %lu MB", (unsigned long)(freeB / 1024),
                 (unsigned long)((totalB + 524288UL) / 1048576UL));
    else
        EX_PRINTF(out, n, "trống %lu KB / %lu KB", (unsigned long)(freeB / 1024), (unsigned long)(totalB / 1024));
}
// The used part of the drive bar (120 px inside).
inline int driveUsedW(uint32_t freeB, uint32_t totalB) {
    if (!totalB || freeB >= totalB) return 0;
    return (int)((uint64_t)(totalB - freeB) * 120 / totalB);
}

// "8 đối tượng · 214 KB" / "0 đối tượng" (status bar, left cell).
inline void objectsText(int n, uint32_t bytes, bool withSize, char* out, size_t len) {
    if (withSize && n > 0) EX_PRINTF(out, len, "%d đối tượng \xC2\xB7 %lu KB", n, (unsigned long)((bytes + 1023) / 1024));
    else EX_PRINTF(out, len, "%d đối tượng", n);
}

// ── Ảnh của tôi: thumbnails ── cells 57 × 72, 4 a row from (6, 28), 2 rows on screen.
constexpr int kThumbCols = 4, kThumbRows = 2, kCellW = 57, kCellH = 72;
inline bool thumbCell(int i, int top, int& x, int& y) {
    const int row = i / kThumbCols - top;
    if (row < 0 || row >= kThumbRows) return false;
    x = 6 + kCellW * (i % kThumbCols);
    y = 28 + kCellH * row;
    return true;
}

// ── Thùng rác: buttons and rows ──
struct Rect { int16_t x, y, w, h; };
constexpr Rect kEmptyBtn = {6, 26, 136, 21}, kRestoreBtn = {146, 26, 75, 21};
constexpr int kRowY = 70, kRowH = 18, kRowsShown = 6;
// Confirm box buttons (Có / Không).
constexpr Rect kYesBtn = {58, 134, 56, 21}, kNoBtn = {126, 134, 56, 21};
inline bool in(const Rect& r, int x, int y) { return x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h; }

// "14:02" when deleted today, else "28/11" (dd/mm), "--" with no clock. [dayNow] / [day] = days since epoch
// in local time; [minOfDay] = local minutes of [at].
inline void deletedText(uint32_t at, long dayAt, long dayNow, int minOfDay, int mday, int mon, char* out, size_t n) {
    if (!at) { EX_PRINTF(out, n, "--"); return; }
    if (dayAt == dayNow) EX_PRINTF(out, n, "%02d:%02d", minOfDay / 60, minOfDay % 60);
    else EX_PRINTF(out, n, "%02d/%02d", mday, mon);
}

// Plan thiet-bi-la-may-tinh stage 5 (R-DK-28, was the app's): what a click on the window hits.
enum HitKind : uint8_t { HIT_NONE, HIT_OPEN_PHOTOS, HIT_ITEM, HIT_EMPTY, HIT_RESTORE, HIT_YES, HIT_NO };
struct Hit { uint8_t kind = HIT_NONE; int8_t value = -1; };
inline Hit hitAt(const View& v, int x, int y, int photos, int trash) {
    Hit h;
    auto mk = [&h](uint8_t k, int val = -1) { h.kind = k; h.value = (int8_t)val; return h; };
    if (v.confirm != CONFIRM_NONE) {
        if (in(kYesBtn, x, y)) return mk(HIT_YES);
        if (in(kNoBtn, x, y)) return mk(HIT_NO);
        return h;
    }
    if (v.place == PLACE_COMPUTER) {
        if (x >= 8 && x < 230 && y >= 118 && y < 152) return mk(HIT_OPEN_PHOTOS);
        return h;
    }
    if (v.place == PLACE_PHOTOS) {
        if (x < 2 || x >= 238 || y < 22 || y >= 196) return h;
        if (x >= 6 && y >= 28) {
            const int col = (x - 6) / kCellW, row = (y - 28) / kCellH;
            if (col < kThumbCols && row < kThumbRows) {
                const int i = (v.top + row) * kThumbCols + col;
                return mk(HIT_ITEM, i < photos ? i : -1);
            }
        }
        return mk(HIT_ITEM, -1);
    }
    if (in(kEmptyBtn, x, y)) return trash > 0 ? mk(HIT_EMPTY) : h;
    if (in(kRestoreBtn, x, y)) return trash > 0 && v.sel >= 0 ? mk(HIT_RESTORE) : h;
    if (x >= 7 && x < 233 && y >= kRowY && y < kRowY + kRowH * kRowsShown) {
        const int i = (y - kRowY) / kRowH;
        return mk(HIT_ITEM, i < trash ? i : -1);
    }
    if (x >= 7 && x < 233 && y >= 53 && y < 191) return mk(HIT_ITEM, -1);
    return h;
}
// Ảnh của tôi: [v] after an arrow ([dx], [dy] cells) among [photos]; rows scroll to keep the selection in sight.
inline View move(View v, int dx, int dy, int photos) {
    if (photos <= 0) return v;
    int sel = v.sel < 0 ? 0 : v.sel + dx + dy * kThumbCols;
    if (sel < 0) sel = 0;
    if (sel > photos - 1) sel = photos - 1;
    const int row = sel / kThumbCols;
    if (row < v.top) v.top = (uint8_t)row;
    else if (row >= v.top + kThumbRows) v.top = (uint8_t)(row - kThumbRows + 1);
    v.sel = (int8_t)sel;
    return v;
}

}  // namespace ExplorerCore
