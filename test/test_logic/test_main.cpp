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
#include <time.h>
#include <initializer_list>
#if defined(_WIN32)   // host tests on Windows (MinGW) lack the POSIX localtime_r
static inline struct tm* localtime_r(const time_t* t, struct tm* out) { *out = *localtime(t); return out; }
#endif
#include "clockfmt.h"

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
    TEST_ASSERT_EQUAL(BTN_WEATHER, buttonFor("Weather"));
    TEST_ASSERT_EQUAL(BTN_WEATHER, buttonFor("Forecast"));
    TEST_ASSERT_EQUAL(BTN_CLOCK, buttonFor("Clock"));
    const char* agent[] = {"Home", "Agents", "Claude", "Codex", "AI", "Trend", "Setup"};
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

void test_taskbar_state_looks() {
    using namespace XPCore;
    BarState s;
    s.mask = buttonMask("agent,photo,weather,clock");
    s.active = BTN_CLAUDE; s.badge = 1; s.progress = 10; s.accent = 0xFA89;
    TEST_ASSERT_EQUAL(LOOK_PRESSED, lookOf(BTN_CLAUDE, s));
    TEST_ASSERT_EQUAL(LOOK_NORMAL, lookOf(BTN_PHOTO, s));
    TEST_ASSERT_EQUAL(1, badgeOn(BTN_CLAUDE, s));
    TEST_ASSERT_EQUAL(-1, badgeOn(BTN_WEATHER, s));
    TEST_ASSERT_EQUAL(10, progressOn(BTN_CLAUDE, s));
    TEST_ASSERT_EQUAL(0, progressOn(BTN_CLOCK, s));
    // A card that needs you: orange, no badge, no progress (XP-Attention).
    BarState f = s; f.flash = true;
    TEST_ASSERT_EQUAL(LOOK_FLASH, lookOf(BTN_CLAUDE, f));
    TEST_ASSERT_EQUAL(-1, badgeOn(BTN_CLAUDE, f));
    TEST_ASSERT_EQUAL(0, progressOn(BTN_CLAUDE, f));
    TEST_ASSERT_TRUE(buttonChanged(BTN_CLAUDE, s, f));
    TEST_ASSERT_FALSE(buttonChanged(BTN_PHOTO, s, f));
    // Progress tick on the Weather button repaints only that button.
    BarState w = s; w.active = BTN_WEATHER;
    BarState w2 = w; w2.progress = 11;
    TEST_ASSERT_TRUE(buttonChanged(BTN_WEATHER, w, w2));
    TEST_ASSERT_FALSE(buttonChanged(BTN_CLAUDE, w, w2));
    // Progress: 26 px × elapsed / slide, clamped; 0 for no slide.
    TEST_ASSERT_EQUAL(0, progressLen(0, 20000));
    TEST_ASSERT_EQUAL(13, progressLen(10000, 20000));
    TEST_ASSERT_EQUAL(26, progressLen(30000, 20000));
    TEST_ASSERT_EQUAL(0, progressLen(5000, 0));
    // Start button rounding: 5,3,2,1,1, 0×16, 1,1,2,3,5.
    TEST_ASSERT_EQUAL(5, startInset(0));
    TEST_ASSERT_EQUAL(0, startInset(5));
    TEST_ASSERT_EQUAL(0, startInset(20));
    TEST_ASSERT_EQUAL(1, startInset(21));
    TEST_ASSERT_EQUAL(5, startInset(25));
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
    uint8_t m = buttonMask("agent,clock");
    TEST_ASSERT_EQUAL(2, buttonCount(m));
    TEST_ASSERT_EQUAL(0, slotOf(BTN_CLAUDE, m));
    TEST_ASSERT_EQUAL(-1, slotOf(BTN_WEATHER, m));
    TEST_ASSERT_EQUAL(1, slotOf(BTN_CLOCK, m));
    TEST_ASSERT_EQUAL(-1, slotOf(BTN_NONE, m));
    TEST_ASSERT_EQUAL(101, buttonX(slotOf(BTN_CLOCK, m)));   // packed: x 71 + 30k
    TEST_ASSERT_EQUAL(3, buttonCount(buttonMask(Skill::kDefaultOn)));
    TEST_ASSERT_EQUAL(0, slotOf(BTN_WEATHER, buttonMask("weather")));
    // Ảnh (P-2026-11-25.7): tab 2, off by default.
    TEST_ASSERT_TRUE(Skill::known("photo"));
    TEST_ASSERT_FALSE(Skill::inList(Skill::kDefaultOn, "photo"));
    TEST_ASSERT_EQUAL(BTN_PHOTO, buttonFor("Photo"));
    uint8_t all = buttonMask("clock,photo,weather,agent");
    TEST_ASSERT_EQUAL(4, buttonCount(all));
    TEST_ASSERT_EQUAL(1, slotOf(BTN_PHOTO, all));
    TEST_ASSERT_EQUAL(3, slotOf(BTN_CLOCK, all));
    TEST_ASSERT_EQUAL(161, buttonX(3));   // design: Đồng hồ at x 161
    char on[48];
    Skill::normalise("clock,photo,agent", on, sizeof(on), true);
    TEST_ASSERT_EQUAL_STRING("agent,photo,clock", on);
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

int main(int, char**) {
    UNITY_BEGIN();
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
    RUN_TEST(test_projects_follow_hook_events);
    RUN_TEST(test_projects_order_idle_and_eviction);
    RUN_TEST(test_projects_sessions_merge_per_project);
    RUN_TEST(test_projects_from_pushed_cards);
    RUN_TEST(test_skill_filter_and_default);
    RUN_TEST(test_taskbar_buttons_follow_enabled_skills);
    RUN_TEST(test_photo_jpeg_header_check);
    RUN_TEST(test_photo_names_order_and_rotation);
    RUN_TEST(test_photo_room_limits);
    return UNITY_END();
}
