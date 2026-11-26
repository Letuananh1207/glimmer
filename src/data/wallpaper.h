#pragma once
// Desktop wallpaper (P-2026-11-26.12): /wallpaper.jpg on LittleFS — storage,
// upload, and painting any rectangle of it to the panel. Limits and the
// header check in photos_core.h (Wallpaper::kW × kH, JpegSniffer).
//
// No file, or a file that fails to decode → the fallback pixel wallpaper of
// the design (src/ui/desk_wallpaper.h, PROGMEM runs). A broken file is
// remembered until the next upload / delete so it is not decoded again.
//
// Heap: like Photos::draw — paint() mallocs the TJpgDec workspace (3.5 KB)
// + a file handle and frees them before returning; MCU blocks go straight to
// the TFT (only the part inside the asked rectangle), no framebuffer.
#include <Arduino.h>
#include "photos_core.h"

namespace Wallpaper {

void begin();                 // LittleFS mounted; drop a stale upload, look for the file
bool present();               // a usable JPEG is set (not missing, not known broken)
uint32_t size();              // bytes of /wallpaper.jpg, 0 when none

// A capture: while painting, the wallpaper pixels of (x, y, w, h) are also
// copied into buf (w × h RGB565, native order — what a getColor callback
// returns). buf == nullptr = skip. Must lie inside the painted rectangle.
struct Cap { int16_t x, y, w, h; uint16_t* buf; };

// Paint the wallpaper's (x, y, w, h) — screen coordinates, clipped to
// 240×214 — from the JPEG, or from the fallback when there is none / it is
// broken. Fills the captures on the way. A decode that stops on the bottom
// edge of the rectangle aborts early (cheap for bands near the top).
void paint(int x, int y, int w, int h, Cap* caps = nullptr, int nCaps = 0);

// Colour of the fallback wallpaper at (x, y) (screen = wallpaper coords).
uint16_t fallbackAt(int x, int y);

// ── Upload: start → write* → end (or abort), driven by the multipart
// callbacks of POST /api/wallpaper (field "wallpaper"). end() returns "" on
// success or an error code: too_big / no_space / not_jpeg / progressive /
// bad_size / truncated / fs / empty / field.
void        uploadStart(const char* field);
void        uploadWrite(const uint8_t* p, size_t n);
const char* uploadEnd();
void        uploadAbort();

// Delete the wallpaper; false when none was set.
bool remove();

}  // namespace Wallpaper
