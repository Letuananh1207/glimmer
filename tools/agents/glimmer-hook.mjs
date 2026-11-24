#!/usr/bin/env node
// glimmer-hook.mjs <claude|codex>
//
// Forward an agent hook event (JSON on stdin) to a glimmer desk display: the
// approval/question card, and the Claude screen's project board ("glimmer
// Cần duyệt · Bash"). Same payload as glimmer-hook.sh, but needs only Node
// (no jq / sh), so it runs as-is on Windows, macOS and Linux.
//
// Sends a few small fields — never the raw event (a PostToolUse event carries
// the tool's whole output, far more than the device's RAM). Anything that
// looks like a credential is masked first: the device shows it on a desk.
//
// Device address / token, first found wins:
//   GLIMMER_URL / GLIMMER_TOKEN env  →  ~/.glimmer/config.json {url, token}
//   →  http://glimmer.local (mDNS: any machine on the same network)
//
// Always exits 0 within ~4.5 s (runs async), so an offline display never blocks the agent.
// `--dry-run` prints the payload instead of sending it.

import { readFileSync, writeFileSync } from "node:fs";
import { lookup } from "node:dns/promises";
import { homedir } from "node:os";
import { join } from "node:path";

const agent = process.argv[2] === "codex" ? "codex" : "claude";
const dryRun = process.argv.includes("--dry-run");
const done = () => process.exit(0);
// Hard stop. The hook runs async (Claude Code doesn't wait for it) with a 5 s
// limit in settings, so 4.5 s leaves room for one mDNS lookup.
setTimeout(done, 4500).unref();

// Resolving "glimmer.local" from Node on Windows can take ~3 s — longer than
// a hook should wait, so events were dropped at random. Remember the
// device's IP and post straight to it; look the name up again only when
// that IP stops answering (the router handed out a new one).
const CACHE = join(homedir(), ".glimmer", "cache.json");
const readCache = () => { try { return JSON.parse(readFileSync(CACHE, "utf8")); } catch { return {}; } };
const writeCache = (c) => { try { writeFileSync(CACHE, JSON.stringify(c)); } catch {} };

async function post(url, init, ms) {
  const r = await fetch(url, { ...init, signal: AbortSignal.timeout(ms) });
  return r.status;
}

async function send(base, path, init) {
  const u = new URL(base);
  if (!u.hostname.endsWith(".local")) return post(base + path, init, 4000);
  const cache = readCache();
  const viaIp = (ip) => { const x = new URL(base); x.hostname = ip; return x.origin + path; };
  if (cache[u.hostname]) {
    try { return await post(viaIp(cache[u.hostname]), init, 1500); } catch {}
  }
  const { address } = await lookup(u.hostname, { family: 4 });
  const status = await post(viaIp(address), init, 1500);
  writeCache({ ...cache, [u.hostname]: address });
  return status;
}

function config() {
  let file = {};
  try { file = JSON.parse(readFileSync(join(homedir(), ".glimmer", "config.json"), "utf8")); } catch {}
  return {
    url: (process.env.GLIMMER_URL || file.url || "http://glimmer.local").replace(/\/+$/, ""),
    token: process.env.GLIMMER_TOKEN || file.token || "",
  };
}

// Mirrors glimmer-hook.sh's jq `redact`.
function redact(s) {
  return String(s)
    .replace(/((?:bearer|token|key|secret|password|passwd|pwd|auth[a-z]*)["']?\s*[=: ]\s*["']?)[^\s"'&|;]+/gi, "$1***")
    .replace(/(sk-[A-Za-z0-9_-]{8,}|eyJ[A-Za-z0-9_-]{10,}(\.[A-Za-z0-9_-]+){0,2}|gh[pousr]_[A-Za-z0-9]{10,}|xox[abprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{12,})/g, "***");
}

function payload(ev) {
  const ti = ev.tool_input || {};
  const detail = ti.command ?? ti.file_path ?? ti.path ?? "";
  const message = ev.message ?? ev.last_assistant_message ?? "";
  return {
    event: ev.hook_event_name || "",
    type: ev.notification_type || "",
    session: ev.session_id || "",
    cwd: (ev.cwd || "").replace(/\\/g, "/"),       // device takes the last "/" segment
    tool: ev.tool_name || "",
    detail: redact(typeof detail === "string" ? detail : JSON.stringify(detail)).slice(0, 60),
    message: redact(String(message).replace(/\s+/g, " ")).slice(0, 80),
  };
}

async function main() {
  let raw = "";
  for await (const chunk of process.stdin) {
    raw += chunk;
    if (raw.length > 4 * 1024 * 1024) break;        // a huge PostToolUse: we only need the head fields
  }
  let ev;
  try { ev = JSON.parse(raw); } catch { return; }
  const body = JSON.stringify(payload(ev));
  const { url, token } = config();
  if (dryRun) { console.log(`POST ${url}/hook?agent=${agent}\n${body}`); return; }
  const headers = { "Content-Type": "application/json" };
  if (token) headers.Authorization = `Bearer ${token}`;
  try {
    await send(url, `/hook?agent=${agent}`, { method: "POST", headers, body });
  } catch {}
}

// End naturally (process.exit could drop buffered stdout); the unref'd
// timer above still forces an exit if a socket hangs.
main().catch(() => {}).finally(() => { process.exitCode = 0; });
