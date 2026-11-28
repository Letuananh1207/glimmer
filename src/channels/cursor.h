#pragma once
// Mouse cursor on the panel (R-DK-17; pure rules + glyphs in cursor_core.h).
//
// The app sends where the pointer is over UDP (CursorCore::kPort); this draws
// the glyph on top of whatever is on screen. No save-under (no MISO): moving
// it asks main.cpp to repaint the screen clipped to the old box, then draws
// the glyph at the new spot. Anything that paints the screen calls overlay()
// afterwards so the cursor stays on top.
//
// Heap: the UDP socket (~1 KB lwIP pcb + one pbuf while a packet waits); no
// pixel buffers.
#include <stdint.h>
#include "cursor_core.h"

namespace Cursor {

using Repaint = void (*)(int x, int y, int w, int h);

void begin();                    // listen on CursorCore::kPort (Wi-Fi up)
// Read waiting datagrams; true when the wanted position / shape changed.
bool poll(uint32_t now);
// Where the cursor may show: false (night face, system screen, screen off,
// powered off, setup AP) hides it — its box is repainted once.
void setAllowed(bool allowed, Repaint repaint);
// Move the drawn cursor to the wanted one (paced: kMinMoveMs): repaint the
// old box, draw at the new spot.
void step(uint32_t now, Repaint repaint);
// Draw the glyph where it is (after the screen under it was painted).
void overlay();
// The screen was painted whole (drawActive): the cursor is gone from it until
// overlay(); nothing to erase.
void screenRepainted();

// P-2026-11-27.24: a window just opened / loading (XP::waitCursor). In mouse
// mode the cursor turns into Working in Background where it is for a while
// (300 ms, each call extends it) and true comes back — the fixed wait cell is not
// drawn; otherwise false (the window draws its fixed cell, as before).
bool busy(uint32_t now);
// The app drives a visible cursor on a screen that may show it.
bool mouseMode();
// Where the cursor's hotspot is drawn (valid while shown()).
int  drawnX();
int  drawnY();

bool    seen();                  // a packet came since boot (the app drives a cursor)
uint8_t x();
uint8_t y();
uint8_t shape();                 // CursorCore::Shape wanted
bool    shown();                 // drawn on the panel now
uint16_t repaintMs();            // ms the last erase (clipped repaint) took
uint16_t repaintMax();           // the worst since boot

}  // namespace Cursor
