// Find glimmer displays on this network (L-10) — no dependencies, Node ≥ 18.
//
// Each display answers its own mDNS name, glimmer-<last 2 MAC bytes>.local (older firmware: plain
// "glimmer", shared by every display — two of them on one network sent hooks to the wrong one).
// Browsing mDNS from Node is unreliable (Windows' firewall drops the multicast answers), so this
// asks GET /api/state of every address of this computer's /24 networks — outbound
// HTTP only, a /24 at a time, ~2 s. Returns [{host, url, ip, fw, ssid}]: `url` is the address to keep
// (http://glimmer-xxxx.local — the same on every network, whatever IP DHCP hands out), the IP on
// old firmware (`host` null).

import { networkInterfaces } from "node:os";

function subnets() {
  const out = new Set();
  for (const list of Object.values(networkInterfaces()))
    for (const a of list || [])
      if (a.family === "IPv4" && !a.internal && !a.address.startsWith("169.254."))
        out.add(a.address.split(".").slice(0, 3).join("."));
  return [...out];
}

// Windows lets a connect to an absent host hang past the abort: give up on it at `ms` regardless.
function stateOf(ip, token, ms) {
  return Promise.race([ask(ip, token, ms), new Promise((r) => setTimeout(() => r(null), ms + 200).unref())]);
}

async function ask(ip, token, ms) {
  try {
    const r = await fetch(`http://${ip}/api/state`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {}, signal: AbortSignal.timeout(ms) });
    if (!r.ok) return null;
    const s = await r.json();
    return typeof s.fw === "string" && s.fw.includes("glimmer") ? s : null;
  } catch { return null; }
}

export async function findDisplays({ token = "", ms = 1500 } = {}) {
  const ips = subnets().flatMap((n) => Array.from({ length: 254 }, (_, i) => `${n}.${i + 1}`));
  const out = [];
  for (let i = 0; i < ips.length; i += 254) {
    const batch = ips.slice(i, i + 254);
    const got = await Promise.all(batch.map((ip) => stateOf(ip, token, ms)));
    got.forEach((s, k) => {
      if (s) out.push({ host: s.host || null, ip: batch[k], fw: s.fw, ssid: s.ssid || "",
                        url: `http://${s.host ? s.host + ".local" : batch[k]}` });
    });
  }
  return out;
}

// node tools/agents/discover.mjs — list the displays on this network.
if (process.argv[1] && /discover\.mjs$/.test(process.argv[1])) {
  const list = await findDisplays();
  if (!list.length) console.log("no glimmer display answered on this network");
  for (const d of list) console.log(`${d.url}  ip ${d.ip}  fw ${d.fw}${d.host ? "" : "  (old firmware: no own name)"}`);
  process.exit(0);   // connects to absent hosts may still be pending
}
