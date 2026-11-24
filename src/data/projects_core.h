#pragma once
// Project board — the latest state of each project an agent works in, for the
// Claude screen's bottom rows ("glimmer  Cần duyệt · Bash   2M").
//
// The attention queue answers "what needs me NOW" and forgets a finished
// task after 20 s; this answers "how are my projects doing", so DONE stays
// visible for hours. Fed by the same hook events (and by pushed cards that
// name a project). Pure C++ — host-testable.
//
// One entry per SESSION (project + agent + session id), shown one row per
// PROJECT: two Claude Code sessions in glimmer/app and glimmer/design are
// both "glimmer" (the hook sends the git root as cwd) and the row shows the
// most urgent of them, so one finishing doesn't hide the other still running.
#include <stdint.h>
#include <string.h>
#include "attention_core.h"

namespace Projects {

enum State : uint8_t { P_APPROVAL, P_INPUT, P_ERROR, P_WORKING, P_DONE };  // display priority

constexpr int      kMax       = 8;           // sessions tracked (rows shown: ≤ 3 on screen)
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
    char             session[12] = "";  // first chars of the agent's session id
};

struct Board { Entry e[kMax]; };

inline void clearAll(Board& b) { for (auto& x : b.e) x = Entry(); }

// Slot for (project, agent, session): existing, else free, else the stalest.
inline Entry& slot(Board& b, const char* project, Attention::Agent agent, const char* session) {
    int free = -1, oldest = 0;
    char sess[12]; Attention::copyStr(sess, sizeof(sess), session ? session : "");
    for (int i = 0; i < kMax; i++) {
        Entry& x = b.e[i];
        if (x.used && x.agent == agent && !strcmp(x.project, project) && !strcmp(x.session, sess)) return x;
        if (!x.used && free < 0) free = i;
        if (x.used && x.last < b.e[oldest].last) oldest = i;
    }
    Entry& x = b.e[free >= 0 ? free : oldest];
    x = Entry();
    x.used = true;
    Attention::copyStr(x.project, sizeof(x.project), project);
    Attention::copyStr(x.session, sizeof(x.session), sess);
    x.agent = agent;
    return x;
}

inline bool set(Board& b, const char* project, Attention::Agent agent, State st,
                const char* detail, uint32_t now, const char* session = "") {
    Entry& x = slot(b, project, agent, session);
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

    const char* s = e.session ? e.session : "";
    if (approval) return set(b, p, agent, P_APPROVAL, e.tool ? e.tool : "", now, s);
    if (input)    return set(b, p, agent, P_INPUT, "", now, s);
    if (done)     return set(b, p, agent, P_DONE, "", now, s);
    if (working)  return set(b, p, agent, P_WORKING,
                             !strcmp(ev, "UserPromptSubmit") ? "" : (e.tool ? e.tool : ""), now, s);
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

// a shows before b: more urgent state, then the newer one.
inline bool before(const Entry& a, const Entry& b) {
    return a.state < b.state || (a.state == b.state && a.since > b.since);
}

// One row per project: of its visible sessions, the most urgent (ties: the
// newest). Rows sorted most urgent first. [sessions], if given, receives how
// many visible sessions each row stands for.
inline int ordered(const Board& b, int out[kMax], uint32_t now, int sessions[kMax] = nullptr) {
    int n = 0;
    for (int i = 0; i < kMax; i++) {
        if (!shown(b.e[i], now)) continue;
        int row = -1;
        for (int k = 0; k < n; k++)
            if (!strcmp(b.e[out[k]].project, b.e[i].project)) { row = k; break; }
        if (row < 0) {
            if (sessions) sessions[n] = 1;
            out[n++] = i;
        } else {
            if (sessions) sessions[row]++;
            if (before(b.e[i], b.e[out[row]])) out[row] = i;
        }
    }
    for (int i = 1; i < n; i++)
        for (int j = i; j > 0; j--) {
            if (!before(b.e[out[j]], b.e[out[j - 1]])) break;
            int t = out[j]; out[j] = out[j - 1]; out[j - 1] = t;
            if (sessions) { int u = sessions[j]; sessions[j] = sessions[j - 1]; sessions[j - 1] = u; }
        }
    return n;
}

}  // namespace Projects
