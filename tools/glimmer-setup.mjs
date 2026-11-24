#!/usr/bin/env node
// glimmer-setup.mjs — trình hướng dẫn tương tác (tiếng Việt) cho các việc hay
// làm lại khi đổi máy hoặc đổi mạng:
//
//   node tools/glimmer-setup.mjs           menu
//   node tools/glimmer-setup.mjs may-moi   cài hook cho máy này
//   node tools/glimmer-setup.mjs wifi      đổi Wi-Fi cho thiết bị
//   node tools/glimmer-setup.mjs kiem-tra  kiểm tra thiết bị + hook
//
// Chỉ cần Node (≥ 18). Mật khẩu Wi-Fi được gõ ẩn, gửi thẳng tới thiết bị và
// không được lưu ở đâu trên máy này.
//
// Device API used: GET /api/state, POST /api/settings
//   {wifiSSID, wifiPass, _restart:true}  (Bearer token if one is set).
// In setup-AP mode the device is http://192.168.4.1 (open AP "glimmer-setup").

import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { createInterface } from "node:readline";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const CFG = join(homedir(), ".glimmer", "config.json");
const AP_URL = "http://192.168.4.1";
const AP_SSID = "glimmer-setup";

// ── terminal helpers ────────────────────────────────────────────────────────
const c = (n) => (s) => (process.stdout.isTTY ? `\x1b[${n}m${s}\x1b[0m` : s);
const bold = c(1), dim = c(2), green = c(32), yellow = c(33), red = c(31), cyan = c(36);
const ok = (s) => console.log(green("  ✓ ") + s);
const warn = (s) => console.log(yellow("  ! ") + s);
const bad = (s) => console.log(red("  ✗ ") + s);
const step = (s) => console.log("\n" + bold(cyan("▸ " + s)));

const rl = createInterface({ input: process.stdin, output: process.stdout, terminal: true });
let muted = false;
rl._writeToOutput = (s) => {                      // hide what is typed for passwords
  if (!muted) return rl.output.write(s);
  if (s.includes("\n") || s.includes("\r")) rl.output.write("\n");
  else if (s.length === 1) rl.output.write("*");
};
// Lines are queued as they arrive: piped input delivers several at once, and
// rl.question() would drop the ones that come before it is called.
const lines = [], waiters = [];
rl.on("line", (l) => (waiters.length ? waiters.shift()(l) : lines.push(l)));
let closed = false;
rl.on("close", () => { closed = true; while (waiters.length) waiters.shift()(""); });
const nextLine = () => (lines.length ? Promise.resolve(lines.shift())
                                     : new Promise((res) => waiters.push(res)));
const ask = async (q, dflt = "") => {
  rl.output.write(`  ${q}${dflt ? dim(` [${dflt}]`) : ""}: `);
  return (await nextLine()).trim() || dflt;
};
const askSecret = async (q) => {
  rl.output.write(`  ${q}: `);
  muted = true;
  const a = await nextLine();
  muted = false;
  return a;
};
const pause = (q = "Nhấn Enter để tiếp tục") => ask(dim(q));
// End of input never counts as "yes" — nothing changes on the device by accident.
const yes = async (q, dflt = "c") => {
  const a = await ask(`${q} (c/k)`, dflt);
  return !(closed && !lines.length && a === dflt) && /^(c|co|có|y|yes)$/i.test(a);
};

// ── device helpers ──────────────────────────────────────────────────────────
const readCfg = () => { try { return JSON.parse(readFileSync(CFG, "utf8")); } catch { return {}; } };

async function http(url, { method = "GET", body, token, timeout = 3000 } = {}) {
  const headers = {};
  if (body) headers["Content-Type"] = "application/json";
  if (token) headers.Authorization = `Bearer ${token}`;
  try {
    const r = await fetch(url, { method, headers, body: body && JSON.stringify(body),
                                 signal: AbortSignal.timeout(timeout) });
    let json = null; try { json = await r.json(); } catch {}
    return { status: r.status, json };
  } catch (e) { return { status: 0, error: e.cause?.code || e.name }; }
}

// The ESP8266 is single-threaded: during a TLS fetch (a few s) its web server
// doesn't answer, so allow 6 s and one retry before calling it offline.
const state = async (url, token, tries = 2) => {
  for (let i = 0; i < tries; i++) {
    const r = await http(`${url}/api/state`, { token, timeout: 6000 });
    if (r.status === 200 && r.json) return r.json;
    if (r.status === 401) return null;
  }
  return null;
};

// Poll until `fn` returns truthy or `seconds` pass; prints a dot per try.
async function waitFor(fn, seconds, label) {
  process.stdout.write(`  ${label} `);
  const end = Date.now() + seconds * 1000;
  while (Date.now() < end) {
    const v = await fn();
    if (v) { process.stdout.write(green(" ✓\n")); return v; }
    process.stdout.write(".");
    await new Promise((r) => setTimeout(r, 3000));
  }
  process.stdout.write(red(" hết giờ\n"));
  return null;
}

// Where is the device right now? Configured URL, glimmer.local, then the AP.
async function locate() {
  const cfg = readCfg();
  const tried = [...new Set([cfg.url, "http://glimmer.local"].filter(Boolean))];
  for (const url of tried) {
    const s = await state(url, cfg.token);
    if (s) return { url, mode: "sta", state: s, token: cfg.token };
    const r = await http(`${url}/api/state`, { token: cfg.token });
    if (r.status === 401) return { url, mode: "sta", needsToken: true };
  }
  const ap = await state(AP_URL, cfg.token);
  if (ap) return { url: AP_URL, mode: "ap", state: ap, token: cfg.token };
  return null;
}

function describe(s) {
  const src = s.sources?.claude;
  console.log(dim(`    firmware ${s.fw || "?"} · Wi-Fi ${s.ssid || "?"} (${s.wifi || "?"}) · IP ${s.ip || "?"}`));
  if (src) console.log(dim(`    Claude: ${src.valid ? "có dữ liệu" : "chưa có dữ liệu"}${src.err ? " · lỗi " + src.err : ""}`));
}

// ── 1. máy mới: cài hook ────────────────────────────────────────────────────
async function newMachine() {
  step("Cài hook cho máy này (Claude Code / Codex → thiết bị)");
  const major = Number(process.versions.node.split(".")[0]);
  if (major < 18) { bad(`Cần Node ≥ 18 (đang là ${process.versions.node}).`); return; }

  let dev = await locate();
  let url = dev?.url, token = readCfg().token || "";
  if (dev?.mode === "ap") {
    warn(`Thiết bị đang ở chế độ cài đặt (${AP_SSID}). Đổi Wi-Fi cho nó trước (mục 2), rồi chạy lại mục này.`);
    return;
  }
  if (!dev) {
    warn("Không tìm thấy thiết bị qua glimmer.local.");
    console.log(dim("    Máy này phải cùng mạng Wi-Fi với thiết bị. IP xem trên màn hình thiết bị, kênh Thông tin."));
    url = await ask("Địa chỉ thiết bị (vd http://192.168.1.50)", "http://glimmer.local");
    if (!/^https?:\/\//.test(url)) url = "http://" + url;
  }
  if (dev?.needsToken) token = await askSecret("Thiết bị yêu cầu API token — nhập token");

  const args = [join(here, "agents", "install.mjs"), "--url", url.replace(/\/+$/, "")];
  if (token) args.push("--token", token);
  const r = spawnSync(process.execPath, args, { stdio: "inherit" });
  if (r.status !== 0) { bad("Cài hook thất bại (xem lỗi ở trên)."); return; }
  ok("Xong. Mở phiên Claude Code mới để hook có hiệu lực.");
}

// ── 2. đổi Wi-Fi cho thiết bị ──────────────────────────────────────────────
async function changeWifi() {
  step("Đổi mạng Wi-Fi cho thiết bị");
  console.log(dim("    Thiết bị chỉ nhớ MỘT mạng, chỉ dùng được Wi-Fi 2,4 GHz, và không vào được"));
  console.log(dim("    mạng phải đăng nhập qua trang web (khách sạn, sân bay) — khi đó dùng hotspot điện thoại."));

  let dev = await locate();
  if (dev?.needsToken) dev.token = await askSecret("Thiết bị yêu cầu API token — nhập token");
  if (dev?.mode === "sta") {
    ok(`Thiết bị đang online ở ${dev.url}${dev.state ? "" : " (có token)"}.`);
    if (dev.state) describe(dev.state);
    console.log(dim("    Có thể đặt sẵn mạng mới ngay bây giờ: thiết bị sẽ rời mạng hiện tại và vào mạng mới"));
    console.log(dim("    khi nó bắt được sóng (ví dụ sau khi bạn mang nó tới chỗ mới)."));
    if (!(await yes("Đặt Wi-Fi mới cho thiết bị ngay bây giờ?"))) return;
  } else {
    console.log(`
  Thiết bị chưa ở trên mạng này. Làm lần lượt:
   1. Cắm điện thiết bị, chờ khoảng 1 phút tới khi màn hình hiện ${bold("KẾT NỐI WI-FI · " + AP_SSID)}.
   2. Cho ${bold("máy này")} kết nối Wi-Fi ${bold(AP_SSID)} (mạng mở, không mật khẩu).
      ${yellow("Lúc đó máy sẽ tạm mất Internet — bình thường.")}
  (Hoặc dùng điện thoại: vào ${AP_SSID}, mở ${AP_URL}, tab Wi-Fi — khỏi cần script này.)
`);
    await pause("Đã kết nối máy này vào " + AP_SSID + "? Nhấn Enter");
    dev = await waitFor(async () => {
      const s = await state(AP_URL, readCfg().token);
      return s ? { url: AP_URL, mode: "ap", state: s, token: readCfg().token } : null;
    }, 120, `Đang tìm thiết bị ở ${AP_URL}`);
    if (!dev) { bad(`Không thấy thiết bị. Kiểm tra máy đã vào đúng Wi-Fi ${AP_SSID} chưa rồi chạy lại.`); return; }
  }

  const ssid = await ask("Tên Wi-Fi mới (SSID, phân biệt hoa thường)");
  if (!ssid) { bad("Chưa nhập tên Wi-Fi."); return; }
  const pass = await askSecret("Mật khẩu Wi-Fi (để trống nếu mạng mở)");
  const r = await http(`${dev.url}/api/settings`, { method: "POST", token: dev.token,
    body: { wifiSSID: ssid, wifiPass: pass, _restart: true }, timeout: 6000 });
  if (r.status === 401) { bad("Thiết bị từ chối: sai hoặc thiếu API token."); return; }
  if (r.status !== 200 && r.status !== 0) { bad(`Thiết bị trả lỗi HTTP ${r.status}.`); return; }
  ok(`Đã gửi. Thiết bị đang khởi động lại để vào "${ssid}".`);

  console.log(`\n  Giờ cho ${bold("máy này")} kết nối lại Wi-Fi ${bold(ssid)} (cùng mạng với thiết bị).`);
  await pause();
  const back = await waitFor(async () => state("http://glimmer.local", dev.token), 240,
                             "Đang chờ thiết bị lên mạng mới (tối đa 4 phút)");
  if (back) {
    ok(`Thiết bị đã vào "${back.ssid || ssid}" — IP ${back.ip}.`);
    const cfg = readCfg();
    if (cfg.url && cfg.url !== "http://glimmer.local") {
      warn(`Hook đang trỏ tới ${cfg.url}. Chuyển về glimmer.local cho tiện:`);
      spawnSync(process.execPath, [join(here, "agents", "install.mjs"), "--url", "http://glimmer.local"], { stdio: "inherit" });
    }
  } else {
    warn("Chưa thấy thiết bị qua glimmer.local. Có thể:");
    console.log(dim("    • sai mật khẩu → sau ~1 phút màn hình lại hiện " + AP_SSID + ": chạy lại mục này;"));
    console.log(dim("    • mạng chặn các máy thấy nhau (Wi-Fi công ty/khách) → xem IP trên kênh Thông tin rồi"));
    console.log(dim("      chạy: node tools/agents/install.mjs --url http://<IP>;"));
    console.log(dim("    • kẹt ở màn kết nối quá 4 phút → rút điện cắm lại."));
  }
  console.log(dim("\n  Nhớ đổi thành phố ở tab Vị trí & giờ trên trang web nếu bạn đã chuyển nơi khác."));
}

// ── 3. kiểm tra ─────────────────────────────────────────────────────────────
async function check() {
  step("Kiểm tra");
  const hook = join(homedir(), ".glimmer", "glimmer-hook.mjs");
  const settings = join(homedir(), ".claude", "settings.json");
  const hooked = existsSync(settings) && readFileSync(settings, "utf8").includes("glimmer-hook");
  existsSync(hook) && hooked ? ok("Hook đã cài trên máy này.") : warn("Hook CHƯA cài trên máy này → chọn mục 1.");
  const cfg = readCfg();
  if (cfg.url) console.log(dim(`    hook gửi tới ${cfg.url}${cfg.token ? " (có token)" : ""}`));

  const dev = await locate();
  if (!dev) bad("Không tìm thấy thiết bị (glimmer.local / " + AP_URL + "). Cùng mạng Wi-Fi chưa?");
  else if (dev.needsToken) warn(`Thấy thiết bị ở ${dev.url} nhưng cần API token.`);
  else if (dev.mode === "ap") warn(`Thiết bị đang ở chế độ cài đặt (${AP_SSID}) → chọn mục 2.`);
  else { ok(`Thiết bị online ở ${dev.url}.`); describe(dev.state); }
}

// ── menu ────────────────────────────────────────────────────────────────────
const ACTIONS = { "may-moi": newMachine, wifi: changeWifi, "kiem-tra": check };

async function main() {
  console.log(bold("\nglimmer — cài đặt nhanh"));
  let pick = process.argv[2];
  if (!ACTIONS[pick]) {
    console.log(`
  1. Máy mới / máy chưa cài: cài hook cho Claude Code / Codex
  2. Đổi mạng Wi-Fi cho thiết bị (chuyển nhà, chuyển nơi làm)
  3. Kiểm tra kết nối
  4. Cả 2 rồi 1 (thiết bị ở nơi mới + máy mới)`);
    const n = await ask("Chọn", "3");
    pick = { 1: "may-moi", 2: "wifi", 3: "kiem-tra", 4: "both" }[n] || "kiem-tra";
  }
  if (pick === "both") { await changeWifi(); await newMachine(); }
  else await ACTIONS[pick]();
  console.log();
}

main().catch((e) => bad(e.message)).finally(() => rl.close());
