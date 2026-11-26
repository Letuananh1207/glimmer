#include "storage.h"
#include "skill_core.h"
#include <LittleFS.h>
#include <time.h>

static const char* CFG_PATH = "/config.json";

void Storage::begin() {
    LittleFS.begin();
}

Settings Storage::load() {
    Settings s;
    File f = LittleFS.open(CFG_PATH, "r");
    if (!f) return s;
    JsonDocument doc;
    auto err = deserializeJson(doc, f);
    f.close();
    if (err) return s;
    s.wifiSSID      = doc[F("wifi_ssid")]      | "";
    s.wifiPass      = doc[F("wifi_pass")]      | "";
    s.claudeKey     = doc[F("claude_key")]     | "";
    s.codexToken    = doc[F("codex_token")]    | "";
    s.codexDeviceId    = doc[F("codex_dev")]      | "";
    s.codexModelLabel  = doc[F("codex_model")]    | "";
    s.refreshMin    = doc[F("refresh_min")]    | 5;
    s.channelSec    = doc[F("channel_sec")]    | 8;
    s.brightness    = doc[F("brightness")]     | 80;
    // Timezone: `tz_min` is authoritative. Configs written before it carried an
    // ambiguous pair (tz_minutes == 0 meant "use the hour-only tz_offset"), so
    // UTC could never be chosen; translate that once on load.
    if (!doc[F("tz_min")].isNull()) {
        s.tzMinutes = doc[F("tz_min")] | 0;
    } else {
        int16_t legacyMin = doc[F("tz_minutes")] | 0;
        int8_t  legacyHr  = doc[F("tz_offset")]  | 0;
        s.tzMinutes = legacyMin != 0 ? legacyMin : (int16_t)(legacyHr * 60);
    }
    s.showClaude    = doc[F("show_claude")]    | true;
    s.showCodex     = doc[F("show_codex")]     | true;
    s.showHome      = doc[F("show_home")]      | true;
    s.showClock     = doc[F("show_clock")]     | true;
    s.showForecast  = doc[F("show_forecast")]  | true;
    s.showAiDash    = doc[F("show_aidash")]    | true;
    s.showInfo      = doc[F("show_info")]      | true;
    s.showTrend     = doc[F("show_trend")]     | true;
    s.showAgents    = doc[F("show_agents")]    | true;
    s.idleDim       = doc[F("idle_dim")]       | true;
    s.showStatus    = doc[F("show_status")]    | false;
    s.autoRotate    = doc[F("auto_rotate")]    | true;
    s.claudeWeeklyHero = doc[F("claude_weekly_hero")] | false;
    s.codexWeeklyHero  = doc[F("codex_weekly_hero")]  | false;
    s.clock24h      = doc[F("clock_24h")]      | true;
    s.invertDisplay = doc[F("invert_display")] | true;
    // Night: minute-precision window + mode. Older configs stored whole hours
    // and an on/off dim flag; translate those once on load.
    if (!doc[F("night_mode")].isNull()) {
        s.nightMode     = doc[F("night_mode")]      | 0;
        s.nightStartMin = doc[F("night_start_min")] | 22 * 60;
        s.nightEndMin   = doc[F("night_end_min")]   | 7 * 60;
    } else {
        s.nightMode     = (doc[F("night_dim")] | false) ? 1 : 0;
        s.nightStartMin = (uint16_t)((doc[F("night_start")] | 22) * 60);
        s.nightEndMin   = (uint16_t)((doc[F("night_end")]   | 7)  * 60);
    }
    s.nightBright   = doc[F("night_bright")]   | 15;
    s.weatherLat    = doc[F("weather_lat")]    | 0.0f;
    s.weatherLon    = doc[F("weather_lon")]    | 0.0f;
    s.showWeather   = doc[F("show_weather")]   | true;
    s.useFahrenheit = doc[F("fahrenheit")]     | false;
    s.userName      = doc[F("user_name")]      | "";
    s.apiToken      = doc[F("api_token")]      | "";
    s.pinApprovals   = doc[F("pin_approvals")]    | true;
    s.approvalTtlMin = doc[F("approval_ttl_min")] | 30;
    s.agentDoneCards = doc[F("agent_done_cards")] | false;
    s.agentNightShow = doc[F("agent_night_show")] | false;
    {
        // Before 2026-11-25.3 one "skill" owned the screen and weather/clock always rotated:
        // no "skills_on" yet → everything on, so the device shows what it showed before.
        char on[48];
        Skill::normalise(doc[F("skills_on")] | Skill::kDefaultOn, on, sizeof(on), true);
        s.skillsOn = on;
    }
    return s;
}

static bool writeAtomic(const std::function<size_t(File&)>& writer) {
    File f = LittleFS.open("/config.tmp", "w");
    if (!f) return false;
    size_t n = writer(f);
    f.close();
    if (n == 0) { LittleFS.remove("/config.tmp"); return false; }
    LittleFS.remove(CFG_PATH);
    return LittleFS.rename("/config.tmp", CFG_PATH);
}

bool Storage::save(const Settings& s) {
    JsonDocument doc;
    doc[F("wifi_ssid")]    = s.wifiSSID;
    doc[F("wifi_pass")]    = s.wifiPass;
    doc[F("claude_key")]   = s.claudeKey;
    doc[F("codex_token")]  = s.codexToken;
    doc[F("codex_dev")]    = s.codexDeviceId;
    doc[F("codex_model")]  = s.codexModelLabel;
    doc[F("refresh_min")]  = s.refreshMin;
    doc[F("channel_sec")]  = s.channelSec;
    doc[F("brightness")]   = s.brightness;
    doc[F("tz_min")]       = s.tzMinutes;
    doc[F("show_claude")]   = s.showClaude;
    doc[F("show_codex")]    = s.showCodex;
    doc[F("show_home")]     = s.showHome;
    doc[F("show_clock")]    = s.showClock;
    doc[F("show_forecast")] = s.showForecast;
    doc[F("show_aidash")]   = s.showAiDash;
    doc[F("show_info")]     = s.showInfo;
    doc[F("show_trend")]    = s.showTrend;
    doc[F("show_agents")]   = s.showAgents;
    doc[F("idle_dim")]      = s.idleDim;
    doc[F("show_status")]   = s.showStatus;
    doc[F("auto_rotate")]   = s.autoRotate;
    doc[F("claude_weekly_hero")] = s.claudeWeeklyHero;
    doc[F("codex_weekly_hero")]  = s.codexWeeklyHero;
    doc[F("clock_24h")]     = s.clock24h;
    doc[F("invert_display")]= s.invertDisplay;
    doc[F("night_mode")]      = s.nightMode;
    doc[F("night_start_min")] = s.nightStartMin;
    doc[F("night_end_min")]   = s.nightEndMin;
    doc[F("night_bright")] = s.nightBright;
    doc[F("weather_lat")]  = s.weatherLat;
    doc[F("weather_lon")]  = s.weatherLon;
    doc[F("show_weather")] = s.showWeather;
    doc[F("fahrenheit")]   = s.useFahrenheit;
    doc[F("user_name")]    = s.userName;
    doc[F("api_token")]    = s.apiToken;
    doc[F("pin_approvals")]    = s.pinApprovals;
    doc[F("approval_ttl_min")] = s.approvalTtlMin;
    doc[F("agent_done_cards")] = s.agentDoneCards;
    doc[F("agent_night_show")] = s.agentNightShow;
    doc[F("skills_on")]        = s.skillsOn;
    return writeAtomic([&](File& f) { return serializeJson(doc, f); });
}

bool Storage::importRaw(const String& json) {
    JsonDocument d;
    if (deserializeJson(d, json) || !d.is<JsonObject>()) return false;
    return writeAtomic([&](File& f) { return f.print(json); });
}

void Storage::factoryReset() {
    LittleFS.remove(CFG_PATH);
}

void Storage::applyTimezone(const Settings& s) {
    // POSIX expresses the offset as "time to ADD to local to get UTC", so a
    // zone east of UTC is written with a NEGATIVE offset.
    int posixMin = -(int)s.tzMinutes;
    int posixH   = posixMin / 60;
    int posixM   = posixMin % 60; if (posixM < 0) posixM = -posixM;
    char tz[16];
    snprintf(tz, sizeof(tz), "UTC%+d:%02d", posixH, posixM);
    setenv("TZ", tz, 1);
    tzset();
}
