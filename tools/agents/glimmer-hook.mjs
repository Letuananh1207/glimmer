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
// Always exits 0 within ~2 s, so an offline display never blocks the agent.
// `--dry-run` prints the payload instead of sending it.

import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const agent = process.argv[2] === "codex" ? "codex" : "claude";
const dryRun = process.argv.includes("--dry-run");
const done = () => process.exit(0);
setTimeout(done, 2500).unref();                    // hard stop, whatever happens

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
    await fetch(`${url}/hook?agent=${agent}`, { method: "POST", headers, body, signal: AbortSignal.timeout(2000) });
  } catch {}
}

// End naturally (process.exit could drop buffered stdout); the unref'd
// timer above still forces an exit if a socket hangs.
main().catch(() => {}).finally(() => { process.exitCode = 0; });
