#pragma once
// 12/24-hour formatting shared by Clock, Home, Night and Weather.
#include <stdio.h>
#include <time.h>

namespace ClockFmt {

// Hour as shown on a big clock face: 0..23, or 1..12 in 12-hour mode.
inline int displayHour(int hour24, bool h24) {
    if (h24) return hour24;
    int h = hour24 % 12;
    return h ? h : 12;
}

// Two-character hour field: "07" (24 h) or " 7" (12 h, space-padded so the
// monospace clock geometry stays fixed).
inline void hourField(int hour24, bool h24, char* buf, size_t n) {
    snprintf(buf, n, h24 ? "%02d" : "%2d", displayHour(hour24, h24));
}

// 12-hour suffix: SA (sáng) / CH (chiều) — design token text.ampm.
inline const char* ampm(int hour24) { return hour24 < 12 ? "SA" : "CH"; }

// "THỨ HAI" … "CHỦ NHẬT" (full) or "T2" … "CN" (short). UTF-8.
inline const char* weekday(int wday, bool full) {
    static const char* const kFull[7]  = {"CHỦ NHẬT", "THỨ HAI", "THỨ BA", "THỨ TƯ",
                                          "THỨ NĂM", "THỨ SÁU", "THỨ BẢY"};
    static const char* const kShort[7] = {"CN", "T2", "T3", "T4", "T5", "T6", "T7"};
    if (wday < 0 || wday > 6) wday = 0;
    return full ? kFull[wday] : kShort[wday];
}

// "THỨ HAI<sep>24/11" — Vietnamese order, day before month. buf ≥ 24.
inline void date(const struct tm& tm, const char* sep, char* buf, size_t n) {
    snprintf(buf, n, "%s%s%d/%d", weekday(tm.tm_wday, true), sep, tm.tm_mday, tm.tm_mon + 1);
}

// "Chủ Nhật", "Thứ Hai" … "Thứ Bảy" — title case for the XP windows
// (P-2026-11-26.8: XP-Clock "Thứ Tư · 25/11", XP-Night "Thứ Tư 25/11").
inline const char* weekdayTitle(int wday) {
    static const char* const kTitle[7] = {"Chủ Nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư",
                                          "Thứ Năm", "Thứ Sáu", "Thứ Bảy"};
    if (wday < 0 || wday > 6) wday = 0;
    return kTitle[wday];
}

// "Thứ Hai<sep>24/11" in title case. buf ≥ 24.
inline void dateTitle(const struct tm& tm, const char* sep, char* buf, size_t n) {
    snprintf(buf, n, "%s%s%d/%d", weekdayTitle(tm.tm_wday), sep, tm.tm_mday, tm.tm_mon + 1);
}

// "GMT+7", "GMT-3", "GMT+5:30" from a UTC offset in minutes.
inline void gmtLabel(int tzMin, char* buf, size_t n) {
    char sign = tzMin < 0 ? '-' : '+';
    int a = tzMin < 0 ? -tzMin : tzMin;
    if (a % 60) snprintf(buf, n, "GMT%c%d:%02d", sign, a / 60, a % 60);
    else        snprintf(buf, n, "GMT%c%d", sign, a / 60);
}

// "17:48" or "5:48PM".
inline void hm(time_t t, bool h24, char* buf, size_t n) {
    struct tm tm; localtime_r(&t, &tm);
    if (h24) snprintf(buf, n, "%02d:%02d", tm.tm_hour, tm.tm_min);
    else     snprintf(buf, n, "%d:%02d%s", displayHour(tm.tm_hour, false), tm.tm_min,
                      ampm(tm.tm_hour));
}

}  // namespace ClockFmt
