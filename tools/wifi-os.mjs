// wifi-os.mjs — the few Wi-Fi operations glimmer-setup's `auto` mode needs,
// per OS. Every command runs without a shell (argument arrays), so an SSID
// with quotes or spaces can't break out. Nothing here prints a password.
//
//   current()          → { ssid, profile, band5 } | null   (what this computer is on)
//   secret(cur)        → { password, open } | null           (saved key for it)
//   joinOpen(ssid)     → bool   connect to an open network (the display's setup AP)
//   back(cur, secret)  → bool   reconnect to the network we came from
//   forget(ssid)       → void   drop the temporary profile so it never auto-joins
//
// Windows (netsh) is tested. macOS (networksetup / security) and Linux
// (nmcli) follow their documented CLIs but have not been run here.

import { spawnSync } from "node:child_process";
import { mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const run = (cmd, args) => {
  const r = spawnSync(cmd, args, { encoding: "utf8", windowsHide: true });
  return { ok: r.status === 0, out: (r.stdout || "") + (r.stderr || "") };
};
const field = (text, label) => {
  const m = text.match(new RegExp(`^\\s*${label}\\s*:\\s*(.*?)\\s*$`, "m"));
  return m ? m[1] : "";
};
const xmlText = (s) => s.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"')
                        .replace(/&apos;/g, "'").replace(/&amp;/g, "&");

// ── Windows ──────────────────────────────────────────────────────────────────
const win = {
  current() {
    const r = run("netsh", ["wlan", "show", "interfaces"]);
    if (!r.ok || !/^\s*State\s*:\s*connected/m.test(r.out)) return null;
    const ssid = field(r.out, "SSID");
    if (!ssid) return null;
    return { ssid, profile: field(r.out, "Profile") || ssid, band5: /5\s*GHz|6\s*GHz/.test(field(r.out, "Band")) };
  },
  secret(cur) {
    const dir = mkdtempSync(join(tmpdir(), "glimmer-"));
    try {
      run("netsh", ["wlan", "export", "profile", `name=${cur.profile}`, "key=clear", `folder=${dir}`]);
      const f = readdirSync(dir).find((n) => n.endsWith(".xml"));
      if (!f) return null;
      const x = readFileSync(join(dir, f), "utf8");
      if (/<authentication>open<\/authentication>/i.test(x)) return { password: "", open: true };
      const k = x.match(/<keyMaterial>([^<]*)<\/keyMaterial>/);
      if (!k || /<protected>true<\/protected>/.test(x)) return null;   // key not readable
      return { password: xmlText(k[1]), open: false };
    } finally { rmSync(dir, { recursive: true, force: true }); }   // the export holds the key
  },
  joinOpen(ssid) {
    const dir = mkdtempSync(join(tmpdir(), "glimmer-"));
    const file = join(dir, "profile.xml");
    const esc = ssid.replace(/&/g, "&amp;").replace(/</g, "&lt;");
    writeFileSync(file, `<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
  <name>${esc}</name>
  <SSIDConfig><SSID><name>${esc}</name></SSID></SSIDConfig>
  <connectionType>ESS</connectionType>
  <connectionMode>manual</connectionMode>
  <MSM><security><authEncryption><authentication>open</authentication><encryption>none</encryption><useOneX>false</useOneX></authEncryption></security></MSM>
</WLANProfile>`);
    run("netsh", ["wlan", "add", "profile", `filename=${file}`, "user=current"]);
    rmSync(dir, { recursive: true, force: true });
    return run("netsh", ["wlan", "connect", `name=${ssid}`, `ssid=${ssid}`]).ok;
  },
  back(cur) { return run("netsh", ["wlan", "connect", `name=${cur.profile}`]).ok; },
  forget(ssid) { run("netsh", ["wlan", "delete", "profile", `name=${ssid}`]); },
};

// ── macOS ────────────────────────────────────────────────────────────────────
const macIf = () => {
  const r = run("networksetup", ["-listallhardwareports"]);
  const m = r.out.match(/Hardware Port: (?:Wi-Fi|AirPort)\s*\nDevice: (\S+)/);
  return m ? m[1] : "en0";
};
const mac = {
  current() {
    const dev = macIf();
    let ssid = field(run("networksetup", ["-getairportnetwork", dev]).out, "Current Wi-Fi Network");
    if (!ssid) ssid = field(run("ipconfig", ["getsummary", dev]).out, "SSID");   // macOS 14.4+
    return ssid ? { ssid, profile: ssid, dev, band5: false } : null;
  },
  secret(cur) {   // macOS asks for the login password once (Keychain)
    const r = run("security", ["find-generic-password", "-D", "AirPort network password", "-a", cur.ssid, "-w"]);
    return r.ok ? { password: r.out.trim(), open: false } : null;
  },
  joinOpen(ssid) { return run("networksetup", ["-setairportnetwork", macIf(), ssid]).ok; },
  back(cur, s) { return run("networksetup", ["-setairportnetwork", cur.dev || macIf(), cur.ssid, s?.password || ""]).ok; },
  forget(ssid) { run("networksetup", ["-removepreferredwirelessnetwork", macIf(), ssid]); },
};

// ── Linux (NetworkManager) ──────────────────────────────────────────────────
const nm = {
  current() {
    const r = run("nmcli", ["-t", "-f", "ACTIVE,SSID", "dev", "wifi"]);
    const line = r.out.split("\n").find((l) => l.startsWith("yes:"));
    if (!line) return null;
    const ssid = line.slice(4).replace(/\\:/g, ":");
    const c = run("nmcli", ["-t", "-f", "NAME,TYPE", "connection", "show", "--active"]).out
      .split("\n").find((l) => l.endsWith(":802-11-wireless"));
    return { ssid, profile: c ? c.slice(0, -":802-11-wireless".length).replace(/\\:/g, ":") : ssid, band5: false };
  },
  secret(cur) {
    const r = run("nmcli", ["-s", "-g", "802-11-wireless-security.psk", "connection", "show", cur.profile]);
    if (!r.ok) return null;
    const pw = r.out.trim();
    return { password: pw, open: pw === "" };
  },
  joinOpen(ssid) { return run("nmcli", ["dev", "wifi", "connect", ssid]).ok; },
  back(cur) { return run("nmcli", ["connection", "up", cur.profile]).ok; },
  forget(ssid) { run("nmcli", ["connection", "delete", ssid]); },
};

export const wifi = process.platform === "win32" ? win : process.platform === "darwin" ? mac : nm;
