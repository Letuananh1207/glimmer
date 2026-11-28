#pragma once
// "Ngày và Giờ" touched like XP's Date and Time Properties (P-2026-11-26.22,
// screen_specs §17 XP-Real) — pure logic, host-tested. The app sends what the
// user touched (POST /api/clock); ch_clock.cpp draws it. RAM only.
//
//   tab 0 Ngày và giờ: month field "Thg <m>" + year spin, calendar of the viewed
//         month, a chosen day (just to look at), month list (9 rows + scroll bar)
//   tab 1 Múi giờ: zone field + world map (27 × 11 cells of 8 px), zone list
//   tab 2 Internet: auto sync, server, "Cập nhật ngay", last / next sync
#include <stdint.h>

namespace ClockCore {

enum Tab : uint8_t { TAB_DATE, TAB_ZONE, TAB_NET, TAB_COUNT };
enum List : uint8_t { LIST_NONE, LIST_MONTH, LIST_ZONE };

// What the app shows on the Clock window. year / month 0 = today's; day 0 = none chosen.
struct View {
    uint8_t  tab   = TAB_DATE;
    uint16_t year  = 0;
    uint8_t  month = 0;      // 1..12
    uint8_t  day   = 0;      // 1..31
    uint8_t  list  = LIST_NONE;
    uint8_t  top   = 0;      // first row shown in the open list
};

// ── Time zones (XP's list, shortened to what fits the 216-px field) ──
// Offsets in minutes; names live in flash in ch_clock.cpp, same order.
constexpr int kZoneCount = 12;
constexpr int16_t kZoneMin[kZoneCount] = {-480, -300, -180, 0, 60, 180, 240, 330, 420, 480, 540, 600};

// Index of [tzMin] in the list, -1 when the device uses an offset not listed.
inline int zoneIndex(int tzMin) {
    for (int i = 0; i < kZoneCount; i++) if (kZoneMin[i] == tzMin) return i;
    return -1;
}

// "(GMT+07:00)" / "(GMT-03:00)" / "(GMT+05:30)" into buf (≥ 12 bytes).
inline void gmtParen(int tzMin, char* buf) {
    const char sign = tzMin < 0 ? '-' : '+';
    const int a = tzMin < 0 ? -tzMin : tzMin, h = a / 60, m = a % 60;
    const char s[12] = {'(', 'G', 'M', 'T', sign, (char)('0' + h / 10), (char)('0' + h % 10), ':',
                        (char)('0' + m / 10), (char)('0' + m % 10), ')', 0};
    for (int i = 0; i < 12; i++) buf[i] = s[i];
}

// Map column of a zone: round((the zone's middle longitude + 180) / 13.33),
// longitude = offset hours × 15; 27 columns (0..26).
inline int mapColumn(int tzMin) {
    const int lon10 = tzMin * 10 / 4;                       // tenths of a degree (× 15 / 60)
    const int c = ((lon10 + 1800) * 3 + 200) / 400;          // / 13.33… rounded
    return c < 0 ? 0 : c > 26 ? 26 : c;
}

// Map land cells (token themeXP.dateTime.p22.zone.landRows): per row, column ranges [a, b].
struct Span { uint8_t a, b; };
constexpr int kMapCols = 27, kMapRows = 11;
constexpr Span kLand[kMapRows][3] = {
    {{4, 8}, {9, 12}, {18, 24}}, {{1, 8}, {10, 11}, {14, 26}}, {{3, 9}, {13, 25}, {0xFF, 0}},
    {{4, 8}, {13, 23}, {24, 24}}, {{5, 7}, {12, 22}, {0xFF, 0}}, {{6, 7}, {12, 17}, {19, 19}},
    {{8, 10}, {14, 16}, {21, 23}}, {{8, 10}, {15, 16}, {23, 24}}, {{8, 10}, {15, 16}, {22, 25}},
    {{8, 9}, {24, 24}, {26, 26}}, {{8, 8}, {0xFF, 0}, {0xFF, 0}},
};
// Row 5 has a fourth span [21, 22] in the token.
inline bool isLand(int row, int col) {
    if (row < 0 || row >= kMapRows) return false;
    for (const Span& s : kLand[row]) if (s.a != 0xFF && col >= s.a && col <= s.b) return true;
    return row == 5 && col >= 21 && col <= 22;
}

// ── Drop-down lists: 9 rows of 13 px, scroll bar 10 px wide ──
constexpr int kListRows = 9, kListRowH = 13;
inline int listCount(uint8_t list) { return list == LIST_MONTH ? 12 : list == LIST_ZONE ? kZoneCount : 0; }
inline int maxTop(uint8_t list) { const int n = listCount(list); return n > kListRows ? n - kListRows : 0; }
inline uint8_t clampTop(uint8_t list, int top) { const int m = maxTop(list); return (uint8_t)(top < 0 ? 0 : top > m ? m : top); }
// Thumb of the scroll bar in a track [y0, y0 + h): its top and height.
inline void thumb(uint8_t list, int top, int y0, int h, int& ty, int& th) {
    const int n = listCount(list);
    th = n > kListRows ? h * kListRows / n : h;
    const int m = maxTop(list);
    ty = y0 + (m ? (h - th) * top / m : 0);
}

// Short month name as Windows (Vietnamese) writes it: "Thg 11" (buf ≥ 7).
inline void monthShort(int m, char* buf) {
    buf[0] = 'T'; buf[1] = 'h'; buf[2] = 'g'; buf[3] = ' ';
    if (m >= 10) { buf[4] = '1'; buf[5] = (char)('0' + m - 10); buf[6] = 0; }
    else { buf[4] = (char)('0' + m); buf[5] = 0; }
}

// Day of the week of a date, 0 = Sunday (Sakamoto) — the calendar of any month the app browses to.
inline int wdayOf(int y, int m, int d) {
    static const int t[12] = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};
    if (m < 3) y -= 1;
    return (y + y / 4 - y / 100 + y / 400 + t[m - 1] + d) % 7;
}

// SNTP asks again every hour (ESP8266 core SNTP_UPDATE_DELAY).
constexpr uint32_t kSyncEveryS = 3600;

// ── Touched on the device (plan thiet-bi-la-may-tinh, stage 4; was the app's clock_rules.dart, R-DK-16) ──
inline int daysIn(int y, int m) {
    static const uint8_t kDays[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    if (m == 2) return (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)) ? 29 : 28;
    return m >= 1 && m <= 12 ? kDays[m - 1] : 30;
}
// First row shown when [list] opens on row [sel] (XP keeps the chosen row in view).
inline uint8_t topFor(uint8_t list, int sel) { return clampTop(list, sel - 4); }

enum HitKind : uint8_t {
    HIT_NONE, HIT_TAB, HIT_MONTH_LIST, HIT_YEAR_UP, HIT_YEAR_DOWN, HIT_DAY, HIT_PICK_MONTH, HIT_ZONE_LIST,
    HIT_PICK_ZONE, HIT_SCROLL_UP, HIT_SCROLL_DOWN, HIT_CLOSE_LIST, HIT_SYNC,
};
struct Hit { uint8_t kind = HIT_NONE; int16_t value = 0; };
inline Hit hit(uint8_t k, int v = 0) { Hit h; h.kind = k; h.value = (int16_t)v; return h; }
inline bool inBox(int x, int y, int rx, int ry, int rw, int rh) { return x >= rx && x < rx + rw && y >= ry && y < ry + rh; }

// A click while a drop list (lx, ly, w × 119) is open: a row picks (value = index + base), the scroll buttons scroll,
// anywhere outside closes it (XP).
inline Hit listHit(const View& v, int x, int y, int lx, int ly, int w, uint8_t pick, int base) {
    const int h = 2 + kListRows * kListRowH;
    if (!inBox(x, y, lx, ly, w, h)) return hit(HIT_CLOSE_LIST);
    if (x >= lx + w - 11) {
        if (y < ly + 11) return hit(HIT_SCROLL_UP);
        if (y >= ly + h - 11) return hit(HIT_SCROLL_DOWN);
        return Hit();
    }
    const int r = (y - ly - 1) / kListRowH, i = v.top + r;
    return r >= 0 && r < kListRows && i < listCount(v.list) ? hit(pick, i + base) : Hit();
}

// What a click at (x, y) on the Ngày và Giờ window hits (ch_clock.cpp's layout); [year] / [month] = today's.
inline Hit hitAt(const View& v, int x, int y, int year, int month) {
    if (y >= 26 && y < 42) {
        static const uint8_t kTabX[4] = {6, 93, 152, 218};
        for (int i = 0; i < 3; i++) if (x >= kTabX[i] && x < kTabX[i + 1]) return hit(HIT_TAB, i);
        return Hit();
    }
    switch (v.tab) {
        case TAB_DATE: {
            if (v.list == LIST_MONTH) return listHit(v, x, y, 14, 78, 67, HIT_PICK_MONTH, 1);
            if (inBox(x, y, 14, 62, 67, 16)) return hit(HIT_MONTH_LIST);
            if (inBox(x, y, 112, 60, 20, 10)) return hit(HIT_YEAR_UP);
            if (inBox(x, y, 112, 70, 20, 10)) return hit(HIT_YEAR_DOWN);
            if (inBox(x, y, 13, 98, 112, 78)) {
                const int vy = v.year ? v.year : year, vm = v.month ? v.month : month;
                const int i = ((y - 98) / 13) * 7 + (x - 13) / 16;
                const int lead = (wdayOf(vy, vm, 1) + 6) % 7;          // Monday first
                const int d = i - lead + 1;
                return d >= 1 && d <= daysIn(vy, vm) ? hit(HIT_DAY, d) : Hit();
            }
            break;
        }
        case TAB_ZONE:
            if (v.list == LIST_ZONE) return listHit(v, x, y, 12, 68, 216, HIT_PICK_ZONE, 0);
            if (inBox(x, y, 12, 50, 216, 18)) return hit(HIT_ZONE_LIST);
            break;
        default:
            if (inBox(x, y, 125, 98, 103, 21)) return hit(HIT_SYNC);
    }
    return Hit();
}

// [v] after hit [h]; [zone] = the device's zone index now. [sync] = ask the time servers again; [newZone] = a zone
// picked (its index), −1 none.
inline View apply(View v, const Hit& h, int year, int month, int zone, bool& sync, int& newZone) {
    sync = false;
    newZone = -1;
    const int vy = v.year ? v.year : year, vm = v.month ? v.month : month;
    switch (h.kind) {
        case HIT_TAB: v.tab = (uint8_t)h.value; v.list = LIST_NONE; break;
        case HIT_MONTH_LIST:
            if (v.list == LIST_MONTH) v.list = LIST_NONE;
            else { v.list = LIST_MONTH; v.top = topFor(LIST_MONTH, vm - 1); }
            break;
        case HIT_YEAR_UP:   v.year = (uint16_t)(vy + 1 > 2099 ? 2099 : vy + 1); v.month = (uint8_t)vm; v.day = 0; break;
        case HIT_YEAR_DOWN: v.year = (uint16_t)(vy - 1 < 1970 ? 1970 : vy - 1); v.month = (uint8_t)vm; v.day = 0; break;
        case HIT_DAY:       v.year = (uint16_t)vy; v.month = (uint8_t)vm; v.day = (uint8_t)h.value; break;
        case HIT_PICK_MONTH: v.year = (uint16_t)vy; v.month = (uint8_t)h.value; v.list = LIST_NONE; v.day = 0; break;
        case HIT_ZONE_LIST:
            if (v.list == LIST_ZONE) v.list = LIST_NONE;
            else { v.list = LIST_ZONE; v.top = topFor(LIST_ZONE, zone < 0 ? 0 : zone); }
            break;
        case HIT_PICK_ZONE: v.list = LIST_NONE; newZone = h.value; break;
        case HIT_SCROLL_UP:   v.top = clampTop(v.list, v.top - 1); break;
        case HIT_SCROLL_DOWN: v.top = clampTop(v.list, v.top + 1); break;
        case HIT_CLOSE_LIST: v.list = LIST_NONE; break;
        case HIT_SYNC: sync = true; break;
        default: break;
    }
    return v;
}


}  // namespace ClockCore
