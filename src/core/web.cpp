// SmallTV web server.
//
// Static UI is served from LittleFS at /web/* (gzip-preferred). C++ side
// exposes a clean JSON API:
//   GET  /api/state    — live device state
//   GET  /api/settings — current settings (secrets masked as "***")
//   POST /api/settings — partial update; merges; optionally restarts
//   GET  /api/export   — raw config.json
//   POST /api/import   — replace config.json + restart
//   POST /api/factory-reset
//   POST /push         — attention card (see attention_json.h); GET lists, /push/clear removes
//   POST /hook         — trimmed agent hook event (tools/agents/glimmer-hook.sh)
//   POST /api/channel  — {"name":…[,"zoom":"min"]} show a channel (zoom: the app's _ button, the window
//                        zooms down) | {"action":"next"|"prev"|"pause"|"resume"}
//   POST /api/screen   — {"on":false|true} backlight off / on now (RAM only)
//   POST /api/windows  — {"open":[…],"top":…|null,"min":[…],"sel":…|null} the app's open windows (RAM only)
//   POST /api/menu     — {"kind":"desktop"|"window"|"none","x","y","minimized"} context menu (RAM only)
//   POST /api/balloon  — {"show":true|false} desktop tray balloon: show 10 s / hide now (RAM only)
//   POST /mcp          — JSON-RPC: push_card, clear_card, list_cards, get_state, show/next_channel
//   GET  /api/photos   — photos on the device + limits; POST uploads one (multipart field
//                        "photo", baseline JPEG 188×188); DELETE /api/photos?name=p3.jpg
//   GET  /api/wallpaper — desktop wallpaper state + limits; POST uploads it (multipart field
//                        "wallpaper", baseline JPEG 240×214 ≤ 40 KB); DELETE removes it
//   The API token (when set) guards /push*, /hook, /mcp, /api/refresh, /api/channel,
//   /api/screen, /api/windows, /api/menu, /api/balloon, photo and wallpaper upload / delete.
//   POST /update       — OTA firmware + filesystem (ESP8266HTTPUpdateServer)

#include "web.h"
#include "display.h"
#include "api.h"
#include "weather.h"
#include "vendor_status.h"
#include "attention.h"
#include "attention_json.h"
#include "skill_core.h"
#include "photos.h"
#include "wallpaper.h"
#include "control_core.h"
#include <ESP8266HTTPUpdateServer.h>
#include <ESP8266WebServer.h>
#include <ESP8266WiFi.h>
#include <LittleFS.h>

static ESP8266WebServer        server(80);
static ESP8266HTTPUpdateServer updater;
static Settings*               pSettings = nullptr;

// Defined in src/main.cpp
extern uint32_t mainApprovalTtlS();
extern bool     mainAgentDoneCards();

// Defined in src/main.cpp
extern const char* mainActiveChannelName();
extern int         mainEnabledCount();
extern int         mainTotalCount();
extern void        mainTriggerRefresh();
extern const char* mainEnabledChannelName(int idx);
extern const ClaudeData* mainClaudeData();
extern const CodexData*  mainCodexData();
extern bool        mainNightFace();
extern uint32_t    mainHeapRefusals();
extern uint32_t    mainMinMaxBlock();
extern uint32_t    mainNextFetchInMs();
extern bool        mainShowChannel(const char* name);
extern void        mainNoteMinimize();
extern void        mainNextChannel();
extern void        mainPrevChannel();
extern void        mainSetPaused(bool paused);
extern bool        mainPaused();
extern void        mainSetScreenOn(bool on);
extern bool        mainScreenOn();
extern void        mainSlideTiming(uint32_t& totalMs, uint32_t& leftMs);
extern void        mainWallpaperChanged();
extern const Control::Windows& mainWindows();
extern void        mainSetWindows(const Control::Windows& w);
extern const Control::Menu& mainMenu();
extern bool        mainSetMenu(const Control::Menu& m);
extern bool        mainSetBalloon(bool show);
extern bool        mainBalloonShown();
extern void        mainSettingsChanged();

// ── Helpers ─────────────────────────────────────────────────────────────────

static bool checkAuth() {
    if (!pSettings || pSettings->apiToken.isEmpty()) return true;
    if (!server.hasHeader("Authorization")) return false;
    return server.header("Authorization") == ("Bearer " + pSettings->apiToken);
}

static const char* contentTypeFor(const String& path) {
    if (path.endsWith(".html") || path.endsWith(".html.gz")) return "text/html";
    if (path.endsWith(".css")  || path.endsWith(".css.gz"))  return "text/css";
    if (path.endsWith(".js")   || path.endsWith(".js.gz"))   return "application/javascript";
    if (path.endsWith(".json") || path.endsWith(".json.gz")) return "application/json";
    if (path.endsWith(".svg"))  return "image/svg+xml";
    if (path.endsWith(".ico"))  return "image/x-icon";
    if (path.endsWith(".png"))  return "image/png";
    return "application/octet-stream";
}

// Serve any file under /web/, preferring its .gz variant if present.
// Returns true if the URL was handled.
static bool serveStatic(const String& uri) {
    String path = "/web";
    path += (uri == "/" ? String("/index.html") : uri);
    String gz = path + ".gz";

    bool useGz = LittleFS.exists(gz);
    String actual = useGz ? gz : path;
    if (!useGz && !LittleFS.exists(path)) return false;

    File f = LittleFS.open(actual, "r");
    if (!f) return false;
    // streamFile() auto-adds Content-Encoding: gzip when filename ends in .gz
    server.sendHeader("Cache-Control", "public, max-age=300");
    server.streamFile(f, contentTypeFor(path));
    f.close();
    return true;
}

// ── JSON API ────────────────────────────────────────────────────────────────

static String maskSecret(const String& s) {
    return s.isEmpty() ? String("") : String("***");
}

static void sourceJson(JsonObject o, const FetchPolicy::State& p, bool valid, const char* err) {
    o[F("valid")]     = valid;
    o[F("last_ok")]   = (uint32_t)p.lastOk;
    o[F("code")]      = p.lastCode;
    o[F("fails")]     = p.fails;
    o[F("auth_bad")]  = p.authLatched;
    o[F("blocked")]   = FetchPolicy::blocked(p);
    o[F("backoff_s")] = p.waitS;
    o[F("err")]       = err;
}

static void credJson(JsonObject o, Cred cred, time_t expiresAt, const ResetGrant& g) {
    o[F("cred")] = CredState::name(cred);
    if (expiresAt) o[F("expires_at")] = (uint32_t)expiresAt;
    if (g.left) {
        JsonObject r = o[F("resets")].to<JsonObject>();
        r[F("left")]    = g.left;
        r[F("usable")]  = g.usable;
        r[F("ends_at")] = (uint32_t)g.endsAt;
        r[F("title")]   = g.title;
    }
}

static void handleApiState() {
    JsonDocument d;
    d[F("fw")]                  = FW_VERSION;
    d[F("wifi")]                = WiFi.status() == WL_CONNECTED ? "connected" : "ap";
    d[F("ip")]                  = WiFi.status() == WL_CONNECTED
                                 ? WiFi.localIP().toString() : WiFi.softAPIP().toString();
    d[F("ssid")]                = WiFi.SSID();
    d[F("rssi")]                = WiFi.RSSI();
    d[F("uptime_s")]            = (uint32_t)(millis() / 1000);
    d[F("heap")]                = ESP.getFreeHeap();
    d[F("maxblk")]              = ESP.getMaxFreeBlockSize();
    d[F("cpu_mhz")]             = ESP.getCpuFreqMHz();
    d[F("min_maxblk")]          = mainMinMaxBlock();
    d[F("heap_refusals")]       = mainHeapRefusals();
    d[F("reset_reason")]        = ESP.getResetReason();
    d[F("build")]               = __DATE__ " " __TIME__;
    d[F("active_channel")]      = mainActiveChannelName();
    // Skills: every one this firmware has + the enabled ones (taskbar buttons, R-SK-1/2). "skill"
    // = the first enabled, for apps before 2026-11-25.3 (they hide the switch without it, R-SK-4).
    {
        const char* on = pSettings ? pSettings->skillsOn.c_str() : Skill::kDefaultOn;
        d[F("skill")] = Skill::first(on);
        JsonArray sk = d[F("skills")].to<JsonArray>();
        for (int i = 0; i < Skill::kCount; i++) sk.add(Skill::kAll[i]);
        JsonArray so = d[F("skills_on")].to<JsonArray>();
        for (int i = 0; i < Skill::kCount; i++)
            if (Skill::inList(on, Skill::kAll[i])) so.add(Skill::kAll[i]);
    }
    d[F("night_face")]          = mainNightFace();
    // App remote control (design 2026-11-26.5): rotation paused (temporary), backlight
    // on/off as commanded (a waking card lights an "off" screen without changing it),
    // the active slide's length and what is left of it (both 0 when nothing rotates).
    d[F("paused")]              = mainPaused();
    d[F("screen_on")]           = mainScreenOn();
    {
        uint32_t total, left;
        mainSlideTiming(total, left);
        d[F("slide_ms")]        = total;
        d[F("slide_left_ms")]   = left;
    }
    // Open windows the app sent (P-2026-11-26.14) and the context menu on screen.
    {
        const Control::Windows& w = mainWindows();
        JsonObject wo = d[F("windows")].to<JsonObject>();
        JsonArray op = wo[F("open")].to<JsonArray>();
        JsonArray mn = wo[F("min")].to<JsonArray>();
        for (int i = 0; i < w.n; i++) {
            op.add(XPCore::progName(w.open[i]));
            if (w.minMask >> w.open[i] & 1) mn.add(XPCore::progName(w.open[i]));
        }
        if (w.top >= 0) wo[F("top")] = XPCore::progName(w.top); else wo[F("top")] = nullptr;
        if (w.sel >= 0) wo[F("sel")] = XPCore::progName(w.sel); else wo[F("sel")] = nullptr;
        const XPCore::MenuKind k = mainMenu().kind;
        d[F("menu")] = k == XPCore::MENU_DESKTOP ? "desktop" : k == XPCore::MENU_WINDOW ? "window" : "none";
        d[F("balloon")] = mainBalloonShown();      // desktop tray balloon up now (P-2026-11-26.15)
    }
    d[F("photos")]              = Photos::count();
    d[F("wallpaper")]           = Wallpaper::present();
    d[F("next_fetch_s")]        = mainNextFetchInMs() / 1000;
    d[F("claude_configured")]   = pSettings && !pSettings->claudeKey.isEmpty();
    d[F("codex_configured")]    = pSettings && !pSettings->codexToken.isEmpty();
    d[F("weather_configured")]  = pSettings && Weather::configured(*pSettings);
    // Diagnostics for the cold-boot Claude parse failure.
    d[F("claude_http")]         = Api::lastClaudeHttp();
    d[F("claude_parse")]        = Api::lastClaudeParse();
    if (const ClaudeData* cd = mainClaudeData()) {
        d[F("claude_err")]      = cd->err;
        d[F("claude_valid")]    = cd->valid;
        // Usage for the companion app (% USED, like the screen; epochs for
        // the resets so the app counts down itself). -1 = unknown.
        JsonObject u = d[F("claude_usage")].to<JsonObject>();
        u[F("session_used")]  = cd->sessionPct < 0 ? -1 : (int)(100.0f - cd->sessionPct + 0.5f);
        u[F("weekly_used")]   = cd->weeklyPct  < 0 ? -1 : (int)(100.0f - cd->weeklyPct  + 0.5f);
        u[F("session_reset")] = (uint32_t)cd->sessionReset;
        u[F("weekly_reset")]  = (uint32_t)cd->weeklyReset;
        u[F("last_ok")]       = (uint32_t)cd->lastOk;
        u[F("stale")]         = pSettings ? Api::isStale(cd->lastOk, *pSettings) : false;
        u[F("cred")]          = CredState::name(cd->cred);
    }
    d[F("time")] = (uint32_t)time(nullptr);     // device clock (epoch; < 1e9 = not synced)
    // Weather for the app's weather tab (design 2026-11-25.3): now + today and 3 days.
    // Celsius always (the app converts); -999 = unknown. Absent until configured.
    if (pSettings && Weather::configured(*pSettings)) {
        const WeatherData& w = Weather::snapshot();
        JsonObject wo = d[F("weather")].to<JsonObject>();
        wo[F("valid")]    = w.valid;
        wo[F("temp_c")]   = w.tempC;
        wo[F("feels_c")]  = w.feelsC;
        wo[F("code")]     = w.code;
        wo[F("desc")]     = Weather::describe(w.code);
        wo[F("is_day")]   = w.isDay;
        wo[F("humidity")] = w.humidity;
        wo[F("wind_kmh")] = w.windKmh;
        wo[F("last_ok")]  = (uint32_t)w.lastOk;
        wo[F("stale")]    = Weather::isStale(*pSettings);
        wo[F("err")]      = w.err;
        JsonArray days = wo[F("days")].to<JsonArray>();
        for (const WeatherDay& wd : w.forecast) {
            JsonObject o = days.add<JsonObject>();
            o[F("tmin")] = wd.tmin; o[F("tmax")] = wd.tmax; o[F("code")] = wd.code;
            o[F("desc")] = Weather::describe(wd.code);
        }
    }
    // Project board (what the Claude screen's bottom rows show), for
    // diagnosing "no project activity": empty = no hook events arrived.
    {
        const Projects::Board& pb = AttentionQueue::projects();
        uint32_t pnow = AttentionQueue::now();
        static const char* const kSt[] = {"approval", "input", "error", "working", "done"};
        // One row per project (sessions merged, most urgent wins) — what the
        // screen shows; "sessions" = how many agent sessions are behind it.
        JsonArray pa = d[F("projects")].to<JsonArray>();
        int ord[Projects::kMax], cnt[Projects::kMax];
        int rows = Projects::ordered(pb, ord, pnow, cnt);
        for (int r = 0; r < rows; r++) {
            const Projects::Entry& x = pb.e[ord[r]];
            JsonObject o = pa.add<JsonObject>();
            o[F("sessions")] = cnt[r];
            o[F("project")] = x.project;
            o[F("agent")]   = Attention::agentName(x.agent);
            o[F("state")]   = kSt[x.state];
            o[F("detail")]  = x.detail;
            o[F("age_s")]   = pnow - x.since;
            o[F("idle_s")]  = pnow - x.last;
            o[F("shown")]   = Projects::shown(x, pnow);
        }
    }
    // Per-source fetch health.
    JsonObject src = d[F("sources")].to<JsonObject>();
    const ClaudeData* cl = mainClaudeData();
    const CodexData*  cx = mainCodexData();
    JsonObject jcl = src[F("claude")].to<JsonObject>();
    JsonObject jcx = src[F("codex")].to<JsonObject>();
    sourceJson(jcl, Api::claudePolicy(), cl->valid, cl->err);
    sourceJson(jcx, Api::codexPolicy(),  cx->valid, cx->err);
    credJson(jcl, cl->cred, 0, cl->resets);
    credJson(jcx, cx->cred, cx->jwtExp, cx->resets);
    const WeatherData& w = Weather::snapshot();
    sourceJson(src[F("weather")].to<JsonObject>(), Weather::policy(), w.valid, w.err);
    if (pSettings && pSettings->showStatus) {
        JsonObject vs = d[F("vendor_status")].to<JsonObject>();
        const char* names[VendorStatus::COUNT] = {"claude", "openai"};
        for (int i = 0; i < VendorStatus::COUNT; i++) {
            const VendorStatus::Info& in = VendorStatus::get((VendorStatus::Vendor)i);
            JsonObject o = vs[names[i]].to<JsonObject>();
            o[F("level")]       = VendorStatus::levelName(in.level);
            o[F("description")] = in.description;
            o[F("last_ok")]     = (uint32_t)in.lastOk;
        }
    }
    String out; serializeJson(d, out);
    server.send(200, "application/json", out);
}

static void handleApiGetSettings() {
    if (!pSettings) { server.send_P(500, PSTR("application/json"), PSTR("{\"error\":\"no settings\"}")); return; }
    Settings& s = *pSettings;
    JsonDocument d;
    d[F("wifiSSID")]      = s.wifiSSID;
    d[F("wifiPass")]      = maskSecret(s.wifiPass);
    d[F("claudeKey")]     = maskSecret(s.claudeKey);
    d[F("codexToken")]    = maskSecret(s.codexToken);
    d[F("codexDeviceId")]    = s.codexDeviceId;
    d[F("codexModelLabel")]  = s.codexModelLabel;
    d[F("apiToken")]      = maskSecret(s.apiToken);
    d[F("refreshMin")]    = s.refreshMin;
    d[F("channelSec")]    = s.channelSec;
    d[F("brightness")]    = s.brightness;
    d[F("tzMinutes")]     = s.tzMinutes;
    d[F("showClaude")]    = s.showClaude;
    d[F("showCodex")]     = s.showCodex;
    d[F("showWeather")]   = s.showWeather;
    d[F("showHome")]      = s.showHome;
    d[F("showClock")]     = s.showClock;
    d[F("showForecast")]  = s.showForecast;
    d[F("showAiDash")]    = s.showAiDash;
    d[F("showInfo")]      = s.showInfo;
    d[F("showTrend")]     = s.showTrend;
    d[F("showAgents")]    = s.showAgents;
    d[F("idleDim")]       = s.idleDim;
    d[F("showStatus")]    = s.showStatus;
    d[F("autoRotate")]    = s.autoRotate;
    d[F("claudeWeeklyHero")] = s.claudeWeeklyHero;
    d[F("codexWeeklyHero")]  = s.codexWeeklyHero;
    d[F("clock24h")]      = s.clock24h;
    d[F("invertDisplay")] = s.invertDisplay;
    d[F("nightMode")]     = s.nightMode;
    d[F("nightStartMin")] = s.nightStartMin;
    d[F("nightEndMin")]   = s.nightEndMin;
    d[F("nightBright")]   = s.nightBright;
    d[F("weatherLat")]    = s.weatherLat;
    d[F("weatherLon")]    = s.weatherLon;
    d[F("useFahrenheit")] = s.useFahrenheit;
    d[F("userName")]      = s.userName;
    d[F("pinApprovals")]   = s.pinApprovals;
    d[F("approvalTtlMin")] = s.approvalTtlMin;
    d[F("agentDoneCards")] = s.agentDoneCards;
    d[F("agentNightShow")] = s.agentNightShow;
    d[F("skill")]          = Skill::first(s.skillsOn.c_str());
    {
        JsonArray so = d[F("skillsOn")].to<JsonArray>();
        for (int i = 0; i < Skill::kCount; i++)
            if (Skill::inList(s.skillsOn.c_str(), Skill::kAll[i])) so.add(Skill::kAll[i]);
    }
    String out; serializeJson(d, out);
    server.send(200, "application/json", out);
}

static void applyIfPresent(Settings& s, JsonDocument& d) {
    // Strings — only apply if key is present AND value is not "***" (the mask).
    auto applyStr = [&](const char* k, String& dst) {
        if (!d[k].is<const char*>()) return;
        const char* v = d[k].as<const char*>();
        if (v && strcmp(v, "***") != 0) dst = v;
    };
    applyStr("wifiSSID",      s.wifiSSID);
    applyStr("wifiPass",      s.wifiPass);
    applyStr("claudeKey",     s.claudeKey);
    applyStr("codexToken",    s.codexToken);
    applyStr("codexDeviceId",    s.codexDeviceId);
    applyStr("codexModelLabel",  s.codexModelLabel);
    applyStr("apiToken",      s.apiToken);
    applyStr("userName",      s.userName);

    auto applyU32 = [&](const char* k, uint32_t& dst, uint32_t lo, uint32_t hi) {
        if (d[k].is<int>() || d[k].is<unsigned int>()) {
            int v = d[k].as<int>();
            if (v < (int)lo) v = lo; if (v > (int)hi) v = hi;
            dst = v;
        }
    };
    auto applyU8 = [&](const char* k, uint8_t& dst, int lo, int hi) {
        if (d[k].is<int>() || d[k].is<unsigned int>()) {
            int v = d[k].as<int>();
            if (v < lo) v = lo; if (v > hi) v = hi;
            dst = (uint8_t)v;
        }
    };
    auto applyU16 = [&](const char* k, uint16_t& dst, int lo, int hi) {
        if (d[k].is<int>() || d[k].is<unsigned int>()) {
            int v = d[k].as<int>();
            if (v < lo) v = lo; if (v > hi) v = hi;
            dst = (uint16_t)v;
        }
    };
    auto applyI16 = [&](const char* k, int16_t& dst, int lo, int hi) {
        if (d[k].is<int>()) {
            int v = d[k].as<int>();
            if (v < lo) v = lo; if (v > hi) v = hi;
            dst = (int16_t)v;
        }
    };
    auto applyBool = [&](const char* k, bool& dst) {
        if (d[k].is<bool>()) dst = d[k].as<bool>();
    };
    auto applyFloat = [&](const char* k, float& dst) {
        if (d[k].is<float>() || d[k].is<int>() || d[k].is<double>()) dst = d[k].as<float>();
    };

    applyU32("refreshMin",  s.refreshMin,  1, 60);
    applyU32("channelSec",  s.channelSec,  3, 60);
    applyU8 ("brightness",  s.brightness,  5, 100);
    applyI16("tzMinutes",   s.tzMinutes,  -720, 840);
    applyU8 ("nightMode",   s.nightMode,   0, 3);
    applyU16("nightStartMin", s.nightStartMin, 0, 1439);
    applyU16("nightEndMin",   s.nightEndMin,   0, 1439);
    applyU16("approvalTtlMin", s.approvalTtlMin, 5, 240);
    applyBool("pinApprovals",   s.pinApprovals);
    applyBool("agentDoneCards", s.agentDoneCards);
    applyBool("agentNightShow", s.agentNightShow);
    applyU8 ("nightBright", s.nightBright, 1, 100);
    applyBool("showClaude",   s.showClaude);
    applyBool("showCodex",    s.showCodex);
    applyBool("showWeather",  s.showWeather);
    applyBool("showHome",     s.showHome);
    applyBool("showClock",    s.showClock);
    applyBool("showForecast", s.showForecast);
    applyBool("showAiDash",   s.showAiDash);
    applyBool("showInfo",     s.showInfo);
    applyBool("showTrend",    s.showTrend);
    applyBool("showAgents",   s.showAgents);
    applyBool("idleDim",      s.idleDim);
    applyBool("showStatus",   s.showStatus);
    applyBool("autoRotate",   s.autoRotate);
    applyBool("claudeWeeklyHero", s.claudeWeeklyHero);
    applyBool("codexWeeklyHero",  s.codexWeeklyHero);
    applyBool("clock24h",     s.clock24h);
    applyBool("invertDisplay",s.invertDisplay);
    applyBool("useFahrenheit", s.useFahrenheit);
    applyFloat("weatherLat", s.weatherLat);
    applyFloat("weatherLon", s.weatherLon);
    // Enabled skills (R-SK-1): known ids only; an empty result is ignored (at least one stays on).
    if (d[F("skillsOn")].is<JsonArray>()) {
        String in;
        for (JsonVariant v : d[F("skillsOn")].as<JsonArray>())
            if (v.is<const char*>()) { in += v.as<const char*>(); in += ','; }
        char on[48];
        Skill::normalise(in.c_str(), on, sizeof(on), false);
        if (on[0]) s.skillsOn = on;
    } else if (d[F("skill")].is<const char*>() && Skill::known(d[F("skill")].as<const char*>())
               && !Skill::inList(s.skillsOn.c_str(), d[F("skill")].as<const char*>())) {
        // An app before 2026-11-25.3 picking a skill: turn it on, leave the others.
        String in = s.skillsOn + "," + d[F("skill")].as<const char*>();
        char on[48];
        Skill::normalise(in.c_str(), on, sizeof(on), false);
        if (on[0]) s.skillsOn = on;
    }
}

static void handleApiPostSettings() {
    if (!pSettings) { server.send_P(500, PSTR("application/json"), PSTR("{\"error\":\"no settings\"}")); return; }
    JsonDocument d;
    if (deserializeJson(d, server.arg("plain"))) {
        server.send_P(400, PSTR("application/json"), PSTR("{\"error\":\"bad json\"}"));
        return;
    }
    applyIfPresent(*pSettings, d);
    if (!Storage::save(*pSettings)) {
        server.send_P(507, PSTR("application/json"), PSTR("{\"error\":\"save failed\"}"));
        return;
    }

    bool restart = d[F("_restart")] | false;
    // Apply runtime-mutable settings immediately so the user sees the effect.
    if (!restart) mainSettingsChanged();
    server.send(200, "application/json", restart ? "{\"ok\":true,\"restart\":true}" : "{\"ok\":true}");
    if (restart) { delay(300); ESP.restart(); }
}

static void handleApiExport() {
    File f = LittleFS.open("/config.json", "r");
    if (!f) {
        // No saved config — synthesize from current
        handleApiGetSettings();
        return;
    }
    server.sendHeader("Content-Disposition", "attachment; filename=glimmer-config.json");
    server.streamFile(f, "application/json");
    f.close();
}

static void handleApiImport() {
    // Body is a full config.json. Validate it parses, then atomically replace
    // the file (tmp + rename) and restart.
    if (!Storage::importRaw(server.arg("plain"))) {
        server.send_P(400, PSTR("application/json"), PSTR("{\"error\":\"bad json or fs write\"}"));
        return;
    }
    server.send_P(200, PSTR("application/json"), PSTR("{\"ok\":true,\"restart\":true}"));
    delay(300);
    ESP.restart();
}

static void handleFactoryReset() {
    Storage::factoryReset();
    server.send_P(200, PSTR("application/json"), PSTR("{\"ok\":true}"));
    delay(200);
    ESP.restart();
}

static void handleReboot() {
    server.send_P(200, PSTR("application/json"), PSTR("{\"ok\":true,\"restart\":true}"));
    delay(300);
    ESP.restart();
}

// ── /push and /mcp (unchanged contract) ─────────────────────────────────────

// Build an attention item from a /push body or MCP push_card arguments and
// queue it. Returns the item id written into idOut (for the reply).
static int pushFrom(JsonVariantConst d, char* idOut, size_t n) {
    static uint32_t s_seq = 0;
    Attention::Item it;
    Attention::fromJson(d, AttentionQueue::now(), mainApprovalTtlS(), ++s_seq, it);
    snprintf(idOut, n, "%s", it.id);
    AttentionQueue::noteItem(it);           // project board (only if it names a project)
    return AttentionQueue::put(it);
}

static void sendJson(int code, JsonDocument& d) {
    String out; serializeJson(d, out);
    server.send(code, "application/json", out);
}

static void handlePush() {
    if (!checkAuth()) { server.send_P(401, PSTR("application/json"), PSTR("{\"error\":\"unauthorized\"}")); return; }
    JsonDocument doc;
    if (deserializeJson(doc, server.arg("plain"))) {
        server.send_P(400, PSTR("application/json"), PSTR("{\"error\":\"bad json\"}"));
        return;
    }
    char id[24];
    int slot = pushFrom(doc.as<JsonVariantConst>(), id, sizeof(id));
    JsonDocument r;
    r[F("ok")] = slot >= 0;
    r[F("id")] = id;
    if (slot < 0) r[F("error")] = F("queue full of more important cards");
    sendJson(slot >= 0 ? 200 : 409, r);
}

// GET /push — the active queue, most important first.
static void handlePushList() {
    if (!checkAuth()) { server.send_P(401, PSTR("application/json"), PSTR("{\"error\":\"unauthorized\"}")); return; }
    JsonDocument r;
    JsonArray a = r[F("cards")].to<JsonArray>();
    const Attention::Queue& q = AttentionQueue::get();
    int ord[Attention::kMax], n = Attention::ordered(q, ord);
    uint32_t now = AttentionQueue::now();
    for (int i = 0; i < n; i++) Attention::toJson(q.items[ord[i]], now, a.add<JsonObject>());
    sendJson(200, r);
}

// POST /push/clear — {"id": "..."} | {"all": true}
static void handlePushClear() {
    if (!checkAuth()) { server.send_P(401, PSTR("application/json"), PSTR("{\"error\":\"unauthorized\"}")); return; }
    JsonDocument d;
    if (deserializeJson(d, server.arg("plain"))) {
        server.send_P(400, PSTR("application/json"), PSTR("{\"error\":\"bad json\"}"));
        return;
    }
    JsonDocument r;
    if (d[F("projects")] | false) {             // {"projects":true}: empty the project board
        r[F("cleared")] = AttentionQueue::clearProjects();
        sendJson(200, r);
        return;
    }
    if (d[F("all")] | false) r[F("cleared")] = AttentionQueue::clearAll();
    else                  r[F("cleared")] = AttentionQueue::clear(d[F("id")] | "") ? 1 : 0;
    sendJson(200, r);
}

// POST /hook?agent=claude|codex — a TRIMMED agent hook event, sent by
// tools/agents/glimmer-hook.sh: {event, type, session, cwd, tool, detail,
// message}. Never post raw hook JSON here — a PostToolUse event carries the
// whole tool output, far beyond this device's RAM. Always answers 200 {} so
// a hook can never block or decide anything.
static void handleHook() {
    if (!checkAuth()) { server.send_P(401, PSTR("application/json"), PSTR("{\"error\":\"unauthorized\"}")); return; }
    JsonDocument d;
    if (server.arg("plain").length() > 2048 || deserializeJson(d, server.arg("plain"))) {
        server.send_P(200, PSTR("application/json"), PSTR("{}"));
        return;
    }
    Attention::HookEvent e;
    e.event   = d[F("event")]   | "";
    e.type    = d[F("type")]    | "";
    e.session = d[F("session")] | "";
    e.cwd     = d[F("cwd")]     | "";
    e.tool    = d[F("tool")]    | "";
    e.detail  = d[F("detail")]  | "";
    e.message = d[F("message")] | "";
    Attention::Agent agent = Attention::agentFrom(server.arg("agent").c_str());
    AttentionQueue::noteHook(agent, e);     // project board: every event, even ones the queue ignores
    Attention::Item it, extra;
    switch (Attention::fromHook(agent, e, mainAgentDoneCards(), mainApprovalTtlS(),
                                AttentionQueue::now(), it, &extra)) {
        case Attention::HOOK_UPSERT:
            if (extra.used) AttentionQueue::put(extra);
            AttentionQueue::put(it);
            break;
        case Attention::HOOK_CLEAR:  AttentionQueue::clear(it.id); break;
        default: break;
    }
    server.send_P(200, PSTR("application/json"), PSTR("{}"));
}

static void handleMcp() {
    if (!checkAuth()) { server.send_P(401, PSTR("application/json"), PSTR("{\"error\":\"unauthorized\"}")); return; }
    JsonDocument req;
    if (deserializeJson(req, server.arg("plain"))) {
        server.send_P(400, PSTR("application/json"), PSTR("{\"error\":\"bad json\"}"));
        return;
    }
    const char* method = req[F("method")] | "";
    auto id            = req[F("id")];

    JsonDocument resp;
    resp[F("jsonrpc")] = F("2.0");
    resp[F("id")]      = id;

    if (strcmp(method, "initialize") == 0) {
        JsonObject r = resp[F("result")].to<JsonObject>();
        r[F("protocolVersion")] = F("2024-11-05");
        JsonObject si = r[F("serverInfo")].to<JsonObject>();
        si[F("name")] = F("smalltv"); si[F("version")] = FW_VERSION;
        r[F("capabilities")]["tools"] = JsonObject();
    }
    else if (strcmp(method, "tools/list") == 0) {
        JsonArray tools = resp[F("result")]["tools"].to<JsonArray>();

        // push_card
        JsonObject t1 = tools.add<JsonObject>();
        t1[F("name")] = F("push_card");
        t1[F("description")] = F(
            "Show a card on the user's glimmer desk display. Use kind=approval when you are "
            "blocked waiting for the user to approve something, kind=input when you need an "
            "answer, progress for long work (re-send the same id to update it), success/error "
            "when a task finishes. Keep it short; never include secrets or file contents.");
        JsonObject s1 = t1[F("inputSchema")].to<JsonObject>();
        s1[F("type")] = F("object");
        JsonObject p1 = s1[F("properties")].to<JsonObject>();
        auto prop = [&](const char* k, const char* type, const __FlashStringHelper* desc) {
            p1[k]["type"] = type; p1[k]["description"] = desc;
        };
        prop("title",    "string",  F("Headline, <= 27 chars, e.g. 'TESTS PASSED'"));
        prop("value",    "string",  F("Optional big value, <= 15 chars, e.g. '142/142'"));
        prop("body",     "string",  F("Optional detail line, <= 39 chars"));
        prop("kind",     "string",  F("approval | input | error | warning | success | progress | info"));
        prop("id",       "string",  F("Stable id: re-send it to update the card in place, or to clear it"));
        prop("agent",    "string",  F("claude | codex | other (tag on the card)"));
        prop("project",  "string",  F("Repo / project name, <= 15 chars"));
        prop("progress", "integer", F("0-100, draws a progress bar"));
        prop("ttl_s",    "integer", F("Seconds until it disappears; 0 = until cleared (max 86400)"));
        prop("display",  "string",  F("interrupt (default: takes the screen briefly) | queue (only listed)"));
        prop("urgent",   "boolean", F("May wake a dark screen at night. Use sparingly."));
        s1[F("required")].to<JsonArray>().add("title");

        // clear_card
        JsonObject tc = tools.add<JsonObject>();
        tc[F("name")] = F("clear_card");
        tc[F("description")] = F("Remove a card you pushed (by id), or all cards with all=true.");
        JsonObject sc = tc[F("inputSchema")].to<JsonObject>();
        sc[F("type")] = F("object");
        sc[F("properties")]["id"]["type"]  = "string";
        sc[F("properties")]["all"]["type"] = F("boolean");

        // list_cards
        JsonObject tl = tools.add<JsonObject>();
        tl[F("name")] = F("list_cards");
        tl[F("description")] = F("List the cards currently on the display, most important first.");
        tl[F("inputSchema")]["type"] = F("object");

        // get_state
        JsonObject t2 = tools.add<JsonObject>();
        t2[F("name")] = F("get_state");
        t2[F("description")] = F("Return the device's current state (active channel, usage, uptime, heap, wifi)");
        t2[F("inputSchema")]["type"] = F("object");

        // show_channel
        JsonObject t3 = tools.add<JsonObject>();
        t3[F("name")] = F("show_channel");
        t3[F("description")] = F("Switch the screen to a channel by name (see enabled_channels in get_state)");
        JsonObject s3 = t3[F("inputSchema")].to<JsonObject>();
        s3[F("type")] = F("object");
        s3[F("properties")]["name"]["type"] = F("string");
        s3[F("properties")]["name"]["description"] = F("Channel name, e.g. Claude, Codex, Weather, Trend");
        s3[F("required")].to<JsonArray>().add("name");

        // next_channel
        JsonObject t4 = tools.add<JsonObject>();
        t4[F("name")] = F("next_channel");
        t4[F("description")] = F("Advance the screen to the next enabled channel");
        t4[F("inputSchema")]["type"] = F("object");
    }
    else if (strcmp(method, "tools/call") == 0) {
        const char* name = req[F("params")]["name"] | "";
        JsonObject args  = req[F("params")]["arguments"].as<JsonObject>();
        if (strcmp(name, "push_card") == 0) {
            char id[24];
            int slot = pushFrom(args, id, sizeof(id));
            char msg[64];
            if (slot >= 0) snprintf(msg, sizeof(msg), "Card shown (id %s)", id);
            else           snprintf(msg, sizeof(msg), "Not shown: queue full of more important cards");
            resp[F("result")]["content"][0]["type"] = F("text");
            resp[F("result")]["content"][0]["text"] = msg;
            if (slot < 0) resp[F("result")]["isError"] = true;
        } else if (strcmp(name, "clear_card") == 0) {
            int n = (args[F("all")] | false) ? AttentionQueue::clearAll()
                                          : (AttentionQueue::clear(args[F("id")] | "") ? 1 : 0);
            char msg[32]; snprintf(msg, sizeof(msg), "Cleared %d", n);
            resp[F("result")]["content"][0]["type"] = F("text");
            resp[F("result")]["content"][0]["text"] = msg;
        } else if (strcmp(name, "list_cards") == 0) {
            JsonDocument list;
            JsonArray a = list.to<JsonArray>();
            const Attention::Queue& q = AttentionQueue::get();
            int ord[Attention::kMax], n = Attention::ordered(q, ord);
            uint32_t now = AttentionQueue::now();
            for (int i = 0; i < n; i++) Attention::toJson(q.items[ord[i]], now, a.add<JsonObject>());
            String txt; serializeJson(list, txt);
            resp[F("result")]["content"][0]["type"] = F("text");
            resp[F("result")]["content"][0]["text"] = txt;
        } else if (strcmp(name, "get_state") == 0) {
            JsonObject st = resp[F("result")]["content"][0]["json"].to<JsonObject>();
            st[F("fw")]              = FW_VERSION;
            st[F("uptime_s")]        = (uint32_t)(millis() / 1000);
            st[F("heap")]            = ESP.getFreeHeap();
            st[F("maxblk")]          = ESP.getMaxFreeBlockSize();
            st[F("wifi")]            = WiFi.status() == WL_CONNECTED ? "connected" : "ap";
            st[F("rssi")]            = WiFi.RSSI();
            st[F("active_channel")]  = mainActiveChannelName();
            st[F("total_channels")]  = mainTotalCount();
            st[F("brightness")]      = pSettings->brightness;
            JsonArray ec = st[F("enabled_channels")].to<JsonArray>();
            for (int i = 0; i < mainEnabledCount(); i++) {
                const char* n = mainEnabledChannelName(i);
                if (n) ec.add(n);
            }
            const ClaudeData* cd = mainClaudeData();
            if (cd && cd->valid) {
                JsonArray ma = st[F("claude_models")].to<JsonArray>();
                for (int i = 0; i < 3; i++) {
                    if (cd->models[i].label[0]) {
                        JsonObject m = ma.add<JsonObject>();
                        m[F("label")] = cd->models[i].label;
                        m[F("pct")]   = (int)cd->models[i].pct;
                    }
                }
            }
            resp[F("result")]["content"][0]["type"] = F("json");
        } else if (strcmp(name, "show_channel") == 0) {
            const char* ch = args[F("name")] | "";
            bool ok = mainShowChannel(ch);
            resp[F("result")]["content"][0]["type"] = F("text");
            resp[F("result")]["content"][0]["text"] = ok ? "Switched" : "No enabled channel with that name";
            if (!ok) resp[F("result")]["isError"] = true;
        } else if (strcmp(name, "next_channel") == 0) {
            mainNextChannel();
            resp[F("result")]["content"][0]["type"] = F("text");
            resp[F("result")]["content"][0]["text"] = mainActiveChannelName();
        } else {
            resp[F("error")]["code"]    = -32602;
            resp[F("error")]["message"] = F("Unknown tool");
        }
    }
    else {
        resp[F("error")]["code"]    = -32601;
        resp[F("error")]["message"] = F("Method not found");
    }

    String out; serializeJson(resp, out);
    server.send(200, "application/json", out);
}

// ── Photos (skill `photo`) ──────────────────────────────────────────────────

static void handlePhotoList() {
    JsonDocument d;
    JsonArray a = d[F("photos")].to<JsonArray>();
    char nm[16];
    for (int i = 0; i < Photos::count(); i++) {
        JsonObject o = a.add<JsonObject>();
        o[F("name")] = Photos::name(i, nm, sizeof(nm));
        o[F("size")] = Photos::size(i);
    }
    d[F("free")]        = Photos::fsFree();
    d[F("total")]       = Photos::fsTotal();
    d[F("max_count")]   = Photos::kMax;
    d[F("max_bytes")]   = Photos::kMaxBytes;
    d[F("reserve")]     = Photos::kReserveBytes;
    d[F("side")]        = Photos::kSide;
    sendJson(200, d);
}

// Multipart chunks: auth is checked once headers are in (UPLOAD_FILE_START).
static bool s_photoAuthBad = false;

static void handlePhotoUploadChunk() {
    HTTPUpload& up = server.upload();
    switch (up.status) {
        case UPLOAD_FILE_START:
            s_photoAuthBad = !checkAuth();
            if (!s_photoAuthBad) Photos::uploadStart(up.name.c_str());
            break;
        case UPLOAD_FILE_WRITE:
            if (!s_photoAuthBad) Photos::uploadWrite(up.buf, up.currentSize);
            break;
        case UPLOAD_FILE_ABORTED:
            if (!s_photoAuthBad) Photos::uploadAbort();
            break;
        default: break;
    }
}

static void handlePhotoUploadDone() {
    if (s_photoAuthBad || !checkAuth()) {
        s_photoAuthBad = false;
        server.send_P(401, PSTR("application/json"), PSTR("{\"error\":\"unauthorized\"}"));
        return;
    }
    char nm[16];
    const char* err = Photos::uploadEnd(nm, sizeof(nm));
    JsonDocument d;
    if (*err) {
        d[F("error")] = err;
        d[F("count")] = Photos::count();
        // full / no_space / too_big = limits (413 / 507); format problems = 400.
        int code = !strcmp(err, "full") || !strcmp(err, "too_big") ? 413
                 : !strcmp(err, "no_space") ? 507 : !strcmp(err, "fs") ? 500 : 400;
        sendJson(code, d);
        return;
    }
    d[F("ok")]    = true;
    d[F("name")]  = nm;
    d[F("count")] = Photos::count();
    sendJson(200, d);
}

static void handlePhotoDelete() {
    if (!checkAuth()) { server.send_P(401, PSTR("application/json"), PSTR("{\"error\":\"unauthorized\"}")); return; }
    if (!Photos::remove(server.arg("name").c_str())) {
        server.send_P(404, PSTR("application/json"), PSTR("{\"error\":\"no such photo\"}"));
        return;
    }
    JsonDocument d;
    d[F("ok")]    = true;
    d[F("count")] = Photos::count();
    sendJson(200, d);
}

// ── Desktop wallpaper (P-2026-11-26.12) ─────────────────────────────────────

static void handleWallpaperGet() {
    JsonDocument d;
    d[F("set")]       = Wallpaper::present();
    d[F("size")]      = Wallpaper::size();
    d[F("w")]         = Wallpaper::kW;
    d[F("h")]         = Wallpaper::kH;
    d[F("max_bytes")] = Wallpaper::kMaxBytes;
    d[F("free")]      = Photos::fsFree();
    d[F("reserve")]   = Photos::kReserveBytes;
    sendJson(200, d);
}

static bool s_wallAuthBad = false;

static void handleWallpaperChunk() {
    HTTPUpload& up = server.upload();
    switch (up.status) {
        case UPLOAD_FILE_START:
            s_wallAuthBad = !checkAuth();
            if (!s_wallAuthBad) Wallpaper::uploadStart(up.name.c_str());
            break;
        case UPLOAD_FILE_WRITE:
            if (!s_wallAuthBad) Wallpaper::uploadWrite(up.buf, up.currentSize);
            break;
        case UPLOAD_FILE_ABORTED:
            if (!s_wallAuthBad) Wallpaper::uploadAbort();
            break;
        default: break;
    }
}

static void handleWallpaperUploadDone() {
    if (s_wallAuthBad || !checkAuth()) {
        s_wallAuthBad = false;
        server.send_P(401, PSTR("application/json"), PSTR("{\"error\":\"unauthorized\"}"));
        return;
    }
    const char* err = Wallpaper::uploadEnd();
    JsonDocument d;
    if (*err) {
        d[F("error")] = err;
        // too_big / no_space = limits (413 / 507); format problems = 400.
        int code = !strcmp(err, "too_big") ? 413 : !strcmp(err, "no_space") ? 507
                 : !strcmp(err, "fs") ? 500 : 400;
        sendJson(code, d);
        return;
    }
    d[F("ok")]   = true;
    d[F("size")] = Wallpaper::size();
    sendJson(200, d);
    mainWallpaperChanged();
}

static void handleWallpaperDelete() {
    if (!checkAuth()) { server.send_P(401, PSTR("application/json"), PSTR("{\"error\":\"unauthorized\"}")); return; }
    if (!Wallpaper::remove()) {
        server.send_P(404, PSTR("application/json"), PSTR("{\"error\":\"no wallpaper\"}"));
        return;
    }
    server.send_P(200, PSTR("application/json"), PSTR("{\"ok\":true}"));
    mainWallpaperChanged();
}

// ── Public API ──────────────────────────────────────────────────────────────

void Web::begin(Settings& settings) {
    pSettings = &settings;
    updater.setup(&server);                                     // POST /update OTA
    // OTA progress UI — Update callback fires repeatedly during flash write.
    // We only repaint when integer-% changes (≤100 paints per flash, cheap).
    Update.onProgress([](size_t cur, size_t total) {
        if (!total) return;
        uint8_t pct = (uint8_t)((cur * 100UL) / total);
        Display::drawOtaProgress(pct);
    });

    // JSON API
    server.on("/api/state",          HTTP_GET,  handleApiState);
    server.on("/api/settings",       HTTP_GET,  handleApiGetSettings);
    server.on("/api/settings",       HTTP_POST, handleApiPostSettings);
    server.on("/api/export",         HTTP_GET,  handleApiExport);
    server.on("/api/import",         HTTP_POST, handleApiImport);
    server.on("/api/factory-reset",  HTTP_POST, handleFactoryReset);
    server.on("/api/reboot",         HTTP_POST, handleReboot);
    server.on("/api/refresh",        HTTP_POST, []() {
        if (!checkAuth()) { server.send_P(401, PSTR("application/json"), PSTR("{\"error\":\"unauthorized\"}")); return; }
        mainTriggerRefresh();
        server.send_P(200, PSTR("application/json"), PSTR("{\"ok\":true}"));
    });

    // Channel control (app remote, design 2026-11-26.5): {"name":"Claude"} shows a
    // channel; {"action":"next"|"prev"} steps; {"action":"pause"|"resume"} holds the
    // rotation (RAM only, R-DK-4). Answer: {ok, active, paused}.
    server.on("/api/channel",        HTTP_POST, []() {
        if (!checkAuth()) { server.send_P(401, PSTR("application/json"), PSTR("{\"error\":\"unauthorized\"}")); return; }
        JsonDocument d;
        if (deserializeJson(d, server.arg("plain"))) {
            server.send_P(400, PSTR("application/json"), PSTR("{\"error\":\"bad json\"}"));
            return;
        }
        const char* action = d[F("action")] | "";
        if      (!strcmp(action, "next"))   mainNextChannel();
        else if (!strcmp(action, "prev"))   mainPrevChannel();
        else if (!strcmp(action, "pause"))  mainSetPaused(true);
        else if (!strcmp(action, "resume")) mainSetPaused(false);
        else if (*action) {
            server.send_P(400, PSTR("application/json"), PSTR("{\"error\":\"unknown action\"}"));
            return;
        } else {
            // {"zoom":"min"} = the app's _ button: the window zooms down to its button (P-2026-11-26.16).
            if (!strcmp(d[F("zoom")] | "", "min")) mainNoteMinimize();
            if (!mainShowChannel(d[F("name")] | "")) {
                server.send_P(404, PSTR("application/json"), PSTR("{\"error\":\"no enabled channel with that name\"}"));
                return;
            }
        }
        JsonDocument r;
        r[F("ok")]     = true;
        r[F("active")] = mainActiveChannelName();
        r[F("paused")] = mainPaused();
        sendJson(200, r);
    });

    // The app's open windows (design 2026-11-26.7, P-2026-11-26.14): the whole
    // list each time, names as /api/channel's; unknown names are skipped.
    server.on("/api/windows",        HTTP_POST, []() {
        if (!checkAuth()) { server.send_P(401, PSTR("application/json"), PSTR("{\"error\":\"unauthorized\"}")); return; }
        JsonDocument d;
        if (deserializeJson(d, server.arg("plain")) || !d[F("open")].is<JsonArray>()) {
            server.send_P(400, PSTR("application/json"), PSTR("{\"error\":\"body must be {open: [...], top, min, sel}\"}"));
            return;
        }
        Control::Windows w;
        for (JsonVariant v : d[F("open")].as<JsonArray>()) Control::addOpen(w, XPCore::progOf(v | ""));
        for (JsonVariant v : d[F("min")].as<JsonArray>()) {
            const int p = XPCore::progOf(v | "");
            if (p >= 0 && Control::isOpen(w, p)) w.minMask |= (uint16_t)(1u << p);
        }
        const int top = XPCore::progOf(d[F("top")] | "");
        w.top = top >= 0 && Control::isOpen(w, top) ? (int8_t)top : XPCore::PROG_NONE;
        w.sel = XPCore::progOf(d[F("sel")] | "");
        mainSetWindows(w);
        server.send_P(200, PSTR("application/json"), PSTR("{\"ok\":true}"));
    });

    // Context menu (P-2026-11-26.14 XP-Menu): the app places it (top-left)
    // and picks the item itself; "none" closes it. 409 on a screen without one.
    server.on("/api/menu",           HTTP_POST, []() {
        if (!checkAuth()) { server.send_P(401, PSTR("application/json"), PSTR("{\"error\":\"unauthorized\"}")); return; }
        JsonDocument d;
        if (deserializeJson(d, server.arg("plain"))) {
            server.send_P(400, PSTR("application/json"), PSTR("{\"error\":\"bad json\"}"));
            return;
        }
        const char* kind = d[F("kind")] | "none";
        Control::Menu m;
        m.kind = !strcmp(kind, "desktop") ? XPCore::MENU_DESKTOP
               : !strcmp(kind, "window")  ? XPCore::MENU_WINDOW : XPCore::MENU_NONE;
        int x = d[F("x")] | 0, y = d[F("y")] | 0;
        if (m.kind != XPCore::MENU_NONE) XPCore::menuClamp(m.kind, x, y);
        m.x = (int16_t)x;
        m.y = (int16_t)y;
        m.minimized = d[F("minimized")] | false;
        if (!mainSetMenu(m)) {
            server.send_P(409, PSTR("application/json"), PSTR("{\"error\":\"no menu on this screen\"}"));
            return;
        }
        server.send_P(200, PSTR("application/json"), PSTR("{\"ok\":true}"));
    });

    // Tray balloon (P-2026-11-26.15): the app taps the tray icon → show for
    // 10 s; × → hide. 409 when the desktop is not on screen / weather skill off.
    server.on("/api/balloon",        HTTP_POST, []() {
        if (!checkAuth()) { server.send_P(401, PSTR("application/json"), PSTR("{\"error\":\"unauthorized\"}")); return; }
        JsonDocument d;
        if (deserializeJson(d, server.arg("plain")) || !d[F("show")].is<bool>()) {
            server.send_P(400, PSTR("application/json"), PSTR("{\"error\":\"body must be {show: true|false}\"}"));
            return;
        }
        if (!mainSetBalloon(d[F("show")].as<bool>())) {
            server.send_P(409, PSTR("application/json"), PSTR("{\"error\":\"no balloon on this screen\"}"));
            return;
        }
        JsonDocument r;
        r[F("ok")]      = true;
        r[F("balloon")] = mainBalloonShown();
        sendJson(200, r);
    });

    // Backlight off / on now, whatever the night window says (RAM only; an
    // approval / question / urgent card still lights an "off" screen).
    server.on("/api/screen",         HTTP_POST, []() {
        if (!checkAuth()) { server.send_P(401, PSTR("application/json"), PSTR("{\"error\":\"unauthorized\"}")); return; }
        JsonDocument d;
        if (deserializeJson(d, server.arg("plain")) || !d[F("on")].is<bool>()) {
            server.send_P(400, PSTR("application/json"), PSTR("{\"error\":\"body must be {on: true|false}\"}"));
            return;
        }
        mainSetScreenOn(d[F("on")].as<bool>());
        JsonDocument r;
        r[F("ok")]        = true;
        r[F("screen_on")] = mainScreenOn();
        sendJson(200, r);
    });

    // Legacy + event endpoints
    server.on("/push",               HTTP_POST, handlePush);
    server.on("/push",               HTTP_GET,  handlePushList);
    server.on("/push/clear",         HTTP_POST, handlePushClear);
    server.on("/hook",               HTTP_POST, handleHook);
    server.on("/mcp",                HTTP_POST, handleMcp);
    server.on("/api/photos",         HTTP_GET,    handlePhotoList);
    server.on("/api/photos",         HTTP_POST,   handlePhotoUploadDone, handlePhotoUploadChunk);
    server.on("/api/photos",         HTTP_DELETE, handlePhotoDelete);
    server.on("/api/wallpaper",      HTTP_GET,    handleWallpaperGet);
    server.on("/api/wallpaper",      HTTP_POST,   handleWallpaperUploadDone, handleWallpaperChunk);
    server.on("/api/wallpaper",      HTTP_DELETE, handleWallpaperDelete);

    // Backwards-compat status (used by some scripts)
    server.on("/status",             HTTP_GET,  handleApiState);

    // Static file serving — fallback for everything else
    server.onNotFound([]() {
        if (!serveStatic(server.uri())) {
            server.send_P(404, PSTR("text/plain"), PSTR("Not found"));
        }
    });

    server.collectHeaders("Authorization");
    server.begin();
}

void Web::loop() {
    server.handleClient();
}
