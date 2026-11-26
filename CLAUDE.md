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
  framebuffer (~115 KB). Literals in flash: `snprintf_P`/`PSTR`/`F()`.
- **Build**: `pio run -e nodemcuv2` (firmware), `pio run -e nodemcuv2 -t buildfs`
  (LittleFS image, `data/` → `/`), `pio test -e native` (host tests).
  Version: `-D FW_VERSION` in `platformio.ini`.
- **mDNS** `glimmer.local`; setup AP `glimmer-setup` (open) at `192.168.4.1`.
- **LittleFS files**: `/config.json` (settings), `/usage.bin` (history ring),
  `/weather.json` (last-good weather), `/photos/p<N>.jpg` (skill `photo`),
  `/wallpaper.jpg` (desktop wallpaper), `/fonts/*.vlw`, `/web/*`. A
  filesystem flash replaces all of them.

## Flashing (OTA over HTTP)

`POST /update`, form field exactly `firmware` or `filesystem`
(`ESP8266HTTPUpdateServer`). Firmware flash keeps the filesystem; filesystem
flash replaces it. `pio run -e ota` (espota) does **not** work — no ArduinoOTA.

Committed code: download CI builds from the rolling `latest` release instead
of building —
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
  `main.cpp` registers them (order = rotation order). `recomputeActive()` runs
  every rotation tick, so settings toggles apply within one slide.
- **Skills** (`src/data/skill_core.h`; R-SK-1/2, design 2026-11-25.3): several
  on at once, at least one — `Settings::skillsOn` CSV in `Skill::kAll` order
  (`agent`, `photo`, `weather`, `clock`); `skills_on` in config.json (missing →
  agent,weather,clock — `photo` starts off),
  `skillsOn` array in `/api/settings`, `skills_on` + `skills` (+ legacy
  `skill` = first on) in `/api/state`. Channels of enabled skills rotate, plus
  `skill = nullptr` system channels (Attention, Night, Info). Weather +
  Forecast = `weather`, Clock = `clock`, Photo = `photo`. New pack = id in `Skill::kAll` +
  taskbar button (`XPCore`) + tag its channels. App rules `R-SK-*`.
- `draw(ctx)` — full repaint on activation, may `Display::clear()`.
- `tick(ctx)` — 5 Hz while active. **Never** `Display::clear()` /
  `tft.fillScreen()`. File-static caches with sentinels (`-1`, `-2.f`) +
  per-region `paintX()` helpers that clear only their band; `draw()` seeds the
  cache. References: `ch_clock.cpp`, `ch_weather.cpp`.
- **No animated transitions** — rotation is an instant cut.
- **XP look** (P-2026-11-26.8/.9, `screen_specs.md` §17): every channel but
  Night is an XP window — `XP::window(title, icon, status)` (`xp.{h,cpp}`):
  title bar y 0–21, frame, body `Theme::XP::BODY` x 2–237 y 22–213 (content
  x 10–229, `Layout::XP_*`), optional status bar y 196–213. Components:
  `XP::progress` (9 blocks, pixelBar rule), `groupBox`, `field`, `dialog`,
  `loading`/`loadingStep`, `infoStrip`, `titleMeta` (`· cũ 14P`). `tick()`
  clear bands fill `XP::BODY`, never `BG`. Night + system screens stay black.
- **Clawd on the Claude window** (`ch_claude.cpp`, P-2026-11-26.13): top project Đang chạy → the GIF
  Clawd at work in x 132..229, y 22..83 — intro once (12 frames, GIF timings rounded up to the 200 ms
  tick: 3.0 s), then 3 typing frames × 200 ms (`clawd_work_core.h`, tested); bitmaps `src/ui/clawd_work.h`
  generated by `tools/clawdwork.py` from token `themeXP.clawdWork.frames`. Xong / empty board → asleep
  at (156, 44) + Zz squeezed into y 24..38; approval / error → the mood Clawd at (156, 36). The reset
  countdown never moves (TR 229, 84); the hero clears only x 10..131.
- **Home = the XP desktop** (`ch_home.cpp`, P-2026-11-26.12), no window:
  wallpaper y 0–213 (`/wallpaper.jpg`, else the fallback pixel wallpaper,
  `src/ui/desk_wallpaper.h` generated by `tools/deskwall.py`), icons
  Claude % / Codex % / Ảnh / Thùng rác with shadowed labels, weather tray
  balloon. `tick()` restores the wallpaper under a changed label with
  `Wallpaper::paint(rect, cap)` (partial JPEG decode, early stop) — never a
  fill colour. No taskbar button pressed (`XPCore::buttonFor("Home")`).
- **Taskbar** y 214–239 (`taskbar.{h,cpp}`, pure `xp_core.h`): painted by
  `main.cpp` after `draw()`, never by a channel; `Taskbar::update` ~4 Hz
  repaints only a changed button + the tray clock per minute. Start button,
  one 28-px button per enabled skill (packed from x 71), the active
  channel's pressed with 2-px slide progress at its bottom, AMBER badge on
  Claude = agents waiting; on a card that needs the user (approval /
  question / error) the Claude button is lit orange instead. Info and the
  desktop press none; Night has no taskbar (no waiting signal there). The dock and the
  y 230 strip are gone.
- System screens (`display.cpp`, after real XP, P-2026-11-26.9): boot
  (black, flag, logo, 3-block box — `splashStep(ms/200)` / `splashWait`
  repaint only the box), welcome = connecting, log-on = setup AP, "đang cập
  nhật..." = OTA. No info lines: the ssid / attempt / pct / line arguments
  are ignored. Each paints its chrome once; call
  `Display::resetSystemScreens()` from non-system entry points.

## Photos (skill `photo`, `src/data/photos.{h,cpp}`, `photos_core.h`)

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
- A TLS job starts only when `ESP.getMaxFreeBlockSize() >= Api::kTlsFloor`
  (20 000); otherwise deferred 5 s and counted in `heap_refusals` — never an
  upstream failure. Weather is plain HTTP and skips the gate.
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
  (backlight off). Window = minutes past midnight; start == end disables.
- **Idle dim** (`idleDim`, default on): no agent activity (hook event,
  pushed card, queue change — `AttentionQueue::lastActivityMs()`) for 15 min
  → backlight ≤ 15 %; a card holding the screen counts as activity; checked
  every 1 s in `loop()`. Night rules apply first. `showAgents` hides the
  Agents list channel (approval cards still interrupt).
- On the night face only these cards show (and wake a dark panel): `urgent`,
  a user's error card (agent `other`, not `sys:*`), and approvals/questions if
  `agentNightShow`. Others wait (no taskbar on the night face).
- **App remote** (design 2026-11-26.5, `control_core.h`, RAM only — R-DK-4):
  `/api/channel` `prev` / `pause` / `resume`, `POST /api/screen {"on"}`;
  `/api/state` `paused`, `screen_on`, `slide_ms`, `slide_left_ms`. Pause
  freezes the slide clock (`Control::Rotation`; taskbar progress stops, no
  other indicator yet — ticket `docs/phieu_panel/2026-11-26-tam-dung-xoay-va-tat-man.md`);
  screen off = backlight 0 on top of the night rules until an urgent /
  approval / question / user-error card holds the screen
  (`chAttentionWakesScreen`).

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
  per-model rows). Hooks are installed per computer with
  `node tools/agents/install.mjs` (Node only, `glimmer.local` by default).
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
