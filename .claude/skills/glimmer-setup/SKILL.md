---
name: glimmer-setup
description: Set glimmer up again after moving — a new computer (connect Claude Code / Codex hooks to the display) or a new place (put the display on a new Wi-Fi), or check that everything is connected. Use when the user says they changed machine, moved house/office, changed Wi-Fi, the project board or approval cards stopped showing, or asks "cài lại glimmer", "đổi mạng", "sang máy khác", "glimmer không hiện", "/glimmer-setup". Talk to the user in Vietnamese.
---

# glimmer — cài lại khi đổi máy hoặc đổi mạng

Two things can need redoing, independently:

| Situation | What breaks | Fix |
|---|---|---|
| **New / other computer** | no hooks → no approval cards, empty project board ("Chưa có hoạt động project") | `node tools/agents/install.mjs` |
| **Display moved to another Wi-Fi** | display can't join → shows `KẾT NỐI WI-FI · glimmer-setup` | give it the new SSID/password |

Both are wrapped by an interactive wizard the user can run themselves:
`node tools/glimmer-setup.mjs` (menu) or `… may-moi | wifi | kiem-tra`.

Facts you need (from the firmware, don't re-derive):
- Device answers on `http://glimmer.local` (mDNS) when it shares the
  computer's network. `GET /api/state` → `fw`, `ssid`, `ip`, `wifi`,
  `sources.claude`. `/hook` answers 200 to anything.
- Lost network → after 2 × 30 s it opens the **open** AP `glimmer-setup`,
  device at `http://192.168.4.1`, and keeps retrying the saved network every
  180 s. It remembers ONE network, 2.4 GHz only, no captive portals.
- `POST /api/settings {"wifiSSID","wifiPass","_restart":true}` sets Wi-Fi and
  reboots (Bearer token if the user set an API token — 401 tells you).
- The ESP8266 is single-threaded: during a TLS fetch it ignores HTTP for a
  few seconds. Use `--max-time 6` and retry once before calling it offline.

## 1. Find out where things stand — run, don't ask

```bash
node tools/glimmer-setup.mjs kiem-tra < /dev/null
```

It reports whether hooks are installed here, where they point, and whether
the device is online, in setup-AP mode, needs a token, or is unreachable.
Then pick the branch below. Only ask the user what you can't detect
(e.g. "did you move the display?") with AskUserQuestion.

## 2. New computer → install hooks (you can do this yourself)

```bash
node --version                        # needs ≥ 18
node tools/agents/install.mjs         # idempotent; merges into ~/.claude/settings.json
```

Read its last line:
- `display: OK` → done. Tell the user hooks apply to **new** Claude Code sessions.
- `wants a token` → ask the user for the device's API token (it is a secret:
  suggest they run `node tools/agents/install.mjs --token <t>` themselves),
  or run it with the token they give you.
- `no answer` → device not on this network. Either the user is elsewhere
  (fine — hooks stay silent until they are back) or the network blocks
  device-to-device traffic (office/guest Wi-Fi): ask for the IP shown on the
  display's **Thông tin** channel and run
  `node tools/agents/install.mjs --url http://<ip>`.

Codex: the installer also writes `~/.codex/hooks.json` when `~/.codex`
exists; Codex asks the user to trust new hooks once.

## 3. Display on a new Wi-Fi → the USER enters the password

**Never ask for the Wi-Fi password in chat**, and don't run the Wi-Fi step
yourself: joining `glimmer-setup` takes this computer offline, so this
session would stall mid-way. Hand it over:

- **If the device is still online here** (they are about to move it): they
  can pre-set the new network now — it switches when it sees it.
- **Otherwise**, give these steps, then tell them to run the wizard in their
  own terminal (not via `!`, which can't read the hidden password prompt):

> 1. Cắm điện thiết bị, chờ ~1 phút tới khi màn hình hiện **KẾT NỐI WI-FI · glimmer-setup**.
> 2. Chạy trong terminal của bạn: `node tools/glimmer-setup.mjs wifi`
>    — nó bảo bạn vào Wi-Fi `glimmer-setup`, hỏi tên + mật khẩu Wi-Fi mới
>    (gõ ẩn), gửi cho thiết bị rồi chờ thiết bị lên mạng mới.
> 3. Hoặc không cần máy tính: điện thoại vào Wi-Fi `glimmer-setup`, mở
>    `http://192.168.4.1`, tab **Wi-Fi**, nhập, Lưu.

Warn up front when relevant: 5 GHz-only networks and captive-portal Wi-Fi
(hotels, airports) can't work — use a phone hotspot (iPhone: "Maximize
Compatibility" for 2.4 GHz) for both the display and the laptop.

When they're back, re-run step 1 to confirm, and remind them to update the
city in the web UI's **Vị trí & giờ** tab if they moved.

## 4. Troubleshooting table

| Symptom | Cause → fix |
|---|---|
| Display stuck on "Đang kết nối Wi-Fi" > 4 min | unplug and replug (a cold boot resets the radio) |
| Back on `glimmer-setup` after entering Wi-Fi | wrong password/SSID (case-sensitive) or 5 GHz → redo step 3 |
| Online, but `glimmer.local` not found | network blocks mDNS/peers → install with `--url http://<ip>` |
| Hooks installed, board still empty | hooks start with the next Claude Code session; check `~/.glimmer/config.json` url |
| `install.mjs` says settings.json is not valid JSON | fix that file first — it changes nothing until then |

Uninstall everything on a machine: `node tools/agents/install.mjs --uninstall`.
