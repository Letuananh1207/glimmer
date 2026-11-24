#include "attention.h"
#include <Arduino.h>
#include <LittleFS.h>

namespace AttentionQueue {

static Attention::Queue s_q;
static uint32_t         s_rev = 1;
static bool             s_interrupt = false;

Attention::Queue& get() { return s_q; }
uint32_t revision()     { return s_rev; }

uint32_t now() {
    time_t t = time(nullptr);
    return t > 1000000000L ? (uint32_t)t : millis() / 1000;
}

int put(const Attention::Item& it, bool* fresh) {
    bool f = false;
    int i = Attention::upsert(s_q, it, now(), &f);
    if (i >= 0) {
        s_rev++;
        if (f && it.display == Attention::SHOW_INTERRUPT) s_interrupt = true;
    }
    if (fresh) *fresh = f;
    return i;
}

bool takeInterrupt() {
    bool v = s_interrupt;
    s_interrupt = false;
    return v;
}

bool clear(const char* id) {
    bool ok = Attention::clear(s_q, id);
    if (ok) s_rev++;
    return ok;
}

int clearAll() {
    int n = Attention::clearAll(s_q);
    if (n) s_rev++;
    return n;
}

int expire() {
    int n = Attention::expire(s_q, now());
    if (n) s_rev++;
    return n;
}

// ── project board, persisted to LittleFS ─────────────────────────────────────
//
// A reboot (OTA flash, power cut) used to wipe the board, so the Claude
// screen said "no project activity" until the next hook event. It is now
// saved — at most every 30 s, only after a change — and restored at boot.
// A filesystem flash still clears it (like /usage.bin).

static Projects::Board s_board;
static uint32_t        s_boardRev = 1;
static bool            s_boardDirty = false;
static uint32_t        s_boardSavedMs = 0;
static const char*     kBoardPath = "/projects.bin";
static constexpr uint32_t kBoardMagic = 0x474C5031;   // "GLP1"

const Projects::Board& projects() { return s_board; }
uint32_t projectsRevision()       { return s_boardRev; }

static void boardChanged() { s_boardRev++; s_boardDirty = true; }

void noteHook(Attention::Agent a, const Attention::HookEvent& e) {
    if (Projects::noteHook(s_board, a, e, now())) boardChanged();
}

void noteItem(const Attention::Item& it) {
    if (Projects::noteItem(s_board, it, now())) boardChanged();
}

int clearProjects() {
    int n = 0;
    for (const auto& x : s_board.e) if (x.used) n++;
    Projects::clearAll(s_board);
    boardChanged();
    return n;
}

void projectsBegin() {
    Projects::clearAll(s_board);
    File f = LittleFS.open(kBoardPath, "r");
    if (!f) return;
    uint32_t hdr[2] = {0, 0};
    bool ok = f.size() == sizeof(hdr) + sizeof(s_board)
           && f.read((uint8_t*)hdr, sizeof(hdr)) == sizeof(hdr)
           && hdr[0] == kBoardMagic && hdr[1] == sizeof(s_board)
           && f.read((uint8_t*)&s_board, sizeof(s_board)) == sizeof(s_board);
    f.close();
    if (!ok) { Projects::clearAll(s_board); return; }   // other layout: start empty
    s_boardRev++;
}

void projectsTick() {
    if (!s_boardDirty || millis() - s_boardSavedMs < 30000UL) return;
    s_boardSavedMs = millis();
    s_boardDirty = false;
    File f = LittleFS.open("/projects.tmp", "w");
    if (!f) return;
    const uint32_t hdr[2] = {kBoardMagic, (uint32_t)sizeof(s_board)};
    size_t n = f.write((const uint8_t*)hdr, sizeof(hdr));
    n += f.write((const uint8_t*)&s_board, sizeof(s_board));
    f.close();
    if (n != sizeof(hdr) + sizeof(s_board)) { LittleFS.remove("/projects.tmp"); return; }
    LittleFS.remove(kBoardPath);
    LittleFS.rename("/projects.tmp", kBoardPath);
}

}  // namespace AttentionQueue
