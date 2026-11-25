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

namespace Photos {

void begin();                   // scan /photos/ (LittleFS already mounted)
int  count();
const char* name(int i, char* buf, size_t n);   // "p3.jpg"; "" when out of range
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

// Delete by name (validated with idOf). false = no such photo.
bool remove(const char* name);

}  // namespace Photos
