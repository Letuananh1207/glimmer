#pragma once
// A JPEG on LittleFS drawn smaller (P-2026-11-28.30 Display preview, .32 Explorer thumbnails): TJpgDec's own
// 1/2^scale output (scale 2 = 1/4 — no resampling of ours), clipped to (x, y, w, h) on screen. Same heap
// rules as Photos::draw: a 3.5 KB workspace malloc'd and freed, the VLW font released first if the largest
// block is short; MCU blocks pushed straight to the panel (or the repaint sprite), no framebuffer.
#include <stdint.h>

namespace JpegThumb {
// [path] must be a baseline JPEG of exactly expectW × expectH (else false, nothing drawn). Rows below the
// clip of a repaint under the cursor are not decoded.
bool draw(const char* path, int expectW, int expectH, uint8_t scale, int x, int y, int w, int h);
}
