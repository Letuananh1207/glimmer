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
#include "clock_core.h"
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
    { "Photo",    chPhotoEnabled,    chPhotoDraw,    nullptr,        "photo" },
    { "Weather",  chWeatherEnabled,  chWeatherDraw,  chWeatherTick,  "weather" },
    { "Forecast", chForecastEnabled, chForecastDraw, chForecastTick, "weather" },
    { "Clock",    chClockEnabled,    chClockDraw,    chClockTick,    "clock" },
    { "Info",     chInfoEnabled,     chInfoDraw,     chInfoTick     },
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
// The Clock window as the app touched it (P-2026-11-26.22) and the last SNTP sync.
static ClockCore::View  g_clockView;
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
uint32_t mainNtpLast()      { return g_ntpLast; }
const Control::Windows& mainWindows() { return g_windows; }
const Control::Menu&    mainMenu()    { return g_menu; }
bool     mainScreenOn()     { return !g_screenOff; }
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
    return !g_nightFace && g_activeCount && Photos::count() > 1
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

// The open menu: the Start menu (P-2026-11-26.20) or a context menu (P-2026-11-26.14).
static void paintMenu() {
    if (g_menu.kind == XPCore::MENU_START) XPStart::draw(g_menu, g_settings.skillsOn.c_str());
    else XPMenu::draw(g_menu);
}

// A context menu stays over the screen it was opened on (not on Night / cards).
static void drawMenuOver(const char* name) {
    if (g_menu.kind == XPCore::MENU_NONE) return;
    if (XPCore::buttonFor(name) == XPCore::BTN_NO_BAR || !strcmp(name, "Attention")) g_menu = Control::Menu();
    else paintMenu();
}

static void drawActive() {
    g_contentDue = false;
    const bool afterSystem = Display::systemScreenShown();
    if (g_activeCount == 0) {
        noteDrawn(nullptr);
        g_restoring = g_minimizing = XPCore::PROG_NONE;
        XP::drawNoChannels();                               // XP-NoChannels
        Taskbar::draw(barState(millis()), g_settings.clock24h);
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
}

// 4. The content of a window whose empty frame is up (see drawActive).
static void drawDueContent(uint32_t now) {
    if (!g_contentDue || (int32_t)(now - g_contentAt) < 0 || !g_activeCount) return;
    g_contentDue = false;
    ChannelCtx ctx = makeCtx();
    const char* name = kChannels[g_activeIdx[g_activePtr]].name;
    kChannels[g_activeIdx[g_activePtr]].draw(ctx);
    drawMenuOver(name);
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
            g_activePtr = i;
            g_menu = Control::Menu();
            g_wantHome = false;
            const int p = XPCore::progOf(kChannels[g_activeIdx[i]].name);
            // A minimized window coming back up zooms from its button (XP).
            if (p >= 0 && (g_windows.minMask >> p & 1)) g_restoring = (int8_t)p;
            Control::adopt(g_windows, p);
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
    applyBrightness();
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
    if (selChanged && g_activeCount && !strcmp(kChannels[g_activeIdx[g_activePtr]].name, "Home")) drawActive();
}

// A context menu (POST /api/menu): drawn over the screen; closing it repaints
// what was under it (the channel's draw()). Not over Night / cards / setup.
bool mainSetMenu(const Control::Menu& m) {
    if (g_apMode || !g_activeCount) return false;
    const char* name = kChannels[g_activeIdx[g_activePtr]].name;
    if (m.kind != XPCore::MENU_NONE
        && (XPCore::buttonFor(name) == XPCore::BTN_NO_BAR || !strcmp(name, "Attention"))) return false;
    const bool wasOpen = g_menu.kind != XPCore::MENU_NONE;
    const bool startToStart = wasOpen && g_menu.kind == XPCore::MENU_START && m.kind == XPCore::MENU_START;
    g_menu = m;
    if (m.kind != XPCore::MENU_NONE) {
        // Start → Start (All Programs opened / closed): the menu covers its own area.
        if (wasOpen && !startToStart) drawActive();   // moved: repaint under the old one first
        else paintMenu();
    } else if (wasOpen) {
        drawActive();
    }
    if (Taskbar::shown()) Taskbar::update(barState(millis()), g_settings.clock24h);   // start button
    return true;
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
    WiFi.hostname(MDNS_HOSTNAME);
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
    MDNS.begin(MDNS_HOSTNAME);
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
    char sub[40]; snprintf(sub, sizeof(sub), "cập nhật tại %s.local", MDNS_HOSTNAME);
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
        drawActive();
    }

    // Partial-redraw tick — channels with a tick() callback are called at 5 Hz
    // (every 200 ms) to update only the regions that changed. NO full redraw
    // here — channels handle their own minimal repaints (see channel.h's
    // PARTIAL REDRAW DISCIPLINE comment).
    drawDueContent(now);
    static uint32_t lastTick = 0;
    if (!g_apMode && g_activeCount > 0 && !g_contentDue && now - lastTick >= 200) {
        lastTick = now;
        auto tickFn = kChannels[g_activeIdx[g_activePtr]].tick;
        // A context menu is over the window: nothing may paint under / over it.
        if (tickFn && g_menu.kind == XPCore::MENU_NONE) tickFn(makeCtx());
    }

    // Taskbar ~4 Hz: repaints only a button whose window / look / badge
    // changed, and the tray clock once a minute (no-op on Night).
    static uint32_t lastBar = 0;
    if (!g_apMode && now - lastBar >= 250) {
        lastBar = now;
        Taskbar::update(barState(now), g_settings.clock24h);
    }

    delay(10);
}

// Settings were saved from the web UI: apply what can change at runtime.
void mainSettingsChanged() {
    // A newly pasted key/token is fetched right away, not at the next interval.
    if (Api::refreshCred(g_settings, g_claude, g_codex)) mainTriggerRefresh();
    Display::setInvert(g_settings.invertDisplay);
    Storage::applyTimezone(g_settings);
    applyBrightness();
    if (!g_apMode) refreshScreen(true);
}
