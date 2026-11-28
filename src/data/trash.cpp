#include "trash.h"
#include <Arduino.h>
#include <LittleFS.h>
#include <time.h>
#include "photos.h"

using ExplorerCore::Entry;
using ExplorerCore::kTrashMax;

namespace {

const char* const kDir = "/trash";
const char* const kIndex = "/trash/index.bin";
int s_n = 0;

int readAll(Entry* out) {
    File f = LittleFS.open(kIndex, "r");
    if (!f) return 0;
    int n = 0;
    while (n < kTrashMax && f.read((uint8_t*)&out[n], sizeof(Entry)) == sizeof(Entry)) {
        out[n].name[sizeof(out[n].name) - 1] = 0;
        n++;
    }
    f.close();
    return n;
}

bool writeAll(const Entry* e, int n) {
    if (!n) { LittleFS.remove(kIndex); return true; }
    File f = LittleFS.open(kIndex, "w");
    if (!f) return false;
    const bool ok = f.write((const uint8_t*)e, sizeof(Entry) * n) == sizeof(Entry) * (size_t)n;
    f.close();
    return ok;
}

void pathIn(const char* name, char* out, size_t n) { snprintf_P(out, n, PSTR("/trash/%s"), name); }
void pathOut(const char* name, char* out, size_t n) { snprintf_P(out, n, PSTR("/photos/%s"), name); }

}  // namespace

namespace Trash {

void begin() {
    LittleFS.mkdir(kDir);
    // The index needs ~16 × 22 B on the stack while it is read; kept short-lived.
    Entry e[kTrashMax];
    const int n = readAll(e);
    int k = 0;
    char p[32];
    for (int i = 0; i < n; i++) {
        pathIn(e[i].name, p, sizeof(p));
        if (LittleFS.exists(p)) e[k++] = e[i];
    }
    if (k != n) writeAll(e, k);
    s_n = k;
}

int count() { return s_n; }

uint32_t bytes() {
    Entry e[kTrashMax];
    const int n = readAll(e);
    uint32_t b = 0;
    for (int i = 0; i < n; i++) b += e[i].size;
    return b;
}

bool at(int i, Entry& out) {
    if (i < 0 || i >= s_n) return false;
    File f = LittleFS.open(kIndex, "r");
    if (!f || !f.seek(sizeof(Entry) * i, SeekSet) || f.read((uint8_t*)&out, sizeof(Entry)) != sizeof(Entry)) {
        if (f) f.close();
        return false;
    }
    f.close();
    out.name[sizeof(out.name) - 1] = 0;
    return true;
}

bool moveIn(const char* name) {
    if (!name || !*name || strlen(name) >= sizeof(Entry::name)) return false;
    Entry e[kTrashMax];
    int n = readAll(e);
    if (n >= kTrashMax) return false;
    char from[32], to[32];
    pathOut(name, from, sizeof(from));
    pathIn(name, to, sizeof(to));
    File f = LittleFS.open(from, "r");
    if (!f) return false;
    const uint32_t size = f.size();
    f.close();
    if (!Photos::forget(name)) return false;
    LittleFS.remove(to);                                   // an older copy of the same name
    if (!LittleFS.rename(from, to)) { Photos::adopt(name); return false; }
    Entry& ne = e[n++];
    memset(&ne, 0, sizeof(ne));
    strncpy(ne.name, name, sizeof(ne.name) - 1);
    ne.size = size;
    const time_t now = time(nullptr);
    ne.at = now > 1000000000L ? (uint32_t)now : 0;
    writeAll(e, n);
    s_n = n;
    return true;
}

bool restore(int i) {
    Entry e[kTrashMax];
    int n = readAll(e);
    if (i < 0 || i >= n) return false;
    char from[32], to[32];
    pathIn(e[i].name, from, sizeof(from));
    pathOut(e[i].name, to, sizeof(to));
    if (LittleFS.exists(to) || !LittleFS.rename(from, to)) return false;
    Photos::adopt(e[i].name);
    for (int k = i; k + 1 < n; k++) e[k] = e[k + 1];
    n--;
    writeAll(e, n);
    s_n = n;
    return true;
}

void empty() {
    Entry e[kTrashMax];
    const int n = readAll(e);
    char p[32];
    for (int i = 0; i < n; i++) {
        pathIn(e[i].name, p, sizeof(p));
        LittleFS.remove(p);
    }
    writeAll(e, 0);
    s_n = 0;
}

}  // namespace Trash
