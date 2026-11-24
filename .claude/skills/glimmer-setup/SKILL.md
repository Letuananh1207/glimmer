---
name: glimmer-setup
description: One command to make glimmer work wherever the user is now — a new computer, a new place, a new Wi-Fi. Installs the Claude Code / Codex hooks on this computer and, if the display isn't on this network, moves it onto this computer's current Wi-Fi automatically. Use when the user says they changed machine, moved house/office, changed Wi-Fi, the display shows "glimmer-setup", the project board or approval cards stopped showing, or asks "cài lại glimmer", "đổi mạng", "sang máy khác", "glimmer không hiện", "/glimmer-setup". Talk to the user in Vietnamese.
---

# glimmer — một lệnh cho mọi nơi mới

The whole job is `node tools/glimmer-setup.mjs auto` (repo root). It asks
nothing. It:

1. installs/updates the hooks on this computer (`tools/agents/install.mjs`,
   idempotent, keeps the user's other settings);
2. looks for the display — configured URL, `glimmer.local`, the setup AP;
3. if the display is not on this network: reads THIS computer's current
   Wi-Fi name and the password the OS saved for it, hops onto the display's
   open setup AP `glimmer-setup`, sends it that Wi-Fi, hops back, and waits
   until the display shows up on `glimmer.local`.

Exit code 0 = ready, 2 = needs the user (the output says what).

## Do this

1. **Tell the user first, in one short message** (they may have other apps
   or sessions online):
   > Mình sẽ chạy cài đặt tự động. Nếu thiết bị chưa ở mạng này, máy bạn sẽ
   > tạm rời Wi-Fi khoảng 1–2 phút để chuyển Wi-Fi cho thiết bị rồi tự quay
   > lại. Hãy cắm điện thiết bị.
2. **Run it in the foreground** with a long timeout (it can take ~6 min when
   the display is booting into its setup AP):
   ```bash
   node tools/glimmer-setup.mjs auto < /dev/null
   ```
   Run it as ONE command and don't do anything else until it returns: during
   the hop this computer has no Internet; it all happens inside that process,
   which needs none.
3. **Relay the result** in Vietnamese: `XONG` → done (hooks apply to Claude
   Code sessions started after install; remind them to set the city in the
   web UI's **Vị trí & giờ** tab if they moved). `CHƯA XONG` → follow the
   table below.

Never print, ask for, or echo a Wi-Fi password. If the OS can't give the
saved password, the user runs the interactive version themselves:
`node tools/glimmer-setup.mjs wifi` (hidden prompt) — not via `!`.

## When it says CHƯA XONG

| Output | Meaning → what to tell the user |
|---|---|
| `Máy này chưa vào Wi-Fi nào` | join the local Wi-Fi first, then rerun |
| `Không đọc được mật khẩu đã lưu` | run `node tools/glimmer-setup.mjs wifi` and type it (macOS may also just need the Keychain prompt approved) |
| `Không thấy Wi-Fi glimmer-setup` | display unpowered, still booting, or ONLINE ON ANOTHER NETWORK (the old place): power-cycle it here and rerun |
| `Thiết bị đòi API token` | `node tools/agents/install.mjs --token <token>`, rerun |
| `Thiết bị chưa lên "<ssid>"` | 5 GHz-only or captive-portal Wi-Fi (hotel/airport) → phone hotspot at 2.4 GHz (iPhone: Maximize Compatibility) for both, rerun; or the network hides devices from each other → IP from the display's **Thông tin** channel, `node tools/agents/install.mjs --url http://<ip>` |

Other checks: `node tools/glimmer-setup.mjs kiem-tra < /dev/null` prints the
hooks, the display, and its project board (`GET /api/state` → `projects`).

## Facts (don't re-derive)

- Display: `http://glimmer.local` on the shared network; after losing its
  network it opens the open AP `glimmer-setup` (device `http://192.168.4.1`)
  ~60 s after boot and retries the saved network every 180 s. One saved
  network, 2.4 GHz only. `POST /api/settings {"wifiSSID","wifiPass","_restart":true}`.
- ESP8266 is single-threaded: during a TLS fetch it ignores HTTP for seconds;
  the scripts retry with 6 s timeouts.
- Hook delivery: `~/.glimmer/glimmer-hook.mjs` caches the display's IP in
  `~/.glimmer/cache.json` (Node's mDNS lookup can take ~3 s on Windows);
  `auto` clears it after moving the display. Board: `POST /push/clear
  {"projects":true}` empties it; it survives reboots (`/projects.bin`).
- OS Wi-Fi control (`tools/wifi-os.mjs`): Windows `netsh` (tested),
  macOS `networksetup` + `security` Keychain, Linux `nmcli` (untested).
  The temporary `glimmer-setup` profile is deleted afterwards so the
  computer never auto-joins it.
- Uninstall the hooks on a computer: `node tools/agents/install.mjs --uninstall`.
