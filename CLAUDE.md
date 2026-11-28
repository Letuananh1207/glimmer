# glimmer — collaboration notes for Claude Code

Hard-won facts from building this firmware, so future sessions don't re-walk
the same dead ends. Repo layout, house rules and CI: `AGENTS.md`. The
agent-facing card/MCP contract: `docs/AGENTS-GLIMMER.md`. Keep this tight.

**Android app (`app/`, Flutter)**: rules in `app/CLAUDE.md` — MVVM standard
(`.claude/skills/flutter-dev/`), `/lead`, `/loi`, `/guide`; a Stop hook and git
pre-commit run `app/tool/guard.dart`. App UI is design-first: drawn on the canvas
https://claude.ai/artifact/WzLqGhKvD1MYxqaiRkzq1r, exported to `design/` by a design session
(`/ui-design`, outside VS Code), applied to code by `/ui-apply`. This file is firmware-only.

## Hardware & build

- **Target**: GeekMagic SmallTV-Ultra — ESP8266 @ 160 MHz, 4 MB flash
  (`eagle.flash.4m1m.ld`, 1 MB LittleFS), ST7789 240×240. Backlight GPIO5 is
  **active-low PWM** (`analogWrite 0` = full bright). USB-C is power only.
- **No PSRAM, ~30 KB free heap** at idle. Never allocate a full 240×240 16bpp
  framebuffer (~115 KB). Literals in flash: `snprintf_P`/`PSTR`/`F()` — every
  plain `"…"` lands in RAM (`.rodata`). ArduinoJson keys / string values
  `d[F("key")] = F("…")`, responses `server.send_P(…, PSTR(…), PSTR(…))`,
  headers `addHeader(F(…), F(…))` (L-4: moving these to flash freed 2.1 KB).
  Check `pio run` `RAM:` before / after any change.
- **Build**: `pio run -e nodemcuv2` (firmware), `pio run -e nodemcuv2 -t buildfs`
  (LittleFS image, `data/` → `/`), `pio test -e native` (host tests).
  Version: `-D FW_VERSION` in `platformio.ini`.
- **mDNS** `glimmer-<last 2 MAC bytes hex>.local` (`deviceHost()`, `src/core/host.h`, L-10 — each display its own
  name; ≤ 0.23.0 all answered `glimmer.local` and hooks went to the wrong one). Also the Wi-Fi hostname and the NSD
  name (app: `glimmer*`); `/api/state` `host`, `/hook` header `X-Glimmer-Host` (the hook checks it). Setup AP
  `glimmer-setup` (open) at `192.168.4.1`.
  The log-on screen's QR (`Display::drawSetupQr`, `qr_payload.h`, R-WF-4) = `ricmoo/QRCode` built with
  `-D LOCK_VERSION=3` (else ~560 B of version tables land in RAM); native tests need `lib_compat_mode = off` +
  `tools/pio_native_cflags.py` (host gcc defaults to C23, which breaks its `typedef bool`).
- **LittleFS files**: `/config.json` (settings), `/usage.bin` (history ring),
  `/weather.json` (last-good weather), `/photos/p<N>.jpg` (skill `photo`),
  `/wallpaper.jpg` (desktop wallpaper), `/trash/*` + `/trash/index.bin` (Thùng rác), `/fonts/*.vlw`,
  `/web/*`. A filesystem flash replaces all of them.

## Flashing (OTA over HTTP)

`POST /update`, form field exactly `firmware` or `filesystem`
(`ESP8266HTTPUpdateServer`). Firmware flash keeps the filesystem; filesystem
flash replaces it. `pio run -e ota` (espota) does **not** work — no ArduinoOTA.

CI no longer runs on push (manual `workflow_dispatch` only), so the rolling
`latest` release may lag `main` — build locally unless a manual run was just
made. Otherwise —
`https://github.com/Letuananh1207/glimmer/releases/download/latest/{firmware,littlefs}.bin`.
Build locally only for uncommitted changes.

**Firmware only** (no `data/` changes): just
`curl -F "firmware=@firmware.bin" http://<ip>/update`.

**Firmware + filesystem, preferred: bake the config in (no AP).** The device
keeps its config and never drops to the setup AP.

```bash
IP=<device-ip>; S=$(mktemp -d)            # scratch dir — will hold secrets
curl -sf -o "$S/cfg.json" http://$IP/api/export
jq -e '.wifi_ssid' "$S/cfg.json"          # raw config.json (snake_case keys);
                                          # camelCase/"***" = no config file, stop
cp -R data "$S/fs" && cp "$S/cfg.json" "$S/fs/config.json"
pio run -e nodemcuv2
PLATFORMIO_DATA_DIR="$S/fs" pio run -e nodemcuv2 -t buildfs
curl -F "firmware=@.pio/build/nodemcuv2/firmware.bin"   http://$IP/update
# wait for it to come back (curl --max-time poll on /api/state), then:
curl -F "filesystem=@.pio/build/nodemcuv2/littlefs.bin" http://$IP/update
trash "$S"                                # delete the secrets copy
pio run -e nodemcuv2 -t buildfs           # rebuild the normal (config-free) image
```

`PLATFORMIO_DATA_DIR` must be absolute. Usage history, the weather cache and
the user's **photos** are still lost (they live on the FS); history refills
over 7 days, photos and the wallpaper must be re-uploaded (`GET /api/photos`,
`GET /api/wallpaper` first to know).

**Fallback: restore via the setup AP.** Flash `littlefs.bin` as-is; the
device reboots into `glimmer-setup`. Join it, then:

```bash
curl -X POST -H 'Content-Type: application/json' \
     --data-binary @/tmp/glimmer-config-backup.json http://192.168.4.1/api/import
```

It reboots onto normal Wi-Fi. `/api/export` returns the raw config **with
secrets** (Wi-Fi password, keys) and is not auth-gated — treat backups as
secrets.

## VLW smooth fonts — the critical gotchas

1. **Path**: `Display::useFont(name)` calls `tft.loadFont("fonts/<name>",
   LittleFS)`; TFT_eSPI prepends `/` and appends `.vlw` → `/fonts/<name>.vlw`.
2. **Filesystem**: one-arg `tft.loadFont(name)` defaults to SPIFFS — a silent
   fail here. Always pass `LittleFS`.
3. **Silent failure**: a missing file prints to Serial and returns; later
   `drawString` uses the last loaded font, or GLCD 5×7. This ate days.
4. **Glyphs**: ASCII 0x20–0x7E + `°` + `·` (`EXTRA`) + all 134 Vietnamese
   letters (`VIET`) in every font except VT323-86 (digits only). Only fonts
   DRAWN with Vietnamese are used — VT323 and JetBrains Mono; accents
   synthesized onto Silkscreen/DM Mono never looked tidy and were dropped.
   `genfonts.py` refuses a font that lacks a letter. No `…`: write `...`.
   Missing glyphs are skipped silently — check with `tools/vlwpreview.py`
   (renders like the panel). The JBMono files carry the line box of the
   font each replaced (DMMono-11 → JBMono-11, Silkscreen-12/16 →
   JBMono-12B/16B, PixelifySans-14 → JBMono-13) so layouts did not move;
   TFT_eSPI recomputes `maxDescent` from glyphs > U+00FF, so a deeper
   glyph changes the line height of every string in that font.
5. **Heap**: `Api::tlsGetStream` calls `Display::releaseFont()` (frees ~3–5
   KB; 231 glyphs × 12 B of metrics) before every TLS handshake (~25 KB
   peak). Keep that.

## Vietnamese UI

- Device strings are Vietnamese UTF-8 literals in source (GCC is fine).
  Fixed `char[N]` are **bytes**: an accented letter is 2–3. Truncate with
  `Utf8::copy` / `Utf8::prevChar` (`src/data/utf8.h`), never bare
  `snprintf`/`strncpy` on text that can hold Vietnamese; case-map with
  `Utf8::upper` / `Utf8::sentence` (ASCII-only `-= 32` corrupts it).
- Short units: `P` phút, `G` giờ, `NG` ngày (`shortDuration`,
  `formatCountdown`); 12 h suffix `SA`/`CH` and dates via `ClockFmt`.
- API/MCP/JSON values and hook-generated card titles (`APPROVAL NEEDED`,
  `DONE`…) stay English; `ch_attention.cpp` translates them on screen.
- Before shipping a label, measure it against its slot (status title ≈ 88
  px, right meta ≈ 72 px) — Vietnamese runs longer than the English did.
6. **Shipped** (`data/fonts/`): JBMono-11/13/12B/16B, VT323-32/44/86. The
   generator also builds VT323-110 (unused) — don't ship unused ones (1 MB FS).

**VLW format** (verified against TFT_eSPI `Smooth_font.cpp`, big-endian):
header 24 B — u32 glyphCount, version (=11), fontSize, reserved, ascent,
descent. Per glyph 28 B, sorted by codepoint — u32 codepoint, height, width,
xAdvance, i32 dY (baseline→top, +up), i32 dX, u32 reserved. Then each
glyph's w×h grayscale bytes. Runbook: `.claude/skills/regenerate-fonts/SKILL.md`.

## Display polarity / panel quirks

- `tft.invertDisplay(true)` is required; off = cream/washed colours. Exposed
  as `settings.invertDisplay` in case a panel revision differs.
- Theme `BG = 0x0000`: the design's `#0E0D12` reads cyan-grey on this panel.

## Channels & PARTIAL REDRAW DISCIPLINE

- `channel.h`: `Channel { name, enabled, draw, tick, skill }`; `kChannels[]` in
  `main.cpp` registers them. **No rotation** (P-2026-11-26.14): the screen
  shows what the app opened until it opens something else; agent cards still
  interrupt, then the top window (else the desktop) comes back
  (`recomputeActive()`). Boot lands on the desktop as soon as it can show.
  A Photo window still steps its photos every `channelSec` (XP slideshow).
- **Skills** (`src/data/skill_core.h`; R-SK-1/2, design 2026-11-25.3): several
  on at once, at least one — `Settings::skillsOn` CSV in `Skill::kAll` order
  (`agent`, `photo`, `weather`, `clock`); `skills_on` in config.json (missing →
  agent,weather,clock — `photo` starts off),
  `skillsOn` array in `/api/settings`, `skills_on` + `skills` (+ legacy
  `skill` = first on) in `/api/state`. Channels of enabled skills can show, plus
  `skill = nullptr` system channels (Attention, Night, Info). Weather +
  Forecast = `weather`, Clock = `clock`, Photo = `photo`, Mines + Calc = `fun` (Giải trí, default off). New pack = id in
  `Skill::kAll` + program(s) in `XPCore::Prog` + desktop icon (`XPCore::deskIcons`) + Start rows
  (`PointerCore::startLayout`, `XPCore::installed`) + tag its channels. App rules `R-SK-*`.
- **Start lists** (P-2026-11-27.25): left column = pinned Claude / Codex + the **3 programs opened last**
  (`XPCore::noteRecent` in `mainShowChannel`, RAM; filled Ảnh, Thời tiết, Đồng hồ, Dò mìn, AI, Xu hướng,
  Agents); All Programs = every installed program, (144, top, 96 wide), top y 62 or moved up so the bottom
  is ≤ 213. Icons: `tools/minesicons.py` → `src/ui/mines_icons.h` (cut from the P-.25 full-screen artboards).
- **Dò mìn** (`ch_mines.cpp`, `mines_core.h`, P-2026-11-27.25): **the app keeps the game** (mines, flood
  open, win / loss); `POST /api/mines {board: 81 chars '.' 'F' 'P' '0'..'8' 'M' 'X' 'W', face, left, secs,
  run}` → the device repaints only the changed cells / face / LED and runs the seconds itself;
  `/api/state` `mines` (present = this firmware draws it). No menu bar, no `?` (P-.25).
- **More XP programs** (P-2026-11-28.28–.32): **the app is the computer** — it keeps the state / arithmetic and
  sends a view; the device draws, repaints only what changed, and lights its own buttons under the cursor
  (`chXPointer` from `pointerTick`, XP's hot ring, `XP::pushButton`). Colour 16-px icons: `src/ui/xp_icons.h`
  (`tools/deskicons.py`), `XPCore::colorIcon`. System windows (no skill, not in Start's "hay dùng"):
  **TaskMgr** (`POST /api/taskmgr {tab, sel}`; CPU % = the share of each second `loop()` is outside its
  `delay(10)`, histories 38/38/48 B in RAM, `perf_core.h`), **Display** (Thuộc tính màn hình: `POST /api/display`
  = the app's pending values, OK / Áp dụng = its `POST /api/settings`; setting `wallpaperMode` 0 (Không) =
  #004E98 / 1 Đồi xanh = fallback / 2 your photo; preview = wallpaper at 1/4 via `jpeg_thumb.cpp`),
  **Explorer** (Máy tính / Ảnh của tôi / Thùng rác, `POST /api/explorer {place, sel, top, confirm, do}`;
  deleting a photo = rename into `/trash/` (≤ 16, `trash.cpp`), the desktop bin shows full). **Calc**
  (skill `fun`, `POST /api/calc {display, error, mem, down}`; no Start row until designed). **Alt+Tab** =
  menu kind `alttab` + `sel` (`xp_alttab.cpp`; order = top window, then newest opened; `/api/state`
  `alttab`). Not drawn yet (no design): the taskbar's right-click menu (Trình quản lý tác vụ item).
- `draw(ctx)` — full repaint on activation, may `Display::clear()`.
- `tick(ctx)` — 5 Hz while active. **Never** `Display::clear()` /
  `tft.fillScreen()`. File-static caches with sentinels (`-1`, `-2.f`) +
  per-region `paintX()` helpers that clear only their band; `draw()` seeds the
  cache. References: `ch_clock.cpp`, `ch_weather.cpp`.
- **No animated transitions** — every switch is an instant cut, with exactly
  two exceptions (P-2026-11-26.16, XP-Open, user-approved): restoring a
  minimized window / minimizing one (the app's `_`, `/api/channel
  {"zoom":"min"}`) zooms the title bar between its taskbar button and the top
  (`XP::zoom`, 4 × 40 ms, **blocks loop ~160 ms**, `delay()` yields to Wi-Fi);
  and a window that just came up (not from a card / the night face, not a
  repaint) shows its empty frame + the wait cursor (`XP::emptyFrame`,
  `XPCore::frameOf`) for 200 ms, the content drawn from `loop()`
  (`drawDueContent`; no `tick()` meanwhile). Its taskbar button presses first:
  with the taskbar on screen `drawActive()` only `Taskbar::update`s changed
  buttons (full draw after Night / a system screen,
  `Display::systemScreenShown()`). Loading screens (Claude, Codex, Weather,
  AI) = XP File Download: `XP::loading(label, source)` globe → flying paper →
  folder + "từ claude.ai" …, `loadingStep` moves paper / marquee / hourglass.
- **XP look** (P-2026-11-26.8/.9, `screen_specs.md` §17): every channel but
  Night is an XP window — `XP::window(title, icon, status)` (`xp.{h,cpp}`):
  title bar y 0–21, frame, body `Theme::XP::BODY` x 2–237 y 22–213 (content
  x 10–229, `Layout::XP_*`), optional status bar y 196–213. Components:
  `XP::progress` (9 blocks, pixelBar rule), `groupBox`, `field`, `dialog`,
  `loading`/`loadingStep`, `infoStrip`, `titleMeta` (`· cũ 14P`). `tick()`
  clear bands fill `XP::BODY`, never `BG`. Night + system screens stay black.
  The □ caption button is drawn off (`CAPTION_OFF`): windows never resize.
- **Clawd on the Claude window** (`ch_claude.cpp`, P-2026-11-26.13): top project Đang chạy → the GIF
  Clawd at work in x 132..229, y 22..83 — intro once (12 frames, GIF timings rounded up to the 200 ms
  tick: 3.0 s), then 3 typing frames × 200 ms (`clawd_work_core.h`, tested); bitmaps `src/ui/clawd_work.h`
  generated by `tools/clawdwork.py` from token `themeXP.clawdWork.frames`. Xong / empty board → asleep
  at (156, 44) + Zz squeezed into y 24..38; approval / error → the mood Clawd at (156, 36). The reset
  countdown never moves (TR 229, 84); the hero clears only x 10..131.
- **Home = the XP desktop** (`ch_home.cpp`, P-2026-11-26.12), no window:
  wallpaper y 0–213 (`/wallpaper.jpg`, else the fallback pixel wallpaper,
  `src/ui/desk_wallpaper.h` generated by `tools/deskwall.py`), as XP: only
  installed programs, **one column** x 40 (P-2026-11-26.17, `XPCore::deskIcons`:
  Claude / Codex / Ảnh / Thùng rác — no Weather / Clock icons; Weather
  opens from the tray icon, the clock from the tray clock, both via the app)
  with shadowed labels that are **just the name** (P-2026-11-26.18, no %).
  Codex / Ảnh / Thùng rác are XP colour bitmaps 32×23 at real pixels
  (P-2026-11-26.19, `src/ui/desk_icons.h` generated by `tools/deskicons.py`
  from the source SVGs; transparent cells keep the wallpaper); the app's
  selected icon (`windows.sel`): Clawd xpSelectClawd, bitmaps dithered
  xpSelectIcon on (x+y)-even cells. Nothing changes by itself: `tick()` is
  empty. No taskbar button pressed.
- **XP-Real windows** (P-2026-11-26.17, §17 XP-Real): Clock = "Date and Time
  Properties" (`XP::tabs`, month calendar from Monday, analog face from a
  60-entry flash sine table — **no `sinf`/`cosf`**, libm's tables cost ~800 B
  RAM — repainted once a second, read-only time field, `Múi giờ: GMT+7 · <place>`),
  **touched from the app** (P-2026-11-26.22, `clock_core.h`): 3 tabs (Ngày và
  giờ / Múi giờ / Internet), month + year fields, month list, a chosen day,
  zone list + 27×11 world map, Internet = SNTP last / next sync
  (`settimeofday_cb`), "Cập nhật ngay" = `configTime` again;
  Weather = property sheet tab "Hiện tại" (32-px `XP::weatherIcon`, 6 rows, no
  status bar); **Forecast = tab "Dự báo" of the same window**:
  `XPCore::progOf("Forecast") == PROG_WEATHER` (one program, one taskbar
  button, title "Thời tiết"), ListView Details. The place name is the
  setting `weatherPlace` (`weather_place`), sent by the app with its location.
- **No tray balloon** (P-2026-11-26.21): the weather tray icon (180, 220)
  stays; the app taps it to open the Weather window.
- **Taskbar** y 214–239 (`taskbar.{h,cpp}`, pure `xp_core.h`): painted by
  `main.cpp` after `draw()`, never by a channel; `Taskbar::update` ~4 Hz
  repaints only a changed slot + the tray clock per minute. Start button,
  one 28-px button per **open window** (P-2026-11-26.14: the app's list,
  opening order, last 4, from x 71; nothing open → start + tray only; weather
  skill on → tray from x 176 with the weather icon at (180, 220) and only the
  last **3** buttons, P-2026-11-26.15), the
  top window's pressed while it shows, no slide progress. AMBER badge = agents
  waiting and the orange "needs you" look sit on the **Claude window's**
  button only (no Claude window open → no taskbar signal; the card itself
  still interrupts). Night has no taskbar.
- **Context menus** (`xp_menu.{h,cpp}`, P-2026-11-26.14 XP-Menu): desktop
  (166×127) / window (128×113) menu drawn by `main.cpp` over the screen on
  `POST /api/menu`; the channel's `tick()` is paused while one is open;
  closing (`kind:none`, any `/api/channel`, a card) repaints with `draw()`.
  The app picks items itself and sends the command — the device never acts
  on a menu. **Start menu** (`xp_start.{h,cpp}`, P-2026-11-26.20 XP-Start):
  `kind:"start"` (+ `all` = All Programs open) draws the XP two-column Start
  menu over (0, 0)–(239, 213) with the start button pressed
  (`BarState.startDown`); its 16-px icons are in `src/ui/start_icons.h`
  (`tools/deskicons.py`). Same rules: the app's sheet picks, the device draws.
- System screens (`display.cpp`, after real XP, P-2026-11-26.9): boot
  (black, flag, logo, 3-block box — `splashStep(ms/200)` / `splashWait`
  repaint only the box), welcome = connecting, log-on = setup AP, "đang cập
  nhật..." = OTA. No info lines: the ssid / attempt / pct / line arguments
  are ignored. Each paints its chrome once; call
  `Display::resetSystemScreens()` from non-system entry points.

## Photos (skill `photo`, `src/data/photos.{h,cpp}`, `photos_core.h`)

- **The app's library** (app plan `app/docs/tasks/2026-11-27-kho-anh-tren-app.md`, R-AK-*;
  `photo_source_core.h`, tested in `test/test_photo_source`): the app is the memory, the device points at it.
  `POST /api/photos/source {host, port, key}` (RAM; `{clear}`) — each slide asks
  `GET http://host:port/p/<key>/next?after=<id on screen>` (plain HTTP, 3 s timeout; 200 = JPEG + `X-Photo-Id /
  -Index / -Count`, 204 = empty), written to `/photos/cur.jpg` then drawn (repaints never ask again). The device keeps
  only the pointer (id). A failed ask → the cache (the `p<N>.jpg` user photos = the app's 8 newest, then samples),
  asked again after 60 s. A slide moves only when `main.cpp` calls `chPhotoRequestStep()` (slideshow tick); any
  other `draw()` shows the photo on screen again. `/api/state` `photo_source {state, remote, index, count}`.

- Baseline JPEG, exactly 188×188 (the device never scales), ≤ 8 photos, ≤ 40
  KB each, upload refused if LittleFS would keep < 64 KB + 1 block free. The
  header is checked while the upload streams (`JpegSniffer`); chunks go straight
  to `/photos/up.tmp`, renamed on success.
- Decode: TJpgDec's C core (`tjpgd.c`, not the `TJpgDec` class, whose 3.5 KB
  workspace would be static) with a malloc'd workspace freed after each draw;
  MCU blocks are `pushImage`d with swap bytes on. Peak ≈ 3.7 KB; the font is
  released first if the largest block is short.
- Wallpaper (`src/data/wallpaper.{h,cpp}`): same rules, one baseline JPEG of
  exactly 240×214 at `/wallpaper.jpg` (`/api/wallpaper`, field `wallpaper`);
  `JpegSniffer(Wallpaper::kW, kH)`. A file that fails to decode is latched
  broken → fallback until the next upload / delete.

## Fetch scheduler & heap gate

- No blocking "refresh all". `main.cpp` job table: claude, codex,
  codex-resets (hourly), weather, status-claude, status-openai. At most one
  job per loop pass, starts ≥ 3 s apart.
- A TLS job starts only when `FetchPolicy::tlsHeapOk(freeHeap, maxBlock)`:
  largest block ≥ 12 000 **and** free heap ≥ 20 000 (L-4, 2026-11-26 — the
  old "largest block ≥ 20 000" refused forever after an OTA soft restart split
  the heap into 15–19 KB blocks, though TLS with 4 K / 1 K buffers then works
  and the heap re-coalesces); otherwise deferred 5 s and counted in
  `heap_refusals` — never an upstream failure. Weather is plain HTTP and skips the gate.
- `FetchPolicy::State` (`fetch_policy.h`): backoff 60→120→240→300 s,
  `Retry-After` honoured (≤ 6 h), credential latched bad only after **two**
  consecutive JSON 401/403. Errors surface only after 3 failures or a latched
  credential; until then stale data stays up.
- A job triggers a full redraw only when the data's *shape* changes
  (loading → valid → error); value changes are `tick()`'s job.
- Bodies are streamed into a filtered ArduinoJson parse (`tlsGetStream`) —
  never `getString()`.
- Claude per-model windows come from `limits[]` (`weekly_scoped`) or a fixed
  allowlist (`seven_day_opus`/`seven_day_sonnet`/`extra_usage`) — never a sweep
  of top-level keys (rotating internal codenames). Reset credits: `grants[]`
  under any top-level key (filter wildcard `"*"`); Codex
  `wham/rate-limit-reset-credits`.

## Credential states (`src/data/cred_state.h`)

- `NOT_SET / CHECKING / OK / EXPIRING / EXPIRED / REJECTED / BLOCKED`, derived
  by `Api::refreshCred()` after each fetch, on settings change, and every 10 s
  (a JWT crossing `exp` is noticed).
- **HTML 401/403 = an edge (Cloudflare) challenging the device, not a dead
  key** → `BLOCKED` after two in a row, never fed to the auth latch, retried
  every 15 min. Only JSON 401/403 ×2 → `REJECTED`.
- Codex `exp` from its JWT: `EXPIRING` < 72 h; `EXPIRED` skips the fetch.
  Claude's sessionKey has no expiry — it only fails.
- Surfaces, all in `src/channels/chrome.{h,cpp}`: `credCard` (no data),
  dimmed values + `credBanner` (data), `credLine` (Home/AI rows), `usageMeta`
  (status-bar meta).
- Device notices (`notice()` in `main.cpp`): 12 s `sys:*` cards through the
  attention queue, rate-limited per provider/reason (`CredState::NoticeLog`),
  not raised at night.
- No keys at all → `Setup` channel (hidden once either key is set, or both
  usage channels are off).

## Stale data & night modes

- `Api::isStale`: older than 3 × refresh interval (15 min floor) → dimmed hero
  + amber `STALE 14M` meta, never a takeover.
- `nightMode` 0 none, 1 dim, 2 clock (Night face only, no rotation), 3 dark
  (backlight off). Window = minutes past midnight; start == end disables. The
  Night face is an XP screen saver (P-2026-11-26.17): the 170×100 time + date
  block jumps every minute (`XPCore::saverSpot`, x 6–64, y 6–134, ≥ 30 px).
- **Idle dim** (`idleDim`, default on): no agent activity (hook event,
  pushed card, queue change — `AttentionQueue::lastActivityMs()`) for 15 min
  → backlight ≤ 15 %; a card holding the screen counts as activity; checked
  every 1 s in `loop()`. Night rules apply first. `showAgents` hides the
  Agents list channel (approval cards still interrupt).
- On the night face only these cards show (and wake a dark panel): `urgent`,
  a user's error card (agent `other`, not `sys:*`), and approvals/questions if
  `agentNightShow`. Others wait (no taskbar on the night face).
- **App remote** (design 2026-11-26.5 → .7, `control_core.h`, RAM only): the
  app is the computer, the device its screen. `POST /api/channel {name}`
  opens a window (adopted into the list if the app did not send it),
  `POST /api/windows {open, top, min, sel}` = the app's open windows (whole
  list each time), `POST /api/menu` (`desktop` / `window` / `start`),
  `POST /api/clock {tab, year, month, day, list, top, sync}` (Clock window),
  `POST /api/screen {"on"}`; `/api/state` `windows`, `menu`, `clock`,
  `ntp_last` / `ntp_next`, `paused` (still reported: the app detects the remote
  firmware by it), `screen_on`, `slide_ms` / `slide_left_ms` (always 0).
  `prev` / `pause` / `resume` still answer but nothing rotates. Screen off = backlight 0 on top of the night rules until an urgent /
  approval / question / user-error card holds the screen
  (`chAttentionWakesScreen`).
- **The device is the computer** (app plan `app/docs/tasks/2026-11-28-thiet-bi-la-may-tinh.md`, in stages): mouse
  datagram **v2** `'G' 'C' 2 buttons seq16 x y` (buttons bit 0 left / 1 right; a change sent 3× with one seq) →
  `Cursor` queues the presses, `main.cpp inputTick()` works out what a click does with `input_core.h` (pure, tested:
  `leftClick(Scene, x, y, dbl)`, XP double click ≤ 500 ms / ≤ 4 px, `shapeAt` = the device picks the cursor shape) and
  applies it with the same functions the HTTP commands use; windows keep an activation order (`Control::Windows::z`,
  `closeWindow` brings the previous one back). `/api/state` `input {mouse, stage}`; stage 1 = desktop (click selects,
  double click opens, Recycle Bin → Explorer › Thùng rác), taskbar (start, buttons, tray icon / clock), _ / ×, Start
  (Thiết bị → Máy tính; Số liệu / Cài đặt / Thêm-gỡ do nothing until their windows are drawn), Tắt máy tính. v1
  packets (the app works clicks out) still work.
- **Mouse, keyboard, power** (app plan `app/docs/tasks/2026-11-27-app-la-chuot-ban-phim-nguon.md`,
  R-DK-17…21): the app is the mouse / keyboard / power button, the device
  only the screen. **Cursor** (`cursor_core.h` pure + glyphs, `channels/cursor.cpp`):
  the app sends `'G' 'C' 1 shape seq16 x y` over **UDP :4210** (~30 / s, on
  change; a big backwards seq jump = the app reopened); `/api/state` `cursor`
  `{port, x, y, shape, shown, repaint_ms, repaint_max}`. The panel has **no
  MISO — no pixel read-back, no save-under**: moving the cursor calls
  `repaintRect()` (`main.cpp`) = tick() first, then the window's `draw()` +
  `Taskbar::repaint()` + the open menu under `Display::beginRepaint()` — drawn
  into a sprite of the clip box (L-8: `tft` is `(*g_tft)`, the panel or that
  sprite; JPEG blocks via `Display::pushImage`), pushed in one go, screen coords. So every `draw()` must be **repaint-safe**:
  under `Display::repainting()` keep caches / timers / slideshow (Photo,
  Claude's Clawd T0, Attention cycle) and guard blocks with
  `Display::clipHits(x, y, w, h)` — a font load is ~30 ms, a missed guard
  makes the cursor crawl (measured: Claude 193 → 4–80 ms, Home 8 ms).
  Anything that paints calls `Cursor::overlay()` after. No cursor on Night,
  system screens, screen off, power off. Shapes (P-2026-11-27.24 XP-Pointer):
  arrow 12×19, hand 16×19, wait = arrow + XP-Open's hourglass (21×22, 4 ×
  200 ms); in mouse mode (`Cursor::mouseMode()`) `XP::waitCursor` turns the
  cursor into wait where it is (`Cursor::busy`, 300 ms per call) instead of
  the fixed cell (132, 160). **Menu hover**: `/api/menu {…, hover}` (item
  index without separators) lights it xpSelect, dim items too (as XP); same
  menu + new hover repaints only the menu. **Start menu / Tắt máy tính light
  the row under the cursor themselves** (`pointer_core.h` geometry, the app's
  `hover` / `sub` wins: Start = left column, right column, bottom band; `sub`
  = All Programs rows); another row lit repaints only two rows. **Hot**
  (device-computed): the taskbar button / title-bar _ / × under the cursor
  lights (`XP::setHot`, repaintRect of its box); none while a menu is open.
  `/api/state` `menu_hover`, `menu_sub`, `hot`. **Tắt máy tính**
  (`xp_turnoff.{h,cpp}`, menu kind `turnoff`): Start › `Tắt máy` or Alt+F4
  on the desktop (the app opens it); dotted shade over all 240×240 + XP's
  Turn off computer box; no taskbar update under it; Chờ / Tắt / Khởi động
  lại / Hủy are the app's `/api/screen off` (closes it) / `/api/power off` /
  `/api/power {restart}` / `/api/menu none`. **Power**: `POST /api/power
  {on}` → `shutting` ("đang tắt máy..." screen, `Display::drawShutDown`, 1.5
  s) → `off` (= screen off, windows cleared) / `booting` (boot splash 2.4 s →
  welcome 1 s, still reported `booting`) → `on` (desktop, no windows);
  `{restart:true}` = shutting → booting. The power screens own the panel
  (`Control::powerScreen`: no drawActive, tick, taskbar, cursor);
  `/api/state` `power`.

## Attention queue (agents, push, device notices)

- One queue (`attention_core.h`, 5 slots) behind `POST /push`, `GET /push`,
  `/push/clear`, `/hook`, MCP `push_card`/`clear_card`/`list_cards`, and the
  device's own `sys:*` notices. Upsert by id updates in place (no new
  interrupt unless the kind escalates); kind order = priority; a full queue
  never evicts an approval/input for something less important (push → 409).
- `/hook` takes the **trimmed** event from `tools/agents/glimmer-hook.sh`,
  never raw hook JSON (PostToolUse carries whole tool output; bodies > 2 KB
  are ignored). It always answers 200 so a hook can't block an agent.
- Items can be **hidden until `showAfter`**: Codex has no idle event, so its
  `Stop` queues a "your turn" card visible only after 60 s (`kCodexIdleS`);
  `UserPromptSubmit` clears it first if the user replies. Use
  `ordered(q, ord, now)` / `countWaiting(q, now)` for anything on screen.
- `Attention` channel = the full-screen card (holds ≤ 30 s, or until answered
  for approvals/inputs when `pinApprovals`; several holders cycle every 6 s).
  `Agents` channel = the list (≤ 3 rows; more → 2 rows + "+ N more").
- Card layout (`ch_attention.cpp`): centred `■ AGENT · project`, one VT323
  focal word/value (64, steps to 44), one muted detail line, kind-coloured
  status (`NEEDS YOU · 2M` / `WAITING · 2M`), queue dots or a time-left
  hairline.
- Enums are `K_*` / `SHOW_*` — `INPUT` is an Arduino macro.
- **Project board** (`projects_core.h`, owned in `attention.cpp`): latest
  state per project from every `/hook` event + pushed cards with a
  `project`; drawn in the Claude screen's bottom rows (replaced resets and
  per-model rows). Persisted (`/projects.bin`), so a wait (approval / input)
  whose session went silent — e.g. on a computer that left the network —
  must not live forever (L-5): it yields to a newer session of the same
  project + agent ≥ 10 min later, and expires after 2 h with no event.
  Hooks are installed per computer with
  `node tools/agents/install.mjs` (Node only; finds the display with `tools/agents/discover.mjs` — an HTTP sweep
  of the /24, mDNS browse from Node is dropped by Windows' firewall — and pins `http://glimmer-xxxx.local`).
- Keep `docs/AGENTS-GLIMMER.md` in sync with `attention_json.h`,
  `attention_core.h` and the MCP schema in `web.cpp`.

## Settings round-trip — four files

1. `src/core/storage.h` — field + default in `Settings`.
2. `src/core/storage.cpp` — `doc["snake_key"] | default` on load,
   `doc["snake_key"] = s.field` on save. Renaming a key needs a load-time
   fallback (see `tz_min`, `night_mode`).
3. `src/core/web.cpp` — `handleApiGetSettings` + `applyIfPresent` (camelCase).
   Runtime values are applied by `mainSettingsChanged()` after `Storage::save`.
4. `data/web/index.html` — input with `x-model="settings.fieldName"`.

## pixelBar

9 discrete segments with 1-px BG gaps, each fully lit or empty — **no partial
fills** (92% and 99% bars used to look like they crossed). Segment i lights
when `pct > i * 11.11`, so anything ≥ 89% is full.

## Common pitfalls

- **clangd noise** (missing `Arduino.h`, `uint16_t`…): no PlatformIO context.
  `pio run` is the truth.
- **Filesystem flash wipes config** unless baked in (see Flashing).
- **`ESP.restart()` doesn't reset the Wi-Fi RF** — after it the connect fails
  and the device strands in AP mode. Wi-Fi recovery is in-place, STA retries
  forever. At boot: 2 × 30 s attempts, then the setup AP, which retries the
  saved network every 180 s.
- **`Auth -1` / `Auth -2`** from a fetch = BearSSL handshake failed under heap
  pressure, not a bad key. Check `/api/state` `maxblk` / `heap_refusals`.
- **No sleep loops** in build/flash scripts; for "wait for the device" a short
  poll with `curl --max-time` is fine.

## Where the design lives

`design/` at the repo root is the **Android app's** design (see above), except
`design/panel/`: the **panel's** 240×240 design. Same design-first flow as the
app: drawn on the canvas https://claude.ai/artifact/Kkt5gUfTSSTjxKBZ6mPuZA by
`/panel-design` (outside VS Code), exported to `design/panel/` (CHANGELOG codes
`P-YYYY-MM-DD.N`), applied to firmware by `/panel-apply` (progress in
`.panel_design_sync.json`); tickets in `docs/phieu_panel/`. Don't hand-edit
`design/panel/`. The old `/tmp/smalltv-design` archive is gone; until the first
redraw is chốt, the code is the reference — `tools/screens.py` renders it with
the real fonts (`--compare` puts each `design/panel/screens/@2x/XP*.png` beside it). Tokens live in `src/core/theme.h` (RGB565) and
`data/fonts/*.vlw` (design-spec pixel sizes).
