#pragma once
// Photos (skill `photo`, design P-2026-11-25.7) — pure logic, host-tested.
//
// The user's photos are baseline JPEGs of exactly kSide × kSide stored on
// LittleFS as /photos/p<N>.jpg; N grows with each upload, so name order =
// upload order. The device never scales: the app / web page crops and
// resizes before sending.
//
// Sample photos (like XP's "Sample Pictures") ship in the filesystem image as
// /photos/s<N>.jpg (tools/samplephotos.py): shown after the user's photos so
// the window is never empty, outside the kMax user slots, deletable like any
// photo (a filesystem flash brings them back).
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

namespace Photos {

constexpr int      kMax          = 8;            // user photos kept
constexpr int      kMaxSamples   = 8;            // sample photos read at boot
constexpr char     kUserPrefix   = 'p';
constexpr char     kSamplePrefix = 's';
constexpr uint32_t kMaxBytes     = 40UL * 1024;  // per photo
constexpr uint32_t kReserveBytes = 64UL * 1024;  // LittleFS left free for config / usage / weather
constexpr int      kSide         = 188;          // exact width = height (Layout::CONTENT_W)

// ── JPEG header check, fed in arbitrary chunks (upload buffers) ─────────────
//
// Walks the markers from SOI to the first SOFn and reads its size. Decides
// as soon as the SOF is seen; the rest of the stream is ignored.
enum JpegVerdict : uint8_t {
    JPEG_PENDING = 0,    // need more bytes
    JPEG_OK,             // baseline (SOF0), the expected size, 1 or 3 components
    JPEG_NOT_JPEG,       // no SOI / broken marker
    JPEG_PROGRESSIVE,    // SOF2 (or any non-baseline SOF)
    JPEG_BAD_SIZE,       // baseline but not the expected size
    JPEG_TRUNCATED,      // stream ended before the SOF (finish())
};

class JpegSniffer {
public:
    // Expected size: a photo (kSide²) by default; the desktop wallpaper passes
    // Wallpaper::kW × kH.
    explicit JpegSniffer(uint16_t wantW = kSide, uint16_t wantH = kSide) : wantW_(wantW), wantH_(wantH) {}
    JpegVerdict verdict() const { return v_; }
    uint16_t width()  const { return w_; }
    uint16_t height() const { return h_; }

    JpegVerdict feed(const uint8_t* p, size_t n) {
        for (size_t i = 0; i < n && v_ == JPEG_PENDING; i++) step(p[i]);
        return v_;
    }
    // End of stream: still undecided → truncated.
    JpegVerdict finish() {
        if (v_ == JPEG_PENDING) v_ = JPEG_TRUNCATED;
        return v_;
    }

private:
    enum St : uint8_t { S_SOI0, S_SOI1, S_FF, S_MARK, S_LEN0, S_LEN1, S_SKIP, S_SOF };
    St st_ = S_SOI0;
    JpegVerdict v_ = JPEG_PENDING;
    uint8_t  mark_ = 0;
    uint16_t len_ = 0;      // segment length (incl. the 2 length bytes)
    uint16_t left_ = 0;     // bytes of the segment still to skip / read
    uint8_t  sof_[6] = {};  // precision, h hi, h lo, w hi, w lo, ncomp
    uint8_t  sofN_ = 0;
    uint16_t w_ = 0, h_ = 0;
    uint16_t wantW_, wantH_;

    static bool isSof(uint8_t m) {
        // C0..CF are SOFn except C4 (DHT), C8 (JPG), CC (DAC).
        return m >= 0xC0 && m <= 0xCF && m != 0xC4 && m != 0xC8 && m != 0xCC;
    }

    void step(uint8_t b) {
        switch (st_) {
            case S_SOI0: if (b != 0xFF) v_ = JPEG_NOT_JPEG; else st_ = S_SOI1; break;
            case S_SOI1: if (b != 0xD8) v_ = JPEG_NOT_JPEG; else st_ = S_FF; break;
            case S_FF:   if (b != 0xFF) v_ = JPEG_NOT_JPEG; else st_ = S_MARK; break;
            case S_MARK:
                if (b == 0xFF) break;                       // fill bytes
                if (b == 0xD8 || b == 0xD9 || b == 0xDA || b == 0x00) { v_ = JPEG_NOT_JPEG; break; }
                if (b >= 0xD0 && b <= 0xD7) { st_ = S_FF; break; }   // RSTn: no length
                mark_ = b;
                st_ = S_LEN0;
                break;
            case S_LEN0: len_ = (uint16_t)(b << 8); st_ = S_LEN1; break;
            case S_LEN1:
                len_ |= b;
                if (len_ < 2) { v_ = JPEG_NOT_JPEG; break; }
                left_ = (uint16_t)(len_ - 2);
                if (isSof(mark_)) {
                    if (mark_ != 0xC0) { v_ = JPEG_PROGRESSIVE; break; }
                    if (left_ < 6) { v_ = JPEG_NOT_JPEG; break; }
                    sofN_ = 0;
                    st_ = S_SOF;
                } else {
                    st_ = left_ ? S_SKIP : S_FF;
                }
                break;
            case S_SKIP: if (--left_ == 0) st_ = S_FF; break;
            case S_SOF:
                sof_[sofN_++] = b;
                if (sofN_ < 6) break;
                h_ = (uint16_t)(sof_[1] << 8 | sof_[2]);
                w_ = (uint16_t)(sof_[3] << 8 | sof_[4]);
                if (sof_[0] != 8 || (sof_[5] != 1 && sof_[5] != 3)) v_ = JPEG_NOT_JPEG;
                else if (w_ != wantW_ || h_ != wantH_) v_ = JPEG_BAD_SIZE;
                else v_ = JPEG_OK;
                break;
        }
    }
};

// Short machine code for API errors.
inline const char* verdictCode(JpegVerdict v) {
    switch (v) {
        case JPEG_OK:          return "ok";
        case JPEG_NOT_JPEG:    return "not_jpeg";
        case JPEG_PROGRESSIVE: return "progressive";
        case JPEG_BAD_SIZE:    return "bad_size";
        case JPEG_TRUNCATED:   return "truncated";
        default:               return "pending";
    }
}

// ── Names: "p<N>.jpg" (user) / "s<N>.jpg" (sample), N = 1..999999 ──────────

// N of a valid photo name with [prefix], 0 when [name] is not one (also
// guards DELETE against paths: no '/', no "..").
inline uint32_t idOf(const char* name, char prefix = kUserPrefix) {
    if (!name || name[0] != prefix) return 0;
    uint32_t n = 0;
    int digits = 0;
    const char* p = name + 1;
    while (*p >= '0' && *p <= '9') {
        if (++digits > 6) return 0;
        n = n * 10 + (uint32_t)(*p - '0');
        p++;
    }
    if (!digits || p[0] != '.' || strcmp(p, ".jpg")) return 0;
    if (name[1] == '0') return 0;                  // no leading zeros: one name per id
    return n;
}

inline void nameOf(uint32_t id, char* buf, size_t n, char prefix = kUserPrefix) {
    snprintf(buf, n, "%c%lu.jpg", prefix, (unsigned long)id);
}

// Insert [id] into the ascending list [ids] (size [n], capacity [cap]).
// Returns the new size; unchanged when full or a duplicate.
inline int insertId(uint32_t* ids, int n, uint32_t id, int cap = kMax) {
    if (n >= cap || !id) return n;
    int i = n;
    while (i > 0 && ids[i - 1] > id) i--;
    if (i > 0 && ids[i - 1] == id) return n;
    for (int k = n; k > i; k--) ids[k] = ids[k - 1];
    ids[i] = id;
    return n + 1;
}

inline int removeId(uint32_t* ids, int n, uint32_t id) {
    for (int i = 0; i < n; i++) {
        if (ids[i] != id) continue;
        for (int k = i; k + 1 < n; k++) ids[k] = ids[k + 1];
        return n - 1;
    }
    return n;
}

// Id for the next upload: one past the newest (ids ascending).
inline uint32_t nextId(const uint32_t* ids, int n) {
    uint32_t id = n ? ids[n - 1] + 1 : 1;
    return id > 999999UL ? 0 : id;
}

// Rotation: the photo after [cur] (-1 = none shown yet), wrapping.
inline int nextIndex(int cur, int n) {
    if (n <= 0) return -1;
    if (cur < 0 || cur >= n - 1) return 0;
    return cur + 1;
}

// Room for an upload: count below kMax, size within kMaxBytes, and the
// filesystem keeps kReserveBytes free after it (+ one block of slack,
// LittleFS allocates whole blocks).
enum Room : uint8_t { ROOM_OK, ROOM_FULL, ROOM_TOO_BIG, ROOM_NO_SPACE };
inline Room room(int count, uint32_t size, uint32_t fsFree, uint32_t blockSize) {
    if (count >= kMax) return ROOM_FULL;
    if (size > kMaxBytes) return ROOM_TOO_BIG;
    uint64_t need = (uint64_t)size + blockSize + kReserveBytes;
    if (need > fsFree) return ROOM_NO_SPACE;
    return ROOM_OK;
}

inline const char* roomCode(Room r) {
    switch (r) {
        case ROOM_FULL:     return "full";
        case ROOM_TOO_BIG:  return "too_big";
        case ROOM_NO_SPACE: return "no_space";
        default:            return "ok";
    }
}

}  // namespace Photos

// ── Desktop wallpaper (P-2026-11-26.12, token themeXP.desktop.wallpaper) ─────
// One baseline JPEG of exactly kW × kH at /wallpaper.jpg, drawn at (0, 0)
// behind the desktop icons. Same header check and free-space reserve as the
// photos (Photos::room with count 0).
namespace Wallpaper {
constexpr int      kW        = 240;
constexpr int      kH        = 214;               // y 0..213, above the taskbar
constexpr uint32_t kMaxBytes = Photos::kMaxBytes; // 40 KB
inline Photos::Room room(uint32_t size, uint32_t fsFree, uint32_t blockSize) {
    return Photos::room(0, size, fsFree, blockSize);
}
}  // namespace Wallpaper
