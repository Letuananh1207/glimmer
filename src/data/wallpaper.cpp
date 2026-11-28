#include "wallpaper.h"
#include <LittleFS.h>
#include "display.h"
#include "tjpgd.h"
#include "desk_wallpaper.h"
#include "jpeg_thumb.h"

namespace {

const char* const kPath = "/wallpaper.jpg";
const char* const kTmp  = "/wallpaper.tmp";

bool s_set    = false;    // file present
bool s_broken = false;    // present but failed to decode (until the next upload / delete)
uint8_t s_mode = 2;       // Wallpaper::Mode (setting wallpaperMode)

// ── Upload state ──
File                 s_up;
Photos::JpegSniffer  s_sniff(Wallpaper::kW, Wallpaper::kH);
uint32_t             s_upBytes = 0;
uint32_t             s_upFree  = 0;
uint32_t             s_upBlock = 0;
const char*          s_upErr   = "field";

// ── Clipping ──
struct Rect { int x0, y0, x1, y1; };    // inclusive
inline int imax(int a, int b) { return a > b ? a : b; }
inline int imin(int a, int b) { return a < b ? a : b; }

// Copy the part of block (bx, by, bw, bh) — pixels px — that falls inside
// each capture.
void capture(const uint16_t* px, int bx, int by, int bw, int bh, Wallpaper::Cap* caps, int n) {
    for (int i = 0; i < n; i++) {
        Wallpaper::Cap& c = caps[i];
        if (!c.buf) continue;
        const int x0 = imax(bx, c.x), x1 = imin(bx + bw - 1, c.x + c.w - 1);
        const int y0 = imax(by, c.y), y1 = imin(by + bh - 1, c.y + c.h - 1);
        if (x0 > x1 || y0 > y1) continue;
        for (int y = y0; y <= y1; y++)
            memcpy(c.buf + (y - c.y) * c.w + (x0 - c.x), px + (y - by) * bw + (x0 - bx),
                   (size_t)(x1 - x0 + 1) * 2);
    }
}

// ── JPEG decode ──
struct DecodeCtx { File* f; Rect clip; Wallpaper::Cap* caps; int n; bool stopped; };

size_t jdIn(JDEC* jd, uint8_t* buf, size_t len) {
    File* f = ((DecodeCtx*)jd->device)->f;
    if (!buf) return f->seek(len, SeekCur) ? len : 0;
    return f->read(buf, len);
}

int jdOut(JDEC* jd, void* bitmap, JRECT* r) {
    DecodeCtx* c = (DecodeCtx*)jd->device;
    if (r->top > c->clip.y1) { c->stopped = true; return 0; }   // below the area: done
    const uint16_t* px = (const uint16_t*)bitmap;
    const int bw = r->right - r->left + 1, bh = r->bottom - r->top + 1;
    capture(px, r->left, r->top, bw, bh, c->caps, c->n);
    const int x0 = imax(r->left, c->clip.x0), x1 = imin(r->right, c->clip.x1);
    const int y0 = imax(r->top, c->clip.y0), y1 = imin(r->bottom, c->clip.y1);
    if (x0 > x1 || y0 > y1) return 1;
    if (x0 == r->left && x1 == r->right && y0 == r->top && y1 == r->bottom) {
        Display::pushImage(r->left, r->top, bw, bh, (uint16_t*)px);
    } else {
        // Only the inside: a block straddling the edge must not paint over
        // the icons / balloon next to the rectangle.
        for (int y = y0; y <= y1; y++)
            Display::pushImage(x0, y, x1 - x0 + 1, 1, (uint16_t*)(px + (y - r->top) * bw + (x0 - r->left)));
    }
    return 1;
}

constexpr size_t kWork = TJPGD_WORKSPACE_SIZE;   // 3500 B (JD_FASTDECODE 1)

bool paintJpeg(const Rect& clip, Wallpaper::Cap* caps, int n) {
    // The VLW font's glyph metrics are the only big thing we can drop.
    if (ESP.getMaxFreeBlockSize() < kWork + 1024) Display::releaseFont();
    void* work = malloc(kWork);
    if (!work) { Serial.println(F("[wallpaper] no heap for decoder")); return false; }
    File f = LittleFS.open(kPath, "r");
    bool ok = false;
    if (f) {
        DecodeCtx c{&f, clip, caps, n, false};
        JDEC jd;
        jd.swap = 0;
        JRESULT r = jd_prepare(&jd, jdIn, work, kWork, &c);
        if (r == JDR_OK && jd.width == Wallpaper::kW && jd.height == Wallpaper::kH) {
            bool sw = tft.getSwapBytes();
            tft.setSwapBytes(true);                    // decoder emits native-order RGB565
            r = jd_decomp(&jd, jdOut, 0);
            tft.setSwapBytes(sw);
            ok = r == JDR_OK || (r == JDR_INTR && c.stopped);
        }
        if (!ok) {
            Serial.printf_P(PSTR("[wallpaper] decode failed (%d, %ux%u)\n"), (int)r, jd.width, jd.height);
            s_broken = true;                           // fallback from now on
        }
        f.close();
    }
    free(work);
    return ok;
}

// ── One colour (Màn nền › (Không)) ──
void paintSolid(const Rect& clip, Wallpaper::Cap* caps, int n) {
    tft.fillRect(clip.x0, clip.y0, clip.x1 - clip.x0 + 1, clip.y1 - clip.y0 + 1, Wallpaper::kNoneColor);
    for (int k = 0; k < n; k++)
        if (caps[k].buf)
            for (int i = 0; i < caps[k].w * caps[k].h; i++) caps[k].buf[i] = Wallpaper::kNoneColor;
}

// ── Fallback (design pixel wallpaper) ──

void paintFallback(const Rect& clip, Wallpaper::Cap* caps, int n) {
    int i = 0;                                      // run index
    for (int y = 0; y <= clip.y1; y++) {
        int x = 0;
        while (x < Desk::kDeskW) {
            const uint8_t ci  = pgm_read_byte(&Desk::kDeskRuns[2 * i]);
            const uint8_t len = pgm_read_byte(&Desk::kDeskRuns[2 * i + 1]);
            i++;
            if (y >= clip.y0) {
                const int a = imax(x, clip.x0), b = imin(x + len - 1, clip.x1);
                const uint16_t col = pgm_read_word(&Desk::kDeskPal[ci]);
                if (a <= b) tft.drawFastHLine(a, y, b - a + 1, col);
                for (int k = 0; k < n; k++) {
                    Wallpaper::Cap& c = caps[k];
                    if (!c.buf || y < c.y || y >= c.y + c.h) continue;
                    const int ca = imax(x, c.x), cb = imin(x + len - 1, c.x + c.w - 1);
                    for (int px = ca; px <= cb; px++) c.buf[(y - c.y) * c.w + (px - c.x)] = col;
                }
            }
            x += len;
        }
    }
}

}  // namespace

namespace Wallpaper {

void begin() {
    LittleFS.remove(kTmp);                   // a reboot mid-upload
    File f = LittleFS.open(kPath, "r");
    s_set = f && f.size() > 0;
    if (f) f.close();
    s_broken = false;
    Serial.printf_P(PSTR("[wallpaper] %s\n"), s_set ? "set" : "none (fallback)");
}

bool present() { return s_set && !s_broken; }

void setMode(uint8_t m) { s_mode = m > MODE_PHOTO ? MODE_PHOTO : m; }
uint8_t mode() { return s_mode; }

void thumb(uint8_t m, int x, int y, int w, int h) {
    if (!Display::clipHits(x, y, w, h)) return;
    if (m == MODE_NONE) { tft.fillRect(x, y, w, h, kNoneColor); return; }
    if (m == MODE_PHOTO && present() && JpegThumb::draw(kPath, kW, kH, 2, x, y, w, h)) return;
    // Fallback: every 4th pixel of every 4th row of the runs.
    int i = 0;
    for (int yy = 0; yy < Desk::kDeskH && yy / 4 < h; yy++) {
        int xx = 0;
        while (xx < Desk::kDeskW) {
            const uint8_t ci  = pgm_read_byte(&Desk::kDeskRuns[2 * i]);
            const uint8_t len = pgm_read_byte(&Desk::kDeskRuns[2 * i + 1]);
            i++;
            if (yy % 4 == 0) {
                const int a = (xx + 3) / 4, b = (xx + len - 1) / 4;   // the 4th pixels inside the run
                const int bb = b < w - 1 ? b : w - 1;
                if (a <= bb) tft.drawFastHLine(x + a, y + yy / 4, bb - a + 1, pgm_read_word(&Desk::kDeskPal[ci]));
            }
            xx += len;
        }
    }
}

uint32_t size() {
    if (!s_set) return 0;
    File f = LittleFS.open(kPath, "r");
    uint32_t sz = f ? f.size() : 0;
    if (f) f.close();
    return sz;
}

uint16_t fallbackAt(int x, int y) {
    if (x < 0 || y < 0 || x >= Desk::kDeskW || y >= Desk::kDeskH) return 0;
    int i = 0;
    for (int yy = 0; yy < y; yy++)
        for (int xx = 0; xx < Desk::kDeskW; i++) xx += pgm_read_byte(&Desk::kDeskRuns[2 * i + 1]);
    for (int xx = 0;; i++) {
        xx += pgm_read_byte(&Desk::kDeskRuns[2 * i + 1]);
        if (x < xx) return pgm_read_word(&Desk::kDeskPal[pgm_read_byte(&Desk::kDeskRuns[2 * i])]);
    }
}

void paint(int x, int y, int w, int h, Cap* caps, int nCaps) {
    Rect clip{imax(x, 0), imax(y, 0), imin(x + w - 1, kW - 1), imin(y + h - 1, kH - 1)};
    if (clip.x0 > clip.x1 || clip.y0 > clip.y1) return;
    if (s_mode == MODE_NONE) { paintSolid(clip, caps, nCaps); return; }
    if (s_mode == MODE_PHOTO && present() && paintJpeg(clip, caps, nCaps)) return;
    paintFallback(clip, caps, nCaps);          // none, or the decode failed half-way
}

// ── Upload ──────────────────────────────────────────────────────────────────

void uploadStart(const char* field) {
    if (s_up) s_up.close();
    s_sniff = Photos::JpegSniffer(kW, kH);
    s_upBytes = 0;
    s_upErr = "";
    if (!field || strcmp(field, "wallpaper")) { s_upErr = "field"; return; }
    FSInfo fi;
    if (!LittleFS.info(fi)) { s_upErr = "fs"; return; }
    s_upFree  = fi.totalBytes > fi.usedBytes ? fi.totalBytes - fi.usedBytes : 0;
    s_upBlock = fi.blockSize;
    Photos::Room rm = room(0, s_upFree, s_upBlock);
    if (rm != Photos::ROOM_OK) { s_upErr = Photos::roomCode(rm); return; }
    s_up = LittleFS.open(kTmp, "w");
    if (!s_up) s_upErr = "fs";
}

void uploadWrite(const uint8_t* p, size_t n) {
    if (*s_upErr || !s_up) return;
    Photos::Room rm = room(s_upBytes + n, s_upFree, s_upBlock);
    if (rm != Photos::ROOM_OK) { s_upErr = Photos::roomCode(rm); return; }
    Photos::JpegVerdict v = s_sniff.feed(p, n);
    if (v != Photos::JPEG_PENDING && v != Photos::JPEG_OK) { s_upErr = Photos::verdictCode(v); return; }
    if (s_up.write(p, n) != n) { s_upErr = "fs"; return; }
    s_upBytes += n;
}

void uploadAbort() {
    if (s_up) s_up.close();
    LittleFS.remove(kTmp);
    if (!*s_upErr) s_upErr = "aborted";
}

const char* uploadEnd() {
    if (s_up) s_up.close();
    if (!*s_upErr && !s_upBytes) s_upErr = "empty";
    if (!*s_upErr) {
        Photos::JpegVerdict v = s_sniff.finish();
        if (v != Photos::JPEG_OK) s_upErr = Photos::verdictCode(v);
    }
    if (!*s_upErr) {
        LittleFS.remove(kPath);                // rename does not overwrite on LittleFS
        if (!LittleFS.rename(kTmp, kPath)) s_upErr = "fs";
        else {
            s_set = true;
            s_broken = false;
            Serial.printf_P(PSTR("[wallpaper] saved (%u B)\n"), (unsigned)s_upBytes);
        }
    }
    if (*s_upErr) {
        LittleFS.remove(kTmp);
        if (!strcmp(s_upErr, "fs")) s_set = LittleFS.exists(kPath);
    }
    const char* e = s_upErr;
    s_upErr = "field";
    s_upBytes = 0;
    return e;
}

bool remove() {
    const bool had = s_set || LittleFS.exists(kPath);
    LittleFS.remove(kPath);
    s_set = false;
    s_broken = false;
    return had;
}

}  // namespace Wallpaper
