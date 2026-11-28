#pragma once
// Photos on LittleFS (/photos/p<N>.jpg) — storage, upload, JPEG decode to the
// panel. Pure rules (limits, header check, names, rotation) in photos_core.h.
//
// Heap: idle = the id list (8 × 4 B). Upload streams each HTTP chunk straight
// into the file. Decode (draw) mallocs the TJpgDec workspace (3.5 KB) + a
// LittleFS file handle for its duration and frees them before returning; it
// pushes each MCU block (≤ 16×16 px) to the TFT, no framebuffer. Runs inside
// a channel draw() in loop(), so never alongside a TLS fetch.
#include <Arduino.h>
#include "photos_core.h"
#include "photo_source_core.h"

namespace Photos {

void begin();                   // scan /photos/ (LittleFS already mounted)
// Indexed user photos first (0 .. count()-1, upload order), then the sample
// photos shipped in the filesystem image (count() .. total()-1). The upload
// limits apply to count() only.
int  count();                   // the user's photos (p<N>.jpg)
int  samples();                 // sample photos (s<N>.jpg)
int  total();                   // count() + samples()
bool isSample(int i);
const char* name(int i, char* buf, size_t n);   // "p3.jpg" / "s2.jpg"; "" when out of range
uint32_t size(int i);

// Free LittleFS bytes (total - used) and the block size.
uint32_t fsFree();
uint32_t fsTotal();

// Rotation cursor: advance to the next photo (wraps), return its index; -1 = none.
int  advance();
int  current();                 // last index returned by advance(); -1 = none

// Decode photo [i] to the panel with its top-left at (x, y). false when the
// file is missing, not a kSide² baseline JPEG, or the decoder failed (the
// area may hold a partial image — the caller clears it).
bool draw(int i, int x, int y);

// ── Upload (driven by the web server's multipart callbacks) ─────────────────
// start → write* → end (or abort). end() returns "" on success (the new name
// in [savedName]) or an error code: full / too_big / no_space / not_jpeg /
// progressive / bad_size / truncated / fs / empty / field.
void        uploadStart(const char* field);
void        uploadWrite(const uint8_t* p, size_t n);
const char* uploadEnd(char* savedName, size_t n);
void        uploadAbort();

// Delete a user (p<N>) or sample (s<N>) photo by name. false = no such photo.
bool remove(const char* name);

// ── Thùng rác (P-2026-11-28.32, trash.h) ──
// Drop [name] from the list, keep its file (the bin moves it). false = no such photo.
bool forget(const char* name);
// Take [name] back into the list (its file is in /photos/ again).
void adopt(const char* name);
// Explorer › open: the slideshow shows photo [i] next (Photo window), cache side.
void setCurrent(int i);
// Photo [i] at 1/4 (47 × 47) with its top-left at (x, y) — Ảnh của tôi's thumbnails.
bool drawThumb(int i, int x, int y);

// ── The app's library (photo_source_core.h; app plan 2026-11-27 kho ảnh trên app) ──
// The device points at the app's library: each slide it asks for the photo after the one on screen and keeps it
// in /photos/cur.jpg (one file, overwritten) so a repaint never asks again. The user photos above are the cache
// the app keeps (its 8 newest), shown while the app is away.
PhotoSource::Source& source();
enum Fetch : uint8_t { FETCH_OK, FETCH_EMPTY, FETCH_FAIL, FETCH_SKIP };
// Ask the app for the next photo (blocks ≤ ~kFetchTimeoutMs per step). OK = in cur.jpg, source() updated;
// EMPTY = 204; FAIL = app away / bad answer (source() marked, retried after kRetryMs); SKIP = no heap now.
Fetch fetchNext(uint32_t now);
// Decode the app's photo on screen (cur.jpg). false = none / unreadable.
bool drawCurrent(int x, int y);

}  // namespace Photos
