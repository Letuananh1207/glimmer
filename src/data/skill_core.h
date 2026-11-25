#pragma once
// Skills — feature packs, each one tab of the dock (app: docs/tasks/2026-11-25-thiet-ke-2026-11-25.3.md).
//
// Several skills are on at once (R-SK-1, design 2026-11-25.3); every channel of an enabled skill rotates,
// plus system channels (skill = nullptr: Attention, Night, Info). Each channel in kChannels[] carries the
// skill it belongs to. The enabled set is Settings::skillsOn, a comma-separated list kept in kAll order
// ("skills_on" in config.json, "skillsOn" array in /api/settings, "skills_on" in /api/state). Pure —
// host-tested.
#include <string.h>
#include <stddef.h>

namespace Skill {

// Every skill this firmware has channels for, in dock order. Add a pack: add its id here (and a dock
// tab), tag its channels in kChannels[].
static const char* const kAll[] = {"agent", "photo", "weather", "clock"};
static constexpr int kCount = sizeof(kAll) / sizeof(kAll[0]);
// Default = everything that rotated before skills were switchable (upgrade keeps the same screen);
// photo (P-2026-11-25.7) starts off — the user turns it on once photos are uploaded.
static constexpr const char* kDefaultOn = "agent,weather,clock";

inline bool known(const char* id) {
    if (!id) return false;
    for (int i = 0; i < kCount; i++)
        if (!strcmp(kAll[i], id)) return true;
    return false;
}

// [id] is one of the comma-separated tokens of [csv].
inline bool inList(const char* csv, const char* id) {
    if (!csv || !id || !*id) return false;
    size_t n = strlen(id);
    for (const char* p = csv; *p;) {
        const char* e = strchr(p, ',');
        size_t len = e ? (size_t)(e - p) : strlen(p);
        if (len == n && !strncmp(p, id, n)) return true;
        if (!e) break;
        p = e + 1;
    }
    return false;
}

// Canonical list from any input: known ids only, no duplicates, kAll order. Empty result →
// kDefaultOn when [emptyToDefault] (loading config), else "" (the caller rejects it: at least one).
inline void normalise(const char* in, char* out, size_t n, bool emptyToDefault) {
    if (!n) return;
    out[0] = 0;
    size_t used = 0;
    for (int i = 0; i < kCount; i++) {
        if (!inList(in, kAll[i])) continue;
        size_t l = strlen(kAll[i]) + (used ? 1 : 0);
        if (used + l + 1 > n) break;
        if (used) out[used++] = ',';
        strcpy(out + used, kAll[i]);
        used += strlen(kAll[i]);
    }
    if (!used && emptyToDefault) {
        strncpy(out, kDefaultOn, n - 1);
        out[n - 1] = 0;
    }
}

// The first enabled skill — the old single "skill" field, kept for apps before 2026-11-25.3.
inline const char* first(const char* csv) {
    for (int i = 0; i < kCount; i++)
        if (inList(csv, kAll[i])) return kAll[i];
    return kAll[0];
}

// R-SK-2: a channel rotates when it is a system channel or its skill is enabled.
inline bool shows(const char* channelSkill, const char* enabledCsv) {
    return channelSkill == nullptr || inList(enabledCsv, channelSkill);
}

}  // namespace Skill
