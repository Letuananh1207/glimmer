#include "photos.h"
#include <LittleFS.h>
#include "display.h"
#include "tjpgd.h"

namespace {

const char* const kDir = "/photos";
const char* const kTmp = "/photos/up.tmp";

uint32_t s_ids[Photos::kMax];            // user photos p<N>, ascending
int      s_n   = 0;
uint32_t s_sam[Photos::kMaxSamples];     // sample photos s<N>, ascending
int      s_ns  = 0;
int      s_cur = -1;                     // index over user photos, then samples

void pathOf(uint32_t id, char* buf, size_t n, char prefix = Photos::kUserPrefix) {
    char nm[16];
    Photos::nameOf(id, nm, sizeof(nm), prefix);
    snprintf_P(buf, n, PSTR("/photos/%s"), nm);
}

// Path of photo [i] of the combined list; false when out of range.
bool pathAt(int i, char* buf, size_t n) {
    if (i < 0 || i >= s_n + s_ns) return false;
    if (i < s_n) pathOf(s_ids[i], buf, n);
    else         pathOf(s_sam[i - s_n], buf, n, Photos::kSamplePrefix);
    return true;
}

// ── Upload state ──
File                 s_up;
Photos::JpegSniffer  s_sniff;
uint32_t             s_upBytes = 0;
uint32_t             s_upFree  = 0;     // FS free when the upload started
uint32_t             s_upBlock = 0;
const char*          s_upErr   = "field";   // first error; "" = fine so far (set by uploadStart)

// ── Decode ──
struct DecodeCtx { File* f; int x, y; int stopY; bool stopped; };   // stopY: clipped repaint's bottom

size_t jdIn(JDEC* jd, uint8_t* buf, size_t len) {
    File* f = ((DecodeCtx*)jd->device)->f;
    if (!buf) return f->seek(len, SeekCur) ? len : 0;
    return f->read(buf, len);
}

int jdOut(JDEC* jd, void* bitmap, JRECT* r) {
    DecodeCtx* c = (DecodeCtx*)jd->device;
    if (c->y + r->top > c->stopY) { c->stopped = true; return 0; }   // below the clip: done
    Display::pushImage(c->x + r->left, c->y + r->top, r->right - r->left + 1, r->bottom - r->top + 1,
                       (uint16_t*)bitmap);
    return 1;
}

constexpr size_t kWork = TJPGD_WORKSPACE_SIZE;   // 3500 B (JD_FASTDECODE 1)

}  // namespace

namespace Photos {

void begin() {
    s_n = 0;
    s_ns = 0;
    s_cur = -1;
    LittleFS.mkdir(kDir);
    LittleFS.remove(kTmp);               // a reboot mid-upload
    Dir d = LittleFS.openDir(kDir);
    while (d.next()) {
        if (d.fileSize() == 0) continue;
        const String nm = d.fileName();
        if (uint32_t id = idOf(nm.c_str())) s_n = insertId(s_ids, s_n, id);
        else if ((id = idOf(nm.c_str(), kSamplePrefix))) s_ns = insertId(s_sam, s_ns, id, kMaxSamples);
    }
    Serial.printf_P(PSTR("[photos] %d + %d samples on fs, %u B free\n"), s_n, s_ns, (unsigned)fsFree());
}

int  count()   { return s_n; }
int  samples() { return s_ns; }
int  total()   { return s_n + s_ns; }
bool isSample(int i) { return i >= s_n && i < s_n + s_ns; }

const char* name(int i, char* buf, size_t n) {
    if (i < 0 || i >= s_n + s_ns) { if (n) buf[0] = 0; return buf; }
    if (i < s_n) nameOf(s_ids[i], buf, n);
    else         nameOf(s_sam[i - s_n], buf, n, kSamplePrefix);
    return buf;
}

uint32_t size(int i) {
    char p[32];
    if (!pathAt(i, p, sizeof(p))) return 0;
    File f = LittleFS.open(p, "r");
    uint32_t sz = f ? f.size() : 0;
    f.close();
    return sz;
}

uint32_t fsFree() {
    FSInfo fi;
    if (!LittleFS.info(fi)) return 0;
    return fi.totalBytes > fi.usedBytes ? fi.totalBytes - fi.usedBytes : 0;
}

uint32_t fsTotal() {
    FSInfo fi;
    return LittleFS.info(fi) ? fi.totalBytes : 0;
}

int advance() { return s_cur = nextIndex(s_cur, s_n + s_ns); }
int current() { return s_cur < s_n + s_ns ? s_cur : -1; }

bool draw(int i, int x, int y) {
    char p[32];
    if (!pathAt(i, p, sizeof(p))) return false;
    // Workspace + file handle ≈ 3.7 KB. The VLW font (2-5 KB of glyph
    // metrics) is the only big thing we can drop to make room.
    if (ESP.getMaxFreeBlockSize() < kWork + 1024) Display::releaseFont();
    void* work = malloc(kWork);
    if (!work) { Serial.println(F("[photos] no heap for decoder")); return false; }
    File f = LittleFS.open(p, "r");
    bool ok = false;
    if (f) {
        // A clipped repaint (cursor moving) stops decoding below the clip.
        int cx, cy, cw, ch;
        Display::clipRect(cx, cy, cw, ch);
        DecodeCtx c{&f, x, y, Display::repainting() ? cy + ch - 1 : 0x7FFF, false};
        JDEC jd;
        jd.swap = 0;                                   // jd_prepare keeps it
        JRESULT r = jd_prepare(&jd, jdIn, work, kWork, &c);
        if (r == JDR_OK && jd.width == kSide && jd.height == kSide) {
            bool sw = tft.getSwapBytes();
            tft.setSwapBytes(true);                    // decoder emits native-order RGB565
            r = jd_decomp(&jd, jdOut, 0);
            tft.setSwapBytes(sw);
            ok = r == JDR_OK || (r == JDR_INTR && c.stopped);
        }
        if (!ok) Serial.printf_P(PSTR("[photos] %s: decode failed (%d, %ux%u)\n"), p, (int)r,
                                 jd.width, jd.height);
        f.close();
    }
    free(work);
    return ok;
}

// ── Upload ──────────────────────────────────────────────────────────────────

void uploadStart(const char* field) {
    if (s_up) s_up.close();
    s_sniff = JpegSniffer();
    s_upBytes = 0;
    s_upErr = "";
    if (!field || strcmp(field, "photo")) { s_upErr = "field"; return; }
    FSInfo fi;
    if (!LittleFS.info(fi)) { s_upErr = "fs"; return; }
    s_upFree  = fi.totalBytes > fi.usedBytes ? fi.totalBytes - fi.usedBytes : 0;
    s_upBlock = fi.blockSize;
    Room rm = room(s_n, 0, s_upFree, s_upBlock);
    if (rm != ROOM_OK) { s_upErr = roomCode(rm); return; }
    LittleFS.mkdir(kDir);
    s_up = LittleFS.open(kTmp, "w");
    if (!s_up) s_upErr = "fs";
}

void uploadWrite(const uint8_t* p, size_t n) {
    if (*s_upErr || !s_up) return;
    Room rm = room(s_n, s_upBytes + n, s_upFree, s_upBlock);
    if (rm != ROOM_OK) { s_upErr = roomCode(rm); return; }
    JpegVerdict v = s_sniff.feed(p, n);
    if (v != JPEG_PENDING && v != JPEG_OK) { s_upErr = verdictCode(v); return; }
    if (s_up.write(p, n) != n) { s_upErr = "fs"; return; }
    s_upBytes += n;
}

void uploadAbort() {
    if (s_up) s_up.close();
    LittleFS.remove(kTmp);
    if (!*s_upErr) s_upErr = "aborted";
}

const char* uploadEnd(char* savedName, size_t n) {
    if (n) savedName[0] = 0;
    if (s_up) s_up.close();
    if (!*s_upErr && !s_upBytes) s_upErr = "empty";
    if (!*s_upErr) {
        JpegVerdict v = s_sniff.finish();
        if (v != JPEG_OK) s_upErr = verdictCode(v);
    }
    uint32_t id = nextId(s_ids, s_n);
    if (!*s_upErr && !id) s_upErr = "full";
    if (!*s_upErr) {
        char p[32]; pathOf(id, p, sizeof(p));
        if (!LittleFS.rename(kTmp, p)) s_upErr = "fs";
        else {
            s_n = insertId(s_ids, s_n, id);
            nameOf(id, savedName, n);
            Serial.printf_P(PSTR("[photos] saved %s (%u B)\n"), p, (unsigned)s_upBytes);
        }
    }
    if (*s_upErr) LittleFS.remove(kTmp);
    const char* e = s_upErr;
    s_upErr = "field";          // a POST with no file part next time
    s_upBytes = 0;
    return e;
}

bool remove(const char* nm) {
    char p[32];
    if (uint32_t id = idOf(nm)) {
        int before = s_n;
        s_n = removeId(s_ids, s_n, id);
        if (s_n == before) return false;
        pathOf(id, p, sizeof(p));
    } else if ((id = idOf(nm, kSamplePrefix))) {
        int before = s_ns;
        s_ns = removeId(s_sam, s_ns, id);
        if (s_ns == before) return false;
        pathOf(id, p, sizeof(p), kSamplePrefix);
    } else {
        return false;
    }
    LittleFS.remove(p);
    // Keep the cursor on the same next photo where possible.
    if (s_cur >= s_n + s_ns) s_cur = s_n + s_ns - 1;
    return true;
}

}  // namespace Photos
