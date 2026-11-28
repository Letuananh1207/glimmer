// glimmer — main orchestrator.
//
// Architecture:
//   core/    hardware + I/O (display, wifi, time, storage, web, OTA)
//   data/    external API clients (claude, codex, weather, status) + history
//   channels/ self-contained renderers, registered in kChannels[]
//
// Adding a channel = drop one .cpp into src/channels/ + add a row to kChannels[].
//
// Fetching is a staggered job scheduler, not a blocking "refresh all": each
// loop pass starts at most one job, jobs are spaced ≥ 3 s apart, and a TLS job
// only starts when the heap clears FetchPolicy::tlsHeapOk (L-4). The web
// server, channel ticks and Wi-Fi checks keep running between jobs.

#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <ESP8266mDNS.h>
#include <time.h>

#include "config.h"
#include "host.h"
#include "theme.h"
#include "display.h"
#include "storage.h"
#include "web.h"
#include "api.h"
#include "weather.h"
#include "history.h"
#include "vendor_status.h"
#include "channel.h"
#include "night_core.h"
#include "chrome.h"
#include "attention.h"
#include "skill_core.h"
#include "xp.h"
#include "taskbar.h"
#include "photos.h"
#include "wallpaper.h"
#include "control_core.h"
#include "xp_menu.h"
#include "xp_start.h"
#include "xp_turnoff.h"
#include "pointer_core.h"
#include "mines_core.h"
#include "clock_core.h"
#include "perf_core.h"
#include "display_core.h"
#include "calc_core.h"
#include "explorer_core.h"
#include "trash.h"
#include "xp_alttab.h"
#include "cursor.h"
#include <coredecls.h>

// ── Channel registry — declared in their own .cpp files ─────────────────────
extern bool chClaudeEnabled(const ChannelCtx&);  extern void chClaudeDraw(const ChannelCtx&);
extern bool chCodexEnabled (const ChannelCtx&);  extern void chCodexDraw (const ChannelCtx&);
extern bool chClockEnabled (const ChannelCtx&);  extern void chClockDraw (const ChannelCtx&);
extern bool chInfoEnabled  (const ChannelCtx&);  extern void chInfoDraw  (const ChannelCtx&);
extern bool chWeatherEnabled (const ChannelCtx&); extern void chWeatherDraw (const ChannelCtx&);
extern bool chAttentionEnabled(const ChannelCtx&); extern void chAttentionDraw(const ChannelCtx&);
extern bool chAgentsEnabled  (const ChannelCtx&); extern void chAgentsDraw  (const ChannelCtx&);
extern bool chHomeEnabled    (const ChannelCtx&); extern void chHomeDraw    (const ChannelCtx&);
extern bool chAiDashEnabled  (const ChannelCtx&); extern void chAiDashDraw  (const ChannelCtx&);
extern bool chForecastEnabled(const ChannelCtx&); extern void chForecastDraw(const ChannelCtx&);
extern bool chTrendEnabled   (const ChannelCtx&); extern void chTrendDraw   (const ChannelCtx&);
extern bool chNightEnabled   (const ChannelCtx&); extern void chNightDraw   (const ChannelCtx&);
extern bool chSetupEnabled   (const ChannelCtx&); extern void chSetupDraw   (const ChannelCtx&);
extern bool chPhotoEnabled   (const ChannelCtx&); extern void chPhotoDraw   (const ChannelCtx&);
extern bool chPhotoEmpty();
extern void chPhotoRequestStep();
extern void chPhotoTick       (const ChannelCtx&);   // the slideshow's next draw() moves to the next photo
extern void chAttentionTick  (const ChannelCtx&);
extern void chAgentsTick     (const ChannelCtx&);
extern void chClockTick      (const ChannelCtx&);
extern void chHomeTick       (const ChannelCtx&);
extern void chClaudeTick     (const ChannelCtx&);
extern void chCodexTick      (const ChannelCtx&);
extern void chAiDashTick     (const ChannelCtx&);
extern void chWeatherTick    (const ChannelCtx&);
extern void chForecastTick   (const ChannelCtx&);
extern void chTrendTick      (const ChannelCtx&);
extern void chInfoTick       (const ChannelCtx&);
extern void chNightTick      (const ChannelCtx&);
extern bool chMinesEnabled   (const ChannelCtx&); extern void chMinesDraw   (const ChannelCtx&);
extern void chMinesTick      (const ChannelCtx&);
extern void chMinesSet(const Mines::View& v, bool onScreen);
// Trình quản lý tác vụ (P-2026-11-28.28).
extern bool chTaskMgrEnabled (const ChannelCtx&); extern void chTaskMgrDraw (const ChannelCtx&);
extern void chTaskMgrTick    (const ChannelCtx&);
extern bool chTaskMgrPointer (int x, int y);
// Thuộc tính màn hình (P-2026-11-28.30).
extern bool chDisplayEnabled (const ChannelCtx&); extern void chDisplayDraw (const ChannelCtx&);
extern bool chDisplaySet     (const DisplayCore::View& v, const Settings* set);
extern bool chDisplayPointer (int x, int y);
// Máy tính bỏ túi (P-2026-11-28.31, skill Giải trí).
extern bool chCalcEnabled    (const ChannelCtx&); extern void chCalcDraw    (const ChannelCtx&);
extern void chCalcSet        (const CalcCore::View& v);
extern bool chCalcPointer    (int x, int y);
// Máy tính / Ảnh của tôi / Thùng rác (P-2026-11-28.32).
extern bool chExplorerEnabled(const ChannelCtx&); extern void chExplorerDraw(const ChannelCtx&);
extern bool chExplorerSet    (const ExplorerCore::View& v);
extern bool chExplorerPointer(int x, int y);
extern void chPhotoShowIndex (int i);
extern bool chAttentionNeedsYou();
extern bool chAttentionWakesScreen();

static const Channel kChannels[] = {
    //  name        enabled              draw                  tick           skill (nullptr = system)
    { "Attention",chAttentionEnabled,chAttentionDraw,chAttentionTick},
    { "Night",    chNightEnabled,    chNightDraw,    chNightTick    },
    { "Setup",    chSetupEnabled,    chSetupDraw,    nullptr,        "agent" },
    { "Home",     chHomeEnabled,     chHomeDraw,     chHomeTick,     "agent" },
    { "Agents",   chAgentsEnabled,   chAgentsDraw,   chAgentsTick,   "agent" },
    { "Claude",   chClaudeEnabled,   chClaudeDraw,   chClaudeTick,   "agent" },
    { "Codex",    chCodexEnabled,    chCodexDraw,    chCodexTick,    "agent" },
    { "AI",       chAiDashEnabled,   chAiDashDraw,   chAiDashTick,   "agent" },
    { "Trend",    chTrendEnabled,    chTrendDraw,    chTrendTick,    "agent" },
    { "Photo",    chPhotoEnabled,    chPhotoDraw,    chPhotoTick,        "photo" },
    { "Weather",  chWeatherEnabled,  chWeatherDraw,  chWeatherTick,  "weather" },
    { "Forecast", chForecastEnabled, chForecastDraw, chForecastTick, "weather" },
    { "Clock",    chClockEnabled,    chClockDraw,    chClockTick,    "clock" },
    { "Mines",    chMinesEnabled,    chMinesDraw,    chMinesTick,    "fun" },     // Dò mìn (P-2026-11-27.25)
    { "Calc",     chCalcEnabled,     chCalcDraw,     nullptr,        "fun" },     // Máy tính bỏ túi (P-2026-11-28.31)
    { "Info",     chInfoEnabled,     chInfoDraw,     chInfoTick     },
    { "TaskMgr",  chTaskMgrEnabled,  chTaskMgrDraw,  chTaskMgrTick  },     // P-2026-11-28.28 (system)
    { "Display",  chDisplayEnabled,  chDisplayDraw,  nullptr        },     // P-2026-11-28.30 (system)
    { "Explorer", chExplorerEnabled, chExplorerDraw, nullptr        },     // P-2026-11-28.32 (system)
};
static constexpr int kChannelCount = sizeof(kChannels) / sizeof(kChannels[0]);

// ── Globals ──────────────────────────────────────────────────────────────────

static Settings    g_settings;
static bool        g_apMode      = false;
static ClaudeData  g_claude;
static CodexData   g_codex;

static int         g_activeIdx[kChannelCount];   // indices into kChannels[] that are enabled
static int         g_activeCount = 0;
static int         g_activePtr   = 0;     // which active channel is on screen

static uint32_t    g_lastRefresh = 0;     // millis of the last completed fetch job
static uint32_t    g_lastSlide   = 0;
static bool        g_nightFace   = false; // night window + mode clock/dark

// App remote control (design 2026-11-26.5), RAM only — R-DK-4: lost on
// reboot, the saved autoRotate / night settings are never touched.
static Control::Rotation g_rot;           // rotation paused + frozen slide time
static bool        g_screenOff   = false; // backlight off on the app's command

// The app is the computer, the device its screen (design 2026-11-26.6 / .7,
// P-2026-11-26.14), RAM only: the open windows the app sends down, and a
// context menu drawn over the screen. The device never rotates channels.
static Control::Windows g_windows;
static Control::Menu    g_menu;
static Control::PowerState g_power;
// Start's "most frequently used" (P-2026-11-27.25): programs opened last, newest first (RAM).
static int8_t g_recent[XPCore::kRecentN] = {XPCore::PROG_NONE, XPCore::PROG_NONE, XPCore::PROG_NONE};      // the app's power button (R-DK-20)
// The Clock window as the app touched it (P-2026-11-26.22) and the last SNTP sync.
static ClockCore::View  g_clockView;
// Task Manager (P-2026-11-28.28): the app's tab / row, and the samples it draws (once a second, RAM).
static Perf::View       g_taskMgrView;
static DisplayCore::View g_displayView;
static CalcCore::View   g_calcView;
static ExplorerCore::View g_explorerView; // Explorer as the app touched it (P-2026-11-28.32)       // Máy tính bỏ túi as the app sent it (P-2026-11-28.31)   // Display Properties as the app touched it (P-2026-11-28.30)
static Perf::History    g_perf;
static uint32_t         g_perfSeq = 0, g_heapTotal = 0, g_idleUs = 0;
static volatile uint32_t g_ntpLast = 0;
static bool        g_wantHome    = true;  // boot: the desktop as soon as it can show

// ── Fetch scheduler state ────────────────────────────────────────────────────

enum Job : uint8_t { JOB_CLAUDE, JOB_CODEX, JOB_CODEX_RESETS, JOB_WEATHER, JOB_STATUS_CLAUDE,
                    JOB_STATUS_OPENAI, JOB_COUNT };
static const char* kJobName[JOB_COUNT] = {"claude", "codex", "codex-resets", "weather",
                                          "status-claude", "status-openai"};

static uint32_t g_jobDue[JOB_COUNT];      // millis when due (0 = now)
static uint32_t g_lastJobStart = 0;
static uint32_t g_heapRefusals = 0;       // jobs deferred by the heap gate
static uint32_t g_minMaxBlk    = 0xFFFFFFFF;

// ── Accessors for web.cpp / channels ────────────────────────────────────────

const char* mainActiveChannelName() {
    if (g_activeCount == 0) return "none";
    return kChannels[g_activeIdx[g_activePtr]].name;
}
int  mainEnabledCount()    { return g_activeCount; }
int  mainTotalCount()      { return kChannelCount; }
uint32_t mainLastRefreshMs() { return g_lastRefresh; }
const char* mainEnabledChannelName(int idx) {
    if (idx < 0 || idx >= g_activeCount) return nullptr;
    return kChannels[g_activeIdx[idx]].name;
}
const ClaudeData* mainClaudeData() { return &g_claude; }
const CodexData*  mainCodexData()  { return &g_codex; }
bool     mainNightFace()    { return g_nightFace; }
bool     mainPinApprovals()   { return g_settings.pinApprovals; }
bool     mainAgentNightShow() { return g_settings.agentNightShow; }
uint32_t mainApprovalTtlS()   { return (uint32_t)g_settings.approvalTtlMin * 60UL; }
bool     mainAgentDoneCards() { return g_settings.agentDoneCards; }
bool     mainPaused()       { return g_rot.paused; }
int8_t   mainSelectedIcon() { return g_windows.sel; }
const ClockCore::View& mainClockView() { return g_clockView; }
const Perf::View& mainTaskMgrView() { return g_taskMgrView; }
const DisplayCore::View& mainDisplayView() { return g_displayView; }
const CalcCore::View& mainCalcView() { return g_calcView; }
const ExplorerCore::View& mainExplorerView() { return g_explorerView; }
const Perf::History& mainPerf() { return g_perf; }
uint32_t mainPerfSeq() { return g_perfSeq; }
uint32_t mainHeapTotal() { return g_heapTotal; }
uint32_t mainNtpLast()      { return g_ntpLast; }
const Control::Windows& mainWindows() { return g_windows; }
const Control::Menu&    mainMenu()    { return g_menu; }
bool     mainScreenOn()     { return !g_screenOff; }
// What the Start menu lists (P-2026-11-27.25): installed programs + the 3 opened last.
PointerCore::StartInputs mainStartInputs() {
    PointerCore::StartInputs si;
    si.in = XPCore::installedOf(g_settings.skillsOn.c_str(), g_settings.showAgents);
    for (int i = 0; i < XPCore::kRecentN; i++) si.recent[i] = g_recent[i];
    return si;
}
const int8_t* mainRecent() { return g_recent; }
const char* mainPowerName() { return Control::powerName(g_power.p); }
int mainHot() { return XP::hot(); }
uint32_t mainHeapRefusals() { return g_heapRefusals; }
uint32_t mainMinMaxBlock()  { return g_minMaxBlk; }

// ── Helpers ──────────────────────────────────────────────────────────────────

static ChannelCtx makeCtx() {
    return ChannelCtx { &g_settings, &g_claude, &g_codex, millis() };
}

static bool timeSynced() { return time(nullptr) > 1000000000L; }

static bool nightNow() {
    if (!timeSynced() || g_settings.nightMode == Night::NONE) return false;
    time_t t = time(nullptr);
    struct tm tm; localtime_r(&t, &tm);
    return Night::inWindow(tm.tm_hour * 60 + tm.tm_min,
                           g_settings.nightStartMin, g_settings.nightEndMin);
}

// Idle dim: no agent activity (hook event, pushed card, queue change) for
// kIdleDimMs → the backlight drops to at most kIdleDimPct. A card holding the
// screen (approval, question) always counts as activity. Night rules still
// decide first; this only ever makes the panel dimmer.
static constexpr uint32_t kIdleDimMs  = 15UL * 60UL * 1000UL;
static constexpr uint8_t  kIdleDimPct = 15;

static bool idleNow() {
    if (!g_settings.idleDim || g_apMode) return false;
    if (chAttentionEnabled(makeCtx())) return false;
    return millis() - AttentionQueue::lastActivityMs() >= kIdleDimMs;
}

static void applyBrightness() {
    ChannelCtx ctx = makeCtx();
    bool night = nightNow();
    uint8_t pct = Night::brightness((Night::Mode)g_settings.nightMode, night,
                                    chAttentionEnabled(ctx), g_settings.brightness,
                                    g_settings.nightBright);
    if (idleNow() && pct > kIdleDimPct) pct = kIdleDimPct;
    // Screen off from the app: dark until a card that needs the user holds the screen.
    pct = (uint8_t)Control::brightness(pct, g_screenOff, g_screenOff && chAttentionWakesScreen());
    Display::setBrightness(pct);
}

static void recomputeActive() {
    // Keep showing the same channel across a recompute when it is still enabled.
    const char* cur = g_activeCount ? kChannels[g_activeIdx[g_activePtr]].name : nullptr;
    g_nightFace = nightNow() && g_settings.nightMode >= Night::CLOCK;
    ChannelCtx ctx = makeCtx();
    const char* skillsOn = g_settings.skillsOn.c_str();
    g_activeCount = 0;
    for (int i = 0; i < kChannelCount; i++) {
        // The night face replaces rotation: only it (and an alert card) runs.
        if (g_nightFace && strcmp(kChannels[i].name, "Night") && strcmp(kChannels[i].name, "Attention"))
            continue;
        // Enabled skills' channels + system ones (R-SK-2).
        if (!Skill::shows(kChannels[i].skill, skillsOn)) continue;
        if (kChannels[i].enabled(ctx)) g_activeIdx[g_activeCount++] = i;
    }
    // Keep the same channel; when it is gone (a card ended, the night is over,
    // a skill turned off) the top window comes back, else the desktop
    // (P-2026-11-26.14: no rotation, the screen shows what the app opened).
    auto find = [](const char* name) {
        for (int i = 0; name && i < g_activeCount; i++)
            if (!strcasecmp(kChannels[g_activeIdx[i]].name, name)) return i;
        return -1;
    };
    int at = find(cur);
    if (at < 0) at = find(XPCore::progName(g_windows.top));
    if (at < 0) at = find("Home");
    g_activePtr = at < 0 ? 0 : at;
}

// A program whose channel is on now (its skill enabled, its show* flag on).
static bool progInstalled(int p) {
    const char* name = XPCore::progName(p);
    for (int i = 0; name && i < g_activeCount; i++)
        if (!strcasecmp(kChannels[g_activeIdx[i]].name, name)) return true;
    return false;
}

// Agents waiting on the user (approval / question) — the badge on the
// taskbar's Claude button.
static int waitingNow() {
    return Attention::countWaiting(AttentionQueue::get(), AttentionQueue::now());
}

// The device never rotates channels (P-2026-11-26.14). A Photo window still
// steps through its photos, like XP's picture viewer slideshow.
static bool photoSlideshow() {
    return !g_nightFace && g_activeCount && Photos::total() > 1
        && !strcmp(kChannels[g_activeIdx[g_activePtr]].name, "Photo");
}

// A new slide starts now (a paused rotation stays paused, at its start).
static void markSlide(uint32_t now) {
    g_lastSlide = now;
    Control::restart(g_rot);
}

static uint32_t slideMs() { return (uint32_t)g_settings.channelSec * 1000UL; }

// What the taskbar shows now (P-2026-11-26.14): one button per open window,
// the top one pressed while it is on screen, the Claude window's button
// orange on a card that needs the user, the waiting badge on it.
static XPCore::BarState barState(uint32_t) {
    XPCore::BarState s;
    s.badge = (int8_t)XPCore::badgeGlyph(waitingNow());
    int8_t open[XPCore::PROG_COUNT];
    int n = 0;
    for (int i = 0; i < g_windows.n; i++)
        if (progInstalled(g_windows.open[i])) open[n++] = g_windows.open[i];
    const char* name = g_activeCount ? kChannels[g_activeIdx[g_activePtr]].name : nullptr;
    s.trayWeather = Skill::inList(g_settings.skillsOn.c_str(), "weather");
    XPCore::fillBar(s, open, n, g_windows.top, XPCore::progOf(name), XPCore::slotsFor(s.trayWeather));
    s.flash = name && !strcmp(name, "Attention") && chAttentionNeedsYou();
    s.startDown = g_menu.kind == XPCore::MENU_START;
    return s;
}

// The channel drawActive() painted last (to see the desktop come up / go away).
static const char* g_drawnName = nullptr;

// Opening a window (P-2026-11-26.16, XP-Open): the empty frame is up and the
// content comes at g_contentAt; a window being restored from / minimized to
// its taskbar button zooms (XP "animate windows").
static bool     g_contentDue = false;
static uint32_t g_contentAt  = 0;
static int8_t   g_restoring  = XPCore::PROG_NONE;   // minimized program coming back up
static int8_t   g_minimizing = XPCore::PROG_NONE;   // program going down to its button

static bool isHome(const char* name) { return name && !strcmp(name, "Home"); }

// What drawActive() painted last (P-2026-11-26.21: no tray balloon any more).
static void noteDrawn(const char* name) { g_drawnName = name; }

// Taskbar slot showing program [p] in [s], -1 = none.
static int slotOf(const XPCore::BarState& s, int p) {
    for (int i = 0; p >= 0 && i < XPCore::kSlots; i++) if (s.prog[i] == p) return i;
    return -1;
}

// P-2026-11-27.24 (XP-Pointer): the Start menu row / sub-menu row / Tắt máy tính button under the
// mouse cursor (the device knows the geometry, pointer_core.h); the app's hover (arrow keys) wins.
static int8_t g_autoHover = -1, g_autoSub = -1;

static Control::Menu litMenu() {
    Control::Menu m = g_menu;
    if (m.kind == XPCore::MENU_START || m.kind == XPCore::MENU_TURNOFF) {
        if (m.hover < 0) m.hover = g_autoHover;
        if (m.sub < 0) m.sub = g_autoSub;
    }
    return m;
}

// The open menu: the Start menu (P-2026-11-26.20), Tắt máy tính (P-2026-11-27.24) or a context
// menu (P-2026-11-26.14).
static void paintMenu() {
    const Control::Menu m = litMenu();
    if (m.kind == XPCore::MENU_START) XPStart::draw(m, g_settings.skillsOn.c_str());
    else if (m.kind == XPCore::MENU_TURNOFF) XPTurnOff::draw(m.hover);
    else if (m.kind == XPCore::MENU_ALTTAB) XPAltTab::draw(m);
    else XPMenu::draw(m);
}

// Another row lit on the same menu: only what changed repaints.
static void relightMenu(const Control::Menu& was) {
    const Control::Menu now = litMenu();
    if (now.kind == XPCore::MENU_START) XPStart::relight(was, now, g_settings.skillsOn.c_str());
    else if (now.kind == XPCore::MENU_TURNOFF) XPTurnOff::relight(was.hover, now.hover);
    else if (now.kind == XPCore::MENU_ALTTAB) XPAltTab::relight(was, now);
    else XPMenu::draw(now);
}

// A context menu stays over the screen it was opened on (not on Night / cards).
static void drawMenuOver(const char* name) {
    if (g_menu.kind == XPCore::MENU_NONE) return;
    if (XPCore::buttonFor(name) == XPCore::BTN_NO_BAR || !strcmp(name, "Attention")) g_menu = Control::Menu();
    else paintMenu();
}

static void drawActive() {
    // P-2026-11-27.24: the power screens (đang tắt máy, boot, welcome) own the panel.
    if (Control::powerScreen(g_power.p)) return;
    g_contentDue = false;
    const bool afterSystem = Display::systemScreenShown();
    if (g_activeCount == 0) {
        noteDrawn(nullptr);
        g_restoring = g_minimizing = XPCore::PROG_NONE;
        XP::drawNoChannels();                               // XP-NoChannels
        Taskbar::draw(barState(millis()), g_settings.clock24h);
        Cursor::screenRepainted();
        return;
    }
    // Re-arm splash/connecting/OTA partial-redraw state in case we re-enter
    // a system screen later (e.g., WiFi reconnect drops to drawConnecting).
    Display::resetSystemScreens();
    ChannelCtx ctx = makeCtx();
    const char* name = kChannels[g_activeIdx[g_activePtr]].name;
    const char* prev = g_drawnName;
    noteDrawn(name);
    XP::setDefaultIcon(XPCore::iconFor(name));   // for the legacy Display::statusBar

    // P-2026-11-26.16 (XP-Open). 1. The window's button presses first: with the
    // taskbar still on screen only the changed buttons repaint.
    const bool hasBar = XPCore::buttonFor(name) != XPCore::BTN_NO_BAR;
    const bool barKept = hasBar && Taskbar::shown() && !afterSystem;
    const XPCore::BarState bar = barState(millis());
    if (barKept) Taskbar::update(bar, g_settings.clock24h);
    // 2. Restoring a minimized window: its title bar zooms up from the button;
    //    minimizing: down to it, then the desktop. Nothing else zooms (XP).
    if (barKept) {
        const int p = XPCore::progOf(name);
        if (isHome(name) && g_minimizing >= 0) {
            const int slot = slotOf(bar, g_minimizing);
            if (slot >= 0) XP::zoom(slot, false);
        } else if (p >= 0 && p == g_restoring) {
            const int slot = slotOf(bar, p);
            if (slot >= 0) XP::zoom(slot, true);
        }
    }
    g_restoring = g_minimizing = XPCore::PROG_NONE;
    // 3. A window that just came up shows its empty frame + the wait cursor for
    //    200 ms; the content comes from loop(). Back from a card / the night
    //    face, or a repaint of the same window: the content at once.
    const bool fresh = !prev || strcmp(prev, name);
    const bool revealed = prev && (!strcmp(prev, "Attention") || !strcmp(prev, "Night"));
    if (fresh && !revealed && XPCore::framesFirst(name)) {
        const XPCore::WinFrame f = XPCore::frameOf(name);
        XP::emptyFrame(f.title, f.icon, f.status);
        g_contentDue = true;
        g_contentAt = millis() + XPCore::kEmptyFrameMs;
    } else {
        kChannels[g_activeIdx[g_activePtr]].draw(ctx);
    }
    // Taskbar (main.cpp owns y 214..239); none on Night.
    if (!hasBar) Taskbar::hide();
    else if (!barKept) Taskbar::draw(bar, g_settings.clock24h);
    if (!g_contentDue) drawMenuOver(name);
    Cursor::screenRepainted();
}

// 4. The content of a window whose empty frame is up (see drawActive).
static void drawDueContent(uint32_t now) {
    if (!g_contentDue || (int32_t)(now - g_contentAt) < 0 || !g_activeCount) return;
    g_contentDue = false;
    ChannelCtx ctx = makeCtx();
    const char* name = kChannels[g_activeIdx[g_activePtr]].name;
    kChannels[g_activeIdx[g_activePtr]].draw(ctx);
    drawMenuOver(name);
    Cursor::overlay();
}

// The screen again, clipped to (x, y, w, h): the mouse cursor left that box
// and the panel can't be read back (cursor.h). The window's tick() runs first
// so the values its draw() seeds are the ones the rest of the screen shows;
// draw() sees Display::repainting() and skips its side effects.
static void repaintRect(int x, int y, int w, int h) {
    if (g_apMode || !g_activeCount) return;
    const Channel& ch = kChannels[g_activeIdx[g_activePtr]];
    if (!g_contentDue && g_menu.kind == XPCore::MENU_NONE && ch.tick) ch.tick(makeCtx());
    Display::beginRepaint(x, y, w, h);
    // L-9: the Start menu covers (0, 0)–(239, 213) — a box inside it needs no window under it.
    const bool underStart = g_menu.kind == XPCore::MENU_START && y + h <= Layout::TASKBAR_Y;
    if (underStart) {
        // nothing: paintMenu() below covers the whole box
    } else if (g_contentDue) {
        const XPCore::WinFrame f = XPCore::frameOf(ch.name);
        XP::emptyFrame(f.title, f.icon, f.status);
    } else {
        ch.draw(makeCtx());
    }
    if (y + h > Layout::TASKBAR_Y) Taskbar::repaint();
    if (g_menu.kind != XPCore::MENU_NONE) paintMenu();
    Display::endRepaint();
}

// Where the mouse cursor may show: a desktop / window / card on a lit screen.
static bool cursorAllowed() {
    return !g_apMode && g_activeCount && g_power.p == Control::POWER_ON && !g_nightFace && !g_screenOff
        && !Display::systemScreenShown()
        && strcmp(kChannels[g_activeIdx[g_activePtr]].name, "Night");
}

// /api/channel {"name":"Home","zoom":"min"} — the app's _ button: the window on
// screen goes down to its taskbar button (zooms), unlike close / Show desktop.
void mainNoteMinimize() {
    if (!g_activeCount) return;
    const int p = XPCore::progOf(kChannels[g_activeIdx[g_activePtr]].name);
    if (p >= 0) g_minimizing = (int8_t)p;
}

// Recompute, and repaint only when what should be on screen changed.
static void refreshScreen(bool force) {
    const char* before = g_activeCount ? kChannels[g_activeIdx[g_activePtr]].name : nullptr;
    int countBefore = g_activeCount;
    recomputeActive();
    const char* after = g_activeCount ? kChannels[g_activeIdx[g_activePtr]].name : nullptr;
    if (force || before != after || countBefore != g_activeCount) {
        drawActive();
        markSlide(millis());
    }
}

// Manual switching (web /api/channel, MCP): closes a context menu; a
// program comes to the top of the open windows (the app sends the full list
// right after; this covers a channel opened without the app).
bool mainShowChannel(const char* name) {
    recomputeActive();
    for (int i = 0; i < g_activeCount; i++) {
        if (!strcasecmp(kChannels[g_activeIdx[i]].name, name)) {
            if (strcmp(kChannels[g_activeIdx[g_activePtr]].name, "Clock") && !strcasecmp(name, "Clock"))
                g_clockView = ClockCore::View();      // the Clock window opens on today, as XP
            if (strcmp(kChannels[g_activeIdx[g_activePtr]].name, "Display") && !strcasecmp(name, "Display"))
                g_displayView = DisplayCore::View();  // Display Properties opens on the saved values, as XP
            g_activePtr = i;
            g_menu = Control::Menu();
            g_wantHome = false;
            const int p = XPCore::progOf(kChannels[g_activeIdx[i]].name);
            // A minimized window coming back up zooms from its button (XP).
            if (p >= 0 && (g_windows.minMask >> p & 1)) g_restoring = (int8_t)p;
            Control::adopt(g_windows, p);
            XPCore::noteRecent(g_recent, p);
            drawActive();
            markSlide(millis());
            return true;
        }
    }
    return false;
}

void mainNextChannel() {
    recomputeActive();
    if (g_activeCount == 0) return;
    g_activePtr = (g_activePtr + 1) % g_activeCount;
    drawActive();
    markSlide(millis());
}

// The channel before the current one (app d-pad, swipe right).
void mainPrevChannel() {
    recomputeActive();
    if (g_activeCount == 0) return;
    g_activePtr = Control::prevIndex(g_activePtr, g_activeCount);
    drawActive();
    markSlide(millis());
}

// Temporary rotation pause (R-DK-4): no auto-advance, the taskbar's slide
// progress stops where it is; manual next / prev / show still work and keep
// it paused; agent cards still interrupt.
void mainSetPaused(bool paused) {
    uint32_t now = millis();
    if (paused) Control::pause(g_rot, now, g_lastSlide, slideMs());
    else        g_lastSlide = Control::resume(g_rot, now, g_lastSlide);
}

// Backlight off / on now, whatever the night window says (RAM only).
void mainSetScreenOn(bool on) {
    g_screenOff = !on;
    // Tắt máy tính › Chờ (P-2026-11-27.24): the box goes with the screen.
    if (!on && g_menu.kind == XPCore::MENU_TURNOFF) {
        g_menu = Control::Menu();
        drawActive();
    }
    applyBrightness();
}

// The app's power button (R-DK-20). Off: the screen stays as it is while
// shutting down (XP's "shutting down" screen waits for the panel design),
// then goes dark. On: the boot screen, then the desktop with no window open.
// The boot screen (power booting: on, or a restart's second half).
static void showBoot() {
    g_screenOff = false;
    g_menu = Control::Menu();
    XP::setHot(PointerCore::kHotNone);
    Taskbar::hide();
    Display::resetSystemScreens();
    Display::drawSplash("");
    applyBrightness();
}

// XP's "đang tắt máy..." (P-2026-11-27.24, XP-ShutDown) for 1.5 s.
static void showShutDown() {
    g_menu = Control::Menu();
    XP::setHot(PointerCore::kHotNone);
    Taskbar::hide();
    Display::resetSystemScreens();
    Display::drawShutDown();
    applyBrightness();
}

static void powerChanged() {
    if (g_power.p == Control::POWER_BOOTING) showBoot();
    else if (g_power.p == Control::POWER_SHUTTING) showShutDown();
}

void mainSetPower(bool on) {
    if (Control::requestPower(g_power, on, millis())) powerChanged();
}

// Tắt máy tính › Khởi động lại: shut down, then boot again.
void mainRestart() {
    if (Control::requestRestart(g_power, millis())) powerChanged();
}

// Shutting down → off (or booting), booting → welcome 1 s → the desktop (every loop pass).
static void powerTick(uint32_t now) {
    if (g_power.p == Control::POWER_BOOTING) Display::splashStep((now - g_power.since) / 200);
    if (!Control::advancePower(g_power, now)) return;
    if (g_power.p == Control::POWER_BOOTING) {        // a restart: off the shutdown screen, boot
        showBoot();
        return;
    }
    if (g_power.p == Control::POWER_WELCOME) {        // as XP: boot → Welcome → desktop
        Display::resetSystemScreens();
        Display::drawConnecting("", 0);
        return;
    }
    if (g_power.p == Control::POWER_OFF) {
        g_screenOff = true;
        g_windows = Control::Windows();
        g_menu = Control::Menu();
        applyBrightness();
    } else {                                   // on: a fresh start, like opening the app (R-DK-7)
        g_windows = Control::Windows();
        Display::resetSystemScreens();
        if (!mainShowChannel("Home")) drawActive();
        applyBrightness();
    }
}

// The device does not rotate (P-2026-11-26.14): no slide to report.
void mainSlideTiming(uint32_t& totalMs, uint32_t& leftMs) { totalMs = leftMs = 0; }

// The app's open windows (POST /api/windows). The selected desktop icon
// changing on the desktop repaints it; the taskbar catches up by itself.
void mainSetWindows(const Control::Windows& w) {
    const bool selChanged = w.sel != g_windows.sel;
    // The list may come before the /api/channel that shows its top window.
    if (w.top >= 0 && (g_windows.minMask >> w.top & 1) && !(w.minMask >> w.top & 1)) g_restoring = w.top;
    g_windows = w;
    Control::zFromOpen(g_windows);
    if (selChanged && g_activeCount && !strcmp(kChannels[g_activeIdx[g_activePtr]].name, "Home")) drawActive();
}

// A context menu (POST /api/menu): drawn over the screen; closing it repaints
// what was under it (the channel's draw()). Not over Night / cards / setup.
bool mainSetMenu(const Control::Menu& m) {
    if (g_apMode || !g_activeCount) return false;
    const char* name = kChannels[g_activeIdx[g_activePtr]].name;
    if (m.kind != XPCore::MENU_NONE
        && (XPCore::buttonFor(name) == XPCore::BTN_NO_BAR || !strcmp(name, "Attention"))) return false;
    // Alt+Tab with no window open: XP shows no box (P-2026-11-28.29).
    if (m.kind == XPCore::MENU_ALTTAB && !g_windows.n) return false;
    const bool wasOpen = g_menu.kind != XPCore::MENU_NONE;
    const bool startToStart = wasOpen && g_menu.kind == XPCore::MENU_START && m.kind == XPCore::MENU_START;
    const bool hoverOnly = wasOpen && Control::sameMenu(g_menu, m);
    const Control::Menu was = litMenu();
    if (!hoverOnly) g_autoHover = g_autoSub = -1;       // a new menu: the cursor's pick comes next pass
    if (m.kind != XPCore::MENU_NONE && XP::hot() != PointerCore::kHotNone) {
        const PointerCore::Rect r = PointerCore::hotRect(XP::hot());
        XP::setHot(PointerCore::kHotNone);              // a menu over the screen: nothing hot under it
        if (!wasOpen) repaintRect(r.x, r.y, r.w, r.h);
    }
    g_menu = m;
    if (hoverOnly) {
        if (m.kind != XPCore::MENU_NONE) relightMenu(was);   // another item lit (cursor / arrow keys)
    } else if (m.kind != XPCore::MENU_NONE) {
        // Start → Start (All Programs opened / closed): the menu covers its own area.
        if (wasOpen && !startToStart) drawActive();   // moved: repaint under the old one first
        else paintMenu();
    } else if (wasOpen) {
        drawActive();
    }
    // The start button (not under Tắt máy tính's shade: drawActive() already released it).
    if (Taskbar::shown() && g_menu.kind != XPCore::MENU_TURNOFF) Taskbar::update(barState(millis()), g_settings.clock24h);
    Cursor::overlay();
    return true;
}

// ── The device is the computer (plan app/docs/tasks/2026-11-28-thiet-bi-la-may-tinh.md, stage 1) ──
// Mouse v2: the app sends the buttons; what a click hits and does is worked out here (input_core.h).

// What is on screen now, for input_core.
static InputCore::Scene inputScene() {
    InputCore::Scene s;
    const char* name = g_activeCount ? kChannels[g_activeIdx[g_activePtr]].name : nullptr;
    s.desktop = isHome(name);
    s.shown = (int8_t)XPCore::progOf(name);
    s.caption = name && Taskbar::shown() && s.shown >= 0 && (g_contentDue || XPCore::framesFirst(name));
    s.menu = g_menu.kind;
    s.all = g_menu.all;
    s.bar = Taskbar::state();
    s.nIcons = s.desktop ? XPCore::deskIcons(g_settings.skillsOn.c_str(), s.icons) : 0;
    if (s.menu == XPCore::MENU_START) PointerCore::startLayout(mainStartInputs(), s.start);
    if (s.menu == XPCore::MENU_DESKTOP || s.menu == XPCore::MENU_WINDOW) {
        int mx = g_menu.x, my = g_menu.y;
        XPCore::menuClamp(s.menu, mx, my);
        s.menuX = (int16_t)mx;
        s.menuY = (int16_t)my;
    }
    s.menuMin = g_menu.minimized;
    s.menuProg = g_menu.prog >= 0 ? g_menu.prog : s.shown;
    s.hover = g_menu.hover >= 0 ? g_menu.hover : g_autoHover;
    s.sel = g_windows.sel;
    return s;
}

static uint32_t g_altCommitAt = 0;   // Alt+Tab: "Alt let go" (the app's key is one press, R-DK-25)

static InputCore::ClickTrack g_clicks;

static void showMenu(XPCore::MenuKind k, bool all = false) {
    Control::Menu m;
    m.kind = k;
    m.all = all;
    mainSetMenu(m);
}

// Apply what a left click does (the same device functions the app's HTTP commands use).
static void applyClick(const InputCore::Action& a) {
    using namespace InputCore;
    switch (a.kind) {
        case ACT_SELECT:
            if (a.prog != g_windows.sel) {
                g_windows.sel = a.prog;
                drawActive();
                Cursor::overlay();
            }
            break;
        case ACT_OPEN:
            if (a.prog == XPCore::PROG_EXPLORER && a.arg >= 0) {
                g_explorerView = ExplorerCore::View();
                g_explorerView.place = (uint8_t)a.arg;
            }
            mainShowChannel(XPCore::progName(a.prog));
            break;
        case ACT_TASKBAR:
            if (a.prog == XPCore::progOf(mainActiveChannelName())) {       // on screen: down (XP)
                Control::minimizeWindow(g_windows, a.prog);
                mainNoteMinimize();
                mainShowChannel("Home");
            } else {
                mainShowChannel(XPCore::progName(a.prog));
            }
            break;
        case ACT_MINIMIZE:
            if (a.prog != XPCore::progOf(mainActiveChannelName())) {    // from a menu: a window not on screen
                Control::minimizeWindow(g_windows, a.prog);
                showMenu(XPCore::MENU_NONE);
                break;
            }
            Control::minimizeWindow(g_windows, a.prog);
            mainNoteMinimize();
            mainShowChannel("Home");
            break;
        case ACT_CLOSE:
            if (a.prog != XPCore::progOf(mainActiveChannelName())) {
                Control::removeWindow(g_windows, a.prog);
                showMenu(XPCore::MENU_NONE);
                break;
            }
            Control::closeWindow(g_windows, a.prog);
            mainShowChannel(g_windows.top >= 0 ? XPCore::progName(g_windows.top) : "Home");
            break;
        case ACT_MENU_OPEN: {
            Control::Menu m;
            m.kind = (XPCore::MenuKind)a.arg;
            m.x = a.x;
            m.y = a.y;
            m.minimized = a.min;
            m.prog = a.prog;
            mainSetMenu(m);
            break;
        }
        case ACT_HOVER: {
            Control::Menu m = g_menu;
            m.hover = a.arg;
            m.sub = -1;
            mainSetMenu(m);
            break;
        }
        case ACT_ALTTAB: {
            if (!g_windows.n) break;
            int8_t list[XPCore::PROG_COUNT];
            const int n = XPAltTab::order(list);
            Control::Menu m;
            m.kind = XPCore::MENU_ALTTAB;
            m.hover = g_menu.kind == XPCore::MENU_ALTTAB ? (int8_t)((g_menu.hover + a.arg + n) % n)
                                                        : (int8_t)XPCore::altTabSel(a.arg < 0 ? n - 1 : -1, n);
            mainSetMenu(m);
            g_altCommitAt = millis() + 1000;
            break;
        }
        case ACT_ALTTAB_CANCEL:
            showMenu(XPCore::MENU_NONE);
            break;
        case ACT_START:
            showMenu(g_menu.kind == XPCore::MENU_START ? XPCore::MENU_NONE : XPCore::MENU_START);
            break;
        case ACT_START_ALL:
            showMenu(XPCore::MENU_START, !g_menu.all);
            break;
        case ACT_SHOW_DESKTOP:
            Control::showDesktop(g_windows);
            g_menu = Control::Menu();
            mainShowChannel("Home");
            break;
        case ACT_TURNOFF_BOX:
            showMenu(XPCore::MENU_TURNOFF);
            break;
        case ACT_STANDBY:
            mainSetScreenOn(false);
            break;
        case ACT_POWER_OFF:
            showMenu(XPCore::MENU_NONE);
            mainSetPower(false);
            break;
        case ACT_RESTART:
            showMenu(XPCore::MENU_NONE);
            mainRestart();
            break;
        case ACT_START_CLOSE:
        case ACT_TURNOFF_CLOSE:
        case ACT_MENU_CLOSE:
            showMenu(XPCore::MENU_NONE);
            break;
        case ACT_NONE:
            break;
    }
}

// Alt+Tab box up and Alt let go (1 s without another Alt+Tab): the window chosen comes up (XP).
static void altTabCommit() {
    if (g_menu.kind != XPCore::MENU_ALTTAB) return;
    int8_t list[XPCore::PROG_COUNT];
    const int n = XPAltTab::order(list);
    const int sel = XPCore::altTabSel(g_menu.hover, n);
    showMenu(XPCore::MENU_NONE);
    if (sel >= 0 && list[sel] != XPCore::progOf(mainActiveChannelName())) mainShowChannel(XPCore::progName(list[sel]));
}

// The presses (v2 mouse: left = a click, double click as XP; right = context menus) and keys that came in.
static void inputTick() {
    Cursor::PressAt pr[4];
    const int n = Cursor::takePresses(pr, 4);
    InputCore::KeyPress ks[4];
    const int nk = Cursor::takeKeys(ks, 4);
    const bool ready = g_activeCount && g_power.p == Control::POWER_ON && cursorAllowed();
    if (g_menu.kind == XPCore::MENU_ALTTAB && (int32_t)(millis() - g_altCommitAt) >= 0) altTabCommit();
    if (!ready) return;
    for (int i = 0; i < n; i++) {
        const int x = pr[i].x, y = pr[i].y;
        if (pr[i].press == InputCore::PRESS_RIGHT) {
            applyClick(InputCore::rightClick(inputScene(), x, y, g_windows.minMask));
            continue;
        }
        const bool dbl = InputCore::doubleClick(g_clicks, pr[i].at, x, y);
        applyClick(InputCore::leftClick(inputScene(), x, y, dbl));
    }
    for (int i = 0; i < nk; i++) {
        const bool altTab = ks[i].key == InputCore::KEY_TAB && (ks[i].mods & InputCore::MOD_ALT);
        // Another key while the box is up: Alt was let go first (Esc cancels instead).
        if (g_menu.kind == XPCore::MENU_ALTTAB && !altTab && ks[i].key != InputCore::KEY_ESC) altTabCommit();
        applyClick(InputCore::keyAction(inputScene(), ks[i].key, ks[i].mods, g_menu.kind == XPCore::MENU_ALTTAB));
    }
}

// P-2026-11-27.24 (XP-Pointer): what the mouse cursor is over — a Start menu / sub-menu row or a Tắt
// máy tính button lights (when the app picked none), a taskbar / caption button turns hot.
static void pointerTick() {
    const bool mouse = Cursor::mouseMode() && g_activeCount && g_power.p == Control::POWER_ON;
    const int x = Cursor::x(), y = Cursor::y();
    // Menu rows.
    int8_t hv = -1, sb = -1;
    if (mouse && g_menu.kind == XPCore::MENU_START) {
        PointerCore::StartLayout L;
        PointerCore::startLayout(mainStartInputs(), L);
        hv = (int8_t)PointerCore::startHit(L, g_menu.all, x, y);
        sb = (int8_t)PointerCore::subHit(L, g_menu.all, x, y);
    } else if (mouse && g_menu.kind == XPCore::MENU_TURNOFF) {
        hv = (int8_t)PointerCore::turnOffHit(x, y);
    }
    if (hv != g_autoHover || sb != g_autoSub) {
        const Control::Menu was = litMenu();
        g_autoHover = hv;
        g_autoSub = sb;
        // Stage 3: the pointer moved onto another row — it takes over from the arrow keys' pick.
        if (Cursor::deviceDriven()) g_menu.hover = g_menu.sub = -1;
        if (g_menu.kind == XPCore::MENU_START || g_menu.kind == XPCore::MENU_TURNOFF) {
            relightMenu(was);
            Cursor::overlay();
        }
    }
    // Stage 3: a context menu the device opened lights the item under the pointer (dim ones too, as XP); only when
    // the pointer moves onto another item, so an arrow key's pick stays while it rests.
    static int8_t ptrItem = -2;
    if (mouse && Cursor::deviceDriven() && (g_menu.kind == XPCore::MENU_DESKTOP || g_menu.kind == XPCore::MENU_WINDOW)) {
        int mx = g_menu.x, my = g_menu.y;
        XPCore::menuClamp(g_menu.kind, mx, my);
        bool inside = false;
        const int8_t it = (int8_t)InputCore::menuItemAt(g_menu.kind, mx, my, x, y, inside);
        if (it != ptrItem) {
            ptrItem = it;
            if (it != g_menu.hover) {
                g_menu.hover = it;
                XPMenu::draw(g_menu);
                Cursor::overlay();
            }
        }
    } else {
        ptrItem = -2;
    }
    // Hot buttons: only with no menu over the screen, on a screen with the taskbar.
    int8_t hot = PointerCore::kHotNone;
    if (mouse && g_menu.kind == XPCore::MENU_NONE && Taskbar::shown()) {
        const char* name = kChannels[g_activeIdx[g_activePtr]].name;
        const bool caption = g_contentDue || XPCore::framesFirst(name);
        hot = PointerCore::hotAt(Taskbar::state(), caption, x, y);
    }
    // P-2026-11-28.28–.31: a window's own buttons under the mouse (hot ring); it repaints only those.
    if (g_menu.kind == XPCore::MENU_NONE && !g_contentDue && g_activeCount) {
        const char* name = kChannels[g_activeIdx[g_activePtr]].name;
        const int px = mouse ? x : -1, py = mouse ? y : -1;
        if (!strcmp(name, "TaskMgr") && chTaskMgrPointer(px, py)) Cursor::overlay();
        if (!strcmp(name, "Display") && chDisplayPointer(px, py)) Cursor::overlay();
        if (!strcmp(name, "Calc") && chCalcPointer(px, py)) Cursor::overlay();
        if (!strcmp(name, "Explorer") && chExplorerPointer(px, py)) Cursor::overlay();
    }
    if (hot != XP::hot()) {
        const PointerCore::Rect was = PointerCore::hotRect(XP::hot()), now = PointerCore::hotRect(hot);
        XP::setHot(hot);
        if (was.w) repaintRect(was.x, was.y, was.w, was.h);
        if (now.w) repaintRect(now.x, now.y, now.w, now.h);
        Cursor::overlay();
    }
}

// The Clock window touched from the app (POST /api/clock, P-2026-11-26.22):
// tab, viewed month / year, chosen day, open list. Repaints the window when it
// is on screen. [sync] asks the time servers again now ("Cập nhật ngay").
void mainSetClock(const ClockCore::View& v, bool sync) {
    g_clockView = v;
    if (sync) {
        configTime(0, 0, "pool.ntp.org", "time.google.com");
        Storage::applyTimezone(g_settings);
    }
    if (g_activeCount && !strcmp(kChannels[g_activeIdx[g_activePtr]].name, "Clock") && g_menu.kind == XPCore::MENU_NONE)
        drawActive();
}

// The Task Manager touched from the app (POST /api/taskmgr, P-2026-11-28.28): tab / selected row.
// On screen a new tab repaints the window, a new row only the list (tick()).
void mainSetTaskMgr(const Perf::View& v) {
    const bool tabChanged = v.tab != g_taskMgrView.tab;
    g_taskMgrView = v;
    if (tabChanged && g_activeCount && !strcmp(kChannels[g_activeIdx[g_activePtr]].name, "TaskMgr")
        && g_menu.kind == XPCore::MENU_NONE && !g_contentDue) {
        drawActive();
    }
}

// Display Properties touched from the app (POST /api/display, P-2026-11-28.30): on screen only what changed
// repaints; a new tab / the drop list opening or closing repaints the window.
void mainSetDisplay(const DisplayCore::View& v) {
    g_displayView = v;
    if (!g_activeCount || strcmp(kChannels[g_activeIdx[g_activePtr]].name, "Display")
        || g_menu.kind != XPCore::MENU_NONE || g_contentDue) return;
    if (!chDisplaySet(v, &g_settings)) drawActive();
    else Cursor::overlay();
}

// Máy tính bỏ túi from the app (POST /api/calc, P-2026-11-28.31): on screen only the display / memory cell /
// the keys that changed repaint.
void mainSetCalc(const CalcCore::View& v) {
    g_calcView = v;
    if (g_activeCount && !strcmp(kChannels[g_activeIdx[g_activePtr]].name, "Calc")
        && g_menu.kind == XPCore::MENU_NONE && !g_contentDue) {
        chCalcSet(v);
        Cursor::overlay();
    }
}

// Explorer touched from the app (POST /api/explorer, P-2026-11-28.32): the place / selection / scroll / confirm
// box, then what to do ("delete" the selected photo to the bin, "restore" / "empty" the bin, "open" the
// selected photo in the Photo window — the app sends /api/channel Photo after). Returns false when the
// action could not be done (no such item, bin full, file system).
bool mainSetExplorer(const ExplorerCore::View& v, const char* what) {
    bool ok = true;
    bool changed = false;
    if (what && *what) {
        if (!strcmp(what, "delete")) {
            char nm[16];
            Photos::name(g_explorerView.sel, nm, sizeof(nm));
            ok = *nm && Trash::moveIn(nm);
        } else if (!strcmp(what, "restore")) {
            ok = Trash::restore(g_explorerView.sel);
        } else if (!strcmp(what, "empty")) {
            Trash::empty();
        } else if (!strcmp(what, "open")) {
            ok = g_explorerView.sel >= 0 && g_explorerView.sel < Photos::total();
            if (ok) chPhotoShowIndex(g_explorerView.sel);
        }
        changed = ok;
    }
    g_explorerView = v;
    // The window's icon follows the place (the taskbar button reads it before the window draws).
    XPCore::explorerIcon() = v.place == ExplorerCore::PLACE_PHOTOS ? XPCore::ICON_PICTURES
                           : v.place == ExplorerCore::PLACE_TRASH
                               ? (Trash::count() ? XPCore::ICON_TRASH_FULL : XPCore::ICON_TRASH)
                               : XPCore::ICON_COMPUTER;
    if (g_activeCount && !strcmp(kChannels[g_activeIdx[g_activePtr]].name, "Explorer")
        && g_menu.kind == XPCore::MENU_NONE && !g_contentDue) {
        if (changed || !chExplorerSet(v)) {
            drawActive();
            Taskbar::draw(barState(millis()), g_settings.clock24h);   // the bin's icon may have filled / emptied
            Cursor::overlay();
        } else {
            Cursor::overlay();
        }
    }
    return ok;
}

// A Dò mìn board from the app (POST /api/mines, P-2026-11-27.25): the app keeps the game; on screen
// (no menu over it) only the cells / face / LEDs that changed repaint.
void mainSetMines(const Mines::View& v) {
    const bool onScreen = g_activeCount && !strcmp(kChannels[g_activeIdx[g_activePtr]].name, "Mines")
                       && g_menu.kind == XPCore::MENU_NONE && !g_contentDue;
    chMinesSet(v, onScreen);
    if (onScreen) Cursor::overlay();
}

// A new / deleted wallpaper: repaint the desktop if it is on screen.
void mainWallpaperChanged() {
    if (g_activeCount && !strcmp(kChannels[g_activeIdx[g_activePtr]].name, "Home")) drawActive();
}

// ── Fetch scheduler ──────────────────────────────────────────────────────────

static bool jobEnabled(Job j) {
    switch (j) {
        case JOB_CLAUDE:  return !g_settings.claudeKey.isEmpty();
        case JOB_CODEX:   return !g_settings.codexToken.isEmpty();
        // Reset credits only once the token is known to work.
        case JOB_CODEX_RESETS: return g_codex.cred == Cred::OK || g_codex.cred == Cred::EXPIRING;
        // Weather feeds the Weather, Forecast and Home channels, and the app's weather tab
        // (/api/state "weather") whenever the weather skill is on.
        case JOB_WEATHER: return Weather::configured(g_settings)
                              && (g_settings.showWeather || g_settings.showHome || g_settings.showForecast
                                  || Skill::inList(g_settings.skillsOn.c_str(), "weather"));
        case JOB_STATUS_CLAUDE: return g_settings.showStatus && !g_settings.claudeKey.isEmpty();
        case JOB_STATUS_OPENAI: return g_settings.showStatus && !g_settings.codexToken.isEmpty();
        default: return false;
    }
}

static uint32_t jobIntervalMs(Job j) {
    switch (j) {
        case JOB_WEATHER:       return Weather::intervalMin(g_settings) * 60000UL;
        case JOB_CODEX_RESETS:  return 60UL * 60000UL;
        case JOB_STATUS_CLAUDE:
        case JOB_STATUS_OPENAI: return VendorStatus::kIntervalMin * 60000UL;
        default:                return g_settings.refreshMin * 60000UL;
    }
}

static const FetchPolicy::State& jobPolicy(Job j) {
    switch (j) {
        case JOB_CLAUDE:        return Api::claudePolicy();
        case JOB_CODEX:
        case JOB_CODEX_RESETS:  return Api::codexPolicy();
        case JOB_WEATHER:       return Weather::policy();
        case JOB_STATUS_CLAUDE: return VendorStatus::policy(VendorStatus::CLAUDE);
        default:                return VendorStatus::policy(VendorStatus::OPENAI);
    }
}

void mainTriggerRefresh() {
    uint32_t now = millis();
    for (auto& d : g_jobDue) d = now;
}

uint32_t mainNextFetchInMs() {
    uint32_t now = millis(), best = 0xFFFFFFFF;
    for (int j = 0; j < JOB_COUNT; j++) {
        if (!jobEnabled((Job)j)) continue;
        int32_t in = (int32_t)(g_jobDue[j] - now);
        uint32_t v = in > 0 ? (uint32_t)in : 0;
        if (v < best) best = v;
    }
    return best == 0xFFFFFFFF ? 0 : best;
}

// What a channel's draw() depends on, coarsely: a change means a full redraw
// (loading → data → error / credential-card transitions), otherwise tick()
// picks up new values.
static uint16_t usageShape(bool valid, const char* err, Cred cred) {
    return (valid ? 1 : 0) | (err[0] ? 2 : 0) | ((uint16_t)cred << 2);
}

static void runJob(Job j) {
    uint16_t before = 0, after = 0;
    bool ok = false;
    switch (j) {
        case JOB_CLAUDE:
            before = usageShape(g_claude.valid, g_claude.err, g_claude.cred);
            ok = Api::fetchClaude(g_settings, g_claude);
            Api::refreshCred(g_settings, g_claude, g_codex);
            after = usageShape(g_claude.valid, g_claude.err, g_claude.cred);
            break;
        case JOB_CODEX:
            before = usageShape(g_codex.valid, g_codex.err, g_codex.cred);
            ok = Api::fetchCodex(g_settings, g_codex);
            Api::refreshCred(g_settings, g_claude, g_codex);
            after = usageShape(g_codex.valid, g_codex.err, g_codex.cred);
            break;
        case JOB_CODEX_RESETS:
            ok = Api::fetchCodexResets(g_settings, g_codex);
            break;
        case JOB_WEATHER: {
            const WeatherData& w = Weather::snapshot();
            before = usageShape(w.valid, w.err, Cred::OK);
            ok = Weather::fetch(g_settings);
            after = usageShape(w.valid, w.err, Cred::OK);
            break;
        }
        case JOB_STATUS_CLAUDE: ok = VendorStatus::fetch(VendorStatus::CLAUDE); break;
        case JOB_STATUS_OPENAI: ok = VendorStatus::fetch(VendorStatus::OPENAI); break;
        default: break;
    }
    if (ok && (j == JOB_CLAUDE || j == JOB_CODEX)) UsageHistory::record(g_claude, g_codex);

    uint32_t now = millis();
    const FetchPolicy::State& pol = jobPolicy(j);
    // The resets job is best-effort: it never adopts the usage backoff.
    uint32_t waitMs = (ok || j == JOB_CODEX_RESETS) ? jobIntervalMs(j)
                         : (pol.waitS ? pol.waitS * 1000UL : jobIntervalMs(j));
    g_jobDue[j] = now + waitMs;
    g_lastRefresh = now;
    Serial.printf_P(PSTR("[sched] %s %s → next in %lus (heap=%u maxblk=%u)\n"), kJobName[j],
                  ok ? "ok" : "fail", (unsigned long)(waitMs / 1000),
                  ESP.getFreeHeap(), ESP.getMaxFreeBlockSize());
    refreshScreen(before != after);
}

static void schedulerTick(uint32_t now) {
    if (g_apMode || WiFi.status() != WL_CONNECTED) return;
    if (now - g_lastJobStart < 3000) return;
    for (int i = 0; i < JOB_COUNT; i++) {
        Job j = (Job)i;
        if (!jobEnabled(j) || (int32_t)(now - g_jobDue[j]) < 0) continue;
        // TLS drops the VLW font anyway (Api::tlsGetStream); drop it before
        // measuring. Its metric arrays (7 mallocs, ~2.8 KB with the 231-glyph
        // Vietnamese fonts) sit inside the big free block and made the gate
        // refuse forever (maxblk 18 K < 20 K) though the heap had room.
        if (j != JOB_WEATHER) Display::releaseFont();
        uint32_t blk = ESP.getMaxFreeBlockSize();
        uint32_t freeHeap = ESP.getFreeHeap();
        if (blk < g_minMaxBlk) g_minMaxBlk = blk;
        if (j != JOB_WEATHER && !FetchPolicy::tlsHeapOk(freeHeap, blk)) {
            // Our own memory, not the upstream: defer briefly, never count it
            // as a failure.
            g_jobDue[j] = now + 5000;
            g_heapRefusals++;
            Serial.printf_P(PSTR("[sched] %s deferred: maxblk=%u free=%u\n"), kJobName[j], blk, freeHeap);
            return;
        }
        g_lastJobStart = now;
        // Fetch activity: a 3-px dot in the bottom-right gap, cleared after.
        tft.fillRect(SCREEN_W - 5, 224, 3, 3, Theme::CORAL);
        runJob(j);
        tft.fillRect(SCREEN_W - 5, 224, 3, 3, Theme::BG);
        return;                                      // at most one job per pass
    }
}

// ── WiFi orchestration ───────────────────────────────────────────────────────

static void prepareSta(WiFiMode_t mode) {
    WiFi.persistent(false);
    WiFi.disconnect(true);
    WiFi.mode(WIFI_OFF);
    delay(150);
    WiFi.mode(mode);
    WiFi.setSleepMode(WIFI_NONE_SLEEP);
    WiFi.setOutputPower(20.5);
    WiFi.setAutoReconnect(true);
    WiFi.hostname(deviceHost());
    delay(100);
}

static bool tryConnect() {
    if (g_settings.wifiSSID.isEmpty()) return false;

    // Two clean attempts of 30 s each, then the setup AP comes up. The AP keeps
    // retrying the saved network in the background (see apStrandRetry), so a
    // router that is simply slow to boot no longer strands the device.
    constexpr int ATTEMPTS    = 2;
    constexpr int ATTEMPT_TICKS = 60;      // 60 × 500 ms = 30 s per attempt

    for (int attempt = 1; attempt <= ATTEMPTS; attempt++) {
        prepareSta(WIFI_STA);
        Serial.printf_P(PSTR("[wifi] attempt %d/%d: connecting to '%s'\n"), attempt, ATTEMPTS, g_settings.wifiSSID.c_str());
        WiFi.begin(g_settings.wifiSSID.c_str(), g_settings.wifiPass.c_str());

        for (int i = 0; i < ATTEMPT_TICKS; i++) {
            if (WiFi.status() == WL_CONNECTED) {
                Serial.printf_P(PSTR("[wifi] connected, IP=%s, RSSI=%d\n"), WiFi.localIP().toString().c_str(), WiFi.RSSI());
                return true;
            }
            Display::drawConnecting(g_settings.wifiSSID.c_str(), i + (attempt - 1) * ATTEMPT_TICKS);
            delay(500);
        }
        Serial.printf_P(PSTR("[wifi] attempt %d timed out (status=%d), backing off...\n"), attempt, WiFi.status());
        delay(2000);
    }
    Serial.println(F("[wifi] all attempts failed — falling back to AP mode"));
    return false;
}

static void startAPMode() {
    g_apMode = true;
    WiFi.mode(WIFI_AP);
    WiFi.softAP(SETUP_AP_SSID);
    Display::drawSetupMode(SETUP_AP_SSID, WiFi.softAPIP().toString().c_str());
}

// STA is up: mDNS, time, and every fetch job due now.
static void onStaUp() {
    MDNS.begin(deviceHost());
    MDNS.addService("http", "tcp", 80);      // lets the Android app find it via NSD
    // Remember each SNTP sync (the Clock window's Internet tab, P-2026-11-26.22).
    settimeofday_cb([]() { g_ntpLast = (uint32_t)time(nullptr); });
    configTime(0, 0, "pool.ntp.org", "time.google.com");
    Storage::applyTimezone(g_settings);
    for (int i = 0; i < 20 && !timeSynced(); i++) delay(250);
    mainTriggerRefresh();
}

// Stranded in setup-AP mode with saved credentials (e.g. the router was down
// at boot): every 180 s, try the saved network for 20 s while keeping the AP
// up. On success, drop the AP and carry on as a normal boot — no reboot.
static void apStrandRetry(uint32_t now) {
    static uint32_t lastTry = 0, tryStart = 0;
    if (!g_apMode || g_settings.wifiSSID.isEmpty()) return;
    if (tryStart == 0) {
        if (lastTry != 0 && now - lastTry < 180000UL) return;
        if (lastTry == 0) { lastTry = now; return; }   // first window starts at AP entry
        Serial.println(F("[wifi] AP-strand: retrying saved network"));
        WiFi.mode(WIFI_AP_STA);
        WiFi.begin(g_settings.wifiSSID.c_str(), g_settings.wifiPass.c_str());
        tryStart = now;
        return;
    }
    if (WiFi.status() == WL_CONNECTED && WiFi.localIP() != IPAddress(0U)) {
        Serial.printf_P(PSTR("[wifi] AP-strand: joined, IP=%s\n"), WiFi.localIP().toString().c_str());
        WiFi.softAPdisconnect(true);
        WiFi.mode(WIFI_STA);
        g_apMode = false;
        tryStart = 0;
        onStaUp();
        refreshScreen(true);
        return;
    }
    if (now - tryStart >= 20000UL) {
        WiFi.disconnect(false);
        WiFi.mode(WIFI_AP);
        tryStart = 0;
        lastTry = now;
    }
}

// ── Device notices ───────────────────────────────────────────────────────────
//
// Short cards (12 s) for things the user should act on: a credential that
// stopped working, a token about to expire, an unused reset credit about to
// lapse. They go through the attention queue as `sys:*` warnings/errors.
// Rate-limited per (provider, reason); deferred, not dropped, at night.

static CredState::NoticeLog g_noticeLog[2];          // 0 = Claude, 1 = Codex

static bool notice(int prov, CredState::NoticeReason r, const char* title, const char* value,
                   const char* sub, uint16_t color) {
    time_t now = time(nullptr);
    if (!CredState::noticeDue(g_noticeLog[prov], r, now)) return false;
    Attention::Item it;
    snprintf_P(it.id, sizeof(it.id), PSTR("sys:%d:%d"), prov, (int)r);
    it.kind = color == Theme::CORAL ? Attention::K_ERROR : Attention::K_WARNING;
    Attention::copyStr(it.title, sizeof(it.title), title);
    Attention::copyStr(it.value, sizeof(it.value), value);
    Attention::copyStr(it.body,  sizeof(it.body),  sub);
    uint32_t an = AttentionQueue::now();
    it.expires = an + 12;
    it.interruptUntil = an + 12;
    if (AttentionQueue::put(it) < 0) return false;
    g_noticeLog[prov].last[r] = now;
    Serial.printf_P(PSTR("[notice] %s %s\n"), title, value);
    return true;
}

static void noticesTick() {
    if (!timeSynced() || nightNow()) return;
    time_t now = time(nullptr);
    char sub[40]; snprintf(sub, sizeof(sub), "cập nhật tại %s.local", deviceHost());
    struct P { const char* title; Cred cred; time_t exp; const ResetGrant* g; } ps[2] = {
        {"KHÓA CLAUDE", g_claude.cred, 0,              &g_claude.resets},
        {"TOKEN CODEX", g_codex.cred,  g_codex.jwtExp, &g_codex.resets},
    };
    for (int i = 0; i < 2; i++) {
        const P& p = ps[i];
        if (CredState::bad(p.cred)) {
            const char* v = p.cred == Cred::EXPIRED ? "HẾT HẠN"
                          : p.cred == Cred::REJECTED ? "BỊ TỪ CHỐI" : "BỊ CHẶN";
            const char* s2 = p.cred == Cred::BLOCKED ? "khóa vẫn tốt - đang thử lại" : sub;
            if (notice(i, CredState::NOTICE_BAD, p.title, v, s2, credColor(p.cred))) return;
        } else if (p.cred == Cred::EXPIRING) {
            long left = (long)(p.exp - now);
            char v[24];
            if (left >= 86400L) snprintf(v, sizeof(v), "CÒN %ld NGÀY", left / 86400L);
            else                snprintf(v, sizeof(v), "CÒN %ld GIỜ", left / 3600L > 0 ? left / 3600L : 1);
            if (notice(i, CredState::NOTICE_EXPIRING, p.title, v, sub, Theme::AMBER)) return;
        }
        // An unused limit-reset credit that lapses within 48 h.
        if (p.g->left && p.g->endsAt > now && p.g->endsAt - now < 48L * 3600L) {
            char v[24]; snprintf(v, sizeof(v), "%u LƯỢT", p.g->left);
            char d[8];  TimeUtil::shortDuration((long)(p.g->endsAt - now), d, sizeof(d));
            char s3[40]; snprintf(s3, sizeof(s3), "chưa dùng - hết hạn sau %s", d);
            const char* who = i == 0 ? "CLAUDE" : "CODEX";
            if (notice(i, CredState::NOTICE_RESET, who, v, s3, Theme::AMBER)) return;
        }
    }
}

// ── Setup / loop ─────────────────────────────────────────────────────────────

void setup() {
    g_heapTotal = ESP.getFreeHeap();     // Task Manager: the heap's size (nothing allocated yet)
    Serial.begin(115200);
    Serial.println(F("\n=== glimmer v" FW_VERSION " ==="));

    Display::begin();
    Storage::begin();          // mount LittleFS first: the boot logo's fonts live there
    Display::drawSplash("đang khởi động...");
    Display::splashWait(400);

    g_settings = Storage::load();
    Display::setBrightness(g_settings.brightness);
    Display::setInvert(g_settings.invertDisplay);
    Weather::begin();
    UsageHistory::begin();
    AttentionQueue::projectsBegin();
    Photos::begin();
    Wallpaper::begin();
    Wallpaper::setMode(g_settings.wallpaperMode);   // P-2026-11-28.30
    Trash::begin();                                 // P-2026-11-28.32 (after Photos: it re-adopts nothing)
    Api::refreshCred(g_settings, g_claude, g_codex);

    Display::splashStep(millis() / 200);
    if (!tryConnect()) {
        startAPMode();
    } else {
        // Theo XP thật the welcome screen stays up while the session loads
        // (time sync, first fetches) — no boot screen in between.
        Display::drawConnecting(g_settings.wifiSSID.c_str(), 0);
        onStaUp();
    }

    Web::begin(g_settings);
    Cursor::begin();

    if (!g_apMode) {
        applyBrightness();
        refreshScreen(true);
    }
}

void loop() {
    Web::loop();
    if (!g_apMode) MDNS.update();

    uint32_t now = millis();

    apStrandRetry(now);

    // WiFi health check. "Healthy" means associated AND holding a DHCP lease.
    // A DHCP lease-renewal failure (common after ~10-12 h) leaves the link
    // associated — WiFi.status() stays WL_CONNECTED — but with IP 0.0.0.0, so
    // a status-only check never notices and the device silently stops talking
    // to the network. We treat "no IP" as lost too.
    //
    // Recovery is ALWAYS in-place (full RF reset, mirroring tryConnect()) and
    // never ESP.restart(): a software restart does NOT reset the ESP8266 WiFi
    // RF/calibration, so the post-restart connect reliably fails and the device
    // drops into AP mode — stuck there until a physical power-cycle. Retrying in
    // STA forever recovers cleanly whenever WiFi/DHCP returns. The 30 s arm
    // debounces brief glitches so a momentary blip doesn't bounce the radio.
    // (An OTA upload is handled inside a single Web::loop() call, so this
    // never fires mid-upload.)
    static uint32_t lastWifiCheck = 0;
    static uint32_t wifiRetrySince = 0;
    if (!g_apMode && now - lastWifiCheck >= 10000) {
        lastWifiCheck = now;
        bool healthy = (WiFi.status() == WL_CONNECTED)
                    && (WiFi.localIP() != IPAddress(0U));
        if (!healthy) {
            if (wifiRetrySince == 0) {
                wifiRetrySince = now;
                Serial.printf_P(PSTR("[wifi] unhealthy (status=%d ip=%s), waiting...\n"), WiFi.status(), WiFi.localIP().toString().c_str());
            } else if (now - wifiRetrySince >= 30000) {
                Serial.println(F("[wifi] reconnecting (full RF reset)..."));
                prepareSta(WIFI_STA);
                WiFi.begin(g_settings.wifiSSID.c_str(), g_settings.wifiPass.c_str());
                wifiRetrySince = now;
            }
        } else {
            if (wifiRetrySince != 0) {
                Serial.println(F("[wifi] reconnected"));
                mainTriggerRefresh();
            }
            wifiRetrySince = 0;
        }
    }

    schedulerTick(now);

    // Attention queue: expire once a second; a new interrupt card (or one that
    // became more urgent) takes the screen right away; when nothing holds the
    // screen any more, the rotation resumes immediately.
    static uint32_t lastExpire = 0;
    if (now - lastExpire >= 1000UL) {
        lastExpire = now;
        AttentionQueue::expire();
        AttentionQueue::projectsTick();
        static bool wasIdle = false;                 // idle dim: react within 1 s
        bool idle = idleNow();
        if (idle != wasIdle) { wasIdle = idle; applyBrightness(); }
        static bool wasWake = false;                 // screen off: a waking card lights it
        bool wake = g_screenOff && chAttentionWakesScreen();
        if (wake != wasWake) { wasWake = wake; applyBrightness(); }
    }
    static bool wasAttention = false;
    ChannelCtx ctx = makeCtx();
    bool attention = !g_apMode && chAttentionEnabled(ctx);
    bool interrupt = AttentionQueue::takeInterrupt();
    const char* curName = g_activeCount ? kChannels[g_activeIdx[g_activePtr]].name : "";
    if (attention && (!wasAttention || (interrupt && strcmp(curName, "Attention")))) {
        mainShowChannel("Attention");
        applyBrightness();                   // a dark night wakes for an urgent card
    } else if (!attention && wasAttention) {
        recomputeActive();
        drawActive();
        applyBrightness();
        markSlide(now);
    }
    wasAttention = attention;

    // Every 10 s: night window, staleness and status badges can change what
    // should be on screen (night face in/out) or how it looks (dimmed data).
    static uint32_t lastState = 0;
    static uint32_t stateSig  = 0xFFFFFFFF;
    if (!g_apMode && now - lastState >= 10000UL) {
        lastState = now;
        // Credential state tracks the clock too (a JWT crossing EXPIRING/EXPIRED).
        Api::refreshCred(g_settings, g_claude, g_codex);
        uint32_t sig = (nightNow() ? 1 : 0)
                     | (Api::isStale(g_claude.lastOk, g_settings) ? 2 : 0)
                     | (Api::isStale(g_codex.lastOk, g_settings)  ? 4 : 0)
                     | (Weather::isStale(g_settings)              ? 8 : 0)
                     | ((uint32_t)g_claude.cred << 4) | ((uint32_t)g_codex.cred << 8);
        if (sig != stateSig) {
            // Night and credential changes alter what draw() paints; staleness
            // is handled by the channels' tick().
            bool redraw = ((sig ^ stateSig) & 0xFF1) != 0;
            stateSig = sig;
            applyBrightness();
            refreshScreen(redraw);
        }
    }

    // Once a minute: device notices (token expiring/expired, reset credit
    // about to lapse) as short cards — never at night, never over a user card.
    static uint32_t lastNotice = 0;
    if (!g_apMode && now - lastNotice >= 60000UL) {
        lastNotice = now;
        noticesTick();
    }

    // No channel rotation (P-2026-11-26.14). Boot lands on the desktop as soon
    // as it can show (it needs the clock); a Photo window steps its photos.
    if (!g_apMode && g_wantHome && g_activeCount
        && strcmp(kChannels[g_activeIdx[g_activePtr]].name, "Attention")) {
        for (int i = 0; i < g_activeCount; i++)
            if (!strcmp(kChannels[g_activeIdx[i]].name, "Home")) {
                g_wantHome = false;
                if (i != g_activePtr) { g_activePtr = i; drawActive(); markSlide(now); }
                break;
            }
    }
    if (!g_apMode && photoSlideshow() && g_menu.kind == XPCore::MENU_NONE && now - g_lastSlide >= slideMs()) {
        markSlide(now);
        chPhotoRequestStep();
        drawActive();
    }

    // Partial-redraw tick — channels with a tick() callback are called at 5 Hz
    // (every 200 ms) to update only the regions that changed. NO full redraw
    // here — channels handle their own minimal repaints (see channel.h's
    // PARTIAL REDRAW DISCIPLINE comment).
    powerTick(now);
    const bool booting = Control::powerScreen(g_power.p);   // đang tắt máy / boot / welcome own the panel
    if (!booting) drawDueContent(now);
    static uint32_t lastTick = 0;
    if (!g_apMode && !booting && g_activeCount > 0 && !g_contentDue && now - lastTick >= 200) {
        lastTick = now;
        auto tickFn = kChannels[g_activeIdx[g_activePtr]].tick;
        // A context menu is over the window: nothing may paint under / over it.
        if (tickFn && g_menu.kind == XPCore::MENU_NONE) { tickFn(makeCtx()); Cursor::overlay(); }
    }

    // Taskbar ~4 Hz: repaints only a button whose window / look / badge
    // changed, and the tray clock once a minute (no-op on Night).
    static uint32_t lastBar = 0;
    if (!g_apMode && !booting && g_menu.kind != XPCore::MENU_TURNOFF && now - lastBar >= 250) {
        lastBar = now;
        Taskbar::update(barState(now), g_settings.clock24h);
        Cursor::overlay();
    }

    // Mouse cursor (R-DK-17): the app's latest position, drawn on top.
    if (!g_apMode) {
        Cursor::poll(now);
        Cursor::setAllowed(cursorAllowed(), repaintRect);
        if (!booting) {
            inputTick();
            pointerTick();
            // Mouse v2: the device picks the cursor's shape (XP's hand over what a click acts on).
            if (Cursor::deviceDriven() && Cursor::mouseMode())
                Cursor::setShape(InputCore::shapeAt(inputScene(), Cursor::x(), Cursor::y()));
        }
        Cursor::step(now, repaintRect);
    }

    // Task Manager's samples (P-2026-11-28.28): once a second — CPU = the share not spent in the delay below.
    static uint32_t perfAt = 0, perfUs = 0;
    if (now - perfAt >= 1000UL) {
        const uint32_t us = micros();
        if (perfAt) {
            g_perf.cpu.push(Perf::cpuPct(g_idleUs, us - perfUs));
            g_perf.mem.push(Perf::memPct(ESP.getFreeHeap(), g_heapTotal));
            g_perf.net.push(WiFi.status() == WL_CONNECTED ? Perf::rssiPct(WiFi.RSSI()) : 0);
            g_perfSeq++;
        }
        perfAt = now;
        perfUs = us;
        g_idleUs = 0;
    }
    const uint32_t idle0 = micros();
    delay(10);
    g_idleUs += micros() - idle0;
}

// Settings were saved from the web UI: apply what can change at runtime.
void mainSettingsChanged() {
    // A newly pasted key/token is fetched right away, not at the next interval.
    if (Api::refreshCred(g_settings, g_claude, g_codex)) mainTriggerRefresh();
    Display::setInvert(g_settings.invertDisplay);
    Wallpaper::setMode(g_settings.wallpaperMode);      // P-2026-11-28.30
    Storage::applyTimezone(g_settings);
    applyBrightness();
    if (!g_apMode) refreshScreen(true);
}
