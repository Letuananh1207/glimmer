#!/usr/bin/env node
// glimmer-setup.mjs — trình hướng dẫn tương tác (tiếng Việt) cho các việc hay
// làm lại khi đổi máy hoặc đổi mạng:
//
//   node tools/glimmer-setup.mjs           menu
//   node tools/glimmer-setup.mjs auto      làm hết, không hỏi gì (dùng bởi /glimmer-setup)
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
import { existsSync, readFileSync, rmSync } from "node:fs";
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
  if (Array.isArray(s.projects)) {
    const vi = { approval: "Cần duyệt", input: "Chờ bạn", error: "Lỗi", working: "Đang chạy", done: "Xong" };
    const ago = (sec) => sec < 60 ? `${sec}s` : sec < 3600 ? `${Math.round(sec / 60)}m` : `${Math.round(sec / 3600)}h`;
    if (!s.projects.length)
      console.log(dim("    Bảng project: trống — chưa có sự kiện hook nào tới thiết bị (từ lần khởi động này)."));
    for (const p of s.projects)
      console.log(dim(`    • ${p.project} (${p.agent}): ${vi[p.state] || p.state}${p.detail ? " · " + p.detail : ""}` +
                      ` — ${ago(p.age_s)} trước${p.shown ? "" : " (đã ẩn: quá cũ)"}`));
  }
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

// ── 0. tự động: một lệnh cho mọi nơi mới ──────────────────────────────────
//
// No questions asked (Claude Code's /glimmer-setup runs it): installs hooks,
// and if the display isn't on this computer's network but is broadcasting
// its setup AP, hands it THIS computer's current Wi-Fi — SSID and the
// password the OS has saved — by hopping onto the AP and back. The hop takes
// this computer offline for ~1 min; it all happens inside this one process,
// so nothing that needs the Internet is waiting on it. The password never
// leaves memory except in the POST to the display.

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function auto() {
  const { wifi } = await import("./wifi-os.mjs");

  step("1/3 Hook trên máy này");
  const inst = spawnSync(process.execPath, [join(here, "agents", "install.mjs")], { encoding: "utf8" });
  if (inst.status !== 0) bad("Cài hook lỗi: " + (inst.stderr || inst.stdout).trim().split("\n").pop());
  else ok("Hook đã cài / cập nhật (có hiệu lực từ phiên Claude Code mới).");

  step("2/3 Tìm thiết bị");
  const cur = wifi.current();
  console.log(dim(`    máy này đang ở Wi-Fi: ${cur ? cur.ssid : "(không có)"}`));
  let dev = await locate();
  if (dev?.mode === "sta") {
    ok(`Thiết bị đã online cùng mạng ở ${dev.url}${dev.state ? "" : " (cần token)"}.`);
    if (dev.state) describe(dev.state);
    return finish(true);
  }
  if (dev?.mode === "ap") {
    // This computer is already on the setup AP (user joined it by hand).
    warn(`Máy này đang nối thẳng vào ${AP_SSID}. Hãy cho máy vào Wi-Fi của nơi này rồi chạy lại.`);
    return finish(false);
  }
  if (!cur) {
    bad("Máy này chưa vào Wi-Fi nào. Vào Wi-Fi của nơi bạn đang ở rồi chạy lại.");
    return finish(false);
  }
  const sec = wifi.secret(cur);
  if (!sec) {
    bad(`Không đọc được mật khẩu đã lưu của "${cur.ssid}" từ hệ điều hành.`);
    console.log(dim("    Chạy bản hỏi-đáp và tự gõ mật khẩu: node tools/glimmer-setup.mjs wifi"));
    return finish(false);
  }

  step(`3/3 Đưa thiết bị vào Wi-Fi "${cur.ssid}"`);
  console.log(dim(`    Thiết bị chưa có trên mạng này. Cắm điện thiết bị; khoảng 1 phút sau nó phát`));
  console.log(dim(`    Wi-Fi "${AP_SSID}". Máy này sẽ tạm chuyển sang đó (~1 phút mất Internet) rồi quay lại.`));
  if (cur.band5) console.log(dim(`    (máy đang ở băng 5 GHz — router cần phát "${cur.ssid}" cả ở 2,4 GHz cho thiết bị)`));

  let sent = false, reason = "";
  try {
    // The display opens its AP ~60 s after power-on; keep trying ~3 min.
    let onAp = null;
    const end = Date.now() + 180000;
    process.stdout.write(`  Đang tìm Wi-Fi ${AP_SSID} `);
    while (!onAp && Date.now() < end) {
      wifi.joinOpen(AP_SSID);
      for (let i = 0; i < 4 && !onAp; i++) { await sleep(3000); onAp = await state(AP_URL, readCfg().token, 1); }
      process.stdout.write(".");
    }
    process.stdout.write(onAp ? green(" ✓\n") : red(" không thấy\n"));
    if (!onAp) reason = "noap";
    else {
      const r = await http(`${AP_URL}/api/settings`, { method: "POST", token: readCfg().token, timeout: 8000,
        body: { wifiSSID: cur.ssid, wifiPass: sec.password, _restart: true } });
      if (r.status === 401) reason = "token";
      else if (r.status === 200 || r.status === 0) sent = true;   // 0: it rebooted mid-reply
      else reason = `http ${r.status}`;
    }
  } finally {
    wifi.back(cur, sec);           // always return this computer to its network
    wifi.forget(AP_SSID);          // and never auto-join the setup AP later
  }
  if (!sent) {
    if (reason === "noap") {
      bad(`Không thấy Wi-Fi ${AP_SSID} sau 3 phút.`);
      console.log(dim("    • Thiết bị có cắm điện không? Màn hình có hiện KẾT NỐI WI-FI · glimmer-setup không?"));
      console.log(dim("    • Nếu nó đang hiện số liệu bình thường thì nó đang online ở mạng KHÁC (nơi cũ)."));
    } else if (reason === "token") bad("Thiết bị đòi API token: chạy node tools/agents/install.mjs --token <token> rồi chạy lại.");
    else bad(`Thiết bị trả lỗi (${reason}).`);
    return finish(false);
  }
  ok(`Đã gửi Wi-Fi "${cur.ssid}" cho thiết bị; máy này đang về lại "${cur.ssid}".`);
  try { rmSync(join(homedir(), ".glimmer", "cache.json"), { force: true }); } catch {}   // IP will differ
  const back = await waitFor(async () => state("http://glimmer.local", readCfg().token, 1), 360,
                             "Chờ thiết bị lên mạng mới (tối đa 6 phút)");
  if (back) { ok(`Thiết bị đã online — IP ${back.ip}.`); describe(back); return finish(true); }
  bad(`Thiết bị chưa lên "${cur.ssid}".`);
  console.log(dim("    • Mạng chỉ có 5 GHz, hoặc phải đăng nhập qua trang web (khách sạn/sân bay) → dùng"));
  console.log(dim("      hotspot điện thoại (2,4 GHz) cho cả laptop và thiết bị, rồi chạy lại."));
  console.log(dim("    • Mạng chặn các máy thấy nhau → xem IP trên kênh Thông tin, chạy"));
  console.log(dim("      node tools/agents/install.mjs --url http://<IP>"));
  return finish(false);
}

function finish(good) {
  console.log("\n" + (good ? green(bold("XONG — glimmer đã sẵn sàng ở nơi này."))
                           : yellow(bold("CHƯA XONG — xem hướng dẫn ở trên."))));
  console.log(dim("  Nhớ đổi thành phố ở tab Vị trí & giờ nếu bạn đã chuyển nơi khác."));
  process.exitCode = good ? 0 : 2;
}

// ── menu ────────────────────────────────────────────────────────────────────
const ACTIONS = { auto, "may-moi": newMachine, wifi: changeWifi, "kiem-tra": check };

async function main() {
  console.log(bold("\nglimmer — cài đặt nhanh"));
  let pick = process.argv[2];
  if (!ACTIONS[pick]) {
    console.log(`
  0. Tự động — làm hết mọi thứ cho nơi/máy này (khuyên dùng)
  1. Máy mới / máy chưa cài: cài hook cho Claude Code / Codex
  2. Đổi mạng Wi-Fi cho thiết bị, tự gõ tên + mật khẩu
  3. Kiểm tra kết nối
  4. Cả 2 rồi 1 (thiết bị ở nơi mới + máy mới)`);
    const n = await ask("Chọn", "0");
    pick = { 0: "auto", 1: "may-moi", 2: "wifi", 3: "kiem-tra", 4: "both" }[n] || "auto";
  }
  if (pick === "both") { await changeWifi(); await newMachine(); }
  else await ACTIONS[pick]();
  console.log();
}

main().catch((e) => bad(e.message)).finally(() => rl.close());
