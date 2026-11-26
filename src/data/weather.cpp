#include "weather.h"
#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266HTTPClient.h>
#include <ArduinoJson.h>
#include <LittleFS.h>

// Open-Meteo is plain HTTP (and HTTPS); we use HTTP to save TLS memory.
// API doc: https://open-meteo.com/en/docs

namespace Weather {

static WeatherData        s_w;
static FetchPolicy::State s_pol;
static const char*        kCachePath = "/weather.json";

WeatherData& snapshot() { return s_w; }
const FetchPolicy::State& policy() { return s_pol; }

bool configured(const Settings& s) {
    return s.weatherLat != 0.0f || s.weatherLon != 0.0f;
}

uint32_t intervalMin(const Settings& s) {
    return s.refreshMin < 10 ? 10 : s.refreshMin;
}

bool isStale(const Settings& s) {
    time_t now = time(nullptr);
    if (!s_w.valid || s_w.lastOk <= 0 || now < 1000000000L) return false;
    return (long)(now - s_w.lastOk) > (long)intervalMin(s) * 60L * 3L;
}

// ── last-good persistence ───────────────────────────────────────────────────

static void save() {
    JsonDocument d;
    d[F("t")] = s_w.tempC; d[F("f")] = s_w.feelsC; d[F("c")] = s_w.code; d[F("day")] = s_w.isDay;
    d[F("h")] = s_w.humidity; d[F("w")] = s_w.windKmh; d[F("ok")] = (uint32_t)s_w.lastOk;
    d[F("rs")] = (uint32_t)s_w.rainStart;
    JsonArray rp = d[F("rp")].to<JsonArray>();
    for (uint8_t p : s_w.rainPct) rp.add(p);
    JsonArray fc = d[F("fc")].to<JsonArray>();
    for (const WeatherDay& wd : s_w.forecast) {
        JsonObject o = fc.add<JsonObject>();
        o[F("lo")] = wd.tmin; o[F("hi")] = wd.tmax; o[F("c")] = wd.code; o[F("uv")] = wd.uvMax;
        o[F("sr")] = (uint32_t)wd.sunrise; o[F("ss")] = (uint32_t)wd.sunset;
    }
    File f = LittleFS.open("/weather.tmp", "w");
    if (!f) return;
    size_t n = serializeJson(d, f);
    f.close();
    if (!n) { LittleFS.remove("/weather.tmp"); return; }
    LittleFS.remove(kCachePath);
    LittleFS.rename("/weather.tmp", kCachePath);
}

void begin() {
    File f = LittleFS.open(kCachePath, "r");
    if (!f) return;
    JsonDocument d;
    DeserializationError e = deserializeJson(d, f);
    f.close();
    if (e || d[F("ok")].isNull()) return;
    s_w.tempC = d[F("t")] | -999.0f; s_w.feelsC = d[F("f")] | s_w.tempC;
    s_w.code = d[F("c")] | 0; s_w.isDay = d[F("day")] | true;
    s_w.humidity = d[F("h")] | -1; s_w.windKmh = d[F("w")] | -1.0f;
    s_w.lastOk = (time_t)(d[F("ok")] | 0UL);
    s_w.rainStart = (time_t)(d[F("rs")] | 0UL);
    for (int i = 0; i < 12; i++) s_w.rainPct[i] = d[F("rp")][i] | 255;
    for (int i = 0; i < 4; i++) {
        JsonVariant o = d[F("fc")][i];
        s_w.forecast[i].tmin = o[F("lo")] | -999.0f; s_w.forecast[i].tmax = o[F("hi")] | -999.0f;
        s_w.forecast[i].code = o[F("c")] | 0;        s_w.forecast[i].uvMax = o[F("uv")] | -1.0f;
        s_w.forecast[i].sunrise = (time_t)(o[F("sr")] | 0UL);
        s_w.forecast[i].sunset  = (time_t)(o[F("ss")] | 0UL);
    }
    s_w.valid = s_w.tempC > -900.0f;
}

// ── fetch ───────────────────────────────────────────────────────────────────

static bool fail(int code, const char* err) {
    FetchPolicy::onFailure(s_pol, code, -1);
    // Keep showing the last good snapshot (it goes stale on its own clock);
    // only a never-loaded snapshot surfaces the error text.
    if (!s_w.valid) snprintf_P(s_w.err, sizeof(s_w.err), PSTR("%s"), err);
    Serial.printf_P(PSTR("[weather] fail (%s) streak=%u wait=%us\n"), err, s_pol.fails,
                  (unsigned)s_pol.waitS);
    return false;
}

bool fetch(const Settings& s) {
    if (!configured(s)) return false;

    char url[320];
    snprintf_P(url, sizeof(url), PSTR("http://api.open-meteo.com/v1/forecast"
        "?latitude=%.4f&longitude=%.4f"
        "&current=temperature_2m,apparent_temperature,weather_code,relative_humidity_2m,"
        "wind_speed_10m,is_day"
        "&hourly=precipitation_probability&forecast_hours=12"
        "&daily=temperature_2m_min,temperature_2m_max,weather_code,sunrise,sunset,uv_index_max"
        "&forecast_days=4&timezone=auto&timeformat=unixtime"),
        s.weatherLat, s.weatherLon);

    WiFiClient client;
    HTTPClient http;
    http.useHTTP10(true);
    http.setTimeout(8000);
    if (!http.begin(client, url)) return fail(-2, "http begin");
    int code = http.GET();
    if (code != HTTP_CODE_OK) {
        http.end();
        char e[24]; snprintf_P(e, sizeof(e), PSTR("HTTP %d"), code);
        return fail(code, e);
    }

    JsonDocument doc;
    auto err = deserializeJson(doc, http.getStream());
    http.end();
    if (err) {
        char e[24]; snprintf_P(e, sizeof(e), PSTR("JSON %s"), err.c_str());
        return fail(0, e);
    }

    JsonObject cur = doc[F("current")].as<JsonObject>();
    if (cur.isNull()) return fail(0, "no current");

    WeatherData w;
    w.tempC    = cur[F("temperature_2m")]       | -999.0f;
    w.feelsC   = cur[F("apparent_temperature")] | w.tempC;
    w.code     = cur[F("weather_code")]         | 0;
    // Open-Meteo sends is_day as 0/1 — read it as an int, not a JSON bool.
    w.isDay    = cur[F("is_day")].isNull() ? true : (cur[F("is_day")].as<int>() != 0);
    w.humidity = cur[F("relative_humidity_2m")] | -1;
    w.windKmh  = cur[F("wind_speed_10m")]       | -1.0f;

    JsonObject daily = doc[F("daily")].as<JsonObject>();
    for (int i = 0; i < 4; i++) {
        WeatherDay& d = w.forecast[i];
        d.tmin    = daily[F("temperature_2m_min")][i] | -999.0f;
        d.tmax    = daily[F("temperature_2m_max")][i] | -999.0f;
        d.code    = daily[F("weather_code")][i]       | 0;
        d.uvMax   = daily[F("uv_index_max")][i]       | -1.0f;
        d.sunrise = (time_t)(daily[F("sunrise")][i]   | 0L);
        d.sunset  = (time_t)(daily[F("sunset")][i]    | 0L);
    }

    JsonObject hourly = doc[F("hourly")].as<JsonObject>();
    w.rainStart = (time_t)(hourly[F("time")][0] | 0L);
    for (int i = 0; i < 12; i++) {
        JsonVariant p = hourly[F("precipitation_probability")][i];
        w.rainPct[i] = p.isNull() ? 255 : (uint8_t)p.as<int>();
    }

    FetchPolicy::onSuccess(s_pol, time(nullptr));
    w.valid  = true;
    w.lastOk = s_pol.lastOk;
    s_w = w;
    save();
    return true;
}

void rainHint(const Settings& s, char* buf, size_t n) {
    if (n) buf[0] = '\0';
    if (!s_w.valid || !s_w.rainStart) return;
    time_t now = time(nullptr);
    int best = -1, bestPct = 0;
    for (int i = 0; i < 12; i++) {
        time_t slot = s_w.rainStart + i * 3600L;
        if (slot + 3600 <= now || s_w.rainPct[i] == 255) continue;
        if (s_w.rainPct[i] > bestPct) { bestPct = s_w.rainPct[i]; best = i; }
    }
    if (best < 0 || bestPct < 40) return;
    time_t at = s_w.rainStart + best * 3600L;
    struct tm tm; localtime_r(&at, &tm);
    if (at <= now)            snprintf_P(buf, n, PSTR("MƯA %d%% NGAY"), bestPct);
    else if (s.clock24h)      snprintf_P(buf, n, PSTR("MƯA %d%% %02d:00"), bestPct, tm.tm_hour);
    else {
        int h12 = tm.tm_hour % 12; if (!h12) h12 = 12;
        snprintf_P(buf, n, PSTR("MƯA %d%% %d%s"), bestPct, h12, tm.tm_hour < 12 ? "SA" : "CH");   // token text.ampm
    }
}

const char* describe(uint8_t code) {
    // WMO weather interpretation codes — compressed to short labels
    if (code == 0) return "Quang";
    if (code == 1 || code == 2) return "Ít mây";
    if (code == 3) return "Nhiều mây";
    if (code == 45 || code == 48) return "Sương mù";
    if (code >= 51 && code <= 57) return "Mưa phùn";
    if (code >= 61 && code <= 67) return "Mưa";
    if (code >= 71 && code <= 77) return "Tuyết";
    if (code == 80 || code == 81 || code == 82) return "Mưa rào";
    if (code == 85 || code == 86) return "Mưa tuyết";
    if (code >= 95 && code <= 99) return "Dông";
    return "--";                        // L-3: U+2014 is not in the VLW glyph set
}

float toDisplay(float c, bool fahrenheit) {
    if (c <= -900.0f) return c;
    return fahrenheit ? (c * 9.0f / 5.0f + 32.0f) : c;
}

}  // namespace Weather
