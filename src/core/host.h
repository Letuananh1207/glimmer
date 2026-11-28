#pragma once
// The display's own network name (L-10): glimmer-<last 2 MAC bytes, hex> — every display on a network
// answers its own mDNS name, so two of them never share "glimmer.local" (hooks went to the wrong one).
// The same name is the Wi-Fi hostname and the NSD service name the app finds ("glimmer*").

#include <ESP8266WiFi.h>

inline const char* deviceHost() {
    static char h[16] = "";
    if (!h[0]) {
        uint8_t m[6];
        WiFi.macAddress(m);
        snprintf_P(h, sizeof(h), PSTR("glimmer-%02x%02x"), m[4], m[5]);
    }
    return h;
}
