#include "photos.h"
#include <LittleFS.h>
#include "display.h"
#include "tjpgd.h"

namespace {

const char* const kDir = "/photos";
const char* const kTmp = "/photos/up.tmp";

uint32_t s_ids[Photos::kMax];
int      s_n   = 0;
int      s_cur = -1;

void pathOf(uint32_t id, char* buf, size_t n) {
    char nm[16];
    Photos::nameOf(id, nm, sizeof(nm));
    snprintf_P(buf, n, PSTR("/photos/%s"), nm);
}

// ── Upload state ──
File                 s_up;
Photos::JpegSniffer  s_sniff;
uint32_t             s_upBytes = 0;
uint32_t             s_upFree  = 0;     // FS free when the upload started
uint32_t             s_upBlock = 0;
const char*          s_upErr   = "field";   // first error; "" = fine so far (set by uploadStart)

// ── Decode ──
struct DecodeCtx { File* f; int x, y; };

size_t jdIn(JDEC* jd, uint8_t* buf, size_t len) {
    File* f = ((DecodeCtx*)jd->device)->f;
    if (!buf) return f->seek(len, SeekCur) ? len : 0;
    return f->read(buf, len);
}

int jdOut(JDEC* jd, void* bitmap, JRECT* r) {
    DecodeCtx* c = (DecodeCtx*)jd->device;
    tft.pushImage(c->x + r->left, c->y + r->top, r->right - r->left + 1, r->bottom - r->top + 1,
                  (uint16_t*)bitmap);
    return 1;
}

constexpr size_t kWork = TJPGD_WORKSPACE_SIZE;   // 3500 B (JD_FASTDECODE 1)

}  // namespace

namespace Photos {

void begin() {
    s_n = 0;
    s_cur = -1;
    LittleFS.mkdir(kDir);
    LittleFS.remove(kTmp);               // a reboot mid-upload
    Dir d = LittleFS.openDir(kDir);
    while (d.next()) {
        uint32_t id = idOf(d.fileName().c_str());
        if (id && d.fileSize() > 0) s_n = insertId(s_ids, s_n, id);
    }
    Serial.printf_P(PSTR("[photos] %d on fs, %u B free\n"), s_n, (unsigned)fsFree());
}

int count() { return s_n; }

const char* name(int i, char* buf, size_t n) {
    if (i < 0 || i >= s_n) { if (n) buf[0] = 0; return buf; }
    nameOf(s_ids[i], buf, n);
    return buf;
}

uint32_t size(int i) {
    if (i < 0 || i >= s_n) return 0;
    char p[32]; pathOf(s_ids[i], p, sizeof(p));
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

int advance() { return s_cur = nextIndex(s_cur, s_n); }
int current() { return s_cur < s_n ? s_cur : -1; }

bool draw(int i, int x, int y) {
    if (i < 0 || i >= s_n) return false;
    char p[32]; pathOf(s_ids[i], p, sizeof(p));
    // Workspace + file handle ≈ 3.7 KB. The VLW font (2-5 KB of glyph
    // metrics) is the only big thing we can drop to make room.
    if (ESP.getMaxFreeBlockSize() < kWork + 1024) Display::releaseFont();
    void* work = malloc(kWork);
    if (!work) { Serial.println(F("[photos] no heap for decoder")); return false; }
    File f = LittleFS.open(p, "r");
    bool ok = false;
    if (f) {
        DecodeCtx c{&f, x, y};
        JDEC jd;
        jd.swap = 0;                                   // jd_prepare keeps it
        JRESULT r = jd_prepare(&jd, jdIn, work, kWork, &c);
        if (r == JDR_OK && jd.width == kSide && jd.height == kSide) {
            bool sw = tft.getSwapBytes();
            tft.setSwapBytes(true);                    // decoder emits native-order RGB565
            r = jd_decomp(&jd, jdOut, 0);
            tft.setSwapBytes(sw);
            ok = r == JDR_OK;
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
    uint32_t id = idOf(nm);
    if (!id) return false;
    int before = s_n;
    s_n = removeId(s_ids, s_n, id);
    if (s_n == before) return false;
    char p[32]; pathOf(id, p, sizeof(p));
    LittleFS.remove(p);
    // Keep the cursor on the same next photo where possible.
    if (s_cur >= s_n) s_cur = s_n - 1;
    return true;
}

}  // namespace Photos
