#include "jpeg_thumb.h"
#include <Arduino.h>
#include <LittleFS.h>
#include "display.h"
#include "tjpgd.h"

namespace {

struct Ctx { File* f; int x, y, x1, y1; bool stopped; };   // screen box (inclusive)

size_t in(JDEC* jd, uint8_t* buf, size_t len) {
    File* f = ((Ctx*)jd->device)->f;
    if (!buf) return f->seek(len, SeekCur) ? len : 0;
    return f->read(buf, len);
}

int out(JDEC* jd, void* bitmap, JRECT* r) {
    Ctx* c = (Ctx*)jd->device;
    const int top = c->y + r->top;
    if (top > c->y1) { c->stopped = true; return 0; }        // below the box: done
    const uint16_t* px = (const uint16_t*)bitmap;
    const int bw = r->right - r->left + 1;
    const int sx = c->x + r->left, sx1 = c->x + r->right, sy1 = c->y + r->bottom;
    const int x0 = sx > c->x ? sx : c->x, x1 = sx1 < c->x1 ? sx1 : c->x1;
    const int y1 = sy1 < c->y1 ? sy1 : c->y1;
    if (x0 > x1) return 1;
    for (int y = top; y <= y1; y++)
        Display::pushImage(x0, y, x1 - x0 + 1, 1, (uint16_t*)(px + (y - top) * bw + (x0 - sx)));
    return 1;
}

}  // namespace

namespace JpegThumb {

bool draw(const char* path, int expectW, int expectH, uint8_t scale, int x, int y, int w, int h) {
    if (!Display::clipHits(x, y, w, h)) return true;
    constexpr size_t kWork = TJPGD_WORKSPACE_SIZE;
    if (ESP.getMaxFreeBlockSize() < kWork + 1024) Display::releaseFont();
    void* work = malloc(kWork);
    if (!work) return false;
    File f = LittleFS.open(path, "r");
    bool ok = false;
    if (f) {
        int cx, cy, cw, ch;
        Display::clipRect(cx, cy, cw, ch);
        const int bottom = y + h - 1, clipBottom = cy + ch - 1;
        Ctx c{&f, x, y, x + w - 1, bottom < clipBottom ? bottom : clipBottom, false};
        JDEC jd;
        jd.swap = 0;
        JRESULT r = jd_prepare(&jd, in, work, kWork, &c);
        if (r == JDR_OK && jd.width == expectW && jd.height == expectH) {
            const bool sw = tft.getSwapBytes();
            tft.setSwapBytes(true);                  // the decoder emits native-order RGB565
            r = jd_decomp(&jd, out, scale);
            tft.setSwapBytes(sw);
            ok = r == JDR_OK || (r == JDR_INTR && c.stopped);
        }
        f.close();
    }
    free(work);
    return ok;
}

}  // namespace JpegThumb
