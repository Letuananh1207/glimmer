#pragma once
// Skills — one feature pack owns the screen at a time (app: docs/tasks/2026-11-25-he-sinh-thai-skill.md).
//
// Each channel in kChannels[] carries the skill it belongs to; nullptr = a system channel (attention,
// night, clock, weather, info) shown under every skill. The active skill is Settings::skill ("skill"
// in /api/settings, /api/state). Pure — host-tested.
#include <string.h>

namespace Skill {

// Every skill this firmware has channels for, in the order the app lists them. Add a pack: add its id
// here and tag its channels in kChannels[].
static const char* const kAll[] = {"agent"};
static constexpr int kCount = sizeof(kAll) / sizeof(kAll[0]);
static constexpr const char* kDefault = "agent";

inline bool known(const char* id) {
    if (!id) return false;
    for (int i = 0; i < kCount; i++)
        if (!strcmp(kAll[i], id)) return true;
    return false;
}

// The skill to run: [stored] when this firmware knows it, else the default (R-SK-1).
inline const char* active(const char* stored) { return known(stored) ? stored : kDefault; }

// R-SK-2: a channel rotates under [activeSkill] when it is a system channel or belongs to that skill.
inline bool shows(const char* channelSkill, const char* activeSkill) {
    return channelSkill == nullptr || (activeSkill && !strcmp(channelSkill, activeSkill));
}

}  // namespace Skill
