// Host tests for glimmer's pure logic: usage parsers, fetch policy, time
// parsing, history pace/trend and the night window. Run: pio test -e native
#include <unity.h>
#include <ArduinoJson.h>
#include "usage_parse.h"
#include "fetch_policy.h"
#include "history_core.h"
#include "night_core.h"
#include "timeutil.h"
#include "attention_core.h"
#include "attention_json.h"
#include "utf8.h"
#include "skill_core.h"
#include "projects_core.h"
#include "xp_core.h"
#include "photos_core.h"
#include "control_core.h"
#include "clock_core.h"
#include "desk_wallpaper.h"
#include "clawd_work_core.h"
#include "clawd_work.h"
#include "cursor_core.h"
#include "mines_core.h"
#include "pointer_core.h"
#include <time.h>
#include <initializer_list>
#if defined(_WIN32)   // host tests on Windows (MinGW) lack the POSIX localtime_r
static inline struct tm* localtime_r(const time_t* t, struct tm* out) { *out = *localtime(t); return out; }
#endif
#include "clockfmt.h"
#include "qr_payload.h"
#include <qrcode.h>

void setUp() {}
void tearDown() {}

static const time_t T0 = 1790000000;   // 2026-09-21, an arbitrary synced "now"

// Parse a payload through the same filter the device uses.
template <class D, class FilterFn, class ParseFn>
static bool parseFiltered(const char* json, D& out, FilterFn filterFn, ParseFn parseFn) {
    JsonDocument filter; filterFn(filter);
    JsonDocument doc;
    TEST_ASSERT_FALSE(deserializeJson(doc, json, DeserializationOption::Filter(filter)));
    return parseFn(doc.template as<JsonVariantConst>(), out);
}

// ── Claude ──────────────────────────────────────────────────────────────────

void test_claude_limits_drive_windows_and_ignore_codenames() {
    const char* json = R"({
      "five_hour": {"utilization": 99, "resets_at": "2026-09-21T10:00:00Z"},
      "seven_day": {"utilization": 99, "resets_at": "2026-09-25T00:00:00Z"},
      "seven_day_opus": {"utilization": 50},
      "nimbus_quill": {"utilization": 0.0},
      "tangelo": null,
      "limits": [
        {"kind": "session",    "percent": 20, "resets_at": "2026-09-21T12:00:00+00:00"},
        {"kind": "weekly_all", "percent": 40, "resets_at": "2026-09-26T00:00:00Z"},
        {"kind": "weekly_scoped", "percent": 30, "scope": {"model": {"display_name": "Fable", "id": null}}},
        {"kind": "weekly_scoped", "percent": 10, "scope": {"model": {"display_name": "Opus"}}}
      ]
    })";
    ClaudeData d;
    TEST_ASSERT_TRUE(parseFiltered(json, d, UsageParse::claudeFilter, UsageParse::claude));
    TEST_ASSERT_EQUAL_FLOAT(80.0f, d.sessionPct);
    TEST_ASSERT_EQUAL_FLOAT(60.0f, d.weeklyPct);
    TEST_ASSERT_EQUAL(TimeUtil::epochUtc(2026, 9, 21, 12, 0, 0), d.sessionReset);
    TEST_ASSERT_EQUAL_STRING("FABLE", d.models[0].label);
    TEST_ASSERT_EQUAL_FLOAT(70.0f, d.models[0].pct);
    TEST_ASSERT_EQUAL_STRING("OPUS", d.models[1].label);
    TEST_ASSERT_EQUAL_FLOAT(90.0f, d.models[1].pct);
    // seven_day_opus is the pre-limits[] spelling → skipped; the codename never appears.
    TEST_ASSERT_EQUAL_FLOAT(-1.0f, d.models[2].pct);
    TEST_ASSERT_EQUAL_STRING("", d.models[2].label);
}

void test_claude_flat_fallback_uses_allowlist_only() {
    const char* json = R"({
      "five_hour": {"utilization": 25, "resets_at": "2026-09-21T10:00:00.000Z"},
      "seven_day": {"utilization": 60},
      "seven_day_opus": {"utilization": 50},
      "nimbus_quill": {"utilization": 0.0},
      "extra_usage": {"utilization": 5}
    })";
    ClaudeData d;
    TEST_ASSERT_TRUE(parseFiltered(json, d, UsageParse::claudeFilter, UsageParse::claude));
    TEST_ASSERT_EQUAL_FLOAT(75.0f, d.sessionPct);
    TEST_ASSERT_EQUAL_FLOAT(40.0f, d.weeklyPct);
    TEST_ASSERT_EQUAL_STRING("OPUS", d.models[0].label);
    TEST_ASSERT_EQUAL_FLOAT(50.0f, d.models[0].pct);
    TEST_ASSERT_EQUAL_STRING("EXTRA", d.models[1].label);
    TEST_ASSERT_EQUAL_FLOAT(95.0f, d.models[1].pct);
    TEST_ASSERT_EQUAL_STRING("", d.models[2].label);
}

void test_claude_unrecognised_shape_is_rejected() {
    ClaudeData d;
    TEST_ASSERT_FALSE(parseFiltered(R"({"type":"error","error":{"message":"nope"}})", d,
                                    UsageParse::claudeFilter, UsageParse::claude));
}

// ── Codex ───────────────────────────────────────────────────────────────────

void test_codex_primary_plus_additional_limit_tag() {
    const char* json = R"({
      "plan_type": "pro",
      "rate_limit": {
        "primary_window": {"used_percent": 35, "reset_at": 1790500000, "limit_window_seconds": 604800},
        "secondary_window": null
      },
      "additional_rate_limits": [
        {"limit_name": "codex-spark", "rate_limit": {"primary_window": {"used_percent": 10, "reset_at": 1790100000, "limit_window_seconds": 18000}}}
      ],
      "credits": {"has_credits": true, "balance": "12.50"}
    })";
    CodexData d;
    TEST_ASSERT_TRUE(parseFiltered(json, d, UsageParse::codexFilter, UsageParse::codex));
    TEST_ASSERT_EQUAL_FLOAT(65.0f, d.primaryPct);
    TEST_ASSERT_EQUAL(604800, d.primaryWinSec);
    TEST_ASSERT_EQUAL_FLOAT(90.0f, d.secondaryPct);
    TEST_ASSERT_EQUAL_STRING("SPARK", d.secondaryTag);
    TEST_ASSERT_EQUAL_FLOAT(12.5f, d.creditsRemain);
}

void test_codex_missing_primary_is_rejected() {
    CodexData d;
    TEST_ASSERT_FALSE(parseFiltered(R"({"rate_limit":{}})", d, UsageParse::codexFilter, UsageParse::codex));
}

// ── Time ────────────────────────────────────────────────────────────────────

void test_iso8601_variants() {
    time_t base = TimeUtil::epochUtc(2026, 9, 21, 10, 0, 0);
    TEST_ASSERT_EQUAL(base, TimeUtil::parseIso8601("2026-09-21T10:00:00Z"));
    TEST_ASSERT_EQUAL(base, TimeUtil::parseIso8601("2026-09-21T10:00:00.123456+00:00"));
    TEST_ASSERT_EQUAL(base, TimeUtil::parseIso8601("2026-09-21T15:30:00+05:30"));
    TEST_ASSERT_EQUAL(0, TimeUtil::parseIso8601("garbage"));
    TEST_ASSERT_EQUAL(0, TimeUtil::epochUtc(1970, 1, 1, 0, 0, 0));
}

// ── Fetch policy ────────────────────────────────────────────────────────────

void test_backoff_steps_and_cap() {
    FetchPolicy::State st;
    uint32_t expect[] = {60, 120, 240, 300, 300};
    for (uint32_t e : expect) { FetchPolicy::onFailure(st, -1, -1); TEST_ASSERT_EQUAL_UINT32(e, st.waitS); }
    FetchPolicy::onSuccess(st, T0);
    TEST_ASSERT_EQUAL(0, st.fails);
    TEST_ASSERT_EQUAL_UINT32(0, st.waitS);
    TEST_ASSERT_EQUAL(T0, st.lastOk);
}

void test_auth_latch_needs_two_consecutive() {
    FetchPolicy::State st;
    FetchPolicy::onFailure(st, 403, -1);
    TEST_ASSERT_FALSE(st.authLatched);
    FetchPolicy::onFailure(st, 500, -1);          // a non-auth error breaks the streak
    FetchPolicy::onFailure(st, 401, -1);
    TEST_ASSERT_FALSE(st.authLatched);
    FetchPolicy::onFailure(st, 401, -1);
    TEST_ASSERT_TRUE(st.authLatched);
    TEST_ASSERT_TRUE(FetchPolicy::shouldSurface(st));
    FetchPolicy::onSuccess(st, T0);
    TEST_ASSERT_FALSE(st.authLatched);
}

void test_silent_failures_before_surfacing() {
    FetchPolicy::State st;
    FetchPolicy::onFailure(st, -1, -1);
    FetchPolicy::onFailure(st, -1, -1);
    TEST_ASSERT_FALSE(FetchPolicy::shouldSurface(st));
    FetchPolicy::onFailure(st, -1, -1);
    TEST_ASSERT_TRUE(FetchPolicy::shouldSurface(st));
}

void test_retry_after_seconds_date_and_cap() {
    TEST_ASSERT_EQUAL(-1, FetchPolicy::retryAfterSec("", T0));
    TEST_ASSERT_EQUAL(120, FetchPolicy::retryAfterSec("120", T0));
    TEST_ASSERT_EQUAL(6 * 3600, FetchPolicy::retryAfterSec("999999", T0));
    time_t at = TimeUtil::parseHttpDate("Wed, 21 Oct 2015 07:28:00 GMT");
    TEST_ASSERT_EQUAL(TimeUtil::epochUtc(2015, 10, 21, 7, 28, 0), at);
    TEST_ASSERT_EQUAL(600, FetchPolicy::retryAfterSec("Wed, 21 Oct 2015 07:28:00 GMT", at - 600));
    TEST_ASSERT_EQUAL(-1, FetchPolicy::retryAfterSec("Someday", T0));

    FetchPolicy::State st;                          // Retry-After beats a shorter backoff step
    FetchPolicy::onFailure(st, 429, 900);
    TEST_ASSERT_EQUAL_UINT32(900, st.waitS);
}

// ── History ─────────────────────────────────────────────────────────────────

static History::Ring ring;

void test_history_slot_tag_rejects_previous_lap() {
    History::clear(ring);
    History::record(ring, T0, History::CODEX_WEEK, 80);
    uint32_t h = (uint32_t)(T0 / 3600);
    TEST_ASSERT_EQUAL_INT8(80, History::at(ring, h, History::CODEX_WEEK));
    TEST_ASSERT_EQUAL_INT8(-1, History::at(ring, h + History::kSlots, History::CODEX_WEEK));
    TEST_ASSERT_EQUAL_INT8(-1, History::at(ring, h, History::CLAUDE_WEEK));
}

void test_history_last_reading() {
    History::clear(ring);
    TEST_ASSERT_EQUAL(0, History::lastReading(ring, History::CODEX_WEEK, T0));
    History::record(ring, T0 - 30 * 3600, History::CODEX_WEEK, 40);
    History::record(ring, T0 - 5 * 3600,  History::CODEX_WEEK, 30);
    TEST_ASSERT_EQUAL((T0 / 3600 - 5) * 3600, History::lastReading(ring, History::CODEX_WEEK, T0));
    TEST_ASSERT_EQUAL(0, History::lastReading(ring, History::CLAUDE_WEEK, T0));
}

void test_pace_empty_before_reset() {
    History::clear(ring);
    // 10 points per hour over the last 4 hours: 90 → 50.
    for (int i = 4; i >= 1; i--) History::record(ring, T0 - i * 3600, History::CLAUDE_WEEK, 50 + i * 10);
    History::Pace p = History::pace(ring, History::CLAUDE_WEEK, 50, T0, T0 + 24 * 3600);
    TEST_ASSERT_EQUAL(History::Pace::EMPTY, p.kind);
    TEST_ASSERT_INT_WITHIN(60, 5 * 3600, p.sec);     // 50 left at 10/h ≈ 5 h
    char buf[40]; History::paceText(p, buf, sizeof(buf));
    TEST_ASSERT_EQUAL_STRING("HẾT SAU 5G", buf);
}

void test_pace_lasts_until_reset() {
    History::clear(ring);
    for (int i = 4; i >= 1; i--) History::record(ring, T0 - i * 3600, History::CLAUDE_WEEK, 80 + i);
    History::Pace p = History::pace(ring, History::CLAUDE_WEEK, 80, T0, T0 + 10 * 3600);
    TEST_ASSERT_EQUAL(History::Pace::AT_RESET, p.kind);
    TEST_ASSERT_EQUAL(70, p.pct);                    // 1 point/h for 10 h
    char buf[40]; History::paceText(p, buf, sizeof(buf));
    TEST_ASSERT_EQUAL_STRING("~70% KHI ĐẶT LẠI", buf);
}

void test_pace_stops_at_window_reset_and_needs_span() {
    History::clear(ring);
    History::record(ring, T0 - 5 * 3600, History::CODEX_WEEK, 5);    // previous window
    History::record(ring, T0 - 1 * 3600, History::CODEX_WEEK, 100);  // after the reset
    History::Pace p = History::pace(ring, History::CODEX_WEEK, 98, T0, T0 + 3 * 86400);
    TEST_ASSERT_EQUAL(History::Pace::NONE, p.kind);  // only 1 h in this window
}

void test_trend_sums_drops_and_skips_resets() {
    History::clear(ring);
    // Today (UTC): 100 → 90 → 95 (reset, ignored) → 80 = 10 + 15 = 25 used.
    time_t day0 = (T0 / 86400) * 86400;              // today's UTC midnight
    time_t now  = day0 + 12 * 3600;
    History::record(ring, day0 + 1 * 3600, History::CLAUDE_WEEK, 100);
    History::record(ring, day0 + 2 * 3600, History::CLAUDE_WEEK, 90);
    History::record(ring, day0 + 3 * 3600, History::CLAUDE_WEEK, 95);
    History::record(ring, day0 + 4 * 3600, History::CLAUDE_WEEK, 80);
    // Yesterday: 60 → 20 = 40 used (the heaviest day).
    History::record(ring, day0 - 20 * 3600, History::CLAUDE_WEEK, 60);
    History::record(ring, day0 - 10 * 3600, History::CLAUDE_WEEK, 20);
    History::Trend t = History::trend(ring, History::CLAUDE_WEEK, now, 0);
    TEST_ASSERT_TRUE(t.have[6]);
    TEST_ASSERT_EQUAL_FLOAT(25.0f, t.burn[6]);
    TEST_ASSERT_EQUAL_FLOAT(40.0f, t.burn[5]);
    TEST_ASSERT_EQUAL(5, t.heaviest);
    TEST_ASSERT_FALSE(t.have[0]);
}

// ── Credential state ────────────────────────────────────────────────────────

void test_markup_403_blocks_but_never_latches_auth() {
    FetchPolicy::State st;
    FetchPolicy::onFailure(st, 403, -1, true);
    FetchPolicy::onFailure(st, 403, -1, true);
    FetchPolicy::onFailure(st, 403, -1, true);
    TEST_ASSERT_FALSE(st.authLatched);
    TEST_ASSERT_TRUE(FetchPolicy::blocked(st));
    TEST_ASSERT_TRUE(st.waitS >= FetchPolicy::kBlockedWaitS);
    TEST_ASSERT_EQUAL(Cred::BLOCKED, CredState::derive(true, st, 0, T0, true));
    // A JSON 403 after the challenges starts the auth count from scratch.
    FetchPolicy::onFailure(st, 403, -1, false);
    TEST_ASSERT_FALSE(FetchPolicy::blocked(st));
    TEST_ASSERT_FALSE(st.authLatched);
}

void test_jwt_exp_decode() {
    TEST_ASSERT_EQUAL(1790000000,
        CredState::jwtExp("eyJhbGciOiJub25lIn0.eyJzdWIiOiJ1LTEiLCJleHAiOjE3OTAwMDAwMDAsImlhdCI6MTc4OTAwMDAwMH0.sig"));
    TEST_ASSERT_EQUAL(1790003600,
        CredState::jwtExp("eyJhbGciOiJub25lIn0.eyJodHRwczovL2FwaS5vcGVuYWkuY29tL2F1dGgiOnsieCI6MX0sImV4cCI6MTc5MDAwMzYwMH0.s"));
    // Regression: real access tokens carry 1-2 KB of claims with `exp` near
    // the end, after an "expires_in" decoy. A bounded buffer missed it.
    static const char kLong[] =
    "eyJhbGciOiJSUzI1NiJ9.eyJodHRwczovL2FwaS5vcGVuYWkuY29tL3Byb2ZpbGUiOnsiZW1haWwiOiJ4eHh4eHh4e"
    "Hh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh"
    "4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4e"
    "Hh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh"
    "4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4e"
    "Hh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh"
    "4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4In0sInNjcCI6WyJhY"
    "WFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWF"
    "hYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhY"
    "WFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWF"
    "hYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhY"
    "WFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWEiLCJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJ"
    "iYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiY"
    "mJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJ"
    "iYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiY"
    "mJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmIiXSwiZXh"
    "waXJlc19pbiI6OTk5LCJleHAiOjE3NTQyNTE4Njl9.sig";
    TEST_ASSERT_TRUE(strlen(kLong) > 1400);
    TEST_ASSERT_EQUAL(1754251869, CredState::jwtExp(kLong));
    TEST_ASSERT_EQUAL(0, CredState::jwtExp("sk-ant-sid02-not-a-jwt"));
    TEST_ASSERT_EQUAL(0, CredState::jwtExp("a.b"));
    TEST_ASSERT_EQUAL(0, CredState::jwtExp(""));
}

void test_cred_derivation_order() {
    FetchPolicy::State ok;
    TEST_ASSERT_EQUAL(Cred::NOT_SET,  CredState::derive(false, ok, 0, T0, false));
    TEST_ASSERT_EQUAL(Cred::CHECKING, CredState::derive(true,  ok, 0, T0, false));
    TEST_ASSERT_EQUAL(Cred::OK,       CredState::derive(true,  ok, 0, T0, true));
    TEST_ASSERT_EQUAL(Cred::EXPIRING, CredState::derive(true,  ok, T0 + 3600, T0, true));
    TEST_ASSERT_EQUAL(Cred::OK,       CredState::derive(true,  ok, T0 + 30L * 86400L, T0, true));
    TEST_ASSERT_EQUAL(Cred::EXPIRED,  CredState::derive(true,  ok, T0 - 1, T0, true));
    FetchPolicy::State rej;
    FetchPolicy::onFailure(rej, 401, -1);
    FetchPolicy::onFailure(rej, 401, -1);
    TEST_ASSERT_EQUAL(Cred::REJECTED, CredState::derive(true, rej, 0, T0, true));
    // Our own clock's verdict (expired JWT) outranks upstream's.
    TEST_ASSERT_EQUAL(Cred::EXPIRED,  CredState::derive(true, rej, T0 - 1, T0, true));
    TEST_ASSERT_TRUE(CredState::bad(Cred::BLOCKED));
    TEST_ASSERT_FALSE(CredState::bad(Cred::EXPIRING));
}

void test_cred_meta_labels() {
    char b[24];
    CredState::meta(Cred::EXPIRING, T0 + 2 * 86400L + 60, T0, b, sizeof(b));
    TEST_ASSERT_EQUAL_STRING("HẠN 2NG", b);
    CredState::meta(Cred::REJECTED, 0, T0, b, sizeof(b));
    TEST_ASSERT_EQUAL_STRING("KHÓA LỖI", b);
    CredState::meta(Cred::OK, 0, T0, b, sizeof(b));
    TEST_ASSERT_EQUAL_STRING("", b);
}

void test_notice_rate_limit() {
    CredState::NoticeLog log;
    TEST_ASSERT_TRUE(CredState::noticeDue(log, CredState::NOTICE_BAD, T0));
    log.last[CredState::NOTICE_BAD] = T0;
    TEST_ASSERT_FALSE(CredState::noticeDue(log, CredState::NOTICE_BAD, T0 + 11 * 3600));
    TEST_ASSERT_TRUE (CredState::noticeDue(log, CredState::NOTICE_BAD, T0 + 12 * 3600));
    TEST_ASSERT_TRUE (CredState::noticeDue(log, CredState::NOTICE_EXPIRING, T0));
}

// ── Reset credits ───────────────────────────────────────────────────────────

void test_claude_grants_found_under_any_key() {
    const char* json = R"({
      "five_hour": {"utilization": 10},
      "seven_day": {"utilization": 20},
      "cedar_thing": {"grants": [
        {"resets_left": 1, "ends_at": "2026-10-20T00:00:00Z", "usable_now": false, "clears": ["seven_day"]},
        {"resets_left": 2, "ends_at": "2026-10-25T00:00:00Z", "usable_now": true,  "clears": ["five_hour", "seven_day"]}
      ]},
      "other": {"utilization": 5}
    })";
    ClaudeData d;
    TEST_ASSERT_TRUE(parseFiltered(json, d, UsageParse::claudeFilter, UsageParse::claude));
    TEST_ASSERT_EQUAL_UINT8(2, d.resets.left);          // usable beats sooner-but-locked
    TEST_ASSERT_TRUE(d.resets.usable);
    TEST_ASSERT_EQUAL(TimeUtil::epochUtc(2026, 10, 25, 0, 0, 0), d.resets.endsAt);
    TEST_ASSERT_EQUAL_STRING("session + weekly", d.resets.title);
}

void test_claude_without_grants_has_no_resets() {
    ClaudeData d;
    TEST_ASSERT_TRUE(parseFiltered(R"({"five_hour":{"utilization":1},"x":{"grants":[]}})", d,
                                   UsageParse::claudeFilter, UsageParse::claude));
    TEST_ASSERT_EQUAL_UINT8(0, d.resets.left);
}

void test_codex_reset_credits() {
    const char* json = R"({"available_count": 2, "credits": [
        {"status": "used",      "expires_at": "2026-10-09T00:00:00Z", "title": "old"},
        {"status": "available", "expires_at": "2026-10-30T00:00:00Z", "title": "later"},
        {"status": "available", "expires_at": "2026-10-12T00:00:00Z", "title": "Weekly reset"}
    ]})";
    ResetGrant g;
    TEST_ASSERT_TRUE(parseFiltered(json, g, UsageParse::codexResetsFilter, UsageParse::codexResets));
    TEST_ASSERT_EQUAL_UINT8(2, g.left);
    TEST_ASSERT_EQUAL(TimeUtil::epochUtc(2026, 10, 12, 0, 0, 0), g.endsAt);
    TEST_ASSERT_EQUAL_STRING("Weekly reset", g.title);

    TEST_ASSERT_TRUE(parseFiltered(R"({"available_count": 0, "credits": []})", g,
                                   UsageParse::codexResetsFilter, UsageParse::codexResets));
    TEST_ASSERT_EQUAL_UINT8(0, g.left);
}

// ── Attention queue ─────────────────────────────────────────────────────────

static Attention::Item mk(const char* id, Attention::Kind k, uint32_t expires = 0) {
    Attention::Item it;
    snprintf(it.id, sizeof(it.id), "%s", id);
    it.kind = k;
    it.expires = expires;
    return it;
}

void test_attention_upsert_updates_in_place() {
    Attention::Queue q;
    bool fresh = false;
    Attention::Item a = mk("build", Attention::K_PROGRESS);
    a.progress = 10;
    TEST_ASSERT_TRUE(Attention::upsert(q, a, 100, &fresh) >= 0);
    TEST_ASSERT_TRUE(fresh);
    a.progress = 60;
    Attention::upsert(q, a, 200, &fresh);
    TEST_ASSERT_FALSE(fresh);                                 // same id → no new interruption
    TEST_ASSERT_EQUAL(1, Attention::count(q));
    int i = Attention::find(q, "build");
    TEST_ASSERT_EQUAL_INT8(60, q.items[i].progress);
    TEST_ASSERT_EQUAL_UINT32(100, q.items[i].created);       // age kept across updates
    // Escalation (progress → error) counts as fresh and restarts the age.
    Attention::upsert(q, mk("build", Attention::K_ERROR), 300, &fresh);
    TEST_ASSERT_TRUE(fresh);
    TEST_ASSERT_EQUAL_UINT32(300, q.items[i].created);
}

void test_attention_order_and_eviction() {
    Attention::Queue q;
    Attention::upsert(q, mk("i1", Attention::K_INFO), 1);
    Attention::upsert(q, mk("a1", Attention::K_APPROVAL), 2);
    Attention::upsert(q, mk("s1", Attention::K_SUCCESS), 3);
    Attention::upsert(q, mk("a0", Attention::K_APPROVAL), 4);
    Attention::upsert(q, mk("e1", Attention::K_ERROR), 5);
    int ord[Attention::kMax];
    TEST_ASSERT_EQUAL(5, Attention::ordered(q, ord));
    TEST_ASSERT_EQUAL_STRING("a1", q.items[ord[0]].id);       // oldest approval first
    TEST_ASSERT_EQUAL_STRING("a0", q.items[ord[1]].id);
    TEST_ASSERT_EQUAL_STRING("e1", q.items[ord[2]].id);
    TEST_ASSERT_EQUAL_STRING("i1", q.items[ord[4]].id);
    // Full: a warning evicts the info card.
    TEST_ASSERT_TRUE(Attention::upsert(q, mk("w1", Attention::K_WARNING), 6) >= 0);
    TEST_ASSERT_EQUAL(-1, Attention::find(q, "i1"));
    // Fill with approvals; an info card can then not get in.
    Attention::Queue full;
    for (int k = 0; k < Attention::kMax; k++) {
        char id[8]; snprintf(id, sizeof(id), "a%d", k);
        Attention::upsert(full, mk(id, Attention::K_APPROVAL), 10 + k);
    }
    TEST_ASSERT_EQUAL(-1, Attention::upsert(full, mk("x", Attention::K_ERROR), 20));
    TEST_ASSERT_EQUAL(Attention::kMax, Attention::countWaiting(full, 100));
}

void test_attention_expire_and_clear() {
    Attention::Queue q;
    Attention::upsert(q, mk("t", Attention::K_INFO, 50), 10);
    Attention::upsert(q, mk("forever", Attention::K_INFO, 0), 10);
    TEST_ASSERT_EQUAL(0, Attention::expire(q, 49));
    TEST_ASSERT_EQUAL(1, Attention::expire(q, 50));
    TEST_ASSERT_TRUE(Attention::clear(q, "forever"));
    TEST_ASSERT_FALSE(Attention::clear(q, "forever"));
    TEST_ASSERT_EQUAL(0, Attention::count(q));
}

void test_attention_holds_screen() {
    Attention::Item it = mk("x", Attention::K_INFO);
    it.used = true; it.interruptUntil = 130;
    TEST_ASSERT_TRUE(Attention::holdsScreen(it, 100, true));
    TEST_ASSERT_FALSE(Attention::holdsScreen(it, 130, true));
    it.display = Attention::SHOW_QUEUE;
    TEST_ASSERT_FALSE(Attention::holdsScreen(it, 100, true));  // queued: listed only
    Attention::Item ap = mk("y", Attention::K_APPROVAL);
    ap.used = true; ap.interruptUntil = 0;
    TEST_ASSERT_TRUE(Attention::holdsScreen(ap, 999, true));   // pinned until answered
    TEST_ASSERT_FALSE(Attention::holdsScreen(ap, 999, false));
}

void test_attention_hook_mapping() {
    Attention::Item it;
    Attention::HookEvent e;
    e.event = "Notification"; e.type = "permission_prompt";
    e.session = "abcdef0123456789"; e.cwd = "/Users/me/src/glimmer/";
    e.message = "Claude needs your permission to use Bash";
    TEST_ASSERT_EQUAL(Attention::HOOK_UPSERT,
        Attention::fromHook(Attention::AGENT_CLAUDE, e, false, 1800, 1000, it));
    TEST_ASSERT_EQUAL(Attention::K_APPROVAL, it.kind);
    TEST_ASSERT_EQUAL_STRING("claude:abcdef01", it.id);
    TEST_ASSERT_EQUAL_STRING("glimmer", it.project);
    TEST_ASSERT_EQUAL_STRING("wants to use Bash", it.body);
    TEST_ASSERT_EQUAL_UINT32(2800, it.expires);

    // Codex PermissionRequest with the command as detail.
    Attention::HookEvent c;
    c.event = "PermissionRequest"; c.session = "s1"; c.tool = "Bash"; c.detail = "pio run";
    Attention::fromHook(Attention::AGENT_CODEX, c, false, 1800, 1000, it);
    TEST_ASSERT_EQUAL(Attention::K_APPROVAL, it.kind);
    TEST_ASSERT_EQUAL_STRING("codex:s1", it.id);
    TEST_ASSERT_EQUAL_STRING("Bash: pio run", it.body);

    Attention::HookEvent idle; idle.event = "Notification"; idle.type = "idle_prompt"; idle.session = "s1";
    Attention::fromHook(Attention::AGENT_CLAUDE, idle, false, 1800, 1000, it);
    TEST_ASSERT_EQUAL(Attention::K_INPUT, it.kind);

    const char* clears[] = {"PostToolUse", "PostToolUseFailure", "UserPromptSubmit", "SessionEnd", "Stop"};
    for (const char* ev : clears) {
        Attention::HookEvent x; x.event = ev; x.session = "s1";
        TEST_ASSERT_EQUAL(Attention::HOOK_CLEAR,
            Attention::fromHook(Attention::AGENT_CLAUDE, x, false, 1800, 1000, it));
        TEST_ASSERT_EQUAL_STRING("claude:s1", it.id);
    }
    // Stop with done cards on → a short success card replacing the session's card.
    Attention::HookEvent stop; stop.event = "Stop"; stop.session = "s1";
    TEST_ASSERT_EQUAL(Attention::HOOK_UPSERT,
        Attention::fromHook(Attention::AGENT_CLAUDE, stop, true, 1800, 1000, it));
    TEST_ASSERT_EQUAL(Attention::K_SUCCESS, it.kind);
    TEST_ASSERT_EQUAL_UINT32(1020, it.expires);
    // Unrelated events do nothing.
    Attention::HookEvent pre; pre.event = "PreToolUse";
    TEST_ASSERT_EQUAL(Attention::HOOK_NONE,
        Attention::fromHook(Attention::AGENT_CLAUDE, pre, true, 1800, 1000, it));
}

void test_codex_stop_is_a_delayed_your_turn() {
    Attention::Item it, extra;
    Attention::HookEvent stop;
    stop.event = "Stop"; stop.session = "abcd1234-x"; stop.cwd = "/w/api";
    stop.message = "Which database should the migration target?";
    TEST_ASSERT_EQUAL(Attention::HOOK_UPSERT,
        Attention::fromHook(Attention::AGENT_CODEX, stop, false, 1800, 1000, it, &extra));
    TEST_ASSERT_EQUAL(Attention::K_INPUT, it.kind);
    TEST_ASSERT_EQUAL_STRING("codex:abcd1234", it.id);
    TEST_ASSERT_EQUAL_UINT32(1000 + Attention::kCodexIdleS, it.showAfter);
    TEST_ASSERT_FALSE(extra.used);                            // done cards off

    // Hidden for the first minute: not listed, not holding, not counted.
    Attention::Queue q;
    Attention::upsert(q, it, 1000);
    int ord[Attention::kMax];
    TEST_ASSERT_EQUAL(0, Attention::ordered(q, ord, 1030));
    TEST_ASSERT_EQUAL(0, Attention::countWaiting(q, 1030));
    TEST_ASSERT_FALSE(Attention::holdsScreen(q.items[0], 1030, true));
    TEST_ASSERT_EQUAL(1, Attention::ordered(q, ord, 1060));
    TEST_ASSERT_EQUAL(1, Attention::countWaiting(q, 1060));
    TEST_ASSERT_TRUE(Attention::holdsScreen(q.items[0], 1060, true));
    TEST_ASSERT_EQUAL(1, Attention::ordered(q, ord));       // unfiltered list still has it

    // A reply before then clears it — nothing ever shows.
    Attention::HookEvent reply; reply.event = "UserPromptSubmit"; reply.session = "abcd1234-x";
    Attention::Item c;
    TEST_ASSERT_EQUAL(Attention::HOOK_CLEAR,
        Attention::fromHook(Attention::AGENT_CODEX, reply, false, 1800, 1010, c));
    TEST_ASSERT_TRUE(Attention::clear(q, c.id));

    // Done cards on: a DONE card now, next to the delayed your-turn card.
    Attention::fromHook(Attention::AGENT_CODEX, stop, true, 1800, 1000, it, &extra);
    TEST_ASSERT_TRUE(extra.used);
    TEST_ASSERT_EQUAL(Attention::K_SUCCESS, extra.kind);
    TEST_ASSERT_EQUAL_STRING("codex:abcd1234:done", extra.id);
    TEST_ASSERT_EQUAL_UINT32(0, extra.showAfter);
    TEST_ASSERT_EQUAL(Attention::K_INPUT, it.kind);
}

void test_attention_json_legacy_and_new() {
    JsonDocument d;
    // Legacy /push body: colour → kind, duration holds the screen throughout.
    deserializeJson(d, R"({"title":"Build #2310","value":"passed","subtitle":"main","color":"mint","duration_s":45})");
    Attention::Item it;
    Attention::fromJson(d.as<JsonVariantConst>(), 1000, 1800, 7, it);
    TEST_ASSERT_EQUAL(Attention::K_SUCCESS, it.kind);
    TEST_ASSERT_EQUAL_STRING("push:7", it.id);
    TEST_ASSERT_EQUAL_STRING("passed", it.value);
    TEST_ASSERT_EQUAL_STRING("main", it.body);
    TEST_ASSERT_EQUAL_UINT32(1045, it.expires);
    TEST_ASSERT_EQUAL_UINT32(1045, it.interruptUntil);

    deserializeJson(d, R"({"id":"tests","kind":"progress","title":"TESTS","progress":64,"agent":"codex"})");
    Attention::fromJson(d.as<JsonVariantConst>(), 1000, 1800, 8, it);
    TEST_ASSERT_EQUAL_STRING("tests", it.id);
    TEST_ASSERT_EQUAL(Attention::SHOW_QUEUE, it.display);     // progress defaults to queue
    TEST_ASSERT_EQUAL_STRING("64%", it.value);
    TEST_ASSERT_EQUAL(Attention::AGENT_CODEX, it.agent);
    TEST_ASSERT_EQUAL_UINT32(1000 + 3600, it.expires);

    deserializeJson(d, R"({"title":"BLOCKED","kind":"approval","ttl_s":0})");
    Attention::fromJson(d.as<JsonVariantConst>(), 1000, 1800, 9, it);
    TEST_ASSERT_EQUAL_UINT32(0, it.expires);                  // until cleared
    TEST_ASSERT_EQUAL_UINT32(1000 + Attention::kInterruptS, it.interruptUntil);
}

// ── Night ───────────────────────────────────────────────────────────────────

void test_night_window_wraps_and_disables() {
    TEST_ASSERT_TRUE (Night::inWindow(23 * 60, 22 * 60 + 30, 7 * 60));
    TEST_ASSERT_TRUE (Night::inWindow(6 * 60 + 59, 22 * 60 + 30, 7 * 60));
    TEST_ASSERT_FALSE(Night::inWindow(7 * 60, 22 * 60 + 30, 7 * 60));
    TEST_ASSERT_FALSE(Night::inWindow(22 * 60, 22 * 60 + 30, 7 * 60));
    TEST_ASSERT_TRUE (Night::inWindow(13 * 60, 12 * 60, 14 * 60));
    TEST_ASSERT_FALSE(Night::inWindow(13 * 60, 600, 600));
}

void test_night_brightness() {
    TEST_ASSERT_EQUAL(80, Night::brightness(Night::DIM,  false, false, 80, 15));
    TEST_ASSERT_EQUAL(15, Night::brightness(Night::DIM,  true,  false, 80, 15));
    TEST_ASSERT_EQUAL(80, Night::brightness(Night::NONE, true,  false, 80, 15));
    TEST_ASSERT_EQUAL(0,  Night::brightness(Night::DARK, true,  false, 80, 15));
    TEST_ASSERT_EQUAL(15, Night::brightness(Night::DARK, true,  true,  80, 15));
}

// ── UTF-8 (Vietnamese UI) ──────────────────────────────────────────────────

void test_utf8_never_splits_a_letter() {
    char b[6];
    Utf8::copy(b, sizeof(b), "ĐANG CHỜ");          // Đ=2 bytes: "ĐANG" fits, " CHỜ" not
    TEST_ASSERT_EQUAL_STRING("ĐANG", b);
    char c[4];
    Utf8::copy(c, sizeof(c), "aỜ");                  // Ờ is 3 bytes: only "a" fits
    TEST_ASSERT_EQUAL_STRING("a", c);
    const char* s = "lỗi";
    TEST_ASSERT_EQUAL(1, (int)Utf8::prevChar(s, 4)); // step back over ỗ to its lead byte
    Attention::Item it;                               // the queue truncates the same way
    Attention::copyStr(it.value, sizeof(it.value), "TOKEN CODEX BỊ TỪ ỒN");    // 26 B into 24
    TEST_ASSERT_EQUAL_STRING("TOKEN CODEX BỊ TỪ ", it.value);         // byte 23 is inside Ồ
}

void test_utf8_case_mapping_vietnamese() {
    char a[] = "đang chờ bạn · ưu tiên ỹ";
    Utf8::upper(a);
    TEST_ASSERT_EQUAL_STRING("ĐANG CHỜ BẠN · ƯU TIÊN Ỹ", a);
    char b[] = "ĐÃ XONG ĂN ƠN";
    Utf8::sentence(b);
    TEST_ASSERT_EQUAL_STRING("Đã xong ăn ơn", b);
}

void test_short_duration_units() {
    char d[8];
    TimeUtil::shortDuration(45 * 60, d, sizeof(d));      TEST_ASSERT_EQUAL_STRING("45P", d);
    TimeUtil::shortDuration(6 * 3600, d, sizeof(d));     TEST_ASSERT_EQUAL_STRING("6G", d);
    TimeUtil::shortDuration(3 * 86400, d, sizeof(d));    TEST_ASSERT_EQUAL_STRING("3NG", d);
    TimeUtil::shortDuration(999L * 86400, d, sizeof(d)); TEST_ASSERT_EQUAL_STRING("999NG", d);
}

// Design P-2026-11-25.4 token text.duration.countdown.
void test_countdown_units() {
    char b[12];
    TimeUtil::countdown(0, b, sizeof(b));                    TEST_ASSERT_EQUAL_STRING("ngay", b);
    TimeUtil::countdown(-5, b, sizeof(b));                   TEST_ASSERT_EQUAL_STRING("ngay", b);
    TimeUtil::countdown(14 * 60 + 30, b, sizeof(b));         TEST_ASSERT_EQUAL_STRING("14P", b);
    TimeUtil::countdown(2 * 3600 + 14 * 60, b, sizeof(b));   TEST_ASSERT_EQUAL_STRING("2G 14P", b);
    TimeUtil::countdown(18 * 3600 + 5 * 60, b, sizeof(b));   TEST_ASSERT_EQUAL_STRING("18G 5P", b);
    TimeUtil::countdown(4 * 86400, b, sizeof(b));            TEST_ASSERT_EQUAL_STRING("4NG", b);
    TimeUtil::countdown(23L * 3600 + 59 * 60, b, sizeof(b)); TEST_ASSERT_EQUAL_STRING("23G 59P", b);
}

void test_taskbar_buttons_and_badge() {
    using namespace XPCore;
    TEST_ASSERT_EQUAL(BTN_NO_BAR, buttonFor("Night"));
    TEST_ASSERT_EQUAL(BTN_NO_BAR, buttonFor(nullptr));
    TEST_ASSERT_EQUAL(BTN_CLAUDE, buttonFor("Attention"));   // agent cards are Claude windows
    TEST_ASSERT_EQUAL(BTN_NONE, buttonFor("Info"));
    TEST_ASSERT_EQUAL(BTN_NONE, buttonFor("Home"));          // the desktop: no button pressed
    TEST_ASSERT_EQUAL(BTN_WEATHER, buttonFor("Weather"));
    TEST_ASSERT_EQUAL(BTN_WEATHER, buttonFor("Forecast"));
    TEST_ASSERT_EQUAL(BTN_CLOCK, buttonFor("Clock"));
    const char* agent[] = {"Agents", "Claude", "Codex", "AI", "Trend", "Setup"};
    for (const char* n : agent) {
        TEST_ASSERT_EQUAL(BTN_CLAUDE, buttonFor(n));
        TEST_ASSERT_EQUAL(ICON_CLAWD, iconFor(n));
    }
    TEST_ASSERT_EQUAL(ICON_INFO, iconFor("Info"));
    TEST_ASSERT_EQUAL(ICON_WEATHER, iconFor("Forecast"));
    TEST_ASSERT_EQUAL(ICON_NONE, iconFor("Night"));
    TEST_ASSERT_EQUAL(-1, badgeGlyph(0));
    TEST_ASSERT_EQUAL(1, badgeGlyph(1));
    TEST_ASSERT_EQUAL(9, badgeGlyph(9));
    TEST_ASSERT_EQUAL(10, badgeGlyph(10));   // '+'
    // Orange Claude button: approval / question / error cards only.
    TEST_ASSERT_TRUE(flashes(Attention::K_APPROVAL));
    TEST_ASSERT_TRUE(flashes(Attention::K_INPUT));
    TEST_ASSERT_TRUE(flashes(Attention::K_ERROR));
    TEST_ASSERT_FALSE(flashes(Attention::K_PROGRESS));
    TEST_ASSERT_FALSE(flashes(Attention::K_SUCCESS));
}

// P-2026-11-26.14: one button per open window (the last 4), the top one
// pressed while it shows; badge / orange on the Claude window's button.
void test_taskbar_state_looks() {
    using namespace XPCore;
    BarState s;
    const int8_t open[] = {PROG_CLAUDE, PROG_WEATHER};
    fillBar(s, open, 2, PROG_WEATHER, PROG_WEATHER);
    s.badge = 1;
    TEST_ASSERT_EQUAL(PROG_CLAUDE, s.prog[0]);
    TEST_ASSERT_EQUAL(PROG_WEATHER, s.prog[1]);
    TEST_ASSERT_EQUAL(PROG_NONE, s.prog[2]);
    TEST_ASSERT_EQUAL(1, s.pressed);
    TEST_ASSERT_EQUAL(LOOK_NORMAL, lookOfSlot(0, s));
    TEST_ASSERT_EQUAL(LOOK_PRESSED, lookOfSlot(1, s));
    TEST_ASSERT_EQUAL(1, badgeOnSlot(0, s));      // on Claude, pressed or not
    TEST_ASSERT_EQUAL(-1, badgeOnSlot(1, s));
    // The desktop shows: nothing pressed; the top window stays a raised button.
    BarState d;
    fillBar(d, open, 2, PROG_WEATHER, PROG_NONE);
    TEST_ASSERT_EQUAL(-1, d.pressed);
    TEST_ASSERT_TRUE(slotChanged(1, s, d));
    TEST_ASSERT_FALSE(slotChanged(2, s, d));
    // A card that needs you: the Claude button orange, no badge (XP-Attention).
    BarState f = s; f.flash = true;
    TEST_ASSERT_EQUAL(LOOK_FLASH, lookOfSlot(0, f));
    TEST_ASSERT_EQUAL(-1, badgeOnSlot(0, f));
    TEST_ASSERT_TRUE(slotChanged(0, s, f));
    TEST_ASSERT_FALSE(slotChanged(1, s, f));
    // More than 4 open: the last 4 in opening order.
    const int8_t many[] = {PROG_CLAUDE, PROG_CODEX, PROG_WEATHER, PROG_CLOCK, PROG_INFO};
    BarState m;
    fillBar(m, many, 5, PROG_INFO, PROG_INFO);
    TEST_ASSERT_EQUAL(PROG_CODEX, m.prog[0]);
    TEST_ASSERT_EQUAL(PROG_INFO, m.prog[3]);
    TEST_ASSERT_EQUAL(3, m.pressed);
    // Nothing open: only start + tray.
    BarState e;
    fillBar(e, many, 0, PROG_NONE, PROG_NONE);
    for (int i = 0; i < kSlots; i++) TEST_ASSERT_EQUAL(PROG_NONE, e.prog[i]);
    TEST_ASSERT_EQUAL(ICON_CLAWD, progIcon(PROG_CODEX));
    TEST_ASSERT_EQUAL(ICON_WEATHER, progIcon(PROG_FORECAST));
    TEST_ASSERT_EQUAL(ICON_INFO, progIcon(PROG_INFO));
    TEST_ASSERT_EQUAL(PROG_CLAUDE, progOf("claude"));             // case-insensitive like /api/channel
    TEST_ASSERT_EQUAL(PROG_NONE, progOf("Home"));
    TEST_ASSERT_EQUAL(PROG_NONE, progOf("Attention"));
    TEST_ASSERT_EQUAL_STRING("Forecast", progName(PROG_FORECAST));
    // Start button rounding: 5,3,2,1,1, 0×16, 1,1,2,3,5.
    TEST_ASSERT_EQUAL(5, startInset(0));
    TEST_ASSERT_EQUAL(0, startInset(5));
    TEST_ASSERT_EQUAL(0, startInset(20));
    TEST_ASSERT_EQUAL(1, startInset(21));
    TEST_ASSERT_EQUAL(5, startInset(25));
}

// P-2026-11-26.15: weather skill on → tray from x 176 with the weather icon,
// only 3 window buttons (P-2026-11-26.21: no balloon any more).
void test_tray_weather_and_balloon() {
    using namespace XPCore;
    TEST_ASSERT_EQUAL(196, trayX(false));
    TEST_ASSERT_EQUAL(176, trayX(true));
    TEST_ASSERT_EQUAL(4, slotsFor(false));
    TEST_ASSERT_EQUAL(3, slotsFor(true));
    // 4 open with the weather tray: the last 3, slot 3 empty (it would overlap the tray).
    const int8_t four[] = {PROG_CLAUDE, PROG_CODEX, PROG_WEATHER, PROG_CLOCK};
    BarState s;
    fillBar(s, four, 4, PROG_CLOCK, PROG_CLOCK, slotsFor(true));
    TEST_ASSERT_EQUAL(PROG_CODEX, s.prog[0]);
    TEST_ASSERT_EQUAL(PROG_CLOCK, s.prog[2]);
    TEST_ASSERT_EQUAL(PROG_NONE, s.prog[3]);
    TEST_ASSERT_EQUAL(2, s.pressed);
    TEST_ASSERT_TRUE(buttonX(2) + kBtnW <= kTrayXWeather);
}

// P-2026-11-26.16 (XP-Open): the title bar zooms between the taskbar button and
// (0, 0, 240×22) in 4 steps (rects of XP-Open-2.dc.html for slot 0); every
// window but the desktop / night / cards comes up through its empty frame.
void test_window_open_zoom_and_frame() {
    using namespace XPCore;
    const int16_t want[4][4] = {{57, 174, 70, 20}, {43, 130, 113, 21}, {28, 87, 155, 21}, {14, 43, 198, 22}};
    for (int i = 1; i <= 4; i++) {
        Rect r = zoomRect(0, i);
        TEST_ASSERT_EQUAL(want[i - 1][0], r.x);
        TEST_ASSERT_EQUAL(want[i - 1][1], r.y);
        TEST_ASSERT_EQUAL(want[i - 1][2], r.w);
        TEST_ASSERT_EQUAL(want[i - 1][3], r.h);
    }
    TEST_ASSERT_TRUE(zoomRect(2, 1).x > zoomRect(0, 1).x);      // later slots start further right
    TEST_ASSERT_TRUE(framesFirst("Claude"));
    TEST_ASSERT_TRUE(framesFirst("Clock"));
    TEST_ASSERT_TRUE(framesFirst("Info"));
    TEST_ASSERT_FALSE(framesFirst("Home"));
    TEST_ASSERT_FALSE(framesFirst("Attention"));
    TEST_ASSERT_FALSE(framesFirst("Night"));
    TEST_ASSERT_FALSE(framesFirst(nullptr));
    WinFrame f = frameOf("Weather");
    TEST_ASSERT_EQUAL_STRING("Thời tiết", f.title);
    TEST_ASSERT_EQUAL(ICON_WEATHER, f.icon);
    TEST_ASSERT_FALSE(f.status);      // P-2026-11-26.17: the property sheet has no status bar
    TEST_ASSERT_FALSE(frameOf("Claude").status);
    TEST_ASSERT_EQUAL_STRING("AI hôm nay", frameOf("AI").title);
    // Slot of a program among the last [slots] open windows.
    const int8_t open[] = {PROG_CLAUDE, PROG_CODEX, PROG_WEATHER, PROG_CLOCK};
    TEST_ASSERT_EQUAL(3, slotOf(open, 4, PROG_CLOCK, 4));
    TEST_ASSERT_EQUAL(-1, slotOf(open, 4, PROG_CLAUDE, 3));    // scrolled off with the weather tray
    TEST_ASSERT_EQUAL(0, slotOf(open, 4, PROG_CODEX, 3));
    // File Download paper and the hourglass: one step per 200 ms.
    TEST_ASSERT_EQUAL(60, paperX(0));
    TEST_ASSERT_EQUAL(160, paperX(5));
    TEST_ASSERT_EQUAL(40, paperY(2));
    TEST_ASSERT_EQUAL(48, paperY(5));
    TEST_ASSERT_EQUAL(3, hourglassFrame(7));
    TEST_ASSERT_EQUAL(0, hourglassFrame(8));
}

// L-4: the TLS gate = largest block ≥ 12 000 and free heap ≥ 20 000. The
// numbers measured on the device after an OTA soft restart (largest block
// 15 456–19 304, free ~23.5 K) pass; real shortage does not.
void test_tls_heap_gate() {
    using namespace FetchPolicy;
    TEST_ASSERT_TRUE(tlsHeapOk(23528, 15456));    // soft restart: fetches succeeded on the device
    TEST_ASSERT_TRUE(tlsHeapOk(21104, 20624));    // after a power cycle
    TEST_ASSERT_FALSE(tlsHeapOk(23528, 11999));   // no block for BearSSL's largest allocation
    TEST_ASSERT_FALSE(tlsHeapOk(19999, 19000));   // not enough heap for the ~25 K handshake
    TEST_ASSERT_TRUE(tlsHeapOk(kTlsMinFree, kTlsMinBlock));
}

// P-2026-11-26.17 XP-Real: Date and Time calendar (weeks from Monday) and the
// screen saver's jump.
void test_calendar_and_saver() {
    using namespace XPCore;
    // November 2026: day 1 is a Sunday → 6 days of October first (26..31).
    TEST_ASSERT_EQUAL(6, leadingDays(0));
    CalCell c = calCell(0, 2026, 11, 0);
    TEST_ASSERT_EQUAL(26, c.day); TEST_ASSERT_FALSE(c.inMonth);
    c = calCell(6, 2026, 11, 0);
    TEST_ASSERT_EQUAL(1, c.day); TEST_ASSERT_TRUE(c.inMonth);
    c = calCell(35, 2026, 11, 0);
    TEST_ASSERT_EQUAL(30, c.day); TEST_ASSERT_TRUE(c.inMonth);
    c = calCell(36, 2026, 11, 0);
    TEST_ASSERT_EQUAL(1, c.day); TEST_ASSERT_FALSE(c.inMonth);
    TEST_ASSERT_EQUAL(29, daysIn(2028, 2));
    TEST_ASSERT_EQUAL(28, daysIn(2026, 2));
    TEST_ASSERT_EQUAL(0, leadingDays(1));                       // a Monday starts the grid
    // January: the leading days come from December of the year before.
    c = calCell(0, 2027, 1, 5);                                 // 1/1/2027 is a Friday
    TEST_ASSERT_EQUAL(28, c.day);
    for (uint32_t r = 0; r < 200; r += 7) {
        int x, y;
        saverSpot(14, 22, r * 2654435761u, r * 40503u + 11, x, y);
        TEST_ASSERT_TRUE(x >= 6 && x <= 64 && y >= 6 && y <= 134);
        TEST_ASSERT_TRUE((x - 14) * (x - 14) + (y - 22) * (y - 22) >= 900);
    }
}

void test_xp_progress_blocks_and_marquee() {
    using namespace XPCore;
    // XP-Claude-A weekly bar 220×14 at (10,102), padY 2: blocks 22×8 from (13,105), gap 2.
    Blocks b = blocks(10, 102, 220, 14, 2);
    TEST_ASSERT_EQUAL(13, b.x0); TEST_ASSERT_EQUAL(105, b.y0);
    TEST_ASSERT_EQUAL(22, b.w);  TEST_ASSERT_EQUAL(8, b.h);
    TEST_ASSERT_EQUAL(2, b.gap); TEST_ASSERT_EQUAL(22, b.lastW);
    // Session bar 208×7 at (16,151): 21×3 from (18,153), gap 1, last 28.
    b = blocks(16, 151, 208, 7);
    TEST_ASSERT_EQUAL(18, b.x0); TEST_ASSERT_EQUAL(153, b.y0);
    TEST_ASSERT_EQUAL(21, b.w);  TEST_ASSERT_EQUAL(3, b.h);
    TEST_ASSERT_EQUAL(1, b.gap); TEST_ASSERT_EQUAL(28, b.lastW);
    // XP-Home 120×14 at (70,134), default padY 1: 10×10 from (73,136), last 18.
    b = blocks(70, 134, 120, 14);
    TEST_ASSERT_EQUAL(73, b.x0); TEST_ASSERT_EQUAL(136, b.y0);
    TEST_ASSERT_EQUAL(10, b.w);  TEST_ASSERT_EQUAL(10, b.h); TEST_ASSERT_EQUAL(18, b.lastW);
    // XP-AI 90×12 at (18,164): gap 2, 7×8 from (21,166), last 12.
    b = blocks(18, 164, 90, 12);
    TEST_ASSERT_EQUAL(2, b.gap);
    TEST_ASSERT_EQUAL(21, b.x0); TEST_ASSERT_EQUAL(166, b.y0);
    TEST_ASSERT_EQUAL(7, b.w);   TEST_ASSERT_EQUAL(8, b.h); TEST_ASSERT_EQUAL(12, b.lastW);
    // XP-Codex 220×14 at (10,102): 22×10 from (13,104).
    b = blocks(10, 102, 220, 14);
    TEST_ASSERT_EQUAL(104, b.y0); TEST_ASSERT_EQUAL(10, b.h); TEST_ASSERT_EQUAL(22, b.w);
    // XP-Attention-Progress 180×14 at (30,166): 17×10 from (33,168), last 22.
    b = blocks(30, 166, 180, 14);
    TEST_ASSERT_EQUAL(33, b.x0); TEST_ASSERT_EQUAL(168, b.y0);
    TEST_ASSERT_EQUAL(17, b.w);  TEST_ASSERT_EQUAL(10, b.h); TEST_ASSERT_EQUAL(22, b.lastW);
    // Loading box 140×14 at (50,116), padY 2: cells 13×8 on a 15 pitch from (53,119).
    b = blocks(50, 116, 140, 14, 2);
    TEST_ASSERT_EQUAL(53, b.x0); TEST_ASSERT_EQUAL(119, b.y0);
    TEST_ASSERT_EQUAL(13, b.w);  TEST_ASSERT_EQUAL(8, b.h); TEST_ASSERT_EQUAL(2, b.gap);
    // Same lighting rule as pixelBar: block i when pct > i·11.11.
    TEST_ASSERT_TRUE(blockLit(1, 0));
    TEST_ASSERT_FALSE(blockLit(0, 0));
    TEST_ASSERT_TRUE(blockLit(89, 8));
    TEST_ASSERT_FALSE(blockLit(38, 4));
    // Marquee: 3 lit cells, head enters left, leaves right, period 11 steps.
    TEST_ASSERT_TRUE(marqueeLit(0, 0));
    TEST_ASSERT_FALSE(marqueeLit(0, 1));
    TEST_ASSERT_TRUE(marqueeLit(5, 3));
    TEST_ASSERT_TRUE(marqueeLit(5, 5));
    TEST_ASSERT_FALSE(marqueeLit(5, 6));
    TEST_ASSERT_TRUE(marqueeLit(10, 8));
    TEST_ASSERT_FALSE(marqueeLit(10, 7));
    TEST_ASSERT_TRUE(marqueeLit(11, 0));     // wraps
    // Status bar divider 8 px left of the right text (XP-Home: 98 px → x 125).
    TEST_ASSERT_EQUAL(125, statusDividerX(98));
    TEST_ASSERT_EQUAL(146, statusDividerX(77));
    // Right text room: XP-AI "CL 2G 14P · CX 3NG" (126 px) beside "Dùng Claude" (77).
    TEST_ASSERT_TRUE(statusRightMax(77) >= 126);
    TEST_ASSERT_EQUAL(215, statusRightMax(0));
    TEST_ASSERT_EQUAL(120, statusRightMax(160));       // never below 120 while the left can give
    // Boot box: 3 of 6 lanes, enters left, leaves right, period 8 (XP-Splash = step 3).
    TEST_ASSERT_TRUE(bootLit(3, 1)); TEST_ASSERT_TRUE(bootLit(3, 3));
    TEST_ASSERT_FALSE(bootLit(3, 0)); TEST_ASSERT_FALSE(bootLit(3, 4));
    TEST_ASSERT_TRUE(bootLit(0, 0)); TEST_ASSERT_FALSE(bootLit(0, 1));
    TEST_ASSERT_TRUE(bootLit(7, 5)); TEST_ASSERT_FALSE(bootLit(7, 4));
    TEST_ASSERT_TRUE(bootLit(8, 0));                    // wraps
}

void test_clock_ampm_vietnamese() {
    TEST_ASSERT_EQUAL_STRING("SA", ClockFmt::ampm(0));
    TEST_ASSERT_EQUAL_STRING("SA", ClockFmt::ampm(11));
    TEST_ASSERT_EQUAL_STRING("CH", ClockFmt::ampm(12));
    TEST_ASSERT_EQUAL_STRING("CH", ClockFmt::ampm(23));
}

// ── Project board ─────────────────────────────────────────────────────────

static Attention::HookEvent hev(const char* ev, const char* cwd, const char* ty = "", const char* tool = "") {
    Attention::HookEvent e; e.event = ev; e.cwd = cwd; e.type = ty; e.tool = tool; return e;
}

void test_projects_follow_hook_events() {
    Projects::Board b; Projects::clearAll(b);
    const uint32_t t = 1000000;
    TEST_ASSERT_TRUE(Projects::noteHook(b, Attention::AGENT_CLAUDE, hev("UserPromptSubmit", "/src/glimmer"), t));
    TEST_ASSERT_TRUE(Projects::noteHook(b, Attention::AGENT_CLAUDE,
                     hev("Notification", "/src/glimmer", "permission_prompt", "Bash"), t + 5));
    int ord[Projects::kMax];
    TEST_ASSERT_EQUAL(1, Projects::ordered(b, ord, t + 6));
    const Projects::Entry& x = b.e[ord[0]];
    TEST_ASSERT_EQUAL_STRING("glimmer", x.project);
    TEST_ASSERT_EQUAL(Projects::P_APPROVAL, x.state);
    TEST_ASSERT_EQUAL_STRING("Bash", x.detail);
    // Approved → working → done; DONE stays for hours, unlike the 20 s card.
    Projects::noteHook(b, Attention::AGENT_CLAUDE, hev("PostToolUse", "/src/glimmer", "", "Bash"), t + 9);
    TEST_ASSERT_EQUAL(Projects::P_WORKING, b.e[ord[0]].state);
    Projects::noteHook(b, Attention::AGENT_CLAUDE, hev("Stop", "/src/glimmer"), t + 60);
    TEST_ASSERT_EQUAL(Projects::P_DONE, b.e[ord[0]].state);
    TEST_ASSERT_EQUAL(1, Projects::ordered(b, ord, t + 60 + 3600));
    TEST_ASSERT_EQUAL(0, Projects::ordered(b, ord, t + 60 + Projects::kKeepS));
}

void test_projects_order_idle_and_eviction() {
    Projects::Board b; Projects::clearAll(b);
    const uint32_t t = 2000000;
    Projects::noteHook(b, Attention::AGENT_CLAUDE, hev("Stop", "/a/done"), t);
    Projects::noteHook(b, Attention::AGENT_CODEX,  hev("PostToolUse", "/a/busy"), t + 1);
    Projects::noteHook(b, Attention::AGENT_CLAUDE, hev("Notification", "/a/ask", "idle_prompt"), t + 2);
    int ord[Projects::kMax];
    TEST_ASSERT_EQUAL(3, Projects::ordered(b, ord, t + 3));
    TEST_ASSERT_EQUAL_STRING("ask",  b.e[ord[0]].project);     // waiting on you first
    TEST_ASSERT_EQUAL_STRING("busy", b.e[ord[1]].project);
    TEST_ASSERT_EQUAL_STRING("done", b.e[ord[2]].project);
    // A working project with no event for 30 min is hidden (agent gone quiet).
    TEST_ASSERT_EQUAL(2, Projects::ordered(b, ord, t + 1 + Projects::kIdleS));
    // Full board (kMax sessions): the stalest entry makes room.
    static const char* more[] = {"/a/p4", "/a/p5", "/a/p6", "/a/p7", "/a/p8", "/a/p9"};
    for (int i = 0; i < 6; i++) Projects::noteHook(b, Attention::AGENT_CLAUDE, hev("Stop", more[i]), t + 10 + i);
    bool hasDone = false, hasLast = false;
    for (auto& x : b.e) { if (!strcmp(x.project, "done")) hasDone = true; if (!strcmp(x.project, "p9")) hasLast = true; }
    TEST_ASSERT_FALSE(hasDone);
    TEST_ASSERT_TRUE(hasLast);
}

// Two sessions in one repo are one row; the most urgent session wins, so one
// finishing doesn't hide the other still running.
void test_projects_sessions_merge_per_project() {
    Projects::Board b; Projects::clearAll(b);
    const uint32_t t = 2500000;
    Attention::HookEvent app = hev("PostToolUse", "C:/src/glimmer", "", "Bash");
    app.session = "sess-app";
    Attention::HookEvent design = hev("PostToolUse", "C:/src/glimmer", "", "Edit");
    design.session = "sess-design";
    Attention::HookEvent zidex = hev("PostToolUse", "C:/src/zidex", "", "Read");
    zidex.session = "sess-zidex";
    Projects::noteHook(b, Attention::AGENT_CLAUDE, app, t);
    Projects::noteHook(b, Attention::AGENT_CLAUDE, design, t + 1);
    Projects::noteHook(b, Attention::AGENT_CLAUDE, zidex, t + 2);
    int ord[Projects::kMax], cnt[Projects::kMax];
    TEST_ASSERT_EQUAL(2, Projects::ordered(b, ord, t + 3, cnt));       // glimmer + zidex
    int g = !strcmp(b.e[ord[0]].project, "glimmer") ? 0 : 1;
    TEST_ASSERT_EQUAL_STRING("glimmer", b.e[ord[g]].project);
    TEST_ASSERT_EQUAL(2, cnt[g]);                                      // two sessions behind it
    // The design session stops: glimmer still shows running (app is working).
    design.event = "Stop";
    Projects::noteHook(b, Attention::AGENT_CLAUDE, design, t + 4);
    Projects::ordered(b, ord, t + 5, cnt);
    g = !strcmp(b.e[ord[0]].project, "glimmer") ? 0 : 1;
    TEST_ASSERT_EQUAL(Projects::P_WORKING, b.e[ord[g]].state);
    // The app session asks for approval: glimmer becomes the top row.
    app.event = "Notification"; app.type = "permission_prompt";
    Projects::noteHook(b, Attention::AGENT_CLAUDE, app, t + 6);
    Projects::ordered(b, ord, t + 7, cnt);
    TEST_ASSERT_EQUAL_STRING("glimmer", b.e[ord[0]].project);
    TEST_ASSERT_EQUAL(Projects::P_APPROVAL, b.e[ord[0]].state);
}

// (L-5) A session left waiting on another computer (it left the network, so
// its next event never came) must not pin the project to "Cần duyệt": a newer
// session of the same project and agent, active ≥ kSupersedeS after it, wins;
// and any wait with no event for kWaitS is dropped.
void test_projects_stale_wait_released() {
    Projects::Board b; Projects::clearAll(b);
    const uint32_t t = 3000000;
    Attention::HookEvent oldPc = hev("Notification", "C:/src/glimmer", "permission_prompt", "Bash");
    oldPc.session = "sess-pc-a";
    Attention::HookEvent newPc = hev("PostToolUse", "D:/work/glimmer", "", "Edit");
    newPc.session = "sess-pc-b";
    Projects::noteHook(b, Attention::AGENT_CLAUDE, oldPc, t);
    int ord[Projects::kMax];
    // A parallel session busy a few minutes later: the approval still shows.
    Projects::noteHook(b, Attention::AGENT_CLAUDE, newPc, t + 60);
    TEST_ASSERT_EQUAL(1, Projects::ordered(b, ord, t + 61));
    TEST_ASSERT_EQUAL(Projects::P_APPROVAL, b.e[ord[0]].state);
    // The other session is still active ≥ 10 min after the wait's last event:
    // the stale approval steps aside, the row follows the live session.
    Projects::noteHook(b, Attention::AGENT_CLAUDE, newPc, t + Projects::kSupersedeS);
    TEST_ASSERT_EQUAL(1, Projects::ordered(b, ord, t + Projects::kSupersedeS + 1));
    TEST_ASSERT_EQUAL(Projects::P_WORKING, b.e[ord[0]].state);
    // Another agent in the same repo doesn't release Claude's wait.
    Projects::Board c; Projects::clearAll(c);
    Projects::noteHook(c, Attention::AGENT_CLAUDE, oldPc, t);
    Attention::HookEvent codex = hev("PostToolUse", "D:/work/glimmer", "", "Bash");
    codex.session = "codex-1";
    Projects::noteHook(c, Attention::AGENT_CODEX, codex, t + Projects::kSupersedeS + 5);
    Projects::ordered(c, ord, t + Projects::kSupersedeS + 6);
    TEST_ASSERT_EQUAL(Projects::P_APPROVAL, c.e[ord[0]].state);
    // Alone, a wait with no event for kWaitS is dropped (survives a reboot otherwise).
    Projects::Board d; Projects::clearAll(d);
    Projects::noteHook(d, Attention::AGENT_CLAUDE, oldPc, t);
    TEST_ASSERT_EQUAL(1, Projects::ordered(d, ord, t + Projects::kWaitS - 1));
    TEST_ASSERT_EQUAL(0, Projects::ordered(d, ord, t + Projects::kWaitS));
}

void test_projects_from_pushed_cards() {
    Projects::Board b; Projects::clearAll(b);
    Attention::Item it;
    Attention::copyStr(it.project, sizeof(it.project), "api");
    it.kind = Attention::K_PROGRESS; it.progress = 62;
    TEST_ASSERT_TRUE(Projects::noteItem(b, it, 3000000));
    int ord[Projects::kMax];
    TEST_ASSERT_EQUAL(1, Projects::ordered(b, ord, 3000001));
    TEST_ASSERT_EQUAL_STRING("62%", b.e[ord[0]].detail);
    Attention::Item sys; Attention::copyStr(sys.id, sizeof(sys.id), "sys:0:1");
    Attention::copyStr(sys.project, sizeof(sys.project), "x"); sys.kind = Attention::K_ERROR;
    TEST_ASSERT_FALSE(Projects::noteItem(b, sys, 3000002));     // device notices stay off the board
}

// R-SK-1 / R-SK-2 (design 2026-11-25.3): several skills on, at least one; channels of enabled
// skills + system channels rotate; the dock shows one tab per enabled skill.
void test_skill_filter_and_default() {
    TEST_ASSERT_TRUE(Skill::known("agent"));
    TEST_ASSERT_TRUE(Skill::known("weather"));
    TEST_ASSERT_TRUE(Skill::known("clock"));
    TEST_ASSERT_FALSE(Skill::known("music"));
    TEST_ASSERT_FALSE(Skill::known(nullptr));
    char on[48];
    Skill::normalise("clock,music,agent,clock", on, sizeof(on), true);
    TEST_ASSERT_EQUAL_STRING("agent,clock", on);                 // kAll order, unknown + dupes dropped
    Skill::normalise("", on, sizeof(on), true);
    TEST_ASSERT_EQUAL_STRING(Skill::kDefaultOn, on);             // old config → everything on
    Skill::normalise("music", on, sizeof(on), false);
    TEST_ASSERT_EQUAL_STRING("", on);                            // caller rejects: at least one
    TEST_ASSERT_TRUE(Skill::inList("agent,weather", "weather"));
    TEST_ASSERT_FALSE(Skill::inList("agent,weather", "weath"));
    TEST_ASSERT_EQUAL_STRING("weather", Skill::first("weather,clock"));
    TEST_ASSERT_TRUE(Skill::shows(nullptr, "clock"));            // system channel (Info, Attention…)
    TEST_ASSERT_TRUE(Skill::shows("agent", "agent,clock"));
    TEST_ASSERT_FALSE(Skill::shows("weather", "agent,clock"));   // Weather/Forecast off
}

void test_taskbar_buttons_follow_enabled_skills() {
    using namespace XPCore;
    TEST_ASSERT_EQUAL(101, buttonX(1));   // x 71 + 30k
    // Ảnh (P-2026-11-25.7): tab 2, off by default.
    TEST_ASSERT_TRUE(Skill::known("photo"));
    TEST_ASSERT_FALSE(Skill::inList(Skill::kDefaultOn, "photo"));
    TEST_ASSERT_EQUAL(BTN_PHOTO, buttonFor("Photo"));
    TEST_ASSERT_EQUAL(161, buttonX(3));   // the 4th window at x 161
    char on[48];
    Skill::normalise("clock,photo,agent", on, sizeof(on), true);
    TEST_ASSERT_EQUAL_STRING("agent,photo,clock", on);
}


// P-2026-11-26.14: open windows sent by the app; a channel opened without it is adopted.
void test_windows_adopt_and_prune() {
    using namespace XPCore;
    Control::Windows w;
    Control::adopt(w, PROG_CLAUDE);
    Control::adopt(w, PROG_WEATHER);
    TEST_ASSERT_EQUAL(2, w.n);
    TEST_ASSERT_EQUAL(PROG_WEATHER, w.top);
    Control::adopt(w, PROG_CLAUDE);                  // already open: no reorder (XP taskbar)
    TEST_ASSERT_EQUAL(PROG_CLAUDE, w.open[0]);
    TEST_ASSERT_EQUAL(PROG_CLAUDE, w.top);
    w.minMask = 1u << PROG_WEATHER;
    Control::adopt(w, PROG_WEATHER);                 // restored
    TEST_ASSERT_EQUAL(0, w.minMask);
    Control::adopt(w, PROG_NONE);                    // the desktop is not a window
    TEST_ASSERT_EQUAL(2, w.n);
    Control::prune(w, [](int p) { return p != PROG_WEATHER; });
    TEST_ASSERT_EQUAL(1, w.n);
    TEST_ASSERT_EQUAL(PROG_NONE, w.top);
    Control::addOpen(w, PROG_CLAUDE);                // no duplicates
    Control::addOpen(w, PROG_NONE);
    TEST_ASSERT_EQUAL(1, w.n);
}

// P-2026-11-26.17 XP-Desk-OneCol: only installed programs, one column x 40
// (no Weather / Clock icons — they open from the tray).
void test_desk_icons_follow_skills() {
    using namespace XPCore;
    DeskIcon ic[kDeskMax];
    int n = deskIcons("agent,photo,weather,clock", ic);
    TEST_ASSERT_EQUAL(4, n);
    TEST_ASSERT_EQUAL(PROG_CLAUDE, ic[0].prog); TEST_ASSERT_EQUAL(40, ic[0].cx); TEST_ASSERT_EQUAL(8, ic[0].y);
    TEST_ASSERT_EQUAL(PROG_PHOTO, ic[2].prog);  TEST_ASSERT_EQUAL(104, ic[2].y);
    TEST_ASSERT_EQUAL(kDeskTrash, ic[3].prog);  TEST_ASSERT_EQUAL(152, ic[3].y);
    for (int i = 0; i < n; i++) TEST_ASSERT_EQUAL(40, ic[i].cx);
    // Forecast is the Weather window's tab: one program.
    TEST_ASSERT_EQUAL(PROG_WEATHER, progOf("Forecast"));
    TEST_ASSERT_EQUAL_STRING("Thời tiết", frameOf("Forecast").title);
    n = deskIcons("agent", ic);                      // XPDeskAgent: trash at y 104
    TEST_ASSERT_EQUAL(3, n);
    TEST_ASSERT_EQUAL(kDeskTrash, ic[2].prog);
    TEST_ASSERT_EQUAL(104, ic[2].y);
}

// P-2026-11-26.14 XP-Menu: sizes from the sources, kept inside y ≤ 213.
void test_menu_geometry() {
    using namespace XPCore;
    TEST_ASSERT_EQUAL(166, menuW(MENU_DESKTOP));
    TEST_ASSERT_EQUAL(127, menuH(MENU_DESKTOP));
    TEST_ASSERT_EQUAL(128, menuW(MENU_WINDOW));
    TEST_ASSERT_EQUAL(113, menuH(MENU_WINDOW));
    int x = 200, y = 180;
    menuClamp(MENU_DESKTOP, x, y);
    TEST_ASSERT_EQUAL(74, x);
    TEST_ASSERT_EQUAL(87, y);
    // Start menu (P-2026-11-26.20): covers (0, 0)–(239, 213), never moved.
    TEST_ASSERT_EQUAL(240, menuW(MENU_START));
    TEST_ASSERT_EQUAL(214, menuH(MENU_START));
    x = 50; y = 40;
    menuClamp(MENU_START, x, y);
    TEST_ASSERT_EQUAL(0, x);
    TEST_ASSERT_EQUAL(0, y);
    x = 71; y = 100;                                 // window menu from the Claude button
    menuClamp(MENU_WINDOW, x, y);
    TEST_ASSERT_EQUAL(71, x);
    TEST_ASSERT_EQUAL(100, y);
}


// P-2026-11-26.22: Ngày và Giờ touched from the app.
void test_clock_props_core() {
    using namespace ClockCore;
    char b[12];
    monthShort(11, b); TEST_ASSERT_EQUAL_STRING("Thg 11", b);
    monthShort(3, b);  TEST_ASSERT_EQUAL_STRING("Thg 3", b);
    gmtParen(420, b);  TEST_ASSERT_EQUAL_STRING("(GMT+07:00)", b);
    gmtParen(-180, b); TEST_ASSERT_EQUAL_STRING("(GMT-03:00)", b);
    gmtParen(330, b);  TEST_ASSERT_EQUAL_STRING("(GMT+05:30)", b);
    TEST_ASSERT_EQUAL(8, zoneIndex(420));          // Hà Nội
    TEST_ASSERT_EQUAL(-1, zoneIndex(345));         // not listed
    TEST_ASSERT_EQUAL(21, mapColumn(420));         // round((105 + 180) / 13.33)
    TEST_ASSERT_EQUAL(14, mapColumn(0));
    TEST_ASSERT_EQUAL(5, mapColumn(-480));         // 4.5 rounds up
    TEST_ASSERT_TRUE(isLand(1, 20));               // Asia
    TEST_ASSERT_FALSE(isLand(1, 0));               // sea
    TEST_ASSERT_TRUE(isLand(5, 21));               // the 4th span of row 5
    TEST_ASSERT_EQUAL(3, maxTop(LIST_MONTH));
    TEST_ASSERT_EQUAL(3, clampTop(LIST_MONTH, 9));
    TEST_ASSERT_EQUAL(0, clampTop(LIST_NONE, 2));
    int ty, th;
    thumb(LIST_MONTH, 0, 89, 97, ty, th);
    TEST_ASSERT_EQUAL(72, th);
    TEST_ASSERT_EQUAL(89, ty);
    thumb(LIST_MONTH, 3, 89, 97, ty, th);
    TEST_ASSERT_EQUAL(89 + 97 - 72, ty);
    TEST_ASSERT_EQUAL(0, wdayOf(2026, 11, 1));     // 1/11/2026 is a Sunday
    TEST_ASSERT_EQUAL(4, wdayOf(2026, 11, 26));    // Thursday
    TEST_ASSERT_EQUAL(4, wdayOf(2024, 2, 29));
}

// ── Photos (P-2026-11-25.7) ─────────────────────────────────────────────────

// SOI, APP0 (JFIF), DQT, SOFn (w×h, 3 comps), then a few scan bytes.
static size_t makeJpeg(uint8_t* b, uint8_t sof, uint16_t w, uint16_t h) {
    size_t n = 0;
    auto put = [&](std::initializer_list<int> v) { for (int x : v) b[n++] = (uint8_t)x; };
    put({0xFF, 0xD8});
    put({0xFF, 0xE0, 0x00, 0x10, 'J', 'F', 'I', 'F', 0, 1, 1, 0, 0, 1, 0, 1, 0, 0});
    put({0xFF, 0xDB, 0x00, 0x43, 0x00});
    for (int i = 0; i < 64; i++) b[n++] = 1;
    put({0xFF, 0xFF, sof, 0x00, 0x11, 0x08, h >> 8, h & 0xFF, w >> 8, w & 0xFF, 3,
         1, 0x22, 0, 2, 0x11, 1, 3, 0x11, 1});
    put({0xFF, 0xDA, 0x00, 0x0C});
    return n;
}

void test_photo_jpeg_header_check() {
    uint8_t b[200];
    using namespace Photos;
    // Baseline 188×188, fed one byte at a time (upload chunk boundaries anywhere).
    size_t n = makeJpeg(b, 0xC0, 188, 188);
    JpegSniffer a;
    for (size_t i = 0; i < n; i++) a.feed(b + i, 1);
    TEST_ASSERT_EQUAL(JPEG_OK, a.verdict());
    TEST_ASSERT_EQUAL(188, a.width());
    // Whole buffer at once, same answer; later bytes don't change it.
    JpegSniffer w; TEST_ASSERT_EQUAL(JPEG_OK, w.feed(b, n));
    TEST_ASSERT_EQUAL(JPEG_OK, w.feed((const uint8_t*)"junk", 4));
    // Progressive, wrong size (w ≠ h too), not a JPEG, cut before the SOF.
    n = makeJpeg(b, 0xC2, 188, 188);
    JpegSniffer p; TEST_ASSERT_EQUAL(JPEG_PROGRESSIVE, p.feed(b, n));
    n = makeJpeg(b, 0xC0, 240, 188);
    JpegSniffer z; TEST_ASSERT_EQUAL(JPEG_BAD_SIZE, z.feed(b, n));
    TEST_ASSERT_EQUAL(240, z.width()); TEST_ASSERT_EQUAL(188, z.height());
    const uint8_t png[] = {0x89, 'P', 'N', 'G'};
    JpegSniffer q; TEST_ASSERT_EQUAL(JPEG_NOT_JPEG, q.feed(png, sizeof(png)));
    n = makeJpeg(b, 0xC0, 188, 188);
    JpegSniffer t; TEST_ASSERT_EQUAL(JPEG_PENDING, t.feed(b, 30));
    TEST_ASSERT_EQUAL(JPEG_TRUNCATED, t.finish());
    TEST_ASSERT_EQUAL_STRING("progressive", verdictCode(JPEG_PROGRESSIVE));
}

void test_photo_names_order_and_rotation() {
    using namespace Photos;
    TEST_ASSERT_EQUAL_UINT32(3, idOf("p3.jpg"));
    TEST_ASSERT_EQUAL_UINT32(120, idOf("p120.jpg"));
    TEST_ASSERT_EQUAL_UINT32(0, idOf("../config.json"));
    TEST_ASSERT_EQUAL_UINT32(0, idOf("p03.jpg"));
    TEST_ASSERT_EQUAL_UINT32(0, idOf("p3.jpg/x"));
    TEST_ASSERT_EQUAL_UINT32(0, idOf("p.jpg"));
    TEST_ASSERT_EQUAL_UINT32(0, idOf("up.tmp"));
    TEST_ASSERT_EQUAL_UINT32(0, idOf(nullptr));
    char nm[16]; nameOf(42, nm, sizeof(nm));
    TEST_ASSERT_EQUAL_STRING("p42.jpg", nm);

    // Directory order is arbitrary; the list is upload (numeric) order.
    uint32_t ids[kMax]; int n = 0;
    n = insertId(ids, n, 10); n = insertId(ids, n, 2); n = insertId(ids, n, 9);
    n = insertId(ids, n, 9);                                  // duplicate
    TEST_ASSERT_EQUAL(3, n);
    TEST_ASSERT_EQUAL_UINT32(2, ids[0]); TEST_ASSERT_EQUAL_UINT32(9, ids[1]);
    TEST_ASSERT_EQUAL_UINT32(10, ids[2]);
    TEST_ASSERT_EQUAL_UINT32(11, nextId(ids, n));
    n = removeId(ids, n, 9);
    TEST_ASSERT_EQUAL(2, n); TEST_ASSERT_EQUAL_UINT32(10, ids[1]);
    TEST_ASSERT_EQUAL(2, removeId(ids, n, 77));
    TEST_ASSERT_EQUAL_UINT32(1, nextId(ids, 0));
    for (uint32_t k = 20; k < 40; k++) n = insertId(ids, n, k);
    TEST_ASSERT_EQUAL(kMax, n);                               // capped

    // Rotation: none shown yet → first; wraps; clamps after a delete.
    TEST_ASSERT_EQUAL(-1, nextIndex(-1, 0));
    TEST_ASSERT_EQUAL(0, nextIndex(-1, 3));
    TEST_ASSERT_EQUAL(1, nextIndex(0, 3));
    TEST_ASSERT_EQUAL(0, nextIndex(2, 3));
    TEST_ASSERT_EQUAL(0, nextIndex(5, 3));
}

// Sample photos (s<N>.jpg, like XP's Sample Pictures): their own names and
// list, never mistaken for a user photo and vice versa.
void test_photo_sample_names() {
    using namespace Photos;
    TEST_ASSERT_EQUAL_UINT32(2, idOf("s2.jpg", kSamplePrefix));
    TEST_ASSERT_EQUAL_UINT32(0, idOf("s2.jpg"));                 // not a user photo
    TEST_ASSERT_EQUAL_UINT32(0, idOf("p2.jpg", kSamplePrefix));
    TEST_ASSERT_EQUAL_UINT32(0, idOf("s02.jpg", kSamplePrefix));
    TEST_ASSERT_EQUAL_UINT32(0, idOf("s2.jpg/../x", kSamplePrefix));
    char nm[16]; nameOf(7, nm, sizeof(nm), kSamplePrefix);
    TEST_ASSERT_EQUAL_STRING("s7.jpg", nm);
    uint32_t ids[kMaxSamples]; int n = 0;
    for (uint32_t k = 1; k <= kMaxSamples + 3; k++) n = insertId(ids, n, k, kMaxSamples);
    TEST_ASSERT_EQUAL(kMaxSamples, n);                           // capped at its own size
    TEST_ASSERT_EQUAL_UINT32(1, ids[0]);
    TEST_ASSERT_EQUAL_UINT32(kMaxSamples, ids[kMaxSamples - 1]);
}

void test_photo_room_limits() {
    using namespace Photos;
    const uint32_t blk = 8192;
    TEST_ASSERT_EQUAL(ROOM_OK, room(0, 30000, 300000, blk));
    TEST_ASSERT_EQUAL(ROOM_FULL, room(kMax, 1, 300000, blk));
    TEST_ASSERT_EQUAL(ROOM_TOO_BIG, room(0, kMaxBytes + 1, 300000, blk));
    TEST_ASSERT_EQUAL(ROOM_OK, room(0, kMaxBytes, 300000, blk));
    // 64 KB reserve + one block of slack must stay free after the photo.
    TEST_ASSERT_EQUAL(ROOM_NO_SPACE, room(0, 30000, kReserveBytes + blk + 29999, blk));
    TEST_ASSERT_EQUAL(ROOM_OK, room(0, 30000, kReserveBytes + blk + 30000, blk));
    TEST_ASSERT_EQUAL_STRING("no_space", roomCode(ROOM_NO_SPACE));
}

// ── Desktop wallpaper (P-2026-11-26.12) ─────────────────────────────────────

void test_wallpaper_header_and_fallback() {
    uint8_t b[200];
    using namespace Photos;
    // Exactly 240×214 baseline; a photo-sized or swapped one is refused.
    size_t n = makeJpeg(b, 0xC0, 240, 214);
    JpegSniffer ok(Wallpaper::kW, Wallpaper::kH);
    TEST_ASSERT_EQUAL(JPEG_OK, ok.feed(b, n));
    JpegSniffer photo;                                   // photos still want 188²
    TEST_ASSERT_EQUAL(JPEG_BAD_SIZE, photo.feed(b, n));
    n = makeJpeg(b, 0xC0, 214, 240);
    JpegSniffer swapped(Wallpaper::kW, Wallpaper::kH);
    TEST_ASSERT_EQUAL(JPEG_BAD_SIZE, swapped.feed(b, n));
    n = makeJpeg(b, 0xC2, 240, 214);
    JpegSniffer prog(Wallpaper::kW, Wallpaper::kH);
    TEST_ASSERT_EQUAL(JPEG_PROGRESSIVE, prog.feed(b, n));
    // ≤ 40 KB, same free-space reserve as the photos.
    TEST_ASSERT_EQUAL(ROOM_OK, Wallpaper::room(40960, 300000, 8192));
    TEST_ASSERT_EQUAL(ROOM_TOO_BIG, Wallpaper::room(40961, 300000, 8192));
    TEST_ASSERT_EQUAL(ROOM_NO_SPACE, Wallpaper::room(30000, 30000 + 8192 + kReserveBytes - 1, 8192));
    // Fallback runs: 214 rows of exactly 240 px, palette indices in range.
    int i = 0;
    for (int y = 0; y < Desk::kDeskH; y++) {
        int x = 0;
        while (x < Desk::kDeskW) {
            TEST_ASSERT_TRUE(i < Desk::kDeskRunCount);
            TEST_ASSERT_TRUE(Desk::kDeskRuns[2 * i] < Desk::kDeskPalN);
            TEST_ASSERT_TRUE(Desk::kDeskRuns[2 * i + 1] > 0);
            x += Desk::kDeskRuns[2 * i + 1];
            i++;
        }
        TEST_ASSERT_EQUAL(Desk::kDeskW, x);
    }
    TEST_ASSERT_EQUAL(Desk::kDeskRunCount, i);
    TEST_ASSERT_EQUAL_HEX16(0x1ABA, Desk::kDeskPal[Desk::kDeskRuns[0]]);   // top band #1A55D0
}

// ── App remote control (design 2026-11-26.5) ────────────────────────────────

void test_control_prev_and_pause() {
    using namespace Control;
    TEST_ASSERT_EQUAL(-1, prevIndex(0, 0));
    TEST_ASSERT_EQUAL(2, prevIndex(0, 3));        // wraps to the last
    TEST_ASSERT_EQUAL(0, prevIndex(1, 3));
    TEST_ASSERT_EQUAL(0, prevIndex(0, 1));
    TEST_ASSERT_EQUAL(2, prevIndex(7, 3));        // out of range → last

    // Pause freezes the slide clock; resume continues from there (R-DK-4).
    Rotation r;
    uint32_t last = 1000, slide = 10000;
    TEST_ASSERT_EQUAL_UINT32(4000, elapsed(r, 5000, last));
    pause(r, 5000, last, slide);
    TEST_ASSERT_TRUE(r.paused);
    TEST_ASSERT_EQUAL_UINT32(4000, elapsed(r, 60000, last));   // frozen
    pause(r, 9000, last, slide);                                // idempotent
    TEST_ASSERT_EQUAL_UINT32(4000, r.frozen);
    TEST_ASSERT_EQUAL_UINT32(6000, slideLeft(elapsed(r, 60000, last), slide));
    last = resume(r, 60000, last);
    TEST_ASSERT_FALSE(r.paused);
    TEST_ASSERT_EQUAL_UINT32(56000, last);
    TEST_ASSERT_EQUAL_UINT32(5000, elapsed(r, 61000, last));
    TEST_ASSERT_EQUAL_UINT32(56000, resume(r, 70000, last));   // not paused: unchanged
    // A manual switch while paused: still paused, at the slide's start.
    pause(r, 62000, last, slide);
    restart(r);
    TEST_ASSERT_TRUE(r.paused);
    TEST_ASSERT_EQUAL_UINT32(0, elapsed(r, 99000, 99000));
    // Pausing an overdue slide (a card held the screen) caps at the slide.
    Rotation o; pause(o, 50000, 0, slide);
    TEST_ASSERT_EQUAL_UINT32(slide, o.frozen);
    TEST_ASSERT_EQUAL_UINT32(0, slideLeft(o.frozen, slide));
    TEST_ASSERT_EQUAL_UINT32(0, slideLeft(5, 0));
    // Wrap-around of millis().
    TEST_ASSERT_EQUAL_UINT32(20, elapsed(Rotation(), 10, 0xFFFFFFF6u));
}

void test_control_screen_off_wake() {
    using namespace Control;
    Attention::Item it;
    it.used = true;
    it.kind = Attention::K_SUCCESS;
    TEST_ASSERT_FALSE(wakesScreen(it));
    it.kind = Attention::K_APPROVAL; TEST_ASSERT_TRUE(wakesScreen(it));
    it.kind = Attention::K_INPUT;    TEST_ASSERT_TRUE(wakesScreen(it));
    it.kind = Attention::K_PROGRESS; TEST_ASSERT_FALSE(wakesScreen(it));
    it.urgent = true;                TEST_ASSERT_TRUE(wakesScreen(it));
    it.urgent = false;
    it.kind = Attention::K_ERROR;    TEST_ASSERT_TRUE(wakesScreen(it));     // user's red card
    strcpy(it.id, "sys:0:1");        TEST_ASSERT_FALSE(wakesScreen(it));    // device notice
    strcpy(it.id, "x");
    it.agent = Attention::AGENT_CLAUDE; TEST_ASSERT_FALSE(wakesScreen(it)); // agent error
    TEST_ASSERT_EQUAL(0, brightness(80, true, false));
    TEST_ASSERT_EQUAL(80, brightness(80, true, true));
    TEST_ASSERT_EQUAL(80, brightness(80, false, false));
}

// P-2026-11-26.13: intro once (GIF timings rounded up to the 200 ms tick), then the typing loop.
void test_clawd_work_timing() {
    using namespace ClawdWork;
    TEST_ASSERT_EQUAL_UINT32(3000, introTotalMs());
    for (int i = 0; i < kIntroFrames; i++) TEST_ASSERT_EQUAL_UINT16(0, kIntroMs[i] % 200);
    TEST_ASSERT_EQUAL_UINT8(0, slotAt(0));          // stands facing us
    TEST_ASSERT_EQUAL_UINT8(0, slotAt(399));
    TEST_ASSERT_EQUAL_UINT8(1, slotAt(400));        // wiggle
    TEST_ASSERT_EQUAL_UINT8(9, slotAt(2999));       // last intro frame: lands
    TEST_ASSERT_EQUAL_UINT8(10, slotAt(3000));      // typing loop
    TEST_ASSERT_EQUAL_UINT8(11, slotAt(3200));
    TEST_ASSERT_EQUAL_UINT8(12, slotAt(3400));
    TEST_ASSERT_EQUAL_UINT8(10, slotAt(3600));      // loops, never back to the intro
    TEST_ASSERT_EQUAL_UINT8(10, slotAt(3000 + 600UL * 1000));
    // Every slot exists in the generated bitmaps; the intro starts on frame 0 (GIF 0).
    for (int i = 0; i < kIntroFrames; i++) TEST_ASSERT_TRUE(kIntroSlot[i] < ClawdWorkBits::kFrames);
    for (int i = 0; i < kLoopFrames; i++)  TEST_ASSERT_TRUE(kLoopSlot[i] < ClawdWorkBits::kFrames);
    TEST_ASSERT_EQUAL_INT(13, ClawdWorkBits::kRows);
    TEST_ASSERT_EQUAL_INT(23, ClawdWorkBits::kCols);
}

// ── Setup-AP QR (R-WF-4) ─────────────────────────────────────────────────────

static void test_setup_qr_payload_is_open_wifi() {
    char b[64];
    TEST_ASSERT_TRUE(SetupQr::payload(b, sizeof(b), "glimmer-setup"));
    TEST_ASSERT_EQUAL_STRING("WIFI:T:nopass;S:glimmer-setup;;", b);
    TEST_ASSERT_TRUE(strlen(b) <= SetupQr::kMaxBytes);
}

static void test_setup_qr_payload_escapes_and_refuses_overflow() {
    char b[64];
    TEST_ASSERT_TRUE(SetupQr::payload(b, sizeof(b), "a;b:c"));
    TEST_ASSERT_EQUAL_STRING("WIFI:T:nopass;S:a\\;b\\:c;;", b);
    TEST_ASSERT_FALSE(SetupQr::payload(b, sizeof(b), ""));
    TEST_ASSERT_EQUAL_STRING("", b);
    TEST_ASSERT_FALSE(SetupQr::payload(b, 20, "glimmer-setup"));      // buffer too small
    TEST_ASSERT_EQUAL_STRING("", b);
    TEST_ASSERT_FALSE(SetupQr::payload(b, sizeof(b), "a-very-long-network-name-xx")); // > one v3 code
}

static bool finderAt(QRCode& q, int x0, int y0) {
    for (int y = 0; y < 7; y++)
        for (int x = 0; x < 7; x++) {
            bool ring = x == 0 || y == 0 || x == 6 || y == 6;
            bool core = x >= 2 && x <= 4 && y >= 2 && y <= 4;
            if (qrcode_getModule(&q, x0 + x, y0 + y) != (ring || core)) return false;
        }
    return true;
}

static void test_setup_qr_encodes_v3_with_finders() {
    char b[64];
    SetupQr::payload(b, sizeof(b), "glimmer-setup");
    uint8_t buf[128];
    TEST_ASSERT_EQUAL_UINT16(106, qrcode_getBufferSize(SetupQr::kVersion));   // display.cpp buf[106]
    QRCode q;
    TEST_ASSERT_EQUAL_INT(0, qrcode_initText(&q, buf, SetupQr::kVersion, ECC_MEDIUM, b));
    TEST_ASSERT_EQUAL_UINT8(SetupQr::kModules, q.size);
    const int e = q.size - 7;
    TEST_ASSERT_TRUE(finderAt(q, 0, 0));
    TEST_ASSERT_TRUE(finderAt(q, e, 0));
    TEST_ASSERT_TRUE(finderAt(q, 0, e));
    TEST_ASSERT_EQUAL_INT(148, SetupQr::tileSide(4));
}

// ── Mouse cursor (R-DK-17, app = mouse, device = screen) ────────────────────

template <int H>
static void checkRows(const char* const (&rows)[H], const CursorCore::Glyph& g) {
    TEST_ASSERT_EQUAL(H, g.h);
    TEST_ASSERT_TRUE(H <= CursorCore::kMaxH && g.w <= CursorCore::kMaxW);
    for (int r = 0; r < H; r++) {
        TEST_ASSERT_EQUAL_MESSAGE(g.w, (int)strlen(rows[r]), rows[r]);    // every row the glyph's width
        for (const char* c = rows[r]; *c; c++) TEST_ASSERT_TRUE(*c == 'B' || *c == 'W' || *c == '.');
        TEST_ASSERT_EQUAL_UINT16(0, g.blk[r] & g.wht[r]);
    }
    TEST_ASSERT_TRUE(g.hx < g.w && g.hy < g.h);
}

void test_cursor_glyphs_and_packets() {
    using namespace CursorCore;
    checkRows(kArrowRows, kGlyphs[SHAPE_ARROW]);
    checkRows(kHandRows,  kGlyphs[SHAPE_HAND]);
    // P-2026-11-27.24: wait = the arrow in a 21×22 box, hotspot at the tip; the glass runs 4 × 200 ms.
    TEST_ASSERT_EQUAL(kWaitW, kGlyphs[SHAPE_WAIT].w);
    TEST_ASSERT_EQUAL(kWaitH, kGlyphs[SHAPE_WAIT].h);
    TEST_ASSERT_TRUE(kWaitH <= kMaxH);
    TEST_ASSERT_EQUAL_UINT16(kGlyphs[SHAPE_ARROW].blk[18], kGlyphs[SHAPE_WAIT].blk[18]);
    TEST_ASSERT_EQUAL_UINT16(0, kGlyphs[SHAPE_WAIT].blk[21]);
    TEST_ASSERT_EQUAL(0, waitFrame(199));
    TEST_ASSERT_EQUAL(1, waitFrame(200));
    TEST_ASSERT_EQUAL(0, waitFrame(800));
    TEST_ASSERT_EQUAL_UINT16(0x8000, kGlyphs[SHAPE_ARROW].blk[0]);        // the tip: column 0, black
    TEST_ASSERT_TRUE(boxOf(10, 10, kGlyphs[SHAPE_NONE]).empty());

    // Round trip; anything else is dropped.
    Packet k; k.seq = 0xBEEF; k.x = 239; k.y = 0; k.shape = SHAPE_HAND;
    uint8_t b[kPacketLen]; encode(k, b);
    Packet r;
    TEST_ASSERT_TRUE(parse(b, sizeof(b), r));
    TEST_ASSERT_EQUAL_UINT16(0xBEEF, r.seq); TEST_ASSERT_EQUAL(239, r.x); TEST_ASSERT_EQUAL(0, r.y);
    TEST_ASSERT_EQUAL(SHAPE_HAND, r.shape);
    TEST_ASSERT_FALSE(parse(b, 7, r));
    b[6] = 240; TEST_ASSERT_FALSE(parse(b, sizeof(b), r));                  // off the panel
    encode(k, b); b[3] = SHAPE_COUNT; TEST_ASSERT_FALSE(parse(b, sizeof(b), r));
    encode(k, b); b[2] = 2; TEST_ASSERT_FALSE(parse(b, sizeof(b), r));     // another version
    encode(k, b); b[0] = 'X'; TEST_ASSERT_FALSE(parse(b, sizeof(b), r));

    // Sequence wraps; a late (reordered) packet is older.
    TEST_ASSERT_TRUE(newer(5, 4));
    TEST_ASSERT_TRUE(newer(2, 0xFFFE));
    TEST_ASSERT_FALSE(newer(4, 5));
    TEST_ASSERT_FALSE(newer(7, 7));
    // A late packet is dropped; the app reopening (counting from 0) is taken.
    TEST_ASSERT_FALSE(stillCurrent(4990, 5000));
    TEST_ASSERT_TRUE(stillCurrent(0, 30000));
    TEST_ASSERT_TRUE(stillCurrent(5001, 5000));
}

// R-DK-20: the app's power button. Off → shutting down → off; on → boot →
// on; a press during the other transition turns around.
void test_power_button_states() {
    using namespace Control;
    PowerState p;
    TEST_ASSERT_EQUAL(POWER_ON, p.p);
    TEST_ASSERT_FALSE(requestPower(p, true, 0));                 // already on
    TEST_ASSERT_TRUE(requestPower(p, false, 1000));
    TEST_ASSERT_EQUAL(POWER_SHUTTING, p.p);
    TEST_ASSERT_FALSE(advancePower(p, 1000 + kShutMs - 1));
    TEST_ASSERT_TRUE(advancePower(p, 1000 + kShutMs));
    TEST_ASSERT_EQUAL(POWER_OFF, p.p);
    TEST_ASSERT_EQUAL_STRING("off", powerName(p.p));
    TEST_ASSERT_FALSE(requestPower(p, false, 5000));             // already off
    TEST_ASSERT_TRUE(requestPower(p, true, 6000));
    TEST_ASSERT_EQUAL(POWER_BOOTING, p.p);
    TEST_ASSERT_TRUE(requestPower(p, false, 6100));              // off while booting: shuts down
    TEST_ASSERT_EQUAL(POWER_SHUTTING, p.p);
    TEST_ASSERT_TRUE(requestPower(p, true, 6200));               // on while shutting: boots again
    TEST_ASSERT_TRUE(advancePower(p, 6200 + kBootMs));
    // P-2026-11-27.24: boot screen, then the welcome screen 1 s (still "booting"), then on.
    TEST_ASSERT_EQUAL(POWER_WELCOME, p.p);
    TEST_ASSERT_EQUAL_STRING("booting", powerName(p.p));
    TEST_ASSERT_TRUE(powerScreen(p.p));
    TEST_ASSERT_FALSE(advancePower(p, 6200 + kBootMs + kWelcomeMs - 1));
    TEST_ASSERT_TRUE(advancePower(p, 6200 + kBootMs + kWelcomeMs));
    TEST_ASSERT_EQUAL(POWER_ON, p.p);
    TEST_ASSERT_EQUAL_STRING("on", powerName(p.p));
    TEST_ASSERT_FALSE(powerScreen(p.p));
}

// P-2026-11-27.24 Tắt máy tính › Khởi động lại: shutting, then the boot screen (not off).
void test_power_restart() {
    using namespace Control;
    PowerState p;
    TEST_ASSERT_TRUE(requestRestart(p, 100));
    TEST_ASSERT_EQUAL(POWER_SHUTTING, p.p);
    TEST_ASSERT_FALSE(requestRestart(p, 200));                   // already going down
    TEST_ASSERT_TRUE(advancePower(p, 100 + kShutMs));
    TEST_ASSERT_EQUAL(POWER_BOOTING, p.p);
    TEST_ASSERT_TRUE(advancePower(p, 100 + kShutMs + kBootMs));
    TEST_ASSERT_TRUE(advancePower(p, 100 + kShutMs + kBootMs + kWelcomeMs));
    TEST_ASSERT_EQUAL(POWER_ON, p.p);
    // Off pressed while restarting: it stays off.
    TEST_ASSERT_TRUE(requestRestart(p, 10000));
    TEST_ASSERT_TRUE(requestPower(p, false, 10100));
    TEST_ASSERT_TRUE(advancePower(p, 10000 + kShutMs));
    TEST_ASSERT_EQUAL(POWER_OFF, p.p);
    TEST_ASSERT_FALSE(powerScreen(p.p));
}

// P-2026-11-27.24 XP-Pointer: Start menu rows / sub-menu / Tắt máy tính / hot buttons under the cursor.
static PointerCore::StartInputs startIn(const char* skills, bool showAgents = false,
                                       std::initializer_list<int> recent = {}) {
    PointerCore::StartInputs si;
    si.in = XPCore::installedOf(skills, showAgents);
    int k = 0;
    for (int p : recent) si.recent[k++] = (int8_t)p;
    return si;
}

void test_pointer_start_menu() {
    using namespace PointerCore;
    StartLayout L;
    startLayout(startIn("agent,weather,clock"), L);
    // Claude, Codex, 3 most used (Thời tiết, Đồng hồ, AI hôm nay — filled), All, 5 right, 2 bottom.
    TEST_ASSERT_EQUAL(13, L.n);
    TEST_ASSERT_EQUAL(S_WEATHER, L.item[2]);
    TEST_ASSERT_EQUAL(S_AI, L.item[4]);
    TEST_ASSERT_EQUAL(99, L.row[2].y);                           // first row under the pinned two
    TEST_ASSERT_EQUAL(2, startHit(L, false, 28, 105));           // "Thời tiết"
    TEST_ASSERT_EQUAL(0, startHit(L, false, 60, 40));            // pinned Claude
    TEST_ASSERT_EQUAL(-1, startHit(L, false, 60, 96));           // the separator under the pins
    TEST_ASSERT_EQUAL(startIndexOf(L, S_SETTINGS), startHit(L, false, 180, 95));
    TEST_ASSERT_EQUAL(-1, startHit(L, false, 180, 82));          // right-column separator
    TEST_ASSERT_EQUAL(startIndexOf(L, S_TURNOFF), startHit(L, false, 190, 200));
    TEST_ASSERT_EQUAL(startIndexOf(L, S_RESTART), startHit(L, false, 30, 200));
    // All Programs: Claude, Codex, AI, Xu hướng, Thời tiết, Đồng hồ + Thêm / gỡ; fits at y 62.
    TEST_ASSERT_EQUAL(7, L.subN);
    TEST_ASSERT_EQUAL(4 + 20 * 6 + 7 + 20, L.subBox.h);
    TEST_ASSERT_EQUAL(62, L.subBox.y);
    TEST_ASSERT_EQUAL(144, L.subBox.x);
    TEST_ASSERT_EQUAL(96, L.subBox.w);
    TEST_ASSERT_EQUAL(-1, startHit(L, true, 180, 95));
    TEST_ASSERT_EQUAL(SUB_AI, L.sub[subHit(L, true, 180, 64 + 40 + 5)]);
    TEST_ASSERT_EQUAL(SUB_ADDREMOVE, L.sub[subHit(L, true, 180, 64 + 120 + 7 + 5)]);
    TEST_ASSERT_EQUAL(-1, subHit(L, false, 180, 105));
    // Agent off: programs from y 38.
    startLayout(startIn("photo"), L);
    TEST_ASSERT_EQUAL(S_PHOTO, L.item[0]);
    TEST_ASSERT_EQUAL(38, L.row[0].y);
}

// P-2026-11-27.25: the 3 programs opened last; every program in All Programs, moved up when tall.
void test_start_recent_and_full_sub_menu() {
    using namespace XPCore;
    using namespace PointerCore;
    int8_t r[kRecentN] = {PROG_NONE, PROG_NONE, PROG_NONE};
    noteRecent(r, PROG_CLAUDE);                                  // pinned: not counted
    noteRecent(r, PROG_FORECAST);                                // = Thời tiết
    noteRecent(r, PROG_MINES);
    noteRecent(r, PROG_TREND);
    noteRecent(r, PROG_MINES);                                   // again: to the front
    TEST_ASSERT_EQUAL(PROG_MINES, r[0]);
    TEST_ASSERT_EQUAL(PROG_TREND, r[1]);
    TEST_ASSERT_EQUAL(PROG_WEATHER, r[2]);
    noteRecent(r, PROG_CLOCK);                                   // the oldest falls out
    TEST_ASSERT_EQUAL(PROG_CLOCK, r[0]);
    TEST_ASSERT_EQUAL(PROG_MINES, r[1]);
    TEST_ASSERT_EQUAL(PROG_TREND, r[2]);
    // Shown: installed only (fun off → no Dò mìn), filled in order Ảnh, Thời tiết, …
    int8_t rows[kRecentN];
    TEST_ASSERT_EQUAL(3, recentRows(r, installedOf("agent,photo,clock", false), rows));
    TEST_ASSERT_EQUAL(PROG_CLOCK, rows[0]);
    TEST_ASSERT_EQUAL(PROG_TREND, rows[1]);
    TEST_ASSERT_EQUAL(PROG_PHOTO, rows[2]);
    TEST_ASSERT_EQUAL(1, recentRows(r, installedOf("clock", false), rows));
    // Everything on: 9 programs → (144, 2, 96 × 211), bottom row ends at y 212.
    StartLayout L;
    startLayout(startIn("agent,photo,weather,clock,fun", true), L);
    TEST_ASSERT_EQUAL(10, L.subN);
    TEST_ASSERT_EQUAL(2, L.subBox.y);
    TEST_ASSERT_EQUAL(211, L.subBox.h);
    TEST_ASSERT_EQUAL(SUB_MINES, L.sub[8]);
    TEST_ASSERT_EQUAL(4 + 20 * 8, L.subRow[8].y);
    TEST_ASSERT_EQUAL(212, L.subBox.y + L.subBox.h - 1);          // bottom edge
    TEST_ASSERT_EQUAL(4 + 20 * 9 + 7, L.subRow[9].y);              // Thêm / gỡ after the separator
    TEST_ASSERT_EQUAL(PROG_MINES, progOfSub(L.sub[8]));
    TEST_ASSERT_EQUAL(PROG_AGENTS, progOfSub(L.sub[4]));
}

// P-2026-11-27.25: Dò mìn on the desktop — column 1 before the trash, column 2 when column 1 is full.
// P-2026-11-27.25 Dò mìn: the board the app sends, the cell under a point, the LEDs, the clock.
void test_mines_view() {
    using namespace Mines;
    View v;
    TEST_ASSERT_EQUAL('.', v.cell[80]);
    char b[kCells + 1];
    memset(b, '.', kCells); b[kCells] = 0;
    b[0] = '1'; b[10] = 'F'; b[80] = 'X';
    TEST_ASSERT_TRUE(parseBoard(b, v.cell));
    TEST_ASSERT_EQUAL('F', v.cell[10]);
    b[5] = '?';                                                  // XP's ? mark is dropped (P-.25)
    TEST_ASSERT_FALSE(parseBoard(b, v.cell));
    TEST_ASSERT_EQUAL('.', v.cell[5]);
    TEST_ASSERT_FALSE(parseBoard("..F", v.cell));
    TEST_ASSERT_EQUAL(FACE_COOL, faceOf("cool"));
    TEST_ASSERT_EQUAL(-1, faceOf("sad"));
    TEST_ASSERT_EQUAL_STRING("dead", faceName(FACE_DEAD));
    // Cells (48 + 16c, 64 + 16r).
    TEST_ASSERT_EQUAL(0, cellAt(48, 64));
    TEST_ASSERT_EQUAL(10, cellAt(48 + 16 + 15, 64 + 16));
    TEST_ASSERT_EQUAL(80, cellAt(48 + 16 * 8 + 15, 64 + 16 * 8 + 15));
    TEST_ASSERT_EQUAL(-1, cellAt(47, 70));
    TEST_ASSERT_EQUAL(-1, cellAt(48 + 144, 70));
    // LEDs: 010, -01, capped 999.
    uint8_t d[3];
    ledDigits(10, d);
    TEST_ASSERT_EQUAL_HEX8(0x7E, d[0]); TEST_ASSERT_EQUAL_HEX8(0x30, d[1]); TEST_ASSERT_EQUAL_HEX8(0x7E, d[2]);
    ledDigits(-1, d);
    TEST_ASSERT_EQUAL_HEX8(kSegMinus, d[0]); TEST_ASSERT_EQUAL_HEX8(0x7E, d[1]); TEST_ASSERT_EQUAL_HEX8(0x30, d[2]);
    ledDigits(1500, d);
    TEST_ASSERT_EQUAL_HEX8(0x7B, d[0]);
    // The clock runs on from what the app sent, stops at 999, stands when not running.
    v.secs = 12; v.run = true;
    TEST_ASSERT_EQUAL(15, shownSecs(v, 1000, 4500));
    v.secs = 998;
    TEST_ASSERT_EQUAL(999, shownSecs(v, 0, 60000));
    v.run = false;
    TEST_ASSERT_EQUAL(998, shownSecs(v, 0, 60000));
}

void test_desk_icons_fun() {
    using namespace XPCore;
    DeskIcon ic[kDeskMax];
    int n = deskIcons("agent,photo,fun", ic);
    TEST_ASSERT_EQUAL(5, n);
    TEST_ASSERT_EQUAL(kDeskTrash, ic[3].prog);                   // trash last of column 1
    TEST_ASSERT_EQUAL(PROG_MINES, ic[4].prog);
    TEST_ASSERT_EQUAL(120, ic[4].cx);
    TEST_ASSERT_EQUAL(8, ic[4].y);
    n = deskIcons("photo,fun", ic);
    TEST_ASSERT_EQUAL(3, n);
    TEST_ASSERT_EQUAL(PROG_MINES, ic[1].prog);
    TEST_ASSERT_EQUAL(40, ic[1].cx);
    TEST_ASSERT_EQUAL(56, ic[1].y);
    TEST_ASSERT_EQUAL(kDeskTrash, ic[2].prog);
    TEST_ASSERT_EQUAL(PROG_MINES, progOf("mines"));
    TEST_ASSERT_EQUAL(ICON_MINES, iconFor("Mines"));
}

void test_pointer_turnoff_and_hot() {
    using namespace PointerCore;
    TEST_ASSERT_EQUAL(TO_STANDBY, turnOffHit(50, 100));
    TEST_ASSERT_EQUAL(TO_OFF, turnOffHit(120, 100));
    TEST_ASSERT_EQUAL(TO_RESTART, turnOffHit(190, 100));
    TEST_ASSERT_EQUAL(TO_CANCEL, turnOffHit(190, 160));
    TEST_ASSERT_EQUAL(-1, turnOffHit(85, 100));
    XPCore::BarState bar;
    bar.prog[0] = 0; bar.prog[1] = 2;
    TEST_ASSERT_EQUAL(0, hotAt(bar, true, 80, 225));
    TEST_ASSERT_EQUAL(1, hotAt(bar, true, 110, 225));
    TEST_ASSERT_EQUAL(kHotNone, hotAt(bar, true, 140, 225));    // empty slot
    TEST_ASSERT_EQUAL(kHotNone, hotAt(bar, true, 20, 225));     // start never lights
    TEST_ASSERT_EQUAL(kHotClose, hotAt(bar, true, 228, 11));
    TEST_ASSERT_EQUAL(kHotMin, hotAt(bar, true, 192, 11));
    TEST_ASSERT_EQUAL(kHotNone, hotAt(bar, true, 210, 11));     // □ is off
    TEST_ASSERT_EQUAL(kHotNone, hotAt(bar, false, 228, 11));    // desktop: no title bar
    TEST_ASSERT_EQUAL(XPCore::kBtnY, hotRect(1).y);
}

// R-DK-18/19: another item lit is the same menu (only the menu repaints).
void test_menu_hover_same_menu() {
    using namespace Control;
    Menu a; a.kind = XPCore::MENU_WINDOW; a.x = 71; a.y = 100;
    Menu b = a; b.hover = 3;
    TEST_ASSERT_EQUAL(-1, a.hover);
    TEST_ASSERT_TRUE(sameMenu(a, b));
    b.y = 90;
    TEST_ASSERT_FALSE(sameMenu(a, b));
    Menu c = a; c.minimized = true;
    TEST_ASSERT_FALSE(sameMenu(a, c));
}

void test_cursor_box_clipped() {
    using namespace CursorCore;
    const Glyph& a = kGlyphs[SHAPE_ARROW];
    Box m = boxOf(100, 50, a);                                   // hotspot = tip (0, 0)
    TEST_ASSERT_EQUAL(100, m.x); TEST_ASSERT_EQUAL(50, m.y);
    TEST_ASSERT_EQUAL(12, m.w);  TEST_ASSERT_EQUAL(19, m.h);
    Box e = boxOf(235, 230, a);                                  // runs off the bottom-right
    TEST_ASSERT_EQUAL(5, e.w); TEST_ASSERT_EQUAL(10, e.h);
    const Glyph& w = kGlyphs[SHAPE_WAIT];
    Box t = boxOf(230, 225, w);                                  // hotspot at the tip, runs off the corner
    TEST_ASSERT_EQUAL(230, t.x); TEST_ASSERT_EQUAL(225, t.y);
    TEST_ASSERT_EQUAL(10, t.w); TEST_ASSERT_EQUAL(15, t.h);
    TEST_ASSERT_TRUE(overlaps(m, boxOf(105, 60, a)));
    TEST_ASSERT_FALSE(overlaps(m, boxOf(112, 50, a)));           // side by side
    TEST_ASSERT_FALSE(overlaps(m, Box()));
}

int main(int, char**) {
    UNITY_BEGIN();
    RUN_TEST(test_setup_qr_payload_is_open_wifi);
    RUN_TEST(test_setup_qr_payload_escapes_and_refuses_overflow);
    RUN_TEST(test_setup_qr_encodes_v3_with_finders);
    RUN_TEST(test_claude_limits_drive_windows_and_ignore_codenames);
    RUN_TEST(test_claude_flat_fallback_uses_allowlist_only);
    RUN_TEST(test_claude_unrecognised_shape_is_rejected);
    RUN_TEST(test_codex_primary_plus_additional_limit_tag);
    RUN_TEST(test_codex_missing_primary_is_rejected);
    RUN_TEST(test_iso8601_variants);
    RUN_TEST(test_backoff_steps_and_cap);
    RUN_TEST(test_auth_latch_needs_two_consecutive);
    RUN_TEST(test_silent_failures_before_surfacing);
    RUN_TEST(test_retry_after_seconds_date_and_cap);
    RUN_TEST(test_history_slot_tag_rejects_previous_lap);
    RUN_TEST(test_history_last_reading);
    RUN_TEST(test_pace_empty_before_reset);
    RUN_TEST(test_pace_lasts_until_reset);
    RUN_TEST(test_pace_stops_at_window_reset_and_needs_span);
    RUN_TEST(test_trend_sums_drops_and_skips_resets);
    RUN_TEST(test_markup_403_blocks_but_never_latches_auth);
    RUN_TEST(test_jwt_exp_decode);
    RUN_TEST(test_cred_derivation_order);
    RUN_TEST(test_cred_meta_labels);
    RUN_TEST(test_notice_rate_limit);
    RUN_TEST(test_claude_grants_found_under_any_key);
    RUN_TEST(test_claude_without_grants_has_no_resets);
    RUN_TEST(test_codex_reset_credits);
    RUN_TEST(test_attention_upsert_updates_in_place);
    RUN_TEST(test_attention_order_and_eviction);
    RUN_TEST(test_attention_expire_and_clear);
    RUN_TEST(test_attention_holds_screen);
    RUN_TEST(test_attention_hook_mapping);
    RUN_TEST(test_codex_stop_is_a_delayed_your_turn);
    RUN_TEST(test_attention_json_legacy_and_new);
    RUN_TEST(test_night_window_wraps_and_disables);
    RUN_TEST(test_night_brightness);
    RUN_TEST(test_utf8_never_splits_a_letter);
    RUN_TEST(test_utf8_case_mapping_vietnamese);
    RUN_TEST(test_short_duration_units);
    RUN_TEST(test_countdown_units);
    RUN_TEST(test_clock_ampm_vietnamese);
    RUN_TEST(test_taskbar_buttons_and_badge);
    RUN_TEST(test_taskbar_state_looks);
    RUN_TEST(test_xp_progress_blocks_and_marquee);
    RUN_TEST(test_tray_weather_and_balloon);
    RUN_TEST(test_window_open_zoom_and_frame);
    RUN_TEST(test_tls_heap_gate);
    RUN_TEST(test_calendar_and_saver);
    RUN_TEST(test_projects_follow_hook_events);
    RUN_TEST(test_projects_order_idle_and_eviction);
    RUN_TEST(test_projects_sessions_merge_per_project);
    RUN_TEST(test_projects_stale_wait_released);
    RUN_TEST(test_projects_from_pushed_cards);
    RUN_TEST(test_skill_filter_and_default);
    RUN_TEST(test_taskbar_buttons_follow_enabled_skills);
    RUN_TEST(test_windows_adopt_and_prune);
    RUN_TEST(test_desk_icons_follow_skills);
    RUN_TEST(test_menu_geometry);
    RUN_TEST(test_clock_props_core);
    RUN_TEST(test_photo_jpeg_header_check);
    RUN_TEST(test_photo_names_order_and_rotation);
    RUN_TEST(test_photo_sample_names);
    RUN_TEST(test_photo_room_limits);
    RUN_TEST(test_wallpaper_header_and_fallback);
    RUN_TEST(test_control_prev_and_pause);
    RUN_TEST(test_control_screen_off_wake);
    RUN_TEST(test_clawd_work_timing);
    RUN_TEST(test_cursor_glyphs_and_packets);
    RUN_TEST(test_cursor_box_clipped);
    RUN_TEST(test_power_button_states);
    RUN_TEST(test_power_restart);
    RUN_TEST(test_pointer_start_menu);
    RUN_TEST(test_start_recent_and_full_sub_menu);
    RUN_TEST(test_desk_icons_fun);
    RUN_TEST(test_mines_view);
    RUN_TEST(test_pointer_turnoff_and_hot);
    RUN_TEST(test_menu_hover_same_menu);
    return UNITY_END();
}
