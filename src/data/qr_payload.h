#pragma once
// Setup-AP QR code (R-WF-4, plan app/docs/tasks/2026-11-28-qr-cai-wifi.md) —
// pure logic, host-tested.
//
// The log-on screen shows a standard Wi-Fi QR for the open setup AP:
//   WIFI:T:nopass;S:glimmer-setup;;
// The glimmer app reads it (and an ordinary phone camera can join the AP
// from it). One fixed QR size: version 3 (29 × 29 modules), ECC M — 42 bytes
// of room, the payload is 32. The library is built with LOCK_VERSION=3
// (platformio.ini) so its version tables don't land in RAM.
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#ifdef ARDUINO
#include <pgmspace.h>                              // the head literal stays in flash
#else
#define PROGMEM
#define memcpy_P memcpy
#endif

namespace SetupQr {

constexpr uint8_t kVersion  = 3;
constexpr uint8_t kModules  = 17 + 4 * kVersion;   // 29
constexpr size_t  kMaxBytes = 42;                  // byte mode, v3, ECC M
constexpr uint8_t kQuiet    = 4;                   // white border, in modules (QR spec)

// "WIFI:T:nopass;S:<ssid>;;" with \ ; , : " escaped in the SSID.
// Returns false (out = "") when it would not fit in [n] or in one v3 code.
inline bool payload(char* out, size_t n, const char* ssid) {
    if (!out || n == 0) return false;
    out[0] = '\0';
    static const char kHead[] PROGMEM = "WIFI:T:nopass;S:";
    size_t len = sizeof(kHead) - 1;
    if (!ssid || !ssid[0] || len >= n) return false;
    memcpy_P(out, kHead, len);
    for (const char* p = ssid; *p; ++p) {
        bool esc = *p == '\\' || *p == ';' || *p == ',' || *p == ':' || *p == '"';
        if (len + (esc ? 2 : 1) >= n) { out[0] = '\0'; return false; }
        if (esc) out[len++] = '\\';
        out[len++] = *p;
    }
    if (len + 2 >= n) { out[0] = '\0'; return false; }
    out[len++] = ';';
    out[len++] = ';';
    out[len] = '\0';
    if (len > kMaxBytes) { out[0] = '\0'; return false; }
    return true;
}

// Side of the whole tile in px, quiet zone included, at [module] px per module.
constexpr int tileSide(int module) { return (kModules + 2 * kQuiet) * module; }

} // namespace SetupQr
