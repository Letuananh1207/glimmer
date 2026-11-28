#pragma once
// Thùng rác — XP's Recycle Bin for the photos (P-2026-11-28.32). Files in /trash/, the index in
// /trash/index.bin (ExplorerCore::Entry, newest last). RAM: the count only.
#include <stdint.h>
#include "explorer_core.h"

namespace Trash {

void begin();                          // LittleFS mounted: count the index (drop entries whose file is gone)
int  count();
uint32_t bytes();                      // total size of what is in it
bool at(int i, ExplorerCore::Entry& e);
// Photo [name] ("p3.jpg" / "s2.jpg") to the bin: Photos forgets it, its file moves to /trash/. false = no
// such photo / the bin is full / the file system refused.
bool moveIn(const char* name);
// Row [i] back to /photos/ (Photos takes it again). false = no such row.
bool restore(int i);
// Delete everything in the bin for good.
void empty();

}  // namespace Trash
