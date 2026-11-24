#pragma once
// Device-side owner of the attention queue (see attention_core.h for rules).
#include "attention_core.h"
#include "projects_core.h"

namespace AttentionQueue {
    Attention::Queue& get();

    // Epoch seconds once the clock is synced; uptime seconds before that, so
    // expiries still work on a device that hasn't reached NTP yet.
    uint32_t now();

    // Insert/update; returns the slot (-1 = rejected, queue full of more
    // important items). Bumps the revision so screens repaint.
    int  put(const Attention::Item& it, bool* fresh = nullptr);
    bool clear(const char* id);
    int  clearAll();

    // Drop expired items (call ~1 Hz). Returns how many went.
    int  expire();

    // Changes whenever the queue changes — channels repaint when it moves.
    uint32_t revision();

    // True once after a put() that should take the screen (a new interrupt
    // card, or one that became more urgent). Main loop consumes it.
    bool takeInterrupt();

    // Project board (latest state per project; see projects_core.h). Fed by
    // the same hook events and pushed cards; projectsRevision() moves when
    // anything on it changes.
    const Projects::Board& projects();
    void noteHook(Attention::Agent a, const Attention::HookEvent& e);
    void noteItem(const Attention::Item& it);
    uint32_t projectsRevision();
}
