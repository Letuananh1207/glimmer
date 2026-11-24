#pragma once
// Project board — the latest state of each project an agent works in, for the
// Claude screen's bottom rows ("glimmer  Cần duyệt · Bash   2M").
//
// The attention queue answers "what needs me NOW" and forgets a finished
// task after 20 s; this answers "how are my projects doing", so DONE stays
// visible for hours. Fed by the same hook events (and by pushed cards that
// name a project). Pure C++ — host-testable.
#include <stdint.h>
#include <string.h>
#include "attention_core.h"

namespace Projects {

enum State : uint8_t { P_APPROVAL, P_INPUT, P_ERROR, P_WORKING, P_DONE };  // display priority

constexpr int      kMax       = 4;
constexpr uint32_t kKeepS     = 6 * 3600;   // DONE / ERROR stay this long
constexpr uint32_t kIdleS     = 30 * 60;    // WORKING with no event this long → hidden

struct Entry {
    bool             used = false;
    char             project[24] = "";
    Attention::Agent agent = Attention::AGENT_OTHER;
    State            state = P_WORKING;
    char             detail[24] = "";   // tool ("Bash") or progress ("62%")
    uint32_t         since = 0;         // state entered
    uint32_t         last = 0;          // last event of any kind
};

struct Board { Entry e[kMax]; };

inline void clearAll(Board& b) { for (auto& x : b.e) x = Entry(); }

// Slot for (project, agent): existing, else free, else the stalest.
inline Entry& slot(Board& b, const char* project, Attention::Agent agent) {
    int free = -1, oldest = 0;
    for (int i = 0; i < kMax; i++) {
        Entry& x = b.e[i];
        if (x.used && x.agent == agent && !strcmp(x.project, project)) return x;
        if (!x.used && free < 0) free = i;
        if (x.used && x.last < b.e[oldest].last) oldest = i;
    }
    Entry& x = b.e[free >= 0 ? free : oldest];
    x = Entry();
    x.used = true;
    Attention::copyStr(x.project, sizeof(x.project), project);
    x.agent = agent;
    return x;
}

inline bool set(Board& b, const char* project, Attention::Agent agent, State st,
                const char* detail, uint32_t now) {
    Entry& x = slot(b, project, agent);
    bool changed = !x.since || x.state != st;
    if (changed) x.since = now;
    x.state = st;
    if (detail) {
        if (strcmp(x.detail, detail)) changed = true;
        Attention::copyStr(x.detail, sizeof(x.detail), detail);
    }
    x.last = now;
    return changed;
}

// Project name for an event: the cwd's last path segment, else the agent.
inline void projectOf(Attention::Agent a, const char* cwd, char* out, size_t n) {
    Attention::basename(cwd, out, n);
    if (!out[0]) Attention::copyStr(out, n, Attention::agentName(a));
}

// One hook event (same trimmed shape /hook takes). True when the board's
// visible content changed.
inline bool noteHook(Board& b, Attention::Agent agent, const Attention::HookEvent& e, uint32_t now) {
    const char* ev = e.event ? e.event : "";
    const char* ty = e.type ? e.type : "";
    char p[24]; projectOf(agent, e.cwd, p, sizeof(p));

    bool approval = !strcmp(ev, "PermissionRequest")
                 || (!strcmp(ev, "Notification") && !strcmp(ty, "permission_prompt"));
    bool input    = !strcmp(ev, "Notification")
                 && (!strcmp(ty, "idle_prompt") || !strcmp(ty, "agent_needs_input")
                     || !strcmp(ty, "elicitation_dialog"));
    bool done     = !strcmp(ev, "Stop") || !strcmp(ev, "SessionEnd")
                 || (!strcmp(ev, "Notification") && !strcmp(ty, "agent_completed"));
    bool working  = !strcmp(ev, "UserPromptSubmit") || !strcmp(ev, "PreToolUse")
                 || !strcmp(ev, "PostToolUse") || !strcmp(ev, "PostToolUseFailure");

    if (approval) return set(b, p, agent, P_APPROVAL, e.tool ? e.tool : "", now);
    if (input)    return set(b, p, agent, P_INPUT, "", now);
    if (done)     return set(b, p, agent, P_DONE, "", now);
    if (working)  return set(b, p, agent, P_WORKING,
                             !strcmp(ev, "UserPromptSubmit") ? "" : (e.tool ? e.tool : ""), now);
    return false;
}

// A pushed card that names a project (POST /push, MCP push_card).
inline bool noteItem(Board& b, const Attention::Item& it, uint32_t now) {
    if (!it.project[0] || !strncmp(it.id, "sys:", 4)) return false;
    char d[24] = "";
    switch (it.kind) {
        case Attention::K_APPROVAL: return set(b, it.project, it.agent, P_APPROVAL, it.title, now);
        case Attention::K_INPUT:    return set(b, it.project, it.agent, P_INPUT, it.title, now);
        case Attention::K_SUCCESS:  return set(b, it.project, it.agent, P_DONE, it.title, now);
        case Attention::K_ERROR:    return set(b, it.project, it.agent, P_ERROR, it.title, now);
        case Attention::K_PROGRESS:
            if (it.progress >= 0) snprintf(d, sizeof(d), "%d%%", it.progress);
            else                  Attention::copyStr(d, sizeof(d), it.title);
            return set(b, it.project, it.agent, P_WORKING, d, now);
        default: return false;
    }
}

inline bool shown(const Entry& x, uint32_t now) {
    if (!x.used) return false;
    if (x.state == P_WORKING) return now - x.last < kIdleS;
    if (x.state == P_DONE || x.state == P_ERROR) return now - x.since < kKeepS;
    return true;                       // waiting on the user: until answered
}

// Visible entries, most urgent first; newest first within a state.
inline int ordered(const Board& b, int out[kMax], uint32_t now) {
    int n = 0;
    for (int i = 0; i < kMax; i++) if (shown(b.e[i], now)) out[n++] = i;
    for (int i = 1; i < n; i++)
        for (int j = i; j > 0; j--) {
            const Entry& a = b.e[out[j - 1]];
            const Entry& c = b.e[out[j]];
            bool swap = c.state < a.state || (c.state == a.state && c.since > a.since);
            if (!swap) break;
            int t = out[j]; out[j] = out[j - 1]; out[j - 1] = t;
        }
    return n;
}

}  // namespace Projects
